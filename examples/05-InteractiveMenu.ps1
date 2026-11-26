# An interactive menu with actions, confirmation and multiple choice.
# Run from the repository: .\examples\05-InteractiveMenu.ps1  (choose 0 to exit)

Import-Module (Join-Path $PSScriptRoot '..\HermesConsoleUI.psd1') -Force

Invoke-ConsoleMenu -Title 'Maintenance' -Footer 'Example menu: nothing is changed on your system' -MenuItems @(
    @{ Label = '[Information]' }
    @{ Label = 'Show the five busiest processes'; Action = {
            Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 |
                Select-Object ProcessName, Id, CPU | Write-ConsoleTable
        }
    }
    @{ Label = 'Pick components to check'; Action = {
            # Arrow keys, Space to mark, Enter to accept (numbered prompts without a console).
            $picked = Read-ConsoleSelection -Title 'Components' -Options 'Disk', 'Network', 'Services' -Multiple
            if ($picked) { Show-ConsoleList -Items $picked } else { Write-ConsoleInfo -Message 'Nothing selected' }
        }
    }
    @{ Label = 'Choose an environment'; Action = {
            $target = Read-ConsoleSelection -Title 'Deploy to' -Options 'Development', 'Staging', 'Production'
            if ($target) { Write-ConsoleText "Deploying to {Success}$target{/} (simulated)" } else { Write-ConsoleInfo -Message 'Cancelled' }
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
