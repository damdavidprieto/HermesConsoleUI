<#
.SYNOPSIS
    PSConsoleUI - Interactive Components
.DESCRIPTION
    Interactive UI components including menus, choices, inputs.
#>

function Show-ConsoleMenu {
    <#
    .SYNOPSIS
        Displays an interactive menu with numbered options.
    #>
    [CmdletBinding()]
    param(
        [string]$Title,
        [array]$Options,
        [string]$Color = 'Cyan',
        [string]$OptionColor = 'Gray',
        [string]$Footer = '',
        [switch]$NoClear
    )

    if (-not $Color -or $Color.Trim() -eq '') { $Color = 'Cyan' }
    if (-not $OptionColor -or $OptionColor.Trim() -eq '') { $OptionColor = 'Gray' }
    
    # Respect Global Dev Mode (Infinite Scroll)
    if (-not $NoClear -and -not $Global:CassielDevMode) {
        Clear-Host
    }
    $width = 60
    
    $border = '=' * $width
    Write-HermesHost ''
    Write-HermesHost $border -ForegroundColor $Color
    $padding = [Math]::Floor(($width - $Title.Length) / 2)
    Write-HermesHost ((' ' * $padding) + $Title) -ForegroundColor White
    Write-HermesHost $border -ForegroundColor $Color
    Write-HermesHost ''
    
    $selectableCount = 0
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $opt = $Options[$i]
        
        if ($opt -match '^---') {
            Write-HermesHost ('  ' + $opt) -ForegroundColor DarkGray
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
            Write-HermesHost '  [' -NoNewline -ForegroundColor Gray
            Write-HermesHost ([string]$selectableCount) -NoNewline -ForegroundColor $Color
            Write-HermesHost '] ' -NoNewline -ForegroundColor Gray
            Write-HermesHost $text -ForegroundColor $itemColor
        }
    }
    
    if ($Footer) {
        Write-HermesHost ''
        Write-HermesHost ('  ' + $Footer) -ForegroundColor Yellow
    }
    
    Write-HermesHost ''
    return $selectableCount
}

function Read-ConsoleChoice {
    <#
    .SYNOPSIS
        Reads and validates a numeric menu choice from the user.
    #>
    [CmdletBinding()]
    param(
        [int]$MaxChoice,
        [string]$Prompt = 'Selecciona una opcion',
        [bool]$AllowZero = $true
    )
    
    if ($AllowZero) {
        Write-HermesHost '(0 para salir)' -ForegroundColor Gray
    }
    
    Write-HermesHost ''

    do {
        Write-HermesHost ($Prompt + ': ') -NoNewline -ForegroundColor Cyan
        
        $val = Read-Host
        
        # TryParse instead of [int]: a very long number would overflow and end the script.
        $choice = 0
        if ("$val".Trim() -match '^\d+$' -and [int]::TryParse("$val".Trim(), [ref]$choice)) {
            if ($AllowZero -and $choice -eq 0) {
                return 0
            }
            if ($choice -ge 1 -and $choice -le $MaxChoice) {
                return $choice
            }
        }
        
        Write-HermesHost '  [!] Opcion invalida. Intenta de nuevo.' -ForegroundColor Red
        Write-HermesHost ''
    } while ($true)
}

function Invoke-ConsoleMenu {
    <#
    .SYNOPSIS
        Displays an interactive menu and executes selected actions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$MenuItems,
        
        [Parameter(Mandatory = $false)]
        [string]$Footer = ''
    )
    
    do {
        $options = $MenuItems | ForEach-Object { $_.Label }
        $count = Show-ConsoleMenu -Title $Title -Options $options -Footer $Footer
        
        $choice = Read-ConsoleChoice -MaxChoice $count -AllowZero $true
        
        if ($choice -eq 0) {
            break
        }
        
        $selectedItem = $MenuItems[$choice - 1]
        if ($selectedItem.Action) {
            & $selectedItem.Action
        }
        
        Write-HermesHost ''
        Write-HermesHost '  Presiona Enter para continuar...' -ForegroundColor Gray
        Read-Host
        
    } while ($true)
}

function Read-ConsoleMultiChoice {
    <#
    .SYNOPSIS
        Reads multiple selections from a list of options.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$Options,
        
        [Parameter(Mandatory = $false)]
        [string]$Prompt = 'Seleccione opciones (Separadas por coma)'
    )
    
    Write-HermesHost ('  ' + $Prompt) -ForegroundColor Cyan
    $i = 1
    foreach ($opt in $Options) {
        Write-HermesHost ('    [' + $i + '] ' + $opt)
        $i++
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

function Write-ConsoleTable {
    param(
        [Parameter()]
        [array]$Data,
        [Parameter()]
        [array]$Columns,
        [string]$Title = '',
        [string]$ColorMapProperty = '', 
        [hashtable]$ColorMap = @{}
    )

    if ($Data.Count -eq 0) {
        Write-HermesHost '  (No data to display)' -ForegroundColor Gray
        return
    }

    # Helper: Wrap Text
    function Get-WrappedLines {
        param([string]$Text, [int]$Width)
        if ([string]::IsNullOrEmpty($Text)) { return @('') }
        $rawLines = $Text -split "`n"
        $finalLines = @()
        foreach ($line in $rawLines) {
            if ($line.Length -le $Width) {
                $finalLines += $line
            }
            else {
                $currentLine = ''
                $words = $line -split ' '
                foreach ($word in $words) {
                    if (($currentLine.Length + $word.Length + 1) -le $Width) {
                        $currentLine += ($word + ' ')
                    }
                    else {
                        $finalLines += $currentLine.Trim()
                        $currentLine = ($word + ' ')
                    }
                }
                if ($currentLine) { $finalLines += $currentLine.Trim() }
            }
        }
        return $finalLines
    }
    
    # Simple table rendering
    Write-HermesHost ''
    if ($Title) { Write-HermesHost ('  ' + $Title) -ForegroundColor Cyan }
    
    # Headers
    Write-HermesHost '  ' -NoNewline
    foreach ($col in $Columns) {
        Write-HermesHost ($col.Header.PadRight($col.Width)) -NoNewline -ForegroundColor Yellow
    }
    Write-HermesHost ''
    
    # Rows
    foreach ($row in $Data) {
        Write-HermesHost '  ' -NoNewline
        foreach ($col in $Columns) {
            $val = $row.($col.Property)
            Write-HermesHost ([string]$val).PadRight($col.Width) -NoNewline -ForegroundColor White
        }
        Write-HermesHost ''
    }
    Write-HermesHost ''
}

function Invoke-ConsoleSpinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message, 
        
        [Parameter(Mandatory = $true)]
        [Alias('ScriptBlock')]
        [scriptblock]$Action
    )
    Write-HermesHost $Message -NoNewline
    $spinner = @('|', '/', '-', '\')
    # The spinner writes backspaces on purpose, so these two lines use Write-Host directly.
    $job = Start-Job -ScriptBlock $Action
    try {
        while ($job.State -in 'NotStarted', 'Running') {
            foreach ($s in $spinner) {
                Write-Host "`b$s" -NoNewline
                Start-Sleep -Milliseconds 100
            }
        }
        Receive-Job $job
        Write-Host "`bDone" -ForegroundColor Green
    }
    finally {
        # Stop and remove the job even if the user presses Ctrl+C, so it does not keep running.
        Remove-Job $job -Force -ErrorAction SilentlyContinue
    }
}

function Write-ConsoleProgress {
    param([string]$Activity, [int]$Percent)
    Write-Progress -Activity $Activity -PercentComplete $Percent
}

function Show-ConsoleProgress {
    <#
    .SYNOPSIS
        Displays a visual progress bar in the console.
    .DESCRIPTION
        Shows a progress bar with percentage using safe ASCII characters.
    .PARAMETER Activity
        Description of the activity being performed.
    .PARAMETER PercentComplete
        Percentage complete (0-100).
    .PARAMETER BarLength
        Length of the progress bar (default: 20).
    .PARAMETER Color
        Color of the filled portion (default: Cyan).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Activity,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$PercentComplete,
        
        [int]$BarLength = 20,
        [string]$Color = 'Cyan'
    )
    
    # Calculate filled and empty portions
    $filled = [Math]::Floor(($PercentComplete / 100) * $BarLength)
    $empty = $BarLength - $filled
    
    # Build progress bar using safe ASCII characters
    $filledBar = '#' * $filled
    $emptyBar = '.' * $empty
    
    # Display progress bar
    Write-HermesHost "  $Activity " -NoNewline
    Write-HermesHost '[' -NoNewline -ForegroundColor Gray
    Write-HermesHost $filledBar -NoNewline -ForegroundColor $Color
    Write-HermesHost $emptyBar -NoNewline -ForegroundColor DarkGray
    Write-HermesHost '] ' -NoNewline -ForegroundColor Gray
    Write-HermesHost "$PercentComplete%" -ForegroundColor $Color
}

function Read-ConsoleInput {
    param([string]$Prompt)
    return Read-Host -Prompt $Prompt
}

function Read-ConsoleConfirmation {
    param([string]$Message)
    $response = Read-Host "$Message (y/n)"
    return $response -eq 'y'
}

function Read-ConsolePassword {
    param([string]$Prompt)
    return Read-Host -Prompt $Prompt -AsSecureString
}

function Show-ConsoleNotification {
    param([string]$Message, [string]$Type = 'Info')
    Write-HermesHost "[$Type] $Message" -ForegroundColor Yellow
}


# No local Export-ModuleMember here - handled by main module
