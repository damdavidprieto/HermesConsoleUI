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
- Menus driven by the arrow keys, which fall back to numbered prompts where there is no interactive
  console (CI logs, pipes, remote sessions), so the same script runs everywhere.
- Honors [`NO_COLOR`](https://no-color.org).
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

# Arrow keys and Enter; -Multiple marks several with Space
$target = Read-ConsoleSelection -Title 'Deploy to' -Options 'Development', 'Staging', 'Production'

# Several colors in one line
Write-ConsoleText 'Deploy {Success}finished{/} in {Cyan}42 s{/}, {Warning}2 warnings{/}'

# Asks again until the answer is valid
$port = Read-ConsoleInput -Prompt 'Port' -DefaultValue '8080' -Pattern '\d{1,5}'
```

More in [`examples/`](examples/): text, data display, layouts, themes and locales, and an
interactive menu. Each example runs as part of the tests.

## Commands

| Area | Commands |
|---|---|
| Text | `Write-ConsoleText`, `Format-ConsoleText`, `Measure-ConsoleText`, `Get-ConsoleWidth`, `Clear-ConsoleScreen`, `Register-ConsoleOutputHandler`, `Unregister-ConsoleOutputHandler`, `Write-ConsoleTitle`, `Write-ConsoleHeader`, `Write-ConsoleSubtitle`, `Write-ConsoleStatus`, `Write-ConsoleInfo`, `Write-ConsoleError`, `Write-ConsoleMetadata`, `Write-ConsoleSummary`, `Write-ConsoleDiff`, `Write-ConsoleSeparator`, `Write-ConsoleBreadcrumb` |
| Data | `Write-ConsoleTable`, `Show-ConsoleList`, `Write-ConsoleTree`, `Write-ConsoleChart`, `Write-ConsoleSparkline`, `Write-ConsoleBox`, `Write-ConsolePanel` |
| Interaction | `Read-ConsoleSelection`, `Read-ConsoleMenu`, `Show-ConsoleMenu`, `Read-ConsoleChoice`, `Invoke-ConsoleMenu`, `Read-ConsoleMultiChoice`, `Read-ConsoleInput`, `Read-ConsoleConfirmation`, `Read-ConsolePassword`, `Invoke-ConsoleSpinner`, `Write-ConsoleStatusLine`, `Clear-ConsoleStatusLine`, `Show-ConsoleProgress`, `Write-ConsoleProgress`, `Show-ConsoleNotification` |
| Lines | `Write-ConsoleLine`, `Write-ConsoleKeyValue`, `Write-ConsoleGrid`, `Register-ConsoleStyle`, `Get-ConsoleStyle`, `Unregister-ConsoleStyle`, `Set-ConsoleLayout`, `Get-ConsoleLayout`, `Start-ConsoleCapture`, `Stop-ConsoleCapture`, `Wait-ConsoleKey`, `Enable-ConsoleHostRedirect`, `Disable-ConsoleHostRedirect`, `Enable-ConsoleSimulation`, `Disable-ConsoleSimulation`, `Invoke-ConsoleSimulation` |
| Layout | `New-ConsoleLayout`, `New-ConsoleRow`, `New-ConsoleColumn`, `Write-ConsoleLayout` |
| Themes | `Set-ConsoleTheme`, `Get-ConsoleTheme`, `Get-AvailableTheme`, `Get-UIColor`, `Get-UIIcon`, `Get-UIConfig`, `Initialize-UIConfig` |
| Localization | `Set-UILocale`, `Get-UILocale`, `Get-AvailableLocale`, `Get-LocalizedString`, `Initialize-Localization` |

`Get-Command -Module HermesConsoleUI` lists them and `Get-Help <command> -Full` documents each one. [docs/API.md](docs/API.md) lists them by group, with what each one does.
Commands that return lines (`Show-ConsoleList`, `Write-ConsoleTree`, `Write-ConsoleTable`, `Write-ConsoleChart`,
`Write-ConsoleBox`, `Write-ConsoleLine`, `Write-ConsoleKeyValue`, `Write-ConsoleGrid`) accept `-ReturnLines`, so
their output can go inside a panel or a layout column.

## Reports line by line

An application that writes its own reports defines its words and colors once and then writes each line in
one call:

```powershell
Set-ConsoleLayout -MaxWidth 110 -Margin 2 -DefaultWidth 100
Register-ConsoleStyle State -Map @{ Compliant = 'OK', 'Green'; NonCompliant = 'Pending', 'Red' } -Default 'No data', 'DarkYellow'
Register-ConsoleStyle Percent -Thresholds @{ 0 = 'Red'; 70 = 'Yellow'; 100 = 'Green' } -Format '{0,3} %'

Write-ConsoleTitle -Title 'Audit' -Subtitle 'Checks every rule up to your target level.' -Align Left
Write-ConsoleHeader -Text 'Firewall' -Note 'compliant 4 of 6' -Compact
foreach ($r in $results) {
    Write-ConsoleLine @(
        @{ Value = $r.Status; Style = 'State' }        # as wide as the longest word of the style
        @{ Text = $r.Id; Color = 'DarkCyan'; Width = 8 }
        @{ Text = $r.Title; Fill = 'Cut' }              # the rest of the line, cut with …
        $(if ($r.Risk -eq 'high') { @{ Text = 'high risk'; Color = 'Red'; Gap = 2 } })
    )
}
Write-ConsoleLine @{ Text = 'L2 Recommended'; Width = 16 }, @{ Bar = 82; Width = 24; Style = 'Percent' }, @{ Value = 82; Style = 'Percent' }
Write-ConsoleKeyValue ([ordered]@{ Rule = 'FW-001'; State = @{ Value = 'NonCompliant'; Style = 'State' }; Why = $rule.Reason })
Write-ConsoleGrid -ColumnWidth 38 $areaItems                   # as many per line as fit
Wait-ConsoleKey
```

- `Write-ConsoleLine` takes segments: a string, an array (text, color, width) or a hashtable with `Text`,
  `Color`, `Width`, `Align`, `Fill` (`Cut` or `Wrap`, the rest of the line), `Gap`, `Value` and `Style`, or
  `Bar`. A `$null` segment is skipped, so a segment can depend on a condition. A wrapped segment keeps its
  following lines under its start, after a label or a severity column.
- Write array segments with a comma in front of each, `,@('Name', 'Red')`, or as hashtables: inside `@( )`, arrays written one per line are merged into one list, and `Write-ConsoleLine` refuses a color name found as text.
- `Register-ConsoleStyle` names the text and color of each value; lines, key-value lists, table columns
  (`Style`) and charts (`-Style`) use it, and `Get-ConsoleStyle` returns them for anything else.
- `Set-ConsoleLayout` sets the widest line, the margin and the width to use when the console width is
  unknown, for every component.
- Where the terminal supports virtual terminal sequences (PowerShell 7 in Windows Terminal, and most
  consoles), each line is written in one call, colors included: faster, and lines are never split.
- `Enable-ConsoleHostRedirect` makes `Write-Host` in the calling script or module write through the module,
  so code that still calls it is cleaned and captured too.

## Themes

```powershell
Get-AvailableTheme                      # Classic, Cyberpunk, Default, Monochrome
Set-ConsoleTheme -ThemeName Cyberpunk   # every component uses the theme colors
Set-ConsoleTheme -ThemeName Custom -CustomColors @{ Primary = 'DarkCyan'; Success = 'DarkGreen' }
```

Themes define eight color roles: Primary, Secondary, Success, Warning, Error, Info, Muted and
Highlight. The built-in themes are in [`config/ui_config.json`](config/ui_config.json); a theme added
there (or in your own file, loaded with `Initialize-UIConfig -ConfigPath`) can be activated by its name.
A configuration file only needs what it changes, and a theme that leaves out roles takes them from Default.

## Localization

```powershell
Get-AvailableLocale            # en-US, es-ES, fr-FR
Set-UILocale -Locale es-ES     # menus and prompts in Spanish
```

The locale strings are in [`config/locales/`](config/locales/). The locale starts as the system
culture when a file exists for it, then a file of the same language (`es-MX` uses `es-ES`), and English
otherwise.

## Menus and the screen

`Read-ConsoleSelection` draws the list in place and redraws it as you move, with Page Up, Page Down,
Home and End for long lists (`-PageSize`); with `-Filter`, typing narrows the list. Without an interactive
console it lists the options with numbers and reads the answer with `Read-ConsoleChoice` or
`Read-ConsoleMultiChoice`.

```powershell
$action = Read-ConsoleMenu -Title 'Tasks' -Recommended a -Default q -Cancel q -Items ([ordered]@{
    a = 'Audit', 'Check every rule'
    r = 'Repair', 'Apply the pending rules', 'Yellow'
    q = 'Quit'
})
```

`Read-ConsoleMenu` shows keyed options with a note column and a recommended one, and returns the key:
with the arrow keys in a console, by typing the key elsewhere. `Read-ConsoleChoice -Choices` reads a word
or letter, such as `s` or `n`, with a default for Enter.

`Write-ConsoleStatusLine` shows one line of progress that is rewritten in place, in the same process, and
`Clear-ConsoleStatusLine` removes it; anything else the module writes removes it first.

`Show-ConsoleMenu` and `Clear-ConsoleScreen` clear the screen, or write a blank line where that is not
possible (redirected output, a capture). `Show-ConsoleMenu` clears the screen before drawing. Use `-NoClear` for one menu, or set
`$env:HERMESCONSOLEUI_NOCLEAR = 1` to keep earlier output on screen in every menu, for example
while debugging.

## Capturing the output

`Register-ConsoleOutputHandler` passes a copy of everything the components write to a script block
(the text, whether the line continues, and the color), for logs, transcripts or tests; with `-Quiet`
nothing is shown on screen. The answers typed to the prompts are passed too (a password as asterisks), so a
capture keeps each question with its answer. `Unregister-ConsoleOutputHandler` removes it.

`Start-ConsoleCapture -Path` keeps the same copy in a UTF-8 file, one complete line at a time, for example
for a copy of the script that runs elevated in another window; `Stop-ConsoleCapture` ends it. While
capturing nothing is rewritten in place: prompts list their options and read the typed answer, so the file
shows both.

## Testing without a console

`Invoke-ConsoleSimulation` runs a script block with keys and answers in place of the console, so the prompts can be tested:

```powershell
$pick = Invoke-ConsoleSimulation -KeyPresses 'DownArrow', 'Enter' { Read-ConsoleMenu -Items ([ordered]@{ a = 'Audit'; r = 'Repair' }) -Default a }
$name = Invoke-ConsoleSimulation -Answers 'ana' { Read-ConsoleInput -Prompt 'Name:' }
```

Keys run out into Escape and answers into an ended input (a required input then throws), so a test never waits.
`Enable-ConsoleSimulation` and `Disable-ConsoleSimulation` do the same around a group of tests. `-NonInteractive`
behaves as a console without keys: the options are listed and the typed key is read.

## Tables

`Write-ConsoleTable` sizes each column to its longest value (up to `MaxColumnWidth` in the theme
configuration), narrows the widest ones when the table does not fit in the window, aligns numbers
to the right and underlines the header. Give a column a `Width` or an `Align` to fix them, a `Map` to show
words instead of values and `Colors` to color each cell by its value, or a `Style` for both. Values that do
not fit end with `…`.
Widths are measured as the console shows them: East Asian characters and emoji take two columns.

## Colors

`NO_COLOR` set to any value turns colors off in every component. `Write-ConsoleText` takes
`{Color}` marks with any console color or theme role; `{/}` goes back to the default color and
`{{` writes a literal brace; `-Wrap` breaks long text into lines that fit the console. Any color can also
be `#RRGGBB`, in marks, `-Color` parameters and themes: exact where the terminal supports it, the nearest
console color elsewhere. `Write-ConsoleChart -Thresholds` colors a bar by its percentage.

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
