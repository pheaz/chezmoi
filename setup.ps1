param(
    [Parameter(Position = 0)]
    [ValidateSet('nvim')]
    [string]$Component
)

$ErrorActionPreference = 'Stop'
$RepoDir = $PSScriptRoot

function Link-Nvim {
    $source = Join-Path $RepoDir 'nvim'
    $target = Join-Path $env:LOCALAPPDATA 'nvim'

    if (Test-Path -LiteralPath $target) {
        throw "Refusing to replace existing $target"
    }

    New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
    Write-Host "Linked $target -> $source"
}

switch ($Component) {
    'nvim' { Link-Nvim }
    default {
        Write-Error 'Usage: .\setup.ps1 nvim'
        exit 2
    }
}
