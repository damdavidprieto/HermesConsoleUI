# Force reload module and test separator
Remove-Module PSConsoleUI -Force -ErrorAction SilentlyContinue
Import-Module "C:\test\Cassiel\scripts\Libs\PSConsoleUI\PSConsoleUI.psd1" -Force

Write-Host "`n=== TEST SEPARATOR ===" -ForegroundColor Cyan
Write-Host "Seccion 1: Analisis de Red" -ForegroundColor Cyan
Write-ConsoleSeparator -Length 60
Write-Host "Seccion 2: Analisis de Servicios" -ForegroundColor Cyan
Write-ConsoleSeparator -Length 60
Write-Host "Seccion 3: Analisis de Archivos" -ForegroundColor Cyan
Write-Host "`n=== FIN TEST ===" -ForegroundColor Green
