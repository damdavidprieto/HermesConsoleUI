<#
.SYNOPSIS
    Validates naming conventions for files and functions.

.DESCRIPTION
    Checks that files and functions follow PowerShell best practices
    for naming conventions.

.EXAMPLE
    .\Test-NamingConventions.ps1
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)

Write-Host "`n=== Naming Convention Validation ===" -ForegroundColor Cyan
Write-Host "Analyzing project: $ProjectRoot`n"

$issues = @()

# Get all PowerShell files
$psFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.ps1" -Recurse -File -ErrorAction SilentlyContinue |
Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

$psModules = Get-ChildItem -Path $ProjectRoot -Filter "*.psm1" -Recurse -File -ErrorAction SilentlyContinue |
Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

$allPsFiles = $psFiles + $psModules

Write-Host "Checking $($allPsFiles.Count) PowerShell files...`n"

foreach ($file in $allPsFiles) {
    $relativePath = $file.FullName.Replace($ProjectRoot, "").TrimStart("\")
    $fileName = $file.BaseName
    
    # Check for spaces in filename
    if ($file.Name -match '\s') {
        $issues += [PSCustomObject]@{
            Path     = $relativePath
            Issue    = "Contains spaces"
            Severity = "High"
        }
    }
    
    # Check for special characters
    if ($file.Name -match '[^a-zA-Z0-9\-_\.]') {
        $issues += [PSCustomObject]@{
            Path     = $relativePath
            Issue    = "Contains special characters"
            Severity = "Medium"
        }
    }
    
    # Check for PascalCase (for non-test files)
    if ($fileName -notmatch '^[A-Z][a-zA-Z0-9]*(-[A-Z][a-zA-Z0-9]*)*$' -and 
        $fileName -notmatch '\.Tests$' -and
        $fileName -notmatch '^(test|temp|debug)') {
        
        # Allow some exceptions
        if ($fileName -notmatch '^(README|LICENSE|CHANGELOG)$') {
            $issues += [PSCustomObject]@{
                Path     = $relativePath
                Issue    = "Should use PascalCase (e.g., Get-UserData)"
                Severity = "Low"
            }
        }
    }
    
    # Check for Verb-Noun pattern in .ps1 files
    if ($file.Extension -eq ".ps1" -and 
        $fileName -notmatch '^[A-Z][a-z]+-[A-Z]' -and
        $fileName -notmatch '\.Tests$' -and
        $fileName -notmatch '^(temp|test|debug)') {
        
        $issues += [PSCustomObject]@{
            Path     = $relativePath
            Issue    = "Should follow Verb-Noun pattern (e.g., Get-Data, Show-Menu)"
            Severity = "Medium"
        }
    }
}

# Calculate compliance
$totalFiles = $allPsFiles.Count
$compliantFiles = $totalFiles - ($issues | Select-Object -Unique Path).Count
$complianceRate = if ($totalFiles -gt 0) { 
    [Math]::Round(($compliantFiles / $totalFiles) * 100, 2) 
}
else { 100 }

# Build result
$result = [PSCustomObject]@{
    ProjectRoot       = $ProjectRoot
    TotalFiles        = $totalFiles
    CompliantFiles    = $compliantFiles
    NonCompliantFiles = $issues
    ComplianceRate    = $complianceRate
}

# Display results
Write-Host "=== Validation Results ===" -ForegroundColor Yellow
Write-Host "Total Files Checked: $totalFiles"
Write-Host "Compliant Files: $compliantFiles"
Write-Host "Non-Compliant Files: $($issues.Count)"
Write-Host "Compliance Rate: $complianceRate%"

if ($issues.Count -gt 0) {
    Write-Host "`n⚠️  Naming Convention Issues:" -ForegroundColor Yellow
    $issues | Group-Object Severity | ForEach-Object {
        Write-Host "`n$($_.Name) Severity ($($_.Count)):" -ForegroundColor $(
            switch ($_.Name) {
                "High" { "Red" }
                "Medium" { "Yellow" }
                "Low" { "Cyan" }
            }
        )
        $_.Group | Format-Table Path, Issue -AutoSize
    }
}
else {
    Write-Host "`n✅ All files follow naming conventions!" -ForegroundColor Green
}

# Export to JSON
$outputPath = Join-Path $PSScriptRoot "naming_conventions_results.json"
$result | ConvertTo-Json -Depth 5 | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Green

return $result
