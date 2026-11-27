# Repository hygiene (2.10.0): the runtime files start with a UTF-8 byte order mark, which Windows PowerShell 5.1
# needs to read them as UTF-8; the module names no application that uses it; docs/API.md lists every exported command.

BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:runtime = @(Get-ChildItem -Path (Join-Path $script:root 'modules'), (Join-Path $script:root 'src') -Recurse -Filter *.ps1 -File) +
        @(Get-Item -LiteralPath (Join-Path $script:root 'HermesConsoleUI.psm1'), (Join-Path $script:root 'HermesConsoleUI.psd1'))
}

Describe 'Runtime files' {
    It 'start with a UTF-8 byte order mark' {
        $missing = foreach ($file in $script:runtime) {
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            if (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) { $file.Name }
        }
        @($missing) | Should -BeNullOrEmpty
    }

    It 'name no application that uses the module' {
        $files = @($script:runtime) + @(Get-ChildItem -Path (Join-Path $script:root 'config') -Recurse -Filter *.json -File)
        $hits = @($files | Select-String -Pattern 'cassiel' -CaseSensitive:$false)
        $hits.Count | Should -Be 0
    }
}

Describe 'Public API documentation' {
    It 'lists every exported command and alias in docs/API.md' {
        $manifest = Import-PowerShellDataFile -Path (Join-Path $script:root 'HermesConsoleUI.psd1')
        $api = Get-Content -LiteralPath (Join-Path $script:root 'docs\API.md') -Raw
        $names = @($manifest.FunctionsToExport) + @($manifest.AliasesToExport)
        $missing = @($names | Where-Object { $api -notmatch [regex]::Escape("``$_``") })
        $missing | Should -BeNullOrEmpty
    }
}
