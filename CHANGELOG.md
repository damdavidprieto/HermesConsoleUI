# Changelog

All notable changes to HermesConsoleUI are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.10.0] - 2026-11-27

### Added
- `docs/API.md`: the 72 commands and 2 aliases by group, with what each one does, and the internal helpers apart. The
  test `tests/Unit/Hygiene.Tests.ps1` checks that every exported name is listed.
- A UTF-8 byte order mark in every script file, which Windows PowerShell 5.1 needs to read them as UTF-8. The same test
  keeps it there.

### Changed
- The long functions are split into private helpers that share one state object. `Read-ConsoleSelectionKey` now keeps
  its view (labels, highlight, marks, filter, colors) in one object and handles each key, draws the page and filters
  in functions of their own. `Read-ConsoleMenu` reads its entries, runs the arrow-key list and lists the options in
  separate functions. `Write-ConsoleTable` writes its rows and cells in separate functions; the rows keep the loop that
  writes each row in one go.
- The output state is one object, `$script:HermesOutput` (the handler, its quiet mode, the pause while a list is redrawn,
  the status line and the capture). The default layout is a function, and the Write-Host proxy of
  `Enable-ConsoleHostRedirect` is local to it. The module has fewer script-scope variables.
- `Write-ConsoleTable -ReturnLines` takes about 10% longer, since each cell goes through a function. Writing the table to
  the console is as fast as before.

### Removed
- `$Global:CassielDevMode` is no longer read. Applications that used it to keep earlier output on screen set
  `$env:HERMESCONSOLEUI_NOCLEAR = 1` instead; the module names no application.

### Compatibility
- No command, parameter, alias or output has changed: the public API is the same as in 2.9.0. The test seams
  (`HermesReadKey`, `HermesInteractiveOverride`, `HermesLiveOverride`, `HermesTrueColorOverride`) are unchanged too.

## [2.9.0] - 2026-11-27

### Added
- **Simulated console for tests**: `Enable-ConsoleSimulation`, `Disable-ConsoleSimulation` and `Invoke-ConsoleSimulation`
  give the prompts the keys (`-KeyPresses`, also `-Keys`) and the lines (`-Answers`) they read, so a script's tests need no
  internal variables. Keys run out into Escape and answers into an ended input, as with a redirected file.
  `-NonInteractive` behaves as a console without keys.
- **`Write-ConsoleText -Prefix` and `-PrefixColor`**: a fixed prefix in its own color before the text; with `-Wrap` the
  following lines start under the text, after the prefix (or under a prefix of spaces).
- **`Format-ConsoleText -KeepLineBreaks`** cuts a block of text line by line and keeps its line breaks; **`-MaxLines`**
  keeps the first lines and ends with "…" when there were more.
- **`Read-ConsoleInput -NoColon`** writes only a space after the prompt.

### Changed
- `Read-ConsoleInput` no longer adds a second colon: a prompt that ends in ":", "?" or ">" gets a space instead of
  ": " ("Name:" shows "Name: ", not "Name:: "; "Ready?" shows "Ready? ", not "Ready?: "). Other prompts are unchanged.
- `Write-ConsoleLine` refuses segments that PowerShell merged into one list: a color name written as plain text right after
  another plain text segment fails with a message that shows the safe forms (a comma in front of each array, or hashtables).

### Fixed
- `Write-ConsoleKeyValue -LabelWidth` keeps the width asked for while the line has 10 columns left for the values. Before,
  labels longer than half the line were cut with "…" even when a width was given.

## [2.8.0] - 2026-11-26

### Added
- **`Write-ConsoleLine`**: one line made of segments, each with its own color and width; one segment can
  fill the rest of the line, cut with `…` or wrapped with its following lines aligned under it. Segments are
  strings, arrays (text, color, width) or hashtables (`Text`, `Color`, `Width`, `Align`, `Fill`, `Gap`,
  `Value` and `Style`, `Bar`); `$null` segments are skipped.
- **Named styles**: `Register-ConsoleStyle`, `Get-ConsoleStyle` and `Unregister-ConsoleStyle` give each value
  its text and color (`-Map`), color numbers by thresholds (`-Thresholds`, `-Format`) and have a `-Default`.
  Lines, key-value lists, table columns (`Style`) and charts (`Write-ConsoleChart -Style`) use them.
- **Bars inside a line**: a `Bar` segment, colored by `Color` or by a style.
- **`Write-ConsoleKeyValue`**: labels in a column and values wrapped under themselves (or cut with `-Cut`),
  from a dictionary or a list that can repeat labels; `-LabelStyle` colors labels such as severities.
- **`Set-ConsoleLayout`** and **`Get-ConsoleLayout`**: the widest line, the margin of the line components and
  the width to use when the console width is unknown, for every component. **`Write-ConsoleGrid`** puts items
  of the same width side by side, as many as fit.
- **`Start-ConsoleCapture`** and **`Stop-ConsoleCapture`**: a copy of the output and the answers in a UTF-8
  file, line by line, alongside any output handler. While capturing, prompts read typed answers and nothing
  is rewritten in place.
- **Titles and sections**: `Write-ConsoleTitle -Subtitle` and `-Align Left` (title at the margin, wrapped
  subtitle, rule across the line); `Write-ConsoleHeader -Note` and `-Compact`; `Write-ConsoleSeparator
  -Length 0` (the line width) and `-Indent`. **`Wait-ConsoleKey`** waits for Enter with a localized message.
- **`Enable-ConsoleHostRedirect`** and **`Disable-ConsoleHostRedirect`**: `Write-Host` in the calling script or
  module writes through the module (cleaned, `NO_COLOR`, handlers and captures).

### Changed
- Where the terminal supports virtual terminal sequences, `Write-ConsoleText`, `Write-ConsoleLine` and the
  other line components write each line in one call, with the colors as escape sequences, instead of one
  call per color. Elsewhere, and in output handlers, nothing changes.
- `Get-ConsoleWidth` and wrapped text follow `Set-ConsoleLayout` when it is used; by default nothing changes.

## [2.7.0] - 2026-11-26

### Added
- **Answers in captures**: the output handler (`Register-ConsoleOutputHandler`) now also receives what the
  user typed to `Read-ConsoleChoice`, `Read-ConsoleInput`, `Read-ConsoleConfirmation`, `Read-ConsoleMultiChoice`,
  `Read-ConsoleSelection` and `Read-ConsoleMenu`, so a capture keeps each question with its answer. A password
  is passed as asterisks. A list redrawn in place is passed once, with the option chosen.
- **`Write-ConsoleStatusLine`** and **`Clear-ConsoleStatusLine`**: one line of progress rewritten in place, in
  the same process (unlike `Invoke-ConsoleSpinner`, which runs a job). Nothing is written when the output is
  redirected, it is never passed to the handler, and anything else the module writes clears it first.
- **`Write-ConsoleText -Wrap`** (with `-Width` and `-Indent`): long text broken into lines at spaces, colors
  kept, the following lines aligned.
- **`Format-ConsoleText`** cuts text to a width with `…` and pads it; **`Measure-ConsoleText`** returns the
  columns a text takes (East Asian characters and emoji take two, combining accents none).
- **`Read-ConsoleMenu`**: keyed options with a note column, a color and a recommended one; arrow keys in a
  console, the key typed elsewhere; `-Default`, `-Cancel` and `-Filter`.
- **`Read-ConsoleChoice -Choices`** reads a word or letter (`-DefaultValue` for Enter and for input that runs out).
- **`Read-ConsoleSelection -Filter`**: typing narrows the list to the options that contain the text.
- **`Write-ConsoleTable`**: per-column `Map` (value to the word shown) and `Colors` (value to the cell color),
  and `-ReturnLines`.
- **`Write-ConsoleChart -Thresholds`** (color by percentage) and `-NoNewline`; `-Label` is now optional.
- **`Get-ConsoleWidth`** (with `-Maximum` and `-Default`) and **`Clear-ConsoleScreen`**, which writes a blank
  line where the screen cannot be cleared, are now public.
- **Exact colors**: `#RRGGBB` in color marks, `-Color` parameters and themes, written exactly where the
  terminal supports virtual terminal sequences and as the nearest console color elsewhere.

### Changed
- Text cut to fit (tables, lists, panels, boxes, layouts and the arrow-key list) ends with `…`, and widths are
  measured as the console shows them, so columns stay aligned with East Asian characters and emoji. This costs
  a little time: a 1,000-row table takes about 165 ms instead of 140 in PowerShell 7 and 235 ms instead of 215 in
  Windows PowerShell 5.1.
- `Show-ConsoleMenu` clears the screen with `Clear-ConsoleScreen`: a blank line instead of `Clear-Host` when
  the output is redirected or only goes to an output handler.

## [2.6.0] - 2026-11-26

### Added
- **`Write-ConsoleTree -ReturnLines`**, so a tree can go inside a panel or a layout column.
- **`Read-ConsoleMultiChoice -ReturnIndex`**: the indexes of the chosen options, so options with the same
  text can be told apart.
- **Themes from the configuration file**: any theme in the `ColorScheme` section of `ui_config.json` can be
  activated with `Set-ConsoleTheme` (tab completion lists them). Before, only the four built-in names were
  accepted.
- **Locales by language**: a culture without its own file uses one of the same language, so `es-MX` uses
  `es-ES` and `fr-CA` uses `fr-FR`, at start-up and with `Set-UILocale` (which also accepts `es` or `fr`).

### Changed
- **Faster output**: text without control characters is no longer run through the escape-sequence filter,
  the text of each table cell is cleaned once, and locale lookups no longer call `Get-Member`. Measured on
  Windows: a 1,000-row table takes 155 ms instead of 530 in PowerShell 7 and 215 ms instead of 1,380 in
  Windows PowerShell 5.1; titles, trees and colored text take about 40% less, a status line about 25% less.
- **A configuration file only needs the settings it changes**: it is merged over the built-in ones. A theme
  that leaves out some roles takes them from Default.
- `config/ui_config.json` only has the settings the module reads (themes, the status icons of `Get-UIIcon`
  and `Table.MaxColumnWidth`). The `Version` setting and the `Title`, `Header`, `Box`, `Chart`, `Tree`,
  `Menu` and `Progress` sections were never read: changing them did nothing.

### Fixed
- **`Write-ConsoleTree`** draws the last item of each level with a corner (`└──`) and the others with a tee,
  and the vertical line stops after the last branch. Before, every branch had a tee, every leaf a corner,
  and the line went on under the last branch.
- **`Read-ConsoleInput`** no longer asks forever when redirected input has ended: it returns the default
  value, or an empty answer when that is valid, and otherwise throws.
- **`Read-ConsoleSelection -Multiple`** without an interactive console returned the first of two options
  with the same text twice; it now returns both.
- **`Write-ConsoleLayout`**: a line break in the text of a column starts a new line, instead of being
  written as a space.
- `Set-ConsoleTheme -ThemeName Custom` after a configuration file failed to load changed the built-in
  settings, so the custom theme stayed after loading the configuration again.

## [2.5.0] - 2026-11-22

### Added
- **`Write-ConsoleText -Plain`**: writes the text exactly as given, braces included, in one color. For text
  that comes from data, which otherwise needed every `{` doubled.
- **`Read-ConsoleChoice -DefaultChoice`**: the choice returned when the user just presses Enter, shown after
  the prompt as `[n]`.

### Fixed
- **`Read-ConsoleChoice`** no longer asks forever when redirected input has ended (a script, a scheduled
  task or an agent feeding answers): it returns the default, 0 when allowed, or throws.
- **`Read-ConsoleSelection`** without an interactive console now picks `-Default` on Enter, like the
  interactive list, instead of asking again.

## [2.4.0] - 2026-11-22

### Added
- **`Register-ConsoleOutputHandler`** and **`Unregister-ConsoleOutputHandler`**: a script block receives a
  copy of everything the components write (text, whether the line continues, color), for logs, captures
  of elevated child processes or tests. `-Quiet` writes only to the handler.
- **`Read-ConsoleSelection`**: typing a letter or digit jumps to the next option whose label starts with it.
- **`Read-ConsoleConfirmation -Default`**: the answer used when the user just presses Enter; the hint shows
  it in capitals, as in `(Y/n)`.

## [2.3.0] - 2026-11-22

Compared with other console UI modules in the PowerShell Gallery (PwshSpectreConsole, PSMenu,
ps-menu, PSWriteColor, TableUI), HermesConsoleUI lacked arrow-key menus, tables sized to their
content and validated input. This release adds them without dependencies, on Windows PowerShell
5.1 and PowerShell 7.

### Added
- **`Read-ConsoleSelection`**: choose one option with the arrow keys and Enter, or several with
  `-Multiple` (Space marks, A marks all), with paging for long lists (`-PageSize`), objects shown
  through `-DisplayProperty`, and `-ReturnIndex`. Escape cancels. Without an interactive console
  (CI, pipes, the ISE, remote sessions) it falls back to numbered prompts.
- **`Write-ConsoleText`**: several colors in one line with `{Color}text{/}` marks, using console
  color names or theme roles such as `{Success}`.
- **`Read-ConsoleInput -Required`, `-Pattern`, `-Validate` and `-ErrorMessage`**: the question is
  asked again until the answer is valid.
- **`NO_COLOR`** (https://no-color.org): when set, no component writes colors.
- Locale strings for the selection hints and the input error message in English, Spanish and French.

### Changed
- **`Write-ConsoleTable` sizes columns automatically.** Columns without `Width` are as wide as their
  longest value or header (they were always 20 characters), the widest ones are narrowed to fit the
  console window, numeric columns are aligned to the right (`Align` chooses), and a line separates
  the header from the rows. Columns with `Width` keep it.

### Fixed
- **`Invoke-ConsoleSpinner` erased the last character of the message.** The first spinner frame started
  with a backspace, so "Working" became "Workin|". The message is now followed by a space and the first
  frame has no backspace. When the output is redirected to a file or a pipe the spinner is not drawn,
  so no backspace characters end up in the output.
- **`Read-ConsoleChoice -MaxChoice 0 -AllowZero $false` asked forever**, since no answer could be valid.
  It now throws an `ArgumentException` (for example, a menu whose options are all separators).

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

[Unreleased]: https://github.com/damdavidprieto/HermesConsoleUI/compare/v2.4.0...HEAD
[2.4.0]: https://github.com/damdavidprieto/HermesConsoleUI/releases/tag/v2.4.0
[2.3.0]: https://github.com/damdavidprieto/HermesConsoleUI/releases/tag/v2.3.0
[2.2.0]: https://github.com/damdavidprieto/HermesConsoleUI/releases/tag/v2.2.0
