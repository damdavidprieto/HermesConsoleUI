<#
.SYNOPSIS
    Demonstrates pipeline support in PSConsoleUI
    
.DESCRIPTION
    Shows how to use PSConsoleUI functions with PowerShell pipeline for
    seamless integration with Get-Process, Get-Service, and other cmdlets.
#>

# Import the module
Import-Module "$PSScriptRoot\..\PSConsoleUI.psd1" -Force

Write-ConsoleTitle -Title "PSConsoleUI - Pipeline Support Demo"

# ===== PIPELINE WITH WRITE-CONSOLETABLE =====
Write-ConsoleHeader -Text "Pipeline with Write-ConsoleTable"

# Example 1: Auto-detect columns from Get-Process
Write-ConsoleSubtitle -Text "Processes (Auto Columns)"
Get-Process | Select-Object -First 10 | Write-ConsoleTable -AutoColumns

# Example 2: Custom columns with Get-Service
Write-ConsoleSubtitle -Text "Services (Custom Columns with Color)"
$cols = @(
    @{Header="Service Name"; Property="Name"; Width=30; Align="Left"}
    @{Header="Status"; Property="Status"; Width=15; Align="Left"}
    @{Header="Display Name"; Property="DisplayName"; Width=40; Align="Left"}
)
Get-Service | Select-Object -First 15 | Write-ConsoleTable -Columns $cols `
    -ColorMapProperty "Status" `
    -ColorMap @{"Running"="Green"; "Stopped"="Red"}

# Example 3: File system objects
Write-ConsoleSubtitle -Text "Files in Current Directory"
Get-ChildItem -File | Select-Object -First 10 | Write-ConsoleTable -AutoColumns

# ===== PIPELINE WITH WRITE-CONSOLESTATUS =====
Write-ConsoleHeader -Text "Pipeline with Write-ConsoleStatus"

# Example 1: Multiple success messages
Write-ConsoleSubtitle -Text "Task Completion Messages"
@("Database backup completed", "Log rotation completed", "Cache cleared") | 
    Write-ConsoleStatus -Type Success

# Example 2: Mixed status messages
Write-ConsoleSubtitle -Text "System Check Results"
$checks = @(
    @{Message="Disk space: OK"; Type="Success"}
    @{Message="Memory usage: High"; Type="Warning"}
    @{Message="Service stopped: Critical"; Type="Error"}
    @{Message="Network: Connected"; Type="Info"}
)

foreach ($check in $checks) {
    Write-ConsoleStatus -Message $check.Message -Type $check.Type
}

# ===== PIPELINE WITH WRITE-CONSOLEINFO =====
Write-ConsoleHeader -Text "Pipeline with Write-ConsoleInfo"

# Example: Log messages
@("Starting process...", "Loading configuration...", "Connecting to database...") | 
    Write-ConsoleInfo

# ===== PIPELINE WITH WRITE-CONSOLEERROR =====
Write-ConsoleHeader -Text "Pipeline with Write-ConsoleError"

# Example: Error messages
@("Failed to connect to server", "Invalid credentials", "Timeout exceeded") | 
    Write-ConsoleError

# ===== REAL-WORLD EXAMPLE =====
Write-ConsoleHeader -Text "Real-World Example: System Health Check"

Write-ConsoleSubtitle -Text "Running System Diagnostics..."

# Check services
$criticalServices = @("wuauserv", "BITS", "Winmgmt")
$serviceStatus = Get-Service -Name $criticalServices -ErrorAction SilentlyContinue

$serviceStatus | ForEach-Object {
    $type = if ($_.Status -eq "Running") { "Success" } else { "Error" }
    Write-ConsoleStatus -Message "$($_.DisplayName): $($_.Status)" -Type $type
}

Write-Host ""

# Display in table
Write-ConsoleSubtitle -Text "Service Details"
$serviceStatus | Write-ConsoleTable -AutoColumns

Write-ConsoleTitle -Title "Demo Complete!"
Write-ConsoleStatus -Message "Pipeline support is working!" -Type "Success"
Write-Host ""
