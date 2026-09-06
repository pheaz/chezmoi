param(
    [Parameter(Position = 0)]
    [string]$Component,

    [Parameter(Position = 1)]
    [ValidateSet('status', 'apply', 'capture')]
    [string]$Action = 'status'
)

$ErrorActionPreference = 'Stop'
$RepoDir = $PSScriptRoot
$ConfigsDir = Join-Path $RepoDir 'configs'

. (Join-Path $RepoDir 'lib\powershell\prerequisites.ps1')
. (Join-Path $RepoDir 'lib\powershell\manifests.ps1')
. (Join-Path $RepoDir 'lib\powershell\copy.ps1')
. (Join-Path $RepoDir 'lib\powershell\symlink.ps1')

function Invoke-Status($Info) {
    if ($Info.Mode -eq 'symlink') {
        Test-SymlinkConfig $Info.Name $Info.Source $Info.Target
    }
    else {
        Test-ConfigTree $Info.Name $Info.Source $Info.Target
    }
}

function Invoke-Apply($Info) {
    if ($Info.Mode -eq 'symlink') {
        Apply-SymlinkConfig $Info.Name $Info.Source $Info.Target
    }
    else {
        Apply-ConfigTree $Info.Name $Info.Source $Info.Target
    }
}

function Invoke-Capture($Info) {
    $item = Get-Item -LiteralPath $Info.Target -Force -ErrorAction SilentlyContinue
    if ($Info.Mode -eq 'symlink' -and $item -and $item.LinkType) {
        Write-Host "$($Info.Target) is already a symlink into the repo; there is nothing to capture."
        return
    }

    Capture-ConfigTree $Info.Name $Info.Source $Info.Target
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
        $item = Get-Item -LiteralPath $info.Target -Force -ErrorAction SilentlyContinue
        if ($item) {
            Invoke-Status $info
        }
        else {
            Invoke-Apply $info
        }
    }
}

& git -C $RepoDir rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { throw "Not a Git worktree: $RepoDir" }

$script:Yq = Ensure-Yq

if (-not $Component) {
    Invoke-AutoSetup
    exit 0
}

$info = Get-ComponentInfo $Component

switch ($Action) {
    'status'  { Invoke-Status $info }
    'apply'   { Invoke-Apply $info }
    'capture' { Invoke-Capture $info }
}
