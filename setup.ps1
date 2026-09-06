param(
    [Parameter(Position = 0)]
    [string]$Component,

    [Parameter(Position = 1)]
    [ValidateSet('status', 'apply', 'capture', 'install')]
    [string]$Action = 'status'
)

$ErrorActionPreference = 'Stop'
$RepoDir = $PSScriptRoot
$ConfigsDir = Join-Path $RepoDir 'configs'

function Get-BlobHash([string]$Path) {
    return (& git -C $RepoDir hash-object -- $Path).Trim()
}

function Get-HistoryMatch([string]$RepoPath, [string]$LegacyPath, [string]$WantedBlob) {
    $commits = & git -C $RepoDir log --all --format='%H' -- $RepoPath $LegacyPath
    foreach ($commit in $commits) {
        foreach ($candidatePath in @($RepoPath, $LegacyPath)) {
            $blob = (& git -C $RepoDir rev-parse "${commit}:$candidatePath" 2>$null)
            if ($LASTEXITCODE -eq 0 -and $blob.Trim() -eq $WantedBlob) {
                return $commit
            }
        }
    }
    return $null
}

function Show-Match([string]$Commit) {
    & git -C $RepoDir show -s --format='    matches: %h %cs %s' $Commit
}

function Resolve-TargetPath([string]$Value) {
    if ($Value -eq '$HOME') { return $HOME }
    if ($Value.StartsWith('$HOME/')) {
        return Join-Path $HOME $Value.Substring('$HOME/'.Length)
    }
    if ($Value -eq '$LOCALAPPDATA') { return $env:LOCALAPPDATA }
    if ($Value.StartsWith('$LOCALAPPDATA/')) {
        return Join-Path $env:LOCALAPPDATA $Value.Substring('$LOCALAPPDATA/'.Length)
    }
    if ($Value -eq '$APPDATA') { return $env:APPDATA }
    if ($Value.StartsWith('$APPDATA/')) {
        return Join-Path $env:APPDATA $Value.Substring('$APPDATA/'.Length)
    }
    return $Value
}

function Get-ComponentInfo([string]$Name) {
    $manifest = Join-Path $ConfigsDir "$Name.yaml"
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        throw "Unknown component: $Name"
    }

    $source = Join-Path $RepoDir $Name
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "Missing repo config directory: $source"
    }

    $targetTemplate = (& $script:Yq -r '.target.windows // ""' $manifest).Trim()
    if (-not $targetTemplate) {
        throw "Component $Name has no target for windows"
    }

    $detectCommand = (& $script:Yq -r '.detect.command // ""' $manifest).Trim()

    return [pscustomobject]@{
        Name = $Name
        Source = $source
        Target = Resolve-TargetPath $targetTemplate
        DetectCommand = $detectCommand
    }
}

function Test-ConfigTree([string]$ComponentName, [string]$Source, [string]$Target) {
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) {
        Write-Host "! $Target is a symlink; symlink setups are unsupported"
        return
    }

    if (-not (Test-Path -LiteralPath $Target)) {
        Write-Host "+ $Target is missing locally"
        Write-Host "  Run: .\setup.ps1 $ComponentName apply"
        return
    }

    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        throw "Expected a directory at $Target"
    }

    $same = 0
    $localBehind = 0
    $repoBehind = 0
    $unknown = 0
    $missingLocal = 0
    $localOnly = 0
    $repoDirty = 0

    $repoFiles = @(& git -C $RepoDir -c core.quotePath=false ls-files -- $ComponentName)
    $tracked = @{}

    foreach ($repoPath in $repoFiles) {
        if (-not $repoPath) { continue }
        $rel = $repoPath.Substring($ComponentName.Length + 1)
        $tracked[$rel] = $true
        $sourceFile = Join-Path $RepoDir ($repoPath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $targetFile = Join-Path $Target ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)

        if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
            Write-Host "! $rel"
            Write-Host '    tracked repo file is missing from the repo working copy'
            $repoDirty++; $unknown++
            continue
        }

        if (-not (Test-Path -LiteralPath $targetFile)) {
            Write-Host "+ $rel"
            Write-Host '    missing from natural location'
            $missingLocal++
            continue
        }

        if (-not (Test-Path -LiteralPath $targetFile -PathType Leaf)) {
            Write-Host "! $rel"
            Write-Host '    natural-location entry is not a regular file'
            $unknown++
            continue
        }

        $sourceBlob = Get-BlobHash $sourceFile
        $targetBlob = Get-BlobHash $targetFile

        if ($sourceBlob -eq $targetBlob) {
            Write-Host "= $rel"
            $same++
            continue
        }

        $headBlob = (& git -C $RepoDir rev-parse "HEAD:$repoPath" 2>$null)
        if ($LASTEXITCODE -ne 0) { $headBlob = $null } else { $headBlob = $headBlob.Trim() }

        if (-not $headBlob) {
            Write-Host "? $rel"
            Write-Host '    repo copy is not present in HEAD; ordering is unknown'
            $unknown++
            continue
        }

        if ($sourceBlob -ne $headBlob) {
            Write-Host "? $rel"
            Write-Host '    repo working copy has uncommitted content; ordering is unknown'
            $repoDirty++; $unknown++
            continue
        }

        $match = Get-HistoryMatch $repoPath $rel $targetBlob
        if (-not $match) {
            Write-Host "? $rel"
            Write-Host '    natural-location content matches no committed version'
            $unknown++
            continue
        }

        & git -C $RepoDir merge-base --is-ancestor $match HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            $changes = (& git -C $RepoDir rev-list --count "$match..HEAD" -- $repoPath).Trim()
            Write-Host "< $rel"
            Write-Host "    natural location is behind repo by $changes file-change commit(s)"
            Show-Match $match
            $localBehind++
            continue
        }

        & git -C $RepoDir merge-base --is-ancestor HEAD $match 2>$null
        if ($LASTEXITCODE -eq 0) {
            $changes = (& git -C $RepoDir rev-list --count "HEAD..$match" -- $repoPath).Trim()
            Write-Host "> $rel"
            Write-Host "    repo HEAD is behind this known natural-location version by $changes file-change commit(s)"
            Show-Match $match
            $repoBehind++
            continue
        }

        Write-Host "~ $rel"
        Write-Host '    natural location matches Git history, but on a divergent history'
        Show-Match $match
        $unknown++
    }

    $localFiles = Get-ChildItem -LiteralPath $Target -File -Recurse -Force
    foreach ($file in $localFiles) {
        $rel = [IO.Path]::GetRelativePath($Target, $file.FullName).Replace('\', '/')
        if ($tracked.ContainsKey($rel)) { continue }
        $repoPath = "$ComponentName/$rel"
        & git -C $RepoDir check-ignore -q -- $repoPath 2>$null
        if ($LASTEXITCODE -eq 0) { continue }
        Write-Host "> $rel"
        Write-Host '    exists only in natural location'
        $localOnly++
    }

    Write-Host "`nSummary for $ComponentName"
    Write-Host "  in sync:                   $same"
    Write-Host "  natural location behind:   $localBehind"
    Write-Host "  repo behind known version: $repoBehind"
    Write-Host "  missing locally:            $missingLocal"
    Write-Host "  local-only files:           $localOnly"
    Write-Host "  unknown/divergent:          $unknown"
    if ($repoDirty -gt 0) { Write-Host "  repo files modified:        $repoDirty" }
}

function Apply-ConfigTree([string]$ComponentName, [string]$Source, [string]$Target) {
    if (Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue) {
        throw "Refusing to replace existing $Target. Run status first."
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Target) -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Target -Recurse
    Write-Host "Applied $Source -> $Target"
}

function Capture-ConfigTree([string]$ComponentName, [string]$Source, [string]$Target) {
    $targetItem = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $targetItem -or -not $targetItem.PSIsContainer -or $targetItem.LinkType) {
        throw "Cannot capture: expected a regular directory at $Target"
    }

    $repoChanges = @(& git -C $RepoDir status --porcelain -- $ComponentName)
    if ($repoChanges.Count -gt 0) {
        throw "Refusing to capture over existing repo changes in $ComponentName/. Commit, discard, or move those changes first."
    }

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-" + [guid]::NewGuid().ToString('N'))
    $tempConfig = Join-Path $tempRoot 'config'
    New-Item -ItemType Directory -Path $tempRoot | Out-Null

    try {
        Copy-Item -LiteralPath $Target -Destination $tempConfig -Recurse -Force
        if (Test-Path -LiteralPath $Source) {
            Remove-Item -LiteralPath $Source -Recurse -Force
        }
        Move-Item -LiteralPath $tempConfig -Destination $Source
    }
    finally {
        if (Test-Path -LiteralPath $tempRoot) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force
        }
    }

    Write-Host "Captured $Target -> $Source`n"
    & git -C $RepoDir status --short -- $ComponentName
    & git -C $RepoDir diff -- $ComponentName
}

function New-WorkspaceFile {
    $template = Join-Path $RepoDir 'dotfiles.code-workspace.template'
    $output = Join-Path $RepoDir 'dotfiles.code-workspace'

    if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
        throw "Missing workspace template: $template"
    }

    $nvim = Get-ComponentInfo 'nvim'
    $escapedNvimConfig = $nvim.Target.Replace('\', '\\').Replace('"', '\"')
    $content = [IO.File]::ReadAllText($template).Replace('__NVIM_CONFIG__', $escapedNvimConfig)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($output, $content, $utf8NoBom)

    Write-Host "Generated $output"
    Write-Host "  nvim config: $($nvim.Target)"
}

function Invoke-AutoSetup {
    $manifests = @(Get-ChildItem -LiteralPath $ConfigsDir -Filter '*.yaml' -File | Sort-Object Name)
    if ($manifests.Count -eq 0) {
        Write-Host "No config manifests found in $ConfigsDir"
        return
    }

    foreach ($manifest in $manifests) {
        $name = [IO.Path]::GetFileNameWithoutExtension($manifest.Name)
        $info = Get-ComponentInfo $name

        if ($info.DetectCommand -and -not (Get-Command $info.DetectCommand -ErrorAction SilentlyContinue)) {
            Write-Host "Skipping $name`: $($info.DetectCommand) not detected"
            continue
        }

        Write-Host "`n== $name =="
        if (Get-Item -LiteralPath $info.Target -Force -ErrorAction SilentlyContinue) {
            Test-ConfigTree $info.Name $info.Source $info.Target
        }
        else {
            Apply-ConfigTree $info.Name $info.Source $info.Target
        }
    }
}

& git -C $RepoDir rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { throw "Not a Git worktree: $RepoDir" }

$script:Yq = (Get-Command yq -ErrorAction SilentlyContinue).Source
if (-not $script:Yq) {
    throw "yq is required to read $ConfigsDir\*.yaml"
}

if (-not $Component) {
    Invoke-AutoSetup
    exit 0
}

if ($Component -eq 'workspace') {
    New-WorkspaceFile
    exit 0
}

$info = Get-ComponentInfo $Component

switch ($Action) {
    'status'  { Test-ConfigTree $info.Name $info.Source $info.Target }
    'apply'   { Apply-ConfigTree $info.Name $info.Source $info.Target }
    'install' { Apply-ConfigTree $info.Name $info.Source $info.Target }
    'capture' { Capture-ConfigTree $info.Name $info.Source $info.Target }
}
