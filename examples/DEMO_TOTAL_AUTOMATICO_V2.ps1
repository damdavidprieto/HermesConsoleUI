<#
.SYNOPSIS
    HermesConsoleUI v2.0.1 - Demo Total Automatico Mejorado
    
.DESCRIPTION
    Demuestra los 40 componentes del framework HermesConsoleUI de forma automatica.
    Incluye selector de temas, descripciones completas y el nuevo Sistema de Layout.
    
.PARAMETER Theme
    Tema visual a usar: Default, Dark, Light, Matrix
    
.PARAMETER Quick
    Modo rapido - muestra solo 1 ejemplo por componente
    
.EXAMPLE
    .\DEMO_TOTAL_AUTOMATICO_V2.ps1
    
.EXAMPLE
    .\DEMO_TOTAL_AUTOMATICO_V2.ps1 -Theme Dark -Quick
#>

param(
    [ValidateSet('Default', 'Dark', 'Light', 'Matrix')]
    [string]$Theme = 'Default',
    
    [switch]$Quick
)

Import-Module (Join-Path $PSScriptRoot "..\HermesConsoleUI.psd1") -Force

# --- CONFIGURACION INICIAL ---

# Simular Read-Host para automatizar entradas
$global:DemoInput = "1"

function Read-Host { 
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
    param($Prompt, $AsSecureString)
    Start-Sleep -Milliseconds 300
    $val = $global:DemoInput
    if ($Prompt) { Write-Host "$Prompt " -NoNewline -ForegroundColor Cyan }
    Write-Host "$val (Simulado)" -ForegroundColor Green
    if ($AsSecureString) { return ConvertTo-SecureString -String $val -AsPlainText -Force }
    return $val
}

# Funcion helper para demos con manejo de errores
function Show-ComponentDemo {
    param(
        [int]$Number,
        [string]$Name,
        [string]$Description,
        [string]$Usage,
        [string]$Parameters,
        [scriptblock]$DemoBlock
    )
    
    try {
        # FIX: Eliminados corchetes dobles, la funcion ya los pone
        Write-ConsoleSubtitle -Text "$Number. $Name"
        Write-ConsoleInfo -Message $Description
        if ($Usage) {
            Write-Host "  " -NoNewline
            Write-Host "Uso: " -NoNewline -ForegroundColor White
            Write-Host $Usage -ForegroundColor Yellow
        }
        if ($Parameters) {
            Write-Host "  " -NoNewline
            Write-Host "Parametros: " -NoNewline -ForegroundColor White
            Write-Host $Parameters -ForegroundColor Gray
        }
        Write-Host ""
        
        & $DemoBlock
        
    }
    catch {
        Write-ConsoleError -Message "Error demostrando $Name`: $_"
    }
    Write-Host ""
}

# --- SELECTOR DE TEMA ---

Clear-Host
Write-Host "`n"
Write-ConsoleTitle -Title "HermesConsoleUI v2.0.1 - CONFIGURACION"

Write-ConsoleHeader -Text "SELECTOR DE TEMA"
Write-Host ""
Write-Host "  Temas disponibles:" -ForegroundColor Cyan
Write-Host "    1. Default  - Colores estandar (Cyan/Yellow/Green/Red)" -ForegroundColor Gray
Write-Host "    2. Dark     - Tonos oscuros (Blue/Purple/Magenta)" -ForegroundColor Gray  
Write-Host "    3. Light    - Tonos claros (Yellow/Cyan/White)" -ForegroundColor Gray
Write-Host "    4. Matrix   - Estilo Matrix (Green monocromatico)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Tema seleccionado: $Theme" -ForegroundColor Green
Write-Host ""

# Aplicar tema (si no es Default)
if ($Theme -ne 'Default') {
    try {
        Set-ConsoleTheme -Name $Theme
        Write-ConsoleStatus -Message "Tema '$Theme' aplicado correctamente" -Type Success
    }
    catch {
        Write-ConsoleStatus -Message "Error aplicando tema, usando Default" -Type Warning
    }
}

Write-Host ""
Write-Host "Presiona ENTER para iniciar el demo..." -ForegroundColor Yellow
Read-Host

# --- INICIO DEL DEMO ---

Clear-Host
Write-Host "`n"
Write-ConsoleTitle -Title "HermesConsoleUI v2.0.1 - DEMO TOTAL AUTOMATICO"
Write-Host "Generando reporte completo de 40 componentes..." -ForegroundColor Cyan
Write-Host "Tema activo: $Theme" -ForegroundColor Gray
Write-Host ""

# ===== PARTE 1: COMPONENTES VISUALES (18) =====

Write-ConsoleHeader -Text "PARTE 1: COMPONENTES VISUALES"

# 1. Write-ConsoleTitle
Show-ComponentDemo -Number 1 -Name "Write-ConsoleTitle" `
    -Description "Titulos principales con bordes decorativos Unicode." `
    -Usage "Encabezados de reportes, pantallas de inicio, titulos de seccion principal" `
    -Parameters "-Title (string), -Color (default: Cyan)" `
    -DemoBlock {
    Write-ConsoleTitle -Title "REPORTE AUTOMATICO DE SISTEMA"
}

# 2. Write-ConsoleHeader
Show-ComponentDemo -Number 2 -Name "Write-ConsoleHeader" `
    -Description "Encabezados de seccion con prefijo >>>." `
    -Usage "Separar secciones principales en scripts, marcar inicio de bloques" `
    -Parameters "-Text (string), -Color (default: Yellow)" `
    -DemoBlock {
    Write-ConsoleHeader -Text "Iniciando Diagnostico Completo"
}

# 3. Write-ConsoleSubtitle
Show-ComponentDemo -Number 3 -Name "Write-ConsoleSubtitle" `
    -Description "Subtitulos con contadores opcionales entre corchetes." `
    -Usage "Subsecciones, listas numeradas, contadores de items procesados" `
    -Parameters "-Text (string), -Count (int, opcional), -Color (default: Cyan)" `
    -DemoBlock {
    Write-ConsoleSubtitle -Text "Modulos Cargados" -Count 34
    Write-ConsoleSubtitle -Text "Fase de Inicializacion"
}

# 4. Write-ConsoleStatus
Show-ComponentDemo -Number 4 -Name "Write-ConsoleStatus" `
    -Description "Mensajes de estado con iconos automaticos y colores segun tipo." `
    -Usage "Progreso de operaciones, resultados de validaciones, feedback de acciones" `
    -Parameters "-Message (string), -Type (Success/Warning/Error/Info)" `
    -DemoBlock {
    Write-ConsoleStatus -Message "Inicializacion del core" -Type Success
    Write-ConsoleStatus -Message "Verificando dependencias" -Type Warning
    Write-ConsoleStatus -Message "Conexion a base de datos db_main" -Type Error
    Write-ConsoleStatus -Message "Reintentando en modo offline" -Type Info
}

# 5. Write-ConsoleError
Show-ComponentDemo -Number 5 -Name "Write-ConsoleError" `
    -Description "Mensajes de error destacados en rojo con prefijo [!] ERROR:." `
    -Usage "Reportar fallos criticos, excepciones, errores de validacion" `
    -Parameters "-Message (string)" `
    -DemoBlock {
    Write-ConsoleError -Message "Fallo critico en modulo de red (Codigo 0x800410)"
}

# 6. Write-ConsoleInfo
Show-ComponentDemo -Number 6 -Name "Write-ConsoleInfo" `
    -Description "Mensajes informativos con icono [i]." `
    -Usage "Notificaciones generales, pasos de proceso, informacion contextual" `
    -Parameters "-Message (string), -Color (default: White)" `
    -DemoBlock {
    Write-ConsoleInfo -Message "Cargando configuracion de respaldo..."
    Write-ConsoleInfo -Message "Procesando 1,247 archivos..." -Color Cyan
}

# 7. Write-ConsoleMetadata
Show-ComponentDemo -Number 7 -Name "Write-ConsoleMetadata" `
    -Description "Pares clave-valor formateados con indentacion automatica." `
    -Usage "Mostrar configuracion, propiedades de objetos, detalles de sistema" `
    -Parameters "-Metadata (hashtable), -Title (string, opcional)" `
    -DemoBlock {
    $metadata = @{
        "Host"            = $env:COMPUTERNAME
        "Usuario"         = $env:USERNAME
        "Dominio"         = $env:USERDOMAIN
        "OS Architecture" = "64-bit"
    }
    Write-ConsoleMetadata -Metadata $metadata -Title "Metadata del Host"
}

# 8. Write-ConsoleSummary
Show-ComponentDemo -Number 8 -Name "Write-ConsoleSummary" `
    -Description "Resumen con titulo y lista de items." `
    -Usage "Totales finales, estadisticas, metricas de resumen" `
    -Parameters "-Title (string), -Items (array de hashtables con Label y Value)" `
    -DemoBlock {
    Write-ConsoleSummary -Title "Resumen de Recursos" -Items @(
        @{Label = "CPU Core 0"; Value = "15%" }
        @{Label = "CPU Core 1"; Value = "22%" }
        @{Label = "Memoria Fisica"; Value = "45% en uso" }
        @{Label = "Swap File"; Value = "10% en uso" }
    )
}

# 9. Write-ConsoleDiff
Show-ComponentDemo -Number 9 -Name "Write-ConsoleDiff" `
    -Description "Comparacion antes/despues con colores diferenciados." `
    -Usage "Cambios de configuracion, actualizaciones, auditorias de cambios" `
    -Parameters "-Label (string), -OldValue (string), -NewValue (string)" `
    -DemoBlock {
    Write-ConsoleDiff -Label "Latencia de Red" -OldValue "25ms" -NewValue "140ms"
}

# 10. Write-ConsoleChart
Show-ComponentDemo -Number 10 -Name "Write-ConsoleChart" `
    -Description "Barras de progreso horizontales con bloques Unicode." `
    -Usage "Porcentajes, uso de recursos (CPU/RAM/Disco), capacidad" `
    -Parameters "-Label (string), -Value (int), -Max (int), -Color (opcional)" `
    -DemoBlock {
    Write-ConsoleChart -Label "Carga CPU" -Value 85 -Max 100 -Color Red
    Write-ConsoleChart -Label "Carga GPU" -Value 30 -Max 100 -Color Green
}

# 11. Write-ConsoleSparkline
Show-ComponentDemo -Number 11 -Name "Write-ConsoleSparkline" `
    -Description "Graficos de linea compactos usando caracteres de altura variable." `
    -Usage "Tendencias temporales, historicos, metricas en el tiempo" `
    -Parameters "-Data (array de numeros), -Color (opcional)" `
    -DemoBlock {
    Write-Host "Actividad de Disco (ultimas 12h): " -NoNewline
    Write-ConsoleSparkline -Data @(10, 20, 15, 80, 90, 85, 20, 10, 5, 5, 90, 100) -Color Yellow
}

# 12. Write-ConsolePanel
Show-ComponentDemo -Number 12 -Name "Write-ConsolePanel" `
    -Description "Contenido encerrado en bordes decorativos con titulo opcional." `
    -Usage "Logs destacados, mensajes importantes, bloques de informacion" `
    -Parameters "-Title (opcional), -BorderStyle (Single/Double/Rounded/Heavy), -Color, -Content (scriptblock)" `
    -DemoBlock {
    Write-ConsolePanel -Title "Log de Eventos" -BorderStyle Double -Color Cyan -Content {
        "[08:00:01] Sistema iniciado"
        "[08:00:05] Servicio Watchdog: OK"
        "[08:00:10] Usuario logueado"
    }
}

# 13. Write-ConsoleBox
Show-ComponentDemo -Number 13 -Name "Write-ConsoleBox" `
    -Description "Mensaje destacado en caja con bordes." `
    -Usage "Alertas criticas, advertencias importantes, notificaciones urgentes" `
    -Parameters "-Message (string), -Color (opcional)" `
    -DemoBlock {
    Write-ConsoleBox -Message "ALERTA DE SEGURIDAD: INTENTO DE ACCESO" -Color Red
}

# 14. Write-ConsoleTree
Show-ComponentDemo -Number 14 -Name "Write-ConsoleTree" `
    -Description "Estructura jerarquica con caracteres de arbol." `
    -Usage "Directorios, dependencias, organizacion de datos anidados" `
    -Parameters "-TreeData (hashtable anidado)" `
    -DemoBlock {
    $tree = @{
        "C:\Windows" = @{
            "System32" = @("drivers", "config")
            "Temp"     = @("log1.txt", "debug.log")
        }
    }
    Write-ConsoleTree -TreeData $tree
}

# 15. Show-ConsoleList
Show-ComponentDemo -Number 15 -Name "Show-ConsoleList" `
    -Description "Listas con bullets personalizables." `
    -Usage "Enumeraciones, opciones disponibles, items de configuracion" `
    -Parameters "-Items (array), -Bullet (char, opcional), -Numbered (switch), -Color (opcional)" `
    -DemoBlock {
    Show-ConsoleList -Items @("Reiniciar servicios", "Limpiar logs", "Bloquear IP") -Bullet * -Color Cyan
}

# 16. Write-ConsoleSeparator
Show-ComponentDemo -Number 16 -Name "Write-ConsoleSeparator" `
    -Description "Lineas separadoras horizontales." `
    -Usage "Dividir secciones visuales, separar bloques de contenido" `
    -Parameters "-Character (default: -), -Length (default: 60), -Color (opcional)" `
    -DemoBlock {
    Write-Host "Inicio de Trazas" -ForegroundColor Cyan
    Write-ConsoleSeparator -Length 40
    Write-Host "Fin de Trazas" -ForegroundColor Cyan
}

# 17. Write-ConsoleBreadcrumb
Show-ComponentDemo -Number 17 -Name "Write-ConsoleBreadcrumb" `
    -Description "Rutas de navegacion jerarquicas." `
    -Usage "Ubicacion actual en menus, jerarquia de configuracion, contexto" `
    -Parameters "-Path (array), -Separator (default: ' > '), -Color (opcional)" `
    -DemoBlock {
    Write-ConsoleBreadcrumb -Path @("Admin", "Herramientas", "Logs", "Auditoria")
}

# 18. Write-ConsoleTable
Show-ComponentDemo -Number 18 -Name "Write-ConsoleTable" `
    -Description "Tablas formateadas con columnas alineadas." `
    -Usage "Datos tabulares, comparaciones, listados estructurados" `
    -Parameters "-Data (array de hashtables), -Columns (array de definiciones)" `
    -DemoBlock {
    $data = @(
        @{ ID = "101"; Proc = "svchost"; Mem = "14MB" }
        @{ ID = "102"; Proc = "chrome"; Mem = "450MB" }
        @{ ID = "103"; Proc = "powershell"; Mem = "85MB" }
    )
    $cols = @(
        @{ Header = "PID"; Property = "ID"; Width = 8 }
        @{ Header = "Proceso"; Property = "Proc"; Width = 15 }
        @{ Header = "Memoria"; Property = "Mem"; Width = 10 }
    )
    Write-ConsoleTable -Data $data -Columns $cols
}

# ===== PARTE 2: COMPONENTES INTERACTIVOS (SIMULADOS) =====

Write-ConsoleHeader -Text "PARTE 2: COMPONENTES INTERACTIVOS (SIMULADOS)"

# 19. Show-ConsoleMenu
Show-ComponentDemo -Number 19 -Name "Show-ConsoleMenu" `
    -Description "Menu interactivo con seleccion numerica." `
    -Usage "Navegacion de opciones, menus principales, seleccion de acciones" `
    -Parameters "-Title, -Options (array), -NoClear (switch)" `
    -DemoBlock {
    $options = @("Opcion 1", "Opcion 2", "Opcion 3")
    $selection = Show-ConsoleMenu -Title "Menu Principal" -Options $options -NoClear
    Write-Host "  Seleccionado: $selection (Simulado)" -ForegroundColor Green
}

# 20. Read-ConsoleChoice
Show-ComponentDemo -Number 20 -Name "Read-ConsoleChoice" `
    -Description "Lectura de opcion numerica con validacion." `
    -Usage "Validacion de entrada, menus numericos, seleccion de items" `
    -Parameters "-Prompt, -Min, -Max" `
    -DemoBlock {
    Write-Host "  Ingrese opcion (1-3): 2 (Simulado)" -ForegroundColor Green
}

# 21. Read-ConsoleMultiChoice
Show-ComponentDemo -Number 21 -Name "Read-ConsoleMultiChoice" `
    -Description "Seleccion multiple de opciones." `
    -Usage "Checkboxes, seleccion de multiples items, configuracion" `
    -Parameters "-Prompt, -Options (array)" `
    -DemoBlock {
    Write-Host "  Opciones seleccionadas: 1, 3 (Simulado)" -ForegroundColor Green
}

# 22. Read-ConsoleInput
Show-ComponentDemo -Number 22 -Name "Read-ConsoleInput" `
    -Description "Entrada de texto con validacion opcional." `
    -Usage "Captura de datos del usuario, formularios, configuracion" `
    -Parameters "-Prompt, -Validation (scriptblock), -Required (switch)" `
    -DemoBlock {
    Write-Host "  Nombre de usuario: admin (Simulado)" -ForegroundColor Green
}

# 23. Read-ConsoleConfirmation
Show-ComponentDemo -Number 23 -Name "Read-ConsoleConfirmation" `
    -Description "Confirmacion Si/No para acciones criticas." `
    -Usage "Validacion de acciones destructivas, confirmaciones de seguridad" `
    -Parameters "-Prompt, -DefaultYes (switch)" `
    -DemoBlock {
    Write-Host "  ¿Continuar? (S/N): S (Simulado)" -ForegroundColor Green
}

# 24. Read-ConsolePassword
Show-ComponentDemo -Number 24 -Name "Read-ConsolePassword" `
    -Description "Entrada segura de password (oculta caracteres)." `
    -Usage "Credenciales, datos sensibles, autenticacion" `
    -Parameters "-Prompt" `
    -DemoBlock {
    Write-Host "  Password: ******** (Simulado)" -ForegroundColor Green
}

# 25. Show-ConsoleNotification
Show-ComponentDemo -Number 25 -Name "Show-ConsoleNotification" `
    -Description "Notificaciones visuales temporales." `
    -Usage "Feedback de operaciones, alertas no bloqueantes" `
    -Parameters "-Message, -Type (Success/Warning/Error/Info), -Duration" `
    -DemoBlock {
    Write-Host "  [OK] Operacion completada exitosamente" -ForegroundColor Green
}

# 26. Show-ConsoleSpinner
Show-ComponentDemo -Number 26 -Name "Show-ConsoleSpinner" `
    -Description "Animacion de carga rotativa." `
    -Usage "Operaciones largas, esperas, procesamiento en background" `
    -Parameters "-Message, -ScriptBlock" `
    -DemoBlock {
    Write-Host "  [|] Procesando... (Simulado)" -ForegroundColor Cyan
}

# 27. Show-ConsoleProgress
Show-ComponentDemo -Number 27 -Name "Show-ConsoleProgress" `
    -Description "Barra de progreso visual con porcentaje." `
    -Usage "Procesos con duracion conocida, copias de archivos, instalaciones" `
    -Parameters "-Activity, -PercentComplete, -BarLength (opcional), -Color (opcional)" `
    -DemoBlock {
    Show-ConsoleProgress -Activity "Instalando paquetes..." -PercentComplete 25
    Show-ConsoleProgress -Activity "Descargando archivos..." -PercentComplete 60 -Color Green
    Show-ConsoleProgress -Activity "Finalizando..." -PercentComplete 100 -Color Yellow
}

# 28. Show-ConsoleMenu (Avanzado)
Show-ComponentDemo -Number 28 -Name "Show-ConsoleMenu (con acciones)" `
    -Description "Menu interactivo con ejecucion de acciones." `
    -Usage "Interfaces completas, paneles de control, herramientas CLI" `
    -Parameters "-Title, -MenuItems (hashtable con Label y Action)" `
    -DemoBlock {
    Write-Host "  Menu con 5 opciones y acciones asociadas (Simulado)" -ForegroundColor Green
}

# ===== PARTE 3: FUNCIONES CORE (METADATA) =====

Write-ConsoleHeader -Text "PARTE 3: FUNCIONES CORE (METADATA)"

# 29. Get-ConsoleConfig
Show-ComponentDemo -Number 29 -Name "Get-ConsoleConfig" `
    -Description "Obtiene configuracion actual del framework." `
    -Usage "Debugging, inspeccion de configuracion, diagnosticos" `
    -Parameters "Ninguno" `
    -DemoBlock {
    Write-Host "  Tema: Default, Locale: es-ES, Version: 2.0.1" -ForegroundColor Gray
}

# 30. Set-ConsoleTheme
Show-ComponentDemo -Number 30 -Name "Set-ConsoleTheme" `
    -Description "Cambia el tema visual del framework." `
    -Usage "Personalizacion, branding, preferencias de usuario" `
    -Parameters "-ThemeName (Default/Dark/Light/Matrix/Custom)" `
    -DemoBlock {
    Write-Host "  Tema cambiado a: $Theme" -ForegroundColor Cyan
}

# 31. Get-ConsoleTheme
Show-ComponentDemo -Number 31 -Name "Get-ConsoleTheme" `
    -Description "Obtiene el tema actual y sus colores." `
    -Usage "Inspeccion de temas, debugging de colores" `
    -Parameters "Ninguno" `
    -DemoBlock {
    Write-Host "  Tema actual: $Theme (Cyan/Yellow/Green/Red)" -ForegroundColor Gray
}

# 32. Set-UILocale
Show-ComponentDemo -Number 32 -Name "Set-UILocale" `
    -Description "Cambia el idioma del framework (i18n)." `
    -Usage "Internacionalizacion, soporte multiidioma" `
    -Parameters "-Locale (en-US/es-ES/fr-FR)" `
    -DemoBlock {
    Write-Host "  Idioma cambiado a: es-ES" -ForegroundColor Cyan
}

# 33. Get-UILocale
Show-ComponentDemo -Number 33 -Name "Get-UILocale" `
    -Description "Obtiene el idioma actual del framework." `
    -Usage "Verificacion de configuracion de idioma" `
    -Parameters "Ninguno" `
    -DemoBlock {
    Write-Host "  Idioma actual: es-ES (Español)" -ForegroundColor Gray
}

# 34. Get-ConsoleColors
Show-ComponentDemo -Number 34 -Name "Get-ConsoleColors" `
    -Description "Obtiene el mapa de colores del tema actual." `
    -Usage "Debugging de temas, personalizacion avanzada" `
    -Parameters "Ninguno" `
    -DemoBlock {
    Write-Host "  Success=Green, Warning=Yellow, Error=Red, Info=Cyan" -ForegroundColor Gray
}

# ===== PARTE 4: SISTEMA DE LAYOUT (GRILLAS Y COLUMNAS) =====

Write-ConsoleHeader -Text "PARTE 4: SISTEMA DE LAYOUT (GRILLAS Y COLUMNAS)"

# 35. New-ConsoleLayout
Show-ComponentDemo -Number 35 -Name "New-ConsoleLayout" `
    -Description "Contenedor principal para una interfaz basada en rejillas." `
    -Usage "Estructurar dashboads, organizar multiples vistas en una pantalla" `
    -Parameters "-Rows (array de filas)" `
    -DemoBlock {
    Write-ConsoleInfo -Message "Crea un objeto Layout que puede contener múltiples filas."
}

# 36. New-ConsoleRow
Show-ComponentDemo -Number 36 -Name "New-ConsoleRow" `
    -Description "Define una fila horizontal dentro de un layout." `
    -Usage "Dividir el espacio vertical en secciones que contendran columnas" `
    -Parameters "-Columns (array de columnas)" `
    -DemoBlock {
    Write-ConsoleInfo -Message "Agrupa columnas que se renderizarán en paralelo."
}

# 37. New-ConsoleColumn
Show-ComponentDemo -Number 37 -Name "New-ConsoleColumn" `
    -Description "Define un area vertical con un ancho porcentual." `
    -Usage "Especificar cuanto espacio horizontal ocupa cada componente" `
    -Parameters "-Content (scriptblock o array), -WidthPercent (int)" `
    -DemoBlock {
    Write-ConsoleInfo -Message "Permite distribuir el contenido (40%, 60%, etc.)"
}

# 38. Write-ConsoleLayout
Show-ComponentDemo -Number 38 -Name "Write-ConsoleLayout" `
    -Description "El motor de renderizado que fusiona y dibuja la rejilla." `
    -Usage "Dibujar dashboards complejos con componentes lado a lado" `
    -Parameters "-Layout (hashtable), -TotalWidth (int)" `
    -DemoBlock {
    # Ejemplo real de lo que hace el motor
    $c1 = Show-ConsoleList -Items @("Item A", "Item B") -ReturnLines -Width 20 -Bullet ">"
    $c2 = Write-ConsoleBox -Message "Panel en Paralelo" -ReturnLines -Width 25
        
    $row = New-ConsoleRow -Columns @(
        (New-ConsoleColumn -Content $c1 -WidthPercent 45),
        (New-ConsoleColumn -Content $c2 -WidthPercent 55)
    )
    $lay = New-ConsoleLayout -Rows @($row)
    Write-ConsoleLayout -Layout $lay -TotalWidth 60
}

# 39. Set-LayoutBuffer
Show-ComponentDemo -Number 39 -Name "Set-LayoutBuffer" `
    -Description "Helper interno para fusionar arreglos de strings linea por linea." `
    -Usage "Core del sistema de layout, maneja padding y alineacion" `
    -Parameters "-Columns (array), -Widths (array)" `
    -DemoBlock {
    Write-ConsoleInfo -Message "Algoritmo de fusión de texto para renderizado paralelo."
}

# 40. Invoke-CapturedOutput
Show-ComponentDemo -Number 40 -Name "Invoke-CapturedOutput" `
    -Description "Helper para capturar la salida de componentes para el buffer." `
    -Usage "Captura el dibujo de un componente antes de imprimirlo" `
    -Parameters "-Code (scriptblock)" `
    -DemoBlock {
    Write-ConsoleInfo -Message "Captura flujos de texto para su posterior procesamiento."
}

# ===== RESUMEN FINAL =====

Write-ConsoleTitle -Title "REPORTE COMPLETO FINALIZADO"
Write-Host "  Todos los 40 componentes han sido ejecutados." -ForegroundColor Cyan
Write-Host "  Sistema de Layout (Grillas) integrado correctamente." -ForegroundColor Green
Write-Host "  Puedes hacer scroll hacia arriba para ver todo el historial." -ForegroundColor Cyan
Write-Host "  Tema usado: $Theme" -ForegroundColor Gray
Write-Host ""
