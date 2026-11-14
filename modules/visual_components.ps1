<#
.SYNOPSIS
    PSConsoleUI - Visual Components
.DESCRIPTION
    Visual UI components including lists, trees, charts.
#>

function Show-ConsoleList {
    <#
    .SYNOPSIS
        Displays a formatted list of items.
    
    .DESCRIPTION
        Writes a list with optional numbering or bullets.
    
    .PARAMETER Items
        Array of items to display.
    
    .PARAMETER Numbered
        If specified, displays numbered list (1., 2., 3.)
    
    .PARAMETER Bullet
        Bullet character to use. Default: '•'. Ignored if -Numbered is used.
    
    .PARAMETER Color
        Color for the list items. Default: White
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$Items,
        
        [Parameter(Mandatory = $false)]
        [switch]$Numbered,
        
        [Parameter(Mandatory = $false)]
        [string]$Bullet = '•',
        
        [Parameter(Mandatory = $false)]
        [string]$Color = 'White',
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 40,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnLines
    )
    
    $lines = @()
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $prefix = if ($Numbered) { ($i + 1).ToString() + '. ' } else { $Bullet + ' ' }
        $fullLine = "$prefix$($Items[$i])"
        
        if ($Width -gt 0 -and $fullLine.Length -gt $Width) {
            $fullLine = $fullLine.Substring(0, $Width)
        }
        $lines += $fullLine
    }
    
    if ($ReturnLines) { return $lines }
    
    foreach ($l in $lines) {
        Write-HermesHost "  $l" -ForegroundColor $Color
    }
}

function Write-ConsoleTree {
    param(
        [hashtable]$TreeData, 
        [string]$Indent = '  '
    )
    $Tee = [string][char]0x251C
    $HBar = [string][char]0x2500
    $VBar = [string][char]0x2502
    $Corner = [string][char]0x2514
    
    $branch = $Tee + $HBar + $HBar + ' '
    $leaf = $Corner + $HBar + $HBar + ' '
    $pipe = $VBar + '   '

    foreach ($key in $TreeData.Keys) {
        Write-HermesHost ($Indent + $branch + $key) -ForegroundColor Cyan
        $val = $TreeData[$key]
        if ($val -is [hashtable]) {
            Write-ConsoleTree -TreeData $val -Indent ($Indent + $pipe)
        }
        elseif ($val -is [array] -or $val -is [string]) {
            foreach ($item in $val) {
                Write-HermesHost ($Indent + $pipe + $leaf + $item) -ForegroundColor Gray
            }
        }
    }
}

function Write-ConsoleChart {
    <#
    .SYNOPSIS
        Displays a horizontal bar chart.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Label,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Value,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Max = 100,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = 'Green',
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 20,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnLines
    )
    
    $chartWidth = $Width
    if ($Max -gt 0) { $percent = [Math]::Round(($Value / $Max) * 100) } else { $percent = 0 }
    $filledLen = [Math]::Floor(($Value / $Max) * $chartWidth)
    $f = [char]0x2588 # Full block
    $e = [char]0x2591 # Light shade
    $filledLen = [Math]::Max(0, [Math]::Min($chartWidth, $filledLen))
    $emptyLen = $chartWidth - $filledLen
    $bar = ([string]$f * $filledLen) + ([string]$e * $emptyLen)
    
    $fullLine = $Label + ": " + $percent + "% [" + $bar + "]"
    
    if ($ReturnLines) {
        return @($fullLine)
    }
    
    Write-HermesHost ('  ' + $Label) -NoNewline -ForegroundColor White
    Write-HermesHost (': ' + $percent + '% [' + $bar + ']') -ForegroundColor $Color
}

function Write-ConsoleSparkline {
    <#
    .SYNOPSIS
        Displays an inline mini-chart for data trends.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$Data,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = 'Cyan',
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowMinMax
    )
    
    # Sparkline characters (8 levels)
    $chars = @([char]0x2581, [char]0x2582, [char]0x2583, [char]0x2584, [char]0x2585, [char]0x2586, [char]0x2587, [char]0x2588)
    
    # Find min and max for normalization
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    $range = $max - $min
    
    if ($range -eq 0) {
        # All values are the same
        $sparkline = $chars[4] * $Data.Count
    }
    else {
        $sparkline = ""
        for ($i = 0; $i -lt $Data.Count; $i++) {
            $value = $Data[$i]
            # Normalize to 0-7 range
            $normalized = [Math]::Floor((($value - $min) / $range) * 7)
            $normalized = [Math]::Max(0, [Math]::Min(7, $normalized))
            
            if ($ShowMinMax) {
                if ($value -eq $min) {
                    Write-HermesHost $chars[$normalized] -NoNewline -ForegroundColor Red
                }
                elseif ($value -eq $max) {
                    Write-HermesHost $chars[$normalized] -NoNewline -ForegroundColor Green
                }
                else {
                    Write-HermesHost $chars[$normalized] -NoNewline -ForegroundColor $Color
                }
            }
            else {
                $sparkline += $chars[$normalized]
            }
        }
        
        if (-not $ShowMinMax) {
            Write-HermesHost ('  ' + $sparkline) -ForegroundColor $Color
        }
        else {
            Write-HermesHost ''
        }
    }
}

function Write-ConsolePanel {
    <#
    .SYNOPSIS
        Displays content in a bordered panel.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Title = '',
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [scriptblock]$Content,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Single', 'Double', 'Rounded', 'Heavy')]
        [string]$BorderStyle = 'Single',
        
        [Parameter(Mandatory = $false)]
        [string]$Color = 'Cyan',
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(20, 120)]
        [int]$Width = 60
    )
    
    # Define border characters for each style
    $borders = @{
        'Single'  = @{
            TopLeft = [char]0x250C; TopRight = [char]0x2510; BottomLeft = [char]0x2514; BottomRight = [char]0x2518
            Horizontal = [char]0x2500; Vertical = [char]0x2502
        }
        'Double'  = @{
            TopLeft = [char]0x2554; TopRight = [char]0x2557; BottomLeft = [char]0x255A; BottomRight = [char]0x255D
            Horizontal = [char]0x2550; Vertical = [char]0x2551
        }
        'Rounded' = @{
            TopLeft = [char]0x256D; TopRight = [char]0x256E; BottomLeft = [char]0x2570; BottomRight = [char]0x256F
            Horizontal = [char]0x2500; Vertical = [char]0x2502
        }
        'Heavy'   = @{
            TopLeft = [char]0x250F; TopRight = [char]0x2513; BottomLeft = [char]0x2517; BottomRight = [char]0x251B
            Horizontal = [char]0x2501; Vertical = [char]0x2503
        }
    }
    
    $b = $borders[$BorderStyle]
    $innerWidth = $Width - 4
    
    # Top border with title
    Write-HermesHost ''
    if ($Title) {
        $titleLen = $Title.Length + 2
        $leftLen = [Math]::Floor(($Width - $titleLen - 2) / 2)
        $rightLen = $Width - $titleLen - $leftLen - 2
        
        Write-HermesHost ('  ' + $b.TopLeft + (([string]$b.Horizontal) * $leftLen) + ' ' + $Title + ' ' + (([string]$b.Horizontal) * $rightLen) + $b.TopRight) -ForegroundColor $Color
    }
    else {
        Write-HermesHost ('  ' + $b.TopLeft + (([string]$b.Horizontal) * ($Width - 2)) + $b.TopRight) -ForegroundColor $Color
    }
    
    # Get content lines
    $contentLines = @()
    if ($Content -is [scriptblock]) {
        # Execute scriptblock and capture return values (not Write-HermesHost)
        $contentLines = @(& $Content)
    }
    elseif ($Content -is [array]) {
        $contentLines = $Content
    }
    else {
        $contentLines = @($Content.ToString())
    }
    
    # Display content with borders
    if ($contentLines.Count -eq 0) {
        Write-HermesHost ('  ' + $b.Vertical + (' ' * ($Width - 2)) + $b.Vertical) -ForegroundColor $Color
    }
    else {
        foreach ($line in $contentLines) {
            $trimmed = $line.ToString().TrimEnd()
            if ($trimmed.Length -gt $innerWidth) {
                $trimmed = $trimmed.Substring(0, $innerWidth)
            }
            $padding = ' ' * ($innerWidth - $trimmed.Length)
            Write-HermesHost ('  ' + $b.Vertical + ' ') -NoNewline -ForegroundColor $Color
            Write-HermesHost $trimmed -NoNewline
            Write-HermesHost (' ' + $padding + $b.Vertical) -ForegroundColor $Color
        }
    }
    
    # Bottom border
    Write-HermesHost ('  ' + $b.BottomLeft + (([string]$b.Horizontal) * ($Width - 2)) + $b.BottomRight) -ForegroundColor $Color
    Write-HermesHost ''
}

function Write-ConsoleBox {
    <#
    .SYNOPSIS
        Displays a message in a bordered box.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = 'Cyan',
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 0, # Auto-size if 0
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnLines
    )
    
    $boxWidth = if ($Width -gt 0) { $Width } else { 
        $maxLen = 0
        $Message.Split("`n") | ForEach-Object { if ($_.Trim().Length -gt $maxLen) { $maxLen = $_.Trim().Length } }
        $maxLen + 4
    }
    
    $border = '+' + ('-' * ($boxWidth - 2)) + '+'
    $lines = @($border)
    
    $Message.Split("`n") | ForEach-Object {
        $msg = $_.Trim()
        $inner = if ($msg.Length -gt ($boxWidth - 4)) { $msg.Substring(0, $boxWidth - 4) } else { $msg + (' ' * ($boxWidth - 4 - $msg.Length)) }
        $lines += "| $inner |"
    }
    
    $lines += $border
    
    if ($ReturnLines) {
        return $lines
    }
    
    Write-HermesHost ''
    foreach ($l in $lines) {
        Write-HermesHost $l -ForegroundColor $Color
    }
    Write-HermesHost ''
}





# No local Export-ModuleMember here - handled by main module
