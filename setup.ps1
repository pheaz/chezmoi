param(
    [Parameter(Position = 0)]
    [string]$Component,

    [Parameter(Position = 1)]
    [ValidateSet('status', 'apply', 'capture')]
    [string]$Action = 'status'
)

$ErrorActionPreference = 'Stop'
$RepoDir = $PSScriptRoot
$ComponentsDir = Join-Path $RepoDir 'components'

. (Join-Path $RepoDir 'lib\powershell\prerequisites.ps1')
. (Join-Path $RepoDir 'lib\powershell\manifests.ps1')
. (Join-Path $RepoDir 'lib\powershell\copy.ps1')
. (Join-Path $RepoDir 'lib\powershell\symlink.ps1')

function Invoke-ComponentSetup($Info, [string]$Action) {
    if (-not (Test-Path -LiteralPath $Info.SetupScript -PathType Leaf)) {
        throw "Missing setup script for $($Info.Name): $($Info.SetupScript)"
    }

    & $Info.SetupScript $Action $Info.Source $Info.Target
    if ($LASTEXITCODE -ne 0) {
        throw "Setup action '$Action' failed for $($Info.Name)"
    }
}

function Invoke-Status($Info) {
    switch ($Info.Mode) {
        'symlink' { Test-SymlinkConfig $Info.Name $Info.Source $Info.Target }
        'copy'    { Test-ConfigTree $Info.Name $Info.Source $Info.Target }
        'setup'   { Invoke-ComponentSetup $Info 'status' }
    }
}

function Invoke-Apply($Info) {
    switch ($Info.Mode) {
        'symlink' { Apply-SymlinkConfig $Info.Name $Info.Source $Info.Target }
        'copy'    { Apply-ConfigTree $Info.Name $Info.Source $Info.Target }
        'setup'   { Invoke-ComponentSetup $Info 'apply' }
    }
}

function Invoke-Capture($Info) {
    if ($Info.Mode -eq 'setup') {
        throw "capture is not supported for setup-mode component $($Info.Name)"
    }

    $item = Get-Item -LiteralPath $Info.Target -Force -ErrorAction SilentlyContinue
    if ($Info.Mode -eq 'symlink' -and $item -and $item.LinkType) {
        Write-Host "$($Info.Target) is already a symlink into the repo; there is nothing to capture."
        return
    }

    Capture-ConfigTree $Info.Name $Info.Source $Info.Target
}

function Invoke-AutoSetup {
    $componentDirs = @(Get-ChildItem -LiteralPath $ComponentsDir -Directory | Sort-Object Name)
    $found = $false

    foreach ($componentDir in $componentDirs) {
        $manifest = Join-Path $componentDir.FullName 'manifest.yaml'
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { continue }
        $found = $true

        $name = $componentDir.Name
        $info = Get-ComponentInfo $name

        if (-not $info.Target) {
            Write-Host "Skipping $name`: no target for windows"
            continue
        }

        if ($info.DetectCommand -and -not (Get-Command $info.DetectCommand -ErrorAction SilentlyContinue)) {
            Write-Host "Skipping $name`: $($info.DetectCommand) not detected"
            continue
        }

        if (-not (Test-Path -LiteralPath $info.Source -PathType Container)) {
            $item = Get-Item -LiteralPath $info.Target -Force -ErrorAction SilentlyContinue
            if ($info.Mode -ne 'setup' -and $item -and $item.PSIsContainer -and -not $item.LinkType) {
                Write-Host "Skipping $name`: component files have not been captured yet"
                Write-Host "  Run: .\setup.ps1 $name capture"
            }
            else {
                Write-Host "Skipping $name`: missing component files directory $($info.Source)"
            }
            continue
        }

        Write-Host "`n== $name =="
        if ($info.Mode -eq 'setup') {
            Invoke-Apply $info
            continue
        }

        $item = Get-Item -LiteralPath $info.Target -Force -ErrorAction SilentlyContinue
        if ($item) {
            Invoke-Status $info
        }
        else {
            Invoke-Apply $info
        }
    }

    if (-not $found) {
        Write-Host "No component manifests found in $ComponentsDir"
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
if (-not $info.Target) {
    throw "Component $Component has no target for windows"
}

if (-not (Test-Path -LiteralPath $info.Source -PathType Container)) {
    throw "Missing component files directory: $($info.Source)"
}

switch ($Action) {
    'status'  { Invoke-Status $info }
    'apply'   { Invoke-Apply $info }
    'capture' { Invoke-Capture $info }
}
