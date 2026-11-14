# An interactive menu with actions, confirmation and multiple choice.
# Run from the repository: .\examples\05-InteractiveMenu.ps1  (choose 0 to exit)

Import-Module (Join-Path $PSScriptRoot '..\HermesConsoleUI.psd1') -Force

Invoke-ConsoleMenu -Title 'Maintenance' -Footer 'Example menu: nothing is changed on your system' -MenuItems @(
    @{ Label = '[Information]' }
    @{ Label = 'Show the five busiest processes'; Action = {
            Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 |
                Write-ConsoleTable -Columns @(
                    @{ Header = 'Name'; Property = 'ProcessName'; Width = 25 }
                    @{ Header = 'Id'; Property = 'Id'; Width = 8 }
                )
        }
    }
    @{ Label = 'Pick components to check'; Action = {
            $picked = Read-ConsoleMultiChoice -Options 'Disk', 'Network', 'Services'
            if ($picked) { Show-ConsoleList -Items $picked } else { Write-ConsoleInfo -Message 'Nothing selected' }
        }
    }
    @{ Label = '---' }
    @{ Label = '{Yellow}Pretend to restart a service'; Action = {
            if (Read-ConsoleConfirmation -Message 'Restart the service?') {
                Write-ConsoleStatus -Message 'Restart simulated' -Type Success
            }
            else {
                Write-ConsoleStatus -Message 'Cancelled' -Type Warning
            }
        }
    }
)
