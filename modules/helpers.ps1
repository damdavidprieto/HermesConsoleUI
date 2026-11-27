# HermesConsoleUI - private helper functions.
#
# Used by the public components: safe console output, true color, theme and locale lookups,
# text centering, icons and the layout column merge. Nothing here is exported.

# Any character ConvertTo-ConsoleSafeText removes or changes: C0 and C1 controls except line feed and tab.
# Escape sequences start with ESC (0x1B) or CSI (0x9B), so text without these has nothing to clean.
$script:HermesControlRegex = [regex]::new('[\x00-\x08\x0B-\x1F\x7F-\x9F]', 'CultureInvariant')

# Characters that do not take exactly one column: combining marks and zero-width characters (none), East Asian
# wide characters and emoji (two). Text without any of them is as wide as it is long.
$script:HermesWideRegex = [regex]::new('[\u0300-\u036F\u1100-\u115F\u200B-\u200F\u2E80-\uA4CF\uAC00-\uD7A3\uF900-\uFAFF\uFE00-\uFE0F\uFE30-\uFE4F\uFF00-\uFF60\uFFE0-\uFFE6\uD800-\uDFFF]', 'CultureInvariant')

# The roles every theme defines; components ask for colors by role (see Resolve-UIColor).
$script:HermesColorRoles = @('Primary', 'Secondary', 'Success', 'Warning', 'Error', 'Info', 'Muted', 'Highlight')

function ConvertTo-ConsoleSafeText {
    <#
    .SYNOPSIS
        Removes terminal control sequences from text before it is written to the console.
    .DESCRIPTION
        Text shown by the UI components often comes from outside the script: file names,
        log lines, API responses. If it contains escape sequences, writing it as-is lets that
        data recolor or hide output, move the cursor to overwrite earlier lines, change the
        window title or, in some terminals, set the clipboard (OSC 52).
        ANSI CSI and OSC sequences are removed whole, then every remaining C0/C1 control
        character except line feed and tab. Carriage returns are removed too, so a line
        cannot overwrite itself.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([AllowNull()][AllowEmptyString()][string]$Text)

    # Most text has no control character at all: nothing to remove.
    if ([string]::IsNullOrEmpty($Text) -or -not $script:HermesControlRegex.IsMatch($Text)) { return $Text }
    $clean = $Text -replace '\x1B\][^\x07\x1B]*(\x07|\x1B\\)?', ''            # OSC ... BEL / ST
    $clean = $clean -replace '(\x1B\[|\x9B)[0-?]*[ -/]*[@-~]', ''             # CSI ... final byte
    $clean = $clean -replace '\x1B[@-_]?', ''                                 # other ESC sequences
    $clean = $clean -replace '\r\n', "`n"
    return ($clean -replace '[\x00-\x08\x0B-\x1F\x7F-\x9F]', '')
}

function Write-HermesHost {
    <#
    .SYNOPSIS
        Write-Host with control sequences removed from the text (see ConvertTo-ConsoleSafeText).
    .DESCRIPTION
        All module output goes through here; it takes the same parameters as Write-Host.
        A console UI library writes to the host by design, so the analyzer rule is suppressed.
        When the NO_COLOR environment variable is set to any value (https://no-color.org),
        colors are dropped and the text is written in the terminal's default color.
        A color can also be "#RRGGBB": in a terminal with virtual terminal sequences it is written in
        that exact color, elsewhere in the nearest console color.
        A handler registered with Register-ConsoleOutputHandler receives a copy of every write, with
        the color as given. A status line (Write-ConsoleStatusLine) is cleared before anything else is
        written, so it never mixes with normal output.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Console UI components write to the host by design.')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [object[]]$Object,
        [switch]$NoNewline,
        [object]$Separator,
        $ForegroundColor,
        $BackgroundColor
    )

    if ($script:HermesOutput.StatusLineActive) { Clear-ConsoleStatusLine }
    if ($PSBoundParameters.ContainsKey('Object')) {
        # A loop instead of a pipeline: this runs for every piece of text the module writes.
        $clean = [object[]]::new($Object.Count)
        for ($i = 0; $i -lt $Object.Count; $i++) {
            $text = [string]$Object[$i]
            $clean[$i] = if ($script:HermesControlRegex.IsMatch($text)) { ConvertTo-ConsoleSafeText -Text $text } else { $text }
        }
        $PSBoundParameters['Object'] = $clean
    }
    if (-not [string]::IsNullOrEmpty($env:NO_COLOR)) {
        $null = $PSBoundParameters.Remove('ForegroundColor')
        $null = $PSBoundParameters.Remove('BackgroundColor')
    }
    if (-not $script:HermesOutput.Quiet) {
        $codes = [System.Collections.Generic.List[string]]::new()
        foreach ($name in 'ForegroundColor', 'BackgroundColor') {
            $value = [string]$PSBoundParameters[$name]
            if ($value -notmatch '^#[0-9A-Fa-f]{6}$') { continue }
            if (Test-HermesTrueColor) {
                $rgb = @(1, 3, 5 | ForEach-Object { [Convert]::ToInt32($value.Substring($_, 2), 16) })
                $codes.Add(('{0};2;{1};{2};{3}' -f $(if ($name -eq 'ForegroundColor') { 38 } else { 48 }), $rgb[0], $rgb[1], $rgb[2]))
                $null = $PSBoundParameters.Remove($name)
            }
            else { $PSBoundParameters[$name] = ConvertTo-NearestConsoleColor -Hex $value }
        }
        if ($codes.Count -and $PSBoundParameters.ContainsKey('Object')) {
            # The escape sequences are added after the text was cleaned: they are the module's own.
            $joiner = if ($PSBoundParameters.ContainsKey('Separator')) { [string]$Separator } else { ' ' }
            $esc = [char]27
            $PSBoundParameters['Object'] = @("$esc[$($codes -join ';')m" + (@($PSBoundParameters['Object']) -join $joiner) + "$esc[0m")
            $null = $PSBoundParameters.Remove('Separator')
        }
        Write-Host @PSBoundParameters
    }

    if (($script:HermesOutput.Handler -or $script:HermesOutput.Capture) -and -not $script:HermesOutput.Paused) {
        $separator = if ($PSBoundParameters.ContainsKey('Separator')) { [string]$Separator } else { ' ' }
        $text = if ($PSBoundParameters.ContainsKey('Object')) { @($clean) -join $separator } else { '' }
        $color = if ($PSBoundParameters.ContainsKey('ForegroundColor') -or $ForegroundColor) { [string]$ForegroundColor } else { '' }
        if (-not [string]::IsNullOrEmpty($env:NO_COLOR)) { $color = '' }
        Send-HermesOutput -Text $text -NoNewline ([bool]$NoNewline) -Color $color
    }
}

function Send-HermesOutput {
    <#
    .SYNOPSIS
        Passes a piece of output to the output handler and to the capture file, when there are.
    .DESCRIPTION
        A failing handler or a capture file that cannot be written must not break the user interface.
    #>
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Text, [bool]$NoNewline, [AllowEmptyString()][string]$Color)

    if ($script:HermesOutput.Paused) { return }
    if ($script:HermesOutput.Handler) {
        try { & $script:HermesOutput.Handler $Text $NoNewline $Color } catch { Write-Verbose "Output handler failed: $($_.Exception.Message)" }
    }
    $capture = $script:HermesOutput.Capture
    if ($capture) {
        $null = $capture.Line.Append($Text)
        if (-not $NoNewline) {
            try { [System.IO.File]::AppendAllText($capture.Path, $capture.Line.ToString() + "`n", $capture.Encoding) } catch { Write-Verbose "Capture failed: $($_.Exception.Message)" }
            $null = $capture.Line.Clear()
        }
    }
}

# Virtual terminal codes of the console colors, for lines written in one call (Write-HermesSegment).
$script:HermesAnsiColor = @{
    Black = 30; DarkRed = 31; DarkGreen = 32; DarkYellow = 33; DarkBlue = 34; DarkMagenta = 35; DarkCyan = 36; Gray = 37
    DarkGray = 90; Red = 91; Green = 92; Yellow = 93; Blue = 94; Magenta = 95; Cyan = 96; White = 97
}

function Write-HermesSegment {
    <#
    .SYNOPSIS
        Writes one line made of (text, color) pairs, then ends it unless -NoNewline.
    .DESCRIPTION
        Where the console understands virtual terminal sequences the whole line is written with one Write-Host
        call, with the colors as escape sequences: much faster than one call per color, and the line is never
        split by other output. Elsewhere, and when NO_COLOR is set, each piece is written with Write-HermesHost
        (with NO_COLOR, as one plain call). The handler and the capture receive the pieces as with separate
        writes: each piece without a new line, then the end of the line.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Console UI components write to the host by design.')]
    [CmdletBinding()]
    param([AllowEmptyCollection()][object[]]$Segments, [switch]$NoNewline)

    $noColor = -not [string]::IsNullOrEmpty($env:NO_COLOR)
    $vt = -not $noColor -and -not $script:HermesOutput.Quiet -and (Test-HermesTrueColor)
    if (-not $vt -and -not $noColor) {
        foreach ($segment in $Segments) {
            if ($segment[1]) { Write-HermesHost $segment[0] -NoNewline -ForegroundColor $segment[1] } else { Write-HermesHost $segment[0] -NoNewline }
        }
        if (-not $NoNewline) { Write-HermesHost '' }
        return
    }

    if ($script:HermesOutput.StatusLineActive) { Clear-ConsoleStatusLine }
    $esc = [char]27
    $line = [System.Text.StringBuilder]::new()
    $current = $null
    $pieces = [System.Collections.Generic.List[object]]::new()
    foreach ($segment in $Segments) {
        $text = [string]$segment[0]
        if ($script:HermesControlRegex.IsMatch($text)) { $text = ConvertTo-ConsoleSafeText -Text $text }
        $color = if ($noColor) { '' } else { [string]$segment[1] }
        $pieces.Add(@($text, $color))
        if ($vt -and $color -ne $current) {
            if ($color -match '^#[0-9A-Fa-f]{6}$') {
                $null = $line.Append(('{0}[38;2;{1};{2};{3}m' -f $esc, [Convert]::ToInt32($color.Substring(1, 2), 16), [Convert]::ToInt32($color.Substring(3, 2), 16), [Convert]::ToInt32($color.Substring(5, 2), 16)))
            }
            elseif ($color -and $script:HermesAnsiColor.ContainsKey($color)) { $null = $line.Append("$esc[$($script:HermesAnsiColor[$color])m") }
            else { $null = $line.Append("$esc[39m") }
            $current = $color
        }
        $null = $line.Append($text)
    }
    if ($vt -and $current) { $null = $line.Append("$esc[0m") }
    if (-not $script:HermesOutput.Quiet) { Write-Host $line.ToString() -NoNewline:$NoNewline }
    if (($script:HermesOutput.Handler -or $script:HermesOutput.Capture) -and -not $script:HermesOutput.Paused) {
        foreach ($piece in $pieces) { Send-HermesOutput -Text $piece[0] -NoNewline $true -Color $piece[1] }
        if (-not $NoNewline) { Send-HermesOutput -Text '' -NoNewline $false -Color '' }
    }
}

# The output state in one place: the handler (Register-ConsoleOutputHandler) and its quiet mode; Paused while a list
# is redrawn in place (Read-ConsoleSelection: the handler gets the answer, not every redraw); a status line on
# screen (Write-ConsoleStatusLine); and the capture to a file (Start-ConsoleCapture).
$script:HermesOutput = @{ Handler = $null; Quiet = $false; Paused = $false; StatusLineActive = $false; Capture = $null }
# Tests set these to decide whether true color and live output are available.
$script:HermesTrueColorOverride = $null
$script:HermesLiveOverride = $null

function Send-HermesAnswer {
    <#
    .SYNOPSIS
        Passes what the user answered to the output handler (not to the screen, where it already is).
    .DESCRIPTION
        Read-Host writes the prompt and echoes the answer itself, without going through Write-HermesHost,
        so a capture would otherwise lose the questions and answers.
    #>
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Text)

    if (-not ($script:HermesOutput.Handler -or $script:HermesOutput.Capture) -or $script:HermesOutput.Paused) { return }
    Send-HermesOutput -Text (ConvertTo-ConsoleSafeText -Text $Text) -NoNewline $false -Color ''
}

function Test-HermesTrueColor {
    <#
    .SYNOPSIS
        True when "#RRGGBB" colors can be written exactly: a console that understands virtual terminal sequences.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($null -ne $script:HermesTrueColorOverride) { return [bool]$script:HermesTrueColorOverride }
    if ([Console]::IsOutputRedirected) { return $false }
    try { return [bool]$Host.UI.SupportsVirtualTerminal } catch { return $false }
}

# The classic console palette, to show "#RRGGBB" in the nearest of the 16 colors where true color is not available.
$script:HermesConsolePalette = [ordered]@{
    Black = 0, 0, 0; DarkBlue = 0, 0, 128; DarkGreen = 0, 128, 0; DarkCyan = 0, 128, 128
    DarkRed = 128, 0, 0; DarkMagenta = 128, 0, 128; DarkYellow = 128, 128, 0; Gray = 192, 192, 192
    DarkGray = 128, 128, 128; Blue = 0, 0, 255; Green = 0, 255, 0; Cyan = 0, 255, 255
    Red = 255, 0, 0; Magenta = 255, 0, 255; Yellow = 255, 255, 0; White = 255, 255, 255
}

function ConvertTo-NearestConsoleColor {
    <#
    .SYNOPSIS
        The console color closest to a "#RRGGBB" color.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$Hex)

    $r = [Convert]::ToInt32($Hex.Substring(1, 2), 16); $g = [Convert]::ToInt32($Hex.Substring(3, 2), 16); $b = [Convert]::ToInt32($Hex.Substring(5, 2), 16)
    $best = 'White'; $bestDistance = [double]::MaxValue
    foreach ($name in $script:HermesConsolePalette.Keys) {
        $c = $script:HermesConsolePalette[$name]
        $distance = [Math]::Pow($r - $c[0], 2) + [Math]::Pow($g - $c[1], 2) + [Math]::Pow($b - $c[2], 2)
        if ($distance -lt $bestDistance) { $best = $name; $bestDistance = $distance }
    }
    return $best
}

function Test-HermesLiveOutput {
    <#
    .SYNOPSIS
        True when output reaches a console that can be rewritten in place: not redirected, not only sent to
        an output handler (Register-ConsoleOutputHandler -Quiet), and not captured to a file (Start-ConsoleCapture).
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($script:HermesOutput.Capture) { return $false }
    if ($null -ne $script:HermesLiveOverride) { return [bool]$script:HermesLiveOverride }
    if ($script:HermesOutput.Quiet) { return $false }
    try { return -not [Console]::IsOutputRedirected } catch { return $false }
}

function Test-NoColor {
    <#
    .SYNOPSIS
        True when the NO_COLOR environment variable asks for output without colors.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return -not [string]::IsNullOrEmpty($env:NO_COLOR)
}

# Interactive selection reads keys through this script block and asks Test-InteractiveConsole
# whether it can; the tests replace both to drive the menus without a console.
$script:HermesReadKey = { [Console]::ReadKey($true) }
$script:HermesInteractiveOverride = $null

function Test-InteractiveConsole {
    <#
    .SYNOPSIS
        True when keys can be read one at a time and the screen redrawn: a real console with
        neither input nor output redirected (not the ISE, a pipe, a CI log or a remote session), and no capture
        to a file (Start-ConsoleCapture), which keeps the options and the typed answer instead.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($script:HermesOutput.Capture) { return $false }
    if ($script:HermesSimulation) { return $script:HermesSimulation.Interactive }
    if ($null -ne $script:HermesInteractiveOverride) { return [bool]$script:HermesInteractiveOverride }
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { return $false }
    if ($Host.Name -notin 'ConsoleHost', 'Visual Studio Code Host') { return $false }
    try { $null = [Console]::KeyAvailable; return $true }
    catch { return $false }
}

function Get-ConsoleCursorRow {
    <#
    .SYNOPSIS
        Current cursor row, or -1 when there is no console to ask.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param()

    try { return [Console]::CursorTop } catch { return -1 }
}

function Set-ConsoleCursorRow {
    <#
    .SYNOPSIS
        Moves the cursor to the start of a row; does nothing without a console.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Moves the console cursor only.')]
    [CmdletBinding()]
    param([int]$Row)

    if ($Row -lt 0) { return }
    try { [Console]::SetCursorPosition(0, $Row) } catch { $null = $_ }
}

function Set-ConsoleCursorVisible {
    <#
    .SYNOPSIS
        Shows or hides the cursor where the console allows it; returns the previous state.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Changes the console cursor only.')]
    [CmdletBinding()]
    [OutputType([bool])]
    param([bool]$Visible)

    $previous = $true
    try { $previous = [Console]::CursorVisible } catch { $null = $_ }
    try { [Console]::CursorVisible = $Visible } catch { $null = $_ }
    return $previous
}

function Resolve-UIColor {
    <#
    .SYNOPSIS
        Returns the color the caller passed, or the active theme's color for the given role.
    .DESCRIPTION
        Components call this for every color parameter, so Set-ConsoleTheme changes their
        default colors while an explicit -Color still wins.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()][AllowEmptyString()][string]$Color,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Primary', 'Secondary', 'Success', 'Warning', 'Error', 'Info', 'Muted', 'Highlight')]
        [string]$Role
    )

    if (-not [string]::IsNullOrWhiteSpace($Color)) { return $Color }
    return (Get-UIColor -ColorType $Role -WarningAction SilentlyContinue)
}

function Get-UIText {
    <#
    .SYNOPSIS
        Returns a localized UI string, or the English default if the key is missing.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Default
    )

    $text = Get-LocalizedString -Key $Key -DefaultValue $Default -WarningAction SilentlyContinue
    if ([string]::IsNullOrEmpty($text)) { return $Default }
    return [string]$text
}

function Test-ClearScreenAllowed {
    <#
    .SYNOPSIS
        True unless clearing the screen has been turned off for this session.
    .DESCRIPTION
        Set $env:HERMESCONSOLEUI_NOCLEAR to 1 (or true) to keep earlier output on screen,
        for example while debugging. Applications with their own debug switch set this variable
        from it; the module reads no variable of the calling application.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return -not ($env:HERMESCONSOLEUI_NOCLEAR -match '^(1|true|yes)$')
}

function Get-CenteredText {
    <#
    .SYNOPSIS
        Centers text within a specified width.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [int]$Width
    )

    # Only control sequences are removed: accented letters and other non-ASCII text stay.
    $cleanText = (ConvertTo-ConsoleSafeText -Text $Text).Trim()
    $textWidth = Measure-ConsoleText -Text $cleanText
    if ($textWidth -ge $Width) { return $cleanText }

    $padding = ' ' * [Math]::Floor(($Width - $textWidth) / 2)
    return "$padding$cleanText"
}

function Test-EmojiSupport {
    <#
    .SYNOPSIS
        Tests whether the current console is likely to display emoji characters.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        if ($PSVersionTable.PSVersion.Major -ge 6) { return $true }
        return ([Console]::OutputEncoding.CodePage -eq 65001)
    }
    catch {
        return $false
    }
}

function Merge-LayoutColumn {
    <#
    .SYNOPSIS
        Merges several columns (arrays of lines) into one array of padded lines.
    .DESCRIPTION
        Each line is cut with an ellipsis to its column width and padded, measuring the width the text takes
        on screen (wide characters take two columns).
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Columns,

        [Parameter(Mandatory = $true)]
        [array]$Widths
    )

    $maxLines = 0
    foreach ($col in $Columns) {
        if ($col.Count -gt $maxLines) { $maxLines = $col.Count }
    }

    $expectedTotal = ($Widths | Measure-Object -Sum).Sum + (($Columns.Count - 1) * 2)
    $mergedLines = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $maxLines; $i++) {
        $line = ''
        for ($c = 0; $c -lt $Columns.Count; $c++) {
            $colContent = $Columns[$c]
            $content = ''
            if ($null -ne $colContent -and $colContent -is [array] -and $i -lt $colContent.Count) {
                $content = [string]$colContent[$i]
            }
            $line += (Format-ConsoleText -Text $content -Width $Widths[$c] -Align Left) + '  '
        }

        # Pad the whole line so it overwrites any longer line left on screen.
        $finalLine = $line.TrimEnd()
        $mergedLines.Add($finalLine + (' ' * [Math]::Max(0, ($expectedTotal - (Measure-ConsoleText -Text $finalLine)))))
    }
    return $mergedLines.ToArray()
}

function Get-ComponentIcon {
    <#
    .SYNOPSIS
        Returns the icon for a component, using emoji only when the console supports them.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Metadata', 'Summary', 'Success', 'Warning', 'Error', 'Info')]
        [string]$ComponentType
    )

    # Safe icons that render in every console font (Unicode BMP).
    $safeIcons = @{
        Metadata = [string][char]0x2699    # gear
        Summary  = [string][char]0x25A3    # square
        Success  = [string][char]0x221A    # check root
        Warning  = [string][char]0x26A0    # warning sign
        Error    = [string][char]0x2715    # multiplication x
        Info     = '[i]'
    }

    if (-not (Test-EmojiSupport)) { return $safeIcons[$ComponentType] }

    switch ($ComponentType) {
        'Summary' { return [System.Char]::ConvertFromUtf32(0x1F4CA) }   # bar chart
        'Success' { return [string][char]0x2714 }                       # heavy check
        'Error'   { return [string][char]0x2716 }                       # heavy x
        default   { return $safeIcons[$ComponentType] }
    }
}
