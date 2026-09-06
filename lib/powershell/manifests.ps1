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
    $mode = (& $script:Yq -r '.mode // "copy"' $manifest).Trim()
    if ($mode -notin @('symlink', 'copy')) {
        throw "Unsupported mode for $Name`: $mode"
    }

    return [pscustomobject]@{
        Name = $Name
        Source = $source
        Target = Resolve-TargetPath $targetTemplate
        DetectCommand = $detectCommand
        Mode = $mode
    }
}
