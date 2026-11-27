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

    if (-not $NoClear) { Clear-ConsoleScreen }

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
function Test-HermesInputRedirected {
    if ($script:HermesSimulation) { return $true }
    return [Console]::IsInputRedirected
}

function Read-ConsoleChoice {
    <#
    .SYNOPSIS
        Reads a menu choice and returns it as a number.

    .DESCRIPTION
        With -Choices, the user types one of those words or letters instead (case does not matter) and
        the choice is returned as written in -Choices; an empty answer returns -DefaultValue.
        Otherwise it prompts until the user types a whole number from 1 to -MaxChoice, or 0 when
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

    .PARAMETER Choices
        Words or letters the user can type, such as 's', 'n' or 'audit', 'apply'. Returns the one typed.

    .PARAMETER DefaultValue
        With -Choices, the choice returned for an empty answer or when the input runs out. It must be one of -Choices.

    .PARAMETER Prompt
        Prompt text. Defaults to the locale's "Select an option".

    .PARAMETER AllowZero
        Accept 0 (shown as the exit option). Defaults to $true.

    .PARAMETER DefaultChoice
        Choice returned for an empty answer, shown after the prompt. It must be a valid choice.
        Without it (or with -1, the default) an empty answer asks again.

    .EXAMPLE
        $answer = Read-ConsoleChoice -Choices 'apply', 'skip', 'quit' -DefaultValue 'skip' -Prompt 'What now'

        Returns "apply", "skip" or "quit" as typed in any case, and "skip" for Enter.

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
    [CmdletBinding(DefaultParameterSetName = 'Number')]
    [OutputType([int], [string])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Number')]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MaxChoice,

        [Parameter(Mandatory = $true, ParameterSetName = 'Word')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Choices,

        [string]$Prompt,

        [Parameter(ParameterSetName = 'Number')]
        [bool]$AllowZero = $true,

        [Parameter(ParameterSetName = 'Number')]
        [ValidateRange(-1, [int]::MaxValue)]
        [int]$DefaultChoice = -1,

        [Parameter(ParameterSetName = 'Word')]
        [string]$DefaultValue
    )

    if ($PSCmdlet.ParameterSetName -eq 'Word') { return (Read-ConsoleWordChoice -Choices $Choices -Prompt $Prompt -DefaultValue $DefaultValue) }

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
        $raw = Read-HermesHost
        # $null: the input has ended (a redirected file or pipe). Asking again would loop forever.
        if ($null -eq $raw -and (Test-HermesInputRedirected)) {
            Write-HermesHost ''
            if ($DefaultChoice -ge 0) { return $DefaultChoice }
            if ($AllowZero) { return 0 }
            throw [System.InvalidOperationException]::new('The input ended before a valid choice was read.')
        }
        Send-HermesAnswer "$raw"
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

function Read-ConsoleWordChoice {
    <#
    .SYNOPSIS
        Read-ConsoleChoice -Choices: asks until the user types one of the words, and returns it as written in Choices.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string[]]$Choices,
        [string]$Prompt,
        [string]$DefaultValue
    )

    $default = $null
    if ($DefaultValue) {
        $default = @($Choices | Where-Object { $_ -ieq $DefaultValue })[0]
        if ($null -eq $default) { throw [System.ArgumentException]::new("-DefaultValue '$DefaultValue' is not one of -Choices.", 'DefaultValue') }
    }
    if (-not $Prompt) { $Prompt = Get-UIText -Key 'Menu.SelectPrompt' -Default 'Select an option' }
    $invalid = Get-UIText -Key 'Choice.Invalid' -Default '"{0}" is not an option. Type one of: {1}'
    $shown = "$Prompt ($($Choices -join '/'))" + $(if ($default) { " [$default]" } else { '' }) + ': '

    while ($true) {
        Write-HermesHost $shown -NoNewline -ForegroundColor (Resolve-UIColor -Role Primary)
        $raw = Read-HermesHost
        if ($null -eq $raw -and (Test-HermesInputRedirected)) {
            Write-HermesHost ''
            if ($default) { return $default }
            throw [System.InvalidOperationException]::new('The input ended before a valid choice was read.')
        }
        Send-HermesAnswer "$raw"
        $val = "$raw".Trim()
        if ($val -eq '' -and $default) { return $default }
        foreach ($choice in $Choices) { if ($choice -ieq $val) { return $choice } }
        $message = try { $invalid -f $val, ($Choices -join ', ') } catch { "$val ?" }
        Write-HermesHost ('  [!] ' + $message) -ForegroundColor (Resolve-UIColor -Role Error)
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
        $null = Read-HermesHost
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

    .PARAMETER ReturnIndex
        Return the indexes (from 0) of the chosen options instead of the options, so options with the
        same text can be told apart.

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

        [string]$Prompt,

        [switch]$ReturnIndex
    )

    if (-not $Prompt) { $Prompt = Get-UIText -Key 'MultiChoice.Prompt' -Default 'Select options (separated by comma)' }

    Write-HermesHost ('  ' + $Prompt) -ForegroundColor (Resolve-UIColor -Role Primary)
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-HermesHost ('    [' + ($i + 1) + '] ' + $Options[$i])
    }

    $val = Read-HermesHost -Prompt '    > '
    Send-HermesAnswer ('    > ' + [string]$val)
    if (-not $val) { return @() }

    # Only 1..Count is valid. "0" used to select the last option (index -1), and a very
    # long number threw. Each option is returned once, in the order the user typed it.
    $results = [System.Collections.Generic.List[object]]::new()
    $seen = @{}
    foreach ($idx in $val.Split(',')) {
        $n = 0
        $token = $idx.Trim()
        if ($token -match '^\d+$' -and [int]::TryParse($token, [ref]$n) -and $n -ge 1 -and $n -le $Options.Count -and -not $seen.ContainsKey($n)) {
            $seen[$n] = $true
            $results.Add($(if ($ReturnIndex) { $n - 1 } else { $Options[$n - 1] }))
        }
    }
    return $results.ToArray()
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
        When the input runs out (redirected from a file or pipe that has ended) it returns the default
        value, or an empty string when that is valid, and otherwise throws: it never waits forever for
        input that cannot arrive.

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

    .PARAMETER NoColon
        Do not add ": " after the prompt, only a space. It is never added when the prompt already ends with
        ":", "?" or ">".

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

        [string]$ErrorMessage,

        [switch]$NoColon
    )

    if (-not $Prompt) { $Prompt = Get-UIText -Key 'Input.Prompt' -Default '[?]' }
    if (-not $ErrorMessage) { $ErrorMessage = Get-UIText -Key 'Input.Invalid' -Default 'Invalid value. Try again.' }
    $hasDefault = $PSBoundParameters.ContainsKey('DefaultValue')
    if ($hasDefault -and $DefaultValue) { $Prompt = "$Prompt [$DefaultValue]" }
    # Read-Host always adds ": ". A prompt that already ends in a colon, a question mark or ">" is written by
    # the module instead, followed by a space (the handler gets it with the answer, not twice).
    $ownPrompt = $NoColon -or $Prompt.TrimEnd() -match '[:?>]$'
    $shownPrompt = if ($ownPrompt) { $Prompt.TrimEnd() + ' ' } else { "${Prompt}: " }

    while ($true) {
        if ($ownPrompt) {
            $paused = $script:HermesOutput.Paused
            $script:HermesOutput.Paused = $true
            try { Write-HermesHost $shownPrompt -NoNewline } finally { $script:HermesOutput.Paused = $paused }
            $answer = Read-HermesHost
        }
        else { $answer = Read-HermesHost -Prompt $Prompt }
        # $null: the input has ended (a redirected file or pipe). Asking again would loop forever.
        $ended = $null -eq $answer -and (Test-HermesInputRedirected)
        if ($hasDefault -and [string]::IsNullOrEmpty($answer)) { $answer = $DefaultValue }
        Send-HermesAnswer ($shownPrompt + [string]$answer)

        $valid = $true
        if ([string]::IsNullOrEmpty($answer)) { $valid = -not $Required }
        else {
            if ($Pattern -and $answer -notmatch "^(?:$Pattern)$") { $valid = $false }
            if ($valid -and $Validate) {
                try { $valid = [bool](@($answer | ForEach-Object -Process $Validate) | Select-Object -Last 1) }
                catch { $valid = $false }
            }
        }
        if ($valid) { return [string]$answer }
        if ($ended) { throw [System.InvalidOperationException]::new('The input ended before a valid answer was read.') }
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

    $raw = "$(Read-HermesHost -Prompt "$Message $hint")".Trim()
    $response = $raw.ToLowerInvariant()
    $result = if ($response.Length -eq 0) { $hasDefault -and $Default } else { $yes -contains $response.Substring(0, 1) }
    # A capture keeps the question with its answer: what was typed, or the default letter for Enter.
    $letters = if ($hint -match '^\(\s*(\w)\s*/\s*(\w)\s*\)$') { $matches[1].ToLowerInvariant(), $matches[2].ToLowerInvariant() } else { 'y', 'n' }
    $shownAnswer = if ($raw) { $raw } elseif ($result) { $letters[0] } else { $letters[1] }
    Send-HermesAnswer "$Message ${hint}: $shownAnswer"
    return [bool]$result
}

function Read-ConsolePassword {
    <#
    .SYNOPSIS
        Prompts for a password without showing it and returns it as a SecureString.

    .DESCRIPTION
        Uses Read-Host -AsSecureString, so the characters are masked while typing and the
        value is never returned as plain text. An output handler (Register-ConsoleOutputHandler) only
        receives the prompt and asterisks.

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

    $secure = Read-HermesHost -Prompt $Prompt -AsSecureString
    # A capture shows that something was typed, never what or how long.
    Send-HermesAnswer ("${Prompt}: " + $(if ($secure -and $secure.Length) { '********' } else { '' }))
    return $secure
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
        digit jumps to the next option that starts with it (A marks all only with -Multiple). With -Filter,
        typing narrows the list to the options that contain the text instead (Backspace deletes, the first
        Escape clears the filter and the second cancels).
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

    .PARAMETER Filter
        Typing filters the options instead of jumping to the next one that starts with the letter. For long lists.

    .EXAMPLE
        $target = Read-ConsoleSelection -Title 'Deploy to' -Options 'Development', 'Staging', 'Production'

        Returns the environment chosen with the arrow keys and Enter, or $null on Escape.

    .EXAMPLE
        $rule = Read-ConsoleSelection -Options $rules -DisplayProperty Name -Filter -PageSize 15

        Shows the rules 15 at a time; typing "firewall" leaves only the rules whose name contains it.

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

        [switch]$ReturnIndex,

        [switch]$Filter
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
        # By index: two options with the same text are still two options.
        $final = @(Read-ConsoleMultiChoice -Options $labels -ReturnIndex)
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
        # The list is redrawn at every key: an output handler gets the answer once, not every redraw.
        $script:HermesOutput.Paused = $true
        try { $final = Read-ConsoleSelectionKey -Labels $labels -Multiple:$Multiple -Default $Default -PageSize $PageSize -Filter:$Filter }
        finally { $script:HermesOutput.Paused = $false }
        $answer = if ($null -eq $final) { Get-UIText -Key 'Selection.Cancelled' -Default '(cancelled)' } else { (@($final) | ForEach-Object { $labels[$_] }) -join ', ' }
        Send-HermesAnswer "  > $answer"
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
    .DESCRIPTION
        With -Filter, typed characters narrow the list to the labels that contain them. ItemColors gives a
        color to each option when it is neither highlighted nor marked.
    #>
    [CmdletBinding()]
    [OutputType([int[]], [object[]])]
    param(
        [Parameter(Mandatory = $true)][string[]]$Labels,
        [switch]$Multiple,
        [int]$Default = 0,
        [int]$PageSize = 10,
        [switch]$Filter,
        [string[]]$ItemColors
    )

    $view = Get-ConsoleSelectionView -Labels $Labels -Default $Default -PageSize $PageSize -Multiple:$Multiple -Filter:$Filter -ItemColors $ItemColors
    $cursorWasVisible = Set-ConsoleCursorVisible -Visible $false
    try {
        Write-ConsoleSelectionView -View $view
        while ($true) {
            $step = Invoke-ConsoleSelectionKey -View $view -Key (Read-HermesKey)
            if ($step.Done) {
                # A cancelled list returns $null; the comma keeps a list of indexes from being unrolled.
                if ($null -eq $step.Result) { return $null }
                return , $step.Result
            }
            if ($step.Redraw) {
                # Redraw over the previous list: it always has the same number of lines.
                $row = Get-ConsoleCursorRow
                if ($row -ge 0) { Set-ConsoleCursorRow -Row ($row - $view.PageSize - 1) }
                Write-ConsoleSelectionView -View $view
            }
        }
    }
    finally {
        $null = Set-ConsoleCursorVisible -Visible $cursorWasVisible
    }
}

function Get-ConsoleSelectionView {
    <#
    .SYNOPSIS
        The state of one arrow-key list: its labels, the highlight, the marks, the filter and the colors.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string[]]$Labels,
        [int]$Default,
        [int]$PageSize,
        [switch]$Multiple,
        [switch]$Filter,
        [string[]]$ItemColors
    )

    $total = $Labels.Count
    $all = [int[]](0..($total - 1))
    $hint = if ($Filter -and $Multiple) { Get-UIText -Key 'Selection.FilterMultiHint' -Default 'Type to filter, Space mark, Enter accept, Esc clear or cancel' }
    elseif ($Filter) { Get-UIText -Key 'Selection.FilterHint' -Default 'Type to filter, Up/Down move, Enter select, Esc clear or cancel' }
    elseif ($Multiple) { Get-UIText -Key 'Selection.MultiHint' -Default 'Up/Down move, Space mark, A all, Enter accept, Esc cancel' }
    else { Get-UIText -Key 'Selection.Hint' -Default 'Up/Down move, Enter select, Esc cancel' }

    # Index is a position in Visible, the options that pass the filter (all of them without one).
    return @{
        Labels     = $Labels
        Total      = $total
        All        = $all
        Visible    = $all
        Index      = [Math]::Max(0, [Math]::Min($Default, $total - 1))
        Top        = 0
        Text       = ''
        Marked     = [System.Collections.Generic.SortedSet[int]]::new()
        PageSize   = [Math]::Min($PageSize, $total)
        Multiple   = [bool]$Multiple
        Filter     = [bool]$Filter
        ItemColors = $ItemColors
        Hint       = $hint
        NoMatch    = Get-UIText -Key 'Selection.NoMatch' -Default '(no matches)'
        Width      = Get-ConsoleWidth
        Colors     = @{
            Current = Resolve-UIColor -Role Primary
            Marked  = Resolve-UIColor -Role Success
            Other   = Resolve-UIColor -Role Highlight
            Muted   = Resolve-UIColor -Role Muted
        }
    }
}

function Update-ConsoleSelectionFilter {
    <#
    .SYNOPSIS
        Narrows the list to the options that contain the typed text, and moves the highlight to the first of them.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Changes the view of a list only.')]
    [CmdletBinding()]
    param([hashtable]$View)

    $View.Visible = if ($View.Text) {
        [int[]]@(foreach ($i in $View.All) { if ($View.Labels[$i].IndexOf($View.Text, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $i } })
    }
    else { $View.All }
    $View.Index = 0
    $View.Top = 0
}

function Find-ConsoleSelectionJump {
    <#
    .SYNOPSIS
        Moves the highlight to the next option that starts with the typed letter or digit; returns whether it moved.
    .DESCRIPTION
        A letter or digit jumps to the next option that starts with it, as hotkeys do in menus labelled "1  Audit",
        "2  Apply"...
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([hashtable]$View, [string]$Typed)

    if ($Typed -notmatch '^[\p{L}\p{N}?]$') { return $false }
    for ($step = 1; $step -le $View.Total; $step++) {
        $candidate = ($View.Index + $step) % $View.Total
        if ($View.Labels[$candidate].TrimStart().StartsWith($Typed, [StringComparison]::OrdinalIgnoreCase)) {
            $View.Index = $candidate
            return $true
        }
    }
    return $false
}

function Format-SelectionLine {
    <#
    .SYNOPSIS
        Cuts a line of the list to the console width, one column short, so that the cursor never wraps.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([hashtable]$View, [string]$Line)

    if ($View.Width -le 1) { return $Line }
    return (Format-ConsoleText -Text $Line -Width ($View.Width - 1) -Align Left)
}

function Get-SelectionItemColor {
    <#
    .SYNOPSIS
        The color of one option: the highlight, a mark, its own color from -ItemColors, or the default one.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([hashtable]$View, [int]$Position, [int]$Item)

    if ($Position -eq $View.Index) { return $View.Colors.Current }
    if ($View.Marked.Contains($Item)) { return $View.Colors.Marked }
    if ($View.ItemColors -and $Item -lt $View.ItemColors.Count -and $View.ItemColors[$Item]) { return $View.ItemColors[$Item] }
    return $View.Colors.Other
}

function Write-ConsoleSelectionView {
    <#
    .SYNOPSIS
        Draws the page of the list that holds the highlight, and the footer with the hint and the position.
    .DESCRIPTION
        Always writes the same number of lines (empty ones past the end), so the next redraw covers this one.
    #>
    [CmdletBinding()]
    param([hashtable]$View)

    $shown = $View.Visible.Count
    if ($View.Index -lt $View.Top) { $View.Top = $View.Index }
    if ($View.Index -ge $View.Top + $View.PageSize) { $View.Top = $View.Index - $View.PageSize + 1 }
    for ($row = 0; $row -lt $View.PageSize; $row++) {
        $position = $View.Top + $row
        if ($position -ge $shown) {
            $empty = if ($row -eq 0) { "  $($View.NoMatch)" } else { '' }
            Write-HermesHost (Format-SelectionLine -View $View -Line $empty) -ForegroundColor $View.Colors.Muted
            continue
        }
        $item = $View.Visible[$position]
        $pointer = if ($position -eq $View.Index) { '> ' } else { '  ' }
        $box = ''
        if ($View.Multiple) { $box = if ($View.Marked.Contains($item)) { '[x] ' } else { '[ ] ' } }
        $color = Get-SelectionItemColor -View $View -Position $position -Item $item
        Write-HermesHost (Format-SelectionLine -View $View -Line "  $pointer$box$($View.Labels[$item])") -ForegroundColor $color
    }
    $footer = "  $($View.Hint)"
    if ($View.Text) { $footer += "  [$($View.Text)]" }
    if ($shown -gt $View.PageSize) { $footer += "  ($($View.Index + 1)/$shown)" }
    Write-HermesHost (Format-SelectionLine -View $View -Line $footer) -ForegroundColor $View.Colors.Muted
}

function Invoke-ConsoleSelectionKey {
    <#
    .SYNOPSIS
        Applies one key to the list: moves the highlight, marks, filters, jumps, or ends the choice.
    .DESCRIPTION
        Returns an object with Done (the choice is made or cancelled), Result (the chosen indexes, or $null for
        a cancel) and Redraw (the list has to be drawn again).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([hashtable]$View, [System.ConsoleKeyInfo]$Key)

    $step = [pscustomobject]@{ Done = $false; Result = $null; Redraw = $true }
    $shown = $View.Visible.Count
    $typed = [string]$Key.KeyChar
    if ($View.Filter -and $typed -match '^[^\p{C}\s]$') {
        $View.Text += $typed
        Update-ConsoleSelectionFilter -View $View
        return $step
    }

    switch ([string]$Key.Key) {
        'UpArrow' { if ($shown) { $View.Index = ($View.Index - 1 + $shown) % $shown } }
        'DownArrow' { if ($shown) { $View.Index = ($View.Index + 1) % $shown } }
        'PageUp' { $View.Index = [Math]::Max(0, $View.Index - $View.PageSize) }
        'PageDown' { $View.Index = [Math]::Max(0, [Math]::Min($shown - 1, $View.Index + $View.PageSize)) }
        'Home' { $View.Index = 0 }
        'End' { $View.Index = [Math]::Max(0, $shown - 1) }
        'Backspace' {
            if ($View.Filter -and $View.Text) {
                $View.Text = $View.Text.Substring(0, $View.Text.Length - 1)
                Update-ConsoleSelectionFilter -View $View
            }
            else { $step.Redraw = $false }
        }
        'Spacebar' {
            if ($View.Multiple -and $shown) {
                $item = $View.Visible[$View.Index]
                if (-not $View.Marked.Remove($item)) { $null = $View.Marked.Add($item) }
            }
        }
        'A' {
            if ($View.Multiple) {
                if ($View.Marked.Count -eq $View.Total) { $View.Marked.Clear() }
                else { for ($i = 0; $i -lt $View.Total; $i++) { $null = $View.Marked.Add($i) } }
            }
            else { $step.Redraw = Find-ConsoleSelectionJump -View $View -Typed $typed }
        }
        'Enter' {
            if ($View.Multiple -and $View.Marked.Count) { $step.Done = $true; $step.Result = [int[]]@($View.Marked) }
            elseif ($shown) { $step.Done = $true; $step.Result = [int[]]@($View.Visible[$View.Index]) }
            else { $step.Redraw = $false }
        }
        'Escape' {
            if ($View.Filter -and $View.Text) {
                $View.Text = ''
                Update-ConsoleSelectionFilter -View $View
            }
            else { $step.Done = $true }
        }
        default { $step.Redraw = $(if ($View.Filter) { $false } else { Find-ConsoleSelectionJump -View $View -Typed $typed }) }
    }
    return $step
}

function Read-ConsoleMenu {
    <#
    .SYNOPSIS
        Shows a menu of keyed options, with notes and a recommended one, and returns the key chosen.

    .DESCRIPTION
        Each item has a key (what the user types, such as "1", "a" or "audit"), a text, and optionally a note
        shown aligned in a second column and a color. In an interactive console the options are chosen with
        the arrow keys and Enter (typing a key's first letter jumps to it, or filters with -Filter); elsewhere
        (redirected input, a capture, a CI log) they are listed and the user types the key, as with
        Read-ConsoleChoice -Choices. -Recommended marks one option. Enter on an empty answer, or input that runs
        out, returns -Default. Escape returns -Cancel, or $null when -Cancel is not given.

    .PARAMETER Items
        Ordered dictionary from key to the item: a string (its text), an array (text, note, color) or a
        hashtable with Label, Note and Color.

    .PARAMETER Title
        Text shown above the options.

    .PARAMETER Default
        Key highlighted at the start and returned for an empty answer. Defaults to the first key.

    .PARAMETER Recommended
        Key of the option to mark as recommended.

    .PARAMETER Cancel
        Key returned when the user presses Escape.

    .PARAMETER Prompt
        Prompt text when the key is typed. Defaults to the locale's "Select an option".

    .PARAMETER PageSize
        Options shown at a time in the interactive list. Defaults to 20.

    .PARAMETER Filter
        In the interactive list, typing filters the options instead of jumping to them.

    .EXAMPLE
        $action = Read-ConsoleMenu -Title 'Tasks' -Recommended 'a' -Default 'q' -Cancel 'q' -Items ([ordered]@{
            a = 'Audit', 'Check every rule'
            r = 'Repair', 'Apply the pending rules', 'Yellow'
            q = 'Quit'
        })

        Returns "a", "r" or "q".
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$Items,

        [string]$Title,

        [string]$Default,

        [string]$Recommended,

        [string]$Cancel,

        [string]$Prompt,

        [ValidateRange(3, 100)]
        [int]$PageSize = 20,

        [switch]$Filter
    )

    if ($Items.Count -eq 0) { throw [System.ArgumentException]::new('-Items has no options.', 'Items') }
    $entries = @(ConvertTo-MenuEntry -Items $Items)
    $keys = @($entries.Key)
    $defaultKey = @($keys | Where-Object { $_ -ieq $Default })[0]
    if ($null -eq $defaultKey) { $defaultKey = $keys[0] }
    $marker = Get-UIText -Key 'Menu.Recommended' -Default ([string][char]0x2190 + ' recommended')

    # Key and text, then the notes in a column of their own.
    $keyWidth = ($keys | ForEach-Object { Measure-ConsoleText -Text $_ } | Measure-Object -Maximum).Maximum
    $heads = @($entries | ForEach-Object { $_.Key.PadRight($keyWidth) + '  ' + $_.Label })
    $headWidth = [Math]::Min(46, ($heads | ForEach-Object { Measure-ConsoleText -Text $_ } | Measure-Object -Maximum).Maximum)

    if ($Title) { Write-HermesHost ('  ' + $Title) -ForegroundColor (Resolve-UIColor -Role Primary) }

    if (Test-InteractiveConsole) {
        $picked = Read-ConsoleMenuPick -Entries $entries -Keys $keys -DefaultKey $defaultKey -Heads $heads -HeadWidth $headWidth -Marker $marker -Recommended $Recommended -PageSize $PageSize -Filter:$Filter
        if ($null -eq $picked) {
            Send-HermesAnswer ('  > ' + (Get-UIText -Key 'Selection.Cancelled' -Default '(cancelled)'))
            if ($PSBoundParameters.ContainsKey('Cancel')) { return $Cancel }
            return $null
        }
        $chosen = $entries[$picked]
        Send-HermesAnswer "  > $($chosen.Key)  $($chosen.Label)"
        return $chosen.Key
    }

    Write-ConsoleMenuList -Entries $entries -KeyWidth $keyWidth -HeadWidth $headWidth -Marker $marker -Recommended $Recommended
    $choice = @{ Choices = $keys; DefaultValue = $defaultKey }
    if ($Prompt) { $choice.Prompt = $Prompt }
    return (Read-ConsoleChoice @choice)
}

function ConvertTo-MenuEntry {
    <#
    .SYNOPSIS
        Reads the items of Read-ConsoleMenu as entries with a key, a text, a note and a color.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([System.Collections.IDictionary]$Items)

    foreach ($key in $Items.Keys) {
        $value = $Items[$key]
        $label = $null; $note = $null; $color = $null
        if ($value -is [System.Collections.IDictionary]) { $label = $value['Label']; $note = $value['Note']; $color = $value['Color'] }
        elseif ($null -eq $value -or $value -is [string]) { $label = $value }
        elseif ($value -is [System.Collections.IList]) { $parts = @($value); $label = $parts[0]; if ($parts.Count -gt 1) { $note = $parts[1] }; if ($parts.Count -gt 2) { $color = $parts[2] } }
        elseif ($value.PSObject.Properties['Label']) { $label = $value.Label; $note = $value.Note; $color = $value.Color }
        else { $label = [string]$value }
        [pscustomobject]@{ Key = [string]$key; Label = [string]$label; Note = [string]$note; Color = [string]$color }
    }
}

function Read-ConsoleMenuPick {
    <#
    .SYNOPSIS
        Shows the options in the arrow-key list and returns the position of the one chosen, or $null when cancelled.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [object[]]$Entries,
        [string[]]$Keys,
        [string]$DefaultKey,
        [string[]]$Heads,
        [int]$HeadWidth,
        [string]$Marker,
        [string]$Recommended,
        [int]$PageSize,
        [switch]$Filter
    )

    $primary = Resolve-UIColor -Role Primary
    $lines = @(for ($n = 0; $n -lt $Entries.Count; $n++) {
            $line = $Heads[$n]
            if ($Entries[$n].Note) { $line = (Format-ConsoleText -Text $line -Width $HeadWidth -Align Left) + '  ' + $Entries[$n].Note }
            if ($Entries[$n].Key -eq $Recommended) { $line += "  $Marker" }
            $line
        })
    $itemColors = @(foreach ($entry in $Entries) { if ($entry.Key -eq $Recommended) { $primary } elseif ($entry.Color) { $entry.Color } else { '' } })
    $script:HermesOutput.Paused = $true
    try { $result = Read-ConsoleSelectionKey -Labels $lines -Default ([array]::IndexOf($Keys, $DefaultKey)) -PageSize ([Math]::Min($PageSize, $Entries.Count)) -Filter:$Filter -ItemColors $itemColors }
    finally { $script:HermesOutput.Paused = $false }
    if ($null -eq $result) { return $null }
    return [int]$result[0]
}

function Write-ConsoleMenuList {
    <#
    .SYNOPSIS
        Lists the options of a menu for a console without arrow keys: key, text, note and the recommended mark.
    #>
    [CmdletBinding()]
    param([object[]]$Entries, [int]$KeyWidth, [int]$HeadWidth, [string]$Marker, [string]$Recommended)

    $primary = Resolve-UIColor -Role Primary
    $muted = Resolve-UIColor -Role Muted
    $highlight = Resolve-UIColor -Role Highlight
    foreach ($entry in $Entries) {
        $isRecommended = $entry.Key -eq $Recommended
        Write-HermesHost ('   ' + $entry.Key.PadRight($KeyWidth) + '  ') -NoNewline -ForegroundColor $(if ($isRecommended) { $primary } else { $highlight })
        $labelColor = if ($isRecommended) { $primary } elseif ($entry.Color) { $entry.Color } else { $highlight }
        $labelText = if ($entry.Note) { Format-ConsoleText -Text $entry.Label -Width ($HeadWidth - $KeyWidth - 2) -Align Left } else { $entry.Label }
        Write-HermesHost $labelText -NoNewline -ForegroundColor $labelColor
        if ($entry.Note) { Write-HermesHost ('  ' + $entry.Note) -NoNewline -ForegroundColor $muted }
        if ($isRecommended) { Write-HermesHost ('  ' + $Marker) -NoNewline -ForegroundColor $primary }
        Write-HermesHost ''
    }
}

function Write-ConsoleStatusLine {
    <#
    .SYNOPSIS
        Shows a line of progress that is rewritten in place, such as "  42 %  Checking the firewall".

    .DESCRIPTION
        Writes the text (with the percentage before it when -Percent is given) at the start of the current
        line and leaves the cursor there, so the next call replaces it. Anything else the module writes
        clears it first, and Clear-ConsoleStatusLine removes it. It runs in the same process (unlike
        Invoke-ConsoleSpinner), so it can report the progress of your own loop. The line is cut to the
        console width. Nothing is written when the output is redirected or only goes to an output handler
        (Register-ConsoleOutputHandler -Quiet), and it is never passed to the handler: it is temporary.

    .PARAMETER Text
        What is being done.

    .PARAMETER Percent
        Percentage complete, from 0 to 100, shown before the text. -1 (the default) omits it.

    .PARAMETER Color
        Console color of the line. Defaults to the theme's Muted color.

    .EXAMPLE
        for ($i = 0; $i -lt $rules.Count; $i++) {
            Write-ConsoleStatusLine -Text $rules[$i].Name -Percent ([Math]::Floor(100 * $i / $rules.Count))
            Test-Rule $rules[$i]
        }
        Clear-ConsoleStatusLine

        Shows which rule is being checked, on one line that changes, and removes it at the end.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'The line starts with a carriage return on purpose, which Write-HermesHost would remove.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Text,

        [ValidateRange(-1, 100)]
        [int]$Percent = -1,

        [string]$Color
    )

    if (-not (Test-HermesLiveOutput)) { return }
    $width = Get-ConsoleWidth -Default 80
    $line = '  '
    if ($Percent -ge 0) { $line += ('{0,3} %  ' -f $Percent) }
    # Format-ConsoleText removes control characters from the text; the carriage return is added after.
    $line = Format-ConsoleText -Text ($line + $Text) -Width ([Math]::Max(1, $width - 1)) -Align Left
    $parameters = @{ Object = "`r$line"; NoNewline = $true }
    if ([string]::IsNullOrEmpty($env:NO_COLOR)) {
        $resolved = Resolve-UIColor -Color $Color -Role Muted
        $parameters.ForegroundColor = if ($resolved -match '^#[0-9A-Fa-f]{6}$') { ConvertTo-NearestConsoleColor -Hex $resolved } else { $resolved }
    }
    Write-Host @parameters
    $script:HermesOutput.StatusLineActive = $true
}

function Clear-ConsoleStatusLine {
    <#
    .SYNOPSIS
        Removes the line shown by Write-ConsoleStatusLine.

    .DESCRIPTION
        Blanks the status line and puts the cursor back at the start of it, so the next output starts on a
        clean line. Does nothing when no status line is shown. The module also does this by itself before
        it writes anything else.

    .EXAMPLE
        Clear-ConsoleStatusLine

        Removes the progress line after a loop.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Rewrites the line with a carriage return, which Write-HermesHost would remove.')]
    [CmdletBinding()]
    param()

    if (-not $script:HermesOutput.StatusLineActive) { return }
    $script:HermesOutput.StatusLineActive = $false
    if (-not (Test-HermesLiveOutput)) { return }
    $width = Get-ConsoleWidth -Default 80
    Write-Host ("`r" + (' ' * [Math]::Max(1, $width - 1)) + "`r") -NoNewline
}
