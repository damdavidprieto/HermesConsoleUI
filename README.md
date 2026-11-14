# HermesConsoleUI

> **The Messenger of Your Terminal** - Professional PowerShell Console UI Framework

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.0.1-orange.svg)](https://github.com/damdavidprieto/HermesConsoleUI/releases)

A zero-dependency, highly configurable UI framework for building beautiful PowerShell console applications with internationalization support.

> **Note:** Test suite in development. Core functionality is stable and production-ready with 40 fully documented functions.

---

## 🚀 Quick Start

```powershell
# Import the module
Import-Module .\HermesConsoleUI.psd1

# Use components
Write-ConsoleStatus -Message "Hello World!" -Type "Success"
Write-ConsoleChart -Label "Progress" -Value 75 -Max 100

# Change theme
Set-ConsoleTheme -ThemeName "Cyberpunk"

# Change language
Set-UILocale -Locale "es-ES"
```

---

## ✨ Features

- ✅ **29 UI Components** - Text, visual, and interactive elements
- ✅ **4 Color Themes** - Default, Cyberpunk, Classic, Monochrome + Custom
- ✅ **Internationalization (i18n)** - Multi-language support (EN, ES, FR)
- ✅ **Dynamic Configuration** - Runtime theme and locale switching
- ✅ **Fully Configurable** - Customize via `config/ui_config.json`
- ✅ **PS v2+ Compatible** - Works on legacy Windows systems
- ✅ **Zero Dependencies** - Pure PowerShell, no external modules
- ✅ **Comprehensive Tests** - Full Pester test suite included
- ✅ **Production Ready** - Battle-tested in real-world applications

---

## 📁 Structure

```
HermesConsoleUI/
├── HermesConsoleUI.psm1      # ⭐ Main module file
├── HermesConsoleUI.psd1      # Module manifest
├── build.ps1                 # Analysis, tests and package build (output/HermesConsoleUI)
├── README.md                 # This file
│
├── src/                      # Core: constants, validators, configuration, i18n
├── modules/                  # UI components (text, visual, interactive, layout)
│
├── config/                   # Configuration
│   ├── ui_config.json       # Themes and component defaults
│   └── locales/             # Language resources
│       ├── en-US.json       # English
│       ├── es-ES.json       # Spanish
│       └── fr-FR.json       # French
│
├── docs/                     # Documentation
│   ├── README.md            # Documentation index
│   ├── en/                  # English documentation
│   └── es/                  # Spanish documentation
│
├── examples/                # Usage examples
│   ├── DEMO_TOTAL_AUTOMATICO_V2.ps1  # ⭐ Main comprehensive demo
│   ├── DEMO_SIMPLE.ps1               # Quick start demo
│   ├── DEMO_COMPLETO_INTERACTIVO.ps1 # Interactive demo
│   ├── 01_basic_usage.ps1
│   ├── 02_interactive_menu.ps1
│   ├── 03_data_visualization.ps1
│   └── 04_complete_application.ps1
│
└── tests/                   # Pester test suite
    └── ui_components.tests.ps1
```

---

## 📚 Documentation

- **[Documentation index](docs/README.md)** (English and Spanish)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details

---

## 🔧 Installation

### Option 1: PowerShell Gallery (Recommended)
```powershell
Install-Module -Name HermesConsoleUI -Scope CurrentUser
```

The module auto-loads the first time you call one of its commands; `Import-Module` is optional.
It requires Windows PowerShell 5.1 or PowerShell 7+. On a fresh Windows PowerShell 5.1 install,
update PowerShellGet first (`Install-Module PowerShellGet -Force -Scope CurrentUser`) and accept
the NuGet provider prompt.

Package page: [HermesConsoleUI on the PowerShell Gallery](https://www.powershellgallery.com/packages/HermesConsoleUI)

### Option 2: From source
```powershell
git clone https://github.com/damdavidprieto/HermesConsoleUI.git
cd HermesConsoleUI

# Use it without installing
Import-Module .\HermesConsoleUI.psd1

# Or build the package (only the runtime files) and import that
.\build.ps1 -SkipAnalysis -SkipTests
Import-Module .\output\HermesConsoleUI\HermesConsoleUI.psd1
```

To install a build from source, copy `output\HermesConsoleUI` into a folder listed in
`$env:PSModulePath`. Do not copy the repository root: it contains `.git`, tests and docs.

---

## 🎨 Components Overview

### Text Components (11)
- `Write-ConsoleTitle` - Centered titles with borders
- `Write-ConsoleHeader` - Section headers
- `Write-ConsoleSubtitle` - Subsection titles with optional counts
- `Write-ConsoleStatus` - Status messages with icons (Success, Warning, Error, Info)
- `Write-ConsoleError` - Error messages
- `Write-ConsoleInfo` - Information messages
- `Write-ConsoleMetadata` - Key-value metadata display
- `Write-ConsoleSummary` - Summary sections with items
- `Write-ConsoleDiff` - Before/after comparisons
- `Write-ConsoleSeparator` - Horizontal separator lines
- `Write-ConsoleBreadcrumb` - Breadcrumb navigation

### Visual Components (7)
- `Write-ConsoleBox` - Bordered message boxes
- `Write-ConsoleChart` - Progress bar charts
- `Write-ConsoleTree` - Hierarchical tree structures
- `Write-ConsoleTable` - Formatted tables with color mapping and word wrap
- `Show-ConsoleList` - Formatted lists with bullets
- `Write-ConsoleSparkline` - Inline mini-charts for trends
- `Write-ConsolePanel` - Bordered panels with customizable styles

### Interactive Components (10)
- `Show-ConsoleMenu` - Display interactive menus
- `Read-ConsoleChoice` - Read user menu selection
- `Read-ConsoleMultiChoice` - Read multiple selections
- `Invoke-ConsoleMenu` - Complete menu system with actions
- `Read-ConsoleInput` - User input with defaults
- `Read-ConsoleConfirmation` - Yes/No prompts
- `Invoke-ConsoleSpinner` - Long-running operations with spinner
- `Write-ConsoleProgress` - Progress bars
- `Read-ConsolePassword` - Secure password input
- `Show-ConsoleNotification` - Temporary notifications

### Core Functions (12)
- `Initialize-UIConfig` - Initialize configuration system
- `Get-UIConfig` - Get configuration values
- `Get-UIColor` - Get color from active theme
- `Get-UIIcon` - Get icon from configuration
- `Set-ConsoleTheme` - Change active theme
- `Get-ConsoleTheme` - Get current theme
- `Get-AvailableThemes` - List available themes
- `Initialize-Localization` - Initialize i18n system
- `Get-LocalizedString` - Retrieve localized strings
- `Set-UILocale` - Change active language
- `Get-UILocale` - Get current locale
- `Get-AvailableLocales` - List available locales

---

## 🌍 Internationalization

HermesConsoleUI supports multiple languages out of the box:

```powershell
# Change to Spanish
Set-UILocale -Locale "es-ES"

# Change to French
Set-UILocale -Locale "fr-FR"

# Check available locales
Get-AvailableLocales  # Returns: en-US, es-ES, fr-FR
```

---

## 🎭 Themes

Switch between built-in themes or create custom ones:

```powershell
# Use built-in themes
Set-ConsoleTheme -ThemeName "Cyberpunk"
Set-ConsoleTheme -ThemeName "Classic"
Set-ConsoleTheme -ThemeName "Monochrome"

# Create custom theme
Set-ConsoleTheme -ThemeName "Custom" -CustomColors @{
    Primary = "DarkCyan"
    Success = "DarkGreen"
    Warning = "DarkYellow"
    Error = "DarkRed"
}

# Check available themes
Get-AvailableThemes
```

---

## 🧪 Testing

```powershell
# Run all tests
Invoke-Pester -Path ".\tests\ui_components.tests.ps1"

# Run specific test
Invoke-Pester -Path ".\tests\ui_components.tests.ps1" -TestName "Write-ConsoleStatus"
```

---

## 🛠️ Build & Development

`build.ps1` runs PSScriptAnalyzer and the Pester tests, then copies only the files the module
needs at runtime into `output/HermesConsoleUI`. That folder is what gets installed or published;
the repository root (tests, docs, examples, `.git`) never is.

```powershell
# Install dependencies (Pester 5, PSScriptAnalyzer) before the first run
.\build.ps1 -InstallDependencies

# Analysis + tests + build
.\build.ps1

# Try the built module
Import-Module .\output\HermesConsoleUI\HermesConsoleUI.psd1 -Force
```

Releases are published by the `Publish` workflow when a `v*` tag is pushed. It builds the module
and runs `Publish-Module -Path ./output/HermesConsoleUI` with the `PSGALLERY_API_KEY` secret.

---

## 📦 Package Information

- **Name**: HermesConsoleUI
- **Version**: 2.2.0
- **Author**: David Prieto
- **License**: MIT
- **PowerShell**: Windows PowerShell 5.1, PowerShell 7+
- **Platform**: Windows

---

## 🔄 Migration from CassielUI

If you're migrating from CassielUI v1.x, simply replace function names:

```powershell
# Old (PSConsoleUI / CassielUI)
Write-CassielStatus -Message "Done" -Type "Success"
Show-CassielMenu -Title "Menu" -Options @("Opt1", "Opt2")

# New (HermesConsoleUI)
Write-ConsoleStatus -Message "Done" -Type "Success"
Show-ConsoleMenu -Title "Menu" -Options @("Opt1", "Opt2")
```

---

## 🤝 Contributing

Contributions are welcome! Please submit issues and pull requests on GitHub.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🔗 Links

- **Documentation**: [docs/README.md](docs/README.md)
- **Examples**: [examples/](examples/)
- **Tests**: [tests/](tests/)
- **GitHub**: https://github.com/damdavidprieto/HermesConsoleUI

---

**Built with ❤️ for the PowerShell Community**

