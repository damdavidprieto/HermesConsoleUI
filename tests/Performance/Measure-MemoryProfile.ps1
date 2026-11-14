<#
.SYNOPSIS
    Profiles memory usage and detects memory leaks.

.DESCRIPTION
    Executes operations repeatedly to detect memory leaks and analyze memory consumption patterns.

.EXAMPLE
    .\Measure-MemoryProfile.ps1
#>

[CmdletBinding()]
param()

# Import HermesConsoleUI module
$modulePath = Join-Path $PSScriptRoot "..\..\HermesConsoleUI.psm1"
Import-Module $modulePath -Force

function Get-MemoryUsage {
    # Managed heap after a full collection. The process working set also counts native
    # memory and pages the OS trims or grows on its own, which made this check flaky on CI.
    [Math]::Round([GC]::GetTotalMemory($true) / 1MB, 2)
}

function Test-MemoryLeak {
    param(
        [scriptblock]$Operation,
        [string]$OperationName,
        [int]$Iterations = 1000
    )
    
    Write-Host "`nTesting: $OperationName" -ForegroundColor Yellow
    
    $memorySnapshots = @()
    $sampleInterval = [Math]::Max(1, $Iterations / 20) # Take 20 samples
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        & $Operation
        
        if ($i % $sampleInterval -eq 0) {
            $memorySnapshots += [PSCustomObject]@{
                Iteration = $i
                MemoryMB  = Get-MemoryUsage
            }
        }
    }
    
    # Force garbage collection
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()
    Start-Sleep -Milliseconds 500
    
    $memoryAfterGC = Get-MemoryUsage
    
    # Analyze trend
    $firstMemory = $memorySnapshots[0].MemoryMB
    $lastMemory = $memorySnapshots[-1].MemoryMB
    $memoryGrowth = $lastMemory - $firstMemory
    $memoryAfterGCDelta = $memoryAfterGC - $firstMemory
    
    $leakDetected = $memoryAfterGCDelta -gt 5 # More than 5MB growth after GC
    
    [PSCustomObject]@{
        OperationName        = $OperationName
        Iterations           = $Iterations
        InitialMemoryMB      = $firstMemory
        FinalMemoryMB        = $lastMemory
        MemoryGrowthMB       = [Math]::Round($memoryGrowth, 2)
        MemoryAfterGCMB      = $memoryAfterGC
        MemoryAfterGCDeltaMB = [Math]::Round($memoryAfterGCDelta, 2)
        LeakDetected         = $leakDetected
        Snapshots            = $memorySnapshots
    }
}

Write-Host "`n=== Memory Profiling ===" -ForegroundColor Cyan
Write-Host "Running memory leak detection tests...`n"

$results = @()

# Test 1: Table rendering
$results += Test-MemoryLeak -OperationName "Table Rendering (100 rows)" -Operation {
    $data = 1..100 | ForEach-Object {
        [PSCustomObject]@{ ID = $_; Name = "Item $_"; Value = $_ * 10 }
    }
    $null = $data | Format-Table | Out-String
}

# Test 2: String manipulation
$results += Test-MemoryLeak -OperationName "String Colorization" -Operation {
    $text = "This is a test string with multiple words"
    $null = $text -replace '(\w+)', "`e[32m`$1`e[0m"
}

# Test 3: Array operations
$results += Test-MemoryLeak -OperationName "Array Building" -Operation {
    $arr = @()
    for ($i = 0; $i -lt 50; $i++) {
        $arr += "Item $i"
    }
    $null = $arr
}

# Display results
Write-Host "`n=== Memory Leak Detection Results ===" -ForegroundColor Cyan
$results | Select-Object OperationName, Iterations, InitialMemoryMB, FinalMemoryMB, MemoryGrowthMB, MemoryAfterGCDeltaMB, LeakDetected | Format-Table -AutoSize

# Summary
$leaksFound = ($results | Where-Object { $_.LeakDetected }).Count
if ($leaksFound -gt 0) {
    Write-Host "`n⚠️  WARNING: $leaksFound potential memory leak(s) detected!" -ForegroundColor Red
}
else {
    Write-Host "`n✅ No memory leaks detected" -ForegroundColor Green
}

# Export results
$outputPath = Join-Path $PSScriptRoot "memory_profile_results.json"
$results | Select-Object -Property * -ExcludeProperty Snapshots | ConvertTo-Json -Depth 3 | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Yellow

return $results
