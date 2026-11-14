<#
.SYNOPSIS
    PSConsoleUI - Text Components
    
.DESCRIPTION
    Text-based UI components for console output.
    Includes titles, headers, status messages, and text formatting functions.
#>

# --- UI TEXT COMPONENTS ---

function Write-ConsoleTitle {
    <#
    .SYNOPSIS
        Displays a centered title with decorative borders.
    
    .DESCRIPTION
        Writes a formatted title to the console with equal sign borders above and below.
        The title is automatically centered and padded to a minimum width of 60 characters.
    
    .PARAMETER Title
        The title text to display.
    
    .PARAMETER Color
        The color to use for the title and borders. Default: Cyan
    
    .EXAMPLE
        Write-ConsoleTitle -Title "System Report"
        
        Displays a centered title with cyan borders.
    
    .EXAMPLE
        Write-ConsoleTitle -Title "Critical Alert" -Color Red
        
        Displays a centered title with red borders.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        
        [Parameter(Mandatory=$false)]
        [string]$Color = 'Cyan'
    )
    
    # Calculate width and create ANSI-safe border
    $width = [Math]::Max($Title.Length + 4, 60)
    $border = '=' * $width
    
    # Get centered text (helpers handles sanitization)
    $centeredTitle = Get-CenteredText -Text $Title -Width $width
    
    Write-HermesHost ''
    Write-HermesHost $border -ForegroundColor $Color
    Write-HermesHost $centeredTitle -ForegroundColor $Color
    Write-HermesHost $border -ForegroundColor $Color
    Write-HermesHost ''
}

function Write-ConsoleHeader {
    <#
    .SYNOPSIS
        Displays a section header with arrow prefix.
    
    .DESCRIPTION
        Writes a formatted section header to the console with >>> prefix.
        Used to denote major sections in console output.
    
    .PARAMETER Text
        The header text to display.
    
    .PARAMETER Color
        The color to use for the header. Default: Yellow
    
    .EXAMPLE
        Write-ConsoleHeader -Text "Configuration Settings"
        
        Displays: >>> Configuration Settings (in yellow)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [string]$Color = 'Yellow'
    )
    
    Write-HermesHost ''
    Write-HermesHost ('>>> ' + $Text) -ForegroundColor $Color
    Write-HermesHost ''
}

function Write-ConsoleSubtitle {
    <#
    .SYNOPSIS
        Displays a subsection title with optional count.
    
    .DESCRIPTION
        Writes a formatted subsection title to the console in brackets.
        Optionally displays a count in parentheses.
    
    .PARAMETER Text
        The subtitle text to display.
    
    .PARAMETER Count
        Optional count to display in parentheses. Use -1 to omit count. Default: -1
    
    .PARAMETER Color
        The color to use for the subtitle. Default: Cyan
    
    .EXAMPLE
        Write-ConsoleSubtitle -Text "Processing Files"
        
        Displays: [Processing Files]
    
    .EXAMPLE
        Write-ConsoleSubtitle -Text "Found Items" -Count 42
        
        Displays: [Found Items (42)]
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [int]$Count = -1,
        
        [Parameter(Mandatory=$false)]
        [string]$Color = 'Cyan'
    )
    
    Write-HermesHost ''
    if ($Count -ge 0) {
        Write-HermesHost ('  [' + $Text + ' (' + $Count + ')]') -ForegroundColor $Color
    } else {
        Write-HermesHost ('  [' + $Text + ']') -ForegroundColor $Color
    }
}

function Write-ConsoleError {
    <#
    .SYNOPSIS
        Displays an error message with an error icon.
    
    .DESCRIPTION
        Writes a formatted error message to the console in red with an [!] ERROR: prefix.
        Supports pipeline input for batch error reporting.
    
    .PARAMETER Message
        The error message to display. Can be piped from other commands.
    
    .EXAMPLE
        Write-ConsoleError -Message "Failed to connect to database"
        
        Displays: [!] ERROR: Failed to connect to database (in red)
    
    .EXAMPLE
        "Error 1", "Error 2" | Write-ConsoleError
        
        Displays multiple error messages via pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )
    
    process {
        $icon = Get-ComponentIcon -ComponentType 'Error'
        Write-HermesHost ('  ' + $icon + ' ERROR: ' + $Message) -ForegroundColor Red
    }
}

function Write-ConsoleInfo {
    <#
    .SYNOPSIS
        Displays an informational message with an info icon.
    
    .DESCRIPTION
        Writes a formatted informational message to the console with an [i] icon.
        Supports pipeline input and custom colors.
    
    .PARAMETER Message
        The informational message to display. Can be piped from other commands.
    
    .PARAMETER Color
        The color to use for the message. Default: White
    
    .EXAMPLE
        Write-ConsoleInfo -Message "Loading configuration..."
        
        Displays: [i] Loading configuration...
    
    .EXAMPLE
        "Step 1", "Step 2", "Step 3" | Write-ConsoleInfo
        
        Displays multiple info messages via pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$Color = 'White'
    )
    
    process {
        $icon = Get-ComponentIcon -ComponentType 'Info'
        Write-HermesHost ('  ' + $icon + ' ' + $Message) -ForegroundColor $Color
    }
}

function Write-ConsoleStatus {
    <#
    .SYNOPSIS
        Displays a status message with an icon and color coding.
    
    .DESCRIPTION
        Writes a formatted status message to the console with automatic color coding
        based on the message type (Success, Warning, Error, Info). Supports pipeline input.
    
    .PARAMETER Message
        The status message to display. Can be piped from other commands.
    
    .PARAMETER Type
        The type of status message. Valid values: Success, Warning, Error, Info.
        Default: Info
    
    .EXAMPLE
        Write-ConsoleStatus -Message "Operation completed" -Type Success
        
        Displays: [+] Operation completed (in green)
    
    .EXAMPLE
        "Task 1", "Task 2", "Task 3" | Write-ConsoleStatus -Type Success
        
        Displays multiple success messages via pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Success', 'Warning', 'Error', 'Info')]
        [string]$Type = 'Info'
    )
    
    process {
        $icon = switch ($Type) {
            'Success' { Get-ComponentIcon -ComponentType 'Success'; $color = 'Green'; break }
            'Warning' { Get-ComponentIcon -ComponentType 'Warning'; $color = 'Yellow'; break }
            'Error'   { Get-ComponentIcon -ComponentType 'Error';   $color = 'Red'; break }
            default   { Get-ComponentIcon -ComponentType 'Info';    $color = 'Cyan' }
        }
        Write-HermesHost ('  ' + $icon + ' ' + $Message) -ForegroundColor $color
    }
}

function Write-ConsoleMetadata {
    <#
    .SYNOPSIS
        Displays a hashtable of metadata as key-value pairs.
    
    .DESCRIPTION
        Writes a formatted metadata section to the console with a title and
        key-value pairs displayed in a readable format.
    
    .PARAMETER Metadata
        Hashtable containing metadata key-value pairs.
    
    .PARAMETER Title
        Title for the metadata section. Default: "Configuracion"
    
    .EXAMPLE
        $meta = @{
            "Version" = "2.0.0"
            "Author" = "PSConsoleUI Team"
            "License" = "MIT"
        }
        Write-ConsoleMetadata -Metadata $meta -Title "Module Info"
        
        Displays formatted metadata with custom title.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [hashtable]$Metadata,
        
        [Parameter(Mandatory=$false)]
        [string]$Title = 'Configuracion'
    )
    
    $icon = Get-ComponentIcon -ComponentType 'Metadata'
    
    Write-HermesHost ''
    Write-HermesHost "  $icon [CONFIG] $Title" -ForegroundColor Gray
    foreach ($key in $Metadata.Keys) {
        Write-HermesHost ('    ' + [char]0x2022 + ' ' + $key + ': ') -NoNewline -ForegroundColor Gray
        Write-HermesHost ([string]$Metadata[$key]) -ForegroundColor White
    }
    Write-HermesHost ''
}

function Write-ConsoleSummary {
    <#
    .SYNOPSIS
        Displays a summary section with labeled items.
    
    .DESCRIPTION
        Writes a formatted summary section with a title and list of items.
        Each item can have a label, value, and optional color.
    
    .PARAMETER Title
        Title for the summary section.
    
    .PARAMETER Items
        Array of items. Each item should have: Label, Value, and optionally Color.
    
    .EXAMPLE
        $items = @(
            @{Label="Total"; Value=100; Color="Cyan"}
            @{Label="Success"; Value=95; Color="Green"}
            @{Label="Failed"; Value=5; Color="Red"}
        )
        Write-ConsoleSummary -Title "Test Results" -Items $items
        
        Displays a formatted summary with colored values.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [array]$Items
    )
    
    $icon = Get-ComponentIcon -ComponentType 'Summary'
    $separator = [char]0x2501  # ━
    
    Write-HermesHost ''
    Write-HermesHost "  $icon [RESULTS] $Title" -ForegroundColor Cyan
    Write-HermesHost ('  ' + ($separator.ToString() * ($Title.Length + 12))) -ForegroundColor DarkGray
    foreach ($item in $Items) {
        $bullet = [char]0x25B8  # ▸
        if ($item.Color) {
            Write-HermesHost ('    ' + $bullet + ' ' + $item.Label + ': ' + $item.Value) -ForegroundColor $item.Color
        } else {
            Write-HermesHost ('    ' + $bullet + ' ' + $item.Label + ': ') -NoNewline -ForegroundColor Gray
            Write-HermesHost ([string]$item.Value) -ForegroundColor White
        }
    }
    Write-HermesHost ('  ' + ($separator.ToString() * ($Title.Length + 12))) -ForegroundColor DarkGray
    Write-HermesHost ''
}

function Write-ConsoleDiff {
    <#
    .SYNOPSIS
        Displays a before/after comparison of values.
    
    .DESCRIPTION
        Writes a formatted diff showing the previous value in red and
        the current value in green, useful for showing changes.
    
    .PARAMETER Label
        Label describing what changed.
    
    .PARAMETER OldValue
        The previous/old value.
    
    .PARAMETER NewValue
        The current/new value.
    
    .EXAMPLE
        Write-ConsoleDiff -Label "Version" -OldValue "1.0.0" -NewValue "2.0.0"
        
        Displays:
          Version:
            [-] Previous: 1.0.0
            [+] Current:  2.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Label,
        
        [Parameter(Mandatory=$true)]
        [string]$OldValue,
        
        [Parameter(Mandatory=$true)]
        [string]$NewValue
    )
    
    Write-HermesHost ('  ' + $Label + ':') -ForegroundColor Cyan
    Write-HermesHost ('    [-] Previous: ' + $OldValue) -ForegroundColor Red
    Write-HermesHost ('    [+] Current:  ' + $NewValue) -ForegroundColor Green
    Write-HermesHost ''
}

function Write-ConsoleSeparator {
    <#
    .SYNOPSIS
        Displays a horizontal separator line.
    
    .DESCRIPTION
        Writes a horizontal line to visually separate sections in console output.
    
    .PARAMETER Character
        Character to use for the separator. Default: '─'
    
    .PARAMETER Length
        Length of the separator. Default: 60
    
    .PARAMETER Color
        Color of the separator. Default: DarkGray
    
    .EXAMPLE
        Write-ConsoleSeparator
        
        Displays: ────────────────────────────────────────────────────────
    
    .EXAMPLE
        Write-ConsoleSeparator -Character "=" -Length 40 -Color Cyan
        
        Displays: ======================================== (in cyan)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Character = '-',
        
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 200)]
        [int]$Length = 60,
        
        [Parameter(Mandatory=$false)]
        [string]$Color = 'DarkGray'
    )
    
    Write-HermesHost ('  ' + ($Character * $Length)) -ForegroundColor $Color
}

function Write-ConsoleBreadcrumb {
    <#
    .SYNOPSIS
        Displays a navigation breadcrumb trail.
    
    .DESCRIPTION
        Writes a breadcrumb navigation path showing hierarchical location.
    
    .PARAMETER Path
        Array of path segments (e.g., @("Home", "Settings", "Display"))
    
    .PARAMETER Separator
        Separator between segments. Default: ' > '
    
    .PARAMETER Color
        Color for the breadcrumb. Default: Gray
    
    .EXAMPLE
        Write-ConsoleBreadcrumb -Path @("Home", "Settings", "Display")
        
        Displays: Home > Settings > Display
    
    .EXAMPLE
        Write-ConsoleBreadcrumb -Path @("C:", "Users", "Documents") -Separator " / "
        
        Displays: C: / Users / Documents
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [array]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Separator = ' > ',
        
        [Parameter(Mandatory=$false)]
        [string]$Color = 'Gray'
    )
    
    $breadcrumb = $Path -join $Separator
    Write-HermesHost ('  ' + $breadcrumb) -ForegroundColor $Color
}
