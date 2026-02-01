@echo off
REM ============================================================================
REM Cassiel UI Library - Test Runner
REM ============================================================================
REM Double-click this file to run all Pester tests
REM ============================================================================

echo.
echo ============================================================
echo        Cassiel UI Library - Running Tests
echo ============================================================
echo.

cd /d "%~dp0"

powershell -ExecutionPolicy Bypass -NoProfile -Command "& { Invoke-Pester -Path '.\tests\ui_components.tests.ps1' -Verbose; Write-Host ''; Write-Host 'Press any key to exit...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }"

exit
