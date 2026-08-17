param(
    [Parameter(Position = 0)]
    [ValidateSet('nvim')]
    [string]$Component,

    [Parameter(Position = 1)]
    [ValidateSet('status', 'install', 'materialize')]
    [string]$Action = 'status'
)

$ErrorActionPreference = 'Stop'
$RepoDir = $PSScriptRoot

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

function Test-ConfigTree([string]$ComponentName, [string]$Source, [string]$Target) {
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) {
        Write-Host "! $Target is a symlink, not an independent config copy"
        Write-Host "  Run: .\setup.ps1 $ComponentName materialize"
        return
    }

    if (-not (Test-Path -LiteralPath $Target)) {
        Write-Host "+ $Target is missing locally"
        Write-Host "  Run: .\setup.ps1 $ComponentName install"
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

    $localFiles = Get-ChildItem -LiteralPath $Target -File -Recurse
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

function Install-ConfigTree([string]$Source, [string]$Target) {
    if (Test-Path -LiteralPath $Target) {
        throw "Refusing to replace existing $Target. Run status first."
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Target) -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Target -Recurse
    Write-Host "Installed $Source -> $Target"
}

function Materialize-ConfigTree([string]$ComponentName, [string]$Source, [string]$Target) {
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction Stop
    if (-not $item.LinkType) {
        throw "$Target is not a symlink. Nothing was changed."
    }

    $sourceReal = (Resolve-Path -LiteralPath $Source).Path
    $targetReal = (Resolve-Path -LiteralPath $Target).Path
    if ($sourceReal -ne $targetReal) {
        throw "$Target does not point to this repo config. Nothing was changed."
    }

    $tmp = "$Target.dotfiles-materialize.$PID"
    Copy-Item -LiteralPath $Source -Destination $tmp -Recurse
    Remove-Item -LiteralPath $Target
    Move-Item -LiteralPath $tmp -Destination $Target
    Write-Host "Materialized $Target as an independent directory copy."
    Write-Host "Run: .\setup.ps1 $ComponentName status"
}

& git -C $RepoDir rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { throw "Not a Git worktree: $RepoDir" }

switch ($Component) {
    'nvim' {
        $source = Join-Path $RepoDir 'nvim'
        $target = Join-Path $env:LOCALAPPDATA 'nvim'
    }
}

switch ($Action) {
    'status'      { Test-ConfigTree $Component $source $target }
    'install'     { Install-ConfigTree $source $target }
    'materialize' { Materialize-ConfigTree $Component $source $target }
}
