# ============================================================================
# Example 2: Interactive Menu - Console UI Library
# ============================================================================
# This example demonstrates menu creation and user interaction
# ============================================================================

# Load the library
$LibPath = Split-Path -Parent $PSScriptRoot
. "$LibPath\console_manager.ps1"

function Show-MainMenu {
    $options = @(
        "[MAIN MENU]",
        "View System Information",
        "Run Diagnostics",
        "Configure Settings",
        "---",
        "{Red}Exit Application"
    )

    $count = Show-ConsoleMenu -Title "APPLICATION MANAGER" -Options $options -Footer "Select an option (0 to exit)"
    $choice = Read-ConsoleChoice -MaxChoice $count

    return $choice
}

function Show-SystemInfo {
    Clear-Host
    Write-ConsoleHeader -Text "System Information"
    
    $info = @{
        "Computer Name" = $env:COMPUTERNAME
        "Username" = $env:USERNAME
        "OS" = (Get-WmiObject Win32_OperatingSystem).Caption
        "PowerShell Version" = $PSVersionTable.PSVersion.ToString()
    }
    
    Write-ConsoleMetadata -Metadata $info
    
    Write-Host ""
    Read-ConsoleInput -Prompt "Press Enter to continue" -DefaultValue "" | Out-Null
}

function Run-Diagnostics {
    Clear-Host
    Write-ConsoleHeader -Text "Running Diagnostics"
    
    $result = Invoke-ConsoleSpinner -Message "Checking system health" -ScriptBlock {
        Start-Sleep -Seconds 3
        return "All systems operational"
    }
    
    Write-ConsoleStatus -Message $result -Type "Success"
    
    Write-Host ""
    Read-ConsoleInput -Prompt "Press Enter to continue" -DefaultValue "" | Out-Null
}

function Configure-Settings {
    Clear-Host
    Write-ConsoleHeader -Text "Configuration"
    
    $name = Read-ConsoleInput -Prompt "Enter application name" -DefaultValue "MyApp"
    $port = Read-ConsoleInput -Prompt "Enter port number" -DefaultValue "8080"
    
    if (Read-ConsoleConfirmation -Prompt "Save configuration?") {
        Write-ConsoleStatus -Message "Configuration saved successfully" -Type "Success"
    } else {
        Write-ConsoleStatus -Message "Configuration cancelled" -Type "Warning"
    }
    
    Write-Host ""
    Read-ConsoleInput -Prompt "Press Enter to continue" -DefaultValue "" | Out-Null
}

# Main loop
do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        1 { Show-SystemInfo }
        2 { Run-Diagnostics }
        3 { Configure-Settings }
        4 { 
            Write-ConsoleBox -Message "Goodbye!" -Color "Cyan"
            Start-Sleep -Seconds 1
            break
        }
        0 { break }
    }
} while ($choice -ne 0 -and $choice -ne 4)

