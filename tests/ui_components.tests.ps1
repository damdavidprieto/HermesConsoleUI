$LibRoot = Split-Path $PSScriptRoot -Parent

Describe "HermesConsoleUI v2.0.1 - Complete Test Suite" {
    # Load the module
    BeforeAll {
        $LibRoot = Split-Path $PSScriptRoot -Parent
        $modPath = Join-Path $LibRoot "HermesConsoleUI.psd1"
        Write-Host "DEBUG: Importing module from $modPath"
        try {
            Import-Module $modPath -Force -ErrorAction Stop
        }
        catch {
            Write-Host "DEBUG: Import Failed: $_"
            Write-Host "DEBUG: StackTrace: $($_.ScriptStackTrace)"
            throw
        }
    }

    Context "Module Loading" {
        It "Should load without errors" {
            { Import-Module "$LibRoot\HermesConsoleUI.psd1" -Force } | Should -Not -Throw
        }

        It "Should export Write-ConsoleTitle" {
            Get-Command Write-ConsoleTitle -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should export Write-ConsoleStatus" {
            Get-Command Write-ConsoleStatus -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should export Write-ConsoleBox" {
            Get-Command Write-ConsoleBox -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should export Write-ConsoleTable" {
            Get-Command Write-ConsoleTable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Text Components" {
        It "Write-ConsoleTitle should execute" {
            { Write-ConsoleTitle -Title "Test" } | Should -Not -Throw
        }

        It "Write-ConsoleHeader should execute" {
            { Write-ConsoleHeader -Text "Test" } | Should -Not -Throw
        }

        It "Write-ConsoleStatus should handle all types" {
            { Write-ConsoleStatus -Message "Success" -Type "Success" } | Should -Not -Throw
            { Write-ConsoleStatus -Message "Warning" -Type "Warning" } | Should -Not -Throw
            { Write-ConsoleStatus -Message "Error" -Type "Error" } | Should -Not -Throw
            { Write-ConsoleStatus -Message "Info" -Type "Info" } | Should -Not -Throw
        }

        It "Write-ConsoleInfo should execute" {
            { Write-ConsoleInfo -Message "Test" } | Should -Not -Throw
        }

        It "Write-ConsoleError should execute" {
            { Write-ConsoleError -Message "Test" } | Should -Not -Throw
        }

        It "Write-ConsoleSeparator should execute" {
            { Write-ConsoleSeparator -Length 40 } | Should -Not -Throw
        }

        It "Write-ConsoleBreadcrumb should execute" {
            { Write-ConsoleBreadcrumb -Path @("Home", "Docs", "API") } | Should -Not -Throw
        }
    }

    Context "Visual Components" {
        It "Write-ConsoleBox should execute" {
            { Write-ConsoleBox -Message "Test" } | Should -Not -Throw
        }

        It "Write-ConsoleChart should execute" {
            { Write-ConsoleChart -Label "CPU" -Value 50 -Max 100 } | Should -Not -Throw
        }

        It "Write-ConsoleChart should handle edge cases" {
            { Write-ConsoleChart -Label "Test" -Value 0 -Max 100 } | Should -Not -Throw
            { Write-ConsoleChart -Label "Test" -Value 100 -Max 100 } | Should -Not -Throw
        }

        It "Write-ConsoleTree should execute with simple tree" {
            $tree = @{ "Root" = @("Item1", "Item2") }
            { Write-ConsoleTree -TreeData $tree } | Should -Not -Throw
        }

        It "Write-ConsoleTree should execute with nested tree" {
            $tree = @{
                "Parent" = @{
                    "Child" = @("Leaf1", "Leaf2")
                }
            }
            { Write-ConsoleTree -TreeData $tree } | Should -Not -Throw
        }

        It "Write-ConsoleTable should execute with valid data" {
            $data = @(
                @{ Name = "Item1"; Value = 100 }
                @{ Name = "Item2"; Value = 200 }
            )
            $columns = @(
                @{ Header = "Name"; Property = "Name"; Width = 20 }
                @{ Header = "Value"; Property = "Value"; Width = 10 }
            )
            { Write-ConsoleTable -Data $data -Columns $columns } | Should -Not -Throw
        }

        It "Write-ConsoleTable should handle empty data" {
            $columns = @(@{ Header = "Name"; Property = "Name"; Width = 20 })
            try {
                Write-ConsoleTable -Data @() -Columns $columns
            }
            catch {
                Write-Host "TEST ERROR CAUGHT: $_"
                Write-Host "STACK: $($_.ScriptStackTrace)"
                throw
            }
        }

        It "Show-ConsoleList should execute" {
            { Show-ConsoleList -Items @("Item1", "Item2", "Item3") } | Should -Not -Throw
        }

        It "Write-ConsoleSparkline should execute" {
            { Write-ConsoleSparkline -Data @(1, 5, 2, 8, 3, 9) } | Should -Not -Throw
        }

        It "Write-ConsolePanel should execute" {
            { Write-ConsolePanel -Title "Test" -Content { Write-Host "Content" } } | Should -Not -Throw
        }
    }

    Context "Interactive Components" {
        It "Show-ConsoleMenu should execute" {
            $options = @("Option 1", "Option 2")
            { Show-ConsoleMenu -Title "Test" -Options $options } | Should -Not -Throw
        }

        It "Show-ConsoleMenu should return correct count" {
            $options = @("Option 1", "Option 2")
            $count = Show-ConsoleMenu -Title "Test" -Options $options
            $count | Should -Be 2
        }

        It "Invoke-ConsoleSpinner should execute and return result" {
            $result = Invoke-ConsoleSpinner -Message "Test" -ScriptBlock { return "Success" }
            $result | Should -Be "Success"
        }

        It "Write-ConsoleProgress should execute for various percentages" {
            { Write-ConsoleProgress -Activity "Test" -Percent 0 } | Should -Not -Throw
            { Write-ConsoleProgress -Activity "Test" -Percent 50 } | Should -Not -Throw
            { Write-ConsoleProgress -Activity "Test" -Percent 100 } | Should -Not -Throw
        }

        It "Show-ConsoleNotification should execute" {
            { Show-ConsoleNotification -Message "Test" -Type "Success" -Duration 1 } | Should -Not -Throw
        }
    }

    Context "Core - Configuration" {
        It "Set-ConsoleTheme should change theme" {
            { Set-ConsoleTheme -ThemeName "Cyberpunk" } | Should -Not -Throw
            { Set-ConsoleTheme -ThemeName "Default" } | Should -Not -Throw
        }

        It "Get-ConsoleTheme should return current theme" {
            $theme = Get-ConsoleTheme
            $theme | Should -Not -BeNullOrEmpty
        }

        It "Get-AvailableThemes should return array" {
            $themes = Get-AvailableThemes
            $themes | Should -Not -BeNullOrEmpty
            $themes.Count | Should -BeGreaterThan 0
        }

        It "Get-UIColor should return color" {
            $color = Get-UIColor -ColorType "Success"
            $color | Should -Not -BeNullOrEmpty
        }
    }

    Context "Core - Localization" {
        It "Set-UILocale should change locale" {
            { Set-UILocale -Locale "en-US" } | Should -Not -Throw
        }

        It "Get-UILocale should return current locale" {
            $locale = Get-UILocale
            $locale | Should -Not -BeNullOrEmpty
        }

        It "Get-AvailableLocales should return array" {
            $locales = Get-AvailableLocales
            $locales | Should -Not -BeNullOrEmpty
            $locales.Count | Should -BeGreaterThan 0
        }

        It "Get-LocalizedString should return string" {
            $str = Get-LocalizedString -Key "Common.Yes" -DefaultValue "Yes"
            $str | Should -Not -BeNullOrEmpty
        }
    }

    Context "Integration Tests" {
        It "Should handle complete workflow" {
            {
                Write-ConsoleTitle -Title "TEST"
                Write-ConsoleHeader -Text "Section"
                Write-ConsoleStatus -Message "Starting" -Type "Info"
                Write-ConsoleChart -Label "Progress" -Value 50 -Max 100
                Write-ConsoleBox -Message "Notice"
                Write-ConsoleStatus -Message "Complete" -Type "Success"
            } | Should -Not -Throw
        }

        It "Should handle error scenarios gracefully" {
            {
                Write-ConsoleError -Message "Test error"
                Write-ConsoleStatus -Message "Failed" -Type "Error"
            } | Should -Not -Throw
        }
    }

    Context "Performance Tests" {
        It "Should handle large tables efficiently" {
            $data = 1..50 | ForEach-Object {
                @{ ID = $_; Name = "Item$_"; Value = $_ * 10 }
            }
            $cols = @(
                @{ Header = "ID"; Property = "ID"; Width = 10 }
                @{ Header = "Name"; Property = "Name"; Width = 20 }
                @{ Header = "Value"; Property = "Value"; Width = 15 }
            )
            
            $elapsed = Measure-Command {
                Write-ConsoleTable -Data $data -Columns $cols
            }
            
            # Should complete in reasonable time (< 5 seconds)
            $elapsed.TotalSeconds | Should -BeLessThan 5
        }
    }
}
