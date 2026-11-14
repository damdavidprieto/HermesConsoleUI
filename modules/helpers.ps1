# HermesConsoleUI - private helper functions.
#
# Used by the public components: safe console output, theme and locale lookups,
# text centering, icons and the layout column merge. Nothing here is exported.

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

    if ([string]::IsNullOrEmpty($Text)) { return $Text }
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

    if ($PSBoundParameters.ContainsKey('Object')) {
        $PSBoundParameters['Object'] = @($Object | ForEach-Object { ConvertTo-ConsoleSafeText -Text ([string]$_) })
    }
    Write-Host @PSBoundParameters
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
        for example while debugging. $Global:CassielDevMode is still honoured for
        compatibility with Cassiel, which used it before this setting existed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Read-only compatibility with Cassiel, which sets this variable.')]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($env:HERMESCONSOLEUI_NOCLEAR -match '^(1|true|yes)$') { return $false }
    if ($Global:CassielDevMode) { return $false }
    return $true
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
    if ($cleanText.Length -ge $Width) { return $cleanText }

    $padding = ' ' * [Math]::Floor(($Width - $cleanText.Length) / 2)
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
    $mergedLines = @()
    for ($i = 0; $i -lt $maxLines; $i++) {
        $line = ''
        for ($c = 0; $c -lt $Columns.Count; $c++) {
            $colContent = $Columns[$c]
            $width = $Widths[$c]

            $content = ''
            if ($null -ne $colContent -and $colContent -is [array] -and $i -lt $colContent.Count) {
                $content = [string]$colContent[$i]
            }

            $cleanContent = (ConvertTo-ConsoleSafeText -Text $content) -replace '[\n\t]', ' '
            if ($cleanContent.Length -gt $width) {
                $cleanContent = $cleanContent.Substring(0, $width)
            }
            $line += $cleanContent + (' ' * [Math]::Max(0, ($width - $cleanContent.Length))) + '  '
        }

        # Pad the whole line so it overwrites any longer line left on screen.
        $finalLine = $line.TrimEnd()
        $mergedLines += ($finalLine + (' ' * [Math]::Max(0, ($expectedTotal - $finalLine.Length))))
    }
    return $mergedLines
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
