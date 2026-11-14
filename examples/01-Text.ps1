# Titles, headers and status messages.
# Run from the repository: .\examples\01-Text.ps1

Import-Module (Join-Path $PSScriptRoot '..\HermesConsoleUI.psd1') -Force

Write-ConsoleTitle -Title 'Deployment report'
Write-ConsoleBreadcrumb -Path 'Servers', 'Production', 'web-01'

Write-ConsoleHeader -Text 'Checks'
Write-ConsoleStatus -Message 'Configuration loaded' -Type Success
Write-ConsoleStatus -Message 'Certificate expires in 20 days' -Type Warning
Write-ConsoleStatus -Message 'Health endpoint did not answer' -Type Error
'Cache cleared', 'Service restarted' | Write-ConsoleStatus -Type Info

Write-ConsoleSubtitle -Text 'Changed settings' -Count 1
Write-ConsoleDiff -Label 'MaxConnections' -OldValue '100' -NewValue '250'

Write-ConsoleMetadata -Title 'Run' -Metadata ([ordered]@{
        Host      = [Environment]::MachineName
        PowerShell = $PSVersionTable.PSVersion.ToString()
        Started   = (Get-Date).ToString('yyyy-MM-dd HH:mm')
    })

Write-ConsoleSummary -Title 'Result' -Items @(
    @{ Label = 'Checks'; Value = 4 }
    @{ Label = 'Passed'; Value = 2; Color = 'Green' }
    @{ Label = 'Failed'; Value = 1; Color = 'Red' }
)
Write-ConsoleSeparator
