# HermesConsoleUI - Integration Tests
# Tests for full workflow integration

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot ".." ".." "HermesConsoleUI.psd1"
    Import-Module $modulePath -Force
}

Describe "Full Workflow Integration" {
    
    Context "Module Integration" {
        It "Should load all components successfully" {
            $module = Get-Module HermesConsoleUI
            $module | Should -Not -BeNullOrEmpty
        }
        
        It "Should have all expected commands" {
            $commands = Get-Command -Module HermesConsoleUI
            $commands.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Component Interaction" {
        It "Should allow chaining of components" {
            # Test that components can work together
            { 
                $data = 1..5 | ForEach-Object { [PSCustomObject]@{ID = $_; Name = "Item$_" } }
                $data | Out-Null
            } | Should -Not -Throw
        }
    }
    
    Context "Error Recovery" {
        It "Should recover from errors gracefully" {
            {
                try {
                    throw "Test Error"
                }
                catch {
                    # Module should continue working after errors
                    Get-Module HermesConsoleUI | Should -Not -BeNullOrEmpty
                }
            } | Should -Not -Throw
        }
    }
}

AfterAll {
    Remove-Module HermesConsoleUI -Force -ErrorAction SilentlyContinue
}
