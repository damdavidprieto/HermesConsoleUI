# Color themes and localized prompts.
# Components use the active theme unless you pass -Color; prompts follow the active locale.
# Run from the repository: .\examples\04-ThemesAndLocales.ps1

Import-Module (Join-Path $PSScriptRoot '..\HermesConsoleUI.psd1') -Force

foreach ($theme in Get-AvailableTheme | Sort-Object) {
    Set-ConsoleTheme -ThemeName $theme
    Write-ConsoleTitle -Title "Theme: $theme"
    Write-ConsoleStatus -Message 'Success color' -Type Success
    Write-ConsoleStatus -Message 'Warning color' -Type Warning
    Write-ConsoleChart -Label 'Primary' -Value 60
}

Set-ConsoleTheme -ThemeName Custom -CustomColors @{ Primary = 'DarkCyan'; Success = 'DarkGreen' }
Write-ConsoleTitle -Title 'Theme: Custom'
Set-ConsoleTheme -ThemeName Default

foreach ($locale in Get-AvailableLocale | Sort-Object) {
    Set-UILocale -Locale $locale
    Write-ConsoleInfo -Message "$locale -> $(Get-LocalizedString -Key 'Menu.SelectPrompt')"
}
Set-UILocale -Locale en-US
