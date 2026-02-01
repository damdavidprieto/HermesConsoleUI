<#
.SYNOPSIS
    PSConsoleUI - Framework Constants
    
.DESCRIPTION
    Centralized constants for the PSConsoleUI framework.
    Includes Unicode characters, default values, and immutable configurations.
#>

# Unicode Box Drawing Characters
$script:BoxChars = @{
    Single = @{
        Horizontal = [char]0x2500
        Vertical = [char]0x2502
        TopLeft = [char]0x250C
        TopRight = [char]0x2510
        BottomLeft = [char]0x2514
        BottomRight = [char]0x2518
        Cross = [char]0x253C
        TeeLeft = [char]0x251C
        TeeRight = [char]0x2524
        TeeTop = [char]0x252C
        TeeBottom = [char]0x2534
    }
    Double = @{
        Horizontal = [char]0x2550
        Vertical = [char]0x2551
        TopLeft = [char]0x2554
        TopRight = [char]0x2557
        BottomLeft = [char]0x255A
        BottomRight = [char]0x255D
        Cross = [char]0x256C
        TeeLeft = [char]0x2560
        TeeRight = [char]0x2563
        TeeTop = [char]0x2566
        TeeBottom = [char]0x2569
    }
    Rounded = @{
        Horizontal = [char]0x2500
        Vertical = [char]0x2502
        TopLeft = [char]0x256D
        TopRight = [char]0x256E
        BottomLeft = [char]0x2570
        BottomRight = [char]0x256F
        Cross = [char]0x253C
        TeeLeft = [char]0x251C
        TeeRight = [char]0x2524
        TeeTop = [char]0x252C
        TeeBottom = [char]0x2534
    }
    Heavy = @{
        Horizontal = [char]0x2501
        Vertical = [char]0x2503
        TopLeft = [char]0x250F
        TopRight = [char]0x2513
        BottomLeft = [char]0x2517
        BottomRight = [char]0x251B
        Cross = [char]0x254B
        TeeLeft = [char]0x2523
        TeeRight = [char]0x252B
        TeeTop = [char]0x2533
        TeeBottom = [char]0x253B
    }
}

# Unicode Block Characters (for charts and progress bars)
$script:BlockChars = @{
    Full = [char]0x2588
    SevenEighths = [char]0x2589
    ThreeQuarters = [char]0x258A
    FiveEighths = [char]0x258B
    Half = [char]0x258C
    ThreeEighths = [char]0x258D
    Quarter = [char]0x258E
    Eighth = [char]0x258F
    Empty = [char]0x2591
    Light = [char]0x2591
    Medium = [char]0x2592
    Dark = [char]0x2593
}

# Unicode Arrows
$script:ArrowChars = @{
    Up = [char]0x2191
    Down = [char]0x2193
    Left = [char]0x2190
    Right = [char]0x2192
    UpDown = [char]0x2195
    LeftRight = [char]0x2194
    DoubleUp = [char]0x21D1
    DoubleDown = [char]0x21D3
    DoubleLeft = [char]0x21D0
    DoubleRight = [char]0x21D2
}

# Unicode Symbols
$script:SymbolChars = @{
    Check = [char]0x2713
    Cross = [char]0x2717
    Star = [char]0x2605
    Circle = [char]0x25CF
    Square = [char]0x25A0
    Diamond = [char]0x25C6
    Triangle = [char]0x25B2
    Warning = [char]0x26A0
    Info = [char]0x2139
    Question = '?'
    Bullet = [char]0x2022
    Ellipsis = [char]0x2026
}

# Default Values
$script:Defaults = @{
    Width = 60
    MinWidth = 20
    MaxWidth = 120
    Color = 'White'
    BorderStyle = 'Single'
    Separator = ' > '
    Indent = '  '
    PaddingChar = ' '
}

# Color Mappings
$script:ColorMap = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'Cyan'
    Muted = 'Gray'
    Highlight = 'White'
    Primary = 'Cyan'
    Secondary = 'Yellow'
}

# Status Icons
$script:StatusIcons = @{
    Success = '[+]'
    Warning = '[!]'
    Error = '[x]'
    Info = '[i]'
    Processing = '[*]'
    Question = '[?]'
}

# Validation Limits
$script:ValidationLimits = @{
    MinStringLength = 1
    MaxStringLength = 500
    MinWidth = 20
    MaxWidth = 200
    MinHeight = 1
    MaxHeight = 100
    MinPercent = 0
    MaxPercent = 100
}

# Framework Metadata
$script:FrameworkInfo = @{
    Name = 'PSConsoleUI'
    Version = '2.0.0'
    Author = 'PSConsoleUI Team'
    License = 'MIT'
    MinPSVersion = '2.0'
    Repository = 'https://github.com/yourorg/PSConsoleUI'
}

# Export constants as read-only variables
function Get-BoxCharacters {
    <#
    .SYNOPSIS
        Returns Unicode box drawing characters.
    
    .PARAMETER Style
        Border style: Single, Double, Rounded, Heavy
    #>
    param([ValidateSet('Single','Double','Rounded','Heavy')][string]$Style = 'Single')
    return $script:BoxChars[$Style]
}

function Get-BlockCharacters {
    <#
    .SYNOPSIS
        Returns Unicode block characters for charts.
    #>
    return $script:BlockChars
}

function Get-SymbolCharacters {
    <#
    .SYNOPSIS
        Returns Unicode symbol characters.
    #>
    return $script:SymbolChars
}

function Get-DefaultValues {
    <#
    .SYNOPSIS
        Returns framework default values.
    #>
    return $script:Defaults
}

function Get-ColorMapping {
    <#
    .SYNOPSIS
        Returns color mappings for semantic colors.
    #>
    return $script:ColorMap
}

function Get-ValidationLimits {
    <#
    .SYNOPSIS
        Returns validation limits for framework parameters.
    #>
    return $script:ValidationLimits
}

function Get-FrameworkInfo {
    <#
    .SYNOPSIS
        Returns framework metadata.
    #>
    return $script:FrameworkInfo
}

# Export functions
Export-ModuleMember -Function Get-BoxCharacters, Get-BlockCharacters, Get-SymbolCharacters,
    Get-DefaultValues, Get-ColorMapping, Get-ValidationLimits, Get-FrameworkInfo
