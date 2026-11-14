@{
    RootModule           = 'HermesConsoleUI.psm1'
    ModuleVersion        = '2.2.0'
    CompatiblePSEditions = @('Desktop', 'Core')
    GUID                 = 'a7f3e8d2-4c91-4b5a-9e7f-2d8c3a1b6e4f'
    Author               = 'David Prieto'
    CompanyName          = 'David Prieto'
    Copyright            = '(c) 2026 David Prieto. Licensed under the MIT License.'
    Description          = 'Console UI components for PowerShell scripts: titles, status messages, tables, lists, trees, charts, panels, menus, prompts and side-by-side layouts, with color themes and localized prompts (en-US, es-ES, fr-FR). No dependencies. Windows PowerShell 5.1 and PowerShell 7+.'
    PowerShellVersion    = '5.1'

    # Keep in sync with Export-ModuleMember in HermesConsoleUI.psm1 (tests/Unit/Manifest.Tests.ps1 checks it).
    FunctionsToExport    = @(
        # Configuration and localization
        'Initialize-UIConfig'
        'Get-UIConfig'
        'Get-UIColor'
        'Get-UIIcon'
        'Set-ConsoleTheme'
        'Get-ConsoleTheme'
        'Get-AvailableTheme'
        'Initialize-Localization'
        'Get-LocalizedString'
        'Set-UILocale'
        'Get-UILocale'
        'Get-AvailableLocale'

        # Text components
        'Write-ConsoleTitle'
        'Write-ConsoleHeader'
        'Write-ConsoleSubtitle'
        'Write-ConsoleError'
        'Write-ConsoleInfo'
        'Write-ConsoleStatus'
        'Write-ConsoleMetadata'
        'Write-ConsoleSummary'
        'Write-ConsoleDiff'
        'Write-ConsoleSeparator'
        'Write-ConsoleBreadcrumb'

        # Visual components
        'Write-ConsoleBox'
        'Write-ConsoleChart'
        'Write-ConsoleTree'
        'Write-ConsoleTable'
        'Show-ConsoleList'
        'Write-ConsoleSparkline'
        'Write-ConsolePanel'

        # Interactive components
        'Show-ConsoleMenu'
        'Read-ConsoleChoice'
        'Read-ConsoleMultiChoice'
        'Invoke-ConsoleMenu'
        'Invoke-ConsoleSpinner'
        'Write-ConsoleProgress'
        'Show-ConsoleProgress'
        'Read-ConsoleInput'
        'Read-ConsoleConfirmation'
        'Read-ConsolePassword'
        'Show-ConsoleNotification'

        # Layout components
        'New-ConsoleLayout'
        'New-ConsoleRow'
        'New-ConsoleColumn'
        'Write-ConsoleLayout'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    # Plural names from 2.1 and earlier, kept so existing scripts keep working.
    AliasesToExport      = @('Get-AvailableThemes', 'Get-AvailableLocales')

    PrivateData          = @{
        PSData = @{
            Tags         = @('UI', 'Console', 'Terminal', 'TUI', 'CLI', 'Menu', 'Table', 'Chart', 'Theme', 'Localization', 'Windows', 'Linux', 'MacOS', 'PSEdition_Desktop', 'PSEdition_Core')
            LicenseUri   = 'https://github.com/damdavidprieto/HermesConsoleUI/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/damdavidprieto/HermesConsoleUI'
            ReleaseNotes = 'See https://github.com/damdavidprieto/HermesConsoleUI/blob/main/CHANGELOG.md'
        }
    }
}
