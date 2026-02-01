# ============================================================================
# HermesConsoleUI - Installation Script
# ============================================================================
# This script installs HermesConsoleUI to your PowerShell modules path
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser',
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ModuleName = "HermesConsoleUI"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       HermesConsoleUI - Installation Script" -ForegroundColor Cyan
Write-Host "       The Messenger of Your Terminal" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Determine installation path
$modulePath = if ($Scope -eq 'AllUsers') {
    "$env:ProgramFiles\WindowsPowerShell\Modules"
} else {
    "$HOME\Documents\WindowsPowerShell\Modules"
}

$targetPath = Join-Path $modulePath $ModuleName

Write-Host "[INFO] Installation scope: $Scope" -ForegroundColor Cyan
Write-Host "[INFO] Target path: $targetPath" -ForegroundColor Cyan
Write-Host ""

# Check if already installed
if (Test-Path $targetPath) {
    if (-not $Force) {
        Write-Host "[WARNING] $ModuleName is already installed at: $targetPath" -ForegroundColor Yellow
        $response = Read-Host "Do you want to overwrite? (Y/N)"
        if ($response -notmatch '^[Yy]') {
            Write-Host "[CANCELLED] Installation cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    Write-Host "[INFO] Removing existing installation..." -ForegroundColor Yellow
    Remove-Item $targetPath -Recurse -Force
}

# Create target directory
Write-Host "[INFO] Creating module directory..." -ForegroundColor Cyan
New-Item -Path $targetPath -ItemType Directory -Force | Out-Null

# Copy files
Write-Host "[INFO] Copying module files..." -ForegroundColor Cyan
$sourceRoot = $PSScriptRoot

$filesToCopy = @(
    "HermesConsoleUI.psm1",
    "HermesConsoleUI.psd1",
    "LICENSE",
    "README.md"
)

foreach ($file in $filesToCopy) {
    $source = Join-Path $sourceRoot $file
    if (Test-Path $source) {
        Copy-Item $source $targetPath -Force
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] $file (not found)" -ForegroundColor Yellow
    }
}

# Copy directories
# Includes modules, configs, docs, examples, and source code
$dirsToCopy = @("config", "docs", "modules", "src", "examples")

foreach ($dir in $dirsToCopy) {
    $source = Join-Path $sourceRoot $dir
    if (Test-Path $source) {
        Copy-Item $source (Join-Path $targetPath $dir) -Recurse -Force
        Write-Host "  [OK] $dir\" -ForegroundColor Green
    }
}

# Verify installation
Write-Host ""
Write-Host "[INFO] Verifying installation..." -ForegroundColor Cyan

try {
    # Unload if currently loaded
    if (Get-Module $ModuleName) {
        Remove-Module $ModuleName
    }

    Import-Module $targetPath -Force -ErrorAction Stop
    Write-Host "  [OK] Module loaded successfully" -ForegroundColor Green
    
    # Test a function
    $testFunc = Get-Command Write-ConsoleStatus -ErrorAction SilentlyContinue
    if ($testFunc) {
        Write-Host "  [OK] Functions exported correctly" -ForegroundColor Green
    } else {
        throw "Functions not exported"
    }
    
    Remove-Module $ModuleName
} catch {
    Write-Host "  [ERROR] Module verification failed: $_" -ForegroundColor Red
    exit 1
}

# Success
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "       Installation Completed Successfully!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "To use the module, run:" -ForegroundColor Cyan
Write-Host "  Import-Module $ModuleName" -ForegroundColor White
Write-Host ""
Write-Host "For examples, check:" -ForegroundColor Cyan
Write-Host "  $targetPath\examples\" -ForegroundColor White
Write-Host ""
