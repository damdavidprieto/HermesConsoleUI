# Hygiene Analysis Suite for HermesConsoleUI

This directory contains automated hygiene analysis tools for HermesConsoleUI.

## Quick Start

```powershell
# Run all hygiene analyses
.\Invoke-HygieneAnalysis.ps1

# Run specific analysis
.\Analyze-FileStructure.ps1
.\Find-TemporaryFiles.ps1
.\Analyze-FileSize.ps1

# Run hygiene tests
Invoke-Pester .\Test-ProjectHygiene.Tests.ps1
```

## Analysis Scripts

- **Invoke-HygieneAnalysis.ps1** - Master script that runs all analyses
- **Analyze-FileStructure.ps1** - Analyzes project structure and organization
- **Find-TemporaryFiles.ps1** - Detects temporary and development files
- **Analyze-FileSize.ps1** - Analyzes file sizes and detects blobs
- **Test-NamingConventions.ps1** - Validates naming conventions
- **Analyze-GitIgnore.ps1** - Analyzes .gitignore configuration
- **Export-FileTreeDiagram.ps1** - Generates visual file tree
- **Export-SizeDistribution.ps1** - Generates size distribution chart

## Test Scripts

- **Test-ProjectHygiene.Tests.ps1** - Pester tests for project hygiene
