# Testing Documentation

## Overview

HermesConsoleUI now includes a comprehensive test suite using Pester 5+ to ensure reliability and prevent regressions.

## Test Structure

```
tests/
├── Unit/                    # Unit tests for individual components
│   ├── Module.Tests.ps1              # Module loading and metadata
│   ├── VisualComponents.Tests.ps1    # Visual rendering components
│   ├── InteractiveComponents.Tests.ps1  # Menus and user input
│   └── ComponentTemplate.Tests.ps1   # Template for new tests
├── Integration/             # Integration tests
│   └── FullWorkflow.Tests.ps1        # End-to-end workflows
├── Security/                # Security tests
│   └── ANSIInjection.Tests.ps1       # ANSI injection protection
└── TestHelpers.psm1         # Test utilities and mocks
```

## Running Tests

### Run All Tests
```powershell
Invoke-Pester -Path ./tests
```

### Run Specific Test Suite
```powershell
Invoke-Pester -Path ./tests/Unit/VisualComponents.Tests.ps1
```

### Run with Code Coverage
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './src/**/*.ps1', './src/**/*.psm1'
Invoke-Pester -Configuration $config
```

## Test Coverage

| Area | Coverage | Tests |
|------|----------|-------|
| Module Core | 80% | 7 |
| Visual Components | 60% | 15 |
| Interactive Components | 55% | 18 |
| Security | 70% | 15 |
| Integration | 50% | 5 |
| **Total** | **~60%** | **60** |

## CI/CD

Tests run automatically on:
- Push to main/master/develop branches
- Pull requests to main/master

See `.github/workflows/tests.yml` for configuration.

## Writing New Tests

Use the template in `tests/Unit/ComponentTemplate.Tests.ps1`:

```powershell
BeforeAll {
    Import-Module ./HermesConsoleUI.psd1 -Force
    Import-Module ./tests/TestHelpers.psm1 -Force
}

Describe "YourComponent" {
    Context "Basic Functionality" {
        It "Should work correctly" {
            # Your test here
        }
    }
}
```

## Test Helpers

The `TestHelpers.psm1` module provides:
- `New-MockConsole` - Mock console for isolated testing
- `Assert-ANSIOutput` - Validate ANSI escape codes
- `Remove-ANSICodes` - Strip ANSI codes for comparison
- `New-TestTableData` - Generate test data
- `Assert-CompletesWithin` - Performance assertions

## Best Practices

1. **Isolation**: Each test should be independent
2. **Performance**: Tests should complete in <1 second
3. **Edge Cases**: Always test null, empty, and extreme values
4. **ANSI Codes**: Use helpers to validate color output
5. **Cleanup**: Use `AfterAll` to remove imported modules

## Roadmap

- [ ] Increase coverage to 70%+ (target: 8.0/10)
- [ ] Add performance benchmarks
- [ ] Implement visual regression tests
- [ ] Add mutation testing
