# Text width, cutting and wrapping, exact colors, prompts in captures, keyed menus, filtering and
# status lines (2.7.0).

BeforeAll {
    $script:savedNoColorAll = $env:NO_COLOR
    $env:NO_COLOR = $null
    Get-Module HermesConsoleUI | Remove-Module -Force
    Import-Module (Join-Path $PSScriptRoot '..\..\HermesConsoleUI.psd1') -Force

    function Start-HostCapture {
        $script:hostOutput = [System.Collections.Generic.List[object]]::new()
        Mock -ModuleName HermesConsoleUI Write-Host {
            $script:hostOutput.Add([pscustomobject]@{ Text = ($Object -join ' '); Color = "$ForegroundColor"; NoNewline = [bool]$NoNewline })
        }
    }

    # Collects what an output handler receives, as complete lines.
    function Start-HandlerCapture {
        $script:captured = [System.Collections.Generic.List[string]]::new()
        $script:pending = ''
        Register-ConsoleOutputHandler -Quiet -Confirm:$false {
            param($Text, $NoNewline)
            $script:pending += $Text
            if (-not $NoNewline) { $script:captured.Add($script:pending); $script:pending = '' }
        }
    }

    function Use-Keys([object[]]$Keys) {
        $queue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new()
        foreach ($k in $Keys) {
            if ($k -is [char]) { $queue.Enqueue([System.ConsoleKeyInfo]::new($k, [System.ConsoleKey]::A, $false, $false, $false)) }
            else { $queue.Enqueue([System.ConsoleKeyInfo]::new([char]0, [System.ConsoleKey]$k, $false, $false, $false)) }
        }
        InModuleScope HermesConsoleUI -Parameters @{ Queue = $queue } {
            param($Queue)
            $script:HermesInteractiveOverride = $true
            $script:HermesKeyQueue = $Queue
            $script:HermesReadKey = { $script:HermesKeyQueue.Dequeue() }
        }
    }
}

AfterAll {
    InModuleScope HermesConsoleUI {
        $script:HermesInteractiveOverride = $null
        $script:HermesReadKey = { [Console]::ReadKey($true) }
        $script:HermesTrueColorOverride = $null
        $script:HermesLiveOverride = $null
    }
    Unregister-ConsoleOutputHandler -Confirm:$false
    Get-Module HermesConsoleUI | Remove-Module -Force
    $env:NO_COLOR = $script:savedNoColorAll
}

Describe 'Measure-ConsoleText and Format-ConsoleText' {
    It 'counts <Case> as <Width> columns' -TestCases @(
        @{ Case = 'plain text'; Text = 'Firewall'; Width = 8 }
        @{ Case = 'accents'; Text = 'Configuraci' + [char]0x00F3 + 'n'; Width = 13 }
        @{ Case = 'a combining accent'; Text = 'e' + [char]0x0301; Width = 1 }
        @{ Case = 'East Asian characters'; Text = [string][char]0x65E5 + [char]0x672C; Width = 4 }
        @{ Case = 'an emoji'; Text = 'ok ' + [char]::ConvertFromUtf32(0x1F600); Width = 5 }
    ) {
        Measure-ConsoleText -Text $Text | Should -Be $Width
    }

    It 'cuts with an ellipsis and pads' {
        $ellipsis = [string][char]0x2026
        Format-ConsoleText -Text 'Windows Defender Firewall' -Width 12 | Should -BeExactly ('Windows Def' + $ellipsis)
        Format-ConsoleText -Text 'Windows Defender Firewall' -Width 12 -NoEllipsis | Should -BeExactly 'Windows Defe'
        Format-ConsoleText -Text '42' -Width 6 -Align Right | Should -BeExactly '    42'
        Format-ConsoleText -Text 'ab' -Width 4 -Align Left | Should -BeExactly 'ab  '
        Format-ConsoleText -Text "a`tb`nc$([char]27)[31m" -Width 10 | Should -BeExactly 'a b c'
        Format-ConsoleText -Text 'x' -Width 0 | Should -BeExactly ''
    }

    It 'never splits a wide character' {
        $wide = -join @([char]0x65E5, [char]0x672C, [char]0x8A9E)
        $cut = Format-ConsoleText -Text $wide -Width 4 -Align Left
        Measure-ConsoleText -Text $cut | Should -Be 4
        $cut | Should -BeExactly ([string][char]0x65E5 + [char]0x2026 + ' ')
    }

    It 'Get-ConsoleWidth honours -Maximum and -Default' {
        $width = Get-ConsoleWidth -Maximum 10 -Default 7
        $width | Should -BeGreaterThan 0
        $width | Should -BeLessOrEqual 10
    }
}

Describe 'Write-ConsoleText -Wrap' {
    BeforeEach { Start-HostCapture; Start-HandlerCapture }
    AfterEach { Unregister-ConsoleOutputHandler -Confirm:$false }

    It 'breaks at spaces, indents the next lines and keeps the colors' {
        Write-ConsoleText -Wrap -Width 30 -Indent 6 '  {Red}[x]{/} The firewall of the public profile is off.'
        $script:captured | Should -Be @('  [x] The firewall of the', '      public profile is off.')
        foreach ($line in $script:captured) { (Measure-ConsoleText -Text $line) | Should -BeLessOrEqual 30 }
        Unregister-ConsoleOutputHandler -Confirm:$false
        Start-HostCapture
        Write-ConsoleText -Wrap -Width 30 '{Red}[x]{/} plain'
        ($script:hostOutput | Where-Object Text -EQ '[x]').Color | Should -Be 'Red'
    }

    It 'keeps line breaks, and indents every line after the first like the paragraph' {
        Write-ConsoleText -Wrap -Width 20 "    one two three four five`nsix"
        $script:captured | Should -Be @('    one two three', '    four five', '    six')
    }
}

Describe 'Exact colors' {
    BeforeEach { Start-HostCapture }
    AfterEach { InModuleScope HermesConsoleUI { $script:HermesTrueColorOverride = $null } }

    It 'uses the nearest console color where true color is not available' {
        InModuleScope HermesConsoleUI { $script:HermesTrueColorOverride = $false }
        Write-ConsoleText '{#FF8800}orange{/}'
        ($script:hostOutput | Where-Object Text -EQ 'orange').Color | Should -Be 'Yellow'
    }

    It 'writes the exact color with an escape sequence of its own where it is available' {
        InModuleScope HermesConsoleUI { $script:HermesTrueColorOverride = $true }
        Write-ConsoleInfo -Message 'exact' -Color '#FF8800'
        $line = $script:hostOutput | Where-Object Text -Match 'exact'
        $line.Text | Should -Match ([regex]::Escape("$([char]27)[38;2;255;136;0m"))
        $line.Color | Should -BeNullOrEmpty
    }
}

Describe 'Charts and tables' {
    BeforeEach { Start-HostCapture }

    It 'Write-ConsoleChart picks the color of the highest threshold reached' {
        Write-ConsoleChart -Label 'Compliance' -Value 82 -Thresholds @{ 0 = 'Red'; 70 = 'Yellow'; 100 = 'Green' }
        ($script:hostOutput | Where-Object Text -Match '82%').Color | Should -Be 'Yellow'
        Write-ConsoleChart -Value 50 -ReturnLines | Should -Match '^50% \['
    }

    It 'Write-ConsoleTable shows mapped words, each in its color, and returns lines' {
        $data = @([pscustomobject]@{ Rule = 'Firewall'; Status = 'Compliant' }, [pscustomobject]@{ Rule = 'SMB'; Status = 'NonCompliant' })
        $columns = @(@{ Header = 'Rule'; Property = 'Rule' }, @{ Header = 'State'; Property = 'Status'; Map = @{ Compliant = 'OK'; NonCompliant = 'Pending' }; Colors = @{ Compliant = 'Green'; NonCompliant = 'Red' } })
        Write-ConsoleTable -Data $data -Columns $columns
        ($script:hostOutput | Where-Object Text -Match '^OK').Color | Should -Be 'Green'
        ($script:hostOutput | Where-Object Text -Match '^Pending').Color | Should -Be 'Red'
        $lines = Write-ConsoleTable -Data $data -Columns $columns -ReturnLines
        $lines | Should -Be @('Rule     State', '-------- -------', 'Firewall OK', 'SMB      Pending')
    }
}

Describe 'Prompts in a capture' {
    BeforeEach { Start-HostCapture; Start-HandlerCapture }
    AfterEach { Unregister-ConsoleOutputHandler -Confirm:$false }

    It 'keeps the answers to <Name>' -TestCases @(
        @{ Name = 'Read-ConsoleChoice'; Answer = '2'; Call = { Read-ConsoleChoice -MaxChoice 3 -Prompt 'Pick' }; Expected = 'Pick: 2' }
        @{ Name = 'Read-ConsoleInput'; Answer = 'web01'; Call = { Read-ConsoleInput -Prompt 'Server' }; Expected = 'Server: web01' }
        @{ Name = 'Read-ConsoleConfirmation with Enter'; Answer = ''; Call = { Read-ConsoleConfirmation -Message 'Apply?' -Default $true }; Expected = 'Apply? (Y/n): y' }
        @{ Name = 'Read-ConsoleMultiChoice'; Answer = '1,2'; Call = { Read-ConsoleMultiChoice -Options 'a', 'b' }; Expected = '    > 1,2' }
    ) {
        Set-UILocale -Locale en-US
        Mock -ModuleName HermesConsoleUI Read-Host { $Answer }.GetNewClosure()
        $null = & $Call
        $script:captured | Should -Contain $Expected
    }

    It 'shows that a password was typed, never the password' {
        Mock -ModuleName HermesConsoleUI Read-Host { ConvertTo-SecureString 'Zanahoria9' -AsPlainText -Force }
        $null = Read-ConsolePassword -Prompt 'Admin password'
        $script:captured | Should -Contain 'Admin password: ********'
        ($script:captured -join "`n") | Should -Not -Match 'Zanahoria9'
    }

    It 'keeps the option chosen in the arrow-key list once, not every redraw' {
        Use-Keys 'DownArrow', 'DownArrow', 'Enter'
        try { $null = Read-ConsoleSelection -Title 'Deploy to' -Options 'Dev', 'Staging', 'Prod' }
        finally { InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $null } }
        $script:captured | Should -Be @('  Deploy to', '  > Prod')
    }
}

Describe 'Read-ConsoleChoice -Choices' {
    BeforeEach { Start-HostCapture; Set-UILocale -Locale en-US }

    It 'returns the choice as written, whatever the case' {
        Mock -ModuleName HermesConsoleUI Read-Host { 'APPLY' }
        Read-ConsoleChoice -Choices 'apply', 'skip' | Should -BeExactly 'apply'
    }

    It 'returns the default for Enter and when the input runs out' {
        Mock -ModuleName HermesConsoleUI Read-Host { '' }
        Read-ConsoleChoice -Choices 'apply', 'skip' -DefaultValue 'SKIP' | Should -BeExactly 'skip'
        Mock -ModuleName HermesConsoleUI Read-Host { $null }
        Mock -ModuleName HermesConsoleUI Test-HermesInputRedirected { $true }
        Read-ConsoleChoice -Choices 'apply', 'skip' -DefaultValue 'skip' | Should -BeExactly 'skip'
        { Read-ConsoleChoice -Choices 'apply', 'skip' } | Should -Throw '*input ended*'
    }

    It 'asks again after an answer that is not a choice' {
        $script:answers = [System.Collections.Generic.Queue[string]]::new([string[]]@('maybe', 'skip'))
        Mock -ModuleName HermesConsoleUI Read-Host { $script:answers.Dequeue() }
        Read-ConsoleChoice -Choices 'apply', 'skip' | Should -BeExactly 'skip'
        ($script:hostOutput.Text -join "`n") | Should -Match '"maybe" is not an option. Type one of: apply, skip'
        { Read-ConsoleChoice -Choices 'apply' -DefaultValue 'other' } | Should -Throw '*not one of*'
    }
}

Describe 'Read-ConsoleMenu' {
    BeforeEach { Start-HostCapture; Set-UILocale -Locale en-US }
    AfterEach { InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $null } }

    It 'lists keys, texts, notes and the recommended option, and reads the key without a console' {
        InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $false }
        Mock -ModuleName HermesConsoleUI Read-Host { 'R' }
        $items = [ordered]@{ a = 'Audit', 'Check every rule'; r = @{ Label = 'Repair'; Note = 'Apply the pending rules'; Color = 'Yellow' }; q = 'Quit' }
        Read-ConsoleMenu -Items $items -Recommended a | Should -BeExactly 'r'
        $text = $script:hostOutput.Text -join ''
        $text | Should -Match 'Check every rule'
        $text | Should -Match 'recommended'
        ($script:hostOutput | Where-Object Text -Match '^Repair').Color | Should -Be 'Yellow'
    }

    It 'returns the default when the input runs out' {
        InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $false }
        Mock -ModuleName HermesConsoleUI Read-Host { $null }
        Mock -ModuleName HermesConsoleUI Test-HermesInputRedirected { $true }
        Read-ConsoleMenu -Items ([ordered]@{ a = 'Audit'; q = 'Quit' }) -Default q | Should -BeExactly 'q'
    }

    It 'chooses with the arrow keys, and Escape returns -Cancel' {
        Use-Keys 'DownArrow', 'Enter'
        Read-ConsoleMenu -Items ([ordered]@{ a = 'Audit'; r = 'Repair'; q = 'Quit' }) | Should -BeExactly 'r'
        Use-Keys 'Escape'
        Read-ConsoleMenu -Items ([ordered]@{ a = 'Audit'; q = 'Quit' }) -Cancel q | Should -BeExactly 'q'
        Use-Keys 'Escape'
        Read-ConsoleMenu -Items ([ordered]@{ a = 'Audit'; q = 'Quit' }) | Should -BeNullOrEmpty
    }
}

Describe 'Read-ConsoleSelection -Filter' {
    BeforeEach { Start-HostCapture }
    AfterEach { InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $null } }

    It 'narrows the list to the options that contain the typed text' {
        Use-Keys ([char]'r'), ([char]'o'), 'Enter'
        Read-ConsoleSelection -Options 'Firewall', 'Defender', 'Proxy', 'Updates' -Filter | Should -Be 'Proxy'
    }

    It 'deletes with Backspace, and the first Escape clears the filter' {
        Use-Keys ([char]'x'), ([char]'x'), 'Backspace', 'Backspace', 'DownArrow', 'Enter'
        Read-ConsoleSelection -Options 'Firewall', 'Defender' -Filter | Should -Be 'Defender'
        Use-Keys ([char]'z'), 'Escape', 'Escape'
        Read-ConsoleSelection -Options 'Firewall', 'Defender' -Filter | Should -BeNullOrEmpty
    }

    It 'shows that nothing matches and ignores Enter then' {
        Use-Keys ([char]'z'), 'Enter', 'Backspace', 'Enter'
        Read-ConsoleSelection -Options 'Firewall', 'Defender' -Filter | Should -Be 'Firewall'
        ($script:hostOutput.Text -join "`n") | Should -Match '\(no matches\)'
    }
}

Describe 'Status line and clearing the screen' {
    BeforeEach { Start-HostCapture }
    AfterEach { InModuleScope HermesConsoleUI { $script:HermesLiveOverride = $null; $script:HermesOutput.StatusLineActive = $false } }

    It 'rewrites one line in place, and clears it before other output' {
        InModuleScope HermesConsoleUI { $script:HermesLiveOverride = $true }
        Start-HandlerCapture
        try {
            Write-ConsoleStatusLine -Text 'Checking' -Percent 5
            Write-ConsoleStatusLine -Text "Checking more$([char]27)[2J"
            Write-ConsoleInfo -Message 'done'
        }
        finally { Unregister-ConsoleOutputHandler -Confirm:$false }
        $texts = @($script:hostOutput.Text)
        $texts[0] | Should -Match "^`r {4}5 %  Checking"
        $texts[1] | Should -Match "^`r  Checking more\s*$"
        $texts[2] | Should -Match "^`r\s+`r$"
        # -Quiet: the message only goes to the handler, which never receives the status line.
        $texts.Count | Should -Be 3
        $script:captured | Should -Be @('  [i] done')
    }

    It 'writes nothing when the output is redirected' {
        InModuleScope HermesConsoleUI { $script:HermesLiveOverride = $false }
        Write-ConsoleStatusLine -Text 'Checking'
        Clear-ConsoleStatusLine
        $script:hostOutput.Count | Should -Be 0
    }

    It 'Clear-ConsoleScreen clears a real console and writes a blank line elsewhere' {
        Mock -ModuleName HermesConsoleUI Clear-Host { }
        InModuleScope HermesConsoleUI { $script:HermesLiveOverride = $true }
        Clear-ConsoleScreen
        Should -Invoke -ModuleName HermesConsoleUI Clear-Host -Times 1 -Exactly
        InModuleScope HermesConsoleUI { $script:HermesLiveOverride = $false }
        Clear-ConsoleScreen
        Should -Invoke -ModuleName HermesConsoleUI Clear-Host -Times 1 -Exactly
        $script:hostOutput.Count | Should -Be 1
    }
}
