# Test Environment Setup for HermesConsoleUI
# Prepares the environment for successful module loading in Pester context

<#
.SYNOPSIS
    Initializes test environment for HermesConsoleUI tests
#>
function Initialize-HermesTestEnvironment {
    [CmdletBinding()]
    param()
    
    # Get module root
    $moduleRoot = Resolve-Path (Join-Path $PSScriptRoot ".." "..")
    
    # Ensure all required directories exist
    $requiredDirs = @(
        "src\Constants",
        "src\Validators",
        "src\Core",
        "modules",
        "config\locales"
    )
    
    foreach ($dir in $requiredDirs) {
        $fullPath = Join-Path $moduleRoot $dir
        if (-not (Test-Path $fullPath)) {
            Write-Warning "Required directory not found: $dir"
        }
    }
    
    # Set up minimal environment variables if needed
    if (-not $env:HERMES_TEST_MODE) {
        $env:HERMES_TEST_MODE = "true"
    }
    
    return $moduleRoot
}

<#
.SYNOPSIS
    Safely imports HermesConsoleUI module for testing
#>
function Import-HermesModule {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    try {
        $moduleRoot = Initialize-HermesTestEnvironment
        $manifestPath = Join-Path $moduleRoot "HermesConsoleUI.psd1"
        
        # Remove module if already loaded
        if (Get-Module HermesConsoleUI) {
            Remove-Module HermesConsoleUI -Force -ErrorAction SilentlyContinue
        }
        
        # Import with error handling
        Import-Module $manifestPath -Force:$Force -Global -ErrorAction Stop
        
        return $true
    }
    catch {
        Write-Warning "Failed to import HermesConsoleUI: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Validates that module loaded successfully
#>
function Test-HermesModuleLoaded {
    $module = Get-Module -Name HermesConsoleUI
    return ($null -ne $module)
}

<#
.SYNOPSIS
    Gets list of exported functions from HermesConsoleUI
#>
function Get-HermesFunctions {
    if (-not (Test-HermesModuleLoaded)) {
        return @()
    }
    
    return (Get-Command -Module HermesConsoleUI).Name
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-HermesTestEnvironment',
    'Import-HermesModule',
    'Test-HermesModuleLoaded',
    'Get-HermesFunctions'
)
