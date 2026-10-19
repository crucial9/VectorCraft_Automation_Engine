function Import-ModuleConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Config file not found: $Path"
    }

    try {
        $config = Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Invalid JSON configuration: $($_.Exception.Message)"
    }

    if ([string]::IsNullOrWhiteSpace([string]$config.module)) {
        throw "Config field 'module' is required."
    }

    if ([string]::IsNullOrWhiteSpace([string]$config.document.category)) {
        throw "Config field 'document.category' is required."
    }

    if ([string]::IsNullOrWhiteSpace([string]$config.document.preset)) {
        throw "Config field 'document.preset' is required."
    }

    if ([string]::IsNullOrWhiteSpace([string]$config.output.filename)) {
        throw "Config field 'output.filename' is required."
    }

    return $config
}

function Resolve-DocumentPreset {
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $presetData = Get-VectorPresets `
        -Category ([string]$Config.document.category)

    $category = @(
        $presetData.categories |
        Where-Object {
            $_.name -eq [string]$Config.document.category
        }
    ) | Select-Object -First 1

    if ($null -eq $category) {
        throw "Preset category not found: $($Config.document.category)"
    }

    $preset = @(
        $category.presets |
        Where-Object {
            $_.name -eq [string]$Config.document.preset
        }
    ) | Select-Object -First 1

    if ($null -eq $preset) {
        throw "Preset not found: $($Config.document.preset)"
    }

    return $preset
}
