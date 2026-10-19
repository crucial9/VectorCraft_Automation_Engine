$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$ConfigPath = Join-Path $Root "Modules\A4-Resume\config.json"

Write-Host "`nVectorCraft Automation - Save Engine v0.4" -ForegroundColor Cyan
Write-Host "========================================="

try {
    . (Join-Path $Root "Launch.ps1")
    . (Join-Path $Root "Core\Connection.ps1")
    . (Join-Path $Root "Core\ConfigEngine.ps1")
    . (Join-Path $Root "Core\DocumentEngine.ps1")
    . (Join-Path $Root "Core\SaveEngine.ps1")

    $config = Import-ModuleConfig -Path $ConfigPath
    Write-Host "[PASS] Configuration loaded." -ForegroundColor Green

    $preset = Resolve-DocumentPreset -Config $config
    Write-Host "[PASS] Preset resolved: $($preset.name)" -ForegroundColor Green

    $document = New-VectorCraftDocument `
        -Config $config `
        -Preset $preset

    Write-Host "[PASS] Document creation command succeeded." -ForegroundColor Green
    Write-Host "Document Index: $($document.index)"

    $saved = Save-VectorCraftDocument `
        -Config $config `
        -ProjectRoot $Root

    Write-Host ""
    Write-Host "[PASS] Document saved and file verified." -ForegroundColor Green
    Write-Host "Saved Path : $($saved.path)"
    Write-Host "Format     : $($saved.format)"
    Write-Host "File Bytes : $($saved.bytes)"

    if ($saved.warnings) {
        Write-Host "`nSave warnings:" -ForegroundColor Yellow
        $saved.warnings | ForEach-Object {
            Write-Host " - $_" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "`n[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
