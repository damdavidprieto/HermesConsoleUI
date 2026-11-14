# Changelog

All notable changes to HermesConsoleUI are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.0] - 2026-11-14

This release makes HermesConsoleUI a standard Windows PowerShell 5.1 / PowerShell 7 module that
installs with `Install-Module` and loads automatically (issues #1 and #2).

### Fixed
- **Installation from the PowerShell Gallery (#1).** Earlier packages were packed from the repository
  folder with `nuget.exe` and included `.git`, tests and docs. The package is now built by `build.ps1`
  from `output/HermesConsoleUI` and contains only the module files. CI installs it with
  `Install-Module` on Windows PowerShell 5.1 and checks that it loads automatically.
- **Loading on Windows PowerShell 5.1.** Source files with non-ASCII characters are saved as UTF-8
  with BOM; without it 5.1 read them as ANSI and `src/Core/Config.ps1` failed to parse. The locale
  files are read as UTF-8, so accented prompts no longer show as `opciÃ³n`.
- **Themes had no effect.** Every component used fixed colors, so `Set-ConsoleTheme` changed nothing
  on screen. Color parameters now default to the active theme; an explicit `-Color` still wins.
- **Localization was not used.** Menus had Spanish prompts written in the code and the table an
  English message. Prompts and messages now come from the active locale (`Set-UILocale`).
- `Write-ConsoleTitle`, `Show-ConsoleMenu` and other centered text removed accented and other
  non-ASCII characters.
- `Invoke-ConsoleMenu` ran the wrong action when the menu had section headers or separators.
- `Write-ConsoleTable` ignored `-ColorMapProperty` and `-ColorMap`; rows are now colored by value.
  Long values are cut so columns stay aligned, and without `-Columns` one column per property is used.
- `Show-ConsoleList`, `Write-ConsoleTable` and the status functions accept pipeline input.
- `Invoke-ConsoleSpinner` removes its background job when it finishes or is interrupted.
- `Show-ConsoleMenu` ignores an unknown `{Color}` prefix instead of failing.
- The manifest listed `New-ConsoleColumn` twice and exported two Windows integration functions that
  were never loaded.

### Security
- **Terminal escape sequences in displayed data.** Text was written to the console as-is, so data
  shown in a table, list, menu or message (a file name, a log line, an API response) could contain
  escape sequences that recolor or hide output, move the cursor to overwrite earlier lines, change the
  window title or, in some terminals, set the clipboard (OSC 52). All output now goes through one
  function that removes ANSI CSI/OSC sequences, carriage returns and other control characters.
- **Menu input.** `Read-ConsoleMultiChoice` returned the last option when the user typed `0`, and both
  it and `Read-ConsoleChoice` threw on numbers too large for `[int]`. Only `1..N` is accepted now, each
  option is returned once, and an invalid number asks again.

### Changed
- **Requires Windows PowerShell 5.1 or PowerShell 7+ (#2).** The manifest declared PowerShell 2.0 and
  the documentation promised 2.0 support. Supports the Desktop and Core editions.
- `Get-AvailableThemes` and `Get-AvailableLocales` are now `Get-AvailableTheme` and
  `Get-AvailableLocale`, following PowerShell naming rules. The old names remain as aliases.
- `Set-ConsoleTheme` and `Set-UILocale` support `-WhatIf` and `-Confirm`.
- Every exported function has complete help (`Get-Help <name> -Full`), with examples.
- Clearing the screen in menus can be turned off with `$env:HERMESCONSOLEUI_NOCLEAR = 1`.
  `$Global:CassielDevMode` still works for compatibility.
- `Write-ConsoleMetadata` uses "Configuration" as the default title (was "Configuracion").
- New examples in `examples/` that run as part of the tests.
- Build and CI follow the structure of the Sampler module template: `build.ps1`,
  `PSScriptAnalyzerSettings.psd1`, QA tests for help, analyzer and changelog, and a `Publish`
  workflow triggered by version tags. CI runs on Windows PowerShell 5.1 and on PowerShell 7 on
  Windows, Linux and macOS.

### Removed
- `Install.ps1`; install with `Install-Module HermesConsoleUI`.
- Code that was never loaded or called: `src/Constants`, `src/Validators`,
  `modules/windows_integration.ps1` and several unused helper functions.
- Outdated documents (roadmap, task lists, status reports, function map) and the old examples,
  which imported `PSConsoleUI.psd1` and no longer ran.

## [2.1.0] - 2026-02-08

### Added
- `-Header` and `-ReturnIndex` parameters on `Show-ConsoleMenu`, used by Cassiel.
- Layout components: `New-ConsoleLayout`, `New-ConsoleRow`, `New-ConsoleColumn`, `Write-ConsoleLayout`.

## [2.0.1] - 2026-01-15

### Changed
- Tests rewritten for Pester 5 with the `Console` function names.
- Merged five duplicate component modules into one.

## [2.0.0] - 2026-01-14

### Changed
- Renamed from CassielUI to PSConsoleUI (later HermesConsoleUI), and every `*-Cassiel*` function to
  `*-Console*`.

### Added
- Themes (Default, Cyberpunk, Classic, Monochrome, Custom) and localization (en-US, es-ES, fr-FR).

## [1.1.0] - 2026-01-12

### Added
- Logging, input validation, pagination and arrow-key menu helpers (CassielUI).

## [1.0.0] - 2026-01-12

### Added
- First version, as the Cassiel UI library.

[Unreleased]: https://github.com/damdavidprieto/HermesConsoleUI/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/damdavidprieto/HermesConsoleUI/releases/tag/v2.2.0
