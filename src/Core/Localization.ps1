<#
.SYNOPSIS
    PSConsoleUI Localization System
    
.DESCRIPTION
    Provides internationalization (i18n) support for the UI framework.
    Loads locale-specific resource files and provides string lookup.
#>

# Module-level variables
$script:LocaleResources = @{}
$script:ActiveLocale = $null
$script:FallbackLocale = 'en-US'

function Initialize-Localization {
    <#
    .SYNOPSIS
        Initializes the localization system.
    
    .DESCRIPTION
        Loads locale resource files and sets the active locale based on system culture.
    
    .PARAMETER LocalePath
        Optional path to the locales directory. Defaults to config/locales relative to module root.
    
    .PARAMETER DefaultLocale
        Optional default locale to use. If not specified, uses system culture.
    
    .EXAMPLE
        Initialize-Localization
        
        Initializes localization with system default locale.
    #>
    [CmdletBinding()]
    param(
        [string]$LocalePath = $null,
        [string]$DefaultLocale = $null
    )
    
    # Determine locale path
    if (-not $LocalePath) {
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $LocalePath = Join-Path $moduleRoot 'config\locales'
    }
    
    # Determine active locale
    if ($DefaultLocale) {
        $script:ActiveLocale = $DefaultLocale
    } else {
        try {
            $script:ActiveLocale = (Get-Culture).Name
        } catch {
            $script:ActiveLocale = $script:FallbackLocale
        }
    }
    
    # Load all available locale files
    if (Test-Path $LocalePath) {
        $localeFiles = Get-ChildItem -Path $LocalePath -Filter '*.json'
        foreach ($file in $localeFiles) {
            $localeName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            try {
                $content = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                $script:LocaleResources[$localeName] = $content
                Write-Verbose "Loaded locale: $localeName"
            } catch {
                Write-Warning "Failed to load locale file: $($file.Name) - $_"
            }
        }
    } else {
        Write-Warning "Locale path not found: $LocalePath"
    }
    
    # Verify active locale is available, fallback if not
    if (-not $script:LocaleResources.ContainsKey($script:ActiveLocale)) {
        Write-Verbose "Active locale '$script:ActiveLocale' not found, using fallback '$script:FallbackLocale'"
        $script:ActiveLocale = $script:FallbackLocale
    }
    
    Write-Verbose "Localization initialized. Active locale: $script:ActiveLocale"
}

function Get-LocalizedString {
    <#
    .SYNOPSIS
        Retrieves a localized string by key path.
    
    .DESCRIPTION
        Looks up a localized string using dot-notation key path (e.g., "Menu.SelectPrompt").
        Falls back to default locale if key not found in active locale.
    
    .PARAMETER Key
        The key path to the localized string (e.g., "Menu.ExitPrompt").
    
    .PARAMETER Locale
        Optional locale to use instead of active locale.
    
    .PARAMETER DefaultValue
        Optional default value to return if key not found.
    
    .EXAMPLE
        Get-LocalizedString -Key "Menu.SelectPrompt"
        
        Returns "Select an option" (in active locale).
    
    .EXAMPLE
        Get-LocalizedString -Key "Menu.SelectPrompt" -Locale "es-ES"
        
        Returns "Selecciona una opción".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,
        
        [string]$Locale = $null,
        
        [string]$DefaultValue = ''
    )
    
    # Use specified locale or active locale
    $targetLocale = if ($Locale) { $Locale } else { $script:ActiveLocale }
    
    # Get resource for target locale
    $resource = $script:LocaleResources[$targetLocale]
    
    # If not found, try fallback locale
    if (-not $resource -and $targetLocale -ne $script:FallbackLocale) {
        Write-Verbose "Locale '$targetLocale' not found, using fallback"
        $resource = $script:LocaleResources[$script:FallbackLocale]
        $targetLocale = $script:FallbackLocale
    }
    
    # If still not found, return default value
    if (-not $resource) {
        Write-Warning "No locale resources available"
        return $DefaultValue
    }
    
    # Navigate nested keys (e.g., "Menu.SelectPrompt" -> Menu -> SelectPrompt)
    $keys = $Key -split '\.'
    $value = $resource
    
    foreach ($k in $keys) {
        if ($value -is [PSCustomObject] -and (Get-Member -InputObject $value -Name $k -MemberType NoteProperty)) {
            $value = $value.$k
        } else {
            Write-Verbose "Key '$Key' not found in locale '$targetLocale'"
            # Try fallback locale if we haven't already
            if ($targetLocale -ne $script:FallbackLocale) {
                return Get-LocalizedString -Key $Key -Locale $script:FallbackLocale -DefaultValue $DefaultValue
            }
            return $DefaultValue
        }
    }
    
    return $value
}

function Set-UILocale {
    <#
    .SYNOPSIS
        Changes the active UI locale.
    
    .DESCRIPTION
        Sets the active locale for the UI framework. The locale must be available
        (have a corresponding JSON file loaded).
    
    .PARAMETER Locale
        The locale code to activate (e.g., "en-US", "es-ES", "fr-FR").
    
    .EXAMPLE
        Set-UILocale -Locale "es-ES"
        
        Changes UI language to Spanish.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Locale
    )
    
    if ($script:LocaleResources.ContainsKey($Locale)) {
        $script:ActiveLocale = $Locale
        Write-Verbose "Active locale changed to: $Locale"
    } else {
        $available = $script:LocaleResources.Keys -join ', '
        throw "Locale '$Locale' not available. Available locales: $available"
    }
}

function Get-UILocale {
    <#
    .SYNOPSIS
        Gets the current active UI locale.
    
    .DESCRIPTION
        Returns the currently active locale code.
    
    .EXAMPLE
        Get-UILocale
        
        Returns "en-US" (or current active locale).
    #>
    [CmdletBinding()]
    param()
    
    return $script:ActiveLocale
}

function Get-AvailableLocales {
    <#
    .SYNOPSIS
        Gets list of available locales.
    
    .DESCRIPTION
        Returns an array of all loaded locale codes.
    
    .EXAMPLE
        Get-AvailableLocales
        
        Returns @("en-US", "es-ES", "fr-FR")
    #>
    [CmdletBinding()]
    param()
    
    return @($script:LocaleResources.Keys)
}

# Export functions
Export-ModuleMember -Function Initialize-Localization, Get-LocalizedString, Set-UILocale, Get-UILocale, Get-AvailableLocales
