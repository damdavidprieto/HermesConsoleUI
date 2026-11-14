# Tables, lists, trees, charts, sparklines, boxes and panels.
# Run from the repository: .\examples\02-Data.ps1

Import-Module (Join-Path $PSScriptRoot '..\HermesConsoleUI.psd1') -Force

$services = @(
    [pscustomobject]@{ Name = 'web'; Status = 'Running'; Cpu = 37 }
    [pscustomobject]@{ Name = 'worker'; Status = 'Running'; Cpu = 82 }
    [pscustomobject]@{ Name = 'backup'; Status = 'Stopped'; Cpu = 0 }
)

$services | Write-ConsoleTable -Title 'Services' -Columns @(
    @{ Header = 'Name'; Property = 'Name'; Width = 12 }
    @{ Header = 'Status'; Property = 'Status'; Width = 10 }
    @{ Header = 'CPU %'; Property = 'Cpu'; Width = 6 }
) -ColorMapProperty Status -ColorMap @{ Running = 'Green'; Stopped = 'Red' }

foreach ($service in $services) {
    Write-ConsoleChart -Label $service.Name.PadRight(8) -Value $service.Cpu
}
Write-ConsoleSparkline -Data 12, 18, 9, 30, 25, 41, 38 -ShowMinMax

Show-ConsoleList -Items 'Rotate logs', 'Renew certificate', 'Patch OS' -Numbered

Write-ConsoleTree -TreeData ([ordered]@{
        'C:\Apps' = [ordered]@{
            web    = 'appsettings.json', 'web.config'
            worker = 'worker.json'
        }
    })

Write-ConsoleBox -Message "Backup is stopped`nNext run: tonight at 02:00"

Write-ConsolePanel -Title 'Disk' -BorderStyle Rounded -Width 50 -Content {
    Write-ConsoleChart -Label 'C:' -Value 61 -Width 20 -ReturnLines
    Write-ConsoleChart -Label 'D:' -Value 92 -Width 20 -ReturnLines
}
