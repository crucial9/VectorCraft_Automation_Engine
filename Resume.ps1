$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$Workspace = Join-Path $Root "VectorCraft-Automation.code-workspace"
$LogDir = Join-Path $Root "Logs"
$LogFile = Join-Path $LogDir "resume.log"

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

function Write-ResumeLog {
    param([string]$Message)

    $Line = "{0} | {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -LiteralPath $LogFile -Value $Line -Encoding UTF8
}

Write-Host "`nVectorCraft Automation — Safe Resume" -ForegroundColor Cyan
Write-Host "===================================="

Write-ResumeLog "Resume requested."

# 1. Open the project workspace in VS Code when available.
$CodeCommand = Get-Command code -ErrorAction SilentlyContinue

if ($null -ne $CodeCommand) {
    try {
        Start-Process -FilePath $CodeCommand.Source `
            -ArgumentList @("`"$Workspace`"") `
            -ErrorAction Stop

        Write-Host "[PASS] VS Code workspace requested." -ForegroundColor Green
        Write-ResumeLog "VS Code workspace requested."
    }
    catch {
        Write-Host "[WARN] Could not launch VS Code: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-ResumeLog "VS Code launch failed: $($_.Exception.Message)"
    }
}
else {
    Write-Host "[WARN] The 'code' command is unavailable." -ForegroundColor Yellow
    Write-Host "Open VS Code and use File > Open Workspace from File."
    Write-Host "Select: $Workspace"
    Write-ResumeLog "VS Code CLI not found."
}

# 2. Load existing startup and connection functions.
try {
    . (Join-Path $Root "Launch.ps1")
    . (Join-Path $Root "Core\Connection.ps1")
    . (Join-Path $Root "Core\ConfigEngine.ps1")

    Write-Host "[PASS] Existing core scripts loaded." -ForegroundColor Green
    Write-ResumeLog "Core scripts loaded."

    # 3. Start or detect the VectorCraft control port.
    . (Join-Path $Root "Launch.ps1")

    # 4. Validate configuration without creating a document.
    $ConfigPath = Join-Path $Root "Modules\A4-Resume\config.json"
    $Config = Import-ModuleConfig -Path $ConfigPath

    Write-Host "[PASS] Project configuration loaded." -ForegroundColor Green

    # 5. Verify that the configured preset can be resolved.
    $Preset = Resolve-DocumentPreset -Config $Config

    Write-Host "[PASS] API preset lookup succeeded." -ForegroundColor Green
    Write-Host "Module : $($Config.module)"
    Write-Host "Preset : $($Preset.name)"
    Write-Host ""
    Write-Host "[PASS] Safe resume completed." -ForegroundColor Green
    Write-Host "No new document was created."
    Write-Host "Project: $Root"

    Write-ResumeLog "Resume succeeded. Module=$($Config.module); Preset=$($Preset.name)"
}
catch {
    Write-Host "`n[FAIL] Resume check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Existing project files have not been intentionally overwritten."
    Write-Host "Check Logs\resume.log for the recorded session."
    Write-ResumeLog "Resume failed: $($_.Exception.Message)"
}
