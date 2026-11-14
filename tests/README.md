# Tests

Pester 5 tests. `build.ps1` runs all of them; CI runs them on Windows PowerShell 5.1 and on
PowerShell 7 on Windows, Linux and macOS.

| Folder | What it checks |
|---|---|
| `QA/` | Module quality: complete help for every exported command, no PSScriptAnalyzer findings with `PSScriptAnalyzerSettings.psd1`, changelog format, manifest metadata and exports. Shared with ArgosCCF and ThemisRules. |
| `Unit/Components.Tests.ps1` | What each component writes, themes, localization, menus and layouts. |
| `Unit/Security.Tests.ps1` | Removal of terminal escape sequences and validation of menu input. |
| `Unit/Manifest.Tests.ps1` | Exports and source file encoding (UTF-8 with BOM for non-ASCII files). |
| `Unit/Examples.Tests.ps1` | Runs the non-interactive scripts in `examples/`. |

```powershell
Invoke-Pester -Path ./tests                      # everything
Invoke-Pester -Path ./tests/Unit/Components.Tests.ps1
```

Components write with `Write-Host`. To check their output, mock it inside the module:

```powershell
Mock -ModuleName HermesConsoleUI Write-Host { $script:lines += ($Object -join ' ') }
```
