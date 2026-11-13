<#
.SYNOPSIS
    Demo of all 5 new Priority 1 components in PSConsoleUI

.DESCRIPTION
    Demonstrates the new components added in v2.0.0:
    - Write-ConsoleSeparator
    - Write-ConsoleBreadcrumb
    - Show-ConsoleList
    - Read-ConsolePassword
    - Show-ConsoleNotification
#>

# Import the module
Import-Module "$PSScriptRoot\..\PSConsoleUI.psd1" -Force

# Demo Title
Write-ConsoleTitle -Title "PSConsoleUI v2.0.0 - New Components Demo"

# 1. Separator Demo
Write-ConsoleHeader -Text "1. Separator Component"
Write-Host "  Default separator:" -ForegroundColor Gray
Write-ConsoleSeparator

Write-Host "`n  Custom separator (equals, cyan):" -ForegroundColor Gray
Write-ConsoleSeparator -Character "=" -Color Cyan

Write-Host "`n  Short separator:" -ForegroundColor Gray
Write-ConsoleSeparator -Character "-" -Length 30 -Color Yellow

# 2. Breadcrumb Demo
Write-Host "`n"
Write-ConsoleHeader -Text "2. Breadcrumb Component"
Write-Host "  Navigation path:" -ForegroundColor Gray
Write-ConsoleBreadcrumb -Path @("Home", "Settings", "Display", "Advanced")

Write-Host "`n  File path:" -ForegroundColor Gray
Write-ConsoleBreadcrumb -Path @("C:", "Users", "Documents", "Projects") -Separator " / " -Color Cyan

# 3. List Demo
Write-Host "`n"
Write-ConsoleHeader -Text "3. List Component"
Write-Host "  Bulleted list:" -ForegroundColor Gray
Show-ConsoleList -Items @(
    "First item",
    "Second item",
    "Third item"
)

Write-Host "`n  Numbered list:" -ForegroundColor Gray
Show-ConsoleList -Items @(
    "Initialize system",
    "Load configuration",
    "Start services"
) -Numbered

Write-Host "`n  Custom bullet:" -ForegroundColor Gray
Show-ConsoleList -Items @(
    "Task completed",
    "All tests passed",
    "Ready for deployment"
) -Bullet "✓" -Color Green

# 4. Notification Demo
Write-Host "`n"
Write-ConsoleHeader -Text "4. Notification Component"
Write-Host "  Different notification types:" -ForegroundColor Gray
Show-ConsoleNotification -Message "Operation completed successfully" -Type Success
Show-ConsoleNotification -Message "Configuration loaded" -Type Info
Show-ConsoleNotification -Message "Low disk space detected" -Type Warning
Show-ConsoleNotification -Message "Connection failed" -Type Error

Write-Host "`n  Auto-dismiss notification (3 seconds):" -ForegroundColor Gray
Show-ConsoleNotification -Message "This message will disappear..." -Type Info -Duration 3
Show-ConsoleNotification -Message "Message dismissed!" -Type Success

# 5. Password Demo (Interactive)
Write-Host "`n"
Write-ConsoleHeader -Text "5. Password Component"
Write-Host "  Secure password input (demo - press Enter to skip):" -ForegroundColor Gray
Write-Host "  Note: Input is masked with asterisks" -ForegroundColor DarkGray

# Uncomment to test interactively:
# $securePassword = Read-ConsolePassword -Prompt "Enter password"
# Show-ConsoleNotification -Message "Password captured securely!" -Type Success

Write-Host "  [Demo mode - skipping interactive password input]" -ForegroundColor DarkGray

# Final Summary
Write-Host "`n"
Write-ConsoleSeparator -Character "=" -Color Cyan
Write-ConsoleTitle -Title "Demo Complete"
Write-ConsoleSeparator -Character "=" -Color Cyan

Write-Host "`n  Summary:" -ForegroundColor Cyan
Show-ConsoleList -Items @(
    "5 new components demonstrated",
    "All components working correctly",
    "Ready for production use"
) -Bullet "✓" -Color Green

Write-Host "`n  Component count:" -ForegroundColor Cyan
$componentCount = (Get-Command -Module PSConsoleUI).Count
Write-Host "  Total available: $componentCount functions" -ForegroundColor White

Write-ConsoleSeparator

Write-Host "`n  Press Enter to exit..." -ForegroundColor Gray
Read-Host
