# ============================================================================
# Example 3: Data Visualization - Console UI Library
# ============================================================================
# This example demonstrates tables, trees, and charts
# ============================================================================

# Load the library
$LibPath = Split-Path -Parent $PSScriptRoot
. "$LibPath\console_manager.ps1"

Clear-Host
Write-ConsoleTitle -Title "DATA VISUALIZATION DEMO"

# 1. Table Example
Write-ConsoleHeader -Text "Service Status Table"

$services = @(
    @{ Name = "Web Server"; Status = "Running"; Port = 80; CPU = "2%" }
    @{ Name = "Database"; Status = "Running"; Port = 3306; CPU = "15%" }
    @{ Name = "Cache"; Status = "Stopped"; Port = 6379; CPU = "0%" }
    @{ Name = "Message Queue"; Status = "Running"; Port = 5672; CPU = "5%" }
)

$columns = @(
    @{ Header = "Service"; Property = "Name"; Width = 20; Align = "Left" }
    @{ Header = "Status"; Property = "Status"; Width = 12; Align = "Center" }
    @{ Header = "Port"; Property = "Port"; Width = 8; Align = "Right" }
    @{ Header = "CPU"; Property = "CPU"; Width = 8; Align = "Right" }
)

$colorMap = @{
    "Running" = "Green"
    "Stopped" = "Red"
}

Write-ConsoleTable -Data $services -Columns $columns -Title "Active Services" -ColorMapProperty "Status" -ColorMap $colorMap

# 2. Tree Example
Write-ConsoleHeader -Text "Directory Structure"

$tree = @{
    "Application" = @{
        "Config" = @("app.config", "database.config")
        "Logs" = @{
            "Current" = @("app.log", "error.log")
            "Archive" = @("2026-01-11.log", "2026-01-10.log")
        }
        "Data" = @("users.db", "cache.db")
    }
}

Write-ConsoleTree -TreeData $tree

# 3. Multiple Charts
Write-ConsoleHeader -Text "Resource Usage"

Write-ConsoleChart -Label "CPU Core 1" -Value 45 -Max 100 -Color "Green"
Write-ConsoleChart -Label "CPU Core 2" -Value 67 -Max 100 -Color "Yellow"
Write-ConsoleChart -Label "CPU Core 3" -Value 89 -Max 100 -Color "Red"
Write-ConsoleChart -Label "CPU Core 4" -Value 23 -Max 100 -Color "Green"

Write-Host ""
Write-ConsoleChart -Label "Memory (RAM)" -Value 6144 -Max 8192 -Color "Yellow"
Write-ConsoleChart -Label "Disk C:" -Value 450 -Max 500 -Color "Red"
Write-ConsoleChart -Label "Disk D:" -Value 120 -Max 1000 -Color "Green"

# 4. Progress Simulation
Write-ConsoleHeader -Text "Progress Tracking"

for ($i = 0; $i -le 100; $i += 10) {
    Write-ConsoleProgress -Activity "Processing files" -Percent $i
    Start-Sleep -Milliseconds 300
}

Write-ConsoleStatus -Message "All visualizations complete" -Type "Success"

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host

