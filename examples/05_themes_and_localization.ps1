<#
.SYNOPSIS
    PSConsoleUI - Themes and Localization Demo
    
.DESCRIPTION
    Demonstrates the new internationalization and theme switching capabilities
    of PSConsoleUI framework.
#>

# Import the module
Import-Module "$PSScriptRoot\..\PSConsoleUI.psd1" -Force

Write-Host "`n"
Write-ConsoleTitle -Title "PSConsoleUI - Themes & Localization Demo"

# ===== THEME DEMONSTRATION =====
Write-ConsoleHeader -Text "Theme Demonstration"

Write-ConsoleInfo -Message "Available themes: $(Get-AvailableThemes -join ', ')"
Write-Host ""

# Default Theme
Write-ConsoleSubtitle -Text "Default Theme"
Write-ConsoleStatus -Message "This is a success message" -Type "Success"
Write-ConsoleStatus -Message "This is a warning message" -Type "Warning"
Write-ConsoleStatus -Message "This is an error message" -Type "Error"
Write-ConsoleStatus -Message "This is an info message" -Type "Info"
Write-ConsoleChart -Label "Progress" -Value 75 -Max 100
Write-Host ""

# Cyberpunk Theme
Set-ConsoleTheme -ThemeName "Cyberpunk"
Write-ConsoleSubtitle -Text "Cyberpunk Theme"
Write-ConsoleStatus -Message "This is a success message" -Type "Success"
Write-ConsoleStatus -Message "This is a warning message" -Type "Warning"
Write-ConsoleStatus -Message "This is an error message" -Type "Error"
Write-ConsoleStatus -Message "This is an info message" -Type "Info"
Write-ConsoleChart -Label "Progress" -Value 75 -Max 100
Write-Host ""

# Classic Theme
Set-ConsoleTheme -ThemeName "Classic"
Write-ConsoleSubtitle -Text "Classic Theme"
Write-ConsoleStatus -Message "This is a success message" -Type "Success"
Write-ConsoleStatus -Message "This is a warning message" -Type "Warning"
Write-ConsoleStatus -Message "This is an error message" -Type "Error"
Write-ConsoleStatus -Message "This is an info message" -Type "Info"
Write-ConsoleChart -Label "Progress" -Value 75 -Max 100
Write-Host ""

# Custom Theme
Set-ConsoleTheme -ThemeName "Custom" -CustomColors @{
    Primary = "DarkCyan"
    Success = "DarkGreen"
    Warning = "DarkYellow"
    Error = "DarkRed"
    Info = "DarkMagenta"
}
Write-ConsoleSubtitle -Text "Custom Theme (Dark Colors)"
Write-ConsoleStatus -Message "This is a success message" -Type "Success"
Write-ConsoleStatus -Message "This is a warning message" -Type "Warning"
Write-ConsoleStatus -Message "This is an error message" -Type "Error"
Write-ConsoleStatus -Message "This is an info message" -Type "Info"
Write-ConsoleChart -Label "Progress" -Value 75 -Max 100
Write-Host ""

# Reset to default
Set-ConsoleTheme -ThemeName "Default"

# ===== LOCALIZATION DEMONSTRATION =====
Write-ConsoleHeader -Text "Localization Demonstration"

Write-ConsoleInfo -Message "Available locales: $(Get-AvailableLocales -join ', ')"
Write-ConsoleInfo -Message "Current locale: $(Get-UILocale)"
Write-Host ""

# English
Write-ConsoleSubtitle -Text "English (en-US)"
$menuPrompt = Get-LocalizedString -Key "Menu.SelectPrompt" -Locale "en-US"
$exitPrompt = Get-LocalizedString -Key "Menu.ExitPrompt" -Locale "en-US"
Write-ConsoleInfo -Message "Menu prompt: $menuPrompt"
Write-ConsoleInfo -Message "Exit prompt: $exitPrompt"
Write-Host ""

# Spanish
Write-ConsoleSubtitle -Text "Spanish (es-ES)"
$menuPrompt = Get-LocalizedString -Key "Menu.SelectPrompt" -Locale "es-ES"
$exitPrompt = Get-LocalizedString -Key "Menu.ExitPrompt" -Locale "es-ES"
Write-ConsoleInfo -Message "Menu prompt: $menuPrompt"
Write-ConsoleInfo -Message "Exit prompt: $exitPrompt"
Write-Host ""

# French
Write-ConsoleSubtitle -Text "French (fr-FR)"
$menuPrompt = Get-LocalizedString -Key "Menu.SelectPrompt" -Locale "fr-FR"
$exitPrompt = Get-LocalizedString -Key "Menu.ExitPrompt" -Locale "fr-FR"
Write-ConsoleInfo -Message "Menu prompt: $menuPrompt"
Write-ConsoleInfo -Message "Exit prompt: $exitPrompt"
Write-Host ""

# ===== VISUAL COMPONENTS =====
Write-ConsoleHeader -Text "Visual Components"

# Box
Write-ConsoleBox -Message "This is a boxed message!"

# Tree
$treeData = @{
    "Root" = @{
        "Branch 1" = @("Leaf 1", "Leaf 2")
        "Branch 2" = @("Leaf 3", "Leaf 4")
    }
}
Write-ConsoleSubtitle -Text "Tree Structure"
Write-ConsoleTree -TreeData $treeData
Write-Host ""

# Table
$tableData = @(
    [PSCustomObject]@{ Name = "Item 1"; Status = "Success"; Value = 100 }
    [PSCustomObject]@{ Name = "Item 2"; Status = "Warning"; Value = 75 }
    [PSCustomObject]@{ Name = "Item 3"; Status = "Error"; Value = 50 }
)
$columns = @(
    @{ Header = "Name"; Property = "Name"; Width = 20; Align = "Left" }
    @{ Header = "Status"; Property = "Status"; Width = 15; Align = "Left" }
    @{ Header = "Value"; Property = "Value"; Width = 10; Align = "Right" }
)
Write-ConsoleTable -Data $tableData -Columns $columns -Title "Sample Table" `
    -ColorMapProperty "Status" -ColorMap @{
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
    }

# Summary
$summaryItems = @(
    @{ Label = "Total Items"; Value = 3; Color = "Cyan" }
    @{ Label = "Successful"; Value = 1; Color = "Green" }
    @{ Label = "Warnings"; Value = 1; Color = "Yellow" }
    @{ Label = "Errors"; Value = 1; Color = "Red" }
)
Write-ConsoleSummary -Title "Summary Statistics" -Items $summaryItems

# Metadata
$metadata = @{
    "Module" = "PSConsoleUI"
    "Version" = "2.0.0"
    "Author" = "PSConsoleUI Project"
    "Theme" = Get-ConsoleTheme
    "Locale" = Get-UILocale
}
Write-ConsoleMetadata -Metadata $metadata -Title "Module Information"

# Diff
Write-ConsoleDiff -Label "Module Name" -OldValue "CassielUI" -NewValue "PSConsoleUI"

Write-ConsoleTitle -Title "Demo Complete!"
Write-ConsoleStatus -Message "PSConsoleUI is ready to use!" -Type "Success"
Write-Host ""
