# HermesConsoleUI 2.9.0: public API

Generated from `HermesConsoleUI.psd1` and the help of each command. Every name listed here is exported; the
test `tests/Unit/Hygiene.Tests.ps1` checks that none is missing.

## Stability

Commands and parameters are not removed or renamed before version 3.0. A minor version only adds commands and
parameters; every change is listed in [CHANGELOG.md](../CHANGELOG.md). The compatibility aliases keep the names of
earlier versions.

## Internal functions

Functions that are defined in the module but not exported are its own helpers. Scripts must not call them: they
can change or disappear in any version. They are listed at the end.

## Configuration and localization

| Command | What it does |
|---|---|
| `Initialize-UIConfig` | Initializes the UI configuration system. |
| `Get-UIConfig` | Gets the current UI configuration. |
| `Get-UIColor` | Gets a color from the active theme. |
| `Get-UIIcon` | Gets an icon from the configuration. |
| `Set-ConsoleTheme` | Changes the active UI theme. |
| `Get-ConsoleTheme` | Gets the current active theme name. |
| `Get-AvailableTheme` | Gets list of available themes. |
| `Initialize-Localization` | Initializes the localization system. |
| `Get-LocalizedString` | Retrieves a localized string by key path. |
| `Set-UILocale` | Changes the active UI locale. |
| `Get-UILocale` | Gets the current active UI locale. |
| `Get-AvailableLocale` | Gets list of available locales. |

## Text components

| Command | What it does |
|---|---|
| `Write-ConsoleTitle` | Displays a centered title between two border lines. |
| `Write-ConsoleHeader` | Displays a section header with a ">>>" prefix. |
| `Write-ConsoleSubtitle` | Displays a subsection title in brackets, with an optional count. |
| `Write-ConsoleError` | Displays an error message with an error icon. |
| `Write-ConsoleInfo` | Displays an informational message with an info icon. |
| `Write-ConsoleStatus` | Displays a status message with an icon and a color for its type. |
| `Write-ConsoleMetadata` | Displays a hashtable as a titled list of key-value pairs. |
| `Write-ConsoleSummary` | Displays a summary section with labeled values. |
| `Write-ConsoleDiff` | Displays a before and after comparison of a value. |
| `Write-ConsoleSeparator` | Displays a horizontal separator line. |
| `Write-ConsoleBreadcrumb` | Displays a navigation breadcrumb trail. |
| `Write-ConsoleText` | Writes a line with several colors, marked inline as {Color}text{/}. |
| `Register-ConsoleOutputHandler` | Sends a copy of everything the components write to a script block, for logs, captures or tests. |
| `Unregister-ConsoleOutputHandler` | Removes the handler registered with Register-ConsoleOutputHandler. |
| `Measure-ConsoleText` | Returns how many columns a text takes on the console. |
| `Format-ConsoleText` | Cuts a text to a width with an ellipsis, and optionally pads it, measuring the columns it takes. |
| `Get-ConsoleWidth` | Returns the width of the console window in characters. |
| `Clear-ConsoleScreen` | Clears the console screen where that is possible, and writes a blank line otherwise. |

## Visual components

| Command | What it does |
|---|---|
| `Write-ConsoleBox` | Displays a message inside an ASCII box. |
| `Write-ConsoleChart` | Displays a value as a horizontal bar with its percentage. |
| `Write-ConsoleTree` | Displays a hashtable as a tree. |
| `Write-ConsoleTable` | Displays objects as a table with aligned columns. |
| `Show-ConsoleList` | Displays a bulleted or numbered list. |
| `Write-ConsoleSparkline` | Displays a series of numbers as an inline mini chart. |
| `Write-ConsolePanel` | Displays the output of a script block inside a bordered panel. |

## Interactive components

| Command | What it does |
|---|---|
| `Show-ConsoleMenu` | Displays a numbered menu and returns how many options can be selected. |
| `Read-ConsoleChoice` | Reads a menu choice and returns it as a number. |
| `Read-ConsoleMultiChoice` | Lets the user pick several options by number and returns the chosen options. |
| `Read-ConsoleSelection` | Lets the user pick one option, or several with -Multiple, with the arrow keys. |
| `Invoke-ConsoleMenu` | Shows a menu, runs the selected action and repeats until the user exits. |
| `Invoke-ConsoleSpinner` | Runs a script block in a background job while showing a spinner. |
| `Write-ConsoleProgress` | Updates the PowerShell progress bar. |
| `Show-ConsoleProgress` | Writes an inline text progress bar with its percentage. |
| `Read-ConsoleInput` | Prompts the user for a line of text and returns it. |
| `Read-ConsoleConfirmation` | Asks a yes/no question and returns $true for yes. |
| `Read-ConsolePassword` | Prompts for a password without showing it and returns it as a SecureString. |
| `Show-ConsoleNotification` | Displays a one-line notification such as "[Warning] Disk almost full". |
| `Read-ConsoleMenu` | Shows a menu of keyed options, with notes and a recommended one, and returns the key chosen. |
| `Write-ConsoleStatusLine` | Shows a line of progress that is rewritten in place, such as " 42 % Checking the firewall". |
| `Clear-ConsoleStatusLine` | Removes the line shown by Write-ConsoleStatusLine. |

## Layout components

| Command | What it does |
|---|---|
| `New-ConsoleLayout` | Creates a layout from rows of columns. |
| `New-ConsoleRow` | Creates a layout row from columns. |
| `New-ConsoleColumn` | Creates a layout column with its content and width. |
| `Write-ConsoleLayout` | Draws a layout created with New-ConsoleLayout. |

## Line components

| Command | What it does |
|---|---|
| `Set-ConsoleLayout` | Sets the widest line, the left margin and the width to use when the console width is unknown. |
| `Get-ConsoleLayout` | Returns the layout settings (Set-ConsoleLayout) and the line width they give now. |
| `Register-ConsoleStyle` | Names a set of values with the word and the color to show for each, to use in lines, tables and charts. |
| `Unregister-ConsoleStyle` | Removes a style registered with Register-ConsoleStyle. |
| `Get-ConsoleStyle` | Lists the registered styles, describes one, or returns the text and color a style gives a value. |
| `Write-ConsoleLine` | Writes one line made of segments, each with its own color and width; one can fill the rest of the line. |
| `Write-ConsoleKeyValue` | Writes labels in a column and their values next to them, wrapped under themselves. |
| `Write-ConsoleGrid` | Writes items in columns of the same width, as many on each line as fit. |
| `Start-ConsoleCapture` | Keeps a copy of everything the module writes, and the answers typed, in a text file, line by line. |
| `Stop-ConsoleCapture` | Ends the capture started with Start-ConsoleCapture, writing the last unfinished line. |
| `Wait-ConsoleKey` | Asks the user to press Enter, for example before going back to a menu. |
| `Enable-ConsoleHostRedirect` | Makes Write-Host, in the script or module that calls this, write through HermesConsoleUI. |
| `Disable-ConsoleHostRedirect` | Removes the Write-Host defined by Enable-ConsoleHostRedirect in the calling script or module. |
| `Enable-ConsoleSimulation` | Makes the prompts read simulated keys and answers, for tests of scripts that use the module. |
| `Disable-ConsoleSimulation` | Ends the simulation started with Enable-ConsoleSimulation: prompts read the real console again. |
| `Invoke-ConsoleSimulation` | Runs a script block with simulated keys and answers, and ends the simulation afterwards. |

## Aliases

| Alias | Command |
|---|---|
| `Get-AvailableThemes` | `Get-AvailableTheme` |
| `Get-AvailableLocales` | `Get-AvailableLocale` |

## Internal helpers

| Function | File |
|---|---|
| `ConvertTo-Hashtable` | Config.ps1 |
| `Merge-UIConfigTable` | Config.ps1 |
| `ConvertTo-ConsoleSafeText` | helpers.ps1 |
| `ConvertTo-NearestConsoleColor` | helpers.ps1 |
| `Get-CenteredText` | helpers.ps1 |
| `Get-ComponentIcon` | helpers.ps1 |
| `Get-ConsoleCursorRow` | helpers.ps1 |
| `Get-UIText` | helpers.ps1 |
| `Merge-LayoutColumn` | helpers.ps1 |
| `Resolve-UIColor` | helpers.ps1 |
| `Send-HermesAnswer` | helpers.ps1 |
| `Send-HermesOutput` | helpers.ps1 |
| `Set-ConsoleCursorRow` | helpers.ps1 |
| `Set-ConsoleCursorVisible` | helpers.ps1 |
| `Test-ClearScreenAllowed` | helpers.ps1 |
| `Test-EmojiSupport` | helpers.ps1 |
| `Test-HermesLiveOutput` | helpers.ps1 |
| `Test-HermesTrueColor` | helpers.ps1 |
| `Test-InteractiveConsole` | helpers.ps1 |
| `Test-NoColor` | helpers.ps1 |
| `Write-HermesHost` | helpers.ps1 |
| `Write-HermesSegment` | helpers.ps1 |
| `Read-ConsoleSelectionKey` | interactive_components.ps1 |
| `Read-ConsoleWordChoice` | interactive_components.ps1 |
| `Test-HermesInputRedirected` | interactive_components.ps1 |
| `Assert-HermesSegmentList` | line_components.ps1 |
| `ConvertTo-HermesKey` | line_components.ps1 |
| `ConvertTo-HermesLine` | line_components.ps1 |
| `ConvertTo-HermesSegment` | line_components.ps1 |
| `ConvertTo-HermesStyleEntry` | line_components.ps1 |
| `Get-HermesLineWidth` | line_components.ps1 |
| `Get-HermesMargin` | line_components.ps1 |
| `Get-HermesStyle` | line_components.ps1 |
| `Read-HermesHost` | line_components.ps1 |
| `Read-HermesKey` | line_components.ps1 |
| `Resolve-HermesSegmentColor` | line_components.ps1 |
| `Resolve-HermesStyleValue` | line_components.ps1 |
| `Resolve-UILocaleName` | Localization.ps1 |
| `Split-ConsoleTextLine` | text_components.ps1 |
| `Add-ConsoleTreeLine` | visual_components.ps1 |
| `Format-TableCell` | visual_components.ps1 |
| `Get-ColumnValue` | visual_components.ps1 |
| `Resolve-TableColumn` | visual_components.ps1 |
