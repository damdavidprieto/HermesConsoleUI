# HermesConsoleUI - line components (2.8.0).
#
# Lines made of segments with their own color and width, named styles for values (states, levels,
# percentages), application layout settings, key-value lists, grids, captures to a file, waiting for Enter
# and sending Write-Host through the module.

# --- Layout settings ---------------------------------------------------------------------------------------

$script:HermesLayoutDefault = @{ MaxWidth = 0; Margin = 2; DefaultWidth = 0 }
$script:HermesLayout = $script:HermesLayoutDefault.Clone()

function Set-ConsoleLayout {
    <#
    .SYNOPSIS
        Sets the widest line, the left margin and the width to use when the console width is unknown.

    .DESCRIPTION
        An application sets these once and every component follows them:
        -MaxWidth caps the width the components use (Get-ConsoleWidth, tables, wrapped text, lines, rules),
        so long lines stay readable in a very wide window. -Margin is the indentation of Write-ConsoleLine,
        Write-ConsoleKeyValue, Write-ConsoleGrid, Wait-ConsoleKey and the left-aligned titles and compact headers.
        -DefaultWidth is the line width when the console width cannot be known (redirected output, a capture
        in a log). Only the parameters given change; -Reset goes back to the defaults (no maximum, margin 2,
        80 columns when unknown).

    .PARAMETER MaxWidth
        Widest line, in columns. 0 means the window width.

    .PARAMETER Margin
        Spaces before the text of the line components.

    .PARAMETER DefaultWidth
        Line width when the console width is unknown. 0 means 80.

    .PARAMETER Reset
        Go back to the defaults.

    .EXAMPLE
        Set-ConsoleLayout -MaxWidth 110 -Margin 2 -DefaultWidth 100

        Lines are at most 110 columns wide, indented by two spaces, and 100 wide in a log.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [ValidateRange(0, 1000)]
        [int]$MaxWidth,

        [ValidateRange(0, 40)]
        [int]$Margin,

        [ValidateRange(0, 1000)]
        [int]$DefaultWidth,

        [switch]$Reset
    )

    if (-not $PSCmdlet.ShouldProcess('HermesConsoleUI layout', 'Set')) { return }
    if ($Reset) { $script:HermesLayout = $script:HermesLayoutDefault.Clone() }
    foreach ($name in 'MaxWidth', 'Margin', 'DefaultWidth') {
        if ($PSBoundParameters.ContainsKey($name)) { $script:HermesLayout[$name] = [int]$PSBoundParameters[$name] }
    }
}

function Get-ConsoleLayout {
    <#
    .SYNOPSIS
        Returns the layout settings (Set-ConsoleLayout) and the line width they give now.

    .DESCRIPTION
        MaxWidth, Margin and DefaultWidth as set with Set-ConsoleLayout, and LineWidth: the columns a line can
        use in the current window with those settings, as the line components use it.

    .EXAMPLE
        (Get-ConsoleLayout).LineWidth

        The columns a line can use in this window.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        MaxWidth     = $script:HermesLayout.MaxWidth
        Margin       = $script:HermesLayout.Margin
        DefaultWidth = $script:HermesLayout.DefaultWidth
        LineWidth    = Get-HermesLineWidth
    }
}

function Get-HermesLineWidth {
    <#
    .SYNOPSIS
        Columns a line can use: one less than the window (writing the last column moves the cursor to the next
        line in some consoles), at most the layout MaxWidth; the layout DefaultWidth, or 80, when unknown.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param()

    $window = Get-ConsoleWidth -Maximum 0 -Default 0
    $width = if ($window -le 0) { if ($script:HermesLayout.DefaultWidth -gt 0) { $script:HermesLayout.DefaultWidth } else { 80 } } else { $window - 1 }
    if ($script:HermesLayout.MaxWidth -gt 0 -and $width -gt $script:HermesLayout.MaxWidth) { $width = $script:HermesLayout.MaxWidth }
    return [Math]::Max($width, 20)
}

function Get-HermesMargin {
    <#
    .SYNOPSIS
        The indentation given, or the layout margin when it is negative (the default of the line components).
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param([int]$Indent = -1)

    if ($Indent -ge 0) { return $Indent }
    return [int]$script:HermesLayout.Margin
}

# --- Named styles ------------------------------------------------------------------------------------------

$script:HermesStyles = @{}

function Register-ConsoleStyle {
    <#
    .SYNOPSIS
        Names a set of values with the word and the color to show for each, to use in lines, tables and charts.

    .DESCRIPTION
        A style turns a value into what the user reads: Compliant into "OK" in green, a percentage into a
        color. Lines (Write-ConsoleLine), key-value lists, tables (a column with Style) and charts (-Style) look
        values up by the style name, so the words and colors of an application are defined once.
        -Map gives each value its text and color: a string (the text), an array (text, color) or a hashtable
        with Text and Color. Values are matched as text, ignoring case.
        -Thresholds colors numbers: the color of the highest threshold that the value reaches; the text is the
        value itself, written with -Format.
        -Default is used for any other value: a string (the color, the value is shown as is), an array
        (text, color) or a hashtable with Text and Color.
        Registering a name again replaces it.

    .PARAMETER Name
        Name of the style.

    .PARAMETER Map
        Value to text and color.

    .PARAMETER Thresholds
        Lowest number to color, for numbers: @{ 0 = 'Red'; 70 = 'Yellow'; 100 = 'Green' }.

    .PARAMETER Default
        Text and color for values not in -Map or -Thresholds.

    .PARAMETER Format
        Format of a number shown with -Thresholds, such as '{0} %'. Defaults to the number as is.

    .EXAMPLE
        Register-ConsoleStyle -Name State -Map @{
            Compliant    = 'OK', 'Green'
            NonCompliant = 'Pending', 'Red'
        } -Default 'Unknown', 'DarkYellow'

        Write-ConsoleLine @{ Value = $result.Status; Style = 'State' }, $result.Title

    .EXAMPLE
        Register-ConsoleStyle -Name Percent -Thresholds @{ 0 = 'Red'; 70 = 'Yellow'; 100 = 'Green' } -Format '{0} %'
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [System.Collections.IDictionary]$Map,

        [System.Collections.IDictionary]$Thresholds,

        [object]$Default,

        [string]$Format = '{0}'
    )

    if (-not $PSCmdlet.ShouldProcess($Name, 'Register console style')) { return }
    $entries = [System.Collections.Generic.Dictionary[string, object[]]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $width = 0
    if ($Map) {
        foreach ($key in $Map.Keys) {
            $entry = ConvertTo-HermesStyleEntry -Value $Map[$key] -TextIsDefault
            $entries[[string]$key] = $entry
            $width = [Math]::Max($width, (Measure-ConsoleText -Text ([string]$entry[0])))
        }
    }
    $limits = @()
    if ($Thresholds) {
        $limits = @(foreach ($key in $Thresholds.Keys) {
                $number = $key -as [double]
                if ($null -eq $number) { throw [System.ArgumentException]::new("Threshold '$key' of style '$Name' is not a number.") }
                , @($number, (Resolve-HermesSegmentColor -Color ([string]$Thresholds[$key])))
            }) | Sort-Object { $_[0] } -Descending
    }
    $fallback = $null
    if ($null -ne $Default) {
        $fallback = ConvertTo-HermesStyleEntry -Value $Default
        if ($fallback[0]) { $width = [Math]::Max($width, (Measure-ConsoleText -Text ([string]$fallback[0]))) }
    }
    $script:HermesStyles[$Name] = @{ Name = $Name; Map = $entries; Thresholds = @($limits); Default = $fallback; Format = $Format; Width = $width }
}

function ConvertTo-HermesStyleEntry {
    <#
    .SYNOPSIS
        Reads a style entry (string, array or hashtable) as @(text, color). A lone string is the text with
        -TextIsDefault (in -Map) and the color otherwise (in -Default).
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param([AllowNull()][object]$Value, [switch]$TextIsDefault)

    if ($Value -is [System.Collections.IDictionary] -or $Value -is [pscustomobject]) {
        return , @((Get-ColumnValue $Value 'Text'), (Resolve-HermesSegmentColor -Color ([string](Get-ColumnValue $Value 'Color'))))
    }
    if ($Value -is [System.Collections.IList]) {
        $items = @($Value)
        $color = if ($items.Count -gt 1) { Resolve-HermesSegmentColor -Color ([string]$items[1]) } else { $null }
        return , @($items[0], $color)
    }
    if ($TextIsDefault) { return , @([string]$Value, $null) }
    return , @($null, (Resolve-HermesSegmentColor -Color ([string]$Value)))
}

function Unregister-ConsoleStyle {
    <#
    .SYNOPSIS
        Removes a style registered with Register-ConsoleStyle.

    .DESCRIPTION
        Lines, tables and charts that name the style fail afterwards, as with any unknown style.

    .PARAMETER Name
        Name of the style.

    .EXAMPLE
        Unregister-ConsoleStyle -Name State
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true, Position = 0)][string]$Name)

    if (-not $PSCmdlet.ShouldProcess($Name, 'Remove console style')) { return }
    $null = $script:HermesStyles.Remove($Name)
}

function Get-ConsoleStyle {
    <#
    .SYNOPSIS
        Lists the registered styles, describes one, or returns the text and color a style gives a value.

    .DESCRIPTION
        Without -Name, returns the names of the registered styles. With -Name, returns the style: its name,
        the width of its widest text (the width a column of it takes) and its values. With -Value too, returns
        the Text and Color the style gives that value, for output the module does not draw.

    .PARAMETER Name
        Name of the style.

    .PARAMETER Value
        A value to look up in the style.

    .EXAMPLE
        Get-ConsoleStyle -Name State -Value NonCompliant

        Text = Pending, Color = Red.
    #>
    [CmdletBinding()]
    [OutputType([string[]], [pscustomobject], [object[]])]
    param(
        [Parameter(Position = 0)]
        [string]$Name,

        [Parameter(Position = 1)]
        [AllowNull()]
        [AllowEmptyString()]
        [object]$Value
    )

    if (-not $Name) { return @($script:HermesStyles.Keys | Sort-Object) }
    $style = Get-HermesStyle -Name $Name
    if ($PSBoundParameters.ContainsKey('Value')) {
        $resolved = Resolve-HermesStyleValue -Style $style -Value $Value
        return [pscustomobject]@{ Text = $resolved[0]; Color = $resolved[1] }
    }
    [pscustomobject]@{ Name = $style.Name; Width = $style.Width; Values = @($style.Map.Keys) }
}

function Get-HermesStyle {
    <#
    .SYNOPSIS
        A registered style by name; an unknown name is an error in the calling script.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Name)

    $style = $script:HermesStyles[$Name]
    if (-not $style) { throw [System.ArgumentException]::new("The console style '$Name' is not registered (Register-ConsoleStyle).") }
    return $style
}

function Resolve-HermesStyleValue {
    <#
    .SYNOPSIS
        The text and color (@(text, color)) a style gives a value.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param([Parameter(Mandatory = $true)][hashtable]$Style, [AllowNull()][object]$Value)

    $key = [string]$Value
    if ($Style.Map.ContainsKey($key)) { return , $Style.Map[$key] }
    $number = $Value -as [double]
    if ($Style.Thresholds.Count -and $null -ne $number -and $key -ne '') {
        foreach ($limit in $Style.Thresholds) {
            if ($number -ge $limit[0]) { return , @(($Style.Format -f $Value), $limit[1]) }
        }
        return , @(($Style.Format -f $Value), $(if ($Style.Default) { $Style.Default[1] } else { $null }))
    }
    if ($Style.Default) {
        $text = if ($null -ne $Style.Default[0]) { $Style.Default[0] } else { $key }
        return , @($text, $Style.Default[1])
    }
    return , @($key, $null)
}

# Console color names, any case, to their own spelling.
$script:HermesConsoleColorName = @{}
foreach ($name in [Enum]::GetNames([ConsoleColor])) { $script:HermesConsoleColorName[$name] = $name }

function Resolve-HermesSegmentColor {
    <#
    .SYNOPSIS
        A console color name, "#RRGGBB" or a theme role, resolved to what Write-Host takes; '' and $null give $null.
    .DESCRIPTION
        A simple function, like ConvertTo-HermesSegment, because it runs for every colored segment.
    #>
    param([string]$Color)

    if ([string]::IsNullOrWhiteSpace($Color)) { return $null }
    # Console color names are looked up once; roles follow the active theme, so they are resolved every time.
    $known = $script:HermesConsoleColorName[$Color]
    if ($known) { return $known }
    if ($script:HermesColorRoles -contains $Color) { return (Resolve-UIColor -Role $Color) }
    if ($Color -match '^#[0-9A-Fa-f]{6}$') { return $Color }
    throw [System.ArgumentException]::new("'$Color' is not a console color, a theme role or #RRGGBB.")
}

# --- Lines made of segments ----------------------------------------------------------------------------------

function ConvertTo-HermesSegment {
    <#
    .SYNOPSIS
        Reads one segment of Write-ConsoleLine (string, array or hashtable/object) as a hashtable.
    .DESCRIPTION
        A simple function, not an advanced one: it runs for every segment, and binding an advanced function's
        parameters costs more than the work it does.
    #>
    param($Segment)

    # Settings are read straight from the hashtable: this runs for every segment of every line.
    $s = @{ Text = ''; Color = $null; Width = 0; Align = 'Left'; Fill = 'None'; Gap = -1; Bar = $null; Max = 100; Empty = $null }
    if ($Segment -is [System.Collections.IDictionary] -or $Segment -is [pscustomobject]) {
        $h = $Segment
        if ($Segment -isnot [System.Collections.IDictionary]) {
            $h = @{}
            foreach ($property in $Segment.PSObject.Properties) { $h[$property.Name] = $property.Value }
        }
        $text = $h['Text']
        $value = $h['Value']
        $styleName = [string]$h['Style']
        $bar = $h['Bar']
        if ($null -ne $h['Width']) { $s.Width = [double]$h['Width'] }
        if ($null -ne $h['Gap']) { $s.Gap = [double]$h['Gap'] }
        if ($null -ne $h['Max']) { $s.Max = [double]$h['Max'] }
        if ($h['Align']) { $s.Align = [string]$h['Align'] }
        if ($h['Fill']) { $s.Fill = [string]$h['Fill'] }
        $color = if ($h['Color']) { Resolve-HermesSegmentColor -Color ([string]$h['Color']) } else { $null }
        if ($h['Empty']) { $s.Empty = Resolve-HermesSegmentColor -Color ([string]$h['Empty']) }
        if ($null -ne $bar) {
            $s.Bar = [double]$bar
            if ($s.Width -le 0) { $s.Width = 20 }
            if ($styleName -and -not $color) { $color = (Resolve-HermesStyleValue -Style (Get-HermesStyle -Name $styleName) -Value $bar)[1] }
        }
        elseif ($styleName) {
            $style = Get-HermesStyle -Name $styleName
            $resolved = Resolve-HermesStyleValue -Style $style -Value $(if ($null -ne $value) { $value } else { $text })
            if ($null -eq $text -or $null -ne $value) { $text = $resolved[0] }
            if (-not $color) { $color = $resolved[1] }
            if ($s.Width -le 0 -and $s.Fill -eq 'None' -and $style.Width -gt 0) { $s.Width = $style.Width }
        }
        elseif ($null -eq $text) { $text = $value }
        $s.Text = [string]$text
        $s.Color = $color
    }
    elseif ($Segment -is [System.Collections.IList]) {
        $items = @($Segment)
        $s.Text = [string]$items[0]
        if ($items.Count -gt 1 -and $items[1]) { $s.Color = Resolve-HermesSegmentColor -Color ([string]$items[1]) }
        if ($items.Count -gt 2 -and $null -ne $items[2]) { $s.Width = [double]$items[2] }
    }
    else { $s.Text = [string]$Segment }

    if ($s.Fill -notin 'None', 'Cut', 'Wrap') { throw [System.ArgumentException]::new("Fill must be None, Cut or Wrap, not '$($s.Fill)'.") }
    if ($s.Align -notin 'Left', 'Right') { throw [System.ArgumentException]::new("Align must be Left or Right, not '$($s.Align)'.") }
    $s.Width = [int]$s.Width
    $s.Gap = [int]$s.Gap
    if ($script:HermesControlRegex.IsMatch($s.Text)) { $s.Text = ConvertTo-ConsoleSafeText -Text $s.Text }
    $s.Text = $s.Text.Replace("`t", '    ')
    if ($s.Fill -ne 'Wrap') { $s.Text = $s.Text.Replace("`n", ' ') }
    return $s
}

function Assert-HermesSegmentList {
    <#
    .SYNOPSIS
        Fails when the segments look like array segments merged into one list.
    .DESCRIPTION
        PowerShell joins the arrays written one per line inside @( ... ) into one list: @( @('a', 'Red')
        @('b', 'Green') ) becomes 'a', 'Red', 'b', 'Green', and the color names would be written as text. A
        plain text segment that is a color name, a theme role or #RRGGBB right after another plain value is
        taken as that mistake. Write color names as text with @{ Text = 'Red' }.
    #>
    param([object[]]$Segments)

    $previousPlain = $false
    for ($i = 0; $i -lt $Segments.Count; $i++) {
        $segment = $Segments[$i]
        $plain = $null -ne $segment -and ($segment -is [string] -or $segment -is [ValueType])
        if ($plain -and $previousPlain -and $segment -is [string] -and
            ($script:HermesConsoleColorName.ContainsKey($segment) -or $script:HermesColorRoles -contains $segment -or $segment -match '^#[0-9A-Fa-f]{6}$')) {
            throw [System.ArgumentException]::new(("Segment {0} is the color '{1}' as text: the array segments were probably merged into one list. " +
                    "Write each array segment with a comma, ,@('text', '{1}'), or as a hashtable, @{{ Text = 'text'; Color = '{1}' }}. " +
                    "To write a color name as text, use @{{ Text = '{1}' }}.") -f $i, $segment)
        }
        $previousPlain = $plain
    }
}

function ConvertTo-HermesLine {
    <#
    .SYNOPSIS
        Lays segments out in lines of @(text, color) pairs: fixed widths padded or cut, one segment filling the rest
        (cut, or wrapped with the following lines aligned under it).
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [AllowNull()][AllowEmptyCollection()][object[]]$Segments,
        [int]$Width,
        [int]$Indent,
        [string]$Separator = ' ',
        [switch]$CutLast
    )

    Assert-HermesSegmentList -Segments $Segments
    $parts = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($segment in @($Segments)) { if ($null -ne $segment) { $parts.Add((ConvertTo-HermesSegment -Segment $segment)) } }
    if ($CutLast -and $parts.Count -and $parts[$parts.Count - 1].Width -le 0 -and $parts[$parts.Count - 1].Fill -eq 'None' -and $null -eq $parts[$parts.Count - 1].Bar) {
        $parts[$parts.Count - 1].Fill = 'Cut'
    }

    # The room left for the segment that fills the line: the width minus everything else.
    $fill = -1
    $used = $Indent
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $p = $parts[$i]
        $gap = if ($i -eq 0) { 0 } elseif ($p.Gap -ge 0) { $p.Gap } else { $Separator.Length }
        $p.GapText = if ($p.Gap -ge 0 -and $i -gt 0) { ' ' * $p.Gap } elseif ($i -gt 0) { $Separator } else { '' }
        $used += $gap
        if ($fill -lt 0 -and $p.Fill -ne 'None') { $fill = $i; continue }
        $p.Wide = $script:HermesWideRegex.IsMatch($p.Text)
        $used += $(if ($p.Width -gt 0) { $p.Width } elseif ($p.Wide) { Measure-ConsoleText -Text $p.Text } else { $p.Text.Length })
    }
    $room = [Math]::Max($Width - $used, 10)

    $lines = [System.Collections.Generic.List[object]]::new()
    $line = [System.Collections.Generic.List[object]]::new()
    if ($Indent -gt 0) { $line.Add(@((' ' * $Indent), $null)) }
    $column = $Indent
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $p = $parts[$i]
        if ($p.GapText) { $line.Add(@($p.GapText, $null)); $column += $p.GapText.Length }
        if ($null -ne $p.Bar) {
            $max = if ($p.Max -gt 0) { $p.Max } else { 100 }
            $full = [int][Math]::Round($p.Width * [Math]::Min([Math]::Max($p.Bar, 0), $max) / $max)
            if ($full) { $line.Add(@(([string][char]0x2588 * $full), $p.Color)) }
            if ($p.Width - $full) { $line.Add(@(([string][char]0x2591 * ($p.Width - $full)), $(if ($p.Empty) { $p.Empty } else { Resolve-UIColor -Role Muted }))) }
            $column += $p.Width
            continue
        }
        if ($i -eq $fill -and $p.Fill -eq 'Wrap') {
            $wrapped = Split-ConsoleTextLine -Segments ([System.Collections.Generic.List[object]]@(, @($p.Text, $p.Color))) -Width $room -Indent 0
            for ($w = 0; $w -lt $wrapped.Count; $w++) {
                if ($w -gt 0) {
                    $lines.Add($line.ToArray()); $line = [System.Collections.Generic.List[object]]::new()
                    if ($column -gt 0) { $line.Add(@((' ' * $column), $null)) }
                }
                foreach ($pair in $wrapped[$w]) { $line.Add($pair) }
            }
            continue
        }
        $text = $p.Text
        $limit = if ($i -eq $fill) { $room } else { $p.Width }
        if ($limit -gt 0) {
            if ($script:HermesWideRegex.IsMatch($text)) {
                $text = if ($i -eq $fill) { Format-ConsoleText -Text $text -Width $limit } else { Format-ConsoleText -Text $text -Width $limit -Align $p.Align }
            }
            else {
                # The same as Format-ConsoleText for text without wide characters, without a call per segment.
                if ($text.Length -gt $limit) { $text = $text.Substring(0, $limit - 1) + [char]0x2026 }
                elseif ($i -ne $fill) { $text = if ($p.Align -eq 'Right') { $text.PadLeft($limit) } else { $text.PadRight($limit) } }
            }
        }
        if ($text) { $line.Add(@($text, $p.Color)) }
        $column += $(if ($script:HermesWideRegex.IsMatch($text)) { Measure-ConsoleText -Text $text } else { $text.Length })
    }
    $lines.Add($line.ToArray())
    return , $lines.ToArray()
}

function Write-ConsoleLine {
    <#
    .SYNOPSIS
        Writes one line made of segments, each with its own color and width; one can fill the rest of the line.

    .DESCRIPTION
        The line a report is made of: a state, a level, an identifier and a title, each in its color and column.
        A segment is:
        - a string: text in the default color;
        - an array: text, color and, optionally, width;
        - a hashtable (or object) with:
            Text    the text;
            Color   a console color, a theme role or "#RRGGBB";
            Width   columns: the text is cut with "…" or padded to exactly that width;
            Align   Left (the default) or Right within Width;
            Fill    Cut or Wrap: the segment takes the rest of the line, cut with "…" or wrapped with the
                    following lines aligned under its start (only the first segment with Fill does);
            Gap     spaces before the segment, instead of -Separator;
            Value and Style: the text and color a registered style gives the value (Register-ConsoleStyle);
                    without Width, the segment is as wide as the style's widest text, so states line up;
            Bar     a percentage drawn as a bar of Width (20) columns, colored by Color or by Style; Max is
                    the value of a full bar (100) and Empty the color of the rest.
        $null segments are skipped, so a segment can depend on a condition: $(if ($risk) { @{ ... } }).
        The text is written safely, as everywhere in the module, and is never read for color marks.
        Where the terminal supports virtual terminal sequences (PowerShell 7 in Windows Terminal, and most
        consoles), each line is written in one call, which is faster and keeps lines whole.

    .PARAMETER Segments
        The segments, from left to right.

    .PARAMETER Indent
        Spaces before the first segment. Defaults to the layout margin (Set-ConsoleLayout, 2).

    .PARAMETER Separator
        Text between segments that have no Gap. Defaults to one space.

    .PARAMETER Width
        Width of the line. Defaults to the line width of the layout (the console, at most -MaxWidth).

    .PARAMETER ReturnLines
        Return the text of the lines, without colors, instead of writing them.

    .EXAMPLE
        Write-ConsoleLine @(
            @{ Value = $r.Status; Style = 'State' }
            @{ Text = $r.Id; Color = 'DarkCyan'; Width = 8 }
            @{ Text = $r.Title; Fill = 'Cut' }
            $(if ($r.Risk -eq 'high') { @{ Text = 'high risk'; Color = 'Red'; Gap = 2 } })
        )

        One line per rule, with the columns aligned and the title cut to fit.

    .EXAMPLE
        Write-ConsoleLine @{ Text = 'L2 Recommended'; Width = 16 }, @{ Bar = 82; Width = 24; Style = 'Percent' }, @{ Value = 82; Style = 'Percent' }

        A level with its bar and percentage, colored by the thresholds of the Percent style.

    .EXAMPLE
        Write-ConsoleLine @{ Text = 'high'; Color = 'Red'; Width = 8 }, @{ Text = $alert.Title; Fill = 'Wrap' }

        A long alert title wrapped under itself, after a severity column.
    #>
    [CmdletBinding()]
    [OutputType([string[]], [object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Segments,

        [ValidateRange(-1, 200)]
        [int]$Indent = -1,

        [string]$Separator = ' ',

        [ValidateRange(0, 1000)]
        [int]$Width = 0,

        [switch]$ReturnLines
    )

    if ($Width -le 0) { $Width = Get-HermesLineWidth }
    $lines = ConvertTo-HermesLine -Segments $Segments -Width $Width -Indent (Get-HermesMargin -Indent $Indent) -Separator $Separator
    if ($ReturnLines) { return @(foreach ($l in $lines) { (-join @(foreach ($pair in $l) { $pair[0] })).TrimEnd() }) }
    foreach ($l in $lines) { Write-HermesSegment -Segments $l }
}

function Write-ConsoleKeyValue {
    <#
    .SYNOPSIS
        Writes labels in a column and their values next to them, wrapped under themselves.

    .DESCRIPTION
        For details, settings and lists of findings: each label is padded to the width of the longest (or
        -LabelWidth), and its value starts at the same column on every row; a long value is wrapped and its
        lines stay in that column (with -Cut it is cut with "…" instead).
        -Items is an ordered dictionary (label to value) or a list whose items are arrays (label, value, color)
        or hashtables with Label, Value and, optionally, Color, LabelColor and Style (the style colors and
        words the value). A list can repeat labels, such as a severity before each finding.
        A value in a dictionary can also be an array (value, color) or a hashtable with Value, Color and Style.

    .PARAMETER Items
        The labels and values.

    .PARAMETER LabelWidth
        Width of the label column. 0 (the default) is the width of the longest label, at most half the line;
        a width given is kept as long as 10 columns are left for the values. Longer labels are cut with "…".

    .PARAMETER LabelColor
        Color of the labels. Defaults to the theme's Muted color.

    .PARAMETER LabelStyle
        A registered style that colors each label by its text, such as severities.

    .PARAMETER Color
        Default color of the values. Defaults to the terminal's color.

    .PARAMETER Gap
        Spaces between the label column and the values. Defaults to 2.

    .PARAMETER Indent
        Spaces before the labels. Defaults to the layout margin.

    .PARAMETER Cut
        Cut long values with "…" instead of wrapping them.

    .PARAMETER ReturnLines
        Return the text of the lines, without colors, instead of writing them.

    .EXAMPLE
        Write-ConsoleKeyValue ([ordered]@{ Rule = 'CIS 18.9.4'; State = @{ Value = 'NonCompliant'; Style = 'State' }; Why = $rule.Reason })

    .EXAMPLE
        Write-ConsoleKeyValue -LabelStyle Severity -Indent 4 @($alerts | ForEach-Object { , @($_.Severity, $_.Title) })

        One finding per row, each after its severity in that severity's color.
    #>
    [CmdletBinding()]
    [OutputType([string[]], [object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        [object]$Items,

        [ValidateRange(0, 200)]
        [int]$LabelWidth = 0,

        [string]$LabelColor,

        [string]$LabelStyle,

        [string]$Color,

        [ValidateRange(0, 20)]
        [int]$Gap = 2,

        [ValidateRange(-1, 200)]
        [int]$Indent = -1,

        [switch]$Cut,

        [switch]$ReturnLines
    )

    $rows = [System.Collections.Generic.List[object]]::new()
    $add = {
        param($label, $value, $color, $labelColor, $style)
        if ($value -is [System.Collections.IDictionary] -or $value -is [pscustomobject]) {
            $c = Get-ColumnValue $value 'Color'; if ($c) { $color = $c }
            $s = Get-ColumnValue $value 'Style'; if ($s) { $style = $s }
            $value = Get-ColumnValue $value 'Value'
        }
        elseif ($value -is [System.Collections.IList] -and $value -isnot [string]) {
            $v = @($value); $value = $v[0]; if ($v.Count -gt 1 -and $v[1]) { $color = $v[1] }
        }
        $rows.Add(@([string]$label, $value, $color, $labelColor, $style))
    }
    if ($Items -is [System.Collections.IDictionary]) {
        foreach ($key in $Items.Keys) { & $add $key $Items[$key] $null $null $null }
    }
    else {
        foreach ($item in @($Items)) {
            if ($null -eq $item) { continue }
            if ($item -is [System.Collections.IDictionary] -or $item -is [pscustomobject]) {
                & $add (Get-ColumnValue $item 'Label') @{ Value = (Get-ColumnValue $item 'Value'); Color = (Get-ColumnValue $item 'Color'); Style = (Get-ColumnValue $item 'Style') } $null (Get-ColumnValue $item 'LabelColor') $null
            }
            else {
                $v = @($item)
                & $add $v[0] $(if ($v.Count -gt 1) { $v[1] } else { '' }) $(if ($v.Count -gt 2) { $v[2] } else { $null }) $null $null
            }
        }
    }

    $width = $LabelWidth
    if ($width -le 0) { foreach ($row in $rows) { $width = [Math]::Max($width, (Measure-ConsoleText -Text $row[0])) } }
    $lineWidth = Get-HermesLineWidth
    $margin = Get-HermesMargin -Indent $Indent
    # An automatic width is at most half the line; a width asked for is kept while the values still get 10 columns.
    $limit = if ($LabelWidth -gt 0) { $lineWidth - $margin - $Gap - 10 } else { [int](($lineWidth - $margin) / 2) }
    $width = [Math]::Min($width, [Math]::Max(4, $limit))
    $defaultLabel = if ($LabelColor) { $LabelColor } else { 'Muted' }

    $out = [System.Collections.Generic.List[object]]::new()
    foreach ($row in $rows) {
        $labelColor = if ($row[3]) { $row[3] } elseif ($LabelStyle) { (Resolve-HermesStyleValue -Style (Get-HermesStyle -Name $LabelStyle) -Value $row[0])[1] } else { $defaultLabel }
        $value = @{ Text = [string]$row[1]; Color = $(if ($row[2]) { $row[2] } else { $Color }); Fill = $(if ($Cut) { 'Cut' } else { 'Wrap' }); Gap = $Gap }
        if ($row[4]) { $value.Remove('Text'); $value.Value = $row[1]; $value.Style = $row[4]; if (-not $row[2]) { $value.Remove('Color') } }
        $segments = @(@{ Text = $row[0]; Color = $labelColor; Width = $width }, $value)
        foreach ($l in (ConvertTo-HermesLine -Segments $segments -Width $lineWidth -Indent $margin)) { $out.Add($l) }
    }
    if ($ReturnLines) { return @(foreach ($l in $out) { (-join @(foreach ($pair in $l) { $pair[0] })).TrimEnd() }) }
    foreach ($l in $out) { Write-HermesSegment -Segments $l }
}

function Write-ConsoleGrid {
    <#
    .SYNOPSIS
        Writes items in columns of the same width, as many on each line as fit.

    .DESCRIPTION
        For short summaries that read better side by side, such as the result of each area: each item takes
        -ColumnWidth columns and the items flow from left to right, on as many lines as needed. With a narrow
        console there is one item per line. An item is a string, one segment (a hashtable, see
        Write-ConsoleLine) or an array of segments; its last segment is cut with "…" so the item fits.

    .PARAMETER Items
        The items.

    .PARAMETER ColumnWidth
        Columns each item takes.

    .PARAMETER Gap
        Spaces between items. Defaults to 3.

    .PARAMETER Columns
        Items on each line. 0 (the default) puts as many as fit.

    .PARAMETER Indent
        Spaces before each line. Defaults to the layout margin.

    .PARAMETER ReturnLines
        Return the text of the lines, without colors, instead of writing them.

    .EXAMPLE
        Write-ConsoleGrid -ColumnWidth 38 @($areas | ForEach-Object {
            , @(@{ Text = $_.Name; Width = 32 }, @{ Text = "$($_.Ok)/$($_.Total)"; Color = (Get-ConsoleStyle Percent $_.Percent).Color })
        })

        Two areas on each line in a wide console, one in a narrow one.
    #>
    [CmdletBinding()]
    [OutputType([string[]], [object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyCollection()]
        [object[]]$Items,

        [Parameter(Mandatory = $true)]
        [ValidateRange(4, 1000)]
        [int]$ColumnWidth,

        [ValidateRange(0, 20)]
        [int]$Gap = 3,

        [ValidateRange(0, 100)]
        [int]$Columns = 0,

        [ValidateRange(-1, 200)]
        [int]$Indent = -1,

        [switch]$ReturnLines
    )

    $margin = Get-HermesMargin -Indent $Indent
    $perLine = $Columns
    if ($perLine -le 0) { $perLine = [Math]::Max(1, [Math]::Floor(((Get-HermesLineWidth) - $margin + $Gap) / ($ColumnWidth + $Gap))) }

    $out = [System.Collections.Generic.List[object]]::new()
    $line = $null
    $pad = 0
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $item = $Items[$i]
        $segments = if ($item -is [System.Collections.IList] -and $item -isnot [string]) { @($item) } else { @(, $item) }
        $cell = (ConvertTo-HermesLine -Segments $segments -Width $ColumnWidth -Indent 0 -CutLast)[0]
        $cellWidth = 0; foreach ($pair in $cell) { $cellWidth += Measure-ConsoleText -Text $pair[0] }
        $first = $i % $perLine -eq 0
        if ($first) {
            if ($null -ne $line) { $out.Add($line.ToArray()) }
            $line = [System.Collections.Generic.List[object]]::new()
            if ($margin) { $line.Add(@((' ' * $margin), $null)) }
        }
        else { $line.Add(@((' ' * ($pad + $Gap)), $null)) }
        foreach ($pair in $cell) { $line.Add($pair) }
        $pad = [Math]::Max(0, $ColumnWidth - $cellWidth)
    }
    if ($null -ne $line) { $out.Add($line.ToArray()) }
    if ($ReturnLines) { return @(foreach ($l in $out) { (-join @(foreach ($pair in $l) { $pair[0] })).TrimEnd() }) }
    foreach ($l in $out) { Write-HermesSegment -Segments $l }
}

# --- Captures to a file ------------------------------------------------------------------------------------

$script:HermesCapture = $null

function Start-ConsoleCapture {
    <#
    .SYNOPSIS
        Keeps a copy of everything the module writes, and the answers typed, in a text file, line by line.

    .DESCRIPTION
        For output shown somewhere else later, such as a copy of the script that runs elevated in another
        window: every complete line is added to the file (UTF-8) as soon as it ends, so the file is useful even
        if the process stops. The parts of a line written in several colors are joined, and the questions keep
        their answers (a password as asterisks).
        While capturing, nothing is rewritten in place: status lines are not drawn, the screen is not cleared
        (a blank line instead), and prompts list their options and read the typed answer instead of using the
        arrow keys, so the file shows the options and the answer.
        The capture works alongside a handler registered with Register-ConsoleOutputHandler. Starting another
        capture replaces the first one. Stop-ConsoleCapture ends it.

    .PARAMETER Path
        The file. It is created, or emptied unless -Append is given.

    .PARAMETER Append
        Add to the file instead of emptying it.

    .EXAMPLE
        Start-ConsoleCapture -Path $env:TEMP\elevated.txt
        try { Invoke-Audit } finally { Stop-ConsoleCapture }
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Append
    )

    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if (-not $PSCmdlet.ShouldProcess($full, 'Capture console output')) { return }
    if ($script:HermesCapture) { Stop-ConsoleCapture -Confirm:$false }
    $encoding = [System.Text.UTF8Encoding]::new($false)
    if (-not $Append -or -not [System.IO.File]::Exists($full)) { [System.IO.File]::WriteAllText($full, '', $encoding) }
    $script:HermesCapture = @{ Path = $full; Line = [System.Text.StringBuilder]::new(); Encoding = $encoding }
}

function Stop-ConsoleCapture {
    <#
    .SYNOPSIS
        Ends the capture started with Start-ConsoleCapture, writing the last unfinished line.

    .DESCRIPTION
        Nothing happens when there is no capture. Afterwards prompts use the arrow keys again and status lines
        are drawn, where the console allows it.

    .EXAMPLE
        Stop-ConsoleCapture
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()

    if (-not $script:HermesCapture) { return }
    if (-not $PSCmdlet.ShouldProcess($script:HermesCapture.Path, 'Stop capturing console output')) { return }
    $capture = $script:HermesCapture
    $script:HermesCapture = $null
    if ($capture.Line.Length) {
        try { [System.IO.File]::AppendAllText($capture.Path, $capture.Line.ToString() + "`n", $capture.Encoding) } catch { Write-Verbose "Capture failed: $($_.Exception.Message)" }
    }
}

# --- Simulated console, for tests ----------------------------------------------------------------------------

$script:HermesSimulation = $null

function Read-HermesHost {
    <#
    .SYNOPSIS
        Read-Host, or the next simulated answer while Enable-ConsoleSimulation is on ($null when they run out).
    .DESCRIPTION
        A simple function so that the parameters are passed to Read-Host only when given, as before.
    #>
    param([string]$Prompt, [switch]$AsSecureString)

    if ($script:HermesSimulation) {
        $queue = $script:HermesSimulation.Answers
        $answer = if ($queue.Count) { $queue.Dequeue() } else { $null }
        if (-not $AsSecureString -or $null -eq $answer) { return $answer }
        $secure = [System.Security.SecureString]::new()
        foreach ($c in $answer.ToCharArray()) { $secure.AppendChar($c) }
        $secure.MakeReadOnly()
        return $secure
    }
    if ($AsSecureString) {
        if ($PSBoundParameters.ContainsKey('Prompt')) { return (Read-Host -Prompt $Prompt -AsSecureString) }
        return (Read-Host -AsSecureString)
    }
    if ($PSBoundParameters.ContainsKey('Prompt')) { return (Read-Host -Prompt $Prompt) }
    return (Read-Host)
}

function Read-HermesKey {
    <#
    .SYNOPSIS
        The next key: simulated while Enable-ConsoleSimulation is on (Escape when they run out), otherwise
        from $script:HermesReadKey (the console).
    #>
    if ($script:HermesSimulation) {
        $queue = $script:HermesSimulation.Keys
        if ($queue.Count) { return $queue.Dequeue() }
        return [System.ConsoleKeyInfo]::new([char]27, [System.ConsoleKey]::Escape, $false, $false, $false)
    }
    return (& $script:HermesReadKey)
}

function ConvertTo-HermesKey {
    <#
    .SYNOPSIS
        A ConsoleKeyInfo from a ConsoleKeyInfo, a [char], a [ConsoleKey], a one-character string or a key name.
    #>
    param($Key)

    if ($Key -is [System.ConsoleKeyInfo]) { return $Key }
    $special = @{ Enter = [char]13; Escape = [char]27; Backspace = [char]8; Tab = [char]9; Spacebar = ' ' }
    if ($Key -is [System.ConsoleKey] -or ($Key -is [string] -and $Key.Length -gt 1)) {
        $name = [System.ConsoleKey]$Key
        $char = if ($special.ContainsKey([string]$name)) { [char]$special[[string]$name] } else { [char]0 }
        return [System.ConsoleKeyInfo]::new($char, $name, $false, $false, $false)
    }
    $c = [char]([string]$Key)
    $consoleKey = [System.ConsoleKey]::NoName
    if ($c -match '[A-Za-z]') { $consoleKey = [System.ConsoleKey]([string]$c).ToUpperInvariant() }
    elseif ($c -match '[0-9]') { $consoleKey = [System.ConsoleKey]("D$c") }
    else { foreach ($n in $special.Keys) { if ([char]$special[$n] -eq $c) { $consoleKey = [System.ConsoleKey]$n } } }
    return [System.ConsoleKeyInfo]::new($c, $consoleKey, $false, $false, $false)
}

function Enable-ConsoleSimulation {
    <#
    .SYNOPSIS
        Makes the prompts read simulated keys and answers, for tests of scripts that use the module.

    .DESCRIPTION
        From now on, the prompts that read keys (Read-ConsoleSelection, Read-ConsoleMenu and the arrow-key lists)
        take them from -Keys, and the prompts that read a line (Read-ConsoleInput, Read-ConsoleChoice,
        Read-ConsoleConfirmation, Read-ConsolePassword, Wait-ConsoleKey and the typed menus) take them from
        -Answers, in order. When the keys run out, Escape is read; when the answers run out, the input has
        ended, as with a redirected file: each prompt returns its default or fails, never waits.
        The console counts as interactive (arrow keys), or not with -NonInteractive (options listed and the
        key typed). Captures and output handlers receive the questions and answers as usual.
        Disable-ConsoleSimulation ends it; Invoke-ConsoleSimulation runs a script block with it and ends it.
        Enabling it again replaces the keys and answers.

    .PARAMETER Keys
        Keys to read: [ConsoleKeyInfo], [char], [ConsoleKey], one-character strings ('2') or key names
        ('Enter', 'DownArrow', 'Escape', 'Backspace', 'Spacebar').

    .PARAMETER Answers
        Lines to read, in order.

    .PARAMETER NonInteractive
        Behave as a console where keys cannot be read: menus list their options and read the typed key.

    .EXAMPLE
        Enable-ConsoleSimulation -Keys 'DownArrow', 'Enter'
        $pick = Read-ConsoleMenu -Items ([ordered]@{ a = 'Audit'; r = 'Repair' })
        Disable-ConsoleSimulation

        $pick is 'r'.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [AllowEmptyCollection()]
        [object[]]$Keys = @(),

        [AllowEmptyCollection()]
        [AllowNull()]
        [string[]]$Answers = @(),

        [switch]$NonInteractive
    )

    if (-not $PSCmdlet.ShouldProcess('HermesConsoleUI input', 'Simulate keys and answers')) { return }
    $keyQueue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new()
    foreach ($k in @($Keys)) { if ($null -ne $k) { $keyQueue.Enqueue((ConvertTo-HermesKey -Key $k)) } }
    $answerQueue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($a in @($Answers)) { $answerQueue.Enqueue([string]$a) }
    $script:HermesSimulation = @{ Keys = $keyQueue; Answers = $answerQueue; Interactive = -not $NonInteractive }
}

function Disable-ConsoleSimulation {
    <#
    .SYNOPSIS
        Ends the simulation started with Enable-ConsoleSimulation: prompts read the real console again.

    .DESCRIPTION
        Keys and answers that were not read are discarded. Nothing happens when no simulation is on.

    .EXAMPLE
        Disable-ConsoleSimulation
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()

    if (-not $PSCmdlet.ShouldProcess('HermesConsoleUI input', 'Stop simulating keys and answers')) { return }
    $script:HermesSimulation = $null
}

function Invoke-ConsoleSimulation {
    <#
    .SYNOPSIS
        Runs a script block with simulated keys and answers, and ends the simulation afterwards.

    .DESCRIPTION
        The same as Enable-ConsoleSimulation, the script block and Disable-ConsoleSimulation, with the simulation
        ended even when the script block fails. Returns what the script block returns.

    .PARAMETER ScriptBlock
        The code to run.

    .PARAMETER Keys
        Keys to read (see Enable-ConsoleSimulation).

    .PARAMETER Answers
        Lines to read, in order.

    .PARAMETER NonInteractive
        Behave as a console where keys cannot be read.

    .EXAMPLE
        $answers = Invoke-ConsoleSimulation -Answers '', 'yes' { Read-ConsoleConfirmation 'Go on?' -Default $true; Read-ConsoleConfirmation 'Delete?' }

        Returns $true (Enter takes the default) and $true.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [scriptblock]$ScriptBlock,

        [AllowEmptyCollection()]
        [object[]]$Keys = @(),

        [AllowEmptyCollection()]
        [AllowNull()]
        [string[]]$Answers = @(),

        [switch]$NonInteractive
    )

    Enable-ConsoleSimulation -Keys $Keys -Answers $Answers -NonInteractive:$NonInteractive -Confirm:$false
    try { & $ScriptBlock }
    finally { Disable-ConsoleSimulation -Confirm:$false }
}

# --- Waiting and Write-Host ----------------------------------------------------------------------------------

function Wait-ConsoleKey {
    <#
    .SYNOPSIS
        Asks the user to press Enter, for example before going back to a menu.

    .DESCRIPTION
        Writes a blank line and the message in the theme's Muted color, then waits for Enter. With redirected
        input that has run out it returns at once. A capture keeps the message as one line.

    .PARAMETER Message
        The text to show. Defaults to the localized "Press Enter to continue...".

    .EXAMPLE
        Wait-ConsoleKey -Message 'Press Enter to go back to the menu…'
    #>
    [CmdletBinding()]
    param([string]$Message)

    if (-not $Message) { $Message = Get-UIText -Key 'Menu.PressEnter' -Default 'Press Enter to continue...' }
    Write-HermesHost ''
    Write-HermesHost ((' ' * (Get-HermesMargin)) + $Message + ' ') -NoNewline -ForegroundColor (Resolve-UIColor -Role Muted)
    $null = Read-HermesHost
    Send-HermesAnswer -Text ''
}

$script:HermesWriteHostProxy = {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [object[]]$Object,
        [switch]$NoNewline,
        [object]$Separator,
        $ForegroundColor,
        $BackgroundColor
    )
    # Windows PowerShell 5.1 passes Write-Host 'a', 'b' as one array argument; PowerShell 7 as two.
    if ($null -ne $Object -and $Object.Count -eq 1 -and $Object[0] -is [array]) { $PSBoundParameters['Object'] = [object[]]$Object[0] }
    Write-HermesHost @PSBoundParameters
}

function Enable-ConsoleHostRedirect {
    <#
    .SYNOPSIS
        Makes Write-Host, in the script or module that calls this, write through HermesConsoleUI.

    .DESCRIPTION
        Defines a Write-Host function in the caller's script scope (its module, when called from a module) that
        takes the same parameters and writes with the module: control characters and escape sequences are
        removed, NO_COLOR and "#RRGGBB" colors are honoured, status lines are cleared first, and the output
        reaches output handlers and captures. Code that still calls Write-Host then needs no change.
        Disable-ConsoleHostRedirect removes it. Other modules and the console keep the real Write-Host.

    .EXAMPLE
        # At the top of a module:
        Enable-ConsoleHostRedirect
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()

    if (-not $PSCmdlet.ShouldProcess('Write-Host in the calling scope', 'Redirect to HermesConsoleUI')) { return }
    # An unbound script block runs in the caller's session state; one written here would run in this module's.
    $define = [scriptblock]::Create('param($Body) Set-Item -Path function:script:Write-Host -Value $Body')
    $null = $PSCmdlet.SessionState.InvokeCommand.InvokeScript($PSCmdlet.SessionState, $define, @($script:HermesWriteHostProxy))
}

function Disable-ConsoleHostRedirect {
    <#
    .SYNOPSIS
        Removes the Write-Host defined by Enable-ConsoleHostRedirect in the calling script or module.

    .DESCRIPTION
        Write-Host is the PowerShell cmdlet again in that scope. Nothing happens when it was not redirected.

    .EXAMPLE
        Disable-ConsoleHostRedirect
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()

    if (-not $PSCmdlet.ShouldProcess('Write-Host in the calling scope', 'Remove the redirection')) { return }
    # Remove-Item ignores a scope in the path; without one it removes the nearest definition, the script's.
    $remove = [scriptblock]::Create('if (Test-Path -Path function:script:Write-Host) { Remove-Item -Path function:Write-Host }')
    $null = $PSCmdlet.SessionState.InvokeCommand.InvokeScript($PSCmdlet.SessionState, $remove, @())
}
