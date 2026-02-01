<#
.SYNOPSIS
    PSConsoleUI - Windows Native Integration
.DESCRIPTION
    Provides integration with native Windows APIs (Taskbar, Notifications, etc.)
    Uses embedded C# types for interaction with Windows Shell.
#>

# 1. C# Type Definition for Taskbar & Toast
# We use Add-Type to inject the necessary definitions if they don't exist
$code = @"
using System;
using System.Runtime.InteropServices;

namespace Hermes.Native {
    [ComImport]
    [Guid("56FDF342-FD6D-11d0-958A-006097C9A090")]
    [ClassInterface(ClassInterfaceType.None)]
    public class TaskbarList { }

    [ComImport]
    [Guid("ea1afb91-9e28-4b86-90e9-9e9f8a5eefaf")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface ITaskbarList3 {
        // ITaskbarList
        void HrInit();
        void AddTab(IntPtr hwnd);
        void DeleteTab(IntPtr hwnd);
        void ActivateTab(IntPtr hwnd);
        void SetActiveAlt(IntPtr hwnd);

        // ITaskbarList2
        void MarkFullscreenWindow(IntPtr hwnd, bool fFullscreen);

        // ITaskbarList3
        void SetProgressValue(IntPtr hwnd, ulong ullCompleted, ulong ullTotal);
        void SetProgressState(IntPtr hwnd, int tbpFlags);
        void RegisterTab(IntPtr hwndTab, IntPtr hwndMDI);
        void UnregisterTab(IntPtr hwndTab);
        void SetTabOrder(IntPtr hwndTab, IntPtr hwndInsertBefore);
        void SetTabActive(IntPtr hwndTab, IntPtr hwndMDI, int dwReserved);
        void ThumbBarAddButtons(IntPtr hwnd, uint cButtons, IntPtr pButton);
        void ThumbBarUpdateButtons(IntPtr hwnd, uint cButtons, IntPtr pButton);
        void ThumbBarSetImageList(IntPtr hwnd, IntPtr himl);
        void SetOverlayIcon(IntPtr hwnd, IntPtr hIcon, string pszDescription);
        void SetThumbnailTooltip(IntPtr hwnd, string pszTip);
        void SetThumbnailClip(IntPtr hwnd, IntPtr prcClip);
    }
}
"@

try {
    if (-not ([System.Management.Automation.PSTypeName]'Hermes.Native.TaskbarList').Type) {
        Add-Type -TypeDefinition $code -ErrorAction Stop
    }
} catch {
    # Fail silently on non-Windows or restricted environments
    # Write-Warning "Windows Native Integration not available."
}

# Enum for Taskbar States
$TBPF_NOPROGRESS    = 0
$TBPF_INDETERMINATE = 0x1
$TBPF_NORMAL        = 0x2
$TBPF_ERROR         = 0x4
$TBPF_PAUSED        = 0x8

# Global standard wrapper
function Set-TaskbarProgress {
    <#
    .SYNOPSIS
        Sets the progress bar state on the taskbar icon.
    .PARAMETER State
        Normal, Error, Paused, Indeterminate, None
    .PARAMETER Value
        Progress value (0-100)
    #>
    param(
        [ValidateSet('Normal','Error','Paused','Indeterminate','None')]
        [string]$State = 'Normal',
        
        [int]$Value = 0,
        [int]$Max = 100
    )
    
    # Needs console handle
    $hwnd = (Get-Process -Id $PID).MainWindowHandle
    if ($hwnd -eq 0) { return }

    try {
        $tb = [Hermes.Native.TaskbarList]::new()
        $tbi = $tb -as [Hermes.Native.ITaskbarList3]
        
        # Calculate Flag
        $flag = switch ($State) {
            'None'          { 0 }
            'Indeterminate' { 0x1 }
            'Normal'        { 0x2 }
            'Error'         { 0x4 }
            'Paused'        { 0x8 }
        }
        
        $tbi.SetProgressState($hwnd, $flag)
        
        if ($State -in @('Normal','Error','Paused')) {
            $tbi.SetProgressValue($hwnd, [ulong]$Value, [ulong]$Max)
        }
    } catch {
        # Ignore COM errors
    }
}

function Show-WindowsNotification {
    <#
    .SYNOPSIS
        Displays a native Windows Toast Notification.
    #>
    param(
        [string]$Title,
        [string]$Message,
        [string]$IconPath # Optional
    )
    
    # Use PowerShell's built-in BurntToast-like method via .NET or simple balloon fallback
    # For vanilla dependency-free, we can use the NotifyIcon trick or just rely on 
    # System.Windows.Forms if available (older style) or WinRT (harder from PS plain).
    
    # Fallback: Powershell BurntToast module is best, but we want zero-dep.
    # We will use the System.Windows.Forms NotifyIcon for "Tray Balloon" which is simpler
    # and works on older servers too. For true Toasts we need XML, which is verbose.
    
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -Id $PID).Path)
    $notify.Visible = $true
    
    $notify.ShowBalloonTip(10000, $Title, $Message, [System.Windows.Forms.ToolTipIcon]::Info)
    
    # Cleanup after a bit
    start-sleep -milliseconds 100
    $notify.Dispose()
}

Export-ModuleMember -Function Set-TaskbarProgress, Show-WindowsNotification
