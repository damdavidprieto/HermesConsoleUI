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
    Write-Host ''
    Write-Host $border -ForegroundColor $Color
    $padding = [Math]::Floor(($width - $Title.Length) / 2)
    Write-Host ((' ' * $padding) + $Title) -ForegroundColor White
    Write-Host $border -ForegroundColor $Color
    Write-Host ''
    
    $selectableCount = 0
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $opt = $Options[$i]
        
        if ($opt -match '^---') {
            Write-Host ('  ' + $opt) -ForegroundColor DarkGray
        }
        elseif ($opt -match '^\[') {
            Write-Host ('  ' + $opt) -ForegroundColor $Color
        }
        else {
            $selectableCount++
            $text = $opt
            $itemColor = $OptionColor
            if ($opt -match '^\{([a-zA-Z]+)\}(.*)') {
                $itemColor = $matches[1]
                $text = $matches[2]
            }
            Write-Host '  [' -NoNewline -ForegroundColor Gray
            Write-Host ([string]$selectableCount) -NoNewline -ForegroundColor $Color
            Write-Host '] ' -NoNewline -ForegroundColor Gray
            Write-Host $text -ForegroundColor $itemColor
        }
    }
    
    if ($Footer) {
        Write-Host ''
        Write-Host ('  ' + $Footer) -ForegroundColor Yellow
    }
    
    Write-Host ''
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
        Write-Host '(0 para salir)' -ForegroundColor Gray
    }
    
    Write-Host ''

    do {
        Write-Host ($Prompt + ': ') -NoNewline -ForegroundColor Cyan
        
        $val = Read-Host
        
        if ($val -match '^\d+$') {
            $choice = [int]$val
            if ($AllowZero -and $choice -eq 0) {
                return 0
            }
            if ($choice -ge 1 -and $choice -le $MaxChoice) {
                return $choice
            }
        }
        
        Write-Host '  [!] Opcion invalida. Intenta de nuevo.' -ForegroundColor Red
        Write-Host ''
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
        
        Write-Host ''
        Write-Host '  Presiona Enter para continuar...' -ForegroundColor Gray
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
    
    Write-Host ('  ' + $Prompt) -ForegroundColor Cyan
    $i = 1
    foreach ($opt in $Options) {
        Write-Host ('    [' + $i + '] ' + $opt)
        $i++
    }
    
    $val = Read-Host '    > '
    if (-not $val) { return @() }
    
    $selectedIndices = $val.Split(',')
    $results = @()
    foreach ($idx in $selectedIndices) {
        if ($idx -match '^\d+$' -and [int]$idx -le $Options.Count) {
            $results += $Options[[int]$idx - 1]
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
        Write-Host '  (No data to display)' -ForegroundColor Gray
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
    Write-Host ''
    if ($Title) { Write-Host ('  ' + $Title) -ForegroundColor Cyan }
    
    # Headers
    Write-Host '  ' -NoNewline
    foreach ($col in $Columns) {
        Write-Host ($col.Header.PadRight($col.Width)) -NoNewline -ForegroundColor Yellow
    }
    Write-Host ''
    
    # Rows
    foreach ($row in $Data) {
        Write-Host '  ' -NoNewline
        foreach ($col in $Columns) {
            $val = $row.($col.Property)
            Write-Host ([string]$val).PadRight($col.Width) -NoNewline -ForegroundColor White
        }
        Write-Host ''
    }
    Write-Host ''
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
    Write-Host $Message -NoNewline
    $spinner = @('|', '/', '-', '\')
    $job = Start-Job -ScriptBlock $Action
    while ($job.State -eq 'Running') {
        foreach ($s in $spinner) {
            Write-Host "`b$s" -NoNewline
            Start-Sleep -Milliseconds 100
        }
    }
    Receive-Job $job
    Write-Host "`bDone" -ForegroundColor Green
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
    Write-Host "  $Activity " -NoNewline
    Write-Host '[' -NoNewline -ForegroundColor Gray
    Write-Host $filledBar -NoNewline -ForegroundColor $Color
    Write-Host $emptyBar -NoNewline -ForegroundColor DarkGray
    Write-Host '] ' -NoNewline -ForegroundColor Gray
    Write-Host "$PercentComplete%" -ForegroundColor $Color
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
    Write-Host "[$Type] $Message" -ForegroundColor Yellow
}


# No local Export-ModuleMember here - handled by main module
