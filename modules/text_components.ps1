# HermesConsoleUI - text components.
#
# Titles, headers, status messages and other single-line text output.
# Every color parameter defaults to the active theme (see Set-ConsoleTheme).

function Write-ConsoleTitle {
    <#
    .SYNOPSIS
        Displays a centered title between two border lines.

    .DESCRIPTION
        Writes the title centered between two lines of equal signs. The block is at least
        60 characters wide and grows with longer titles. The color defaults to the Primary
        color of the active theme.

    .PARAMETER Title
        The title text to display.

    .PARAMETER Color
        Console color for the title and borders. Defaults to the theme's Primary color.

    .EXAMPLE
        Write-ConsoleTitle -Title "System Report"

        Displays a centered title with borders in the theme's Primary color.

    .EXAMPLE
        Write-ConsoleTitle -Title "Critical Alert" -Color Red

        Displays a centered title with red borders.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [string]$Color
    )

    $Color = Resolve-UIColor -Color $Color -Role Primary
    $width = [Math]::Max($Title.Length + 4, 60)
    $border = '=' * $width

    Write-HermesHost ''
    Write-HermesHost $border -ForegroundColor $Color
    Write-HermesHost (Get-CenteredText -Text $Title -Width $width) -ForegroundColor $Color
    Write-HermesHost $border -ForegroundColor $Color
    Write-HermesHost ''
}

function Write-ConsoleHeader {
    <#
    .SYNOPSIS
        Displays a section header with a ">>>" prefix.

    .DESCRIPTION
        Writes a section header preceded by ">>>" and surrounded by blank lines, to mark the
        start of a major section in console output. The color defaults to the Secondary
        color of the active theme.

    .PARAMETER Text
        The header text to display. Alias: Title.

    .PARAMETER Color
        Console color for the header. Defaults to the theme's Secondary color.

    .EXAMPLE
        Write-ConsoleHeader -Text "Configuration Settings"

        Displays ">>> Configuration Settings".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Title')]
        [string]$Text,

        [string]$Color
    )

    $Color = Resolve-UIColor -Color $Color -Role Secondary
    Write-HermesHost ''
    Write-HermesHost ('>>> ' + $Text) -ForegroundColor $Color
    Write-HermesHost ''
}

function Write-ConsoleSubtitle {
    <#
    .SYNOPSIS
        Displays a subsection title in brackets, with an optional count.

    .DESCRIPTION
        Writes a subsection title such as "[Processing Files]". When -Count is zero or more,
        the count is shown in parentheses: "[Found Items (42)]". The color defaults to the
        Primary color of the active theme.

    .PARAMETER Text
        The subtitle text to display.

    .PARAMETER Count
        Optional count shown in parentheses. Negative values (the default, -1) omit it.

    .PARAMETER Color
        Console color for the subtitle. Defaults to the theme's Primary color.

    .EXAMPLE
        Write-ConsoleSubtitle -Text "Processing Files"

        Displays "[Processing Files]".

    .EXAMPLE
        Write-ConsoleSubtitle -Text "Found Items" -Count 42

        Displays "[Found Items (42)]".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text,

        [int]$Count = -1,

        [string]$Color
    )

    $Color = Resolve-UIColor -Color $Color -Role Primary
    Write-HermesHost ''
    if ($Count -ge 0) {
        Write-HermesHost ('  [' + $Text + ' (' + $Count + ')]') -ForegroundColor $Color
    }
    else {
        Write-HermesHost ('  [' + $Text + ']') -ForegroundColor $Color
    }
}

function Write-ConsoleError {
    <#
    .SYNOPSIS
        Displays an error message with an error icon.

    .DESCRIPTION
        Writes "ERROR: <message>" with an error icon, in the Error color of the active theme.
        With -Exception, the exception message is shown on a second line as details.
        This only displays text: it does not write to the error stream or stop the script.
        Accepts pipeline input to report several errors at once.

    .PARAMETER Message
        The error message to display. Accepts pipeline input.

    .PARAMETER Exception
        Optional details: an exception, an error record (such as $_ in a catch block) or a string.

    .EXAMPLE
        Write-ConsoleError -Message "Failed to connect to database"

        Displays "ERROR: Failed to connect to database" with an error icon.

    .EXAMPLE
        "Error 1", "Error 2" | Write-ConsoleError

        Displays one error line per piped message.

    .EXAMPLE
        try { Get-Item C:\missing -ErrorAction Stop } catch { Write-ConsoleError -Message "Could not read the file" -Exception $_ }

        Displays the error and, on a second line, the exception message.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [object]$Exception
    )

    begin {
        $color = Resolve-UIColor -Role Error
        $icon = Get-ComponentIcon -ComponentType 'Error'
        $details = if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception.Exception.Message }
        elseif ($Exception -is [System.Exception]) { $Exception.Message }
        elseif ($null -ne $Exception) { [string]$Exception }
    }
    process {
        Write-HermesHost ('  ' + $icon + ' ERROR: ' + $Message) -ForegroundColor $color
        if ($details) { Write-HermesHost ('      ' + $details) -ForegroundColor (Resolve-UIColor -Role Muted) }
    }
}

function Write-ConsoleInfo {
    <#
    .SYNOPSIS
        Displays an informational message with an info icon.

    .DESCRIPTION
        Writes the message preceded by an "[i]" icon. The color defaults to the Highlight
        color of the active theme. Accepts pipeline input.

    .PARAMETER Message
        The informational message to display. Accepts pipeline input.

    .PARAMETER Color
        Console color for the message. Defaults to the theme's Highlight color.

    .EXAMPLE
        Write-ConsoleInfo -Message "Loading configuration..."

        Displays "[i] Loading configuration...".

    .EXAMPLE
        "Step 1", "Step 2", "Step 3" | Write-ConsoleInfo

        Displays one info line per piped message.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [string]$Color
    )

    begin {
        $Color = Resolve-UIColor -Color $Color -Role Highlight
        $icon = Get-ComponentIcon -ComponentType 'Info'
    }
    process {
        Write-HermesHost ('  ' + $icon + ' ' + $Message) -ForegroundColor $Color
    }
}

function Write-ConsoleStatus {
    <#
    .SYNOPSIS
        Displays a status message with an icon and a color for its type.

    .DESCRIPTION
        Writes the message with an icon and the theme color that matches -Type: Success,
        Warning, Error or Info. Accepts pipeline input.

    .PARAMETER Message
        The status message to display. Accepts pipeline input.

    .PARAMETER Type
        The kind of status: Success, Warning, Error or Info (the default).

    .EXAMPLE
        Write-ConsoleStatus -Message "Operation completed" -Type Success

        Displays the message with a success icon in the theme's Success color.

    .EXAMPLE
        "Task 1", "Task 2", "Task 3" | Write-ConsoleStatus -Type Success

        Displays one success line per piped message.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet('Success', 'Warning', 'Error', 'Info')]
        [string]$Type = 'Info'
    )

    begin {
        $icon = Get-ComponentIcon -ComponentType $Type
        $color = Resolve-UIColor -Role $Type
    }
    process {
        Write-HermesHost ('  ' + $icon + ' ' + $Message) -ForegroundColor $color
    }
}

function Write-ConsoleMetadata {
    <#
    .SYNOPSIS
        Displays a hashtable as a titled list of key-value pairs.

    .DESCRIPTION
        Writes a section title followed by one "key: value" line per entry, for example to
        show the settings a script will run with. Keys use the theme's Muted color and
        values its Highlight color. Use an ordered hashtable to control the order.

    .PARAMETER Metadata
        Hashtable (or ordered dictionary) with the key-value pairs to display.

    .PARAMETER Title
        Title of the section. Defaults to "Configuration".

    .EXAMPLE
        Write-ConsoleMetadata -Metadata ([ordered]@{ Version = "2.2.0"; License = "MIT" }) -Title "Module Info"

        Displays the two entries under the title "Module Info".
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Metadata is a mass noun; renaming would break existing scripts.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$Metadata,

        [string]$Title = 'Configuration'
    )

    $muted = Resolve-UIColor -Role Muted
    $highlight = Resolve-UIColor -Role Highlight
    $icon = Get-ComponentIcon -ComponentType 'Metadata'

    Write-HermesHost ''
    Write-HermesHost "  $icon [CONFIG] $Title" -ForegroundColor $muted
    foreach ($key in $Metadata.Keys) {
        Write-HermesHost ('    ' + [char]0x2022 + ' ' + $key + ': ') -NoNewline -ForegroundColor $muted
        Write-HermesHost ([string]$Metadata[$key]) -ForegroundColor $highlight
    }
    Write-HermesHost ''
}

function Write-ConsoleSummary {
    <#
    .SYNOPSIS
        Displays a summary section with labeled values.

    .DESCRIPTION
        Writes a title, a separator line, one "label: value" line per item and a closing
        separator. Each item is a hashtable or object with Label and Value, and optionally
        Color to highlight that line.

    .PARAMETER Title
        Title of the summary section.

    .PARAMETER Items
        Items to display. Each one needs Label and Value, and may have Color.

    .EXAMPLE
        $items = @(
            @{ Label = "Total"; Value = 100 }
            @{ Label = "Passed"; Value = 95; Color = "Green" }
            @{ Label = "Failed"; Value = 5; Color = "Red" }
        )
        Write-ConsoleSummary -Title "Test Results" -Items $items

        Displays the three values under "Test Results", with Passed and Failed colored.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [array]$Items
    )

    $primary = Resolve-UIColor -Role Primary
    $muted = Resolve-UIColor -Role Muted
    $highlight = Resolve-UIColor -Role Highlight
    $icon = Get-ComponentIcon -ComponentType 'Summary'
    $rule = '  ' + ([string][char]0x2501 * ($Title.Length + 12))
    $bullet = [char]0x25B8

    Write-HermesHost ''
    Write-HermesHost "  $icon [RESULTS] $Title" -ForegroundColor $primary
    Write-HermesHost $rule -ForegroundColor $muted
    foreach ($item in $Items) {
        if ($item.Color) {
            Write-HermesHost ('    ' + $bullet + ' ' + $item.Label + ': ' + $item.Value) -ForegroundColor $item.Color
        }
        else {
            Write-HermesHost ('    ' + $bullet + ' ' + $item.Label + ': ') -NoNewline -ForegroundColor $muted
            Write-HermesHost ([string]$item.Value) -ForegroundColor $highlight
        }
    }
    Write-HermesHost $rule -ForegroundColor $muted
    Write-HermesHost ''
}

function Write-ConsoleDiff {
    <#
    .SYNOPSIS
        Displays a before and after comparison of a value.

    .DESCRIPTION
        Writes the label, then the previous value in the theme's Error color and the current
        value in its Success color, to show what a change did.

    .PARAMETER Label
        Name of the value that changed.

    .PARAMETER OldValue
        The previous value.

    .PARAMETER NewValue
        The current value.

    .EXAMPLE
        Write-ConsoleDiff -Label "Version" -OldValue "1.0.0" -NewValue "2.0.0"

        Displays:
          Version:
            [-] Previous: 1.0.0
            [+] Current:  2.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$OldValue,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$NewValue
    )

    Write-HermesHost ('  ' + $Label + ':') -ForegroundColor (Resolve-UIColor -Role Primary)
    Write-HermesHost ('    [-] Previous: ' + $OldValue) -ForegroundColor (Resolve-UIColor -Role Error)
    Write-HermesHost ('    [+] Current:  ' + $NewValue) -ForegroundColor (Resolve-UIColor -Role Success)
    Write-HermesHost ''
}

function Write-ConsoleSeparator {
    <#
    .SYNOPSIS
        Displays a horizontal separator line.

    .DESCRIPTION
        Writes a line made of one repeated character to separate sections of output. The
        color defaults to the Muted color of the active theme.

    .PARAMETER Character
        Character (or short string) to repeat. Defaults to "-".

    .PARAMETER Length
        Number of times to repeat it, from 1 to 200. Defaults to 60.

    .PARAMETER Color
        Console color for the line. Defaults to the theme's Muted color.

    .EXAMPLE
        Write-ConsoleSeparator

        Displays a line of 60 dashes.

    .EXAMPLE
        Write-ConsoleSeparator -Character "=" -Length 40 -Color Cyan

        Displays 40 equal signs in cyan.
    #>
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Character = '-',

        [ValidateRange(1, 200)]
        [int]$Length = 60,

        [string]$Color
    )

    $Color = Resolve-UIColor -Color $Color -Role Muted
    Write-HermesHost ('  ' + ($Character * $Length)) -ForegroundColor $Color
}

function Write-ConsoleBreadcrumb {
    <#
    .SYNOPSIS
        Displays a navigation breadcrumb trail.

    .DESCRIPTION
        Joins the path segments with a separator to show where the user is in a menu
        hierarchy, for example "Home > Settings > Display". The color defaults to the
        Muted color of the active theme.

    .PARAMETER Path
        The path segments, from the top level down.

    .PARAMETER Separator
        Text placed between segments. Defaults to " > ".

    .PARAMETER Color
        Console color for the breadcrumb. Defaults to the theme's Muted color.

    .EXAMPLE
        Write-ConsoleBreadcrumb -Path "Home", "Settings", "Display"

        Displays "Home > Settings > Display".

    .EXAMPLE
        Write-ConsoleBreadcrumb -Path "C:", "Users", "Documents" -Separator " / "

        Displays "C: / Users / Documents".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [string]$Separator = ' > ',

        [string]$Color
    )

    $Color = Resolve-UIColor -Color $Color -Role Muted
    Write-HermesHost ('  ' + ($Path -join $Separator)) -ForegroundColor $Color
}
