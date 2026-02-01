@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'HermesConsoleUI.psm1'

    # Version number of this module.
    ModuleVersion     = '2.0.1'

    # Supported PSEditions
    # CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID              = 'a7f3e8d2-4c91-4b5a-9e7f-2d8c3a1b6e4f'

    # Author of this module
    Author            = 'HermesConsoleUI Project'

    # Company or vendor of this module
    CompanyName       = 'Open Source'

    # Copyright statement for this module
    Copyright         = '(c) 2026 HermesConsoleUI Project. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Professional PowerShell Console UI Framework - A comprehensive, zero-dependency toolkit for building beautiful terminal applications. Includes 40 functions (11 text, 7 visual, 10 interactive, 12 core) with full theme support, internationalization (i18n), and PowerShell 2.0+ compatibility.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '2.0'

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
        'New-ConsoleColumn',
        'Write-ConsoleLayout',
        
        # Windows Integration
        'Set-TaskbarProgress',
        'Show-WindowsNotification'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    # List of all files packaged with this module
    FileList          = @(
        'HermesConsoleUI.psm1',
        'HermesConsoleUI.psd1',
        'modules\helpers.ps1',
        'modules\text_components.ps1',
        'modules\visual_components.ps1',
        'modules\interactive_components.ps1',
        'modules\layout_components.ps1',
        'modules\windows_integration.ps1',
        'Install.ps1',
        'README.md',
        'LICENSE',
        'src\Constants\Constants.ps1',
        'src\Core\Localization.ps1',
        'src\Validators\Validators.ps1',
        'config\ui_config.json',
        'config\locales\en-US.json',
        'config\locales\es-ES.json',
        'config\locales\fr-FR.json',
        'docs\README.md'
    )

    # Private data
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module.
            Tags         = @('UI', 'Console', 'Terminal', 'PowerShell', 'TUI', 'CLI', 'Menu', 'Table', 'Chart', 'Interactive', 'Theme', 'i18n', 'Localization', 'PSv2', 'Framework')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/damdavidprieto/HermesConsoleUI/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/damdavidprieto/HermesConsoleUI'

            # ReleaseNotes of this module
            ReleaseNotes = @'
# Release Notes - v2.0.1

## Branding Update
- Rebranded to HermesConsoleUI

## Bug Fixes
- Fixed visual rendering artifacts in PowerShell ISE (color bleeding, column misalignment)
- Fixed "Rainbow Text" issues by sanitizing file encodings
- Removed double brackets in demo output
- Updated Show-ConsoleProgress to use ASCII characters for better compatibility

## New Features
- Improved Install.ps1 check and installation process
- Updated documentation and roadmap
'@
        }
    }
}
