<#
.SYNOPSIS
    Benchmarks color and ANSI code processing performance.

.DESCRIPTION
    Measures performance of color processing and ANSI escape code handling.

.EXAMPLE
    .\Benchmark-ColorProcessing.ps1
#>

[CmdletBinding()]
param()

function Get-MemoryUsage {
    $process = Get-Process -Id $PID
    [Math]::Round($process.WorkingSet64 / 1MB, 2)
}

function Invoke-ColorBenchmark {
    param(
        [int]$WordCount,
        [int]$Iterations = 100
    )
    
    # Generate test text
    $words = 1..$WordCount | ForEach-Object { "Word$_" }
    $text = $words -join " "
    
    $times = @()
    $memoryBefore = Get-MemoryUsage
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        $measure = Measure-Command {
            # Simulate ANSI colorization
            $colored = $text -replace '(\w+)', "`e[32m`$1`e[0m"
            $null = $colored
        }
        $times += $measure.TotalMilliseconds
    }
    
    $memoryAfter = Get-MemoryUsage
    $avgTime = ($times | Measure-Object -Average).Average
    
    [PSCustomObject]@{
        WordCount  = $WordCount
        AvgTimeMs  = [Math]::Round($avgTime, 4)
        MinTimeMs  = [Math]::Round(($times | Measure-Object -Minimum).Minimum, 4)
        MaxTimeMs  = [Math]::Round(($times | Measure-Object -Maximum).Maximum, 4)
        MemoryMB   = [Math]::Round($memoryAfter - $memoryBefore, 2)
        Iterations = $Iterations
    }
}

function Invoke-ANSIProcessingBenchmark {
    param(
        [int]$CodeCount,
        [int]$Iterations = 100
    )
    
    # Generate text with ANSI codes
    $text = ""
    for ($i = 0; $i -lt $CodeCount; $i++) {
        $text += "`e[3$($i % 8)mText$i`e[0m "
    }
    
    $times = @()
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        $measure = Measure-Command {
            # Simulate ANSI code stripping
            $stripped = $text -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
            $null = $stripped
        }
        $times += $measure.TotalMilliseconds
    }
    
    $avgTime = ($times | Measure-Object -Average).Average
    
    [PSCustomObject]@{
        ANSICodeCount = $CodeCount
        AvgTimeMs     = [Math]::Round($avgTime, 4)
        MinTimeMs     = [Math]::Round(($times | Measure-Object -Minimum).Minimum, 4)
        MaxTimeMs     = [Math]::Round(($times | Measure-Object -Maximum).Maximum, 4)
        Iterations    = $Iterations
    }
}

Write-Host "`n=== Color Processing Benchmark ===" -ForegroundColor Cyan
Write-Host "Testing color and ANSI processing performance...`n"

# Test colorization
Write-Host "Testing colorization..." -ForegroundColor Yellow
$colorResults = @()
$wordCounts = @(10, 50, 100, 500, 1000)

foreach ($wordCount in $wordCounts) {
    Write-Host "  $wordCount words..." -NoNewline
    $result = Invoke-ColorBenchmark -WordCount $wordCount
    $colorResults += $result
    Write-Host " Done (Avg: $($result.AvgTimeMs)ms)" -ForegroundColor Green
}

Write-Host "`n=== Colorization Results ===" -ForegroundColor Cyan
$colorResults | Format-Table -AutoSize

# Test ANSI processing
Write-Host "`nTesting ANSI code processing..." -ForegroundColor Yellow
$ansiResults = @()
$codeCounts = @(10, 50, 100, 500, 1000)

foreach ($codeCount in $codeCounts) {
    Write-Host "  $codeCount codes..." -NoNewline
    $result = Invoke-ANSIProcessingBenchmark -CodeCount $codeCount
    $ansiResults += $result
    Write-Host " Done (Avg: $($result.AvgTimeMs)ms)" -ForegroundColor Green
}

Write-Host "`n=== ANSI Processing Results ===" -ForegroundColor Cyan
$ansiResults | Format-Table -AutoSize

# Export results
$outputPath = Join-Path $PSScriptRoot "benchmark_color_results.json"
@{
    Colorization   = $colorResults
    ANSIProcessing = $ansiResults
} | ConvertTo-Json -Depth 3 | Out-File $outputPath

Write-Host "`nResults exported to: $outputPath" -ForegroundColor Yellow

return @{
    Colorization   = $colorResults
    ANSIProcessing = $ansiResults
}
