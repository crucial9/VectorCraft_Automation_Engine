
# ============================================================
# VectorCraft Layout Engine v0.2
# JSON-driven layout renderer
# Compatible with Windows PowerShell 5.1+
# ============================================================

Set-StrictMode -Version 2.0

# ------------------------------------------------------------
# Parse VectorCraft API response
# ------------------------------------------------------------
function ConvertFrom-VectorCraftResponse {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Response,

        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    try {
        $data = $Response | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "[$CommandName] Invalid JSON response: $Response"
    }

    if ($data.ok -eq $false) {
        $message = $data.error

        if ([string]::IsNullOrWhiteSpace([string]$message)) {
            $message = $Response
        }

        throw "[$CommandName] API error: $message"
    }

    if ($data.status -eq "error") {
        throw "[$CommandName] API error: $Response"
    }

    return $data
}

# ------------------------------------------------------------
# Execute VectorCraft command
# ------------------------------------------------------------
function Invoke-LayoutCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [hashtable]$Params
    )

    $rawResponse = Invoke-VectorCraft `
        -Command $Command `
        -Params $Params

    return ConvertFrom-VectorCraftResponse `
        -Response ([string]$rawResponse) `
        -CommandName $Command
}

# ------------------------------------------------------------
# Convert #RRGGBB to [R,G,B]
# ------------------------------------------------------------
function ConvertTo-RGBArray {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Color
    )

    $hex = $Color.Trim()

    if ($hex.StartsWith("#")) {
        $hex = $hex.Substring(1)
    }

    if ($hex -notmatch '^[0-9a-fA-F]{6}$') {
        throw "Invalid color '$Color'. Expected #RRGGBB."
    }

    return ,@(
        [Convert]::ToInt32($hex.Substring(0, 2), 16),
        [Convert]::ToInt32($hex.Substring(2, 2), 16),
        [Convert]::ToInt32($hex.Substring(4, 2), 16)
    )
}

# ------------------------------------------------------------
# Validate numeric values
# Compatible with Windows PowerShell 5.1
# ------------------------------------------------------------
function Assert-LayoutNumber {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        $Value,

        [switch]$Positive
    )

    $number = 0.0

    if (-not [double]::TryParse(
        [string]$Value,
        [System.Globalization.NumberStyles]::Float,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$number
    )) {
        throw "'$Name' must be a valid number."
    }

    if ([double]::IsNaN($number) -or
        [double]::IsInfinity($number)) {
        throw "'$Name' must be a finite number."
    }

    if ($Positive -and $number -le 0) {
        throw "'$Name' must be greater than zero."
    }

    return $number
}

# ------------------------------------------------------------
# Extract object ID from API response
# ------------------------------------------------------------
function Get-LayoutObjectId {
    param(
        [Parameter(Mandatory = $true)]
        $Response
    )

    if ($Response.targetId) {
        return [string]$Response.targetId
    }

    if ($Response.result -and $Response.result.targetId) {
        return [string]$Response.result.targetId
    }

    if ($Response.result -and
        $null -ne $Response.result.index) {
        return [string]$Response.result.index
    }

    if ($null -ne $Response.index) {
        return [string]$Response.index
    }

    # Some successful APIs do not return an object ID.
    # Return null rather than guessing an ID.
    return $null
}

# ------------------------------------------------------------
# Resolve named style
# ------------------------------------------------------------
function Resolve-LayoutStyle {
    param(
        [Parameter(Mandatory = $true)]
        $Element,

        [Parameter(Mandatory = $true)]
        $Styles
    )

    if (-not $Element.style) {
        return $null
    }

    $styleName = [string]$Element.style
    $styleProperty = $Styles.PSObject.Properties[$styleName]

    if ($null -eq $styleProperty) {
        throw "Style '$styleName' is not defined in layout.json."
    }

    return $styleProperty.Value
}

# ------------------------------------------------------------
# Create rectangle
# ------------------------------------------------------------
function New-LayoutRectangle {
    param(
        [Parameter(Mandatory = $true)]
        $Element
    )

    foreach ($field in @("x", "y", "width", "height")) {
        $property = $Element.layout.PSObject.Properties[$field]

        if ($null -eq $property) {
            throw "Rectangle '$($Element.id)' is missing layout.$field."
        }
    }

    $x = Assert-LayoutNumber -Name "x" `
        -Value $Element.layout.x

    $y = Assert-LayoutNumber -Name "y" `
        -Value $Element.layout.y

    $width = Assert-LayoutNumber -Name "width" `
        -Value $Element.layout.width -Positive

    $height = Assert-LayoutNumber -Name "height" `
        -Value $Element.layout.height -Positive

    $params = @{
        x      = $x
        y      = $y
        width  = $width
        height = $height
    }

    if ($Element.fill) {
        $params.fill = $Element.fill
    }

    if ($null -ne $Element.PSObject.Properties["stroke"] -and $null -ne $Element.stroke) {
        $params.stroke = $Element.stroke
    }

    $response = Invoke-LayoutCommand `
        -Command "shape.rectangle" `
        -Params $params

    return Get-LayoutObjectId -Response $response
}

# ------------------------------------------------------------
# Create text
# Uses VectorCraft's documented text.create parameter names
# ------------------------------------------------------------
function New-LayoutText {
    param(
        [Parameter(Mandatory = $true)]
        $Element,

        [Parameter(Mandatory = $true)]
        $Styles
    )

    if ($null -eq $Element.content) {
        throw "Text element '$($Element.id)' is missing content."
    }

    foreach ($field in @("x", "y")) {
        $property = $Element.layout.PSObject.Properties[$field]

        if ($null -eq $property) {
            throw "Text element '$($Element.id)' is missing layout.$field."
        }
    }

    $x = Assert-LayoutNumber -Name "x" `
        -Value $Element.layout.x

    $y = Assert-LayoutNumber -Name "y" `
        -Value $Element.layout.y

    $params = @{
        x    = $x
        y    = $y
        text = [string]$Element.content
    }

    $style = Resolve-LayoutStyle `
        -Element $Element `
        -Styles $Styles

    if ($null -ne $style) {
        if ($style.font) {
            $params.font = [string]$style.font
        }

        if ($null -ne $style.fontSize) {
            $params.size = Assert-LayoutNumber `
                -Name "fontSize" `
                -Value $style.fontSize `
                -Positive
        }

        if ($null -ne $style.PSObject.Properties["fontStyle"] -and $style.fontStyle) {
            $params.style = [string]$style.fontStyle
        }

        if ($style.color) {
            $params.color = ConvertTo-RGBArray `
                -Color ([string]$style.color)
        }

        if ($null -ne $style.lineHeight) {
            $params.leadingModel = Assert-LayoutNumber `
                -Name "lineHeight" `
                -Value $style.lineHeight `
                -Positive
        }
    }

    # Optional text-specific properties.
    if ($null -ne $Element.layout.width) {
        $params.area = @{
            width = Assert-LayoutNumber `
                -Name "text width" `
                -Value $Element.layout.width `
                -Positive
        }

        if ($null -ne $Element.layout.height) {
            $params.area.height = Assert-LayoutNumber `
                -Name "text height" `
                -Value $Element.layout.height `
                -Positive
        }
    }

    if ($null -ne $Element.vertical) {
        $params.vertical = [bool]$Element.vertical
    }

    if ($Element.justify) {
        $params.justify = [string]$Element.justify
    }

    $response = Invoke-LayoutCommand `
        -Command "text.create" `
        -Params $params

    return Get-LayoutObjectId -Response $response
}

# ------------------------------------------------------------
# Main layout renderer
# ------------------------------------------------------------
function Invoke-VectorCraftLayout {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Layout file not found: $Path"
    }

    try {
        $config = Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Could not parse layout JSON: $($_.Exception.Message)"
    }

    if ($null -eq $config.styles) {
        throw "layout.json must contain a 'styles' object."
    }

    if ($null -eq $config.elements) {
        throw "layout.json must contain an 'elements' array."
    }

    $created = 0
    $failed = 0
    $results = @()
    $errors = @()

    Write-Host ""
    Write-Host "VectorCraft Layout Engine v0.2"
    Write-Host "================================"

    foreach ($element in $config.elements) {
        $elementName = [string]$element.id

        if ([string]::IsNullOrWhiteSpace($elementName)) {
            $elementName = "(unnamed element)"
        }

        Write-Host ""
        Write-Host "[ELEMENT] $elementName ($($element.type))"

        try {
            $objectId = $null

            switch ([string]$element.type) {
                "rectangle" {
                    Write-Host "  -> shape.rectangle"

                    $objectId = New-LayoutRectangle `
                        -Element $element
                }

                "text" {
                    Write-Host "  -> text.create"

                    $objectId = New-LayoutText `
                        -Element $element `
                        -Styles $config.styles
                }

                default {
                    throw "Unsupported element type '$($element.type)'."
                }
            }

            $created++

            if ($null -ne $objectId) {
                Write-Host "  [PASS] Created. Object ID: $objectId" `
                    -ForegroundColor Green
            }
            else {
                Write-Host "  [PASS] API accepted the command; no object ID returned." `
                    -ForegroundColor Yellow
            }

            $results += [PSCustomObject]@{
                Element = $elementName
                Type    = [string]$element.type
                ObjectId = $objectId
                Status  = "Created"
            }
        }
        catch {
            $failed++
            $message = $_.Exception.Message

            Write-Host "  [FAIL] $message" -ForegroundColor Red

            $errors += "Element '$elementName': $message"

            $results += [PSCustomObject]@{
                Element = $elementName
                Type    = [string]$element.type
                ObjectId = $null
                Status  = "Failed"
                Error   = $message
            }
        }
    }

    Write-Host ""
    Write-Host "Layout execution summary"
    Write-Host "================================"
    Write-Host "Created: $created"
    Write-Host "Failed : $failed"

    if ($results.Count -gt 0) {
        Write-Host ""
        $results |
            Format-Table Element, Type, ObjectId, Status -AutoSize
    }

    if ($failed -gt 0) {
        throw ($errors -join [Environment]::NewLine)
    }
}

