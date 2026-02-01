<#
.SYNOPSIS
    Pester tests for performance regression detection.

.DESCRIPTION
    Validates that performance has not degraded by comparing current benchmarks
    against baseline metrics.
#>

BeforeAll {
    $baselinePath = Join-Path $PSScriptRoot "PerformanceBaseline.json"
    $script:baseline = Get-Content $baselinePath | ConvertFrom-Json
}

Describe "Performance Regression Tests" {
    
    Context "Table Rendering Performance" {
        
        It "Should render 100 rows within threshold" {
            # Run benchmark
            $result = & "$PSScriptRoot\Benchmark-TableRendering.ps1"
            $result100 = $result | Where-Object { $_.RowCount -eq 100 }
            
            # Compare against baseline
            $threshold = $baseline.benchmarks.table_rendering.'100_rows'.threshold_time_ms
            $result100.AvgTimeMs | Should -BeLessThan $threshold
        }
        
        It "Should not exceed memory threshold for 100 rows" {
            $result = & "$PSScriptRoot\Benchmark-TableRendering.ps1"
            $result100 = $result | Where-Object { $_.RowCount -eq 100 }
            
            $threshold = $baseline.benchmarks.table_rendering.'100_rows'.threshold_memory_mb
            $result100.MemoryMB | Should -BeLessThan $threshold
        }
    }
    
    Context "Menu Interaction Performance" {
        
        It "Should render 100 options within threshold" {
            $result = & "$PSScriptRoot\Benchmark-MenuInteraction.ps1"
            $result100 = $result | Where-Object { $_.OptionCount -eq 100 }
            
            $threshold = $baseline.benchmarks.menu_interaction.'100_options'.threshold_time_ms
            $result100.AvgTimeMs | Should -BeLessThan $threshold
        }
    }
    
    Context "Memory Leak Detection" {
        
        It "Should not have memory leaks" {
            $result = & "$PSScriptRoot\Measure-MemoryProfile.ps1"
            $leaks = $result | Where-Object { $_.LeakDetected -eq $true }
            
            $leaks.Count | Should -Be 0
        }
    }
    
    Context "CPU Efficiency" {
        
        It "Should maintain CPU efficiency" {
            $result = & "$PSScriptRoot\Measure-CPUProfile.ps1"
            $cpuIntensive = $result | Where-Object { $_.CPUPercent -gt 80 }
            
            # No operation should use more than 80% CPU
            $cpuIntensive.Count | Should -Be 0
        }
    }
}
