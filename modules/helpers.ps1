<#
.SYNOPSIS
    PSConsoleUI - Helper Functions
    
.DESCRIPTION
    Core helper functions used by UI components.
    Includes: Border generation, text centering, value limiting, data validation.
#>

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
        All module output goes through here; it takes the same parameters as Write-Host.
    #>
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

function Get-ConsoleBorder {
    <#
    .SYNOPSIS
        Generates border characters for console UI elements.
    
    .PARAMETER Width
        The width of the border.
    
    .PARAMETER Style
        The border style: Single, Double, Rounded, or Heavy.
    
    .PARAMETER Part
        The part of the border: Top, Bottom, Left, Right, TopLeft, TopRight, BottomLeft, BottomRight, Horizontal, Vertical.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$Width = 60,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Single', 'Double', 'Rounded', 'Heavy')]
        [string]$Style = 'Single',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Top', 'Bottom', 'Left', 'Right', 'TopLeft', 'TopRight', 'BottomLeft', 'BottomRight', 'Horizontal', 'Vertical', 'Full')]
        [string]$Part = 'Horizontal'
    )
    
    $borders = @{
        'Single' = @{
            Horizontal = [char]0x2500
            Vertical = [char]0x2502
            TopLeft = [char]0x250C
            TopRight = [char]0x2510
            BottomLeft = [char]0x2514
            BottomRight = [char]0x2518
        }
        'Double' = @{
            Horizontal = [char]0x2550
            Vertical = [char]0x2551
            TopLeft = [char]0x2554
            TopRight = [char]0x2557
            BottomLeft = [char]0x255A
            BottomRight = [char]0x255D
        }
        'Rounded' = @{
            Horizontal = [char]0x2500
            Vertical = [char]0x2502
            TopLeft = [char]0x256D
            TopRight = [char]0x256E
            BottomLeft = [char]0x2570
            BottomRight = [char]0x256F
        }
        'Heavy' = @{
            Horizontal = [char]0x2501
            Vertical = [char]0x2503
            TopLeft = [char]0x250F
            TopRight = [char]0x2513
            BottomLeft = [char]0x2517
            BottomRight = [char]0x251B
        }
    }
    
    $b = $borders[$Style]
    
    switch ($Part) {
        'Horizontal' { return ([string]$b.Horizontal) * $Width }
        'Vertical' { return $b.Vertical }
        'TopLeft' { return $b.TopLeft }
        'TopRight' { return $b.TopRight }
        'BottomLeft' { return $b.BottomLeft }
        'BottomRight' { return $b.BottomRight }
        'Top' { return $b.TopLeft + (([string]$b.Horizontal) * ($Width - 2)) + $b.TopRight }
        'Bottom' { return $b.BottomLeft + (([string]$b.Horizontal) * ($Width - 2)) + $b.BottomRight }
        'Full' { return $b }
    }
}

function Get-CenteredText {
    <#
    .SYNOPSIS
        Centers text within a specified width.
    
    .PARAMETER Text
        The text to center.
    
    .PARAMETER Width
        The total width to center within.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$true)]
        [int]$Width
    )
    
    
    # Sanitizar input: eliminar caracteres nulos y no imprimibles que causan bugs visuales
    $cleanText = $Text -replace '[^\x20-\x7E]', ''
    $cleanText = $cleanText.Trim()
    
    # Prevenir padding negativo
    if ($cleanText.Length -ge $Width) { return $cleanText }

    $padding = ' ' * [Math]::Floor(($Width - $cleanText.Length) / 2)
    return "$padding$cleanText"
}

function Limit-Value {
    <#
    .SYNOPSIS
        Limits a value to a specified range.
    
    .PARAMETER Value
        The value to limit.
    
    .PARAMETER Min
        The minimum allowed value.
    
    .PARAMETER Max
        The maximum allowed value.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Value,
        
        [Parameter(Mandatory=$true)]
        [int]$Min,
        
        [Parameter(Mandatory=$true)]
        [int]$Max
    )
    
    return [Math]::Max($Min, [Math]::Min($Max, $Value))
}

function Test-ConsoleData {
    <#
    .SYNOPSIS
        Validates data for console UI functions.
    
    .PARAMETER Data
        The data to validate.
    
    .PARAMETER FunctionName
        The name of the calling function (for error messages).
    
    .PARAMETER AllowEmpty
        Whether to allow empty data.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        $Data,
        
        [Parameter(Mandatory=$true)]
        [string]$FunctionName,
        
        [Parameter(Mandatory=$false)]
        [switch]$AllowEmpty
    )
    
    if (-not $Data) {
        Write-Warning "${FunctionName}: No data provided"
        return $false
    }
    
    return $true
}

function Test-EmojiSupport {
    <#
    .SYNOPSIS
        Tests if the current console supports emoji characters.
    
    .DESCRIPTION
        Attempts to detect if the console can properly display emoji Unicode characters.
        Returns true if emojis are supported, false otherwise.
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Check PowerShell version (Core 6+ has better emoji support)
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            return $true
        }
        
        # Check if OutputEncoding supports UTF-8
        if ([Console]::OutputEncoding.CodePage -eq 65001) {
            return $true
        }
        
        # Default to false for older systems
        return $false
    } catch {
        return $false
    }
}


function Set-LayoutBuffer {
    <#
    .SYNOPSIS
        Merges multiple string arrays (columns) into a single line-by-line buffer.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Columns,
        
        [Parameter(Mandatory=$true)]
        [array]$Widths
    )
    
    # Find max depth (lines) across all columns
    $maxLines = 0
    foreach ($col in $Columns) {
        if ($col.Count -gt $maxLines) { $maxLines = $col.Count }
    }
    
    $mergedLines = @()
    for ($i = 0; $i -lt $maxLines; $i++) {
        $line = ""
        for ($c = 0; $c -lt $Columns.Count; $c++) {
            $colContent = $Columns[$c]
            $width = $Widths[$c]
            
            # Get specific line or empty space
            $content = ""
            if ($null -ne $colContent -and $colContent -is [array] -and $i -lt $colContent.Count) {
                $content = $colContent[$i].ToString()
            }
            
            # Pad content to fit column width
            # Remove only non-printable control characters (0-31), keep everything else
            $cleanContent = $content -replace '[\x00-\x1F]', '' 
            if ($cleanContent.Length -gt $width) {
                $cleanContent = $cleanContent.Substring(0, $width)
            }
            $padding = ' ' * [Math]::Max(0, ($width - $cleanContent.Length))
            $line += $cleanContent + $padding + '  ' # 2 space gap between columns
        }
        
        # Pad entire line to ensure it clears previous output residue ("Ghosting")
        $expectedTotal = ($Widths | Measure-Object -Sum).Sum + (($Columns.Count - 1) * 2)
        $finalLine = $line.TrimEnd()
        $linePadding = ' ' * [Math]::Max(0, ($expectedTotal - $finalLine.Length))
        $mergedLines += ($finalLine + $linePadding)
    }
    return $mergedLines
}

function Invoke-CapturedOutput {
    <#
    .SYNOPSIS
        Executes a scriptblock and returns its output as an array of lines.
        Note: This only works with functions updated to support -ReturnLines.
    #>
    param([scriptblock]$Code)
    
    $output = @()
    & $Code | ForEach-Object { $output += $_ }
    return $output
}


function Get-ComponentIcon {
    <#
    .SYNOPSIS
        Returns appropriate icon for a component based on console capabilities.
    
    .DESCRIPTION
        Returns emoji icons if supported, falls back to safe Unicode icons otherwise.
        Implements automatic Versión B/C fallback strategy.
    
    .PARAMETER ComponentType
        Type of component: Metadata, Summary, Success, Warning, Error, Info
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Metadata', 'Summary', 'Success', 'Warning', 'Error', 'Info')]
        [string]$ComponentType
    )
    
    # Safe icons that work everywhere (Unicode BMP)
    $safeIcons = @{
        Metadata = [char]0x2699    # ⚙
        Summary = [char]0x25A3     # ▣
        Success = [char]0x221A     # √
        Warning = [char]0x26A0     # ⚠
        Error   = [char]0x2715     # ✕
        Info    = '[i]'            # Bracketed style as per user preference
    }
    
    # Try to use emoji if supported
    if (Test-EmojiSupport) {
        try {
            switch ($ComponentType) {
                'Summary' { return [System.Char]::ConvertFromUtf32(0x1F4CA) } # 📊
                'Success' { return [char]0x2714 } # ✔
                'Warning' { return [char]0x26A0 } # ⚠
                'Error'   { return [char]0x2716 } # ✖
                'Info'    { return '[i]' }        # Bracketed style as per user preference
                default   { return $safeIcons[$ComponentType] }
            }
        } catch {
            return $safeIcons[$ComponentType]
        }
    } else {
        return $safeIcons[$ComponentType]
    }
}

# No local Export-ModuleMember here - handled by main module
