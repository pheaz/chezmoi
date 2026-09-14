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
    $componentDir = Join-Path $ComponentsDir $Name
    $manifest = Join-Path $componentDir 'manifest.yaml'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        throw "Unknown component: $Name"
    }

    $source = Join-Path $componentDir 'files'
    $setupScript = Join-Path $componentDir 'setup.ps1'
    $targetTemplate = (& $script:Yq -r '.target.windows // ""' $manifest).Trim()
    $target = if ($targetTemplate) { Resolve-TargetPath $targetTemplate } else { $null }

    $detectCommand = (& $script:Yq -r '.detect.command // ""' $manifest).Trim()
    $mode = (& $script:Yq -r '.mode // "copy"' $manifest).Trim()
    if ($mode -notin @('symlink', 'copy', 'setup')) {
        throw "Unsupported mode for $Name`: $mode"
    }

    return [pscustomobject]@{
        Name = $Name
        Source = $source
        Target = $target
        DetectCommand = $detectCommand
        Mode = $mode
        SetupScript = $setupScript
        ComponentDir = $componentDir
    }
}
