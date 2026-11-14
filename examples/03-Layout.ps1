# Side-by-side columns with New-ConsoleLayout.
# A script block column receives -Width and -ReturnLines and returns the lines to show.
# Run from the repository: .\examples\03-Layout.ps1

Import-Module (Join-Path $PSScriptRoot '..\HermesConsoleUI.psd1') -Force

$layout = New-ConsoleLayout -Rows @(
    New-ConsoleRow -Columns @(
        New-ConsoleColumn -WidthPercent 40 -Content {
            param($Width, [switch]$ReturnLines)
            Show-ConsoleList -Items 'web: running', 'worker: running', 'backup: stopped' -Width $Width -ReturnLines
        }
        New-ConsoleColumn -WidthPercent 60 -Content {
            param($Width, [switch]$ReturnLines)
            Write-ConsoleChart -Label 'CPU' -Value 37 -Width ($Width - 15) -ReturnLines
            Write-ConsoleChart -Label 'RAM' -Value 64 -Width ($Width - 15) -ReturnLines
        }
    )
    New-ConsoleRow -Columns @(
        New-ConsoleColumn -WidthPercent 100 -Content 'Updated every 5 minutes'
    )
)

Write-ConsoleTitle -Title 'Dashboard'
Write-ConsoleLayout -Layout $layout -TotalWidth 80
