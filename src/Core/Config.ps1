<#
.SYNOPSIS
    PSConsoleUI Configuration System
    
.DESCRIPTION
    Manages UI configuration including themes, colors, icons, and component defaults.
    Loads configuration from JSON and provides runtime access and modification.
#>

# Module-level variables
$script:UIConfig = $null
$script:DefaultConfig = @{
    UILibrary = @{
        Version = '1.0.0'
        ActiveTheme = 'Default'
        DefaultLocale = 'en-US'
        ColorScheme = @{
            Default = @{
                Primary = 'Cyan'
                Secondary = 'Yellow'
                Success = 'Green'
                Warning = 'Yellow'
                Error = 'Red'
                Info = 'Cyan'
                Muted = 'Gray'
                Highlight = 'White'
            }
        }
        Components = @{
            Status = @{
                Icons = @{
                    Success = '[+]'
                    Warning = '[!]'
                    Error = '[x]'
                    Info = '[*]'
                }
            }
            Title = @{
                DefaultColor = 'Cyan'
                MinWidth = 60
            }
            Header = @{
                DefaultColor = 'Yellow'
                Prefix = '>>> '
            }
            Box = @{
                DefaultColor = 'Cyan'
                BorderStyle = 'ASCII'
            }
            Chart = @{
                DefaultColor = 'Green'
                DefaultWidth = 20
                FilledChar = '█'
                EmptyChar = '░'
            }
            Tree = @{
                UseUnicode = $true
            }
            Table = @{
                DefaultColumnWidth = 20
                MaxColumnWidth = 80
                HeaderColor = 'Yellow'
                SeparatorColor = 'DarkGray'
            }
            Menu = @{
                DefaultColor = 'Cyan'
                OptionColor = 'Gray'
                Width = 60
            }
            Progress = @{
                DefaultColor = 'Cyan'
                CompleteColor = 'Green'
                Width = 30
            }
        }
    }
}

function Initialize-UIConfig {
    <#
    .SYNOPSIS
        Initializes the UI configuration system.
    
    .DESCRIPTION
        Loads configuration from JSON file. Falls back to default configuration if file not found.
    
    .PARAMETER ConfigPath
        Optional path to the configuration file. Defaults to config/ui_config.json.
    
    .EXAMPLE
        Initialize-UIConfig
        
        Loads configuration from default location.
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigPath = $null
    )
    
    # Determine config path
    if (-not $ConfigPath) {
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $ConfigPath = Join-Path $moduleRoot 'config\ui_config.json'
    }
    
    # Load configuration
    if (Test-Path $ConfigPath) {
        try {
            $configContent = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            # Convert PSCustomObject to hashtable for easier manipulation
            $script:UIConfig = ConvertTo-Hashtable -InputObject $configContent
            Write-Verbose "Configuration loaded from: $ConfigPath"
        } catch {
            Write-Warning "Failed to load configuration from '$ConfigPath': $_"
            Write-Warning "Using default configuration"
            $script:UIConfig = $script:DefaultConfig
        }
    } else {
        Write-Verbose "Configuration file not found: $ConfigPath"
        Write-Verbose "Using default configuration"
        $script:UIConfig = $script:DefaultConfig
    }
}

function ConvertTo-Hashtable {
    <#
    .SYNOPSIS
        Converts PSCustomObject to Hashtable recursively.
    
    .DESCRIPTION
        Helper function to convert JSON objects to hashtables for easier manipulation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $InputObject
    )
    
    if ($InputObject -is [PSCustomObject]) {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
        }
        return $hash
    } elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $array = @()
        foreach ($item in $InputObject) {
            $array += ConvertTo-Hashtable -InputObject $item
        }
        return $array
    } else {
        return $InputObject
    }
}

function Get-UIConfig {
    <#
    .SYNOPSIS
        Gets the current UI configuration.
    
    .DESCRIPTION
        Returns the entire configuration object or a specific section.
    
    .PARAMETER Section
        Optional section path (e.g., "UILibrary.ColorScheme.Default").
    
    .EXAMPLE
        Get-UIConfig
        
        Returns entire configuration.
    
    .EXAMPLE
        Get-UIConfig -Section "UILibrary.ActiveTheme"
        
        Returns "Default".
    #>
    [CmdletBinding()]
    param(
        [string]$Section = $null
    )
    
    if (-not $script:UIConfig) {
        Write-Warning "Configuration not initialized. Call Initialize-UIConfig first."
        return $null
    }
    
    if (-not $Section) {
        return $script:UIConfig
    }
    
    # Navigate nested keys
    $keys = $Section -split '\.'
    $value = $script:UIConfig
    
    foreach ($key in $keys) {
        if ($value -is [hashtable] -and $value.ContainsKey($key)) {
            $value = $value[$key]
        } else {
            Write-Warning "Configuration section not found: $Section"
            return $null
        }
    }
    
    return $value
}

function Get-UIColor {
    <#
    .SYNOPSIS
        Gets a color from the active theme.
    
    .DESCRIPTION
        Retrieves a color value from the active theme's color scheme.
    
    .PARAMETER ColorType
        The type of color to retrieve (Primary, Success, Warning, Error, Info, etc.).
    
    .PARAMETER Theme
        Optional theme name to use instead of active theme.
    
    .EXAMPLE
        Get-UIColor -ColorType "Success"
        
        Returns "Green" (from active theme).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Primary', 'Secondary', 'Success', 'Warning', 'Error', 'Info', 'Muted', 'Highlight')]
        [string]$ColorType,
        
        [string]$Theme = $null
    )
    
    if (-not $script:UIConfig) {
        Write-Warning "Configuration not initialized"
        return 'White'
    }
    
    $themeName = if ($Theme) { $Theme } else { $script:UIConfig.UILibrary.ActiveTheme }
    
    $colorScheme = $script:UIConfig.UILibrary.ColorScheme
    if ($colorScheme.ContainsKey($themeName)) {
        $themeColors = $colorScheme[$themeName]
        if ($themeColors.ContainsKey($ColorType)) {
            return $themeColors[$ColorType]
        }
    }
    
    Write-Warning "Color '$ColorType' not found in theme '$themeName'"
    return 'White'
}

function Get-UIIcon {
    <#
    .SYNOPSIS
        Gets an icon from the configuration.
    
    .DESCRIPTION
        Retrieves an icon string from the component configuration.
    
    .PARAMETER IconType
        The type of icon to retrieve (Success, Warning, Error, Info).
    
    .EXAMPLE
        Get-UIIcon -IconType "Success"
        
        Returns "[+]".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Success', 'Warning', 'Error', 'Info')]
        [string]$IconType
    )
    
    if (-not $script:UIConfig) {
        Write-Warning "Configuration not initialized"
        return '[*]'
    }
    
    $icons = $script:UIConfig.UILibrary.Components.Status.Icons
    if ($icons.ContainsKey($IconType)) {
        return $icons[$IconType]
    }
    
    return '[*]'
}

function Set-ConsoleTheme {
    <#
    .SYNOPSIS
        Changes the active UI theme.
    
    .DESCRIPTION
        Sets the active theme for the UI framework. The theme must exist in the configuration.
    
    .PARAMETER ThemeName
        The theme name to activate (Default, Cyberpunk, Classic, Monochrome, or Custom).
    
    .PARAMETER CustomColors
        Optional hashtable of custom colors when using Custom theme.
    
    .EXAMPLE
        Set-ConsoleTheme -ThemeName "Cyberpunk"
        
        Changes theme to Cyberpunk.
    
    .EXAMPLE
        Set-ConsoleTheme -ThemeName "Custom" -CustomColors @{
            Primary = "DarkCyan"
            Success = "DarkGreen"
            Error = "DarkRed"
        }
        
        Creates and activates a custom theme.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Default', 'Cyberpunk', 'Classic', 'Monochrome', 'Custom')]
        [string]$ThemeName,
        
        [hashtable]$CustomColors = @{}
    )
    
    if (-not $script:UIConfig) {
        throw "Configuration not initialized. Call Initialize-UIConfig first."
    }
    
    if ($ThemeName -eq 'Custom') {
        if ($CustomColors.Count -eq 0) {
            throw "CustomColors parameter required when using Custom theme"
        }
        
        # Create custom theme with defaults for missing colors
        $defaultColors = $script:UIConfig.UILibrary.ColorScheme.Default
        $customTheme = @{}
        
        foreach ($colorType in @('Primary', 'Secondary', 'Success', 'Warning', 'Error', 'Info', 'Muted', 'Highlight')) {
            if ($CustomColors.ContainsKey($colorType)) {
                $customTheme[$colorType] = $CustomColors[$colorType]
            } else {
                $customTheme[$colorType] = $defaultColors[$colorType]
            }
        }
        
        $script:UIConfig.UILibrary.ColorScheme['Custom'] = $customTheme
    } elseif (-not $script:UIConfig.UILibrary.ColorScheme.ContainsKey($ThemeName)) {
        $available = $script:UIConfig.UILibrary.ColorScheme.Keys -join ', '
        throw "Theme '$ThemeName' not found. Available themes: $available"
    }
    
    $script:UIConfig.UILibrary.ActiveTheme = $ThemeName
    Write-Verbose "Active theme changed to: $ThemeName"
}

function Get-ConsoleTheme {
    <#
    .SYNOPSIS
        Gets the current active theme name.
    
    .DESCRIPTION
        Returns the name of the currently active theme.
    
    .EXAMPLE
        Get-ConsoleTheme
        
        Returns "Default" (or current active theme).
    #>
    [CmdletBinding()]
    param()
    
    if (-not $script:UIConfig) {
        Write-Warning "Configuration not initialized"
        return $null
    }
    
    return $script:UIConfig.UILibrary.ActiveTheme
}

function Get-AvailableThemes {
    <#
    .SYNOPSIS
        Gets list of available themes.
    
    .DESCRIPTION
        Returns an array of all available theme names.
    
    .EXAMPLE
        Get-AvailableThemes
        
        Returns @("Default", "Cyberpunk", "Classic", "Monochrome")
    #>
    [CmdletBinding()]
    param()
    
    if (-not $script:UIConfig) {
        Write-Warning "Configuration not initialized"
        return @()
    }
    
    return @($script:UIConfig.UILibrary.ColorScheme.Keys)
}

# Export functions
Export-ModuleMember -Function Initialize-UIConfig, Get-UIConfig, Get-UIColor, Get-UIIcon, Set-ConsoleTheme, Get-ConsoleTheme, Get-AvailableThemes
