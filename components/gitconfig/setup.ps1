param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('status', 'apply', 'capture')]
    [string]$Action,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Source,

    [Parameter(Mandatory = $true, Position = 2)]
    [string]$Target
)

$ErrorActionPreference = 'Stop'
$SharedConfig = Join-Path $Source '.gitconfig'

function Test-GitInclude {
    $values = @(& git config --global --get-all include.path 2>$null)
    return $values -contains $SharedConfig
}

switch ($Action) {
    'status' {
        if (Test-GitInclude) {
            Write-Host "= $Target includes $SharedConfig"
            exit 0
        }
        Write-Error "$Target does not include $SharedConfig" -ErrorAction Continue
        exit 1
    }
    'apply' {
        if (Test-GitInclude) {
            Write-Host "$Target already includes $SharedConfig"
            exit 0
        }
        & git config --global --add include.path $SharedConfig
        if ($LASTEXITCODE -ne 0) { throw 'Failed to add global Git include.path' }
        Write-Host "Added $SharedConfig to global Git include.path"
        exit 0
    }
    'capture' {
        Write-Error "capture is not supported for gitconfig; the machine-local $Target is intentionally not tracked." -ErrorAction Continue
        exit 1
    }
}
