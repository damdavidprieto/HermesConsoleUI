# Test Show-ConsoleProgress function
Import-Module (Join-Path $PSScriptRoot "..\HermesConsoleUI.psd1") -Force

Write-Host "`n=== PRUEBA DE SHOW-CONSOLEPROGRESS ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Progress at 0%
Show-ConsoleProgress -Activity "Iniciando proceso..." -PercentComplete 0

# Test 2: Progress at 25%
Show-ConsoleProgress -Activity "Instalando paquetes..." -PercentComplete 25

# Test 3: Progress at 50%
Show-ConsoleProgress -Activity "Descargando archivos..." -PercentComplete 50 -Color Green

# Test 4: Progress at 75%
Show-ConsoleProgress -Activity "Configurando sistema..." -PercentComplete 75 -Color Yellow

# Test 5: Progress at 100%
Show-ConsoleProgress -Activity "Finalizando..." -PercentComplete 100 -Color Green

# Test 6: Custom bar length
Write-Host ""
Write-Host "Con barra mas larga (40 caracteres):" -ForegroundColor Cyan
Show-ConsoleProgress -Activity "Proceso largo..." -PercentComplete 80 -BarLength 40

Write-Host ""
Write-Host "=== PRUEBA COMPLETADA ===" -ForegroundColor Green
Write-Host ""
