<#
.SYNOPSIS
    Benchmarks menu interaction performance.

.DESCRIPTION
    Measures rendering time and memory usage for menus with different numbers of options.

.EXAMPLE
    .\Benchmark-MenuInteraction.ps1
#>

[CmdletBinding()]
param()

# Import HermesConsoleUI module
$modulePath = Join-Path $PSScriptRoot "..\..\HermesConsoleUI.psm1"
Import-Module $modulePath -Force

function Get-MemoryUsage {
    $process = Get-Process -Id $PID
    [Math]::Round($process.WorkingSet64 / 1MB, 2)
}

function Invoke-MenuBenchmark {
    param(
        [int]$OptionCount,
        [int]$Iterations = 10
    )
    
    # Generate menu options
    $options = 1..$OptionCount | ForEach-Object { "Option $_" }
    
    $times = @()
    $memoryBefore = Get-MemoryUsage
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        $measure = Measure-Command {
            # Simulate menu rendering (without actual display)
            $menuText = @()
            $menuText += "=== Menu Title ==="
            for ($j = 0; $j -lt $options.Count; $j++) {
                $menuText += "[$j] $($options[$j])"
            }
            $null = $menuText -join "`n"
        }
        $times += $measure.TotalMilliseconds
    }
    
    $memoryAfter = Get-MemoryUsage
    $avgTime = ($times | Measure-Object -Average).Average
    
    [PSCustomObject]@{
        OptionCount = $OptionCount
        AvgTimeMs   = [Math]::Round($avgTime, 2)
        MinTimeMs   = [Math]::Round(($times | Measure-Object -Minimum).Minimum, 2)
        MaxTimeMs   = [Math]::Round(($times | Measure-Object -Maximum).Maximum, 2)
        MemoryMB    = [Math]::Round($memoryAfter - $memoryBefore, 2)
        Iterations  = $Iterations
    }
}

Write-Host "`n=== Menu Interaction Benchmark ===" -ForegroundColor Cyan
Write-Host "Testing menu rendering with various option counts...`n"

$results = @()
$testCases = @(5, 10, 25, 50, 100, 200)

foreach ($optionCount in $testCases) {
    Write-Host "Testing $optionCount options..." -NoNewline
    $result = Invoke-MenuBenchmark -OptionCount $optionCount
    $results += $result
    Write-Host " Done (Avg: $($result.AvgTimeMs)ms)" -ForegroundColor Green
}

# Display results
Write-Host "`n=== Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Export to JSON
$outputPath = Join-Path $PSScriptRoot "benchmark_menu_results.json"
$results | ConvertTo-Json | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Yellow

return $results
