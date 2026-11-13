<#
.SYNOPSIS
    Analyzes file sizes and detects large files (blobs).

.DESCRIPTION
    Provides detailed metrics about file sizes including total size,
    largest files, size distribution, and potential blob detection.

.EXAMPLE
    .\Analyze-FileSize.ps1
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
    [int]$BlobThresholdKB = 100
)

Write-Host "`n=== File Size Analysis ===" -ForegroundColor Cyan
Write-Host "Analyzing project: $ProjectRoot`n"

# Get all files
$allFiles = Get-ChildItem -Path $ProjectRoot -Recurse -File -Force -ErrorAction SilentlyContinue | 
Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

# Calculate total size
$totalSizeBytes = ($allFiles | Measure-Object -Property Length -Sum).Sum
$totalSizeKB = [Math]::Round($totalSizeBytes / 1KB, 2)
$totalSizeMB = [Math]::Round($totalSizeBytes / 1MB, 2)

# Get largest files
$largestFiles = $allFiles | Sort-Object Length -Descending | Select-Object -First 10 | ForEach-Object {
    $relativePath = $_.FullName.Replace($ProjectRoot, "").TrimStart("\")
    [PSCustomObject]@{
        Path      = $relativePath
        SizeBytes = $_.Length
        SizeKB    = [Math]::Round($_.Length / 1KB, 2)
        SizeMB    = [Math]::Round($_.Length / 1MB, 2)
    }
}

# Detect blobs (files > threshold)
$blobFiles = $allFiles | Where-Object { $_.Length -gt ($BlobThresholdKB * 1KB) } | ForEach-Object {
    $relativePath = $_.FullName.Replace($ProjectRoot, "").TrimStart("\")
    [PSCustomObject]@{
        Path   = $relativePath
        SizeKB = [Math]::Round($_.Length / 1KB, 2)
    }
}

# Average size by extension
$avgSizeByExtension = $allFiles | Group-Object { [System.IO.Path]::GetExtension($_.Name) } | ForEach-Object {
    $ext = if ($_.Name) { $_.Name } else { "(no extension)" }
    $avgSize = ($_.Group | Measure-Object -Property Length -Average).Average
    
    [PSCustomObject]@{
        Extension    = $ext
        Count        = $_.Count
        AvgSizeBytes = [Math]::Round($avgSize, 0)
        AvgSizeKB    = [Math]::Round($avgSize / 1KB, 2)
    }
} | Sort-Object AvgSizeKB -Descending

# Build result
$result = [PSCustomObject]@{
    ProjectRoot            = $ProjectRoot
    TotalFiles             = $allFiles.Count
    TotalSizeBytes         = $totalSizeBytes
    TotalSizeKB            = $totalSizeKB
    TotalSizeMB            = $totalSizeMB
    LargestFiles           = $largestFiles
    BlobFiles              = $blobFiles
    BlobThresholdKB        = $BlobThresholdKB
    AverageSizeByExtension = $avgSizeByExtension
}

# Display results
Write-Host "=== Size Metrics ===" -ForegroundColor Yellow
Write-Host "Total Files: $($allFiles.Count)"
Write-Host "Total Size: $totalSizeKB KB ($totalSizeMB MB)"
Write-Host "Average File Size: $([Math]::Round($totalSizeBytes / $allFiles.Count / 1KB, 2)) KB"

Write-Host "`n=== Top 10 Largest Files ===" -ForegroundColor Yellow
$largestFiles | Format-Table Path, SizeKB, SizeMB -AutoSize

if ($blobFiles.Count -gt 0) {
    Write-Host "`n⚠️  Blob Files Detected (>$BlobThresholdKB KB)" -ForegroundColor Red
    Write-Host "Found $($blobFiles.Count) file(s) exceeding threshold:`n"
    $blobFiles | Format-Table Path, SizeKB -AutoSize
}
else {
    Write-Host "`n✅ No blob files detected (all files <$BlobThresholdKB KB)" -ForegroundColor Green
}

Write-Host "`n=== Average Size by File Type ===" -ForegroundColor Yellow
$avgSizeByExtension | Select-Object -First 10 | Format-Table -AutoSize

# Export to JSON
$outputPath = Join-Path $PSScriptRoot "file_size_results.json"
$result | ConvertTo-Json -Depth 5 | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Green

return $result
