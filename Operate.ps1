param(
    [ValidateSet("Open", "Status", "Layout")]
    [string]$Action = "Open"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

$connectionFile = Join-Path $ProjectRoot "Core\Connection.ps1"
$layoutEngineFile = Join-Path $ProjectRoot "Core\LayoutEngine.ps1"
$configFile = Join-Path $ProjectRoot "Modules\A4-Resume\config.json"
$layoutFile = Join-Path $ProjectRoot "Modules\A4-Resume\layout.json"
$documentFile = Join-Path $ProjectRoot "Output\resume.vectorcraft"

foreach ($requiredFile in @(
    $connectionFile,
    $layoutEngineFile,
    $configFile,
    $layoutFile,
    $documentFile
)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required project file not found: $requiredFile"
    }
}

. $connectionFile
. $layoutEngineFile

$config = Get-Content -LiteralPath $configFile -Raw |
    ConvertFrom-Json -ErrorAction Stop

$layout = Get-Content -LiteralPath $layoutFile -Raw |
    ConvertFrom-Json -ErrorAction Stop

Write-Host "`n=== VECTORCRAFT OPERATION ENGINE ===" -ForegroundColor Cyan
Write-Host "Action : $Action"
Write-Host "Project: $ProjectRoot"
Write-Host "File   : $documentFile"

$listener = Get-NetTCPConnection `
    -LocalPort 7979 `
    -State Listen `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $listener) {
    throw "VectorCraft control port 7979 is not listening. Start VectorCraft first."
}

Write-Host "[PASS] Control port is listening." -ForegroundColor Green

if ($Action -eq "Status") {
    $file = Get-Item -LiteralPath $documentFile

    Write-Host "`nExisting document:" -ForegroundColor Cyan
    $file | Select-Object FullName, Length, LastWriteTime | Format-List

    Write-Host "Layout elements: $(@($layout.elements).Count)"
    Write-Host "No document was opened, created, or modified."
    return
}


if ($Action -eq "Open") {
    Write-Host "`nOpening existing VectorCraft document..." -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $documentFile -PathType Leaf)) {
        throw "Document not found: $documentFile"
    }

    $shell = New-Object -ComObject WScript.Shell

    if (-not $shell.AppActivate("VectorCraft")) {
        throw "Could not activate VectorCraft. Please open VectorCraft first."
    }

    Start-Sleep -Milliseconds 1000
    $shell.SendKeys("^o")
    Start-Sleep -Seconds 2
    $shell.SendKeys($documentFile)
    Start-Sleep -Milliseconds 500
    $shell.SendKeys("{ENTER}")
    Start-Sleep -Seconds 3

    Write-Host "[SENT] Open command sent. Check VectorCraft." -ForegroundColor Yellow
    return
}

}

if ($Action -eq "Layout") {
    Write-Host "`nWARNING: Layout operations may add objects to the active document."
    Write-Host "Only continue if the correct document is open and you intend to apply this layout."

    $confirmation = Read-Host "Type APPLY to continue"

    if ($confirmation -cne "APPLY") {
        Write-Host "Cancelled. No layout operation was sent."
        return
    }

    Invoke-VectorCraftLayout -Path $layoutFile

    Write-Host "`n[PASS] Layout engine returned without throwing an error." -ForegroundColor Green
    Write-Host "Verify the visible result in VectorCraft before saving."
}
