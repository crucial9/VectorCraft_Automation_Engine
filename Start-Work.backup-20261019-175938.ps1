[CmdletBinding()]
param(
    [switch]$StatusOnly
)

$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$AppPath     = "C:\Program Files\VectorCraft\vectorcraft.exe"
$ControlPort = 7979
$Workspace   = Join-Path $ProjectRoot "VectorCraft-Automation.code-workspace"
$Document    = Join-Path $ProjectRoot "Output\resume.vectorcraft"
$ConfigFile  = Join-Path $ProjectRoot "Modules\A4-Resume\config.json"
$LayoutFile  = Join-Path $ProjectRoot "Modules\A4-Resume\layout.json"

function Test-Project {
    foreach ($path in @(
        $AppPath, $Workspace, $Document, $ConfigFile, $LayoutFile
    )) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required file not found: $path"
        }
    }

    Get-Content -LiteralPath $ConfigFile -Raw |
        ConvertFrom-Json -ErrorAction Stop | Out-Null

    Get-Content -LiteralPath $LayoutFile -Raw |
        ConvertFrom-Json -ErrorAction Stop | Out-Null

    Write-Host "[PASS] Required files and JSON are valid." -ForegroundColor Green
}

function Test-ControlPort {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $task = $client.ConnectAsync("127.0.0.1", $ControlPort)
        if (-not $task.Wait(1500)) { return $false }
        return $client.Connected
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Start-ControlMode {
    if (Test-ControlPort) {
        Write-Host "[PASS] Control port $ControlPort is already listening." -ForegroundColor Green
        return
    }

    Write-Host "[START] Starting VectorCraft control mode..." -ForegroundColor Cyan
    Start-Process -FilePath $AppPath -ArgumentList "--control $ControlPort"

    $deadline = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if (Test-ControlPort) {
            Write-Host "[PASS] Control mode is ready." -ForegroundColor Green
            return
        }
    }

    throw "Control port $ControlPort did not become available."
}

function Open-ExistingDocument {
    if (-not (Test-Path -LiteralPath $Document)) {
        throw "Existing document not found: $Document"
    }

    $shell = New-Object -ComObject WScript.Shell
    if (-not $shell.AppActivate("VectorCraft")) {
        throw "Could not activate the existing VectorCraft window."
    }

    Start-Sleep -Milliseconds 800
    $shell.SendKeys("^o")
    Start-Sleep -Seconds 2
    $shell.SendKeys($Document)
    Start-Sleep -Milliseconds 500
    $shell.SendKeys("{ENTER}")
    Start-Sleep -Seconds 2

    Write-Host "[REQUESTED] Open command sent to the existing VectorCraft window." -ForegroundColor Green
}
function Open-Workspace {
    $code = Get-Command "code" -ErrorAction SilentlyContinue
    if ($code) {
        Start-Process -FilePath $code.Source `
            -ArgumentList @("--reuse-window", "`"$Workspace`"")
        Write-Host "[REQUESTED] VS Code workspace opened." -ForegroundColor Green
    }
    else {
        Write-Warning "VS Code command 'code' is unavailable. Open this workspace manually: $Workspace"
    }
}

try {
    Write-Host "`n=== VECTORCRAFT MASTER ENGINE ===" -ForegroundColor Cyan
    Write-Host "Project : $ProjectRoot"
    Write-Host "Document: $Document"
    Write-Host "Control : 127.0.0.1:$ControlPort`n"

    Test-Project

    if ($StatusOnly) {
        Write-Host "[PASS] Status check complete. Nothing was launched."
        exit 0
    }

    Start-ControlMode
    Open-ExistingDocument
    Open-Workspace

    Write-Host "`n[PASS] Startup requests completed." -ForegroundColor Green
    Write-Host "No new document was created by this script."
    Write-Host "No layout was applied and no document was automatically saved."
}
catch {
    Write-Host "`n[FAILED] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}



try {
    Write-Host "`n=== VECTORCRAFT MASTER ENGINE ===" -ForegroundColor Cyan
    Write-Host "Project : $ProjectRoot"
    Write-Host "Document: $Document"
    Write-Host "Control : 127.0.0.1:$ControlPort`n"

    Test-Project

    if ($StatusOnly) {
        Write-Host "[PASS] Status check complete. Nothing was launched."
        exit 0
    }

    Start-ControlMode
    Open-ExistingDocument
    Open-Workspace

    Write-Host "`n[PASS] Startup requests completed." -ForegroundColor Green
    Write-Host "No new document was created by this script."
    Write-Host "No layout was applied and no document was automatically saved."
}
catch {
    Write-Host "`n[FAILED] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}





