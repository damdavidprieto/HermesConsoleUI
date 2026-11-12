# HermesConsoleUI - Function Definitions Tests
# Validates that all expected functions are defined in module files

Describe "Module Files - Function Definitions" {
    
    Context "Helpers Module" {
        It "Should have helpers.ps1 file" {
            Test-Path "$PSScriptRoot\..\..\modules\helpers.ps1" | Should -Be $true
        }
        
        It "Should define Get-ConsoleBorder" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\helpers.ps1" -Raw
            $content | Should -Match "function Get-ConsoleBorder"
        }
        
        It "Should define Get-CenteredText" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\helpers.ps1" -Raw
            $content | Should -Match "function Get-CenteredText"
        }
        
        It "Should define Limit-Value" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\helpers.ps1" -Raw
            $content | Should -Match "function Limit-Value"
        }
    }
    
    Context "Text Components Module" {
        It "Should have text_components.ps1 file" {
            Test-Path "$PSScriptRoot\..\..\modules\text_components.ps1" | Should -Be $true
        }
        
        It "Should define Write-ConsoleHeader" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\text_components.ps1" -Raw
            $content | Should -Match "function Write-ConsoleHeader"
        }
        
        It "Should define Write-ConsoleTitle" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\text_components.ps1" -Raw
            $content | Should -Match "function Write-ConsoleTitle"
        }
        
        It "Should define Write-ConsoleError" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\text_components.ps1" -Raw
            $content | Should -Match "function Write-ConsoleError"
        }
    }
    
    Context "Visual Components Module" {
        It "Should have visual_components.ps1 file" {
            Test-Path "$PSScriptRoot\..\..\modules\visual_components.ps1" | Should -Be $true
        }
        
        It "Should define Write-ConsoleBox" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\visual_components.ps1" -Raw
            $content | Should -Match "function Write-ConsoleBox"
        }
    }
    
    Context "Interactive Components Module" {
        It "Should have interactive_components.ps1 file" {
            Test-Path "$PSScriptRoot\..\..\modules\interactive_components.ps1" | Should -Be $true
        }
        
        It "Should define Show-ConsoleMenu" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\interactive_components.ps1" -Raw
            $content | Should -Match "function Show-ConsoleMenu"
        }
        
        It "Should define Read-ConsoleInput" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\interactive_components.ps1" -Raw
            $content | Should -Match "function Read-ConsoleInput"
        }
    }
    
    Context "Layout Components Module" {
        It "Should have layout_components.ps1 file" {
            Test-Path "$PSScriptRoot\..\..\modules\layout_components.ps1" | Should -Be $true
        }
        
        It "Should define New-ConsoleRow" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\layout_components.ps1" -Raw
            $content | Should -Match "function New-ConsoleRow"
        }
        
        It "Should define New-ConsoleColumn" {
            $content = Get-Content "$PSScriptRoot\..\..\modules\layout_components.ps1" -Raw
            $content | Should -Match "function New-ConsoleColumn"
        }
    }
}
