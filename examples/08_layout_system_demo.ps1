# HermesConsoleUI v2.0.1 - Layout & Grid Dashboard (STABLE V2)
Import-Module (Join-Path $PSScriptRoot "..\HermesConsoleUI.psd1") -Force

# Asegurar encoding UTF-8 (con manejo de errores para terminales restringidas)
try {
    $currentEncoding = [Console]::OutputEncoding
    if ($currentEncoding.CodePage -ne 65001) {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    }
} catch {
    # Silenciar error de encoding si el terminal es restringido
}

Clear-Host
1..2 | ForEach-Object { Write-Host "" }

Write-ConsoleTitle -Title "ESTADO DEL SISTEMA (HermesLayout)"

# 1. CAPTURAR DATOS AISLADOS
# Fila Superior
$data_list = Show-ConsoleList -Items @("CPU: 12%", "RAM: 8GB", "DISK: 40%") -ReturnLines -Width 25 -Bullet "-"
$data_box  = Write-ConsoleBox -Message "DIAGNOSTICO: OK" -Color Green -ReturnLines -Width 25

# Fila Inferior
$chart_s = Write-ConsoleChart -Label "SYS" -Value 45 -Max 100 -ReturnLines -Width 15
$chart_n = Write-ConsoleChart -Label "NET" -Value 12 -Max 100 -ReturnLines -Width 15

# 2. DEFINIR FILAS
$lay_row1 = New-ConsoleRow -Columns @(
    (New-ConsoleColumn -Content $data_list -WidthPercent 50),
    (New-ConsoleColumn -Content $data_box  -WidthPercent 50)
)

$lay_row2 = New-ConsoleRow -Columns @(
    (New-ConsoleColumn -Content $chart_s -WidthPercent 50),
    (New-ConsoleColumn -Content $chart_n -WidthPercent 50)
)

# 3. CONSTRUIR LAYOUT
$final_layout = New-ConsoleLayout -Rows @($lay_row1, $lay_row2)

# 4. RENDERIZAR
Write-ConsoleLayout -Layout $final_layout -TotalWidth 80

# 5. MENSAJES DE ESTADO
Write-ConsoleSeparator
Write-ConsoleStatus -Message "Dashboard Cargado Exitosamente" -Type Success
Write-ConsoleInfo -Message "Arquitectura de REJILLA activada."
