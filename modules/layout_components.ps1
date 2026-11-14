# HermesConsoleUI - layout components.
#
# Side-by-side columns: build a layout with New-ConsoleLayout, New-ConsoleRow and
# New-ConsoleColumn, then draw it with Write-ConsoleLayout.

function New-ConsoleLayout {
    <#
    .SYNOPSIS
        Creates a layout from rows of columns.

    .DESCRIPTION
        Returns a layout object (a hashtable with a Rows key) to pass to Write-ConsoleLayout.
        It only builds the object in memory; nothing is written until Write-ConsoleLayout runs.

    .PARAMETER Rows
        The rows of the layout, created with New-ConsoleRow, from top to bottom.

    .EXAMPLE
        $layout = New-ConsoleLayout -Rows @(
            New-ConsoleRow -Columns @(
                New-ConsoleColumn -WidthPercent 50 -Content { param($Width, [switch]$ReturnLines) Show-ConsoleList -Items "a", "b" -Width $Width -ReturnLines }
                New-ConsoleColumn -WidthPercent 50 -Content "Right column"
            )
        )
        Write-ConsoleLayout -Layout $layout

        Draws a list and a line of text side by side.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Only builds an object in memory; changes no system state.')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Rows
    )

    return @{ Rows = $Rows }
}

function New-ConsoleRow {
    <#
    .SYNOPSIS
        Creates a layout row from columns.

    .DESCRIPTION
        Returns a row object (a hashtable with a Columns key) for New-ConsoleLayout. The
        columns are drawn side by side; their WidthPercent values should add up to 100 or less.

    .PARAMETER Columns
        The columns of the row, created with New-ConsoleColumn, from left to right.

    .EXAMPLE
        New-ConsoleRow -Columns (New-ConsoleColumn -Content "Left" -WidthPercent 30), (New-ConsoleColumn -Content "Right" -WidthPercent 70)

        Creates a row with a narrow left column and a wide right column.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Only builds an object in memory; changes no system state.')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Columns
    )

    return @{ Columns = $Columns }
}

function New-ConsoleColumn {
    <#
    .SYNOPSIS
        Creates a layout column with its content and width.

    .DESCRIPTION
        Returns a column object for New-ConsoleRow. The content can be a string, an array of
        lines, or a script block. A script block is called with -Width (the column width in
        characters) and -ReturnLines, and must return the lines to show: components such as
        Show-ConsoleList, Write-ConsoleChart and Write-ConsoleBox support -ReturnLines.

    .PARAMETER Content
        A string, an array of lines, or a script block that returns lines.

    .PARAMETER WidthPercent
        Column width as a percentage of the layout width, from 1 to 100. Defaults to 50.

    .EXAMPLE
        New-ConsoleColumn -WidthPercent 40 -Content { param($Width, [switch]$ReturnLines) Write-ConsoleChart -Label "CPU" -Value 70 -Width ($Width - 15) -ReturnLines }

        Creates a column that shows a CPU bar sized to the column.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Only builds an object in memory; changes no system state.')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        $Content,

        [ValidateRange(1, 100)]
        [int]$WidthPercent = 50
    )

    return @{ Content = $Content; WidthPercent = $WidthPercent }
}

function Write-ConsoleLayout {
    <#
    .SYNOPSIS
        Draws a layout created with New-ConsoleLayout.

    .DESCRIPTION
        Draws each row with its columns side by side. Column widths are computed from their
        WidthPercent and -TotalWidth; longer lines are cut. If a column's script block
        throws, that column shows "Error rendering column" and the rest of the layout is drawn.

    .PARAMETER Layout
        The layout returned by New-ConsoleLayout.

    .PARAMETER TotalWidth
        Total width of the layout in characters, from 20 to 500. Defaults to 80.

    .EXAMPLE
        Write-ConsoleLayout -Layout $layout -TotalWidth 100

        Draws the layout 100 characters wide.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Layout,

        [ValidateRange(20, 500)]
        [int]$TotalWidth = 80
    )

    foreach ($row in $Layout.Rows) {
        $colOutputs = @()
        $colWidths = @()

        foreach ($col in $row.Columns) {
            $w = [Math]::Max(1, [Math]::Floor(($col.WidthPercent / 100) * $TotalWidth) - 1)
            $colWidths += $w

            $lines = @()
            if ($col.Content -is [scriptblock]) {
                try {
                    $lines = @(& $col.Content -Width $w -ReturnLines)
                }
                catch {
                    Write-Verbose "Layout column failed: $_"
                    $lines = @('Error rendering column')
                }
            }
            elseif ($null -ne $col.Content) {
                $lines = @($col.Content | ForEach-Object { [string]$_ })
            }

            if ($lines.Count -eq 0) { $lines = @('') }
            $colOutputs += , $lines
        }

        foreach ($l in (Merge-LayoutColumn -Columns $colOutputs -Widths $colWidths)) {
            Write-HermesHost "  $l"
        }
        Write-HermesHost ''
    }
}
