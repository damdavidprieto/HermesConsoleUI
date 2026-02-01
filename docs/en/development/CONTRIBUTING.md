# Contributing to PSConsoleUI

First off, thank you for considering contributing to PSConsoleUI! It's people like you that make PSConsoleUI such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps to reproduce the problem**
* **Provide specific examples** to demonstrate the steps
* **Describe the behavior you observed** and what you expected to see
* **Include PowerShell version** (`$PSVersionTable.PSVersion`)
* **Include OS version** (Windows version)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a detailed description** of the suggested enhancement
* **Explain why this enhancement would be useful**
* **List any similar features** in other frameworks

### Pull Requests

* Fill in the required template
* Follow the PowerShell style guide
* Include appropriate test cases
* Update documentation as needed
* End all files with a newline

## Development Setup

1. **Fork and clone the repository**
```powershell
git clone https://github.com/YOUR_USERNAME/PSConsoleUI.git
cd PSConsoleUI
```

2. **Import the module**
```powershell
Import-Module .\PSConsoleUI.psd1 -Force
```

3. **Run tests**
```powershell
Invoke-Pester -Path .\tests\
```

## Style Guidelines

### PowerShell Style Guide

* Use **PascalCase** for function names (e.g., `Write-ConsoleStatus`)
* Use **camelCase** for parameters (e.g., `$Message`, `$Type`)
* Use **4 spaces** for indentation (no tabs)
* Use **full cmdlet names** (not aliases) in scripts
* Add **comment-based help** to all public functions
* Use **approved verbs** for function names (`Get-Verb`)

### Comment-Based Help

All public functions must include:
```powershell
<#
.SYNOPSIS
    Brief description

.DESCRIPTION
    Detailed description

.PARAMETER ParameterName
    Parameter description

.EXAMPLE
    Example usage
#>
```

### Testing

* Write **Pester tests** for all new functionality
* Ensure **all tests pass** before submitting PR
* Aim for **80%+ code coverage**

## Project Structure

```
PSConsoleUI/
├── modules/          # Component modules
├── src/Core/         # Core systems (Config, i18n)
├── config/           # Configuration files
├── docs/             # Documentation
├── examples/         # Usage examples
└── tests/            # Pester tests
```

## Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

Example:
```
Add Write-ConsoleSparkline component

- Implements inline mini-charts
- Uses 8-level Unicode characters
- Includes comprehensive help
- Adds Pester tests

Closes #123
```

## Component Development Guidelines

When adding new components:

1. **Add to appropriate module** (`modules/ui_components.psm1`)
2. **Include comprehensive help** (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
3. **Add parameter validation** (`[ValidateNotNullOrEmpty()]`, etc.)
4. **Export the function** (add to exports list)
5. **Update PSConsoleUI.psm1** (add to exports)
6. **Create examples** (`examples/`)
7. **Write tests** (`tests/`)
8. **Update documentation** (`docs/`)

## Release Process

1. Update version in `PSConsoleUI.psd1`
2. Update `CHANGELOG.md`
3. Run full test suite
4. Create GitHub release
5. Publish to PowerShell Gallery (maintainers only)

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
