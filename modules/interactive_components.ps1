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

# True when input comes from a file or pipe, so Read-Host returning $null means it has ended.
function Test-HermesInputRedirected { return [Console]::IsInputRedirected }

function Read-ConsoleChoice {
    <#
    .SYNOPSIS
        Reads a menu choice and returns it as a number.

    .DESCRIPTION
        Prompts until the user types a whole number from 1 to -MaxChoice, or 0 when
        -AllowZero is true (the default), and returns it. Anything else, including numbers
        too large to read, shows a message and asks again. The default prompt and messages
        follow the active locale. With -MaxChoice 0 and -AllowZero $false there is nothing the
        user could type, so it throws instead of asking forever.
        With -DefaultChoice, an empty answer (Enter) returns that choice. When the input runs
        out (input redirected from a file or pipe that has ended) it returns -DefaultChoice, or
        0 when -AllowZero is true, and otherwise throws: it never waits forever for input that
        cannot arrive.

    .PARAMETER MaxChoice
        Highest valid choice, usually the value returned by Show-ConsoleMenu.

    .PARAMETER Prompt
        Prompt text. Defaults to the locale's "Select an option".

    .PARAMETER AllowZero
        Accept 0 (shown as the exit option). Defaults to $true.

    .PARAMETER DefaultChoice
        Choice returned for an empty answer, shown after the prompt. It must be a valid choice.
        Without it (or with -1, the default) an empty answer asks again.

    .EXAMPLE
        $choice = Read-ConsoleChoice -MaxChoice 3 -DefaultChoice 1

        Returns 1 when the user just presses Enter.

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

        [bool]$AllowZero = $true,

        [ValidateRange(-1, [int]::MaxValue)]
        [int]$DefaultChoice = -1
    )

    if ($MaxChoice -lt 1 -and -not $AllowZero) {
        throw [System.ArgumentException]::new('There is no valid choice: -MaxChoice is 0 and -AllowZero is $false.', 'MaxChoice')
    }
    if ($DefaultChoice -ge 0 -and -not (($DefaultChoice -eq 0 -and $AllowZero) -or ($DefaultChoice -ge 1 -and $DefaultChoice -le $MaxChoice))) {
        throw [System.ArgumentException]::new("-DefaultChoice $DefaultChoice is not a valid choice.", 'DefaultChoice')
    }
    if (-not $Prompt) { $Prompt = Get-UIText -Key 'Menu.SelectPrompt' -Default 'Select an option' }
    $invalid = Get-UIText -Key 'Menu.InvalidOption' -Default 'Invalid option. Try again.'

    if ($AllowZero) {
        Write-HermesHost (Get-UIText -Key 'Menu.ExitPrompt' -Default '(0 to exit)') -ForegroundColor (Resolve-UIColor -Role Muted)
    }
    Write-HermesHost ''

    $shown = if ($DefaultChoice -ge 0) { "$Prompt [$DefaultChoice]: " } else { "${Prompt}: " }
    while ($true) {
        Write-HermesHost $shown -NoNewline -ForegroundColor (Resolve-UIColor -Role Primary)
        $raw = Read-Host
        # $null: the input has ended (a redirected file or pipe). Asking again would loop forever.
        if ($null -eq $raw -and (Test-HermesInputRedirected)) {
            Write-HermesHost ''
            if ($DefaultChoice -ge 0) { return $DefaultChoice }
            if ($AllowZero) { return 0 }
            throw [System.InvalidOperationException]::new('The input ended before a valid choice was read.')
        }
        $val = "$raw".Trim()
        if ($val -eq '' -and $DefaultChoice -ge 0) { return $DefaultChoice }

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
        also when the user presses Ctrl+C. When the output is redirected to a file or a pipe,
        the spinner is not drawn (it would leave backspace characters in the output); the
        message and "Done" are still written.
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

    Write-HermesHost "$Message " -NoNewline
    $spinner = '|', '/', '-', '\'
    $animate = -not [Console]::IsOutputRedirected
    $drawn = $false
    $job = Start-Job -ScriptBlock $Action
    try {
        while ($job.State -in 'NotStarted', 'Running') {
            if (-not $animate) { $null = Wait-Job $job; break }
            foreach ($s in $spinner) {
                # A backspace only once a spinner character is on screen: the first one would
                # erase the last character of the message.
                Write-Host "$(if ($drawn) { "`b" })$s" -NoNewline
                $drawn = $true
                Start-Sleep -Milliseconds 100
            }
        }
        Receive-Job $job
        $doneColor = @{}
        if (-not (Test-NoColor)) { $doneColor.ForegroundColor = Resolve-UIColor -Role Success }
        Write-Host "$(if ($drawn) { "`b" })Done" @doneColor
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
        -Required, -Pattern and -Validate check the answer: until it is valid, the error message
        is shown and the question is asked again. The default value is checked too.

    .PARAMETER Prompt
        Prompt text. Defaults to the locale's input prompt, "[?]".

    .PARAMETER DefaultValue
        Value returned when the user enters nothing.

    .PARAMETER Required
        Do not accept an empty answer (when there is no -DefaultValue).

    .PARAMETER Pattern
        Regular expression the whole answer must match, for example '\d{1,5}'. An empty
        answer is accepted unless -Required is set.

    .PARAMETER Validate
        Script block that receives the answer as $_ and returns $true when it is valid. An empty
        answer is accepted unless -Required is set.

    .PARAMETER ErrorMessage
        Message shown when the answer is not valid. Defaults to the locale's "Invalid value. Try again."

    .EXAMPLE
        $port = Read-ConsoleInput -Prompt "Port" -DefaultValue "8080"

        Shows "Port [8080]" and returns "8080" if the user presses Enter.

    .EXAMPLE
        $name = Read-ConsoleInput -Prompt "Server name"

        Returns the server name the user types.

    .EXAMPLE
        $port = Read-ConsoleInput -Prompt "Port" -Required -Validate { [int]::TryParse($_, [ref]$null) -and [int]$_ -in 1..65535 } -ErrorMessage "Type a port from 1 to 65535."

        Asks again until the user types a valid port number.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Prompt,

        [AllowEmptyString()]
        [string]$DefaultValue,

        [switch]$Required,

        [string]$Pattern,

        [scriptblock]$Validate,

        [string]$ErrorMessage
    )

    if (-not $Prompt) { $Prompt = Get-UIText -Key 'Input.Prompt' -Default '[?]' }
    if (-not $ErrorMessage) { $ErrorMessage = Get-UIText -Key 'Input.Invalid' -Default 'Invalid value. Try again.' }
    $hasDefault = $PSBoundParameters.ContainsKey('DefaultValue')
    if ($hasDefault -and $DefaultValue) { $Prompt = "$Prompt [$DefaultValue]" }

    while ($true) {
        $answer = Read-Host -Prompt $Prompt
        if ($hasDefault -and [string]::IsNullOrEmpty($answer)) { $answer = $DefaultValue }

        $valid = $true
        if ([string]::IsNullOrEmpty($answer)) { $valid = -not $Required }
        else {
            if ($Pattern -and $answer -notmatch "^(?:$Pattern)$") { $valid = $false }
            if ($valid -and $Validate) {
                try { $valid = [bool](@($answer | ForEach-Object -Process $Validate) | Select-Object -Last 1) }
                catch { $valid = $false }
            }
        }
        if ($valid) { return $answer }
        Write-HermesHost ('  ' + $ErrorMessage) -ForegroundColor (Resolve-UIColor -Role Error)
    }
}

function Read-ConsoleConfirmation {
    <#
    .SYNOPSIS
        Asks a yes/no question and returns $true for yes.

    .DESCRIPTION
        Shows the message followed by the locale's yes/no hint, such as "(Y/N)" or "(S/N)",
        and returns $true when the answer starts with "y" or with the locale's yes letter.
        Any other answer returns $false. An empty answer returns -Default when it is given (the hint
        then shows the default letter in capitals, such as "(S/n)"), and $false otherwise.

    .PARAMETER Message
        The question to ask. Alias: Prompt.

    .PARAMETER Default
        Answer used when the user just presses Enter.

    .EXAMPLE
        if (Read-ConsoleConfirmation -Message "Delete the temporary files?") { Remove-Item $env:TEMP\myapp -Recurse }

        Deletes the folder only if the user answers yes.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Prompt')]
        [string]$Message,

        [bool]$Default
    )

    $hint = Get-UIText -Key 'Confirmation.Prompt' -Default '(Y/N)'
    $yes = @('y')
    if ($hint -match '^\(\s*(\w)') { $yes += $matches[1].ToLowerInvariant() }
    $hasDefault = $PSBoundParameters.ContainsKey('Default')
    if ($hasDefault -and $hint -match '^\(\s*(\w)\s*/\s*(\w)\s*\)$') {
        $hint = if ($Default) { "($($matches[1].ToUpperInvariant())/$($matches[2].ToLowerInvariant()))" } else { "($($matches[1].ToLowerInvariant())/$($matches[2].ToUpperInvariant()))" }
    }

    $response = "$(Read-Host "$Message $hint")".Trim().ToLowerInvariant()
    if ($response.Length -eq 0) { return ($hasDefault -and $Default) }
    return ($yes -contains $response.Substring(0, 1))
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

function Read-ConsoleSelection {
    <#
    .SYNOPSIS
        Lets the user pick one option, or several with -Multiple, with the arrow keys.

    .DESCRIPTION
        Shows the options as a list and moves the highlight with the Up and Down arrows (Page Up,
        Page Down, Home and End jump further). Enter chooses the highlighted option and Escape
        cancels. With -Multiple, Space marks or unmarks the highlighted option, A marks or unmarks
        all of them, and Enter returns the marked ones (or the highlighted one if none is marked).
        Long lists scroll in pages of -PageSize lines, with a counter of the position. Typing a letter or
        digit jumps to the next option that starts with it (A marks all only with -Multiple).
        Returns the chosen option, or with -ReturnIndex its index (from 0). Cancelling returns
        $null, or an empty array with -Multiple.
        Without an interactive console (output or input redirected, the ISE, a remote session or a
        CI log) the options are listed with numbers and read with Read-ConsoleChoice or
        Read-ConsoleMultiChoice instead, so scripts keep working there.

    .PARAMETER Options
        The options. Objects are shown with -DisplayProperty, or as text.

    .PARAMETER Title
        Text shown above the list.

    .PARAMETER Multiple
        Allow marking several options with Space.

    .PARAMETER Default
        Index (from 0) of the option highlighted at the start. Defaults to the first one.

    .PARAMETER PageSize
        Options shown at a time; longer lists scroll. Defaults to 10.

    .PARAMETER DisplayProperty
        Property of each option to show, for objects such as services or files.

    .PARAMETER ReturnIndex
        Return the index of the chosen option (or options) instead of the option itself.

    .EXAMPLE
        $target = Read-ConsoleSelection -Title 'Deploy to' -Options 'Development', 'Staging', 'Production'

        Returns the environment chosen with the arrow keys and Enter, or $null on Escape.

    .EXAMPLE
        $services = Read-ConsoleSelection -Options (Get-Service | Select-Object -First 30) -DisplayProperty DisplayName -Multiple

        Returns the service objects marked with Space.
    #>
    [CmdletBinding()]
    [OutputType([object], [object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Options,

        [string]$Title,

        [switch]$Multiple,

        [ValidateRange(0, [int]::MaxValue)]
        [int]$Default = 0,

        [ValidateRange(3, 100)]
        [int]$PageSize = 10,

        [string]$DisplayProperty,

        [switch]$ReturnIndex
    )

    $labels = @(foreach ($option in $Options) {
            $text = if ($DisplayProperty -and $null -ne $option) { [string]$option.$DisplayProperty } else { [string]$option }
            (ConvertTo-ConsoleSafeText -Text $text) -replace '[\r\n\t]', ' '
        })
    $count = $labels.Count
    # Indexes of the chosen options; $null means cancelled. Every path ends at the single return below.
    $final = $null

    if ($Title) { Write-HermesHost ('  ' + $Title) -ForegroundColor (Resolve-UIColor -Role Primary) }

    $interactive = Test-InteractiveConsole
    if (-not $interactive -and $Multiple) {
        $picked = @(Read-ConsoleMultiChoice -Options $labels)
        $final = @(foreach ($label in $picked) { [array]::IndexOf($labels, $label) })
    }
    elseif (-not $interactive) {
        for ($i = 0; $i -lt $count; $i++) {
            Write-HermesHost ('  [{0}] {1}' -f ($i + 1), $labels[$i]) -ForegroundColor (Resolve-UIColor -Role Muted)
        }
        # Enter picks the same option as in the interactive list.
        $choice = Read-ConsoleChoice -MaxChoice $count -AllowZero $true -DefaultChoice ([Math]::Min([Math]::Max(0, $Default), $count - 1) + 1)
        if ($choice -gt 0) { $final = @($choice - 1) }
    }
    else {
        $final = Read-ConsoleSelectionKey -Labels $labels -Multiple:$Multiple -Default $Default -PageSize $PageSize
    }

    $chosen = @(foreach ($i in @($final)) { if ($null -ne $i) { if ($ReturnIndex) { $i } else { $Options[$i] } } })
    if ($Multiple) { return , $chosen }
    if ($chosen.Count) { return $chosen[0] }
    return $null
}

function Read-ConsoleSelectionKey {
    <#
    .SYNOPSIS
        The interactive part of Read-ConsoleSelection: draws the list, reads keys and returns the
        chosen indexes, or $null when the user cancels.
    #>
    [CmdletBinding()]
    [OutputType([int[]], [object[]])]
    param(
        [Parameter(Mandatory = $true)][string[]]$Labels,
        [switch]$Multiple,
        [int]$Default = 0,
        [int]$PageSize = 10
    )

    $count = $Labels.Count

    $state = @{
        Index  = [Math]::Min($Default, $count - 1)
        Top    = 0
        Marked = [System.Collections.Generic.SortedSet[int]]::new()
    }
    $pageSize = [Math]::Min($PageSize, $count)
    $state.Index = [Math]::Max(0, $state.Index)
    if ($Multiple) {
        $hint = Get-UIText -Key 'Selection.MultiHint' -Default 'Up/Down move, Space mark, A all, Enter accept, Esc cancel'
    }
    else {
        $hint = Get-UIText -Key 'Selection.Hint' -Default 'Up/Down move, Enter select, Esc cancel'
    }
    $width = Get-ConsoleWidth
    $colors = @{
        Current = Resolve-UIColor -Role Primary
        Marked  = Resolve-UIColor -Role Success
        Other   = Resolve-UIColor -Role Highlight
        Muted   = Resolve-UIColor -Role Muted
    }
    $fit = {
        param([string]$Line)
        if ($width -le 1) { return $Line }
        if ($Line.Length -ge $width) { return $Line.Substring(0, $width - 1) }
        return $Line.PadRight($width - 1)
    }

    $render = {
        if ($state.Index -lt $state.Top) { $state.Top = $state.Index }
        if ($state.Index -ge $state.Top + $pageSize) { $state.Top = $state.Index - $pageSize + 1 }
        for ($row = 0; $row -lt $pageSize; $row++) {
            $i = $state.Top + $row
            $pointer = if ($i -eq $state.Index) { '> ' } else { '  ' }
            $box = ''
            if ($Multiple) { $box = if ($state.Marked.Contains($i)) { '[x] ' } else { '[ ] ' } }
            $color = if ($i -eq $state.Index) { $colors.Current } elseif ($state.Marked.Contains($i)) { $colors.Marked } else { $colors.Other }
            Write-HermesHost (& $fit "  $pointer$box$($Labels[$i])") -ForegroundColor $color
        }
        $footer = "  $hint"
        if ($count -gt $pageSize) { $footer += "  ($($state.Index + 1)/$count)" }
        Write-HermesHost (& $fit $footer) -ForegroundColor $colors.Muted
    }

    # A letter or digit jumps to the next option that starts with it, as hotkeys do in menus labelled
    # "1  Audit", "2  Apply"... Returns whether the highlight moved.
    $jump = {
        param([string]$Typed)
        if ($Typed -notmatch '^[\p{L}\p{N}?]$') { return $false }
        for ($step = 1; $step -le $count; $step++) {
            $candidate = ($state.Index + $step) % $count
            if ($Labels[$candidate].TrimStart().StartsWith($Typed, [StringComparison]::OrdinalIgnoreCase)) {
                $state.Index = $candidate
                return $true
            }
        }
        return $false
    }

    $cursorWasVisible = Set-ConsoleCursorVisible -Visible $false
    try {
        & $render
        while ($true) {
            $key = & $script:HermesReadKey
            $redraw = $true
            switch ([string]$key.Key) {
                'UpArrow' { $state.Index = ($state.Index - 1 + $count) % $count }
                'DownArrow' { $state.Index = ($state.Index + 1) % $count }
                'PageUp' { $state.Index = [Math]::Max(0, $state.Index - $pageSize) }
                'PageDown' { $state.Index = [Math]::Min($count - 1, $state.Index + $pageSize) }
                'Home' { $state.Index = 0 }
                'End' { $state.Index = $count - 1 }
                'Spacebar' {
                    if ($Multiple) { if (-not $state.Marked.Remove($state.Index)) { $null = $state.Marked.Add($state.Index) } }
                }
                'A' {
                    if ($Multiple) {
                        if ($state.Marked.Count -eq $count) { $state.Marked.Clear() }
                        else { for ($i = 0; $i -lt $count; $i++) { $null = $state.Marked.Add($i) } }
                    }
                    else { $redraw = & $jump ([string]$key.KeyChar) }
                }
                'Enter' {
                    if ($Multiple -and $state.Marked.Count) { return , ([int[]]@($state.Marked)) }
                    return , ([int[]]@($state.Index))
                }
                'Escape' { return $null }
                default { $redraw = & $jump ([string]$key.KeyChar) }
            }
            if ($redraw) {
                # Redraw over the previous list: it always has the same number of lines.
                $row = Get-ConsoleCursorRow
                if ($row -ge 0) { Set-ConsoleCursorRow -Row ($row - $pageSize - 1) }
                & $render
            }
        }
    }
    finally {
        $null = Set-ConsoleCursorVisible -Visible $cursorWasVisible
    }
}
