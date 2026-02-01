<#
.SYNOPSIS
    PSConsoleUI - Demo Rápido
    
.DESCRIPTION
    Demostración visual de los componentes principales de PSConsoleUI.
#>

# Importar módulo
Import-Module "$PSScriptRoot\..\PSConsoleUI.psd1" -Force

Clear-Host

Write-Host "`n`n"
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  PSConsoleUI v2.0.0 - DEMO RÁPIDO" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`nDemostración de los componentes principales del framework.`n" -ForegroundColor Gray

Read-Host "Presiona ENTER para comenzar"
Clear-Host

# Verificar qué funciones están disponibles
$commands = Get-Command -Module PSConsoleUI
Write-Host "`n✓ Módulo cargado correctamente" -ForegroundColor Green
Write-Host "✓ Funciones disponibles: $($commands.Count)`n" -ForegroundColor Green

# Listar funciones disponibles
Write-Host "Funciones exportadas:" -ForegroundColor Yellow
$commands | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Cyan }

Write-Host "`n"
Read-Host "Presiona ENTER para continuar con la demo"
Clear-Host

# Demo de funciones disponibles
Write-Host "`n=== DEMO DE COMPONENTES ===" -ForegroundColor Cyan
Write-Host ""

# Si Write-ConsoleTitle está disponible
if (Get-Command Write-ConsoleTitle -ErrorAction SilentlyContinue) {
    Write-Host "[1] Write-ConsoleTitle" -ForegroundColor Yellow
    Write-ConsoleTitle -Title "SISTEMA DE AUDITORÍA"
    Start-Sleep -Seconds 2
}

# Si Write-ConsoleHeader está disponible
if (Get-Command Write-ConsoleHeader -ErrorAction SilentlyContinue) {
    Write-Host "`n[2] Write-ConsoleHeader" -ForegroundColor Yellow
    Write-ConsoleHeader -Text "Análisis de Seguridad"
    Start-Sleep -Seconds 2
}

# Si Write-ConsoleStatus está disponible
if (Get-Command Write-ConsoleStatus -ErrorAction SilentlyContinue) {
    Write-Host "`n[3] Write-ConsoleStatus" -ForegroundColor Yellow
    Write-ConsoleStatus -Message "Operación exitosa" -Type "Success"
    Write-ConsoleStatus -Message "Advertencia detectada" -Type "Warning"
    Write-ConsoleStatus -Message "Error encontrado" -Type "Error"
    Start-Sleep -Seconds 2
}

# Si Write-ConsoleChart está disponible
if (Get-Command Write-ConsoleChart -ErrorAction SilentlyContinue) {
    Write-Host "`n[4] Write-ConsoleChart" -ForegroundColor Yellow
    Write-ConsoleChart -Label "Uso de CPU" -Value 75 -Max 100
    Write-ConsoleChart -Label "Uso de RAM" -Value 60 -Max 100
    Start-Sleep -Seconds 2
}

# Si Write-ConsoleBox está disponible
if (Get-Command Write-ConsoleBox -ErrorAction SilentlyContinue) {
    Write-Host "`n[5] Write-ConsoleBox" -ForegroundColor Yellow
    Write-ConsoleBox -Message "¡Atención! Sistema requiere actualización"
    Start-Sleep -Seconds 2
}

# Si Write-ConsoleTable está disponible
if (Get-Command Write-ConsoleTable -ErrorAction SilentlyContinue) {
    Write-Host "`n[6] Write-ConsoleTable" -ForegroundColor Yellow
    $data = @(
        @{ Servicio = "Firewall"; Estado = "Running"; Puerto = "443" }
        @{ Servicio = "SSH"; Estado = "Stopped"; Puerto = "22" }
    )
    $columns = @(
        @{ Header = "Servicio"; Property = "Servicio"; Width = 20 }
        @{ Header = "Estado"; Property = "Estado"; Width = 12 }
        @{ Header = "Puerto"; Property = "Puerto"; Width = 10 }
    )
    Write-ConsoleTable -Data $data -Columns $columns
    Start-Sleep -Seconds 2
}

# Resumen final
Clear-Host
Write-Host "`n`n"
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  DEMO COMPLETADA" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host "`n✓ PSConsoleUI v2.0.0 está funcionando" -ForegroundColor Green
Write-Host "✓ $($commands.Count) funciones disponibles" -ForegroundColor Green
Write-Host "✓ Framework listo para usar`n" -ForegroundColor Green

Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Revisar ejemplos en carpeta examples/" -ForegroundColor Gray
Write-Host "  2. Leer documentación en docs/" -ForegroundColor Gray
Write-Host "  3. Integrar en tus proyectos" -ForegroundColor Gray
Write-Host "  4. Subir a GitHub`n" -ForegroundColor Gray

Write-Host "¡Gracias por probar PSConsoleUI!" -ForegroundColor Cyan
Write-Host ""
