<#
.SYNOPSIS
    Benchmarks spinner animation performance.

.DESCRIPTION
    Measures CPU and memory usage during spinner animations.
    Tests different spinner types and durations.

.EXAMPLE
    .\Benchmark-Spinners.ps1
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

function Get-CPUUsage {
    $process = Get-Process -Id $PID
    [Math]::Round($process.CPU, 2)
}

function Invoke-SpinnerBenchmark {
    param(
        [int]$DurationSeconds = 3,
        [string]$SpinnerType = "dots"
    )
    
    $memoryBefore = Get-MemoryUsage
    $cpuBefore = Get-CPUUsage
    
    $measure = Measure-Command {
        # Simulate spinner animation
        $frames = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
        $frameIndex = 0
        $endTime = (Get-Date).AddSeconds($DurationSeconds)
        
        while ((Get-Date) -lt $endTime) {
            $frame = $frames[$frameIndex % $frames.Count]
            # Simulate console write (without actual output to avoid clutter)
            $null = "$frame Processing..."
            Start-Sleep -Milliseconds 80
            $frameIndex++
        }
    }
    
    $memoryAfter = Get-MemoryUsage
    $cpuAfter = Get-CPUUsage
    
    [PSCustomObject]@{
        SpinnerType     = $SpinnerType
        DurationSeconds = $DurationSeconds
        TotalTimeMs     = [Math]::Round($measure.TotalMilliseconds, 2)
        MemoryDeltaMB   = [Math]::Round($memoryAfter - $memoryBefore, 2)
        CPUDelta        = [Math]::Round($cpuAfter - $cpuBefore, 2)
        FramesRendered  = $frameIndex
        AvgFrameTimeMs  = [Math]::Round($measure.TotalMilliseconds / $frameIndex, 2)
    }
}

Write-Host "`n=== Spinner Animation Benchmark ===" -ForegroundColor Cyan
Write-Host "Testing spinner performance...`n"

$results = @()

# Test different durations
$durations = @(2, 5, 10)

foreach ($duration in $durations) {
    Write-Host "Testing $duration second animation..." -NoNewline
    $result = Invoke-SpinnerBenchmark -DurationSeconds $duration
    $results += $result
    Write-Host " Done (Frames: $($result.FramesRendered))" -ForegroundColor Green
}

# Display results
Write-Host "`n=== Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Export to JSON
$outputPath = Join-Path $PSScriptRoot "benchmark_spinner_results.json"
$results | ConvertTo-Json | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Yellow

return $results
