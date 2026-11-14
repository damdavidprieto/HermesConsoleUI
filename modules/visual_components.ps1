# HermesConsoleUI - visual components.
#
# Lists, trees, charts, sparklines, panels, boxes and tables.
# Every color parameter defaults to the active theme (see Set-ConsoleTheme).

function Show-ConsoleList {
    <#
    .SYNOPSIS
        Displays a bulleted or numbered list.

    .DESCRIPTION
        Writes one line per item, prefixed with a bullet or, with -Numbered, with its
        position. Lines longer than -Width are cut. With -ReturnLines the lines are returned
        instead of written, so the list can be placed inside a layout column or a panel.

    .PARAMETER Items
        The items to list. Each item is converted to text.

    .PARAMETER Numbered
        Number the items (1., 2., 3.) instead of using a bullet.

    .PARAMETER Bullet
        Bullet text used when -Numbered is not set. Defaults to a round bullet.

    .PARAMETER Color
        Console color for the items. Defaults to the theme's Highlight color.

    .PARAMETER Width
        Maximum line length, including the prefix. 0 or less disables the limit. Defaults to 40.

    .PARAMETER ReturnLines
        Return the formatted lines instead of writing them to the console.

    .EXAMPLE
        Show-ConsoleList -Items "Apples", "Pears", "Plums"

        Displays three bulleted items.

    .EXAMPLE
        Get-Service | Select-Object -First 5 -ExpandProperty Name | ForEach-Object { $_ } |
            Show-ConsoleList -Numbered

        Displays the first five service names as a numbered list.

    .EXAMPLE
        $lines = Show-ConsoleList -Items "One", "Two" -ReturnLines

        Returns the two formatted lines without writing them.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [object[]]$Items,

        [switch]$Numbered,

        [string]$Bullet = [string][char]0x2022,

        [string]$Color,

        [int]$Width = 40,

        [switch]$ReturnLines
    )

    begin {
        $all = [System.Collections.Generic.List[object]]::new()
    }
    process {
        foreach ($item in $Items) { $all.Add($item) }
    }
    end {
        if ($all.Count -eq 0) {
            if ($ReturnLines) { return @() }
            return
        }
        $lines = for ($i = 0; $i -lt $all.Count; $i++) {
            $prefix = if ($Numbered) { ($i + 1).ToString() + '. ' } else { $Bullet + ' ' }
            $fullLine = $prefix + [string]$all[$i]
            if ($Width -gt 0 -and $fullLine.Length -gt $Width) { $fullLine = $fullLine.Substring(0, $Width) }
            $fullLine
        }

        if ($ReturnLines) { return @($lines) }

        $Color = Resolve-UIColor -Color $Color -Role Highlight
        foreach ($l in $lines) { Write-HermesHost "  $l" -ForegroundColor $Color }
    }
}

function Write-ConsoleTree {
    <#
    .SYNOPSIS
        Displays a hashtable as a tree.

    .DESCRIPTION
        Writes each key as a branch. A value that is a hashtable becomes a nested branch;
        a string or an array becomes leaves under its key. Use ordered hashtables
        ([ordered]@{}) to control the order of the branches.

    .PARAMETER TreeData
        The tree to display: keys are branch names, values are nested hashtables, strings or arrays.

    .PARAMETER Indent
        Text placed before every line of the top level. Nested levels add to it. Defaults to two spaces.

    .EXAMPLE
        Write-ConsoleTree -TreeData ([ordered]@{ src = [ordered]@{ Core = "Config.ps1", "Localization.ps1" }; tests = "Unit" })

        Displays:
          ├── src
          │   ├── Core
          │   │   └── Config.ps1
          │   │   └── Localization.ps1
          ├── tests
          │   └── Unit
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$TreeData,

        [string]$Indent = '  '
    )

    $branchColor = Resolve-UIColor -Role Primary
    $leafColor = Resolve-UIColor -Role Muted
    $branch = [string][char]0x251C + [char]0x2500 + [char]0x2500 + ' '
    $leaf = [string][char]0x2514 + [char]0x2500 + [char]0x2500 + ' '
    $pipe = [string][char]0x2502 + '   '

    foreach ($key in $TreeData.Keys) {
        Write-HermesHost ($Indent + $branch + $key) -ForegroundColor $branchColor
        $val = $TreeData[$key]
        if ($val -is [System.Collections.IDictionary]) {
            Write-ConsoleTree -TreeData $val -Indent ($Indent + $pipe)
        }
        elseif ($null -ne $val) {
            foreach ($item in @($val)) {
                Write-HermesHost ($Indent + $pipe + $leaf + $item) -ForegroundColor $leafColor
            }
        }
    }
}

function Write-ConsoleChart {
    <#
    .SYNOPSIS
        Displays a value as a horizontal bar with its percentage.

    .DESCRIPTION
        Writes "Label: NN% [bar]", where the bar is filled in proportion to Value / Max.
        Values above Max show a full bar. With -ReturnLines the line is returned instead of
        written, for use in layouts and panels.

    .PARAMETER Label
        Text shown before the percentage.

    .PARAMETER Value
        The current value, 0 or more.

    .PARAMETER Max
        The value that represents 100%. Defaults to 100.

    .PARAMETER Color
        Console color for the percentage and bar. Defaults to the theme's Success color.

    .PARAMETER Width
        Number of characters in the bar. Defaults to 20.

    .PARAMETER ReturnLines
        Return the formatted line instead of writing it to the console.

    .EXAMPLE
        Write-ConsoleChart -Label "CPU" -Value 45

        Displays "CPU: 45% [█████████░░░░░░░░░░░]".

    .EXAMPLE
        Write-ConsoleChart -Label "Memory" -Value 6144 -Max 8192 -Color Yellow

        Displays memory use as 75% of 8192, in yellow.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Value,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$Max = 100,

        [string]$Color,

        [ValidateRange(1, 200)]
        [int]$Width = 20,

        [switch]$ReturnLines
    )

    $percent = [Math]::Round(($Value / $Max) * 100)
    $filledLen = [Math]::Max(0, [Math]::Min($Width, [Math]::Floor(($Value / $Max) * $Width)))
    $bar = ([string][char]0x2588 * $filledLen) + ([string][char]0x2591 * ($Width - $filledLen))

    if ($ReturnLines) { return @("${Label}: $percent% [$bar]") }

    Write-HermesHost ('  ' + $Label) -NoNewline -ForegroundColor (Resolve-UIColor -Role Highlight)
    Write-HermesHost (': ' + $percent + '% [' + $bar + ']') -ForegroundColor (Resolve-UIColor -Color $Color -Role Success)
}

function Write-ConsoleSparkline {
    <#
    .SYNOPSIS
        Displays a series of numbers as an inline mini chart.

    .DESCRIPTION
        Draws one block character per value, from the lowest (shortest block) to the
        highest (full block), to show a trend in a single line. With -ShowMinMax the
        lowest values use the theme's Error color and the highest its Success color.

    .PARAMETER Data
        The numbers to draw, in order.

    .PARAMETER Color
        Console color for the sparkline. Defaults to the theme's Primary color.

    .PARAMETER ShowMinMax
        Color the minimum and maximum values differently.

    .EXAMPLE
        Write-ConsoleSparkline -Data 3, 5, 2, 8, 6, 9

        Displays a six-character sparkline.

    .EXAMPLE
        Write-ConsoleSparkline -Data (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 10).CounterSamples.CookedValue -ShowMinMax

        Displays ten CPU samples, highlighting the lowest and highest.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [double[]]$Data,

        [string]$Color,

        [switch]$ShowMinMax
    )

    $Color = Resolve-UIColor -Color $Color -Role Primary
    $chars = 0x2581..0x2588 | ForEach-Object { [string][char]$_ }
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    $range = $max - $min

    if (-not $ShowMinMax -or $range -eq 0) {
        $sparkline = foreach ($value in $Data) {
            if ($range -eq 0) { $chars[4] } else { $chars[[int][Math]::Floor((($value - $min) / $range) * 7)] }
        }
        Write-HermesHost ('  ' + (-join $sparkline)) -ForegroundColor $Color
        return
    }

    Write-HermesHost '  ' -NoNewline
    foreach ($value in $Data) {
        $char = $chars[[int][Math]::Floor((($value - $min) / $range) * 7)]
        $valueColor = if ($value -eq $min) { Resolve-UIColor -Role Error } elseif ($value -eq $max) { Resolve-UIColor -Role Success } else { $Color }
        Write-HermesHost $char -NoNewline -ForegroundColor $valueColor
    }
    Write-HermesHost ''
}

function Write-ConsolePanel {
    <#
    .SYNOPSIS
        Displays the output of a script block inside a bordered panel.

    .DESCRIPTION
        Runs -Content and draws a border around the strings it returns, with an optional
        title in the top border. Lines longer than the panel are cut. Only returned output
        is captured: text the script block writes with Write-Host appears outside the panel,
        so use components with -ReturnLines (or plain strings) inside it.
        The script block runs with your permissions; do not build it from untrusted input.

    .PARAMETER Title
        Optional title shown in the top border.

    .PARAMETER Content
        Script block whose output becomes the panel lines.

    .PARAMETER BorderStyle
        Border characters: Single (default), Double, Rounded or Heavy.

    .PARAMETER Color
        Console color for the border. Defaults to the theme's Primary color.

    .PARAMETER Width
        Total panel width, from 20 to 120. Defaults to 60.

    .EXAMPLE
        Write-ConsolePanel -Title "Status" -Content { "Service: running"; "Uptime: 3 days" }

        Displays the two lines inside a single-line border titled "Status".

    .EXAMPLE
        Write-ConsolePanel -BorderStyle Rounded -Content { Show-ConsoleList -Items "a", "b" -ReturnLines }

        Displays a list inside a rounded panel.
    #>
    [CmdletBinding()]
    param(
        [string]$Title = '',

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [scriptblock]$Content,

        [ValidateSet('Single', 'Double', 'Rounded', 'Heavy')]
        [string]$BorderStyle = 'Single',

        [string]$Color,

        [ValidateRange(20, 120)]
        [int]$Width = 60
    )

    $Color = Resolve-UIColor -Color $Color -Role Primary
    $borders = @{
        Single  = 0x250C, 0x2510, 0x2514, 0x2518, 0x2500, 0x2502
        Double  = 0x2554, 0x2557, 0x255A, 0x255D, 0x2550, 0x2551
        Rounded = 0x256D, 0x256E, 0x2570, 0x256F, 0x2500, 0x2502
        Heavy   = 0x250F, 0x2513, 0x2517, 0x251B, 0x2501, 0x2503
    }
    $topLeft, $topRight, $bottomLeft, $bottomRight, $horizontal, $vertical = $borders[$BorderStyle] | ForEach-Object { [string][char]$_ }
    $innerWidth = $Width - 4

    Write-HermesHost ''
    if ($Title) {
        $titleText = if ($Title.Length -gt ($Width - 6)) { $Title.Substring(0, $Width - 6) } else { $Title }
        $leftLen = [Math]::Floor(($Width - $titleText.Length - 4) / 2)
        $rightLen = $Width - $titleText.Length - 4 - $leftLen
        Write-HermesHost ('  ' + $topLeft + ($horizontal * $leftLen) + ' ' + $titleText + ' ' + ($horizontal * $rightLen) + $topRight) -ForegroundColor $Color
    }
    else {
        Write-HermesHost ('  ' + $topLeft + ($horizontal * ($Width - 2)) + $topRight) -ForegroundColor $Color
    }

    $contentLines = @(& $Content | ForEach-Object { ([string]$_) -split "`n" })
    if ($contentLines.Count -eq 0) { $contentLines = @('') }
    foreach ($line in $contentLines) {
        $trimmed = (ConvertTo-ConsoleSafeText -Text $line).TrimEnd() -replace "`t", '    '
        if ($trimmed.Length -gt $innerWidth) { $trimmed = $trimmed.Substring(0, $innerWidth) }
        Write-HermesHost ('  ' + $vertical + ' ') -NoNewline -ForegroundColor $Color
        Write-HermesHost $trimmed -NoNewline
        Write-HermesHost (' ' * ($innerWidth - $trimmed.Length) + ' ' + $vertical) -ForegroundColor $Color
    }

    Write-HermesHost ('  ' + $bottomLeft + ($horizontal * ($Width - 2)) + $bottomRight) -ForegroundColor $Color
    Write-HermesHost ''
}

function Write-ConsoleBox {
    <#
    .SYNOPSIS
        Displays a message inside an ASCII box.

    .DESCRIPTION
        Draws a "+---+" box around the message. Each line of a multi-line message becomes a
        line in the box. By default the box fits the longest line; with -Width longer lines
        are cut. ASCII borders render in every console font.

    .PARAMETER Message
        The text to put in the box. Line breaks start new lines.

    .PARAMETER Color
        Console color for the box. Defaults to the theme's Primary color.

    .PARAMETER Width
        Total box width. 0 (the default) sizes the box to the message.

    .PARAMETER ReturnLines
        Return the box lines instead of writing them to the console.

    .EXAMPLE
        Write-ConsoleBox -Message "Backup completed"

        Displays the message in a box sized to fit it.

    .EXAMPLE
        Write-ConsoleBox -Message "Line one`nLine two" -Width 30 -Color Yellow

        Displays a 30-character yellow box with two lines.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [string]$Color,

        [ValidateRange(0, 500)]
        [int]$Width = 0,

        [switch]$ReturnLines
    )

    $messageLines = @(($Message -replace "`r", '') -split "`n" | ForEach-Object { $_.Trim() })
    $boxWidth = if ($Width -gt 4) { $Width } else { (($messageLines | Measure-Object -Property Length -Maximum).Maximum) + 4 }
    $inner = $boxWidth - 4
    $border = '+' + ('-' * ($boxWidth - 2)) + '+'

    $lines = @($border)
    foreach ($msg in $messageLines) {
        $text = if ($msg.Length -gt $inner) { $msg.Substring(0, $inner) } else { $msg.PadRight($inner) }
        $lines += "| $text |"
    }
    $lines += $border

    if ($ReturnLines) { return $lines }

    $Color = Resolve-UIColor -Color $Color -Role Primary
    Write-HermesHost ''
    foreach ($l in $lines) { Write-HermesHost $l -ForegroundColor $Color }
    Write-HermesHost ''
}

function Write-ConsoleTable {
    <#
    .SYNOPSIS
        Displays objects as a table with fixed-width columns.

    .DESCRIPTION
        Writes a header row and one row per object. Each column reads one property and has
        a fixed width; longer values are cut so the columns stay aligned. Without -Columns,
        one 20-character column is created for each property of the first object.
        With -ColorMapProperty and -ColorMap, each row is colored according to the value of
        that property, for example green for "Running" and red for "Stopped".

    .PARAMETER Data
        The objects to display. Accepts pipeline input.

    .PARAMETER Columns
        Column definitions: hashtables (or objects) with Header, Property and Width.

    .PARAMETER Title
        Optional title shown above the table. Alias: Header.

    .PARAMETER ColorMapProperty
        Property whose value selects the row color from -ColorMap.

    .PARAMETER ColorMap
        Hashtable from property value to console color, used with -ColorMapProperty.

    .EXAMPLE
        Get-Service | Select-Object -First 5 | Write-ConsoleTable -Columns @(
            @{ Header = "Name"; Property = "Name"; Width = 25 }
            @{ Header = "Status"; Property = "Status"; Width = 10 }
        ) -ColorMapProperty Status -ColorMap @{ Running = "Green"; Stopped = "Red" }

        Displays five services with running ones in green and stopped ones in red.

    .EXAMPLE
        Write-ConsoleTable -Data (Get-ChildItem -File | Select-Object Name, Length) -Title "Files"

        Displays the files with one column per property.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [AllowNull()]
        [object[]]$Data,

        [object[]]$Columns,

        [Alias('Header')]
        [string]$Title = '',

        [string]$ColorMapProperty = '',

        [hashtable]$ColorMap = @{}
    )

    begin {
        $rows = [System.Collections.Generic.List[object]]::new()
    }
    process {
        foreach ($item in $Data) { if ($null -ne $item) { $rows.Add($item) } }
    }
    end {
        if ($rows.Count -eq 0) {
            Write-HermesHost ('  ' + (Get-UIText -Key 'Table.NoData' -Default '(No data to display)')) -ForegroundColor (Resolve-UIColor -Role Muted)
            return
        }

        if (-not $Columns) {
            $Columns = @($rows[0].PSObject.Properties | ForEach-Object { @{ Header = $_.Name; Property = $_.Name; Width = 20 } })
        }

        $headerColor = Resolve-UIColor -Role Secondary
        $rowColor = Resolve-UIColor -Role Highlight

        Write-HermesHost ''
        if ($Title) { Write-HermesHost ('  ' + $Title) -ForegroundColor (Resolve-UIColor -Role Primary) }

        $header = foreach ($col in $Columns) { Format-TableCell -Value $col.Header -Width $col.Width }
        Write-HermesHost ('  ' + (-join $header)) -ForegroundColor $headerColor

        foreach ($row in $rows) {
            $color = $rowColor
            if ($ColorMapProperty) {
                $key = [string]$row.$ColorMapProperty
                if ($ColorMap.ContainsKey($key)) { $color = $ColorMap[$key] }
            }
            $cells = foreach ($col in $Columns) { Format-TableCell -Value $row.($col.Property) -Width $col.Width }
            Write-HermesHost ('  ' + (-join $cells)) -ForegroundColor $color
        }
        Write-HermesHost ''
    }
}

function Format-TableCell {
    <#
    .SYNOPSIS
        Pads or cuts a value to a column width, keeping one space between columns.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param($Value, [int]$Width)

    if ($Width -lt 2) { $Width = 2 }
    $text = (ConvertTo-ConsoleSafeText -Text ([string]$Value)) -replace '[\n\t]', ' '
    if ($text.Length -gt ($Width - 1)) { $text = $text.Substring(0, $Width - 1) }
    return $text.PadRight($Width)
}
