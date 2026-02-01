<#
.SYNOPSIS
    Finds temporary, development, and legacy files in the project.

.DESCRIPTION
    Scans the project for various types of temporary files that should be
    cleaned up or moved to appropriate locations.

.EXAMPLE
    .\Find-TemporaryFiles.ps1
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)

# Define patterns for different types of temporary files
$patterns = @{
    Temporary   = @('*.tmp', '*.bak', '*.old', '*~', '*.swp', '*.swo')
    Development = @('temp_*.ps1', 'test_*.ps1', 'debug_*.ps1', 'scratch_*')
    Editor      = @('.DS_Store', 'Thumbs.db', 'desktop.ini', '*.lnk')
    Log         = @('*.log')
    Backup      = @('*.backup', 'Copy of *', '*- Copy.*')
}

Write-Host "`n=== Temporary File Detection ===" -ForegroundColor Cyan
Write-Host "Scanning project: $ProjectRoot`n"

$findings = @{
    TemporaryFiles   = @()
    DevelopmentFiles = @()
    EditorFiles      = @()
    LogFiles         = @()
    BackupFiles      = @()
}

# Scan for each pattern type
foreach ($category in $patterns.Keys) {
    Write-Host "Scanning for $category files..." -ForegroundColor Yellow
    
    foreach ($pattern in $patterns[$category]) {
        $files = Get-ChildItem -Path $ProjectRoot -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            # Skip files in .git, node_modules, etc.
            if ($file.FullName -match '[\\/](\.git|node_modules|\.vscode)[\\/]') {
                continue
            }
            
            $relativePath = $file.FullName.Replace($ProjectRoot, "").TrimStart("\")
            
            switch ($category) {
                'Temporary' { $findings.TemporaryFiles += $relativePath }
                'Development' { $findings.DevelopmentFiles += $relativePath }
                'Editor' { $findings.EditorFiles += $relativePath }
                'Log' { 
                    # Only flag logs outside of logs/ directory
                    if ($relativePath -notmatch '^logs[\\/]') {
                        $findings.LogFiles += $relativePath
                    }
                }
                'Backup' { $findings.BackupFiles += $relativePath }
            }
        }
    }
}

# Check for development files in root
$rootDevFiles = Get-ChildItem -Path $ProjectRoot -File | Where-Object {
    $_.Name -match '^(temp|test|debug|scratch)' -or
    $_.Name -match '(demo|example|sample)\.ps1$'
}

foreach ($file in $rootDevFiles) {
    $relativePath = $file.Name
    if ($relativePath -notin $findings.DevelopmentFiles) {
        $findings.DevelopmentFiles += $relativePath
    }
}

# Calculate totals
$totalIssues = ($findings.TemporaryFiles.Count + 
    $findings.DevelopmentFiles.Count + 
    $findings.EditorFiles.Count + 
    $findings.LogFiles.Count + 
    $findings.BackupFiles.Count)

# Build result
$result = [PSCustomObject]@{
    ProjectRoot        = $ProjectRoot
    TemporaryFiles     = $findings.TemporaryFiles
    DevelopmentFiles   = $findings.DevelopmentFiles
    EditorFiles        = $findings.EditorFiles
    LogFiles           = $findings.LogFiles
    BackupFiles        = $findings.BackupFiles
    TotalIssues        = $totalIssues
    RecommendedActions = @()
}

# Generate recommendations
if ($findings.DevelopmentFiles.Count -gt 0) {
    $result.RecommendedActions += "Move development files to /dev directory"
    $result.RecommendedActions += "Add /dev to .gitignore"
}
if ($findings.TemporaryFiles.Count -gt 0) {
    $result.RecommendedActions += "Delete temporary files"
}
if ($findings.EditorFiles.Count -gt 0) {
    $result.RecommendedActions += "Add editor files to .gitignore"
}
if ($findings.LogFiles.Count -gt 0) {
    $result.RecommendedActions += "Move log files to /logs directory"
}
if ($findings.BackupFiles.Count -gt 0) {
    $result.RecommendedActions += "Delete backup files or move to /backup"
}

# Display results
Write-Host "`n=== Detection Results ===" -ForegroundColor Cyan

if ($totalIssues -eq 0) {
    Write-Host "✅ No temporary files detected!" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Found $totalIssues issue(s)" -ForegroundColor Yellow
    
    if ($findings.TemporaryFiles.Count -gt 0) {
        Write-Host "`nTemporary Files ($($findings.TemporaryFiles.Count)):" -ForegroundColor Red
        $findings.TemporaryFiles | ForEach-Object { Write-Host "  - $_" }
    }
    
    if ($findings.DevelopmentFiles.Count -gt 0) {
        Write-Host "`nDevelopment Files ($($findings.DevelopmentFiles.Count)):" -ForegroundColor Yellow
        $findings.DevelopmentFiles | ForEach-Object { Write-Host "  - $_" }
    }
    
    if ($findings.EditorFiles.Count -gt 0) {
        Write-Host "`nEditor Files ($($findings.EditorFiles.Count)):" -ForegroundColor Yellow
        $findings.EditorFiles | ForEach-Object { Write-Host "  - $_" }
    }
    
    if ($findings.LogFiles.Count -gt 0) {
        Write-Host "`nLog Files ($($findings.LogFiles.Count)):" -ForegroundColor Yellow
        $findings.LogFiles | ForEach-Object { Write-Host "  - $_" }
    }
    
    if ($findings.BackupFiles.Count -gt 0) {
        Write-Host "`nBackup Files ($($findings.BackupFiles.Count)):" -ForegroundColor Yellow
        $findings.BackupFiles | ForEach-Object { Write-Host "  - $_" }
    }
    
    Write-Host "`n=== Recommended Actions ===" -ForegroundColor Cyan
    $result.RecommendedActions | ForEach-Object { Write-Host "  • $_" }
}

# Export to JSON
$outputPath = Join-Path $PSScriptRoot "temporary_files_results.json"
$result | ConvertTo-Json -Depth 5 | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Green

return $result
