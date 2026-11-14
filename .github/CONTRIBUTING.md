# Contributing

Thanks for helping improve HermesConsoleUI. Issues and pull requests are welcome.

## Setting up

```powershell
git clone https://github.com/damdavidprieto/HermesConsoleUI.git
cd HermesConsoleUI
.\build.ps1 -InstallDependencies   # Pester 5 and PSScriptAnalyzer, first time only
.\build.ps1                        # analysis, tests and package
```

`build.ps1` must pass on both Windows PowerShell 5.1 and PowerShell 7 before a pull request is merged;
CI checks both.

## Making a change

- **New command:** add it to the right file in `modules/`, then to `FunctionsToExport` in
  `HermesConsoleUI.psd1` and to `Export-ModuleMember` in `HermesConsoleUI.psm1`. The QA tests fail if
  the two lists differ.
- **Help:** every exported command needs comment-based help with a synopsis, a description, an
  example and a description for each parameter. `tests/QA/Module.Tests.ps1` checks it.
- **Output:** write to the console with `Write-HermesHost`, not `Write-Host`, so control sequences are
  removed. Take colors from the theme with `Resolve-UIColor` and fixed texts from the locale with
  `Get-UIText`.
- **Analyzer:** the code must have no findings with `PSScriptAnalyzerSettings.psd1`. If a rule does not
  apply, suppress it on that function with `SuppressMessageAttribute` and a justification.
- **Encoding:** save files that contain non-ASCII characters as UTF-8 with BOM, or Windows PowerShell
  5.1 will misread them.
- **Tests:** add or update tests in `tests/Unit`. Mock `Write-Host` and `Read-Host` with
  `-ModuleName HermesConsoleUI` to check what a component writes or to simulate input.
- **Changelog:** describe the change under `## [Unreleased]` in `CHANGELOG.md`.

## Releasing

1. Move the `Unreleased` entries in `CHANGELOG.md` under the new version and update `ModuleVersion`
   in the manifest.
2. Push a tag `v<version>`. The `Publish` workflow checks that the tag matches the manifest, runs the
   build and publishes `output/HermesConsoleUI` to the PowerShell Gallery.

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
