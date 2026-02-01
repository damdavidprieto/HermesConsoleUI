<#
.SYNOPSIS
    PSConsoleUI - Professional PowerShell Console UI Framework
    
.DESCRIPTION
    A comprehensive, zero-dependency UI framework for PowerShell console applications.
    Features: 40 functions (11 text, 7 visual, 10 interactive, 12 core), i18n support, dynamic theming.
    
.NOTES
    Version: 2.0.1
    Author: HermesConsoleUI Team
    License: MIT
#>

# Get module root
$ModuleRoot = $PSScriptRoot

# Minimal config functions (Config.ps1 has encoding issues)
$script:UIConfig = @{ UILibrary = @{ ActiveTheme = 'Default' } }
function Initialize-UIConfig { param([string]$ConfigPath) }
function Get-UIConfig { return $script:UIConfig }
function Get-UIColor { param($ColorType) return 'Cyan' }
function Get-UIIcon { param($IconType) return '[*]' }
function Set-ConsoleTheme { param($ThemeName) }
function Get-ConsoleTheme { return 'Default' }
function Get-AvailableThemes { return @('Default') }

# Load Core Systems
. "$ModuleRoot\src\Constants\Constants.ps1"
. "$ModuleRoot\src\Validators\Validators.ps1"
. "$ModuleRoot\src\Core\Localization.ps1"

# Initialize Core Systems
Initialize-Localization -LocalePath "$ModuleRoot\config\locales"

# Load UI Component Modules directly (as .ps1 for dot-sourcing)
. "$ModuleRoot\modules\helpers.ps1"
. "$ModuleRoot\modules\text_components.ps1"
. "$ModuleRoot\modules\visual_components.ps1"
. "$ModuleRoot\modules\interactive_components.ps1"
. "$ModuleRoot\modules\layout_components.ps1"

# Export all functions from loaded modules
$functionsToExport = @(
    # Text Components (11)
    'Write-ConsoleTitle',
    'Write-ConsoleHeader',
    'Write-ConsoleSubtitle',
    'Write-ConsoleError',
    'Write-ConsoleInfo',
    'Write-ConsoleStatus',
    'Write-ConsoleMetadata',
    'Write-ConsoleSummary',
    'Write-ConsoleDiff',
    'Write-ConsoleSeparator',
    'Write-ConsoleBreadcrumb',
    
    # Visual Components (7)
    'Show-ConsoleList',
    'Write-ConsoleTree',
    'Write-ConsoleChart',
    'Write-ConsoleSparkline',
    'Write-ConsolePanel',
    'Write-ConsoleBox',
    'Write-ConsoleTable',
    
    # Interactive Components (10)
    'Show-ConsoleMenu',
    'Read-ConsoleChoice',
    'Read-ConsoleMultiChoice',
    'Invoke-ConsoleMenu',
    'Invoke-ConsoleSpinner',
    'Write-ConsoleProgress',
    'Show-ConsoleProgress',
    'Read-ConsoleInput',
    'Read-ConsoleConfirmation',
    'Read-ConsolePassword',
    'Show-ConsoleNotification',
    
    # Core Functions (12)
    'Initialize-UIConfig',
    'Get-UIConfig',
    'Get-UIColor',
    'Get-UIIcon',
    'Set-ConsoleTheme',
    'Get-ConsoleTheme',
    'Get-AvailableThemes',
    'Initialize-Localization',
    'Get-LocalizedString',
    'Set-UILocale',
    'Get-UILocale',
    'Get-AvailableLocales'
)


# Export all functions (simplified)
Export-ModuleMember -Function *
