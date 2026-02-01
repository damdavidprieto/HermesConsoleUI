# Diagnostic script to show the problem
Write-Host "`n=== DIAGNOSTIC: Separator Issue ===" -ForegroundColor Red

Write-Host "`n1. Files in modules/ directory:" -ForegroundColor Yellow
Get-ChildItem "C:\test\Cassiel\scripts\Libs\PSConsoleUI\modules\" | Select-Object Name, Length, LastWriteTime | Format-Table

Write-Host "`n2. Content of text_components.ps1 (line 432):" -ForegroundColor Yellow
Get-Content "C:\test\Cassiel\scripts\Libs\PSConsoleUI\modules\text_components.ps1" -TotalCount 432 | Select-Object -Last 1

Write-Host "`n3. Content of text_components.psm1 (line 432) if exists:" -ForegroundColor Yellow
if (Test-Path "C:\test\Cassiel\scripts\Libs\PSConsoleUI\modules\text_components.psm1") {
    Get-Content "C:\test\Cassiel\scripts\Libs\PSConsoleUI\modules\text_components.psm1" -TotalCount 432 | Select-Object -Last 1
} else {
    Write-Host "  File does not exist (GOOD!)" -ForegroundColor Green
}

Write-Host "`n4. Testing separator directly:" -ForegroundColor Yellow
Remove-Module PSConsoleUI -Force -ErrorAction SilentlyContinue
Import-Module "C:\test\Cassiel\scripts\Libs\PSConsoleUI\PSConsoleUI.psd1" -Force
Write-Host "  Expected: ------------------------------------------------------------"
Write-Host -NoNewline "  Actual:   "
Write-ConsoleSeparator -Length 60

Write-Host "`n=== END DIAGNOSTIC ===" -ForegroundColor Red
