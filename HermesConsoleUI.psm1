<#
.SYNOPSIS
    HermesConsoleUI - PowerShell console UI framework.

.DESCRIPTION
    Zero-dependency toolkit for building terminal applications: text, visual,
    interactive and layout components, with themes and localization.
    Requires Windows PowerShell 5.1 or PowerShell 7+.

.NOTES
    License: MIT
#>

$ModuleRoot = $PSScriptRoot

# Core systems
. "$ModuleRoot\src\Constants\Constants.ps1"
. "$ModuleRoot\src\Validators\Validators.ps1"
. "$ModuleRoot\src\Core\Config.ps1"
. "$ModuleRoot\src\Core\Localization.ps1"

Initialize-UIConfig -ConfigPath "$ModuleRoot\config\ui_config.json"
Initialize-Localization -LocalePath "$ModuleRoot\config\locales"

# UI components
. "$ModuleRoot\modules\helpers.ps1"
. "$ModuleRoot\modules\text_components.ps1"
. "$ModuleRoot\modules\visual_components.ps1"
. "$ModuleRoot\modules\interactive_components.ps1"
. "$ModuleRoot\modules\layout_components.ps1"

# Keep this list in sync with FunctionsToExport in HermesConsoleUI.psd1
# (tests/Unit/Manifest.Tests.ps1 checks it).
Export-ModuleMember -Function @(
    # Configuration and localization
    'Initialize-UIConfig', 'Get-UIConfig', 'Get-UIColor', 'Get-UIIcon',
    'Set-ConsoleTheme', 'Get-ConsoleTheme', 'Get-AvailableThemes',
    'Initialize-Localization', 'Get-LocalizedString', 'Set-UILocale', 'Get-UILocale', 'Get-AvailableLocales',

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
