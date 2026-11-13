# Run HermesConsoleUI Tests
# Simple test runner to validate all tests pass

Write-Host "=== HermesConsoleUI Test Suite ===" -ForegroundColor Cyan
Write-Host ""

# Ensure Pester is available
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installing Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck
}

# Import Pester
Import-Module Pester -MinimumVersion 5.0.0

# Run tests
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Output.Verbosity = 'Detailed'
$config.Run.PassThru = $true

Write-Host "Running Unit Tests..." -ForegroundColor Yellow
$result = Invoke-Pester -Configuration $config

# Summary
Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total: $($result.TotalCount)" -ForegroundColor White
Write-Host "Passed: $($result.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { "Green" } else { "Red" })
Write-Host "Skipped: $($result.SkippedCount)" -ForegroundColor Yellow
Write-Host ""

if ($result.FailedCount -eq 0) {
    Write-Host "✅ All tests passed!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "❌ Some tests failed" -ForegroundColor Red
    exit 1
}
