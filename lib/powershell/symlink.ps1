function Get-LinkDestination([System.IO.FileSystemInfo]$Item, [string]$TargetPath) {
    $rawTarget = [string](@($Item.Target)[0])
    if (-not $rawTarget) { return $null }

    if ([IO.Path]::IsPathRooted($rawTarget)) {
        return [IO.Path]::GetFullPath($rawTarget)
    }

    return [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $TargetPath) $rawTarget))
}

function Test-SymlinkConfig([string]$ComponentName, [string]$Source, [string]$Target) {
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue

    if ($item -and $item.LinkType) {
        $expected = [IO.Path]::GetFullPath($Source).TrimEnd([char[]]'\/')
        $actual = Get-LinkDestination $item $Target
        if ($actual) { $actual = $actual.TrimEnd([char[]]'\/') }

        if ($actual -and $actual.Equals($expected, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Host "= $Target -> $Source"
            return
        }

        if (-not $actual) {
            throw "$Target is a broken or unreadable symlink"
        }
        throw "$Target points to $actual, expected $expected"
    }

    if ($item) {
        if ($item.PSIsContainer) {
            Write-Host "! $Target is a real directory; expected a symlink to $Source"
            Write-Host "  Comparing the existing directory before migration:`n"
            Test-ConfigTree $ComponentName $Source $Target
            return
        }
        throw "$Target exists but is not a directory symlink"
    }

    Write-Host "+ $Target is missing"
    Write-Host "  Run: .\setup.ps1 $ComponentName apply"
}

function Apply-SymlinkConfig([string]$ComponentName, [string]$Source, [string]$Target) {
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.LinkType) {
            $expected = [IO.Path]::GetFullPath($Source).TrimEnd([char[]]'\/')
            $actual = Get-LinkDestination $item $Target
            if ($actual) { $actual = $actual.TrimEnd([char[]]'\/') }
            if ($actual -and $actual.Equals($expected, [StringComparison]::OrdinalIgnoreCase)) {
                Write-Host "$Target is already linked to $Source"
                return
            }
        }
        throw "Refusing to replace existing $Target. Run status first; capture it if needed, then move/remove it before applying."
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $Target) -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    Write-Host "Linked $Target -> $Source"
}
