BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '..\..\HermesConsoleUI.psd1'
    Get-Module HermesConsoleUI | Remove-Module -Force
    Import-Module $manifestPath -Force

    $esc = [char]27
    $bel = [char]7
}

AfterAll {
    Get-Module HermesConsoleUI | Remove-Module -Force
}

Describe 'ConvertTo-ConsoleSafeText' {
    It 'removes <Name>' -TestCases @(
        @{ Name = 'color codes (CSI)'; Raw = "$([char]27)[31mred$([char]27)[0m"; Expected = 'red' }
        @{ Name = 'cursor movement (CSI)'; Raw = "ok$([char]27)[2A$([char]27)[2Kfake"; Expected = 'okfake' }
        @{ Name = 'clipboard write (OSC 52)'; Raw = "x$([char]27)]52;c;ZXZpbA==$([char]7)y"; Expected = 'xy' }
        @{ Name = 'window title (OSC 0 with ST)'; Raw = "a$([char]27)]0;pwned$([char]27)\b"; Expected = 'ab' }
        @{ Name = '8-bit CSI'; Raw = "a$([char]0x9B)31mb"; Expected = 'ab' }
        @{ Name = 'carriage return, backspace and bell'; Raw = "safe`rEVIL`b$([char]7)!"; Expected = 'safeEVIL!' }
    ) {
        InModuleScope HermesConsoleUI -Parameters @{ Raw = $Raw } { param($Raw) ConvertTo-ConsoleSafeText -Text $Raw } |
            Should -BeExactly $Expected
    }

    It 'keeps line feeds, tabs, accents and box-drawing characters' {
        $text = "línea 1`n`tcolumna $([char]0x2502) $([char]0x2588) ñ"
        InModuleScope HermesConsoleUI -Parameters @{ Text = $text } { param($Text) ConvertTo-ConsoleSafeText -Text $Text } |
            Should -BeExactly $text
    }

    It 'turns CRLF into LF' {
        InModuleScope HermesConsoleUI { ConvertTo-ConsoleSafeText -Text "a`r`nb" } | Should -BeExactly "a`nb"
    }
}

Describe 'Components do not write control sequences' {
    BeforeEach {
        $script:written = [System.Collections.Generic.List[string]]::new()
        Mock -ModuleName HermesConsoleUI Write-Host { $script:written.Add(($Object -join ' ')) }
    }

    It '<Name>' -TestCases @(
        @{ Name = 'Write-ConsoleTable'; Call = { Write-ConsoleTable -Data @([pscustomobject]@{ File = "$([char]27)]52;c;ZXZpbA==$([char]7)report.txt" }) -Columns @(@{ Header = 'File'; Property = 'File'; Width = 20 }) } }
        @{ Name = 'Show-ConsoleList'; Call = { Show-ConsoleList -Items @("$([char]27)[2Kfake line") } }
        @{ Name = 'Write-ConsoleStatus'; Call = { Write-ConsoleStatus -Message "done$([char]27)[8m hidden" -Type Success } }
        @{ Name = 'Write-ConsoleBox'; Call = { Write-ConsoleBox -Message "box$([char]27)[31m" } }
        @{ Name = 'Show-ConsoleMenu'; Call = { Show-ConsoleMenu -Title 'Menu' -Options @("one$([char]27)[2J") -NoClear } }
    ) {
        & $Call | Out-Null
        $script:written.Count | Should -BeGreaterThan 0
        ($script:written -join "`n") | Should -Not -Match '[\x1B\x07\x9B]'
    }
}

Describe 'Input validation' {
    It 'Read-ConsoleMultiChoice ignores 0, out-of-range, overflowing and repeated indexes' {
        Mock -ModuleName HermesConsoleUI Write-Host { }
        Mock -ModuleName HermesConsoleUI Read-Host { '0, 2,2 ,99999999999999,3,4' }

        $result = Read-ConsoleMultiChoice -Options @('A', 'B', 'C')

        $result | Should -Be @('B', 'C')
    }

    It 'Read-ConsoleChoice asks again after an overflowing number instead of throwing' {
        Mock -ModuleName HermesConsoleUI Write-Host { }
        $script:answers = [System.Collections.Generic.Queue[string]]::new([string[]]@('99999999999999', '2'))
        Mock -ModuleName HermesConsoleUI Read-Host { $script:answers.Dequeue() }

        Read-ConsoleChoice -MaxChoice 3 | Should -Be 2
    }

    It 'Show-ConsoleMenu ignores an unknown {Color} prefix instead of failing' {
        Mock -ModuleName HermesConsoleUI Write-Host { }
        { Show-ConsoleMenu -Title 'Menu' -Options @('{NotAColor}Item', '{red}Other') -NoClear } | Should -Not -Throw
    }
}
