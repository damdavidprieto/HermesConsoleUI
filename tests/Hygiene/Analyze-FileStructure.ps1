<#
.SYNOPSIS
    Analyzes the file structure and organization of the project.

.DESCRIPTION
    Provides detailed metrics about project structure including file counts,
    directory depth, file type distribution, and organizational health.

.EXAMPLE
    .\Analyze-FileStructure.ps1
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)

function Get-DirectoryDepth {
    param([string]$Path, [string]$BasePath)
    $relativePath = $Path.Replace($BasePath, "").TrimStart("\")
    if ([string]::IsNullOrEmpty($relativePath)) { return 0 }
    return ($relativePath.Split("\")).Count
}

function Get-FileTreeRecursive {
    param(
        [string]$Path,
        [int]$CurrentDepth = 0,
        [int]$MaxDepth = 10
    )
    
    if ($CurrentDepth -ge $MaxDepth) { return @() }
    
    $items = @()
    Get-ChildItem -Path $Path -Force | ForEach-Object {
        $item = @{
            Name        = $_.Name
            Path        = $_.FullName
            IsDirectory = $_.PSIsContainer
            Size        = if (-not $_.PSIsContainer) { $_.Length } else { 0 }
            Depth       = $CurrentDepth
        }
        $items += $item
        
        if ($_.PSIsContainer) {
            $items += Get-FileTreeRecursive -Path $_.FullName -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth
        }
    }
    
    return $items
}

Write-Host "`n=== File Structure Analysis ===" -ForegroundColor Cyan
Write-Host "Analyzing project: $ProjectRoot`n"

# Get all items
$allItems = Get-FileTreeRecursive -Path $ProjectRoot

# Separate files and directories
$files = $allItems | Where-Object { -not $_.IsDirectory }
$directories = $allItems | Where-Object { $_.IsDirectory }

# Calculate metrics
$totalFiles = $files.Count
$totalDirectories = $directories.Count
$maxDepth = if ($allItems.Count -gt 0) { ($allItems | Measure-Object -Property Depth -Maximum).Maximum } else { 0 }

# File type distribution
$filesByExtension = $files | Group-Object { [System.IO.Path]::GetExtension($_.Name) } | 
Select-Object @{N = 'Extension'; E = { if ($_.Name) { "$($_.Name)" }else { "(no extension)" } } }, Count |
Sort-Object Count -Descending

# Empty directories
$emptyDirectories = $directories | Where-Object {
    $dirPath = $_.Path
    $childCount = (Get-ChildItem -Path $dirPath -Force).Count
    $childCount -eq 0
}

# Files in root
$filesInRoot = $files | Where-Object { $_.Depth -eq 0 }

# Build result
$result = [PSCustomObject]@{
    ProjectRoot      = $ProjectRoot
    TotalFiles       = $totalFiles
    TotalDirectories = $totalDirectories
    MaxDepth         = $maxDepth
    FilesByExtension = $filesByExtension
    EmptyDirectories = $emptyDirectories
    FilesInRoot      = $filesInRoot
    AllItems         = $allItems
}

# Display results
Write-Host "=== Structure Metrics ===" -ForegroundColor Yellow
Write-Host "Total Files: $totalFiles"
Write-Host "Total Directories: $totalDirectories"
Write-Host "Maximum Depth: $maxDepth levels"
Write-Host "Empty Directories: $($emptyDirectories.Count)"
Write-Host "Files in Root: $($filesInRoot.Count)"

Write-Host "`n=== File Type Distribution ===" -ForegroundColor Yellow
$filesByExtension | Format-Table -AutoSize

if ($emptyDirectories.Count -gt 0) {
    Write-Host "`n=== Empty Directories ===" -ForegroundColor Yellow
    $emptyDirectories | ForEach-Object { Write-Host "  - $($_.Path)" }
}

if ($filesInRoot.Count -gt 0) {
    Write-Host "`n=== Files in Root Directory ===" -ForegroundColor Yellow
    $filesInRoot | ForEach-Object { Write-Host "  - $($_.Name)" }
}

# Export to JSON
$outputPath = Join-Path $PSScriptRoot "file_structure_results.json"
$result | Select-Object -Property * -ExcludeProperty AllItems | ConvertTo-Json -Depth 5 | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Green

return $result
