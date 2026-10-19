function Invoke-VectorCraft {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [hashtable]$Params = @{}
    )

    $client = $null
    $stream = $null
    $writer = $null
    $reader = $null

    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $client.Connect("127.0.0.1", 7979)

        $stream = $client.GetStream()
        $stream.ReadTimeout = 5000
        $stream.WriteTimeout = 5000

        $encoding = [System.Text.UTF8Encoding]::new($false)

        $writer = [System.IO.StreamWriter]::new(
            $stream, $encoding, 1024, $true
        )
        $writer.AutoFlush = $true

        $reader = [System.IO.StreamReader]::new(
            $stream, $encoding, $false, 1024, $true
        )

        $request = @{
            id     = 1
            method = "engine.execute"
            params = @{
                command = $Command
                params  = $Params
            }
        } | ConvertTo-Json -Depth 20 -Compress

        $writer.WriteLine($request)
        $response = $reader.ReadLine()

        if ($null -eq $response) {
            throw "No response received from VectorCraft."
        }

        return $response
    }
    catch {
        throw "VectorCraft request failed: $($_.Exception.Message)"
    }
    finally {
        if ($null -ne $reader) { $reader.Dispose() }
        if ($null -ne $writer) { $writer.Dispose() }
        if ($null -ne $stream) { $stream.Dispose() }
        if ($null -ne $client) { $client.Dispose() }
    }
}

function Get-VectorPresets {
    param(
        [ValidateSet(
            "Recent", "Saved", "Mobile", "Web", "Print",
            "Film & Video", "Art & Illustration", "Branding", "Social"
        )]
        [string]$Category = "Print"
    )

    $response = Invoke-VectorCraft `
        -Command "file.newPresets" `
        -Params @{ category = $Category }

    $data = $response | ConvertFrom-Json

    if ($data.ok -ne $true) {
        throw "Preset request failed: $response"
    }

    return $data.result
}
