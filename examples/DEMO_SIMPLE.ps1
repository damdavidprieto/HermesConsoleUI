# HermesConsoleUI - Demo Simple (Sin errores)
Import-Module "C:\test\HermesConsoleUI\HermesConsoleUI.psd1" -Force

Clear-Host

Write-Host "`n=== HermesConsoleUI v2.0.1 - DEMO VISUAL ===" -ForegroundColor Cyan
Write-Host ""

# 1. Write-ConsoleTitle
Write-Host "[1] Write-ConsoleTitle:" -ForegroundColor Yellow
Write-ConsoleTitle -Title "SISTEMA DE AUDITORIA"
Start-Sleep -Seconds 1

# 2. Write-ConsoleHeader
Write-Host "`n[2] Write-ConsoleHeader:" -ForegroundColor Yellow
Write-ConsoleHeader -Text "Analisis de Seguridad"
Start-Sleep -Seconds 1

# 3. Write-ConsoleSubtitle
Write-Host "`n[3] Write-ConsoleSubtitle:" -ForegroundColor Yellow
Write-ConsoleSubtitle -Text "Servicios Analizados" -Count 47
Start-Sleep -Seconds 1

# 4. Write-ConsoleStatus (con colores)
Write-Host "`n[4] Write-ConsoleStatus:" -ForegroundColor Yellow
Write-ConsoleStatus -Message "Operacion completada exitosamente" -Type "Success"
Write-ConsoleStatus -Message "Advertencia: Configuracion no optima" -Type "Warning"
Write-ConsoleStatus -Message "Error: Acceso denegado" -Type "Error"
Write-ConsoleStatus -Message "Informacion: Procesando datos" -Type "Info"
Start-Sleep -Seconds 2

# 5. Write-ConsoleError
Write-Host "`n[5] Write-ConsoleError:" -ForegroundColor Yellow
Write-ConsoleError -Message "No se pudo conectar al servidor remoto"
Start-Sleep -Seconds 1

# 6. Write-ConsoleInfo
Write-Host "`n[6] Write-ConsoleInfo:" -ForegroundColor Yellow
Write-ConsoleInfo -Message "Escaneando 1,247 archivos en el sistema..."
Start-Sleep -Seconds 1

# 7. Write-ConsoleMetadata
Write-Host "`n[7] Write-ConsoleMetadata:" -ForegroundColor Yellow
$metadata = @{
    "Sistema Operativo" = "Windows 11 Pro"
    "PowerShell" = "7.4.1"
    "Ultima Actualizacion" = "2026-01-14"
}
Write-ConsoleMetadata -Metadata $metadata -Title "Informacion del Sistema"
Start-Sleep -Seconds 2

# 8. Write-ConsoleSummary
Write-Host "`n[8] Write-ConsoleSummary:" -ForegroundColor Yellow
Write-ConsoleSummary -Title "Resumen de Analisis" -Items @(
    "Total de archivos: 1,247",
    "Archivos sospechosos: 3",
    "Tiempo de ejecucion: 45 segundos"
)
Start-Sleep -Seconds 2

# 9. Write-ConsoleDiff
Write-Host "`n[9] Write-ConsoleDiff:" -ForegroundColor Yellow
Write-ConsoleDiff -Label "Servicios vulnerables" -OldValue "12" -NewValue "0"
Start-Sleep -Seconds 1

# 10. Write-ConsoleSeparator
Write-Host "`n[10] Write-ConsoleSeparator:" -ForegroundColor Yellow
Write-ConsoleSeparator -Width 60
Start-Sleep -Seconds 1

# 11. Write-ConsoleBreadcrumb
Write-Host "`n[11] Write-ConsoleBreadcrumb:" -ForegroundColor Yellow
Write-ConsoleBreadcrumb -Path @("Sistema", "Seguridad", "Firewall", "Reglas")
Start-Sleep -Seconds 1

# 12. Write-ConsoleTable
Write-Host "`n[12] Write-ConsoleTable:" -ForegroundColor Yellow
$data = @(
    @{ Servicio = "Windows Update"; Estado = "Running"; Puerto = "443" }
    @{ Servicio = "Firewall"; Estado = "Running"; Puerto = "N/A" }
    @{ Servicio = "SSH"; Estado = "Stopped"; Puerto = "22" }
)
$columns = @(
    @{ Header = "Servicio"; Property = "Servicio"; Width = 20 }
    @{ Header = "Estado"; Property = "Estado"; Width = 12 }
    @{ Header = "Puerto"; Property = "Puerto"; Width = 10 }
)
Write-ConsoleTable -Data $data -Columns $columns
Start-Sleep -Seconds 2

# Resumen final
Write-Host "`n`n=== DEMO COMPLETADA ===" -ForegroundColor Green
Write-Host "HermesConsoleUI v2.0.1 funciona correctamente!" -ForegroundColor Green
Write-Host "34 funciones disponibles" -ForegroundColor Cyan
Write-Host ""
