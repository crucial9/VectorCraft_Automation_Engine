function Test-ContentFit {
    param(
        [Parameter(Mandatory)]
        [object]$Design,

        [Parameter(Mandatory)]
        [object]$Content
    )

    # 1. Canvas Printable Height Calculation (in mm)
    $canvasHeight = [double]$Design.canvas.height
    $marginTop = [double]$Design.margins.top
    $marginBottom = [double]$Design.margins.bottom
    $printableHeightMM =$canvasHeight - ($marginTop +$marginBottom)

    # Convert mm to Points (1 mm = 2.83465 pt)
    $printableHeightPt =$printableHeightMM * 2.83465

    # 2. Extract Typographic Constraints
    $minFont = [double]$Design.constraints.bodyFontSize.min
    $prefFont = [double]$Design.constraints.bodyFontSize.preferred
    $maxFont = [double]$Design.constraints.bodyFontSize.max

    $minLH = [double]$Design.constraints.lineHeightRatio.min
    $prefLH = [double]$Design.constraints.lineHeightRatio.preferred

    # 3. Calculate Total Estimated Lines from Content Groups
    $totalLines = 0
    foreach ($group in$Content.groups) {
        $totalLines += [int]$group.estimatedLines
    }

    # 4. Simulate Space Requirements
    # Preferred Scenario
    $prefLineHeightPt =$prefFont * $prefLH$neededHeightPref = $totalLines * $prefLineHeightPt

    # Compact/Minimum Scenario
    $minLineHeightPt =$minFont * $minLH$neededHeightMin = $totalLines * $minLineHeightPt

    # 5. Analysis & Decision
    $status = "OK"
    $suggestedFontSize = $prefFont$occupancyRatio = [math]::Round(($neededHeightPref / $printableHeightPt) * 100, 2)

    if ($neededHeightPref -gt$printableHeightPt) {
        if ($neededHeightMin -le $printableHeightPt) {$status = "ADJUSTED_TO_FIT"
            $suggestedFontSize =$minFont
        } else {
            $status = "OVERFLOW"
        }
    } elseif ($occupancyRatio -lt 40) {$status = "UNDERFLOW_EXPANDABLE"
        $suggestedFontSize =$maxFont
    }

    return [PSCustomObject]@{
        PrintableHeightPt = [math]::Round($printableHeightPt, 2)
        NeededHeightPt    = [math]::Round($neededHeightPref, 2)
        OccupancyRatio    = "$occupancyRatio %"
        Status            = $status
        SuggestedFontSize = $suggestedFontSize
        TotalLines        = $totalLines
    }
}
