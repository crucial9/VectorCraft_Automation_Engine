function New-VectorCraftDocument {
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter(Mandatory)]
        [object]$Preset
    )

    $params = @{
        preset = [string]$Preset.name
        name   = [string]$Config.output.filename
    }

    $response = Invoke-VectorCraft `
        -Command "file.new" `
        -Params $params

    try {
        $data = $response | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Could not parse file.new response: $response"
    }

    if ($data.ok -ne $true) {
        throw "Document creation failed: $response"
    }

    if ($null -eq $data.result) {
        throw "Document creation returned no result: $response"
    }

    if ($data.result.PSObject.Properties.Name -notcontains "index") {
        throw "Document creation response is missing the document index: $response"
    }

    return $data.result
}

function Open-VectorCraftDocument {
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path $PSScriptRoot "..\Output\resume.vectorcraft"),
        [string]$AppPath = "C:\Program Files\VectorCraft\vectorcraft.exe"
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Document not found: $Path"
    }

    if (-not (Test-Path -LiteralPath $AppPath -PathType Leaf)) {
        throw "VectorCraft executable not found: $AppPath"
    }

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path

    $process = Start-Process `
        -FilePath $AppPath `
        -ArgumentList "`"$resolvedPath`"" `
        -PassThru `
        -ErrorAction Stop

    Write-Host "[PASS] Open request sent to VectorCraft." -ForegroundColor Green
    Write-Host "Document: $resolvedPath"

    return $process
}
