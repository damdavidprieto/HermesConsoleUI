# HermesConsoleUI configuration: themes, colors and icons.
#
# Manages UI configuration including themes, colors, icons, and component defaults.
# Loads configuration from JSON and provides runtime access and modification.

# Module-level variables
$script:UIConfig = $null

# Built-in settings. A configuration file only needs the settings it changes: it is merged over these, so a
# file without a theme, or a theme without some roles, still works. Every setting here is read by the module.
$script:DefaultConfig = @{
    UILibrary = @{
        ActiveTheme = 'Default'
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
            # Returned by Get-UIIcon.
            Status = @{
                Icons = @{
                    Success = '[+]'
                    Warning = '[!]'
                    Error = '[x]'
                    Info = '[*]'
                }
            }
            # Widest a table column grows on its own (Write-ConsoleTable).
            Table = @{
                MaxColumnWidth = 80
            }
        }
    }
}

function Merge-UIConfigTable {
    <#
    .SYNOPSIS
        Copies Overlay over Base, recursively: nested hashtables are merged, other values replace.
    .DESCRIPTION
        Returns a new hashtable; neither argument is changed.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([hashtable]$Base, [hashtable]$Overlay)

    $result = @{}
    if ($Base) { foreach ($key in $Base.Keys) { $result[$key] = if ($Base[$key] -is [hashtable]) { Merge-UIConfigTable -Base $Base[$key] } else { $Base[$key] } } }
    if ($Overlay) {
        foreach ($key in $Overlay.Keys) {
            $value = $Overlay[$key]
            if ($value -is [hashtable]) { $result[$key] = Merge-UIConfigTable -Base ($result[$key] -as [hashtable]) -Overlay $value }
            else { $result[$key] = $value }
        }
    }
    return $result
}

function Initialize-UIConfig {
    <#
    .SYNOPSIS
        Initializes the UI configuration system.

    .DESCRIPTION
        Loads configuration from JSON file and merges it over the built-in settings, so the file only
        needs what it changes. Falls back to the built-in settings if the file is not found or cannot be read.

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
            # -Encoding UTF8: Windows PowerShell 5.1 reads files without a BOM as ANSI otherwise.
            $configContent = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            # Convert PSCustomObject to hashtable for easier manipulation
            $loaded = ConvertTo-Hashtable -InputObject $configContent
            if ($loaded -isnot [hashtable]) { throw 'The file does not contain a JSON object.' }
            $script:UIConfig = Merge-UIConfigTable -Base $script:DefaultConfig -Overlay $loaded
            Write-Verbose "Configuration loaded from: $ConfigPath"
        } catch {
            Write-Warning "Failed to load configuration from '$ConfigPath': $_"
            Write-Warning "Using default configuration"
            $script:UIConfig = Merge-UIConfigTable -Base $script:DefaultConfig
        }
    } else {
        Write-Verbose "Configuration file not found: $ConfigPath"
        Write-Verbose "Using default configuration"
        # A copy: Set-ConsoleTheme changes the active configuration, never the built-in one.
        $script:UIConfig = Merge-UIConfigTable -Base $script:DefaultConfig
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
    [OutputType([hashtable], [object[]], [object])]
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
        $array = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $InputObject) {
            $array.Add((ConvertTo-Hashtable -InputObject $item))
        }
        return , $array.ToArray()
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
    [OutputType([string])]
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
    if ($colorScheme -is [hashtable] -and $colorScheme.ContainsKey($themeName)) {
        $themeColors = $colorScheme[$themeName]
        if ($themeColors -is [hashtable] -and $themeColors.ContainsKey($ColorType)) {
            return $themeColors[$ColorType]
        }
        # A theme from the configuration file may leave out roles: they come from the Default theme.
        $defaultColors = $colorScheme['Default']
        if ($defaultColors -is [hashtable] -and $defaultColors.ContainsKey($ColorType)) {
            return $defaultColors[$ColorType]
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
    [OutputType([string])]
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
    if ($icons -is [hashtable] -and $icons.ContainsKey($IconType)) {
        return $icons[$IconType]
    }

    return '[*]'
}

function Set-ConsoleTheme {
    <#
    .SYNOPSIS
        Changes the active UI theme.

    .DESCRIPTION
        Sets the active theme for the UI framework. The theme must exist in the configuration:
        the built-in ones are Default, Cyberpunk, Classic and Monochrome, and a theme added to the
        ColorScheme section of ui_config.json can be used by its name too. Custom creates a theme
        from -CustomColors.

    .PARAMETER ThemeName
        The theme name to activate: one of Get-AvailableTheme, or Custom. Tab completion lists them.

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
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete)
                $null = $commandName, $parameterName
                @(Get-AvailableTheme) + 'Custom' | Sort-Object -Unique | Where-Object { $_ -like "$wordToComplete*" }
            })]
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

        foreach ($colorType in $script:HermesColorRoles) {
            if ($CustomColors.ContainsKey($colorType)) {
                $customTheme[$colorType] = $CustomColors[$colorType]
            } else {
                $customTheme[$colorType] = $defaultColors[$colorType]
            }
        }

    } elseif (-not $script:UIConfig.UILibrary.ColorScheme.ContainsKey($ThemeName)) {
        $available = $script:UIConfig.UILibrary.ColorScheme.Keys -join ', '
        throw "Theme '$ThemeName' not found. Available themes: $available"
    }

    if (-not $PSCmdlet.ShouldProcess("theme '$ThemeName'", 'Set active console theme')) { return }

    if ($ThemeName -eq 'Custom') {
        $script:UIConfig.UILibrary.ColorScheme['Custom'] = $customTheme
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
    [OutputType([string])]
    param()

    if (-not $script:UIConfig) {
        Write-Warning "Configuration not initialized"
        return $null
    }

    return $script:UIConfig.UILibrary.ActiveTheme
}

function Get-AvailableTheme {
    <#
    .SYNOPSIS
        Gets list of available themes.

    .DESCRIPTION
        Returns the names of the themes defined in the configuration, which can be passed
        to Set-ConsoleTheme. The old name Get-AvailableThemes still works as an alias.

    .EXAMPLE
        Get-AvailableTheme

        Returns @("Default", "Cyberpunk", "Classic", "Monochrome")
    #>
    [CmdletBinding()]
    [OutputType([string[]], [object[]])]
    param()

    if (-not $script:UIConfig) {
        Write-Warning "Configuration not initialized"
        return @()
    }

    return @($script:UIConfig.UILibrary.ColorScheme.Keys)
}
