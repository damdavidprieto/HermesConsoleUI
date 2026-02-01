# ============================================================================
# Example 1: Basic Usage - Console UI Library
# ============================================================================
# This example demonstrates the most common UI components
# ============================================================================

# Load the library
$LibPath = Split-Path -Parent $PSScriptRoot
. "$LibPath\console_manager.ps1"

# Clear screen for clean demo
Clear-Host

# 1. Title
Write-ConsoleTitle -Title "Console UI LIBRARY - BASIC DEMO"

# 2. Header
Write-ConsoleHeader -Text "Getting Started"

# 3. Info messages
Write-ConsoleInfo -Message "This is an informational message"
Write-ConsoleInfo -Message "You can customize colors" -Color "Cyan"

# 4. Status messages
Write-ConsoleStatus -Message "Operation started" -Type "Info"
Start-Sleep -Seconds 1
Write-ConsoleStatus -Message "Processing data..." -Type "Info"
Start-Sleep -Seconds 1
Write-ConsoleStatus -Message "Warning: Low disk space" -Type "Warning"
Start-Sleep -Seconds 1
Write-ConsoleStatus -Message "Operation completed successfully" -Type "Success"

# 5. Box for important messages
Write-ConsoleBox -Message "IMPORTANT: Remember to save your work!" -Color "Yellow"

# 6. Charts for metrics
Write-ConsoleHeader -Text "System Metrics"
Write-ConsoleChart -Label "CPU Usage" -Value 45 -Max 100 -Color "Green"
Write-ConsoleChart -Label "Memory" -Value 6144 -Max 8192 -Color "Yellow"
Write-ConsoleChart -Label "Disk Space" -Value 850 -Max 1000 -Color "Red"

# 7. Metadata display
$metadata = @{
    "Version" = "1.0.0"
    "Author" = "Console Project"
    "Date" = Get-Date -Format "yyyy-MM-dd"
}
Write-ConsoleMetadata -Metadata $metadata -Title "Application Info"

# 8. Summary
$summaryItems = @(
    @{ Label = "Total Items"; Value = 150 }
    @{ Label = "Processed"; Value = 145; Color = "Green" }
    @{ Label = "Failed"; Value = 5; Color = "Red" }
)
Write-ConsoleSummary -Title "Execution Summary" -Items $summaryItems

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host

