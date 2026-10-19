$ErrorActionPreference = "Stop"

$AppPath = "C:\Program Files\VectorCraft\vectorcraft.exe"
$HostAddress = "127.0.0.1"
$Port = 7979

function Test-VectorCraftConnection {
    $client = $null

    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $task = $client.ConnectAsync($HostAddress, $Port)

        if (-not $task.Wait(1000)) {
            return $false
        }

        return $client.Connected
    }
    catch {
        return $false
    }
    finally {
        if ($null -ne $client) {
            $client.Dispose()
        }
    }
}

# Do not launch another instance if the control port is already available.
if (Test-VectorCraftConnection) {
    Write-Host "[PASS] VectorCraft control port is already available." -ForegroundColor Green
    return
}

Write-Host "[INFO] Launching VectorCraft in control mode..." -ForegroundColor Cyan

Start-Process `
    -FilePath $AppPath `
    -ArgumentList @("--control", "$Port") `
    -WorkingDirectory (Split-Path $AppPath)

# Wait up to 15 seconds for the control port.
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500

    if (Test-VectorCraftConnection) {
        Write-Host "[PASS] VectorCraft control port is ready." -ForegroundColor Green
        return
    }
}

throw "VectorCraft did not expose port $Port within 15 seconds. Check the application and control-mode startup."
