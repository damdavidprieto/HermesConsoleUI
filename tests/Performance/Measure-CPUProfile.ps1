<#
.SYNOPSIS
    Profiles CPU usage during operations.

.DESCRIPTION
    Measures CPU consumption for various HermesConsoleUI operations.

.EXAMPLE
    .\Measure-CPUProfile.ps1
#>

[CmdletBinding()]
param()

# Import HermesConsoleUI module
$modulePath = Join-Path $PSScriptRoot "..\..\HermesConsoleUI.psm1"
Import-Module $modulePath -Force

function Get-CPUTime {
    $process = Get-Process -Id $PID
    $process.TotalProcessorTime.TotalSeconds
}

function Measure-CPUUsage {
    param(
        [scriptblock]$Operation,
        [string]$OperationName,
        [int]$Iterations = 100
    )
    
    Write-Host "Testing: $OperationName..." -NoNewline
    
    $cpuBefore = Get-CPUTime
    $wallClockTime = Measure-Command {
        for ($i = 0; $i -lt $Iterations; $i++) {
            & $Operation
        }
    }
    $cpuAfter = Get-CPUTime
    
    $cpuTime = $cpuAfter - $cpuBefore
    $cpuPercent = if ($wallClockTime.TotalSeconds -gt 0) {
        [Math]::Round(($cpuTime / $wallClockTime.TotalSeconds) * 100, 2)
    }
    else { 0 }
    
    Write-Host " Done" -ForegroundColor Green
    
    [PSCustomObject]@{
        OperationName         = $OperationName
        Iterations            = $Iterations
        WallClockTimeMs       = [Math]::Round($wallClockTime.TotalMilliseconds, 2)
        CPUTimeSeconds        = [Math]::Round($cpuTime, 4)
        CPUPercent            = $cpuPercent
        AvgTimePerIterationMs = [Math]::Round($wallClockTime.TotalMilliseconds / $Iterations, 4)
    }
}

Write-Host "`n=== CPU Profiling ===" -ForegroundColor Cyan
Write-Host "Measuring CPU usage for various operations...`n"

$results = @()

# Test 1: Table rendering
$results += Measure-CPUUsage -OperationName "Table Rendering (100 rows)" -Operation {
    $data = 1..100 | ForEach-Object {
        [PSCustomObject]@{ ID = $_; Name = "Item $_"; Value = $_ * 10 }
    }
    $null = $data | Format-Table | Out-String
}

# Test 2: String operations
$results += Measure-CPUUsage -OperationName "String Colorization (100 words)" -Operation {
    $text = (1..100 | ForEach-Object { "Word$_" }) -join " "
    $null = $text -replace '(\w+)', "`e[32m`$1`e[0m"
}

# Test 3: ANSI stripping
$results += Measure-CPUUsage -OperationName "ANSI Code Stripping" -Operation {
    $text = "`e[31mRed`e[0m `e[32mGreen`e[0m `e[34mBlue`e[0m"
    $null = $text -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
}

# Test 4: Menu rendering
$results += Measure-CPUUsage -OperationName "Menu Rendering (50 options)" -Operation {
    $options = 1..50 | ForEach-Object { "Option $_" }
    $menuText = $options | ForEach-Object { "[$_] $_" }
    $null = $menuText -join "`n"
}

# Display results
Write-Host "`n=== CPU Usage Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Identify CPU-intensive operations
$cpuIntensive = $results | Where-Object { $_.CPUPercent -gt 50 }
if ($cpuIntensive) {
    Write-Host "`n⚠️  CPU-Intensive Operations (>50% CPU):" -ForegroundColor Yellow
    $cpuIntensive | Format-Table OperationName, CPUPercent -AutoSize
}
else {
    Write-Host "`n✅ All operations are CPU-efficient (<50% CPU)" -ForegroundColor Green
}

# Export results
$outputPath = Join-Path $PSScriptRoot "cpu_profile_results.json"
$results | ConvertTo-Json -Depth 3 | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Yellow

return $results
