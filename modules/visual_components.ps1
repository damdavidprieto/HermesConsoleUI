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
        position. Lines longer than -Width are cut with an ellipsis. With -ReturnLines the lines are returned
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
            if ($Width -gt 0) { $fullLine = Format-ConsoleText -Text $fullLine -Width $Width }
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
        a string or an array becomes leaves under its key. The last item of each level is drawn
        with a corner and the others with a tee, and the vertical line stops after the last one.
        Use ordered hashtables ([ordered]@{}) to control the order of the branches. With
        -ReturnLines the lines are returned instead of written, for layouts and panels.

    .PARAMETER TreeData
        The tree to display: keys are branch names, values are nested hashtables, strings or arrays.

    .PARAMETER Indent
        Text placed before every line. Defaults to two spaces.

    .PARAMETER ReturnLines
        Return the tree lines instead of writing them to the console.

    .EXAMPLE
        Write-ConsoleTree -TreeData ([ordered]@{ src = [ordered]@{ Core = "Config.ps1", "Localization.ps1" }; tests = "Unit" })

        Displays:
          ├── src
          │   └── Core
          │       ├── Config.ps1
          │       └── Localization.ps1
          └── tests
              └── Unit
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$TreeData,

        [string]$Indent = '  ',

        [switch]$ReturnLines
    )

    $lines = [System.Collections.Generic.List[object]]::new()
    Add-ConsoleTreeLine -TreeData $TreeData -Prefix $Indent -Lines $lines
    if ($ReturnLines) { return @($lines | ForEach-Object { $_[0] }) }

    $colors = @{ Branch = Resolve-UIColor -Role Primary; Leaf = Resolve-UIColor -Role Muted }
    foreach ($line in $lines) { Write-HermesHost $line[0] -ForegroundColor $colors[$line[1]] }
}

function Add-ConsoleTreeLine {
    <#
    .SYNOPSIS
        Adds the lines of one tree level (text and kind, Branch or Leaf) to a list, for Write-ConsoleTree.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$TreeData,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Prefix,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Lines
    )

    $tee = [string][char]0x251C + [char]0x2500 + [char]0x2500 + ' '
    $corner = [string][char]0x2514 + [char]0x2500 + [char]0x2500 + ' '
    $pipe = [string][char]0x2502 + '   '
    $keys = @($TreeData.Keys)
    for ($k = 0; $k -lt $keys.Count; $k++) {
        $last = $k -eq $keys.Count - 1
        $Lines.Add(@(($Prefix + $(if ($last) { $corner } else { $tee }) + $keys[$k]), 'Branch'))
        $childPrefix = $Prefix + $(if ($last) { '    ' } else { $pipe })
        $value = $TreeData[$keys[$k]]
        if ($value -is [System.Collections.IDictionary]) {
            Add-ConsoleTreeLine -TreeData $value -Prefix $childPrefix -Lines $Lines
        }
        elseif ($null -ne $value) {
            $items = @($value)
            for ($n = 0; $n -lt $items.Count; $n++) {
                $Lines.Add(@(($childPrefix + $(if ($n -eq $items.Count - 1) { $corner } else { $tee }) + $items[$n]), 'Leaf'))
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
        Values above Max show a full bar. With -Thresholds the color depends on the percentage, for example
        red below 70, yellow below 100 and green at 100. With -ReturnLines the line is returned instead of
        written, for use in layouts and panels. Without -Label only the percentage and the bar are written.

    .PARAMETER Label
        Text shown before the percentage. Optional.

    .PARAMETER Value
        The current value, 0 or more.

    .PARAMETER Max
        The value that represents 100%. Defaults to 100.

    .PARAMETER Color
        Console color for the percentage and bar. Defaults to the theme's Success color.

    .PARAMETER Thresholds
        Colors by percentage: a hashtable from the lowest percentage of each color to the color, such as
        @{ 0 = 'Red'; 70 = 'Yellow'; 100 = 'Green' }. The color of the highest threshold reached is used;
        below all of them, -Color.

    .PARAMETER Style
        A style registered with Register-ConsoleStyle that colors the bar by its percentage, instead of -Thresholds.

    .PARAMETER Width
        Number of characters in the bar. Defaults to 20.

    .PARAMETER NoNewline
        Do not end the line, to write more after the bar.

    .PARAMETER ReturnLines
        Return the formatted line instead of writing it to the console.

    .EXAMPLE
        Write-ConsoleChart -Label "CPU" -Value 45

        Displays "CPU: 45% [█████████░░░░░░░░░░░]".

    .EXAMPLE
        Write-ConsoleChart -Label "Memory" -Value 6144 -Max 8192 -Color Yellow

        Displays memory use as 75% of 8192, in yellow.

    .EXAMPLE
        Write-ConsoleChart -Label "Compliance" -Value 82 -Thresholds @{ 0 = 'Red'; 70 = 'Yellow'; 100 = 'Green' }

        Displays the bar in yellow: 82% reaches 70 but not 100.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [AllowEmptyString()]
        [string]$Label = '',

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Value,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$Max = 100,

        [string]$Color,

        [System.Collections.IDictionary]$Thresholds,

        [string]$Style,

        [ValidateRange(1, 200)]
        [int]$Width = 20,

        [switch]$NoNewline,

        [switch]$ReturnLines
    )

    $percent = [Math]::Round(($Value / $Max) * 100)
    $filledLen = [Math]::Max(0, [Math]::Min($Width, [Math]::Floor(($Value / $Max) * $Width)))
    $bar = ([string][char]0x2588 * $filledLen) + ([string][char]0x2591 * ($Width - $filledLen))
    $prefix = if ($Label) { "${Label}: " } else { '' }

    if ($ReturnLines) { return @("$prefix$percent% [$bar]") }

    $barColor = Resolve-UIColor -Color $Color -Role Success
    if ($Thresholds) {
        $reached = @($Thresholds.Keys | Where-Object { ($_ -as [double]) -le $percent } | Sort-Object { [double]$_ } -Descending)
        if ($reached.Count) { $barColor = [string]$Thresholds[$reached[0]] }
    }
    if ($Style) {
        $styled = (Resolve-HermesStyleValue -Style (Get-HermesStyle -Name $Style) -Value $percent)[1]
        if ($styled) { $barColor = $styled }
    }
    if ($Label) { Write-HermesHost ('  ' + $Label + ': ') -NoNewline -ForegroundColor (Resolve-UIColor -Role Highlight) }
    else { Write-HermesHost '  ' -NoNewline }
    Write-HermesHost ([string]$percent + '% [' + $bar + ']') -ForegroundColor $barColor -NoNewline:$NoNewline
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
        title in the top border. Lines longer than the panel are cut with an ellipsis. Only returned output
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
        $trimmed = Format-ConsoleText -Text (((ConvertTo-ConsoleSafeText -Text $line).TrimEnd()) -replace "`t", '    ') -Width $innerWidth
        Write-HermesHost ('  ' + $vertical + ' ') -NoNewline -ForegroundColor $Color
        Write-HermesHost $trimmed -NoNewline
        Write-HermesHost (' ' * ($innerWidth - (Measure-ConsoleText -Text $trimmed)) + ' ' + $vertical) -ForegroundColor $Color
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
        are cut with an ellipsis. ASCII borders render in every console font.

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
    [OutputType([string[]], [object[]])]
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
    $longest = 0
    foreach ($msg in $messageLines) { $longest = [Math]::Max($longest, (Measure-ConsoleText -Text $msg)) }
    $boxWidth = if ($Width -gt 4) { $Width } else { $longest + 4 }
    $inner = $boxWidth - 4
    $border = '+' + ('-' * ($boxWidth - 2)) + '+'

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($border)
    foreach ($msg in $messageLines) { $lines.Add('| ' + (Format-ConsoleText -Text $msg -Width $inner -Align Left) + ' |') }
    $lines.Add($border)
    $lines = $lines.ToArray()

    if ($ReturnLines) { return $lines }

    $Color = Resolve-UIColor -Color $Color -Role Primary
    Write-HermesHost ''
    foreach ($l in $lines) { Write-HermesHost $l -ForegroundColor $Color }
    Write-HermesHost ''
}

function Write-ConsoleTable {
    <#
    .SYNOPSIS
        Displays objects as a table with aligned columns.

    .DESCRIPTION
        Writes a header row, a line under it and one row per object. Each column reads one
        property. A column with Width keeps that width; one without it is as wide as its longest
        value or header (up to the MaxColumnWidth of the theme configuration, 80 by default), and
        when the table does not fit in the console window the widest automatic columns are
        narrowed. Longer values are cut with an ellipsis so the columns stay aligned. Without -Columns,
        one column is created for each property of the first object.
        Columns whose values are all numbers are aligned to the right; set Align to Left or Right
        in a column definition to choose.
        A column definition can also have Map, a hashtable that replaces values by the text to show
        (for example Compliant by "OK"), and Colors, a hashtable from value to the color of that cell:
        states then read as words, not only as colors. Style, the name of a style registered with
        Register-ConsoleStyle, gives both at once, also for numbers with thresholds.
        With -ColorMapProperty and -ColorMap, each row is colored according to the value of
        that property, for example green for "Running" and red for "Stopped".

    .PARAMETER Data
        The objects to display. Accepts pipeline input.

    .PARAMETER Columns
        Column definitions: hashtables (or objects) with Header and Property, and optionally Width
        (characters, including the space before the next column), Align (Left or Right), Map (value to
        text shown), Colors (value to cell color) and Style (a registered style for both).

    .PARAMETER Title
        Optional title shown above the table. Alias: Header.

    .PARAMETER ColorMapProperty
        Property whose value selects the row color from -ColorMap.

    .PARAMETER ColorMap
        Hashtable from property value to console color, used with -ColorMapProperty.

    .PARAMETER ReturnLines
        Return the lines of the table (header, rule and rows, without colors) instead of writing them, for
        panels and layouts.

    .EXAMPLE
        Get-Service | Select-Object -First 5 | Write-ConsoleTable -Columns @(
            @{ Header = "Name"; Property = "Name"; Width = 25 }
            @{ Header = "Status"; Property = "Status"; Width = 10 }
        ) -ColorMapProperty Status -ColorMap @{ Running = "Green"; Stopped = "Red" }

        Displays five services with running ones in green and stopped ones in red.

    .EXAMPLE
        Write-ConsoleTable -Data $results -Columns @(
            @{ Header = 'Rule'; Property = 'Name' }
            @{ Header = 'State'; Property = 'Status'; Map = @{ Compliant = 'OK'; NonCompliant = 'Pending' }; Colors = @{ Compliant = 'Green'; NonCompliant = 'Red' } }
        )

        Shows each state as a word in its own color.

    .EXAMPLE
        Write-ConsoleTable -Data (Get-ChildItem -File | Select-Object Name, Length) -Title "Files"

        Displays the files with one column per property.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [AllowNull()]
        [object[]]$Data,

        [object[]]$Columns,

        [Alias('Header')]
        [string]$Title = '',

        [string]$ColorMapProperty = '',

        [hashtable]$ColorMap = @{},

        [switch]$ReturnLines
    )

    begin {
        $rows = [System.Collections.Generic.List[object]]::new()
    }
    process {
        foreach ($item in $Data) { if ($null -ne $item) { $rows.Add($item) } }
    }
    end {
        if ($rows.Count -eq 0) {
            $empty = '  ' + (Get-UIText -Key 'Table.NoData' -Default '(No data to display)')
            if ($ReturnLines) { return @($empty.TrimStart()) }
            Write-HermesHost $empty -ForegroundColor (Resolve-UIColor -Role Muted)
            return
        }

        if (-not $Columns) {
            $Columns = @($rows[0].PSObject.Properties | ForEach-Object { @{ Header = $_.Name; Property = $_.Name } })
        }
        $Columns = @(Resolve-TableColumn -Columns $Columns -Rows $rows)
        $ellipsis = [string][char]0x2026

        $header = -join @(foreach ($col in $Columns) { Format-TableCell -Value $col.Header -Width $col.Width -Align $col.Align })
        $rule = (-join @(foreach ($col in $Columns) { ('-' * ($col.Width - 1)) + ' ' })).TrimEnd()

        # The cell texts were cleaned once by Resolve-TableColumn; here they are only cut and padded.
        $cellText = {
            param($col, [int]$r)
            $text = $col.Texts[$r]
            $room = $col.Width - 1
            if ($col.Wide) { return (Format-ConsoleText -Text $text -Width $room -Align $(if ($col.Align -eq 'Right') { 'Right' } else { 'Left' })) + ' ' }
            if ($text.Length -gt $room) { $text = $text.Substring(0, $room - 1) + $ellipsis }
            if ($col.Align -eq 'Right') { return $text.PadLeft($room) + ' ' }
            return $text.PadRight($col.Width)
        }

        if ($ReturnLines) {
            $out = [System.Collections.Generic.List[string]]::new()
            if ($Title) { $out.Add($Title) }
            $out.Add($header.TrimEnd()); $out.Add($rule)
            for ($r = 0; $r -lt $rows.Count; $r++) { $out.Add((-join @(foreach ($col in $Columns) { & $cellText $col $r })).TrimEnd()) }
            return $out.ToArray()
        }

        $headerColor = Resolve-UIColor -Role Secondary
        $rowColor = Resolve-UIColor -Role Highlight
        $cellColors = @($Columns | Where-Object { $_.CellColors }).Count -gt 0

        Write-HermesHost ''
        if ($Title) { Write-HermesHost ('  ' + $Title) -ForegroundColor (Resolve-UIColor -Role Primary) }
        Write-HermesHost ('  ' + $header) -ForegroundColor $headerColor
        Write-HermesHost ('  ' + $rule) -ForegroundColor (Resolve-UIColor -Role Muted)

        $line = [System.Text.StringBuilder]::new()
        for ($r = 0; $r -lt $rows.Count; $r++) {
            $color = $rowColor
            if ($ColorMapProperty) {
                $key = [string]$rows[$r].$ColorMapProperty
                if ($ColorMap.ContainsKey($key)) { $color = $ColorMap[$key] }
            }
            if ($cellColors) {
                # Cells with their own color: one write per cell.
                Write-HermesHost '  ' -NoNewline
                foreach ($col in $Columns) {
                    $cellColor = $color
                    if ($col.CellColors -and $col.CellColors[$r]) { $cellColor = $col.CellColors[$r] }
                    Write-HermesHost (& $cellText $col $r) -NoNewline -ForegroundColor $cellColor
                }
                Write-HermesHost ''
                continue
            }
            # The same as $cellText, written out: a script block call per cell would double the time of a large table.
            $null = $line.Clear().Append('  ')
            foreach ($col in $Columns) {
                if ($col.Wide) { $null = $line.Append((& $cellText $col $r)); continue }
                $text = $col.Texts[$r]
                $room = $col.Width - 1
                if ($text.Length -gt $room) { $text = $text.Substring(0, $room - 1) + $ellipsis }
                if ($col.Align -eq 'Right') { $null = $line.Append($text.PadLeft($room)).Append(' ') }
                else { $null = $line.Append($text.PadRight($col.Width)) }
            }
            Write-HermesHost $line.ToString() -ForegroundColor $color
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
    param($Value, [int]$Width, [string]$Align = 'Left')

    if ($Width -lt 2) { $Width = 2 }
    $side = if ($Align -eq 'Right') { 'Right' } else { 'Left' }
    return (Format-ConsoleText -Text ([string]$Value) -Width ($Width - 1) -Align $side) + ' '
}

function Resolve-TableColumn {
    <#
    .SYNOPSIS
        Completes the column definitions of Write-ConsoleTable: width and alignment.
    .DESCRIPTION
        Columns without Width get the length of their longest value or header plus one (at most
        the theme's MaxColumnWidth). Each column also gets Texts: its values for every row, as
        clean one-line text. If the table is wider than the console window, the widest
        automatic columns are narrowed, down to 6 characters. Columns without Align are aligned
        right when every value is a number.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject[]], [object[]])]
    param(
        [Parameter(Mandatory = $true)][object[]]$Columns,
        [Parameter(Mandatory = $true)][object[]]$Rows
    )

    $maxWidth = 80
    $configured = Get-UIConfig -Section 'UILibrary.Components.Table.MaxColumnWidth' -WarningAction SilentlyContinue
    if ($configured -as [int]) { $maxWidth = [int]$configured }
    $numeric = [type[]]@([byte], [sbyte], [int16], [uint16], [int], [uint32], [long], [uint64], [single], [double], [decimal])

    $resolved = foreach ($col in $Columns) {
        $property = Get-ColumnValue $col 'Property'
        $header = Get-ColumnValue $col 'Header'
        if ($null -eq $header) { $header = $property }
        # Each value is read and cleaned once: the texts are used for the width and for the rows.
        $map = Get-ColumnValue $col 'Map'
        $colors = Get-ColumnValue $col 'Colors'
        $styleName = Get-ColumnValue $col 'Style'
        $style = if ($styleName) { Get-HermesStyle -Name $styleName } else { $null }
        $cellColors = if ($colors -or $style) { [string[]]::new($Rows.Count) } else { $null }
        $texts = [string[]]::new($Rows.Count)
        $keys = [string[]]::new($Rows.Count)
        $longest = Measure-ConsoleText -Text ([string]$header)
        $allNumbers = $true; $present = 0; $wide = $false
        for ($r = 0; $r -lt $Rows.Count; $r++) {
            $value = $Rows[$r].$property
            if ($null -ne $value) { $present++; if ($numeric -notcontains $value.GetType()) { $allNumbers = $false } }
            $keys[$r] = [string]$value
            $text = if ($map -and $map.Contains($keys[$r])) { [string]$map[$keys[$r]] } else { $keys[$r] }
            if ($style) {
                $resolved = Resolve-HermesStyleValue -Style $style -Value $value
                if (-not ($map -and $map.Contains($keys[$r]))) { $text = [string]$resolved[0] }
                $cellColors[$r] = $resolved[1]
            }
            if ($colors -and $colors.Contains($keys[$r])) { $cellColors[$r] = Resolve-HermesSegmentColor -Color ([string]$colors[$keys[$r]]) }
            if ($script:HermesControlRegex.IsMatch($text)) { $text = ConvertTo-ConsoleSafeText -Text $text }
            $text = $text.Replace("`n", ' ').Replace("`t", ' ')
            $texts[$r] = $text
            $textWidth = $text.Length
            if ($script:HermesWideRegex.IsMatch($text)) { $wide = $true; $textWidth = Measure-ConsoleText -Text $text }
            if ($textWidth -gt $longest) { $longest = $textWidth }
        }
        if ($map -or ($style -and $style.Map.Count)) { $allNumbers = $false }
        $width = Get-ColumnValue $col 'Width'
        $auto = -not ($width -as [int])
        if ($auto) { $width = [Math]::Min([Math]::Max([int]$longest + 1, 4), $maxWidth) }
        if ([int]$width -lt 2) { $width = 2 }
        $align = Get-ColumnValue $col 'Align'
        if (-not $align) { $align = if ($present -and $allNumbers) { 'Right' } else { 'Left' } }
        [pscustomobject]@{ Header = $header; Property = $property; Width = [int]$width; Align = $align; Auto = $auto; Texts = $texts; Keys = $keys; CellColors = $cellColors; Wide = $wide }
    }
    $resolved = @($resolved)

    # Fit the console window: two spaces of indent, and the last column needs no trailing space.
    # The widest automatic column loses one character at a time, down to 6.
    $available = (Get-ConsoleWidth) - 3
    if ($available -gt 0) {
        $total = 0
        foreach ($col in $resolved) { $total += $col.Width }
        while ($total -gt $available) {
            $widest = $null
            foreach ($col in $resolved) { if ($col.Auto -and $col.Width -gt 6 -and ($null -eq $widest -or $col.Width -gt $widest.Width)) { $widest = $col } }
            if ($null -eq $widest) { break }
            $widest.Width--
            $total--
        }
    }
    return $resolved
}

function Get-ColumnValue {
    <#
    .SYNOPSIS
        Reads a setting from a column definition given as a hashtable or as an object.
    #>
    [CmdletBinding()]
    param($Column, [string]$Name)

    if ($Column -is [System.Collections.IDictionary]) { return $Column[$Name] }
    $property = $Column.PSObject.Properties[$Name]
    if ($property) { return $property.Value }
    return $null
}
