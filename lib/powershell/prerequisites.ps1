function Ensure-Yq {
    $command = Get-Command yq -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $installDir = Join-Path $HOME '.local\bin'
    $localYq = Join-Path $installDir 'yq.exe'
    if (Test-Path -LiteralPath $localYq -PathType Leaf) {
        return $localYq
    }

    $architecture = ([string]$env:PROCESSOR_ARCHITECTURE).ToUpperInvariant()
    $assetArchitecture = switch ($architecture) {
        'AMD64' { 'amd64' }
        'ARM64' { 'arm64' }
        'X86'   { '386' }
        default { throw "Cannot bootstrap yq on unsupported architecture: $architecture" }
    }

    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    $url = "https://github.com/mikefarah/yq/releases/latest/download/yq_windows_$assetArchitecture.exe"
    $temp = "$localYq.download"

    Write-Host "Installing yq to $localYq"
    try {
        Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing
        Move-Item -LiteralPath $temp -Destination $localYq -Force
    }
    catch {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        throw "Failed to bootstrap yq from $url`: $($_.Exception.Message)"
    }

    return $localYq
}
