<#
.SYNOPSIS
    Test helpers and utilities for HermesConsoleUI testing

.DESCRIPTION
    Provides mock objects, assertion helpers and utilities for testing
    HermesConsoleUI components in isolation.
#>

#region Mock Console

<#
.SYNOPSIS
    Creates a mock console object for testing
#>
function New-MockConsole {
    [CmdletBinding()]
    param(
        [int]$Width = 120,
        [int]$Height = 30
    )
    
    return [PSCustomObject]@{
        Output     = [System.Collections.ArrayList]::new()
        Width      = $Width
        Height     = $Height
        CursorLeft = 0
        CursorTop  = 0
    }
}

<#
.SYNOPSIS
    Captures console output for testing
#>
function Start-OutputCapture {
    $script:CapturedOutput = [System.Collections.ArrayList]::new()
    $script:OriginalWriteHost = Get-Command Write-Host
}

function Stop-OutputCapture {
    return $script:CapturedOutput
}

function Get-CapturedOutput {
    return $script:CapturedOutput -join "`n"
}

#endregion

#region ANSI Helpers

<#
.SYNOPSIS
    Validates ANSI escape codes in output
#>
function Assert-ANSIOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Output,
        
        [Parameter(Mandatory)]
        [string]$ExpectedCode
    )
    
    if ($Output -notmatch [regex]::Escape($ExpectedCode)) {
        throw "Expected ANSI code '$ExpectedCode' not found in output"
    }
    
    return $true
}

<#
.SYNOPSIS
    Strips ANSI codes from text for comparison
#>
function Remove-ANSICodes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Text
    )
    
    process {
        return $Text -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
    }
}

<#
.SYNOPSIS
    Gets ANSI color code for a color name
#>
function Get-ANSIColorCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Black', 'Red', 'Green', 'Yellow', 'Blue', 'Magenta', 'Cyan', 'White')]
        [string]$Color,
        
        [switch]$Background
    )
    
    $codes = @{
        'Black'   = if ($Background) { 40 } else { 30 }
        'Red'     = if ($Background) { 41 } else { 31 }
        'Green'   = if ($Background) { 42 } else { 32 }
        'Yellow'  = if ($Background) { 43 } else { 33 }
        'Blue'    = if ($Background) { 44 } else { 34 }
        'Magenta' = if ($Background) { 45 } else { 35 }
        'Cyan'    = if ($Background) { 46 } else { 36 }
        'White'   = if ($Background) { 47 } else { 37 }
    }
    
    return "`e[$($codes[$Color])m"
}

#endregion

#region Test Data Generators

<#
.SYNOPSIS
    Generates test data for table rendering
#>
function New-TestTableData {
    [CmdletBinding()]
    param(
        [int]$RowCount = 10,
        [int]$ColumnCount = 3
    )
    
    $data = @()
    for ($i = 1; $i -le $RowCount; $i++) {
        $row = @{}
        for ($j = 1; $j -le $ColumnCount; $j++) {
            $row["Column$j"] = "Value_${i}_${j}"
        }
        $data += [PSCustomObject]$row
    }
    
    return $data
}

<#
.SYNOPSIS
    Generates long string for edge case testing
#>
function New-LongString {
    [CmdletBinding()]
    param(
        [int]$Length = 1000,
        [char]$Character = 'A'
    )
    
    return $Character.ToString() * $Length
}

<#
.SYNOPSIS
    Generates string with special characters
#>
function New-SpecialCharString {
    return "Test`n`r`t`0Special"
}

#endregion

#region Assertion Helpers

<#
.SYNOPSIS
    Asserts that output contains expected text (ignoring ANSI codes)
#>
function Assert-OutputContains {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Output,
        
        [Parameter(Mandatory)]
        [string]$Expected
    )
    
    $cleanOutput = Remove-ANSICodes -Text $Output
    if ($cleanOutput -notmatch [regex]::Escape($Expected)) {
        throw "Expected text '$Expected' not found in output"
    }
    
    return $true
}

<#
.SYNOPSIS
    Asserts that a scriptblock completes within time limit
#>
function Assert-CompletesWithin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory)]
        [int]$Milliseconds
    )
    
    $elapsed = Measure-Command { & $ScriptBlock }
    
    if ($elapsed.TotalMilliseconds -gt $Milliseconds) {
        throw "Script took $($elapsed.TotalMilliseconds)ms, expected <$Milliseconds ms"
    }
    
    return $true
}

#endregion

#region Module Import Helper

<#
.SYNOPSIS
    Imports HermesConsoleUI module for testing
#>
function Import-HermesForTesting {
    [CmdletBinding()]
    param()
    
    $modulePath = Join-Path $PSScriptRoot ".." "HermesConsoleUI.psd1"
    
    if (-not (Test-Path $modulePath)) {
        throw "Module not found at: $modulePath"
    }
    
    Import-Module $modulePath -Force -Global
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-MockConsole',
    'Start-OutputCapture',
    'Stop-OutputCapture',
    'Get-CapturedOutput',
    'Assert-ANSIOutput',
    'Remove-ANSICodes',
    'Get-ANSIColorCode',
    'New-TestTableData',
    'New-LongString',
    'New-SpecialCharString',
    'Assert-OutputContains',
    'Assert-CompletesWithin',
    'Import-HermesForTesting'
)
