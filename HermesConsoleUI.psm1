# HermesConsoleUI - console UI components for PowerShell.
#
# Loads the configuration and localization systems, then the components.
# Requires Windows PowerShell 5.1 or PowerShell 7+.
#
# License: MIT

$ModuleRoot = $PSScriptRoot

# Core systems
. "$ModuleRoot\src\Core\Config.ps1"
. "$ModuleRoot\src\Core\Localization.ps1"

# Components
. "$ModuleRoot\modules\helpers.ps1"
. "$ModuleRoot\modules\text_components.ps1"
. "$ModuleRoot\modules\visual_components.ps1"
. "$ModuleRoot\modules\interactive_components.ps1"
. "$ModuleRoot\modules\layout_components.ps1"

Initialize-UIConfig -ConfigPath "$ModuleRoot\config\ui_config.json"
Initialize-Localization -LocalePath "$ModuleRoot\config\locales"

# Plural names from 2.1 and earlier, kept so existing scripts keep working.
New-Alias -Name Get-AvailableThemes -Value Get-AvailableTheme
New-Alias -Name Get-AvailableLocales -Value Get-AvailableLocale

# Keep these lists in sync with FunctionsToExport and AliasesToExport in HermesConsoleUI.psd1
# (tests/Unit/Manifest.Tests.ps1 checks it).
Export-ModuleMember -Alias 'Get-AvailableThemes', 'Get-AvailableLocales' -Function @(
    # Configuration and localization
    'Initialize-UIConfig', 'Get-UIConfig', 'Get-UIColor', 'Get-UIIcon',
    'Set-ConsoleTheme', 'Get-ConsoleTheme', 'Get-AvailableTheme',
    'Initialize-Localization', 'Get-LocalizedString', 'Set-UILocale', 'Get-UILocale', 'Get-AvailableLocale',

    # Text components
    'Write-ConsoleTitle', 'Write-ConsoleHeader', 'Write-ConsoleSubtitle', 'Write-ConsoleError',
    'Write-ConsoleInfo', 'Write-ConsoleStatus', 'Write-ConsoleMetadata', 'Write-ConsoleSummary',
    'Write-ConsoleDiff', 'Write-ConsoleSeparator', 'Write-ConsoleBreadcrumb',

    # Visual components
    'Write-ConsoleBox', 'Write-ConsoleChart', 'Write-ConsoleTree', 'Write-ConsoleTable',
    'Show-ConsoleList', 'Write-ConsoleSparkline', 'Write-ConsolePanel',

    # Interactive components
    'Show-ConsoleMenu', 'Read-ConsoleChoice', 'Read-ConsoleMultiChoice', 'Invoke-ConsoleMenu',
    'Invoke-ConsoleSpinner', 'Write-ConsoleProgress', 'Show-ConsoleProgress', 'Read-ConsoleInput',
    'Read-ConsoleConfirmation', 'Read-ConsolePassword', 'Show-ConsoleNotification',

    # Layout components
    'New-ConsoleLayout', 'New-ConsoleRow', 'New-ConsoleColumn', 'Write-ConsoleLayout'
)
