@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'HermesConsoleUI.psm1'

    # Version number of this module.
    ModuleVersion     = '2.2.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID              = 'a7f3e8d2-4c91-4b5a-9e7f-2d8c3a1b6e4f'

    # Author of this module
    Author            = 'HermesConsoleUI Project'

    # Company or vendor of this module
    CompanyName       = 'Open Source'

    # Copyright statement for this module
    Copyright         = '(c) 2026 HermesConsoleUI Project. Licensed under the MIT License.'

    # Description of the functionality provided by this module
    Description       = 'Professional PowerShell Console UI Framework - A comprehensive, zero-dependency toolkit for building beautiful terminal applications. Text, visual, interactive and layout components with themes and internationalization (i18n). Works on Windows PowerShell 5.1 and PowerShell 7+.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        # Core Configuration & Localization
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
        'Get-AvailableLocales',
        
        # Text Components
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
        
        # Visual Components
        'Write-ConsoleBox',
        'Write-ConsoleChart',
        'Write-ConsoleTree',
        'Write-ConsoleTable',
        'Show-ConsoleList',
        'Write-ConsoleSparkline',
        'Write-ConsolePanel',
        
        # Interactive Components
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
        'New-ConsoleLayout',
        'New-ConsoleRow',
        'New-ConsoleColumn',
        'Write-ConsoleLayout'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()


    # Private data
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module.
            Tags         = @('UI', 'Console', 'Terminal', 'PowerShell', 'TUI', 'CLI', 'Menu', 'Table', 'Chart', 'Interactive', 'Theme', 'i18n', 'Localization', 'Framework', 'PSEdition_Desktop', 'PSEdition_Core')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/damdavidprieto/HermesConsoleUI/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/damdavidprieto/HermesConsoleUI'

            # ReleaseNotes of this module
            ReleaseNotes = @'
# 2.2.0

- Requires Windows PowerShell 5.1 or PowerShell 7+ (was declared as 2.0).
- Fixed loading on Windows PowerShell 5.1: source files are now UTF-8 with BOM, so
  the configuration system parses correctly and themes work again.
- Exports exactly the public functions (removed a duplicate entry and two Windows
  integration functions that were never loaded).
- The package now contains only the module files.

Full changelog: https://github.com/damdavidprieto/HermesConsoleUI/blob/main/docs/en/reference/CHANGELOG.md
'@
        }
    }
}
