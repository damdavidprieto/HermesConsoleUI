<#
.SYNOPSIS
    Analyzes and optimizes .gitignore configuration.

.DESCRIPTION
    Evaluates the .gitignore file and provides recommendations for improvements.

.EXAMPLE
    .\Analyze-GitIgnore.ps1
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)

Write-Host "`n=== .gitignore Analysis ===" -ForegroundColor Cyan
Write-Host "Analyzing project: $ProjectRoot`n"

$gitignorePath = Join-Path $ProjectRoot ".gitignore"
$gitignoreExists = Test-Path $gitignorePath

if (-not $gitignoreExists) {
    Write-Host "⚠️  No .gitignore file found!" -ForegroundColor Red
    return [PSCustomObject]@{
        Exists         = $false
        Score          = 0
        Recommendation = "Create .gitignore file"
    }
}

# Read current patterns
$currentPatterns = Get-Content $gitignorePath | Where-Object { 
    $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' 
}

Write-Host "Current patterns: $($currentPatterns.Count)"

# Recommended patterns for PowerShell projects
$recommendedPatterns = @(
    # PowerShell
    '*.log'
    '*.tmp'
    '*.bak'
    '*.old'
    '*~'
    
    # OS files
    '.DS_Store'
    'Thumbs.db'
    'desktop.ini'
    
    # Editor files
    '.vscode/'
    '.idea/'
    '*.swp'
    '*.swo'
    
    # Development
    '/dev'
    '/temp'
    '/scratch'
    
    # Build artifacts
    '/bin'
    '/obj'
    '/out'
    
    # Dependencies
    'node_modules/'
    'packages/'
)

# Find missing patterns
$missingPatterns = $recommendedPatterns | Where-Object { $_ -notin $currentPatterns }

# Find potentially redundant patterns
$redundantPatterns = @()
# (Simple check - could be enhanced)

# Check for tracked files that should be ignored
$trackedButShouldIgnore = @()
if (Test-Path (Join-Path $ProjectRoot ".git")) {
    try {
        $trackedFiles = git -C $ProjectRoot ls-files 2>$null
        
        foreach ($file in $trackedFiles) {
            if ($file -match '\.(tmp|bak|old|log)$' -or
                $file -match '^(temp|debug|scratch)_' -or
                $file -match '(\.DS_Store|Thumbs\.db)$') {
                $trackedButShouldIgnore += $file
            }
        }
    }
    catch {
        # Git not available or not a git repo
    }
}

# Calculate score
$score = 10.0
$score -= ($missingPatterns.Count * 0.3)  # -0.3 per missing pattern
$score -= ($trackedButShouldIgnore.Count * 0.5)  # -0.5 per tracked file that should be ignored
$score = [Math]::Max(0, [Math]::Round($score, 1))

# Build result
$result = [PSCustomObject]@{
    ProjectRoot            = $ProjectRoot
    Exists                 = $true
    CurrentPatterns        = $currentPatterns
    MissingPatterns        = $missingPatterns
    TrackedButShouldIgnore = $trackedButShouldIgnore
    RedundantPatterns      = $redundantPatterns
    Score                  = $score
}

# Display results
Write-Host "=== Analysis Results ===" -ForegroundColor Yellow
Write-Host ".gitignore Score: $score/10"
Write-Host "Current Patterns: $($currentPatterns.Count)"
Write-Host "Missing Recommended Patterns: $($missingPatterns.Count)"
Write-Host "Tracked Files That Should Be Ignored: $($trackedButShouldIgnore.Count)"

if ($missingPatterns.Count -gt 0) {
    Write-Host "`n=== Missing Recommended Patterns ===" -ForegroundColor Yellow
    $missingPatterns | ForEach-Object { Write-Host "  + $_" -ForegroundColor Cyan }
}

if ($trackedButShouldIgnore.Count -gt 0) {
    Write-Host "`n⚠️  Tracked Files That Should Be Ignored:" -ForegroundColor Red
    $trackedButShouldIgnore | ForEach-Object { Write-Host "  - $_" }
    Write-Host "`nRecommendation: Add these files to .gitignore and run 'git rm --cached <file>'"
}

if ($score -ge 9.0) {
    Write-Host "`n✅ Excellent .gitignore configuration!" -ForegroundColor Green
}
elseif ($score -ge 7.0) {
    Write-Host "`n✓ Good .gitignore configuration with minor improvements possible" -ForegroundColor Yellow
}
else {
    Write-Host "`n⚠️  .gitignore needs improvement" -ForegroundColor Red
}

# Export to JSON
$outputPath = Join-Path $PSScriptRoot "gitignore_analysis_results.json"
$result | ConvertTo-Json -Depth 5 | Out-File $outputPath
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Green

return $result
