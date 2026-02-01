# ============================================================================
# Example 4: Complete Application - Console UI Library
# ============================================================================
# This example demonstrates a complete application workflow
# ============================================================================

# Load the library
$LibPath = Split-Path -Parent $PSScriptRoot
. "$LibPath\console_manager.ps1"

# Application state
$script:tasks = @()
$script:completedCount = 0

function Show-WelcomeScreen {
    Clear-Host
    Write-ConsoleTitle -Title "TASK MANAGER PRO"
    Write-ConsoleInfo -Message "A demonstration of Console UI Library capabilities"
    Write-ConsoleInfo -Message "Version 1.0.0 - Powered by ConsoleUI" -Color "Gray"
    Write-Host ""
    Start-Sleep -Seconds 2
}

function Show-MainMenu {
    Clear-Host
    Write-ConsoleHeader -Text "TASK MANAGER" -Color "Cyan"
    
    # Show summary
    $summary = @(
        @{ Label = "Total Tasks"; Value = $script:tasks.Count }
        @{ Label = "Completed"; Value = $script:completedCount; Color = "Green" }
        @{ Label = "Pending"; Value = ($script:tasks.Count - $script:completedCount); Color = "Yellow" }
    )
    Write-ConsoleSummary -Title "Current Status" -Items $summary
    
    $options = @(
        "[MAIN MENU]",
        "Add New Task",
        "View All Tasks",
        "Mark Task Complete",
        "Delete Task",
        "---",
        "Generate Report",
        "---",
        "{Red}Exit"
    )
    
    $count = Show-ConsoleMenu -Title "" -Options $options
    return Read-ConsoleChoice -MaxChoice $count
}

function Add-NewTask {
    Clear-Host
    Write-ConsoleHeader -Text "Add New Task"
    
    $title = Read-ConsoleInput -Prompt "Task title"
    if (-not $title) {
        Write-ConsoleStatus -Message "Task title cannot be empty" -Type "Error"
        Start-Sleep -Seconds 2
        return
    }
    
    $priority = Read-ConsoleInput -Prompt "Priority (High/Medium/Low)" -DefaultValue "Medium"
    
    $task = @{
        ID = $script:tasks.Count + 1
        Title = $title
        Priority = $priority
        Status = "Pending"
        Created = Get-Date -Format "yyyy-MM-dd HH:mm"
    }
    
    $script:tasks += $task
    Write-ConsoleStatus -Message "Task added successfully" -Type "Success"
    Start-Sleep -Seconds 1
}

function Show-AllTasks {
    Clear-Host
    Write-ConsoleHeader -Text "All Tasks"
    
    if ($script:tasks.Count -eq 0) {
        Write-ConsoleInfo -Message "No tasks found. Add some tasks to get started!"
        Read-ConsoleInput -Prompt "Press Enter" -DefaultValue "" | Out-Null
        return
    }
    
    $columns = @(
        @{ Header = "ID"; Property = "ID"; Width = 5; Align = "Right" }
        @{ Header = "Title"; Property = "Title"; Width = 30; Align = "Left" }
        @{ Header = "Priority"; Property = "Priority"; Width = 10; Align = "Center" }
        @{ Header = "Status"; Property = "Status"; Width = 12; Align = "Center" }
        @{ Header = "Created"; Property = "Created"; Width = 18; Align = "Left" }
    )
    
    $colorMap = @{
        "Pending" = "Yellow"
        "Completed" = "Green"
    }
    
    Write-ConsoleTable -Data $script:tasks -Columns $columns -ColorMapProperty "Status" -ColorMap $colorMap
    
    Read-ConsoleInput -Prompt "Press Enter" -DefaultValue "" | Out-Null
}

function Complete-Task {
    Clear-Host
    Write-ConsoleHeader -Text "Mark Task Complete"
    
    if ($script:tasks.Count -eq 0) {
        Write-ConsoleInfo -Message "No tasks available"
        Start-Sleep -Seconds 2
        return
    }
    
    $taskId = Read-ConsoleInput -Prompt "Enter task ID to complete"
    $task = $script:tasks | Where-Object { $_.ID -eq [int]$taskId }
    
    if ($task) {
        if ($task.Status -eq "Completed") {
            Write-ConsoleStatus -Message "Task is already completed" -Type "Warning"
        } else {
            $task.Status = "Completed"
            $script:completedCount++
            Write-ConsoleStatus -Message "Task marked as complete" -Type "Success"
        }
    } else {
        Write-ConsoleStatus -Message "Task not found" -Type "Error"
    }
    
    Start-Sleep -Seconds 2
}

function Remove-Task {
    Clear-Host
    Write-ConsoleHeader -Text "Delete Task"
    
    if ($script:tasks.Count -eq 0) {
        Write-ConsoleInfo -Message "No tasks available"
        Start-Sleep -Seconds 2
        return
    }
    
    $taskId = Read-ConsoleInput -Prompt "Enter task ID to delete"
    $task = $script:tasks | Where-Object { $_.ID -eq [int]$taskId }
    
    if ($task) {
        if (Read-ConsoleConfirmation -Prompt "Delete task '$($task.Title)'?") {
            if ($task.Status -eq "Completed") { $script:completedCount-- }
            $script:tasks = $script:tasks | Where-Object { $_.ID -ne [int]$taskId }
            Write-ConsoleStatus -Message "Task deleted" -Type "Success"
        }
    } else {
        Write-ConsoleStatus -Message "Task not found" -Type "Error"
    }
    
    Start-Sleep -Seconds 2
}

function Show-Report {
    Clear-Host
    Write-ConsoleHeader -Text "Task Report"
    
    $result = Invoke-ConsoleSpinner -Message "Generating report" -ScriptBlock {
        Start-Sleep -Seconds 2
        return "Report generated"
    }
    
    # Statistics
    $totalTasks = $script:tasks.Count
    $completed = $script:completedCount
    $pending = $totalTasks - $completed
    $completionRate = if ($totalTasks -gt 0) { [Math]::Round(($completed / $totalTasks) * 100) } else { 0 }
    
    Write-ConsoleChart -Label "Completion Rate" -Value $completionRate -Max 100 -Color "Cyan"
    
    $stats = @(
        @{ Label = "Total Tasks"; Value = $totalTasks }
        @{ Label = "Completed"; Value = $completed; Color = "Green" }
        @{ Label = "Pending"; Value = $pending; Color = "Yellow" }
        @{ Label = "Completion Rate"; Value = "$completionRate%"; Color = "Cyan" }
    )
    Write-ConsoleSummary -Title "Statistics" -Items $stats
    
    # Priority breakdown
    if ($script:tasks.Count -gt 0) {
        Write-ConsoleHeader -Text "Priority Breakdown"
        $high = ($script:tasks | Where-Object { $_.Priority -eq "High" }).Count
        $medium = ($script:tasks | Where-Object { $_.Priority -eq "Medium" }).Count
        $low = ($script:tasks | Where-Object { $_.Priority -eq "Low" }).Count
        
        Write-ConsoleChart -Label "High Priority" -Value $high -Max $totalTasks -Color "Red"
        Write-ConsoleChart -Label "Medium Priority" -Value $medium -Max $totalTasks -Color "Yellow"
        Write-ConsoleChart -Label "Low Priority" -Value $low -Max $totalTasks -Color "Green"
    }
    
    Write-ConsoleBox -Message "Report generated successfully" -Color "Green"
    
    Read-ConsoleInput -Prompt "Press Enter" -DefaultValue "" | Out-Null
}

# Main application flow
Show-WelcomeScreen

do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        1 { Add-NewTask }
        2 { Show-AllTasks }
        3 { Complete-Task }
        4 { Remove-Task }
        5 { Show-Report }
        6 { 
            Clear-Host
            Write-ConsoleBox -Message "Thank you for using Task Manager Pro!" -Color "Cyan"
            Start-Sleep -Seconds 2
            break
        }
        0 { break }
    }
} while ($choice -ne 0 -and $choice -ne 6)

