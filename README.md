# HermesConsoleUI

[![CI](https://github.com/damdavidprieto/HermesConsoleUI/actions/workflows/ci.yml/badge.svg)](https://github.com/damdavidprieto/HermesConsoleUI/actions/workflows/ci.yml)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/HermesConsoleUI.svg)](https://www.powershellgallery.com/packages/HermesConsoleUI)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Console UI components for PowerShell scripts: titles, status messages, tables, lists, trees,
charts, panels, menus, prompts and side-by-side layouts, with color themes and localized prompts.

- Windows PowerShell 5.1 and PowerShell 7+ (Windows, Linux, macOS). No dependencies.
- Every component follows the active color theme; an explicit `-Color` always wins.
- Prompts in English, Spanish and French (`Set-UILocale`).
- Text from your data is written safely: terminal escape sequences are removed before display.
- Every command has full help: `Get-Help Write-ConsoleTable -Full`.

## Installation

```powershell
Install-Module -Name HermesConsoleUI -Scope CurrentUser
```

The module loads automatically the first time you call one of its commands. On a fresh Windows
PowerShell 5.1, update PowerShellGet first (`Install-Module PowerShellGet -Force -Scope CurrentUser`)
and accept the NuGet provider prompt.

## Quick start

```powershell
Write-ConsoleTitle -Title 'Deployment report'
Write-ConsoleStatus -Message 'Configuration loaded' -Type Success
Write-ConsoleStatus -Message 'Certificate expires in 20 days' -Type Warning

Get-Service | Select-Object -First 5 | Write-ConsoleTable -Columns @(
    @{ Header = 'Name'; Property = 'Name'; Width = 25 }
    @{ Header = 'Status'; Property = 'Status'; Width = 10 }
) -ColorMapProperty Status -ColorMap @{ Running = 'Green'; Stopped = 'Red' }

$choice = Show-ConsoleMenu -Title 'Main menu' -Options 'Audit', 'Repair' -ReturnIndex
```

More in [`examples/`](examples/): text, data display, layouts, themes and locales, and an
interactive menu. Each example runs as part of the tests.

## Commands

| Area | Commands |
|---|---|
| Text | `Write-ConsoleTitle`, `Write-ConsoleHeader`, `Write-ConsoleSubtitle`, `Write-ConsoleStatus`, `Write-ConsoleInfo`, `Write-ConsoleError`, `Write-ConsoleMetadata`, `Write-ConsoleSummary`, `Write-ConsoleDiff`, `Write-ConsoleSeparator`, `Write-ConsoleBreadcrumb` |
| Data | `Write-ConsoleTable`, `Show-ConsoleList`, `Write-ConsoleTree`, `Write-ConsoleChart`, `Write-ConsoleSparkline`, `Write-ConsoleBox`, `Write-ConsolePanel` |
| Interaction | `Show-ConsoleMenu`, `Read-ConsoleChoice`, `Invoke-ConsoleMenu`, `Read-ConsoleMultiChoice`, `Read-ConsoleInput`, `Read-ConsoleConfirmation`, `Read-ConsolePassword`, `Invoke-ConsoleSpinner`, `Show-ConsoleProgress`, `Write-ConsoleProgress`, `Show-ConsoleNotification` |
| Layout | `New-ConsoleLayout`, `New-ConsoleRow`, `New-ConsoleColumn`, `Write-ConsoleLayout` |
| Themes | `Set-ConsoleTheme`, `Get-ConsoleTheme`, `Get-AvailableTheme`, `Get-UIColor`, `Get-UIIcon`, `Get-UIConfig`, `Initialize-UIConfig` |
| Localization | `Set-UILocale`, `Get-UILocale`, `Get-AvailableLocale`, `Get-LocalizedString`, `Initialize-Localization` |

`Get-Command -Module HermesConsoleUI` lists them and `Get-Help <command> -Full` documents each one.
Commands that return lines (`Show-ConsoleList`, `Write-ConsoleChart`, `Write-ConsoleBox`) accept
`-ReturnLines`, so their output can go inside a panel or a layout column.

## Themes

```powershell
Get-AvailableTheme                      # Classic, Cyberpunk, Default, Monochrome
Set-ConsoleTheme -ThemeName Cyberpunk   # every component uses the theme colors
Set-ConsoleTheme -ThemeName Custom -CustomColors @{ Primary = 'DarkCyan'; Success = 'DarkGreen' }
```

Themes define eight color roles: Primary, Secondary, Success, Warning, Error, Info, Muted and
Highlight. The built-in themes are in [`config/ui_config.json`](config/ui_config.json).

## Localization

```powershell
Get-AvailableLocale            # en-US, es-ES, fr-FR
Set-UILocale -Locale es-ES     # menus and prompts in Spanish
```

The locale strings are in [`config/locales/`](config/locales/). The locale starts as the system
culture when a file exists for it, and English otherwise.

## Menus and the screen

`Show-ConsoleMenu` clears the screen before drawing. Use `-NoClear` for one menu, or set
`$env:HERMESCONSOLEUI_NOCLEAR = 1` to keep earlier output on screen in every menu, for example
while debugging.

## Security

Components remove ANSI escape sequences and control characters from the text they write, so data
such as file names or log lines cannot restyle the console, overwrite earlier lines or set the
clipboard. Script blocks passed to `Invoke-ConsoleMenu`, `Write-ConsolePanel`, `New-ConsoleColumn`
or `Invoke-ConsoleSpinner` run with your permissions: never build them from untrusted input.
To report a vulnerability, see [SECURITY.md](SECURITY.md).

## Development

```powershell
.\build.ps1 -InstallDependencies   # first time: Pester 5 and PSScriptAnalyzer
.\build.ps1                        # analysis, tests, and the package in output\HermesConsoleUI
```

The repository follows the layout of the [Sampler](https://github.com/gaelcolas/Sampler) module
template: the package is built from the runtime files only, and the QA tests check that every
command has complete help, that the code passes PSScriptAnalyzer with
[`PSScriptAnalyzerSettings.psd1`](PSScriptAnalyzerSettings.psd1) (including Windows PowerShell 5.1
compatibility) and that the changelog is up to date. CI runs on Windows PowerShell 5.1 and on
PowerShell 7 on Windows, Linux and macOS, and installs the package with `Install-Module`.
Pushing a `v*` tag publishes the version to the PowerShell Gallery.

See [CONTRIBUTING](.github/CONTRIBUTING.md), [Architecture](docs/Architecture.md) and the
[CHANGELOG](CHANGELOG.md).

## License

[MIT](LICENSE)
