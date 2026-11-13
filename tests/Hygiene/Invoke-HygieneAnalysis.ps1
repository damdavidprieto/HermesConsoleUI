<#
.SYNOPSIS
    Master script to run all hygiene analyses.

.DESCRIPTION
    Executes all hygiene analysis scripts and generates a consolidated report.

.EXAMPLE
    .\Invoke-HygieneAnalysis.ps1
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)

$ErrorActionPreference = 'Continue'

Write-Host "`n=== HermesConsoleUI Hygiene Analysis Suite ===" -ForegroundColor Cyan
Write-Host "Version 1.0`n" -ForegroundColor Cyan

$startTime = Get-Date
$results = @{}

# Run File Structure Analysis
Write-Host "[1/5] Running File Structure Analysis..." -ForegroundColor Yellow
try {
    $results.FileStructure = & "$PSScriptRoot\Analyze-FileStructure.ps1" -ProjectRoot $ProjectRoot
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $results.FileStructure = $null
}

# Run Temporary Files Detection
Write-Host "`n[2/5] Running Temporary Files Detection..." -ForegroundColor Yellow
try {
    $results.TemporaryFiles = & "$PSScriptRoot\Find-TemporaryFiles.ps1" -ProjectRoot $ProjectRoot
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $results.TemporaryFiles = $null
}

# Run File Size Analysis
Write-Host "`n[3/5] Running File Size Analysis..." -ForegroundColor Yellow
try {
    $results.FileSize = & "$PSScriptRoot\Analyze-FileSize.ps1" -ProjectRoot $ProjectRoot
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $results.FileSize = $null
}

# Run Naming Convention Validation
Write-Host "`n[4/5] Running Naming Convention Validation..." -ForegroundColor Yellow
try {
    $results.NamingConventions = & "$PSScriptRoot\Test-NamingConventions.ps1" -ProjectRoot $ProjectRoot
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $results.NamingConventions = $null
}

# Run .gitignore Analysis
Write-Host "`n[5/5] Running .gitignore Analysis..." -ForegroundColor Yellow
try {
    $results.GitIgnore = & "$PSScriptRoot\Analyze-GitIgnore.ps1" -ProjectRoot $ProjectRoot
}
catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    $results.GitIgnore = $null
}

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalSeconds

# Generate Summary
Write-Host "`n`n=== HYGIENE ANALYSIS SUMMARY ===" -ForegroundColor Cyan
Write-Host "Execution Time: $([Math]::Round($totalDuration, 2)) seconds" -ForegroundColor Green
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green

Write-Host "`n=== Key Metrics ===" -ForegroundColor Yellow

if ($results.FileStructure) {
    Write-Host "Files: $($results.FileStructure.TotalFiles)"
    Write-Host "Directories: $($results.FileStructure.TotalDirectories)"
    Write-Host "Max Depth: $($results.FileStructure.MaxDepth) levels"
}

if ($results.FileSize) {
    Write-Host "Total Size: $($results.FileSize.TotalSizeKB) KB ($($results.FileSize.TotalSizeMB) MB)"
    Write-Host "Blob Files: $($results.FileSize.BlobFiles.Count)"
}

if ($results.TemporaryFiles) {
    $tempIssues = $results.TemporaryFiles.TotalIssues
    if ($tempIssues -eq 0) {
        Write-Host "Temporary Files: ✅ None" -ForegroundColor Green
    }
    else {
        Write-Host "Temporary Files: ⚠️  $tempIssues found" -ForegroundColor Yellow
    }
}

if ($results.NamingConventions) {
    Write-Host "Naming Compliance: $($results.NamingConventions.ComplianceRate)%"
}

if ($results.GitIgnore) {
    Write-Host ".gitignore Score: $($results.GitIgnore.Score)/10"
}

# Calculate overall hygiene score
$overallScore = 0
$scoreCount = 0

if ($results.FileStructure -and $results.FileStructure.EmptyDirectories.Count -eq 0) {
    $overallScore += 10
    $scoreCount++
}

if ($results.TemporaryFiles -and $results.TemporaryFiles.TotalIssues -eq 0) {
    $overallScore += 10
    $scoreCount++
}

if ($results.FileSize -and $results.FileSize.BlobFiles.Count -eq 0) {
    $overallScore += 10
    $scoreCount++
}

if ($results.NamingConventions) {
    $overallScore += ($results.NamingConventions.ComplianceRate / 10)
    $scoreCount++
}

if ($results.GitIgnore) {
    $overallScore += $results.GitIgnore.Score
    $scoreCount++
}

$finalScore = if ($scoreCount -gt 0) { [Math]::Round($overallScore / $scoreCount, 1) } else { 0 }

Write-Host "`n=== OVERALL HYGIENE SCORE ===" -ForegroundColor Cyan
Write-Host "$finalScore / 10" -ForegroundColor $(if ($finalScore -ge 9) { "Green" } elseif ($finalScore -ge 7) { "Yellow" } else { "Red" })

# Export consolidated results
$consolidatedResults = @{
    Metadata = @{
        Timestamp            = Get-Date -Format 'o'
        ProjectRoot          = $ProjectRoot
        PowerShellVersion    = $PSVersionTable.PSVersion.ToString()
        TotalDurationSeconds = [Math]::Round($totalDuration, 2)
        OverallScore         = $finalScore
    }
    Results  = $results
}

$jsonPath = Join-Path $PSScriptRoot "hygiene_consolidated_results.json"
$consolidatedResults | ConvertTo-Json -Depth 10 | Out-File $jsonPath
Write-Host "`nConsolidated results: $jsonPath" -ForegroundColor Yellow

Write-Host "`nAll hygiene analyses completed!`n" -ForegroundColor Green

return $consolidatedResults
