# HermesConsoleUI v2.0.1 - Demo Interactivo Completo
# Muestra TODOS los componentes: visuales + interactivos

Import-Module "C:\test\HermesConsoleUI\HermesConsoleUI.psd1" -Force

# Clear-Host
Write-Host "`n`n"
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "  HermesConsoleUI v2.0.1 - DEMO INTERACTIVO COMPLETO" -ForegroundColor Cyan
Write-Host "  Mostraron TODOS los componentes (40 funciones)" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este demo incluye componentes que requieren tu interaccion." -ForegroundColor Yellow
Write-Host "Presiona ENTER para continuar..." -ForegroundColor Gray
Read-Host

# ===== PARTE 1: COMPONENTES VISUALES (18) =====

# Clear-Host
Write-Host "`n=== PARTE 1: COMPONENTES VISUALES (18) ===" -ForegroundColor Green
Write-Host "Presiona ENTER para comenzar..." -ForegroundColor Gray
Read-Host

# 1. Write-ConsoleTitle
# Clear-Host
Write-Host "`n[1/34] Write-ConsoleTitle" -ForegroundColor Yellow
Write-ConsoleTitle -Title "DEMO COMPLETO HermesConsoleUI"
Read-Host "Presiona ENTER para continuar"

# 2. Write-ConsoleHeader
# Clear-Host
Write-Host "`n[2/34] Write-ConsoleHeader" -ForegroundColor Yellow
Write-ConsoleHeader -Text "Seccion Principal"
Read-Host "Presiona ENTER para continuar"

# 3. Write-ConsoleSubtitle
# Clear-Host
Write-Host "`n[3/34] Write-ConsoleSubtitle" -ForegroundColor Yellow
Write-ConsoleSubtitle -Text "Items Procesados" -Count 42
Read-Host "Presiona ENTER para continuar"

# 4. Write-ConsoleStatus
# Clear-Host
Write-Host "`n[4/34] Write-ConsoleStatus" -ForegroundColor Yellow
Write-ConsoleStatus -Message "Operacion exitosa" -Type Success
Write-ConsoleStatus -Message "Advertencia detectada" -Type Warning
Write-ConsoleStatus -Message "Error encontrado" -Type Error
Write-ConsoleStatus -Message "Procesando datos" -Type Info
Read-Host "Presiona ENTER para continuar"

# 5. Write-ConsoleError
# Clear-Host
Write-Host "`n[5/34] Write-ConsoleError" -ForegroundColor Yellow
Write-ConsoleError -Message "Fallo en la conexion"
Read-Host "Presiona ENTER para continuar"

# 6. Write-ConsoleInfo
# Clear-Host
Write-Host "`n[6/34] Write-ConsoleInfo" -ForegroundColor Yellow
Write-ConsoleInfo -Message "Cargando configuracion..."
Read-Host "Presiona ENTER para continuar"

# 7. Write-ConsoleMetadata
# Clear-Host
Write-Host "`n[7/34] Write-ConsoleMetadata" -ForegroundColor Yellow
$metadata = @{
    "Version" = "2.0.0"
    "Autor" = "David Prieto"
    "Licencia" = "MIT"
}
Write-ConsoleMetadata -Metadata $metadata -Title "Informacion del Modulo"
Read-Host "Presiona ENTER para continuar"

# 8. Write-ConsoleSummary
# Clear-Host
Write-Host "`n[8/34] Write-ConsoleSummary" -ForegroundColor Yellow
Write-ConsoleSummary -Title "Resumen de Operaciones" -Items @(
    "Total procesado: 100",
    "Exitosos: 95",
    "Fallidos: 5"
)
Read-Host "Presiona ENTER para continuar"

# 9. Write-ConsoleDiff
# Clear-Host
Write-Host "`n[9/34] Write-ConsoleDiff" -ForegroundColor Yellow
Write-ConsoleDiff -Label "Version" -OldValue "1.0.0" -NewValue "2.0.0"
Read-Host "Presiona ENTER para continuar"

# 10. Write-ConsoleChart
# Clear-Host
Write-Host "`n[10/34] Write-ConsoleChart" -ForegroundColor Yellow
Write-ConsoleChart -Label "Uso de CPU" -Value 75 -Max 100 -Color Green
Write-ConsoleChart -Label "Uso de RAM" -Value 60 -Max 100 -Color Yellow
Read-Host "Presiona ENTER para continuar"

# 11. Write-ConsoleSparkline
# Clear-Host
Write-Host "`n[11/34] Write-ConsoleSparkline" -ForegroundColor Yellow
Write-Host "Tendencia (ultimas 24h): " -NoNewline
Write-ConsoleSparkline -Data @(45, 52, 48, 65, 70, 68, 55, 50, 47, 60, 75, 80) -Color Cyan
Read-Host "Presiona ENTER para continuar"

# 12. Write-ConsolePanel
# Clear-Host
Write-Host "`n[12/34] Write-ConsolePanel" -ForegroundColor Yellow
Write-ConsolePanel -Title "Panel de Informacion" -BorderStyle Rounded -Color Cyan -Content {
    Write-Host "  Linea 1: Contenido del panel"
    Write-Host "  Linea 2: Mas informacion"
    Write-Host "  Linea 3: Datos adicionales"
}
Read-Host "Presiona ENTER para continuar"

# 13. Write-ConsoleBox
# Clear-Host
Write-Host "`n[13/34] Write-ConsoleBox" -ForegroundColor Yellow
Write-ConsoleBox -Message "Mensaje importante!" -Color Yellow
Read-Host "Presiona ENTER para continuar"

# 14. Write-ConsoleTree
# Clear-Host
Write-Host "`n[14/34] Write-ConsoleTree" -ForegroundColor Yellow
$tree = @{
    "Raiz" = @{
        "Carpeta1" = @("archivo1.txt", "archivo2.txt")
        "Carpeta2" = @("archivo3.txt")
    }
}
Write-ConsoleTree -TreeData $tree
Read-Host "Presiona ENTER para continuar"

# 15. Show-ConsoleList
# Clear-Host
Write-Host "`n[15/34] Show-ConsoleList" -ForegroundColor Yellow
Show-ConsoleList -Items @("Item 1", "Item 2", "Item 3") -Numbered -Color Green
Read-Host "Presiona ENTER para continuar"

# 16. Write-ConsoleSeparator
# Clear-Host
Write-Host "`n[16/34] Write-ConsoleSeparator" -ForegroundColor Yellow
Write-Host "Seccion A" -ForegroundColor Cyan
Write-ConsoleSeparator -Length 60
Write-Host "Seccion B" -ForegroundColor Cyan
Read-Host "Presiona ENTER para continuar"

# 17. Write-ConsoleBreadcrumb
# Clear-Host
Write-Host "`n[17/34] Write-ConsoleBreadcrumb" -ForegroundColor Yellow
Write-ConsoleBreadcrumb -Path @("Home", "Configuracion", "Avanzado")
Read-Host "Presiona ENTER para continuar"

# 18. Write-ConsoleTable
# Clear-Host
Write-Host "`n[18/34] Write-ConsoleTable" -ForegroundColor Yellow
$data = @(
    @{ Nombre = "Item1"; Estado = "Activo"; Valor = "100" }
    @{ Nombre = "Item2"; Estado = "Inactivo"; Valor = "50" }
)
$columns = @(
    @{ Header = "Nombre"; Property = "Nombre"; Width = 15 }
    @{ Header = "Estado"; Property = "Estado"; Width = 12 }
    @{ Header = "Valor"; Property = "Valor"; Width = 10 }
)
Write-ConsoleTable -Data $data -Columns $columns
Read-Host "Presiona ENTER para continuar"

# ===== PARTE 2: COMPONENTES INTERACTIVOS (10) =====

# Clear-Host
Write-Host "`n`n=== PARTE 2: COMPONENTES INTERACTIVOS (10) ===" -ForegroundColor Green
Write-Host "Estos componentes requieren tu interaccion." -ForegroundColor Yellow
Write-Host "Presiona ENTER para comenzar..." -ForegroundColor Gray
Read-Host

# 19. Show-ConsoleMenu
# Clear-Host
Write-Host "`n[19/34] Show-ConsoleMenu" -ForegroundColor Yellow
$count = Show-ConsoleMenu -Title "Menu de Ejemplo" -Options @(
    "Opcion 1",
    "Opcion 2",
    "Opcion 3"
) -Footer "Selecciona una opcion"
Write-Host "`nMenu mostrado con $count opciones seleccionables" -ForegroundColor Green
Read-Host "Presiona ENTER para continuar"

# 20. Read-ConsoleChoice
# Clear-Host
Write-Host "`n[20/34] Read-ConsoleChoice" -ForegroundColor Yellow
Write-Host "Opciones disponibles:" -ForegroundColor Cyan
Write-Host "  1. Primera opcion"
Write-Host "  2. Segunda opcion"
Write-Host "  3. Tercera opcion"
$choice = Read-ConsoleChoice -MaxChoice 3 -Prompt "Selecciona una opcion (1-3)" -AllowZero $false
Write-Host "`nSeleccionaste la opcion: $choice" -ForegroundColor Green
Read-Host "Presiona ENTER para continuar"

# 21. Read-ConsoleMultiChoice
# Clear-Host
Write-Host "`n[21/34] Read-ConsoleMultiChoice" -ForegroundColor Yellow
$selected = Read-ConsoleMultiChoice -Options @("Opcion A", "Opcion B", "Opcion C") -Prompt "Selecciona opciones (separadas por coma, ej: 1,3)"
Write-Host "`nSeleccionaste: $($selected -join ', ')" -ForegroundColor Green
Read-Host "Presiona ENTER para continuar"

# 22. Read-ConsoleInput
# Clear-Host
Write-Host "`n[22/34] Read-ConsoleInput" -ForegroundColor Yellow
$input = Read-ConsoleInput -Prompt "Ingresa tu nombre"
Write-Host "`nHola, $input!" -ForegroundColor Green
Read-Host "Presiona ENTER para continuar"

# 23. Read-ConsoleConfirmation
# Clear-Host
Write-Host "`n[23/34] Read-ConsoleConfirmation" -ForegroundColor Yellow
$confirm = Read-ConsoleConfirmation -Message "Deseas continuar?"
if ($confirm) {
    Write-Host "`nConfirmado!" -ForegroundColor Green
} else {
    Write-Host "`nCancelado" -ForegroundColor Red
}
Read-Host "Presiona ENTER para continuar"

# 24. Read-ConsolePassword
# Clear-Host
Write-Host "`n[24/34] Read-ConsolePassword" -ForegroundColor Yellow
$password = Read-ConsolePassword -Prompt "Ingresa una contrasena (no se mostrara)"
Write-Host "`nContrasena capturada de forma segura" -ForegroundColor Green
Read-Host "Presiona ENTER para continuar"

# 25. Show-ConsoleNotification
# Clear-Host
Write-Host "`n[25/34] Show-ConsoleNotification" -ForegroundColor Yellow
Show-ConsoleNotification -Message "Operacion completada exitosamente" -Type "Success"
Read-Host "Presiona ENTER para continuar"

# 26. Invoke-ConsoleSpinner
# Clear-Host
Write-Host "`n[26/34] Invoke-ConsoleSpinner" -ForegroundColor Yellow
Write-Host "Simulando operacion con spinner..." -ForegroundColor Cyan
Invoke-ConsoleSpinner -Message "Procesando" -Action {
    Start-Sleep -Seconds 3
}
Read-Host "Presiona ENTER para continuar"

# 27. Write-ConsoleProgress
# Clear-Host
Write-Host "`n[27/34] Write-ConsoleProgress" -ForegroundColor Yellow
Write-Host "Simulando barra de progreso..." -ForegroundColor Cyan
for ($i = 0; $i -le 100; $i += 20) {
    Write-ConsoleProgress -Activity "Procesando archivos" -Percent $i
    Start-Sleep -Milliseconds 500
}
Write-Progress -Activity "Procesando archivos" -Completed
Write-Host "Progreso completado!" -ForegroundColor Green
Read-Host "Presiona ENTER para continuar"

# 28. Invoke-ConsoleMenu (menu completo con acciones)
# Clear-Host
Write-Host "`n[28/34] Invoke-ConsoleMenu (Menu Interactivo Completo)" -ForegroundColor Yellow
Write-Host "Este componente muestra un menu interactivo completo." -ForegroundColor Cyan
Write-Host "Selecciona '0' para salir del menu." -ForegroundColor Yellow
Read-Host "Presiona ENTER para abrir el menu"

$menuItems = @(
    @{ Label = "Ver informacion"; Action = { Write-Host "`nMostrando informacion..." -ForegroundColor Cyan } }
    @{ Label = "Ejecutar tarea"; Action = { Write-Host "`nEjecutando tarea..." -ForegroundColor Green } }
    @{ Label = "Configuracion"; Action = { Write-Host "`nAbriendo configuracion..." -ForegroundColor Yellow } }
)
Invoke-ConsoleMenu -Title "Menu de Ejemplo" -MenuItems $menuItems -Footer "Selecciona 0 para salir"

# ===== PARTE 3: FUNCIONES CORE (6) =====

# Clear-Host
Write-Host "`n`n=== PARTE 3: FUNCIONES CORE (6) ===" -ForegroundColor Green
Write-Host "Estas son funciones internas del framework." -ForegroundColor Yellow
Read-Host "Presiona ENTER para ver"

# 29-34. Core Functions
# Clear-Host
Write-Host "`n[29-34] Funciones Core" -ForegroundColor Yellow
Write-Host "`nEstas funciones gestionan la configuracion interna:" -ForegroundColor Cyan
Write-Host "  29. Initialize-UIConfig - Inicializa configuracion"
Write-Host "  30. Get-UIConfig - Obtiene configuracion actual"
Write-Host "  31. Get-UIColor - Obtiene color del tema"
Write-Host "  32. Get-UIIcon - Obtiene icono del tema"
Write-Host "  33. Set-ConsoleTheme - Cambia tema activo"
Write-Host "  34. Get-ConsoleTheme - Obtiene tema actual"
Write-Host "`nTema actual: $(Get-ConsoleTheme)" -ForegroundColor Green
Read-Host "Presiona ENTER para continuar a la nueva Seccion de Layout"

# ===== PARTE 4: SISTEMA DE LAYOUT (6) =====

# Clear-Host
Write-Host "`n`n=== PARTE 4: SISTEMA DE LAYOUT (6) ===" -ForegroundColor Green
Write-Host "Nueva arquitectura de rejillas y columnas paralelas." -ForegroundColor Yellow
Read-Host "Presiona ENTER para ver el motor de Layout en accion"

# 35-38. Layout Engine
Write-Host "`n[35-38] Motor de Layout y Grillas" -ForegroundColor Yellow
Write-Host "Renderizando componentes en paralelo (45% | 55%):" -ForegroundColor Cyan

$list_data = Show-ConsoleList -Items @("CPU: Online", "Disk: Healthy") -ReturnLines -Width 20 -Bullet ">"
$box_data  = Write-ConsoleBox -Message "SISTEMA SEGURO" -Color Green -ReturnLines -Width 25

$demoRow = New-ConsoleRow -Columns @(
    (New-ConsoleColumn -Content $list_data -WidthPercent 45),
    (New-ConsoleColumn -Content $box_data  -WidthPercent 55)
)
$demoLayout = New-ConsoleLayout -Rows @($demoRow)
Write-ConsoleLayout -Layout $demoLayout -TotalWidth 60

# 39-40. Helpers
Write-Host "`n[39-40] Helpers de Captura" -ForegroundColor Yellow
Write-Host "  39. Set-LayoutBuffer - Fusiona lineas de texto"
Write-Host "  40. Invoke-CapturedOutput - Captura salida de comandos"
Read-Host "Presiona ENTER para finalizar"

# ===== RESUMEN FINAL =====

# Clear-Host
Write-Host "`n`n"
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "  DEMO COMPLETO FINALIZADO" -ForegroundColor Green
Write-Host "===================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Componentes demostrados: 40/40 (100%) - HermesConsoleUI v2.0.1 🏛️" -ForegroundColor Cyan
Write-Host ""
Write-Host "Desglose:" -ForegroundColor Yellow
Write-Host "  - Componentes visuales: 18" -ForegroundColor Cyan
Write-Host "  - Componentes interactivos: 10" -ForegroundColor Cyan
Write-Host "  - Funciones core: 6" -ForegroundColor Cyan
Write-Host "  - Sistema de Layout: 6" -ForegroundColor Cyan
Write-Host ""
Write-Host "HermesConsoleUI v2.0.1 - Framework completo y funcional!" -ForegroundColor Green
Write-Host ""
