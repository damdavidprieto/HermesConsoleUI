BeforeDiscovery {
    $script:repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
    # Every PowerShell source file that ships or runs, with non-ASCII content.
    $script:nonAsciiFiles = Get-ChildItem -Path $repoRoot -Recurse -Include '*.ps1', '*.psm1', '*.psd1' |
        Where-Object { $_.FullName -notmatch '[\\/](\.git|output)[\\/]' } |
        Where-Object { [IO.File]::ReadAllBytes($_.FullName) | Where-Object { $_ -gt 127 } | Select-Object -First 1 } |
        ForEach-Object { @{ Path = $_.FullName; Name = $_.FullName.Substring($repoRoot.Path.Length + 1) } }
}

BeforeAll {
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
    $manifestPath = Join-Path $repoRoot 'HermesConsoleUI.psd1'
    $manifest = Import-PowerShellDataFile -Path $manifestPath

    Get-Module HermesConsoleUI | Remove-Module -Force
    $module = Import-Module $manifestPath -Force -PassThru
}

AfterAll {
    Get-Module HermesConsoleUI | Remove-Module -Force
}

Describe 'HermesConsoleUI manifest' {
    It 'targets Windows PowerShell 5.1 or later' {
        [version]$manifest.PowerShellVersion | Should -BeGreaterOrEqual ([version]'5.1')
    }

    It 'lists each exported function once' {
        $duplicates = $manifest.FunctionsToExport | Group-Object | Where-Object Count -GT 1
        $duplicates.Name | Should -BeNullOrEmpty
    }

    It 'does not use wildcards in FunctionsToExport' {
        $manifest.FunctionsToExport | Should -Not -Contain '*'
    }

    It 'exports every function listed in the manifest' {
        $exported = $module.ExportedFunctions.Keys
        $missing = $manifest.FunctionsToExport | Where-Object { $_ -notin $exported }
        $missing | Should -BeNullOrEmpty
    }

    It 'exports nothing that is not listed in the manifest' {
        $extra = $module.ExportedFunctions.Keys | Where-Object { $_ -notin $manifest.FunctionsToExport }
        $extra | Should -BeNullOrEmpty
    }

    It 'loads the theme configuration instead of a stub' {
        Get-AvailableThemes | Should -Contain 'Cyberpunk'
    }
}

Describe 'Source file encoding' {
    # Windows PowerShell 5.1 reads BOM-less files as ANSI, which breaks non-ASCII text.
    It '<Name> has a UTF-8 BOM' -ForEach $nonAsciiFiles {
        $bytes = [IO.File]::ReadAllBytes($Path)
        ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should -BeTrue
    }
}
