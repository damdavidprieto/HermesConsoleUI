# PSConsoleUI Function Map

**Version:** 2.0.1  
**Total Functions:** 40

This document maps each function to its location in the codebase.

---

## 📍 Text Components (11 functions)

| Function | File | Lines | Description |
|----------|------|-------|-------------|
| `Write-ConsoleTitle` | modules/ui_components.psm1 | 11-55 | Centered titles with borders |
| `Write-ConsoleHeader` | modules/ui_components.psm1 | 56-90 | Section headers |
| `Write-ConsoleSubtitle` | modules/ui_components.psm1 | 91-138 | Subsection titles with counts |
| `Write-ConsoleError` | modules/ui_components.psm1 | 139-172 | Error messages |
| `Write-ConsoleInfo` | modules/ui_components.psm1 | 173-212 | Information messages |
| `Write-ConsoleStatus` | modules/ui_components.psm1 | 213-258 | Status messages with icons |
| `Write-ConsoleMetadata` | modules/ui_components.psm1 | 259-304 | Key-value metadata display |
| `Write-ConsoleSummary` | modules/ui_components.psm1 | 305-352 | Summary sections with items |
| `Write-ConsoleDiff` | modules/ui_components.psm1 | 353-399 | Before/after comparisons |
| `Write-ConsoleSeparator` | modules/ui_components.psm1 | 400-442 | Horizontal separator lines |
| `Write-ConsoleBreadcrumb` | modules/ui_components.psm1 | 443-490 | Breadcrumb navigation |

---

## 📊 Visual Components (7 functions)

| Function | File | Lines | Description |
|----------|------|-------|-------------|
| `Write-ConsoleBox` | modules/ui_components.psm1 | 491-543 | Bordered message boxes |
| `Write-ConsoleChart` | modules/ui_components.psm1 | 544-609 | Progress bar charts |
| `Write-ConsoleTree` | modules/ui_components.psm1 | 610-731 | Hierarchical tree structures |
| `Write-ConsoleTable` | modules/ui_components.psm1 | 732-884 | Formatted tables |
| `Show-ConsoleList` | modules/ui_components.psm1 | 1121-1167 | Formatted lists with bullets |
| `Write-ConsoleSparkline` | modules/ui_components.psm1 | 1344-1418 | Inline mini-charts |
| `Write-ConsolePanel` | modules/ui_components.psm1 | 1419-1499 | Bordered panels |

---

## 🎮 Interactive Components (10 functions)

| Function | File | Lines | Description |
|----------|------|-------|-------------|
| `Show-ConsoleMenu` | modules/ui_components.psm1 | 885-944 | Display interactive menus |
| `Read-ConsoleChoice` | modules/ui_components.psm1 | 945-975 | Read user menu selection |
| `Read-ConsoleMultiChoice` | modules/ui_components.psm1 | 976-1040 | Read multiple selections |
| `Invoke-ConsoleMenu` | modules/ui_components.psm1 | 1041-1120 | Complete menu system |
| `Invoke-ConsoleSpinner` | modules/ui_components.psm1 | 1168-1209 | Long-running operations |
| `Write-ConsoleProgress` | modules/ui_components.psm1 | 1210-1240 | Progress bars |
| `Read-ConsoleInput` | modules/ui_components.psm1 | 1241-1267 | User input with defaults |
| `Read-ConsoleConfirmation` | modules/ui_components.psm1 | 1268-1299 | Yes/No prompts |
| `Read-ConsolePassword` | modules/ui_components.psm1 | 1300-1343 | Secure password input |
| `Show-ConsoleNotification` | modules/ui_components.psm1 | 1500-1655 | Temporary notifications |

---

## ⚙️ Core Functions - Configuration (7 functions)

| Function | File | Lines | Description |
|----------|------|-------|-------------|
| `Initialize-UIConfig` | src/Core/Config.ps1 | 1-62 | Initialize configuration system |
| `Get-UIConfig` | src/Core/Config.ps1 | 63-107 | Get configuration values |
| `Get-UIColor` | src/Core/Config.ps1 | 108-165 | Get theme colors |
| `Get-UIIcon` | src/Core/Config.ps1 | 166-213 | Get icons from configuration |
| `Set-ConsoleTheme` | src/Core/Config.ps1 | 214-273 | Change active theme |
| `Get-ConsoleTheme` | src/Core/Config.ps1 | 274-313 | Get current theme name |
| `Get-AvailableThemes` | src/Core/Config.ps1 | 314-358 | List available themes |

---

## 🌍 Core Functions - Localization (5 functions)

| Function | File | Lines | Description |
|----------|------|-------|-------------|
| `Initialize-Localization` | src/Core/Localization.ps1 | 1-58 | Initialize i18n system |
| `Get-LocalizedString` | src/Core/Localization.ps1 | 59-116 | Get localized strings |
| `Set-UILocale` | src/Core/Localization.ps1 | 117-174 | Change active language |
| `Get-UILocale` | src/Core/Localization.ps1 | 175-208 | Get current locale |
| `Get-AvailableLocales` | src/Core/Localization.ps1 | 209-234 | List available languages |

---

## 📂 File Organization

### Main Module Files
- `PSConsoleUI.psm1` (87 lines) - Entry point, loads all modules
- `PSConsoleUI.psd1` (265 lines) - Module manifest

### Component Files
- `modules/ui_components.psm1` (1,655 lines) - All 29 UI components

### Core System Files
- `src/Core/Config.ps1` (408 lines) - Configuration system (7 functions)
- `src/Core/Localization.ps1` (234 lines) - i18n system (5 functions)

### Configuration Files
- `config/ui_config.json` - Themes and settings
- `config/locales/en-US.json` - English strings
- `config/locales/es-ES.json` - Spanish strings
- `config/locales/fr-FR.json` - French strings

### Test Files
- `tests/ui_components.tests.ps1` (252 lines) - Pester test suite

---

## 🔍 Quick Reference

### Finding a Function

**By Category:**
- Text formatting → modules/ui_components.psm1 (lines 11-490)
- Visual elements → modules/ui_components.psm1 (lines 491-1499)
- User interaction → modules/ui_components.psm1 (lines 885-1655)
- Configuration → src/Core/Config.ps1
- Localization → src/Core/Localization.ps1

**By Name Pattern:**
- `Write-Console*` → Text or Visual components
- `Show-Console*` → Visual or Interactive components
- `Read-Console*` → Interactive components
- `Invoke-Console*` → Interactive components
- `Get-*/Set-*` → Core functions

---

## 📝 Notes

- All UI components are in a single file (`ui_components.psm1`) for easier maintenance
- Core systems are separated into dedicated files for modularity
- Line numbers are approximate and may shift with updates
- Use `Get-Help <FunctionName>` for detailed documentation

---

**Last Updated:** 2026-01-15  
**Total Lines of Code:** ~2,900 (excluding tests and docs)
