function Save-VectorCraftDocument {
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $outputDirectory = [string]$Config.output.directory
    $filename = [string]$Config.output.filename

    if ([string]::IsNullOrWhiteSpace($outputDirectory)) {
        throw "Config field 'output.directory' is required."
    }

    if ([string]::IsNullOrWhiteSpace($filename)) {
        throw "Config field 'output.filename' is required."
    }

    if ([System.IO.Path]::IsPathRooted($outputDirectory)) {
        $resolvedDirectory = [System.IO.Path]::GetFullPath($outputDirectory)
    }
    else {
        $resolvedDirectory = [System.IO.Path]::GetFullPath(
            (Join-Path $ProjectRoot $outputDirectory)
        )
    }

    if ($filename -match '[\\/:*?"<>|]') {
        throw "Output filename contains invalid characters: $filename"
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)

    if ([string]::IsNullOrWhiteSpace($baseName)) {
        throw "Output filename is invalid: $filename"
    }

    $outputPath = Join-Path $resolvedDirectory "$baseName.vectorcraft"

    New-Item -ItemType Directory -Path $resolvedDirectory -Force |
        Out-Null

    $params = @{
        path   = $outputPath
        format = "vectorcraft"
    }

    $response = Invoke-VectorCraft `
        -Command "file.saveAs" `
        -Params $params

    try {
        $data = $response | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Could not parse document.save response: $response"
    }

    if ($data.ok -ne $true) {
        throw "Document save failed: $response"
    }

    $result = $data.result

    if ($null -eq $result) {
        throw "Save command returned no result: $response"
    }

    if ([string]::IsNullOrWhiteSpace([string]$result.path)) {
        throw "Save response did not confirm a file path: $response"
    }

    $savedPath = [string]$result.path
    $deadline = [DateTime]::UtcNow.AddSeconds(10)

    while (
        -not (Test-Path -LiteralPath $savedPath -PathType Leaf) -and
        [DateTime]::UtcNow -lt $deadline
    ) {
        Start-Sleep -Milliseconds 250
    }

    if (-not (Test-Path -LiteralPath $savedPath -PathType Leaf)) {
        throw "Save operation returned a path, but no file appeared after 10 seconds: $savedPath"
    }

    $file = Get-Item -LiteralPath $savedPath

    Write-Host "[PASS] Saved file exists." -ForegroundColor Green
    Write-Host "File size: $($file.Length) bytes"

    return $result
}


