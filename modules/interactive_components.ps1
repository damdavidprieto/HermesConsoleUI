# HermesConsoleUI - interactive components.
#
# Menus, prompts, progress and notifications. Prompt texts come from the active locale
# (see Set-UILocale) and colors from the active theme (see Set-ConsoleTheme).

function Show-ConsoleMenu {
    <#
    .SYNOPSIS
        Displays a numbered menu and returns how many options can be selected.

    .DESCRIPTION
        Clears the screen (unless -NoClear is used or clearing is turned off for the session)
        and writes a title between borders followed by the options, numbered from 1.
        Two kinds of lines are not numbered: lines starting with "---" are separators and
        lines starting with "[" are section headers. An option can start with a color name
        in braces, such as "{Red}Delete everything", to be shown in that color.
        Use Read-ConsoleChoice to read the user's selection, or -ReturnIndex to show the menu
        and read the selection in one call. Invoke-ConsoleMenu also runs the selected action.
        Set $env:HERMESCONSOLEUI_NOCLEAR to 1 to keep earlier output on screen in every menu.

    .PARAMETER Title
        Title shown above the options.

    .PARAMETER Options
        Menu lines, in order: options, "---" separators and "[...]" section headers.

    .PARAMETER Color
        Console color for the borders, numbers and section headers. Defaults to the theme's Primary color.

    .PARAMETER OptionColor
        Console color for the option text. Defaults to the theme's Muted color.

    .PARAMETER Header
        Optional text shown between the title and the options, for example an instruction.

    .PARAMETER ReturnIndex
        After showing the menu, read the user's choice with Read-ConsoleChoice and return it
        (1..N, or 0 to exit) instead of the number of options.

    .PARAMETER Footer
        Optional text shown under the options.

    .PARAMETER NoClear
        Do not clear the screen before showing the menu.

    .EXAMPLE
        $choice = Show-ConsoleMenu -Title "Main menu" -Header "Choose a task:" -Options "Audit", "Repair" -ReturnIndex

        Shows the menu and returns the option the user picks, or 0 to exit.

    .EXAMPLE
        $count = Show-ConsoleMenu -Title "Main menu" -Options "List users", "Add user", "---", "{Red}Delete user"
        $choice = Read-ConsoleChoice -MaxChoice $count

        Shows three numbered options and a separator, then reads the user's choice.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCommands', '', Justification = 'Clear-Host is a built-in function in Windows PowerShell 5.1; the profile only lists cmdlets.')]
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string[]]$Options,

        [string]$Color,

        [string]$OptionColor,

        [string]$Header = '',

        [switch]$ReturnIndex,

        [string]$Footer = '',

        [switch]$NoClear
    )

    $Color = Resolve-UIColor -Color $Color -Role Primary
    $OptionColor = Resolve-UIColor -Color $OptionColor -Role Muted
    $muted = Resolve-UIColor -Role Muted

    if (-not $NoClear -and (Test-ClearScreenAllowed)) { Clear-Host }

    $width = [Math]::Max(60, $Title.Length + 4)
    $border = '=' * $width
    Write-HermesHost ''
    Write-HermesHost $border -ForegroundColor $Color
    Write-HermesHost (Get-CenteredText -Text $Title -Width $width) -ForegroundColor (Resolve-UIColor -Role Highlight)
    Write-HermesHost $border -ForegroundColor $Color
    Write-HermesHost ''

    if ($Header) {
        Write-HermesHost ('  ' + $Header) -ForegroundColor (Resolve-UIColor -Role Secondary)
        Write-HermesHost ''
    }

    $selectableCount = 0
    foreach ($opt in $Options) {
        if ($opt -match '^---') {
            Write-HermesHost ('  ' + $opt) -ForegroundColor $muted
        }
        elseif ($opt -match '^\[') {
            Write-HermesHost ('  ' + $opt) -ForegroundColor $Color
        }
        else {
            $selectableCount++
            $text = $opt
            $itemColor = $OptionColor
            $parsedColor = [ConsoleColor]::Gray
            if ($opt -match '^\{([a-zA-Z]+)\}(.*)' -and [Enum]::TryParse($matches[1], $true, [ref]$parsedColor)) {
                $itemColor = $parsedColor
                $text = $matches[2]
            }
            Write-HermesHost '  [' -NoNewline -ForegroundColor $muted
            Write-HermesHost ([string]$selectableCount) -NoNewline -ForegroundColor $Color
            Write-HermesHost '] ' -NoNewline -ForegroundColor $muted
            Write-HermesHost $text -ForegroundColor $itemColor
        }
    }

    if ($Footer) {
        Write-HermesHost ''
        Write-HermesHost ('  ' + $Footer) -ForegroundColor (Resolve-UIColor -Role Warning)
    }

    Write-HermesHost ''
    if ($ReturnIndex) { return (Read-ConsoleChoice -MaxChoice $selectableCount -AllowZero $true) }
    return $selectableCount
}

function Read-ConsoleChoice {
    <#
    .SYNOPSIS
        Reads a menu choice and returns it as a number.

    .DESCRIPTION
        Prompts until the user types a whole number from 1 to -MaxChoice, or 0 when
        -AllowZero is true (the default), and returns it. Anything else, including numbers
        too large to read, shows a message and asks again. The default prompt and messages
        follow the active locale.

    .PARAMETER MaxChoice
        Highest valid choice, usually the value returned by Show-ConsoleMenu.

    .PARAMETER Prompt
        Prompt text. Defaults to the locale's "Select an option".

    .PARAMETER AllowZero
        Accept 0 (shown as the exit option). Defaults to $true.

    .EXAMPLE
        $choice = Read-ConsoleChoice -MaxChoice 3

        Returns 1, 2 or 3, or 0 if the user chooses to exit.

    .EXAMPLE
        $choice = Read-ConsoleChoice -MaxChoice 5 -AllowZero $false -Prompt "Pick a server"

        Returns a number from 1 to 5; 0 is not accepted.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MaxChoice,

        [string]$Prompt,

        [bool]$AllowZero = $true
    )

    if (-not $Prompt) { $Prompt = Get-UIText -Key 'Menu.SelectPrompt' -Default 'Select an option' }
    $invalid = Get-UIText -Key 'Menu.InvalidOption' -Default 'Invalid option. Try again.'

    if ($AllowZero) {
        Write-HermesHost (Get-UIText -Key 'Menu.ExitPrompt' -Default '(0 to exit)') -ForegroundColor (Resolve-UIColor -Role Muted)
    }
    Write-HermesHost ''

    while ($true) {
        Write-HermesHost ($Prompt + ': ') -NoNewline -ForegroundColor (Resolve-UIColor -Role Primary)
        $val = "$(Read-Host)".Trim()

        # TryParse instead of [int]: a very long number would overflow and end the script.
        $choice = 0
        if ($val -match '^\d+$' -and [int]::TryParse($val, [ref]$choice)) {
            if ($AllowZero -and $choice -eq 0) { return 0 }
            if ($choice -ge 1 -and $choice -le $MaxChoice) { return $choice }
        }

        Write-HermesHost ('  [!] ' + $invalid) -ForegroundColor (Resolve-UIColor -Role Error)
        Write-HermesHost ''
    }
}

function Invoke-ConsoleMenu {
    <#
    .SYNOPSIS
        Shows a menu, runs the selected action and repeats until the user exits.

    .DESCRIPTION
        Each menu item is a hashtable with Label (the text shown) and, optionally, Action (a
        script block to run when it is selected). After an action runs, the menu waits for
        Enter and is shown again. Choosing 0 leaves the menu.
        Actions run with your permissions; do not build them from untrusted input.

    .PARAMETER Title
        Title shown above the options.

    .PARAMETER MenuItems
        Items to show: hashtables with Label and Action.

    .PARAMETER Footer
        Optional text shown under the options.

    .EXAMPLE
        Invoke-ConsoleMenu -Title "Tools" -MenuItems @(
            @{ Label = "Show date"; Action = { Get-Date } }
            @{ Label = "Show disk space"; Action = { Get-PSDrive -PSProvider FileSystem | Format-Table } }
        )

        Shows the two options until the user chooses 0.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$MenuItems,

        [string]$Footer = ''
    )

    $pressEnter = Get-UIText -Key 'Menu.PressEnter' -Default 'Press Enter to continue...'
    while ($true) {
        $options = @($MenuItems | ForEach-Object { [string]$_.Label })
        $count = Show-ConsoleMenu -Title $Title -Options $options -Footer $Footer
        $choice = Read-ConsoleChoice -MaxChoice $count -AllowZero $true
        if ($choice -eq 0) { break }

        # Section headers and separators are not numbered, so map the choice to the Nth selectable item.
        $selectable = @($MenuItems | Where-Object { [string]$_.Label -notmatch '^(---|\[)' })
        $selectedItem = $selectable[$choice - 1]
        if ($selectedItem.Action) { & $selectedItem.Action | Out-Host }

        Write-HermesHost ''
        Write-HermesHost ('  ' + $pressEnter) -ForegroundColor (Resolve-UIColor -Role Muted)
        $null = Read-Host
    }
}

function Read-ConsoleMultiChoice {
    <#
    .SYNOPSIS
        Lets the user pick several options by number and returns the chosen options.

    .DESCRIPTION
        Lists the options numbered from 1 and reads a comma-separated list of numbers, such
        as "1,3". Returns the selected options in the order typed, each one once. Numbers
        outside 1..N and other text are ignored. An empty answer returns nothing.

    .PARAMETER Options
        The options to choose from.

    .PARAMETER Prompt
        Prompt text. Defaults to the locale's "Select options (separated by comma)".

    .EXAMPLE
        $features = Read-ConsoleMultiChoice -Options "Logging", "Metrics", "Tracing"

        If the user types "3,1", returns "Tracing" and "Logging".
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Options,

        [string]$Prompt
    )

    if (-not $Prompt) { $Prompt = Get-UIText -Key 'MultiChoice.Prompt' -Default 'Select options (separated by comma)' }

    Write-HermesHost ('  ' + $Prompt) -ForegroundColor (Resolve-UIColor -Role Primary)
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-HermesHost ('    [' + ($i + 1) + '] ' + $Options[$i])
    }

    $val = Read-Host '    > '
    if (-not $val) { return @() }

    # Only 1..Count is valid. "0" used to select the last option (index -1), and a very
    # long number threw. Each option is returned once, in the order the user typed it.
    $results = @()
    $seen = @{}
    foreach ($idx in $val.Split(',')) {
        $n = 0
        $token = $idx.Trim()
        if ($token -match '^\d+$' -and [int]::TryParse($token, [ref]$n) -and $n -ge 1 -and $n -le $Options.Count -and -not $seen.ContainsKey($n)) {
            $seen[$n] = $true
            $results += $Options[$n - 1]
        }
    }
    return $results
}

function Invoke-ConsoleSpinner {
    <#
    .SYNOPSIS
        Runs a script block in a background job while showing a spinner.

    .DESCRIPTION
        Writes the message, runs -Action with Start-Job and animates a spinner until the job
        ends, then writes "Done" and returns the job's output. The job is removed afterwards,
        also when the user presses Ctrl+C.
        The action runs in a separate process: it cannot see your variables (use $using:)
        or functions. It runs with your permissions; do not build it from untrusted input.

    .PARAMETER Message
        Text shown before the spinner. Alias: Label.

    .PARAMETER Action
        Script block to run in the background job. Aliases: ScriptBlock, Job.

    .EXAMPLE
        $files = Invoke-ConsoleSpinner -Message "Scanning disk..." -Action { Get-ChildItem C:\Windows -Recurse -ErrorAction SilentlyContinue | Measure-Object }

        Shows a spinner while the scan runs and returns its result.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'The spinner writes backspace characters on purpose, which Write-HermesHost would remove.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Label')]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [Alias('ScriptBlock', 'Job')]
        [scriptblock]$Action
    )

    Write-HermesHost $Message -NoNewline
    $spinner = '|', '/', '-', '\'
    $job = Start-Job -ScriptBlock $Action
    try {
        while ($job.State -in 'NotStarted', 'Running') {
            foreach ($s in $spinner) {
                Write-Host "`b$s" -NoNewline
                Start-Sleep -Milliseconds 100
            }
        }
        Receive-Job $job
        Write-Host "`bDone" -ForegroundColor (Resolve-UIColor -Role Success)
    }
    finally {
        Remove-Job $job -Force -ErrorAction SilentlyContinue
    }
}

function Write-ConsoleProgress {
    <#
    .SYNOPSIS
        Updates the PowerShell progress bar.

    .DESCRIPTION
        A short wrapper around Write-Progress for scripts that use HermesConsoleUI for all
        their output. The bar is drawn by the host, at the top of the console window.
        Use Show-ConsoleProgress for an inline text bar instead.

    .PARAMETER Activity
        Description of the activity.

    .PARAMETER Percent
        Percentage complete, from 0 to 100.

    .PARAMETER Completed
        Remove the progress bar.

    .EXAMPLE
        1..10 | ForEach-Object { Write-ConsoleProgress -Activity "Copying" -Percent ($_ * 10); Start-Sleep -Milliseconds 200 }
        Write-ConsoleProgress -Activity "Copying" -Completed

        Shows a progress bar that fills up, then removes it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Activity,

        [ValidateRange(0, 100)]
        [int]$Percent = 0,

        [switch]$Completed
    )

    Write-Progress -Activity $Activity -PercentComplete $Percent -Completed:$Completed
}

function Show-ConsoleProgress {
    <#
    .SYNOPSIS
        Writes an inline text progress bar with its percentage.

    .DESCRIPTION
        Writes "Activity [####......] NN%" as a normal line of output, using ASCII characters
        that render in every console. Each call writes a new line.

    .PARAMETER Activity
        Description of the activity.

    .PARAMETER PercentComplete
        Percentage complete, from 0 to 100.

    .PARAMETER BarLength
        Number of characters in the bar. Defaults to 20.

    .PARAMETER Color
        Console color for the filled part and percentage. Defaults to the theme's Primary color.

    .EXAMPLE
        Show-ConsoleProgress -Activity "Upload" -PercentComplete 40

        Displays "Upload [########............] 40%".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Activity,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$PercentComplete,

        [ValidateRange(1, 200)]
        [int]$BarLength = 20,

        [string]$Color
    )

    $Color = Resolve-UIColor -Color $Color -Role Primary
    $muted = Resolve-UIColor -Role Muted
    $filled = [Math]::Floor(($PercentComplete / 100) * $BarLength)

    Write-HermesHost "  $Activity " -NoNewline
    Write-HermesHost '[' -NoNewline -ForegroundColor $muted
    Write-HermesHost ('#' * $filled) -NoNewline -ForegroundColor $Color
    Write-HermesHost ('.' * ($BarLength - $filled)) -NoNewline -ForegroundColor $muted
    Write-HermesHost '] ' -NoNewline -ForegroundColor $muted
    Write-HermesHost "$PercentComplete%" -ForegroundColor $Color
}

function Read-ConsoleInput {
    <#
    .SYNOPSIS
        Prompts the user for a line of text and returns it.

    .DESCRIPTION
        Shows the prompt and returns what the user types, as a string. With -DefaultValue the
        default is shown in brackets and returned when the user just presses Enter. For
        passwords use Read-ConsolePassword, which does not echo the input.

    .PARAMETER Prompt
        Prompt text. Defaults to the locale's input prompt, "[?]".

    .PARAMETER DefaultValue
        Value returned when the user enters nothing.

    .EXAMPLE
        $port = Read-ConsoleInput -Prompt "Port" -DefaultValue "8080"

        Shows "Port [8080]" and returns "8080" if the user presses Enter.

    .EXAMPLE
        $name = Read-ConsoleInput -Prompt "Server name"

        Returns the server name the user types.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Prompt,

        [AllowEmptyString()]
        [string]$DefaultValue
    )

    if (-not $Prompt) { $Prompt = Get-UIText -Key 'Input.Prompt' -Default '[?]' }
    $hasDefault = $PSBoundParameters.ContainsKey('DefaultValue')
    if ($hasDefault -and $DefaultValue) { $Prompt = "$Prompt [$DefaultValue]" }

    $answer = Read-Host -Prompt $Prompt
    if ($hasDefault -and [string]::IsNullOrEmpty($answer)) { return $DefaultValue }
    return $answer
}

function Read-ConsoleConfirmation {
    <#
    .SYNOPSIS
        Asks a yes/no question and returns $true for yes.

    .DESCRIPTION
        Shows the message followed by the locale's yes/no hint, such as "(Y/N)" or "(S/N)",
        and returns $true when the answer starts with "y" or with the locale's yes letter.
        Any other answer, including an empty one, returns $false.

    .PARAMETER Message
        The question to ask. Alias: Prompt.

    .EXAMPLE
        if (Read-ConsoleConfirmation -Message "Delete the temporary files?") { Remove-Item $env:TEMP\myapp -Recurse }

        Deletes the folder only if the user answers yes.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Prompt')]
        [string]$Message
    )

    $hint = Get-UIText -Key 'Confirmation.Prompt' -Default '(Y/N)'
    $yes = @('y')
    if ($hint -match '^\(\s*(\w)') { $yes += $matches[1].ToLowerInvariant() }

    $response = "$(Read-Host "$Message $hint")".Trim().ToLowerInvariant()
    return ($response.Length -gt 0 -and $yes -contains $response.Substring(0, 1))
}

function Read-ConsolePassword {
    <#
    .SYNOPSIS
        Prompts for a password without showing it and returns it as a SecureString.

    .DESCRIPTION
        Uses Read-Host -AsSecureString, so the characters are masked while typing and the
        value is never returned as plain text.

    .PARAMETER Prompt
        Prompt text. Defaults to "Password".

    .EXAMPLE
        $credential = [pscredential]::new("admin", (Read-ConsolePassword -Prompt "Admin password"))

        Builds a credential without the password appearing on screen.
    #>
    [CmdletBinding()]
    [OutputType([securestring])]
    param(
        [string]$Prompt = 'Password'
    )

    return (Read-Host -Prompt $Prompt -AsSecureString)
}

function Show-ConsoleNotification {
    <#
    .SYNOPSIS
        Displays a one-line notification such as "[Warning] Disk almost full".

    .DESCRIPTION
        Writes the message prefixed with its type in brackets, in the theme color for that
        type. Use it for short messages that should stand out from normal output.

    .PARAMETER Message
        The notification text.

    .PARAMETER Type
        Info (the default), Success, Warning or Error.

    .EXAMPLE
        Show-ConsoleNotification -Message "New version available" -Type Info

        Displays "[Info] New version available".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    Write-HermesHost "[$Type] $Message" -ForegroundColor (Resolve-UIColor -Role $Type)
}
