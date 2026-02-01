<#
.SYNOPSIS
    PSConsoleUI - Custom Validators
    
.DESCRIPTION
    Reusable validation functions for PSConsoleUI framework.
    Provides complex validators for parameters and data structures.
#>

function Test-ValidColor {
    <#
    .SYNOPSIS
        Validates if a color name is valid for PowerShell console.
    
    .PARAMETER Color
        Color name to validate.
    
    .EXAMPLE
        Test-ValidColor -Color "Red"
        Returns $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Color
    )
    
    $validColors = @(
        'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta',
        'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red',
        'Magenta', 'Yellow', 'White'
    )
    
    return $validColors -contains $Color
}

function Test-ValidWidth {
    <#
    .SYNOPSIS
        Validates if a width value is within acceptable range.
    
    .PARAMETER Width
        Width value to validate.
    
    .PARAMETER Min
        Minimum allowed width. Default: 20
    
    .PARAMETER Max
        Maximum allowed width. Default: 200
    
    .EXAMPLE
        Test-ValidWidth -Width 80
        Returns $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Width,
        
        [Parameter(Mandatory=$false)]
        [int]$Min = 20,
        
        [Parameter(Mandatory=$false)]
        [int]$Max = 200
    )
    
    return ($Width -ge $Min -and $Width -le $Max)
}

function Test-ValidBorderStyle {
    <#
    .SYNOPSIS
        Validates if a border style is supported.
    
    .PARAMETER Style
        Border style to validate.
    
    .EXAMPLE
        Test-ValidBorderStyle -Style "Single"
        Returns $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Style
    )
    
    $validStyles = @('Single', 'Double', 'Rounded', 'Heavy', 'ASCII')
    return $validStyles -contains $Style
}

function Test-ValidTheme {
    <#
    .SYNOPSIS
        Validates if a theme name exists in configuration.
    
    .PARAMETER ThemeName
        Theme name to validate.
    
    .PARAMETER AvailableThemes
        Array of available theme names.
    
    .EXAMPLE
        Test-ValidTheme -ThemeName "Cyberpunk" -AvailableThemes @("Default", "Cyberpunk")
        Returns $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ThemeName,
        
        [Parameter(Mandatory=$true)]
        [array]$AvailableThemes
    )
    
    return $AvailableThemes -contains $ThemeName
}

function Test-ValidLocale {
    <#
    .SYNOPSIS
        Validates if a locale code is in correct format.
    
    .PARAMETER Locale
        Locale code to validate (e.g., "en-US", "es-ES").
    
    .EXAMPLE
        Test-ValidLocale -Locale "en-US"
        Returns $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Locale
    )
    
    # Validate format: xx-XX (e.g., en-US, es-ES, fr-FR)
    return $Locale -match '^[a-z]{2}-[A-Z]{2}$'
}

function Test-ValidPercentage {
    <#
    .SYNOPSIS
        Validates if a value is a valid percentage (0-100).
    
    .PARAMETER Value
        Value to validate.
    
    .EXAMPLE
        Test-ValidPercentage -Value 75
        Returns $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Value
    )
    
    return ($Value -ge 0 -and $Value -le 100)
}

function Test-ValidDataStructure {
    <#
    .SYNOPSIS
        Validates if data structure is suitable for UI components.
    
    .PARAMETER Data
        Data to validate.
    
    .PARAMETER RequiredProperties
        Array of required property names.
    
    .EXAMPLE
        Test-ValidDataStructure -Data $obj -RequiredProperties @("Name", "Value")
        Returns $true if object has Name and Value properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Data,
        
        [Parameter(Mandatory=$false)]
        [array]$RequiredProperties = @()
    )
    
    if (-not $Data) {
        return $false
    }
    
    # Check if data is enumerable
    if ($Data -isnot [Array] -and $Data -isnot [System.Collections.IEnumerable]) {
        # Single object, wrap in array
        $Data = @($Data)
    }
    
    # If no required properties, just check if data exists
    if ($RequiredProperties.Count -eq 0) {
        return $true
    }
    
    # Check first item for required properties
    $firstItem = $Data | Select-Object -First 1
    foreach ($prop in $RequiredProperties) {
        if (-not (Get-Member -InputObject $firstItem -Name $prop -MemberType Properties)) {
            return $false
        }
    }
    
    return $true
}

function Test-ValidTreeStructure {
    <#
    .SYNOPSIS
        Validates if a hashtable is a valid tree structure.
    
    .PARAMETER TreeData
        Hashtable representing tree structure.
    
    .EXAMPLE
        Test-ValidTreeStructure -TreeData @{"Root" = @("Child1", "Child2")}
        Returns $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $TreeData
    )
    
    if ($TreeData -isnot [hashtable]) {
        return $false
    }
    
    if ($TreeData.Count -eq 0) {
        return $false
    }
    
    # Valid tree structure
    return $true
}

function Assert-ValidParameter {
    <#
    .SYNOPSIS
        Asserts that a parameter value is valid, throws if not.
    
    .PARAMETER Value
        Value to validate.
    
    .PARAMETER ParameterName
        Name of the parameter (for error message).
    
    .PARAMETER ValidatorFunction
        Scriptblock that returns $true if valid.
    
    .EXAMPLE
        Assert-ValidParameter -Value $color -ParameterName "Color" -ValidatorFunction {Test-ValidColor $_}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Value,
        
        [Parameter(Mandatory=$true)]
        [string]$ParameterName,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$ValidatorFunction
    )
    
    $isValid = & $ValidatorFunction $Value
    
    if (-not $isValid) {
        throw "Invalid value for parameter '$ParameterName': $Value"
    }
}

# Export functions
Export-ModuleMember -Function Test-ValidColor, Test-ValidWidth, Test-ValidBorderStyle,
    Test-ValidTheme, Test-ValidLocale, Test-ValidPercentage, Test-ValidDataStructure,
    Test-ValidTreeStructure, Assert-ValidParameter
