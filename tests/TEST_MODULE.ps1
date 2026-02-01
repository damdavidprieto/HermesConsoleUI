# Test script to verify module loading
Import-Module "C:\test\Cassiel\scripts\Libs\PSConsoleUI\PSConsoleUI.psd1" -Force

Write-Host "Module loaded" -ForegroundColor Green
Write-Host "Total commands:" (Get-Command -Module PSConsoleUI).Count

Write-Host "`nTesting Write-ConsoleTitle..."
try {
    Write-ConsoleTitle -Title "TEST TITLE"
    Write-Host "SUCCESS!" -ForegroundColor Green
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
}

Write-Host "`nTesting Write-ConsoleStatus..."
try {
    Write-ConsoleStatus -Message "Test message" -Type Success
    Write-Host "SUCCESS!" -ForegroundColor Green
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
}

Write-Host "`nAll available commands:"
Get-Command -Module PSConsoleUI | Select-Object Name | Format-Table
