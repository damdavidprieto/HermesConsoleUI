# HermesConsoleUI - Structure and Manifest Tests
# Tests that validate project structure without loading the full module

Describe "HermesConsoleUI Project Structure" {
    
    Context "Required Files Exist" {
        It "Should have a module manifest (psd1)" {
            Test-Path "$PSScriptRoot\..\..\HermesConsoleUI.psd1" | Should -Be $true
        }
        
        It "Should have a root module (psm1)" {
            Test-Path "$PSScriptRoot\..\..\HermesConsoleUI.psm1" | Should -Be $true
        }
        
        It "Should have a src directory" {
            Test-Path "$PSScriptRoot\..\..\src" | Should -Be $true
        }
        
        It "Should have a tests directory" {
            Test-Path "$PSScriptRoot\..\..\tests" | Should -Be $true
        }
    }
    
    Context "Manifest Validation" {
        It "Should have a valid manifest file" {
            $manifestPath = "$PSScriptRoot\..\..\HermesConsoleUI.psd1"
            { Test-ModuleManifest -Path $manifestPath } | Should -Not -Throw
        }
        
        It "Should have version 2.0 or higher" {
            $manifest = Import-PowerShellDataFile -Path "$PSScriptRoot\..\..\HermesConsoleUI.psd1"
            $manifest.ModuleVersion | Should -Match "^2\."
        }
        
        It "Should have an author" {
            $manifest = Import-PowerShellDataFile -Path "$PSScriptRoot\..\..\HermesConsoleUI.psd1"
            $manifest.Author | Should -Not -BeNullOrEmpty
        }
        
        It "Should have a description" {
            $manifest = Import-PowerShellDataFile -Path "$PSScriptRoot\..\..\HermesConsoleUI.psd1"
            $manifest.Description | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Source Code Structure" {
        It "Should have Core directory" {
            Test-Path "$PSScriptRoot\..\..\src\Core" | Should -Be $true
        }
        
        It "Should have configuration files" {
            $coreFiles = Get-ChildItem "$PSScriptRoot\..\..\src\Core" -Filter "*.ps1"
            $coreFiles.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Testing Infrastructure" {
        It "Should have TestHelpers module" {
            Test-Path "$PSScriptRoot\..\TestHelpers.psm1" | Should -Be $true
        }
        
        It "Should have Unit tests directory" {
            Test-Path "$PSScriptRoot" | Should -Be $true
        }
        
        It "Should have Integration tests directory" {
            Test-Path "$PSScriptRoot\..\Integration" | Should -Be $true
        }
    }
}
