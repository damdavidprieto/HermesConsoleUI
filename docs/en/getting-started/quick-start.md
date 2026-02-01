# PSConsoleUI - Quick Start Guide

Get up and running with PSConsoleUI in 5 minutes!

---

## 📦 Installation

### Option 1: Direct Import (Recommended)
```powershell
# Clone or download the repository
git clone https://github.com/yourusername/PSConsoleUI.git

# Import the module
Import-Module .\PSConsoleUI\PSConsoleUI.psd1
```

### Option 2: Install Script
```powershell
# Run the installation script
.\PSConsoleUI\Install.ps1
```

---

## 🚀 Your First Script

Create a file called `my-first-ui.ps1`:

```powershell
# Import the module
Import-Module PSConsoleUI

# Display a title
Write-ConsoleTitle -Title "MY FIRST APP"

# Show some status messages
Write-ConsoleStatus -Message "Starting application..." -Type "Info"
Write-ConsoleStatus -Message "Loading configuration..." -Type "Info"
Write-ConsoleStatus -Message "Ready!" -Type "Success"

# Display a chart
Write-ConsoleChart -Label "CPU Usage" -Value 45 -Max 100 -Color "Green"
Write-ConsoleChart -Label "Memory" -Value 6144 -Max 8192 -Color "Yellow"

# Show a box with a message
Write-ConsoleBox -Message "Welcome to PSConsoleUI!" -Color "Cyan"

# Display metadata
$info = @{
    "Version" = "2.0.1"
    "Author" = "Your Name"
    "Status" = "Running"
}
Write-ConsoleMetadata -Metadata $info -Title "Application Info"
```

Run it:
```powershell
.\my-first-ui.ps1
```

---

## 🎨 Using Themes

PSConsoleUI comes with 4 built-in themes:

```powershell
# Change theme
Set-ConsoleTheme -ThemeName "Cyberpunk"

# Available themes:
# - Default (blue/cyan)
# - Cyberpunk (magenta/cyan)
# - Classic (green/yellow)
# - Monochrome (gray scale)

# List all themes
Get-AvailableThemes
```

---

## 🌍 Using Localization

PSConsoleUI supports 3 languages out of the box:

```powershell
# Change language
Set-UILocale -Locale "es-ES"  # Spanish
Set-UILocale -Locale "fr-FR"  # French
Set-UILocale -Locale "en-US"  # English (default)

# Get localized strings
$yesText = Get-LocalizedString -Key "Common.Yes" -DefaultValue "Yes"
```

---

## 📊 Interactive Components

### Simple Menu
```powershell
$options = @("Option 1", "Option 2", "Option 3", "Exit")
$count = Show-ConsoleMenu -Title "MAIN MENU" -Options $options
$choice = Read-ConsoleChoice -MaxChoice $count

switch ($choice) {
    1 { Write-ConsoleStatus "You selected Option 1" -Type "Info" }
    2 { Write-ConsoleStatus "You selected Option 2" -Type "Info" }
    3 { Write-ConsoleStatus "You selected Option 3" -Type "Info" }
    4 { Write-ConsoleStatus "Goodbye!" -Type "Success" }
}
```

### User Input
```powershell
$name = Read-ConsoleInput -Prompt "Enter your name" -DefaultValue "User"
$confirmed = Read-ConsoleConfirmation -Prompt "Continue?"

if ($confirmed) {
    Write-ConsoleStatus "Hello, $name!" -Type "Success"
}
```

### Progress Bar
```powershell
for ($i = 0; $i -le 100; $i += 10) {
    Write-ConsoleProgress -Activity "Processing" -Percent $i
    Start-Sleep -Milliseconds 200
}
```

---

## 📋 Data Visualization

### Table
```powershell
$data = @(
    @{ Name = "Service1"; Status = "Running"; CPU = 45 }
    @{ Name = "Service2"; Status = "Stopped"; CPU = 0 }
    @{ Name = "Service3"; Status = "Running"; CPU = 78 }
)

$columns = @(
    @{ Header = "Name"; Property = "Name"; Width = 20 }
    @{ Header = "Status"; Property = "Status"; Width = 15 }
    @{ Header = "CPU %"; Property = "CPU"; Width = 10 }
)

Write-ConsoleTable -Data $data -Columns $columns
```

### Tree
```powershell
$tree = @{
    "Root" = @{
        "Folder1" = @("File1.txt", "File2.txt")
        "Folder2" = @("File3.txt")
    }
}

Write-ConsoleTree -TreeData $tree
```

---

## 📚 Next Steps

- **[Components Guide](../guides/components.md)** - Learn about all 40 functions
- **[Themes Guide](../guides/themes.md)** - Create custom themes
- **[Examples](../../examples/)** - See 8 complete examples
- **[API Reference](../reference/FUNCTION_MAP.md)** - Complete function reference

---

## 💡 Tips

1. **Use Get-Help** - All functions have complete help:
   ```powershell
   Get-Help Write-ConsoleStatus -Full
   ```

2. **Explore Examples** - Check the `examples/` folder for complete applications

3. **Customize Themes** - Edit `config/ui_config.json` to create your own theme

4. **Check the Demos** - Run `examples/00_DEMO_COMPLETO.ps1` to see all features

---

**Ready to build beautiful console UIs!** 🚀
