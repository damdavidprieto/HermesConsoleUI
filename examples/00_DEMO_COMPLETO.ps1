<#
.SYNOPSIS
    PSConsoleUI - Demo Completo de Todos los Componentes
    
.DESCRIPTION
    Demostración visual de los 29 componentes de PSConsoleUI con datos de prueba
    y explicaciones detalladas.
#>

# Importar módulo
Import-Module "$PSScriptRoot\..\PSConsoleUI.psd1" -Force

Clear-Host

# ============================================================================
# DEMO: COMPONENTES DE TEXTO (11 componentes)
# ============================================================================

Write-Host "`n`n"
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  PSConsoleUI v2.0.0 - DEMO COMPLETO DE COMPONENTES" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`nEsta demo muestra los 29 componentes disponibles con ejemplos visuales.`n" -ForegroundColor Gray

Read-Host "Presiona ENTER para comenzar"
Clear-Host

# --- 1. Write-ConsoleTitle ---
Write-Host "`n[1/29] Write-ConsoleTitle - Títulos centrados con bordes" -ForegroundColor Yellow
Write-ConsoleTitle -Title "SISTEMA DE AUDITORÍA" -Width 80
Write-Host "Uso: Write-ConsoleTitle -Title 'Texto' -Width 80`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 2. Write-ConsoleHeader ---
Write-Host "`n[2/29] Write-ConsoleHeader - Encabezados de sección" -ForegroundColor Yellow
Write-ConsoleHeader -Text "Análisis de Seguridad"
Write-Host "Uso: Write-ConsoleHeader -Text 'Sección'`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 3. Write-ConsoleSubtitle ---
Write-Host "`n[3/29] Write-ConsoleSubtitle - Subtítulos con contadores" -ForegroundColor Yellow
Write-ConsoleSubtitle -Text "Servicios Analizados" -Count 47
Write-Host "Uso: Write-ConsoleSubtitle -Text 'Subtítulo' -Count 47`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 4. Write-ConsoleStatus ---
Write-Host "`n[4/29] Write-ConsoleStatus - Mensajes de estado con iconos" -ForegroundColor Yellow
Write-ConsoleStatus -Message "Operación completada exitosamente" -Type "Success"
Write-ConsoleStatus -Message "Advertencia: Configuración no óptima" -Type "Warning"
Write-ConsoleStatus -Message "Error: Acceso denegado" -Type "Error"
Write-ConsoleStatus -Message "Información: Procesando datos" -Type "Info"
Write-Host "Uso: Write-ConsoleStatus -Message 'Texto' -Type Success|Warning|Error|Info`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# --- 5. Write-ConsoleError ---
Write-Host "`n[5/29] Write-ConsoleError - Mensajes de error destacados" -ForegroundColor Yellow
Write-ConsoleError -Message "No se pudo conectar al servidor remoto"
Write-Host "Uso: Write-ConsoleError -Message 'Error'`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 6. Write-ConsoleInfo ---
Write-Host "`n[6/29] Write-ConsoleInfo - Mensajes informativos" -ForegroundColor Yellow
Write-ConsoleInfo -Message "Escaneando 1,247 archivos en el sistema..."
Write-Host "Uso: Write-ConsoleInfo -Message 'Info'`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 7. Write-ConsoleMetadata ---
Write-Host "`n[7/29] Write-ConsoleMetadata - Pares clave-valor alineados" -ForegroundColor Yellow
$metadata = @{
    "Sistema Operativo" = "Windows 11 Pro"
    "PowerShell" = "7.4.1"
    "Última Actualización" = "2026-01-14"
}
Write-ConsoleMetadata -Metadata $metadata -Title "Información del Sistema"
Write-Host "Uso: Write-ConsoleMetadata -Metadata `$hashtable -Title 'Título'`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# --- 8. Write-ConsoleSummary ---
Write-Host "`n[8/29] Write-ConsoleSummary - Resúmenes con listas" -ForegroundColor Yellow
Write-ConsoleSummary -Title "Resumen de Análisis" -Items @(
    "Total de archivos: 1,247",
    "Archivos sospechosos: 3",
    "Tiempo de ejecución: 45 segundos"
)
Write-Host "Uso: Write-ConsoleSummary -Title 'Título' -Items @('Item1', 'Item2')`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# --- 9. Write-ConsoleDiff ---
Write-Host "`n[9/29] Write-ConsoleDiff - Comparaciones antes/después" -ForegroundColor Yellow
Write-ConsoleDiff -Label "Servicios vulnerables" -OldValue "12" -NewValue "0"
Write-Host "Uso: Write-ConsoleDiff -Label 'Etiqueta' -OldValue 'Antes' -NewValue 'Después'`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 10. Write-ConsoleSeparator ---
Write-Host "`n[10/29] Write-ConsoleSeparator - Líneas separadoras" -ForegroundColor Yellow
Write-ConsoleSeparator -Width 60 -Char "─"
Write-Host "Uso: Write-ConsoleSeparator -Width 60 -Char '─'`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 11. Write-ConsoleBreadcrumb ---
Write-Host "`n[11/29] Write-ConsoleBreadcrumb - Rutas de navegación" -ForegroundColor Yellow
Write-ConsoleBreadcrumb -Path @("Sistema", "Seguridad", "Firewall", "Reglas")
Write-Host "Uso: Write-ConsoleBreadcrumb -Path @('Nivel1', 'Nivel2', 'Nivel3')`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

Read-Host "`nPresiona ENTER para ver componentes visuales"
Clear-Host

# ============================================================================
# DEMO: COMPONENTES VISUALES (7 componentes)
# ============================================================================

Write-ConsoleHeader -Text "COMPONENTES VISUALES"

# --- 12. Show-ConsoleList ---
Write-Host "`n[12/29] Show-ConsoleList - Listas con bullets/números" -ForegroundColor Yellow
Show-ConsoleList -Items @("Firewall activo", "Antivirus actualizado", "Cifrado habilitado") -Numbered
Write-Host "Uso: Show-ConsoleList -Items @('Item1', 'Item2') -Numbered`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# --- 13. Write-ConsoleTree ---
Write-Host "`n[13/29] Write-ConsoleTree - Estructuras jerárquicas" -ForegroundColor Yellow
$tree = @{
    "Sistema" = @{
        "Servicios" = @("Windows Update", "Firewall")
        "Procesos" = @("svchost.exe", "explorer.exe")
    }
}
Write-ConsoleTree -TreeData $tree
Write-Host "Uso: Write-ConsoleTree -TreeData `$hashtable`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# --- 14. Write-ConsoleChart ---
Write-Host "`n[14/29] Write-ConsoleChart - Gráficos de barras horizontales" -ForegroundColor Yellow
Write-ConsoleChart -Label "Uso de CPU" -Value 75 -Max 100 -Color Green
Write-ConsoleChart -Label "Uso de RAM" -Value 60 -Max 100 -Color Yellow
Write-ConsoleChart -Label "Uso de Disco" -Value 90 -Max 100 -Color Red
Write-Host "Uso: Write-ConsoleChart -Label 'Métrica' -Value 75 -Max 100`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# --- 15. Write-ConsoleSparkline ---
Write-Host "`n[15/29] Write-ConsoleSparkline - Mini-gráficos inline" -ForegroundColor Yellow
Write-Host "Tendencia CPU (últimas 24h): " -NoNewline
Write-ConsoleSparkline -Data @(45, 52, 48, 65, 70, 68, 55, 50, 47, 60, 75, 80) -Color Cyan
Write-Host "Uso: Write-ConsoleSparkline -Data @(1,5,2,8,3,9)`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# --- 16. Write-ConsolePanel ---
Write-Host "`n[16/29] Write-ConsolePanel - Contenedores con bordes" -ForegroundColor Yellow
Write-ConsolePanel -Title "Información del Sistema" -BorderStyle Rounded -Color Cyan -Content {
    Write-Host "  CPU: Intel Core i7-9700K"
    Write-Host "  RAM: 32GB DDR4"
    Write-Host "  GPU: NVIDIA RTX 3080"
}
Write-Host "Uso: Write-ConsolePanel -Title 'Título' -Content { ... }`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# --- 17. Write-ConsoleBox ---
Write-Host "`n[17/29] Write-ConsoleBox - Cajas de mensaje simples" -ForegroundColor Yellow
Write-ConsoleBox -Message "¡Atención! Sistema requiere reinicio"
Write-Host "Uso: Write-ConsoleBox -Message 'Texto'`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 18. Write-ConsoleTable ---
Write-Host "`n[18/29] Write-ConsoleTable - Tablas formateadas" -ForegroundColor Yellow
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
if (Get-Command Write-ConsoleTable -ErrorAction SilentlyContinue) {
    Write-ConsoleTable -Data $data -Columns $columns
} else {
    Write-Host "(Write-ConsoleTable aun no esta disponible en esta version)" -ForegroundColor DarkYellow
}
Write-Host "Uso: Write-ConsoleTable -Data `$data -Columns `$columns`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

Read-Host "`nPresiona ENTER para ver componentes interactivos"
Clear-Host

# ============================================================================
# DEMO: COMPONENTES INTERACTIVOS (10 componentes)
# ============================================================================

Write-ConsoleHeader -Text "COMPONENTES INTERACTIVOS"

# --- 19. Show-ConsoleMenu ---
Write-Host "`n[19/29] Show-ConsoleMenu - Menús visuales" -ForegroundColor Yellow
$options = @("Opción 1", "Opción 2", "Opción 3")
Show-ConsoleMenu -Title "Menú de Ejemplo" -Options $options
Write-Host "`nUso: Show-ConsoleMenu -Title 'Menú' -Options @('Op1', 'Op2')`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 20. Read-ConsoleChoice ---
Write-Host "`n[20/29] Read-ConsoleChoice - Selección de opciones" -ForegroundColor Yellow
Write-Host "Ejemplo: `$choice = Read-ConsoleChoice -Prompt '¿Continuar?' -Choices @('Sí', 'No')" -ForegroundColor DarkGray
Write-Host "(Demo no interactiva - requiere input del usuario)`n" -ForegroundColor Gray
Start-Sleep -Seconds 2

# --- 21. Read-ConsoleMultiChoice ---
Write-Host "`n[21/29] Read-ConsoleMultiChoice - Selección múltiple" -ForegroundColor Yellow
Write-Host "Ejemplo: `$choices = Read-ConsoleMultiChoice -Prompt 'Selecciona módulos' -Choices @('A', 'B', 'C')" -ForegroundColor DarkGray
Write-Host "(Demo no interactiva - requiere input del usuario)`n" -ForegroundColor Gray
Start-Sleep -Seconds 2

# --- 22. Invoke-ConsoleMenu ---
Write-Host "`n[22/29] Invoke-ConsoleMenu - Menús con acciones" -ForegroundColor Yellow
Write-Host "Ejemplo: Invoke-ConsoleMenu -Title 'Acciones' -MenuItems `$items" -ForegroundColor DarkGray
Write-Host "(Demo no interactiva - ejecuta acciones)`n" -ForegroundColor Gray
Start-Sleep -Seconds 2

# --- 23. Invoke-ConsoleSpinner ---
Write-Host "`n[23/29] Invoke-ConsoleSpinner - Indicador de progreso animado" -ForegroundColor Yellow
Write-Host "Ejecutando operación con spinner..." -ForegroundColor Cyan
$result = Invoke-ConsoleSpinner -Message "Procesando datos" -ScriptBlock {
    Start-Sleep -Seconds 3
    return "Operación completada"
}
Write-Host "Resultado: $result" -ForegroundColor Green
Write-Host "Uso: Invoke-ConsoleSpinner -Message 'Texto' -ScriptBlock { ... }`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 24. Write-ConsoleProgress ---
Write-Host "`n[24/29] Write-ConsoleProgress - Barras de progreso" -ForegroundColor Yellow
for ($i = 0; $i -le 100; $i += 20) {
    Write-ConsoleProgress -Activity "Descargando archivos" -Percent $i
    Start-Sleep -Milliseconds 500
}
Write-Host "`nUso: Write-ConsoleProgress -Activity 'Tarea' -Percent 50`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 25. Read-ConsoleInput ---
Write-Host "`n[25/29] Read-ConsoleInput - Input con valores por defecto" -ForegroundColor Yellow
Write-Host "Ejemplo: `$name = Read-ConsoleInput -Prompt 'Nombre' -Default 'Usuario'" -ForegroundColor DarkGray
Write-Host "(Demo no interactiva - requiere input del usuario)`n" -ForegroundColor Gray
Start-Sleep -Seconds 2

# --- 26. Read-ConsoleConfirmation ---
Write-Host "`n[26/29] Read-ConsoleConfirmation - Confirmaciones Sí/No" -ForegroundColor Yellow
Write-Host "Ejemplo: `$confirm = Read-ConsoleConfirmation -Prompt '¿Eliminar archivo?'" -ForegroundColor DarkGray
Write-Host "(Demo no interactiva - requiere input del usuario)`n" -ForegroundColor Gray
Start-Sleep -Seconds 2

# --- 27. Read-ConsolePassword ---
Write-Host "`n[27/29] Read-ConsolePassword - Input de contraseñas seguro" -ForegroundColor Yellow
Write-Host "Ejemplo: `$pwd = Read-ConsolePassword -Prompt 'Contraseña'" -ForegroundColor DarkGray
Write-Host "(Demo no interactiva - input enmascarado)`n" -ForegroundColor Gray
Start-Sleep -Seconds 2

# --- 28. Show-ConsoleNotification ---
Write-Host "`n[28/29] Show-ConsoleNotification - Notificaciones temporales" -ForegroundColor Yellow
Show-ConsoleNotification -Message "Operación completada exitosamente" -Type Success -Duration 2
Show-ConsoleNotification -Message "Advertencia: Revisa la configuración" -Type Warning -Duration 2
Show-ConsoleNotification -Message "Error: No se pudo conectar" -Type Error -Duration 2
Write-Host "Uso: Show-ConsoleNotification -Message 'Texto' -Type Success -Duration 3`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

Read-Host "`nPresiona ENTER para ver funciones core"
Clear-Host

# ============================================================================
# DEMO: FUNCIONES CORE (1 componente visible)
# ============================================================================

Write-ConsoleHeader -Text "FUNCIONES CORE Y TEMAS"

# --- 29. Set-ConsoleTheme ---
Write-Host "`n[29/29] Set-ConsoleTheme - Cambio de temas dinámico" -ForegroundColor Yellow
Write-Host "`nTema actual: Default" -ForegroundColor Cyan
Write-ConsoleStatus -Message "Mensaje con tema Default" -Type Success

Write-Host "`nCambiando a tema Cyberpunk..." -ForegroundColor Cyan
Set-ConsoleTheme -ThemeName "Cyberpunk"
Write-ConsoleStatus -Message "Mensaje con tema Cyberpunk" -Type Success

Write-Host "`nCambiando a tema Monochrome..." -ForegroundColor Cyan
Set-ConsoleTheme -ThemeName "Monochrome"
Write-ConsoleStatus -Message "Mensaje con tema Monochrome" -Type Success

Write-Host "`nRestaurando tema Default..." -ForegroundColor Cyan
Set-ConsoleTheme -ThemeName "Default"

Write-Host "`nUso: Set-ConsoleTheme -ThemeName 'Default|Cyberpunk|Classic|Monochrome'`n" -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# ============================================================================
# RESUMEN FINAL
# ============================================================================

Clear-Host
Write-ConsoleTitle -Title "DEMO COMPLETADA" -Width 80

Write-Host "`n"
Write-ConsolePanel -Title "Resumen de PSConsoleUI v2.0.0" -BorderStyle Double -Color Green -Content {
    Write-Host "  ✓ 29 componentes demostrados"
    Write-Host "  ✓ 11 componentes de texto"
    Write-Host "  ✓ 7 componentes visuales"
    Write-Host "  ✓ 10 componentes interactivos"
    Write-Host "  ✓ 1 sistema de temas"
    Write-Host ""
    Write-Host "  Framework: Zero dependencies"
    Write-Host "  i18n: Soporte multiidioma (EN, ES, FR)"
    Write-Host "  Temas: 4 predefinidos + custom"
    Write-Host "  Licencia: MIT"
}

Write-Host "`n"
Write-ConsoleSummary -Title "Próximos Pasos" -Items @(
    "1. Revisar ejemplos en carpeta examples/",
    "2. Leer documentación en docs/",
    "3. Integrar en tus proyectos",
    "4. Contribuir en GitHub (próximamente)"
)

Write-Host "`n"
Write-ConsoleStatus -Message "¡Gracias por probar PSConsoleUI!" -Type Success
Write-Host "`n"
