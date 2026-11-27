# Configuration files that leave settings out, locales by language, input that runs out, trees,
# tables and layouts (2.6.0).

BeforeAll {
    # The tests check colors: NO_COLOR set on this computer would drop them (it is restored afterwards).
    $script:savedNoColorAll = $env:NO_COLOR
    $env:NO_COLOR = $null
    $script:root = Join-Path $PSScriptRoot '..\..'
    Get-Module HermesConsoleUI | Remove-Module -Force
    Import-Module (Join-Path $script:root 'HermesConsoleUI.psd1') -Force

    function Start-HostCapture {
        $script:hostOutput = [System.Collections.Generic.List[object]]::new()
        Mock -ModuleName HermesConsoleUI Write-Host {
            $script:hostOutput.Add([pscustomobject]@{ Text = ($Object -join ' '); Color = "$ForegroundColor"; NoNewline = [bool]$NoNewline })
        }
    }
    function Get-CapturedText { ($script:hostOutput | ForEach-Object Text) -join "`n" }

    function Use-Config([string]$Json) {
        $file = Join-Path $TestDrive ('config-' + [guid]::NewGuid().ToString('N') + '.json')
        Set-Content -LiteralPath $file -Value $Json -Encoding UTF8
        Initialize-UIConfig -ConfigPath $file
    }
}

AfterAll {
    $env:NO_COLOR = $script:savedNoColorAll
    Initialize-UIConfig -ConfigPath (Join-Path $script:root 'config\ui_config.json')
    Get-Module HermesConsoleUI | Remove-Module -Force
}

Describe 'Configuration files' {
    AfterEach { Initialize-UIConfig -ConfigPath (Join-Path $script:root 'config\ui_config.json') }

    It 'works with a file that only changes one setting' {
        Use-Config '{ "UILibrary": { "Components": { "Table": { "MaxColumnWidth": 12 } } } }'
        Get-UIColor -ColorType Success | Should -Be 'Green'
        Get-UIIcon -IconType Warning | Should -Be '[!]'
        Get-UIConfig -Section 'UILibrary.Components.Table.MaxColumnWidth' | Should -Be 12
    }

    It 'can use a theme defined in the file, with the missing roles taken from Default' {
        Use-Config '{ "UILibrary": { "ColorScheme": { "Ocean": { "Primary": "DarkBlue" } } } }'
        Get-AvailableTheme | Should -Contain 'Ocean'
        Set-ConsoleTheme -ThemeName Ocean
        Get-UIColor -ColorType Primary | Should -Be 'DarkBlue'
        Get-UIColor -ColorType Error -WarningAction SilentlyContinue | Should -Be 'Red'
        { Set-ConsoleTheme -ThemeName Nonexistent } | Should -Throw '*not found*'
    }

    It 'never changes the built-in settings' {
        Initialize-UIConfig -ConfigPath (Join-Path $TestDrive 'missing.json')
        Set-ConsoleTheme -ThemeName Custom -CustomColors @{ Primary = 'DarkRed' }
        Initialize-UIConfig -ConfigPath (Join-Path $TestDrive 'missing.json')
        Get-AvailableTheme | Should -Not -Contain 'Custom'
    }

    It 'falls back to the built-in settings when the file is not a JSON object' {
        Use-Config '[1, 2]' 3>$null
        Get-UIColor -ColorType Primary | Should -Be 'Cyan'
    }

    It 'ships a file with only settings the module reads' {
        $config = Get-Content -LiteralPath (Join-Path $script:root 'config\ui_config.json') -Raw | ConvertFrom-Json
        @($config.UILibrary.Components.PSObject.Properties.Name | Sort-Object) | Should -Be @('Status', 'Table')
    }
}

Describe 'Locales' {
    AfterEach { Set-UILocale -Locale en-US }

    It 'uses a locale of the same language for a culture without its own file' {
        Set-UILocale -Locale 'es-MX'
        Get-UILocale | Should -Be 'es-ES'
        Set-UILocale -Locale 'fr'
        Get-UILocale | Should -Be 'fr-FR'
        { Set-UILocale -Locale 'xx-XX' } | Should -Throw
    }

    It 'every locale file has the same keys as en-US' {
        function Get-Key($Node, [string]$Prefix) {
            foreach ($p in $Node.PSObject.Properties) {
                if ($p.Value -is [pscustomobject]) { Get-Key $p.Value "$Prefix$($p.Name)." } else { "$Prefix$($p.Name)" }
            }
        }
        $folder = Join-Path $script:root 'config\locales'
        $english = @(Get-Key (Get-Content (Join-Path $folder 'en-US.json') -Raw -Encoding UTF8 | ConvertFrom-Json) '' | Sort-Object)
        foreach ($file in Get-ChildItem $folder -Filter *.json) {
            $keys = @(Get-Key (Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) '' | Sort-Object)
            $keys | Should -Be $english -Because $file.Name
        }
    }
}

Describe 'Input that runs out' {
    BeforeEach {
        Start-HostCapture
        Mock -ModuleName HermesConsoleUI Read-Host { $null }
        Mock -ModuleName HermesConsoleUI Test-HermesInputRedirected { $true }
    }

    It 'Read-ConsoleInput returns the default value' {
        Read-ConsoleInput -Prompt 'Port' -DefaultValue '8080' -Pattern '\d+' | Should -Be '8080'
    }

    It 'Read-ConsoleInput returns an empty answer when one is allowed' {
        Read-ConsoleInput -Prompt 'Name' | Should -BeExactly ''
    }

    It 'Read-ConsoleInput throws instead of asking forever for a required answer' {
        { Read-ConsoleInput -Prompt 'Name' -Required } | Should -Throw '*input ended*'
        { Read-ConsoleInput -Prompt 'Port' -DefaultValue 'x' -Pattern '\d+' } | Should -Throw '*input ended*'
    }
}

Describe 'Options with the same text' {
    BeforeEach { Start-HostCapture }

    It 'Read-ConsoleMultiChoice -ReturnIndex tells them apart' {
        Mock -ModuleName HermesConsoleUI Read-Host { '2,1' }
        Read-ConsoleMultiChoice -Options 'same', 'same' -ReturnIndex | Should -Be @(1, 0)
    }

    It 'Read-ConsoleSelection -Multiple returns both without a console' {
        Mock -ModuleName HermesConsoleUI Read-Host { '1,2' }
        InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $false }
        try {
            $a = [pscustomobject]@{ Name = 'web'; Id = 1 }
            $b = [pscustomobject]@{ Name = 'web'; Id = 2 }
            $picked = Read-ConsoleSelection -Options $a, $b -DisplayProperty Name -Multiple
            @($picked.Id) | Should -Be @(1, 2)
        }
        finally { InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $null } }
    }
}

Describe 'Trees, tables and layouts' {
    BeforeEach { Start-HostCapture }

    It 'Write-ConsoleTree draws the last item of each level with a corner' {
        $tee = [string][char]0x251C + [char]0x2500 + [char]0x2500 + ' '
        $corner = [string][char]0x2514 + [char]0x2500 + [char]0x2500 + ' '
        $pipe = [string][char]0x2502 + '   '
        $lines = Write-ConsoleTree -TreeData ([ordered]@{ src = [ordered]@{ Core = 'a', 'b' }; tests = 'Unit' }) -Indent '' -ReturnLines
        $lines | Should -Be @(
            "${tee}src"
            "$pipe${corner}Core"
            "$pipe    ${tee}a"
            "$pipe    ${corner}b"
            "${corner}tests"
            "    ${corner}Unit"
        )
        $script:hostOutput.Count | Should -Be 0
    }

    It 'Write-ConsoleTable aligns, cuts and cleans the cells as before' {
        Write-ConsoleTable -Data @(
            [pscustomobject]@{ Name = "tab`there"; Size = 12 }
            [pscustomobject]@{ Name = "esc$([char]27)[31mred"; Size = 3456 }
        ) -Columns @(@{ Header = 'Name'; Property = 'Name' }, @{ Header = 'Size'; Property = 'Size'; Width = 4 })
        $rows = @($script:hostOutput | Where-Object { $_.Text -match 'tab|esc' } | ForEach-Object Text)
        $rows[0] | Should -BeExactly '  tab here  12 '
        # Cut values end with an ellipsis (2.7.0).
        $rows[1] | Should -BeExactly ('  escred   34' + [char]0x2026 + ' ')
    }

    It 'Write-ConsoleLayout starts a new line at each line break of a text column' {
        $layout = New-ConsoleLayout -Rows @(New-ConsoleRow -Columns @(
                    New-ConsoleColumn -WidthPercent 50 -Content "first`nsecond"
                    New-ConsoleColumn -WidthPercent 50 -Content 'right'
                ))
        Write-ConsoleLayout -Layout $layout -TotalWidth 40
        Get-CapturedText | Should -Match '^\s+first\s+right'
        Get-CapturedText | Should -Match '(?m)^\s+second\s*$'
    }
}
