# HermesConsoleUI v2.0.1 - Layout Test (ASCII)
Import-Module "C:\test\HermesConsoleUI\HermesConsoleUI.psd1" -Force

# Asegurar encoding UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-ConsoleTitle -Title "LAYOUT TEST - FINAL VERIFICATION"

$list = @("Item 1", "Item 2", "Item 3")
$box = @("+-------+", "| Box   |", "+-------+")

$myLayout = New-ConsoleLayout -Rows @(
    New-ConsoleRow -Columns @(
        (New-ConsoleColumn -Content $list -WidthPercent 50)
        (New-ConsoleColumn -Content $box -WidthPercent 50)
    )
)

Write-ConsoleLayout -Layout $myLayout -TotalWidth 40

Write-ConsoleInfo -Message "Test Finalizado."
