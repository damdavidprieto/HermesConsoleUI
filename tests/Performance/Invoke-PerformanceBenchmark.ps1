<#
.SYNOPSIS
    Master script to run all performance benchmarks.

.DESCRIPTION
    Executes all benchmark and profiling scripts, consolidates results,
    and generates a comprehensive performance report.

.EXAMPLE
    .\Invoke-PerformanceBenchmark.ps1
#>

[CmdletBinding()]
param(
    [switch]$ExportMarkdown
)

$ErrorActionPreference = 'Continue'

Write-Host "`n=== HermesConsoleUI Performance Benchmark Suite ===" -ForegroundColor Cyan
Write-Host "Version 1.0`n" -ForegroundColor Cyan

$startTime = Get-Date
$benchmarkResults = @{}

# Run Table Rendering Benchmark
Write-Host "[1/6] Running Table Rendering Benchmark..." -ForegroundColor Yellow
try {
    $benchmarkResults.TableRendering = & "$PSScriptRoot\Benchmark-TableRendering.ps1"
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $benchmarkResults.TableRendering = $null
}

# Run Spinner Benchmark
Write-Host "`n[2/6] Running Spinner Benchmark..." -ForegroundColor Yellow
try {
    $benchmarkResults.Spinners = & "$PSScriptRoot\Benchmark-Spinners.ps1"
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $benchmarkResults.Spinners = $null
}

# Run Menu Benchmark
Write-Host "`n[3/6] Running Menu Interaction Benchmark..." -ForegroundColor Yellow
try {
    $benchmarkResults.MenuInteraction = & "$PSScriptRoot\Benchmark-MenuInteraction.ps1"
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $benchmarkResults.MenuInteraction = $null
}

# Run Color Processing Benchmark
Write-Host "`n[4/6] Running Color Processing Benchmark..." -ForegroundColor Yellow
try {
    $benchmarkResults.ColorProcessing = & "$PSScriptRoot\Benchmark-ColorProcessing.ps1"
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $benchmarkResults.ColorProcessing = $null
}

# Run Memory Profiling
Write-Host "`n[5/6] Running Memory Profiling..." -ForegroundColor Yellow
try {
    $benchmarkResults.MemoryProfile = & "$PSScriptRoot\Measure-MemoryProfile.ps1"
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $benchmarkResults.MemoryProfile = $null
}

# Run CPU Profiling
Write-Host "`n[6/6] Running CPU Profiling..." -ForegroundColor Yellow
try {
    $benchmarkResults.CPUProfile = & "$PSScriptRoot\Measure-CPUProfile.ps1"
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $benchmarkResults.CPUProfile = $null
}

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalSeconds

# Generate Summary
Write-Host "`n=== BENCHMARK SUMMARY ===" -ForegroundColor Cyan
Write-Host "Execution Time: $([Math]::Round($totalDuration, 2)) seconds" -ForegroundColor Green
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green

# Export consolidated results
$consolidatedResults = @{
    Metadata = @{
        Timestamp            = Get-Date -Format 'o'
        PowerShellVersion    = $PSVersionTable.PSVersion.ToString()
        OS                   = [System.Environment]::OSVersion.VersionString
        TotalDurationSeconds = [Math]::Round($totalDuration, 2)
    }
    Results  = $benchmarkResults
}

$jsonPath = Join-Path $PSScriptRoot "benchmark_consolidated_results.json"
$consolidatedResults | ConvertTo-Json -Depth 10 | Out-File $jsonPath
Write-Host "`nConsolidated results: $jsonPath" -ForegroundColor Yellow

Write-Host "`nAll benchmarks completed!`n" -ForegroundColor Green

return $consolidatedResults
