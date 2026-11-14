function New-ConsoleLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Rows
    )
    return @{ Rows = $Rows }
}

function New-ConsoleRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Columns
    )
    return @{ Columns = $Columns }
}

function New-ConsoleColumn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Content,
        
        [Parameter(Mandatory=$false)]
        [int]$WidthPercent = 50
    )
    return @{ Content = $Content; WidthPercent = $WidthPercent }
}

function Write-ConsoleLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Layout,
        
        [Parameter(Mandatory=$false)]
        [int]$TotalWidth = 80
    )
    
    foreach ($row in $Layout.Rows) {
        $colOutputs = @()
        $colWidths = @()
        
        # Calculate individual column widths
        foreach ($col in $row.Columns) {
            $w = [Math]::Floor(($col.WidthPercent / 100) * $TotalWidth) - 1
            $colWidths += $w
            
            # Capture output
            $lines = @()
            if ($col.Content -is [array]) {
                $lines = $col.Content
            } elseif ($col.Content -is [string]) {
                $lines = @($col.Content)
            } elseif ($col.Content -is [scriptblock]) {
                try {
                    $lines = @(. $col.Content -Width $w -ReturnLines)
                } catch {
                    $lines = @("Error rendering column")
                }
            }
            
            # Final safety: Ensure it is an array and not null
            if ($null -eq $lines) { $lines = @("") }
            $colOutputs += ,$lines
        }
        
        # Merge and print
        $merged = Set-LayoutBuffer -Columns $colOutputs -Widths $colWidths
        foreach ($l in $merged) {
            Write-HermesHost "  $l"
        }
        Write-HermesHost "" # Row separator
    }
}


# No local Export-ModuleMember here - handled by main module
