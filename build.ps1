# build.ps1 - HermesConsoleUI Build & Test Automation

param(
    [switch]$InstallDependencies,
    [switch]$SkipTests,
    [switch]$Publish
)

$ErrorActionPreference = "Stop"

Write-Host "Starting HermesConsoleUI Build..." -ForegroundColor Cyan

if ($InstallDependencies) {
    Write-Host "Installing dependencies (Pester, PSScriptAnalyzer)..." -ForegroundColor Yellow
    Install-Module Pester -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction SilentlyContinue
    Install-Module PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction SilentlyContinue
}

# 1. Static Code Analysis
Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Cyan
$saResults = Invoke-ScriptAnalyzer -Path "$PSScriptRoot" -Recurse -Severity Error, Warning
if ($saResults) {
    $saResults | Format-Table
    if ($saResults | Where-Object { $_.Severity -eq "Error" }) {
        Write-Error "Build Failed: PSScriptAnalyzer found errors."
    }
}
else {
    Write-Host "Code Analysis Passed." -ForegroundColor Green
}

# 2. Testing
if (-not $SkipTests) {
    Write-Host "Running Pester Tests..." -ForegroundColor Cyan
    # Check if Tests folder exists (case insensitive check usually works, but being specific helps)
    $testPath = "$PSScriptRoot\Tests"
    if (-not (Test-Path $testPath)) {
        $testPath = "$PSScriptRoot\tests"
    }

    if (Test-Path $testPath) {
        $pester = Invoke-Pester -Path $testPath -PassThru -Output Detailed
        if ($pester.FailedCount -gt 0) {
            Write-Error "Build Failed: $($pester.FailedCount) tests failed."
        }
        Write-Host "All Tests Passed." -ForegroundColor Green
    }
    else {
        Write-Warning "No Tests directory found. Skipping tests."
    }
}

# 3. Validation
Write-Host "Validating Module Manifest..." -ForegroundColor Cyan
Test-ModuleManifest -Path "$PSScriptRoot\HermesConsoleUI.psd1" | Out-Null
Write-Host "Manifest Valid." -ForegroundColor Green

Write-Host "Build Complete!" -ForegroundColor Green

if ($Publish) {
    Write-Host "Creating Prerelease Artifact..." -ForegroundColor Cyan
    $prereleaseDir = Join-Path $PSScriptRoot "..\HermesConsoleUI_PreRelease"
    $prereleaseDir = [System.IO.Path]::GetFullPath($prereleaseDir)
    
    if (Test-Path $prereleaseDir) { Remove-Item $prereleaseDir -Recurse -Force }
    New-Item -Path $prereleaseDir -ItemType Directory -Force | Out-Null

    # Read FileList from Manifest
    $manifest = Import-PowerShellDataFile "$PSScriptRoot\HermesConsoleUI.psd1"
    $filesToCopy = $manifest.FileList

    foreach ($file in $filesToCopy) {
        $src = Join-Path $PSScriptRoot $file
        $dest = Join-Path $prereleaseDir $file
        
        if (Test-Path $src) {
            $parent = Split-Path $dest -Parent
            if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }
            Copy-Item -Path $src -Destination $dest -Force
        }
        else {
            Write-Warning "File listed in manifest not found: $file"
        }
    }
    
    # Add Release README
    $releaseReadme = Join-Path $prereleaseDir "README_PRERELEASE.md"
    @"
# HermesConsoleUI - PreRelease Version

This directory contains the production-ready build of the HermesConsoleUI module.

## Installation

1. Copy this entire folder to your PowerShell Modules directory:
   ``$HOME\Documents\WindowsPowerShell\Modules\HermesConsoleUI``

2. Import the module:
   ``Import-Module HermesConsoleUI``

## Documentation
See the ``docs`` folder for full documentation.
"@ | Set-Content $releaseReadme
    
    Write-Host "✅ Prerelease artifact created at: $prereleaseDir" -ForegroundColor Green
}
