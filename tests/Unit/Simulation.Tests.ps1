# Simulated keys and answers, prompts that end in ':' or '?', segments merged into one list, the label width of
# key-value lists, cut text with line breaks and the prefix of Write-ConsoleText (2.9.0).

BeforeAll {
    $script:savedNoColorAll = $env:NO_COLOR
    $env:NO_COLOR = $null
    Get-Module HermesConsoleUI | Remove-Module -Force
    Import-Module (Join-Path $PSScriptRoot '..\..\HermesConsoleUI.psd1') -Force

    # Collects what an output handler receives: complete lines, and the pieces with their colors.
    function Start-HandlerCapture {
        $script:captured = [System.Collections.Generic.List[string]]::new()
        $script:pieces = [System.Collections.Generic.List[object]]::new()
        $script:pending = ''
        Register-ConsoleOutputHandler -Quiet -Confirm:$false {
            param($Text, $NoNewline, $Color)
            if ($Text) { $script:pieces.Add([pscustomobject]@{ Text = $Text; Color = $Color }) }
            $script:pending += $Text
            if (-not $NoNewline) { $script:captured.Add($script:pending); $script:pending = '' }
        }
    }

    $script:ellipsis = [string][char]0x2026
}

AfterAll {
    Disable-ConsoleSimulation -Confirm:$false
    Unregister-ConsoleOutputHandler -Confirm:$false
    Set-ConsoleLayout -Reset -Confirm:$false
    Get-Module HermesConsoleUI | Remove-Module -Force
    $env:NO_COLOR = $script:savedNoColorAll
}

Describe 'Simulated keys and answers' {
    BeforeEach {
        # The menus draw on the screen: a quiet handler keeps the test output clean.
        Register-ConsoleOutputHandler -Quiet -Confirm:$false { param($Text) $null = $Text }
    }

    AfterEach {
        Disable-ConsoleSimulation -Confirm:$false
        Unregister-ConsoleOutputHandler -Confirm:$false
    }

    It 'reads the keys of a menu: DownArrow and Enter pick the second option' {
        $pick = Invoke-ConsoleSimulation -KeyPresses 'DownArrow', 'Enter' { Read-ConsoleMenu -Items ([ordered]@{ a = 'Audit'; r = 'Repair' }) -Default a }
        $pick | Should -Be 'r'
    }

    It 'accepts the Keys name as well' {
        $pick = Invoke-ConsoleSimulation -Keys 'DownArrow', 'Enter' { Read-ConsoleMenu -Items ([ordered]@{ a = 'Audit'; r = 'Repair' }) -Default a }
        $pick | Should -Be 'r'
    }

    It 'takes typed answers in order, and Enter takes the default' {
        $values = Invoke-ConsoleSimulation -Answers '', 'yes' {
            Read-ConsoleConfirmation -Message 'Go on?' -Default $true
            Read-ConsoleConfirmation -Message 'Delete?'
        }
        $values -join '|' | Should -Be 'True|True'
    }

    It 'stops when the answers run out: a required input throws instead of waiting' {
        { Invoke-ConsoleSimulation { Read-ConsoleInput -Prompt 'Port' -Required } } | Should -Throw '*input ended*'
    }

    It 'ends the simulation afterwards, even when the script fails' {
        { Invoke-ConsoleSimulation -KeyPresses 'Enter' { throw 'boom' } } | Should -Throw 'boom'
        (& (Get-Module HermesConsoleUI) { $script:HermesSimulation }) | Should -BeNullOrEmpty
    }

    It 'without keys, lists the options and reads the typed choice' {
        $pick = Invoke-ConsoleSimulation -NonInteractive -Answers '2' { Read-ConsoleMenu -Items ([ordered]@{ '1' = 'Ver'; '2' = 'Aplicar' }) -Default '1' }
        $pick | Should -Be '2'
    }
}

Describe 'Read-ConsoleInput and the colon after the prompt' {
    AfterEach {
        Disable-ConsoleSimulation -Confirm:$false
        Unregister-ConsoleOutputHandler -Confirm:$false
    }

    It 'does not add a second colon to a prompt that ends in one' {
        Start-HandlerCapture
        $answer = Invoke-ConsoleSimulation -Answers 'ana' { Read-ConsoleInput -Prompt 'Name:' }
        $answer | Should -Be 'ana'
        $script:captured | Should -Be @('Name: ana')
    }

    It 'keeps a question mark, with no colon after it' {
        Start-HandlerCapture
        $null = Invoke-ConsoleSimulation -Answers 'si' { Read-ConsoleInput -Prompt 'Ready?' }
        $script:captured | Should -Be @('Ready? si')
    }

    It 'adds the colon to a prompt that has none, as before' {
        Start-HandlerCapture
        $null = Invoke-ConsoleSimulation -Answers 'ana' { Read-ConsoleInput -Prompt 'Name' }
        $script:captured | Should -Be @('Name: ana')
    }

    It '-NoColon writes only a space after the prompt' {
        Start-HandlerCapture
        $null = Invoke-ConsoleSimulation -Answers 'ana' { Read-ConsoleInput -Prompt 'Name' -NoColon }
        $script:captured | Should -Be @('Name ana')
    }
}

Describe 'Write-ConsoleLine and segments merged into one list' {
    It 'refuses a color name written as text right after another text segment' {
        { Write-ConsoleLine -Segments @('Compliant', 'Red', 'Rule', 'Green') -ReturnLines } | Should -Throw '*merged into one list*'
    }

    It 'accepts the safe forms: hashtables, or a comma in front of each array' {
        Write-ConsoleLine -Segments @(@{ Text = 'Red'; Color = 'Red' }, @{ Text = 'Green'; Color = 'Green' }) -Indent 0 -ReturnLines | Should -Be 'Red Green'
        $segments = @(, @('Compliant', 'Green'))
        $segments += , @('Red', 'Red')
        Write-ConsoleLine -Segments $segments -Indent 0 -ReturnLines | Should -Be 'Compliant Red'
    }

    It 'still writes a single text that is a color name' {
        Write-ConsoleLine -Segments @('Red') -Indent 0 -ReturnLines | Should -Be 'Red'
    }
}

Describe 'Write-ConsoleKeyValue and the label width' {
    BeforeEach { Set-ConsoleLayout -Reset -Confirm:$false }

    It 'keeps the label width asked for, while the line has room for it' {
        Mock -ModuleName HermesConsoleUI Get-ConsoleWidth { 101 }
        $label = 'L' * 51
        $line = @(Write-ConsoleKeyValue -Items ([ordered]@{ $label = 'value' }) -LabelWidth 51 -Indent 2 -ReturnLines)[0]
        $line.Substring(2, 51) | Should -BeExactly $label
        $line.Substring(55) | Should -BeExactly 'value'
    }

    It 'cuts a label that cannot fit, keeping 10 columns for the value' {
        Mock -ModuleName HermesConsoleUI Get-ConsoleWidth { 41 }
        $label = 'L' * 51
        $line = @(Write-ConsoleKeyValue -Items ([ordered]@{ $label = 'value' }) -LabelWidth 51 -Indent 2 -ReturnLines)[0]
        $line.Substring(2, 26) | Should -BeExactly (('L' * 25) + $script:ellipsis)
        $line.Substring(30) | Should -BeExactly 'value'
    }
}

Describe 'Format-ConsoleText with line breaks' {
    It 'cuts each line on its own and keeps the line breaks' {
        Format-ConsoleText -Text ("a`nbb`n" + ('c' * 9)) -Width 5 -KeepLineBreaks | Should -BeExactly ("a`nbb`ncccc" + $script:ellipsis)
    }

    It 'keeps at most -MaxLines lines and marks the rest with an ellipsis' {
        Format-ConsoleText -Text "a`nb`nc`nd" -Width 5 -KeepLineBreaks -MaxLines 2 | Should -BeExactly ("a`nb`n" + $script:ellipsis)
    }

    It 'still joins the lines when -KeepLineBreaks is not given' {
        Format-ConsoleText -Text "a`nb" -Width 5 | Should -BeExactly 'a b'
    }
}

Describe 'Write-ConsoleText with a prefix' {
    AfterEach { Unregister-ConsoleOutputHandler -Confirm:$false }

    It 'writes the prefix before the first line and aligns the wrapped lines under the text' {
        Start-HandlerCapture
        Write-ConsoleText -Plain -Wrap -Width 20 -Prefix 'high  ' -PrefixColor Red -Color Gray 'one two three four five'
        $script:captured | Should -Be @('high  one two three', '      four five')
    }

    It 'writes the prefix in its own color' {
        Start-HandlerCapture
        Write-ConsoleText -Plain -Prefix 'high  ' -PrefixColor Red -Color Gray 'one two'
        ($script:pieces | Where-Object Text -EQ 'high  ').Color | Should -Be 'Red'
        ($script:pieces | Where-Object Text -EQ 'one two').Color | Should -Be 'Gray'
    }

    It 'indents every line when the prefix is spaces' {
        Start-HandlerCapture
        Write-ConsoleText -Plain -Wrap -Width 20 -Prefix '    ' 'one two three four'
        $script:captured | Should -Be @('    one two three', '    four')
    }
}
