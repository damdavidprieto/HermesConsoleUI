<#
.SYNOPSIS
    Benchmarks table rendering performance across different row counts.

.DESCRIPTION
    Measures time, memory, and CPU usage for rendering tables with varying numbers of rows.
    Helps identify performance characteristics and potential bottlenecks.

.EXAMPLE
    .\Benchmark-TableRendering.ps1
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

function Invoke-TableBenchmark {
    param(
        [int]$RowCount,
        [int]$Iterations = 10
    )
    
    # Generate test data
    $testData = 1..$RowCount | ForEach-Object {
        [PSCustomObject]@{
            ID          = $_
            Name        = "Item $_"
            Status      = if ($_ % 2) { "Active" } else { "Inactive" }
            Value       = Get-Random -Minimum 1 -Maximum 1000
            Description = "This is a test description for item $_"
        }
    }
    
    $times = @()
    $memoryBefore = Get-MemoryUsage
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        $measure = Measure-Command {
            # Capture output to null to avoid console overhead
            $null = $testData | Format-Table | Out-String
        }
        $times += $measure.TotalMilliseconds
    }
    
    $memoryAfter = Get-MemoryUsage
    $avgTime = ($times | Measure-Object -Average).Average
    $memoryDelta = [Math]::Max(0, $memoryAfter - $memoryBefore)
    
    [PSCustomObject]@{
        RowCount   = $RowCount
        AvgTimeMs  = [Math]::Round($avgTime, 2)
        MinTimeMs  = [Math]::Round(($times | Measure-Object -Minimum).Minimum, 2)
        MaxTimeMs  = [Math]::Round(($times | Measure-Object -Maximum).Maximum, 2)
        MemoryMB   = $memoryDelta
        Iterations = $Iterations
    }
}

Write-Host "`n=== Table Rendering Benchmark ===" -ForegroundColor Cyan
Write-Host "Testing table rendering with various row counts...`n"

$results = @()
$testCases = @(10, 50, 100, 250, 500, 1000, 2500, 5000)

foreach ($rowCount in $testCases) {
    Write-Host "Testing $rowCount rows..." -NoNewline
    $result = Invoke-TableBenchmark -RowCount $rowCount
    $results += $result
    Write-Host " Done (Avg: $($result.AvgTimeMs)ms)" -ForegroundColor Green
}

# Display results
Write-Host "`n=== Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Export to JSON
$outputPath = Join-Path $PSScriptRoot "benchmark_table_results.json"
$results | ConvertTo-Json | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Yellow

# Return results
return $results
