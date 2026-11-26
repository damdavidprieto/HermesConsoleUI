# Lines made of segments, named styles, layout settings, key-value lists, grids, captures to a file,
# waiting for Enter and Write-Host through the module (2.8.0).

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
    InModuleScope HermesConsoleUI {
        $script:HermesTrueColorOverride = $null
        $script:HermesInteractiveOverride = $null
        $script:HermesLiveOverride = $null
        $script:HermesStyles = @{}
    }
    Stop-ConsoleCapture -Confirm:$false
    Set-ConsoleLayout -Reset -Confirm:$false
    Unregister-ConsoleOutputHandler -Confirm:$false
    Get-Module HermesConsoleUI | Remove-Module -Force
    $env:NO_COLOR = $script:savedNoColorAll
}

Describe 'Line components' {
BeforeEach {
    # 60 columns whether the console width is known (capped) or not (the default width).
    Set-ConsoleLayout -Reset -MaxWidth 60 -DefaultWidth 60 -Confirm:$false
}

Describe 'Set-ConsoleLayout and Get-ConsoleLayout' {
    It 'sets only the values given and goes back to the defaults with -Reset' {
        Set-ConsoleLayout -Margin 4 -Confirm:$false
        $layout = Get-ConsoleLayout
        $layout.Margin | Should -Be 4
        $layout.MaxWidth | Should -Be 60
        $layout.LineWidth | Should -Be 60
        Set-ConsoleLayout -Reset -Confirm:$false
        (Get-ConsoleLayout).Margin | Should -Be 2
        (Get-ConsoleLayout).MaxWidth | Should -Be 0
    }

    It 'caps Get-ConsoleWidth, and an explicit -Maximum still wins' {
        InModuleScope HermesConsoleUI {
            Mock Get-ConsoleWidth -ParameterFilter { $Maximum -eq 0 -and $Default -eq 0 } { 200 }
            Get-HermesLineWidth | Should -Be 60
        }
        Get-ConsoleWidth | Should -BeLessOrEqual 60
        Get-ConsoleWidth -Maximum 0 -Default 33 | Should -BeGreaterThan 0
    }

    It 'uses one column less than the window when it is narrower than the maximum' {
        InModuleScope HermesConsoleUI {
            Mock Get-ConsoleWidth -ParameterFilter { $Maximum -eq 0 -and $Default -eq 0 } { 50 }
            Get-HermesLineWidth | Should -Be 49
            Mock Get-ConsoleWidth -ParameterFilter { $Maximum -eq 0 -and $Default -eq 0 } { 0 }
            Get-HermesLineWidth | Should -Be 60
        }
    }

    It 'makes wrapped text follow the layout width' {
        $lines = Write-ConsoleLine @{ Text = ('word ' * 30).Trim(); Fill = 'Wrap' } -ReturnLines
        foreach ($line in $lines) { $line.Length | Should -BeLessOrEqual 60 }
        $lines.Count | Should -BeGreaterThan 1
    }
}

Describe 'Register-ConsoleStyle and Get-ConsoleStyle' {
    BeforeAll {
        Register-ConsoleStyle State -Map ([ordered]@{ Compliant = 'OK', 'Green'; NonCompliant = @{ Text = 'Pending'; Color = 'Error' }; Manual = 'By hand' }) -Default 'No data', 'DarkYellow' -Confirm:$false
        Register-ConsoleStyle Percent -Thresholds @{ 0 = 'Red'; 70 = 'Yellow'; 100 = 'Green' } -Format '{0} %' -Confirm:$false
    }

    It 'gives each value its text and color, ignoring case' {
        $ok = Get-ConsoleStyle State 'compliant'
        $ok.Text | Should -Be 'OK'
        $ok.Color | Should -Be 'Green'
        (Get-ConsoleStyle State NonCompliant).Color | Should -Be (Get-UIColor -ColorType Error)
        (Get-ConsoleStyle State Manual).Color | Should -BeNullOrEmpty
    }

    It 'uses the default for other values' {
        $other = Get-ConsoleStyle State 'Strange'
        $other.Text | Should -Be 'No data'
        $other.Color | Should -Be 'DarkYellow'
    }

    It 'colors numbers by the highest threshold reached' {
        (Get-ConsoleStyle Percent 69).Color | Should -Be 'Red'
        (Get-ConsoleStyle Percent 70).Color | Should -Be 'Yellow'
        (Get-ConsoleStyle Percent 100).Text | Should -Be '100 %'
        (Get-ConsoleStyle Percent 100).Color | Should -Be 'Green'
    }

    It 'lists and describes the styles' {
        Get-ConsoleStyle | Should -Contain 'State'
        $state = Get-ConsoleStyle State
        $state.Width | Should -Be 7
        $state.Values | Should -Contain 'Manual'
    }

    It 'refuses unknown styles, colors and thresholds' {
        { Get-ConsoleStyle Missing } | Should -Throw '*not registered*'
        { Register-ConsoleStyle Bad -Map @{ a = 'A', 'Purpleish' } -Confirm:$false } | Should -Throw '*not a console color*'
        { Register-ConsoleStyle Bad -Thresholds @{ high = 'Red' } -Confirm:$false } | Should -Throw '*not a number*'
    }

    It 'removes a style' {
        Register-ConsoleStyle Temp -Map @{ a = 'A' } -Confirm:$false
        Unregister-ConsoleStyle Temp -Confirm:$false
        Get-ConsoleStyle | Should -Not -Contain 'Temp'
    }
}

Describe 'Write-ConsoleLine' {
    BeforeAll {
        Register-ConsoleStyle State -Map ([ordered]@{ Compliant = 'OK', 'Green'; NonCompliant = 'Pending', 'Red' }) -Default 'No data', 'DarkYellow' -Confirm:$false
        Register-ConsoleStyle Percent -Thresholds @{ 0 = 'Red'; 70 = 'Yellow' } -Confirm:$false
    }
    AfterEach { Unregister-ConsoleOutputHandler -Confirm:$false }

    It 'pads styled values to the widest text of the style, so states line up' {
        $a = Write-ConsoleLine @{ Value = 'Compliant'; Style = 'State' }, 'rule' -ReturnLines
        $b = Write-ConsoleLine @{ Value = 'NonCompliant'; Style = 'State' }, 'rule' -ReturnLines
        $a | Should -BeExactly '  OK      rule'
        $b | Should -BeExactly '  Pending rule'
    }

    It 'cuts or pads fixed widths and aligns right' {
        Write-ConsoleLine @{ Text = 'ABCDEFGHIJ'; Width = 6 }, @{ Text = '7'; Width = 3; Align = 'Right' }, 'end' -ReturnLines |
            Should -BeExactly ('  ABCDE' + $script:ellipsis + '   7 end')
    }

    It 'accepts arrays and strings as segments and skips $null' {
        Write-ConsoleLine @(@('id', 'DarkCyan', 4), $null, 'text') -Indent 0 -ReturnLines | Should -BeExactly 'id   text'
    }

    It 'fills the rest of the line, cut with an ellipsis, before the segments after it' {
        $line = Write-ConsoleLine @{ Text = 'x' * 100; Fill = 'Cut' }, @{ Text = 'high risk'; Gap = 2 } -ReturnLines
        $line.Length | Should -Be 60
        $line | Should -Match ([regex]::Escape($script:ellipsis + '  high risk') + '$')
    }

    It 'does not pad a filling segment that fits' {
        Write-ConsoleLine 'a', @{ Text = 'short'; Fill = 'Cut' }, 'b' -ReturnLines | Should -BeExactly '  a short b'
    }

    It 'wraps a filling segment with the following lines aligned under its start' {
        $lines = @(Write-ConsoleLine @{ Text = 'high'; Width = 8 }, @{ Text = ('alert ' * 15).Trim(); Fill = 'Wrap' } -ReturnLines)
        $lines.Count | Should -BeGreaterThan 1
        $lines[0] | Should -Match '^  high     alert'
        $lines[1] | Should -Match '^ {11}alert'
        foreach ($line in $lines) { $line.Length | Should -BeLessOrEqual 60 }
    }

    It 'keeps line breaks of a wrapped segment' {
        $lines = @(Write-ConsoleLine @{ Text = 'Note'; Width = 6 }, @{ Text = "one`ntwo"; Fill = 'Wrap' } -ReturnLines)
        $lines | Should -Be @('  Note   one', '         two')
    }

    It 'draws a bar colored by a style or a color' {
        Start-HandlerCapture
        Write-ConsoleLine @{ Bar = 75; Width = 8; Style = 'Percent' }, @{ Bar = 10; Width = 4; Color = 'Cyan'; Empty = 'Gray' }
        $script:captured[0] | Should -BeExactly ('  ' + ([string][char]0x2588 * 6) + ([string][char]0x2591 * 2) + ' ' + ([string][char]0x2591 * 4))
        ($script:pieces | Where-Object Text -Match ([char]0x2588)).Color | Should -Be 'Yellow'
        ($script:pieces | Where-Object Text -EQ ([string][char]0x2591 * 4)).Color | Should -Be 'Gray'
    }

    It 'passes each piece with its color, and theme roles resolved, to the handler' {
        Start-HandlerCapture
        Write-ConsoleLine @{ Value = 'NonCompliant'; Style = 'State' }, @{ Text = 'title'; Color = 'Muted' }
        $script:captured | Should -Be @('  Pending title')
        ($script:pieces | Where-Object Text -EQ 'Pending').Color | Should -Be 'Red'
        ($script:pieces | Where-Object Text -EQ 'title').Color | Should -Be (Get-UIColor -ColorType Muted)
    }

    It 'removes control sequences and line breaks from the text' {
        Write-ConsoleLine "a$([char]27)[31mb`nc" -ReturnLines | Should -BeExactly '  ab c'
    }

    It 'refuses a wrong Fill, Align or color' {
        { Write-ConsoleLine @{ Text = 'a'; Fill = 'Stretch' } -ReturnLines } | Should -Throw '*Fill*'
        { Write-ConsoleLine @{ Text = 'a'; Align = 'Center'; Width = 4 } -ReturnLines } | Should -Throw '*Align*'
        { Write-ConsoleLine @{ Text = 'a'; Color = 'NoSuchColor' } -ReturnLines } | Should -Throw '*not a console color*'
    }

    It 'writes the whole line in one call with color sequences where the console supports them' {
        InModuleScope HermesConsoleUI {
            $script:HermesTrueColorOverride = $true
            $script:calls = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $script:calls.Add(($Object -join ' ')) }
            try { Write-ConsoleLine @{ Text = 'ok'; Color = 'Green' }, @{ Text = 'hex'; Color = '#FF8800' }, 'plain' -Indent 0 }
            finally { $script:HermesTrueColorOverride = $null }
            $esc = [char]27
            $script:calls.Count | Should -Be 1
            $script:calls[0] | Should -BeExactly "$esc[92mok$esc[39m $esc[38;2;255;136;0mhex$esc[39m plain"
        }
    }

    It 'writes one plain call when NO_COLOR is set' {
        InModuleScope HermesConsoleUI {
            $script:calls = [System.Collections.Generic.List[object]]::new()
            Mock Write-Host { $script:calls.Add([pscustomobject]@{ Text = ($Object -join ' '); Color = "$ForegroundColor" }) }
            $env:NO_COLOR = '1'
            try { Write-ConsoleLine @{ Text = 'ok'; Color = 'Green' }, 'plain' -Indent 0 }
            finally { $env:NO_COLOR = $null }
            $script:calls.Count | Should -Be 1
            $script:calls[0].Text | Should -BeExactly 'ok plain'
            $script:calls[0].Color | Should -BeNullOrEmpty
        }
    }

    It 'writes one piece at a time, with console colors, where sequences are not supported' {
        InModuleScope HermesConsoleUI {
            $script:HermesTrueColorOverride = $false
            $script:calls = [System.Collections.Generic.List[object]]::new()
            Mock Write-Host { $script:calls.Add([pscustomobject]@{ Text = ($Object -join ' '); Color = "$ForegroundColor" }) }
            try { Write-ConsoleLine @{ Text = 'ok'; Color = 'Green' }, @{ Text = 'hex'; Color = '#FF0000' } -Indent 0 }
            finally { $script:HermesTrueColorOverride = $null }
            ($script:calls | Where-Object Text -EQ 'ok').Color | Should -Be 'Green'
            ($script:calls | Where-Object Text -EQ 'hex').Color | Should -Be 'Red'
        }
    }
}

Describe 'Write-ConsoleKeyValue' {
    BeforeAll {
        Register-ConsoleStyle State -Map @{ NonCompliant = 'Pending', 'Red' } -Confirm:$false
        Register-ConsoleStyle Severity -Map @{ high = 'high', 'Red'; low = 'low', 'Gray' } -Confirm:$false
    }
    AfterEach { Unregister-ConsoleOutputHandler -Confirm:$false }

    It 'aligns the values after the longest label and wraps them under themselves' {
        $lines = @(Write-ConsoleKeyValue ([ordered]@{ Id = 'R1'; Reason = ('long ' * 20).Trim() }) -ReturnLines)
        $lines[0] | Should -BeExactly '  Id      R1'
        $lines[1] | Should -Match '^  Reason  long'
        $lines[2] | Should -Match '^ {10}long'
    }

    It 'cuts long values with -Cut' {
        $lines = @(Write-ConsoleKeyValue ([ordered]@{ Reason = 'x' * 100 }) -Cut -ReturnLines)
        $lines.Count | Should -Be 1
        $lines[0].Length | Should -Be 60
        $lines[0] | Should -Match "$([regex]::Escape($script:ellipsis))$"
    }

    It 'takes values with a color or a style' {
        Start-HandlerCapture
        Write-ConsoleKeyValue ([ordered]@{ State = @{ Value = 'NonCompliant'; Style = 'State' }; Note = @('careful', 'Yellow') }) -LabelColor White
        $script:captured | Should -Be @('  State  Pending', '  Note   careful')
        ($script:pieces | Where-Object Text -EQ 'Pending').Color | Should -Be 'Red'
        ($script:pieces | Where-Object Text -EQ 'careful').Color | Should -Be 'Yellow'
        ($script:pieces | Where-Object Text -Match '^State').Color | Should -Be 'White'
    }

    It 'takes a list with repeated labels colored by a style' {
        Start-HandlerCapture
        Write-ConsoleKeyValue -LabelStyle Severity -Indent 4 @(@('high', 'First'), @('low', 'Second'), @('high', 'Third'))
        $script:captured | Should -Be @('    high  First', '    low   Second', '    high  Third')
        @($script:pieces | Where-Object Text -Match '^high' | ForEach-Object Color) | Should -Be @('Red', 'Red')
    }

    It 'takes a list of hashtables with Label and Value' {
        Write-ConsoleKeyValue -Indent 0 -Gap 1 @(@{ Label = 'A'; Value = 'one' }, [pscustomobject]@{ Label = 'BB'; Value = 'two'; LabelColor = 'Cyan' }) -ReturnLines |
            Should -Be @('A  one', 'BB two')
    }
}

Describe 'Write-ConsoleGrid' {
    It 'puts as many items on a line as fit' {
        $lines = @(Write-ConsoleGrid -ColumnWidth 15 -Gap 3 -ReturnLines @('one', 'two', 'three', 'four'))
        # (60 - 2 + 3) / (15 + 3) = 3 items per line.
        $lines.Count | Should -Be 2
        $lines[0] | Should -BeExactly ('  one' + (' ' * 15) + 'two' + (' ' * 15) + 'three')
        $lines[1] | Should -BeExactly '  four'
    }

    It 'takes a fixed number of columns, segments, and cuts what does not fit' {
        $lines = @(Write-ConsoleGrid -ColumnWidth 10 -Columns 1 -Indent 0 -ReturnLines @(
                , @(@{ Text = 'Area'; Width = 6 }, @{ Text = '3/4'; Color = 'Yellow' })
                'a long text that does not fit'
            ))
        $lines | Should -Be @('Area   3/4', ('a long te' + $script:ellipsis))
    }

    It 'writes nothing for no items' {
        Write-ConsoleGrid -ColumnWidth 10 -ReturnLines @() | Should -BeNullOrEmpty
    }
}

Describe 'Styles in tables and charts' {
    BeforeAll {
        Register-ConsoleStyle State -Map @{ Compliant = 'OK', 'Green'; NonCompliant = 'Pending', 'Red' } -Confirm:$false
        Register-ConsoleStyle Percent -Thresholds @{ 0 = 'Red'; 70 = 'Yellow' } -Format '{0} %' -Confirm:$false
    }
    AfterEach { Unregister-ConsoleOutputHandler -Confirm:$false }

    It 'shows a table column through a style, words and colors' {
        Start-HandlerCapture
        $data = @([pscustomobject]@{ Id = 'A'; State = 'Compliant'; Pct = 40 }, [pscustomobject]@{ Id = 'B'; State = 'NonCompliant'; Pct = 90 })
        Write-ConsoleTable -Data $data -Columns @(@{ Header = 'Id'; Property = 'Id' }, @{ Header = 'State'; Property = 'State'; Style = 'State' }, @{ Header = 'Pct'; Property = 'Pct'; Style = 'Percent' })
        ($script:captured | Where-Object { $_ -match 'Pending' }) | Should -Match 'B +Pending +90 %'
        ($script:pieces | Where-Object Text -Match '^Pending').Color | Should -Be 'Red'
        ($script:pieces | Where-Object Text -Match '40 %').Color | Should -Be 'Red'
        ($script:pieces | Where-Object Text -Match '90 %').Color | Should -Be 'Yellow'
    }

    It 'colors a chart bar through a style' {
        Start-HandlerCapture
        Write-ConsoleChart -Label 'Level' -Value 80 -Style Percent
        ($script:pieces | Where-Object Text -Match ([char]0x2588)).Color | Should -Be 'Yellow'
    }
}

Describe 'Titles, headers and rules' {
    AfterEach { Unregister-ConsoleOutputHandler -Confirm:$false }

    It 'writes a left-aligned title with a wrapped subtitle and a rule across the line' {
        Start-HandlerCapture
        Write-ConsoleTitle -Title 'Audit' -Subtitle (('checks every rule ' * 5).Trim()) -Align Left
        $script:captured[0] | Should -BeExactly ''
        $script:captured[1] | Should -BeExactly '  Audit'
        $script:captured[2] | Should -Match '^  checks'
        $script:captured[3] | Should -Match '^  \S'
        $script:captured[-1] | Should -BeExactly ([string][char]0x2500 * 60)
    }

    It 'adds a centered subtitle to the classic title' {
        Start-HandlerCapture
        Write-ConsoleTitle -Title 'Report' -Subtitle 'today'
        $script:captured[3].Trim() | Should -BeExactly 'today'
        $script:captured[4] | Should -Match '^=+$'
    }

    It 'writes a compact header with a note' {
        Start-HandlerCapture
        Write-ConsoleHeader -Text 'Firewall' -Note '4 of 6' -Compact
        $script:captured | Should -Be @('', '  Firewall   4 of 6')
        Write-ConsoleHeader -Text 'Classic'
        $script:captured[-2] | Should -BeExactly '>>> Classic'
        $script:captured[-1] | Should -BeExactly ''
    }

    It 'draws a rule across the line with -Length 0' {
        Start-HandlerCapture
        Write-ConsoleSeparator -Character '-' -Length 0 -Indent 0
        Write-ConsoleSeparator -Character '=' -Length 0
        $script:captured | Should -Be @(('-' * 60), ('  ' + '=' * 58))
    }
}

Describe 'Start-ConsoleCapture and Stop-ConsoleCapture' {
    BeforeEach { $script:file = Join-Path $TestDrive ("capture-{0}.txt" -f [guid]::NewGuid().ToString('N')) }
    AfterEach {
        Stop-ConsoleCapture -Confirm:$false
        Unregister-ConsoleOutputHandler -Confirm:$false
    }

    It 'writes every complete line, with the colored pieces joined, as soon as it ends' {
        Register-ConsoleOutputHandler -Quiet -Confirm:$false { param($Text) $null = $Text }
        Start-ConsoleCapture -Path $script:file -Confirm:$false
        Write-ConsoleText 'one {Red}two{/} three'
        Get-Content -LiteralPath $script:file | Should -Be @('one two three')
        Write-ConsoleLine 'a', @{ Text = 'b'; Color = 'Green' }
        Write-ConsoleText 'unfinished' -NoNewline
        Get-Content -LiteralPath $script:file | Should -Be @('one two three', '  a b')
        Stop-ConsoleCapture -Confirm:$false
        Get-Content -LiteralPath $script:file | Should -Be @('one two three', '  a b', 'unfinished')
    }

    It 'writes UTF-8 without a byte order mark, and appends with -Append' {
        Register-ConsoleOutputHandler -Quiet -Confirm:$false { param($Text) $null = $Text }
        Start-ConsoleCapture -Path $script:file -Confirm:$false
        Write-ConsoleText -Plain 'Configuración'
        Stop-ConsoleCapture -Confirm:$false
        Start-ConsoleCapture -Path $script:file -Append -Confirm:$false
        Write-ConsoleText -Plain 'more'
        Stop-ConsoleCapture -Confirm:$false
        $bytes = [System.IO.File]::ReadAllBytes($script:file)
        $bytes[0] | Should -Not -Be 0xEF
        [System.IO.File]::ReadAllText($script:file, [System.Text.Encoding]::UTF8) | Should -BeExactly "Configuración`nmore`n"
    }

    It 'keeps working alongside an output handler' {
        Start-HandlerCapture
        Start-ConsoleCapture -Path $script:file -Confirm:$false
        Write-ConsoleText 'both'
        $script:captured | Should -Be @('both')
        Get-Content -LiteralPath $script:file | Should -Be @('both')
    }

    It 'keeps the questions with their answers' {
        Register-ConsoleOutputHandler -Quiet -Confirm:$false { param($Text) $null = $Text }
        Mock -ModuleName HermesConsoleUI Read-Host { 'y' }
        Start-ConsoleCapture -Path $script:file -Confirm:$false
        $null = Read-ConsoleConfirmation -Message 'Apply' -Default $false
        Stop-ConsoleCapture -Confirm:$false
        (Get-Content -LiteralPath $script:file) -join "`n" | Should -Match 'Apply.*y'
    }

    It 'turns off arrow-key prompts, status lines and clearing the screen while capturing' {
        InModuleScope HermesConsoleUI -Parameters @{ File = $script:file } {
            param($File)
            $script:HermesInteractiveOverride = $true
            $script:HermesLiveOverride = $true
            try {
                Start-ConsoleCapture -Path $File -Confirm:$false
                Test-InteractiveConsole | Should -BeFalse
                Test-HermesLiveOutput | Should -BeFalse
                Stop-ConsoleCapture -Confirm:$false
                Test-InteractiveConsole | Should -BeTrue
                Test-HermesLiveOutput | Should -BeTrue
            }
            finally { $script:HermesInteractiveOverride = $null; $script:HermesLiveOverride = $null }
        }
    }

    It 'lists the options and reads the typed key of a menu while capturing' {
        Register-ConsoleOutputHandler -Quiet -Confirm:$false { param($Text) $null = $Text }
        Mock -ModuleName HermesConsoleUI Read-Host { 'b' }
        InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $true }
        try {
            Start-ConsoleCapture -Path $script:file -Confirm:$false
            $key = Read-ConsoleMenu -Items ([ordered]@{ a = 'Audit'; b = 'Backup' })
            Stop-ConsoleCapture -Confirm:$false
        }
        finally { InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $null } }
        $key | Should -Be 'b'
        $text = (Get-Content -LiteralPath $script:file) -join "`n"
        $text | Should -Match 'Audit'
        $text | Should -Match 'Backup'
    }

    It 'replaces a running capture and ignores Stop without one' {
        $second = Join-Path $TestDrive 'second.txt'
        Register-ConsoleOutputHandler -Quiet -Confirm:$false { param($Text) $null = $Text }
        Start-ConsoleCapture -Path $script:file -Confirm:$false
        Write-ConsoleText 'first' -NoNewline
        Start-ConsoleCapture -Path $second -Confirm:$false
        Write-ConsoleText 'second'
        Stop-ConsoleCapture -Confirm:$false
        { Stop-ConsoleCapture -Confirm:$false } | Should -Not -Throw
        Get-Content -LiteralPath $script:file | Should -Be @('first')
        Get-Content -LiteralPath $second | Should -Be @('second')
    }

    It 'does not break the interface when the file cannot be written' {
        Register-ConsoleOutputHandler -Quiet -Confirm:$false { param($Text) $null = $Text }
        Start-ConsoleCapture -Path $script:file -Confirm:$false
        Remove-Item -LiteralPath $script:file
        $null = New-Item -ItemType Directory -Path $script:file
        { Write-ConsoleText 'lost' } | Should -Not -Throw
    }
}

Describe 'Wait-ConsoleKey' {
    AfterEach { Unregister-ConsoleOutputHandler -Confirm:$false }

    It 'writes the message at the margin and waits for Enter, as one captured line' {
        Start-HandlerCapture
        Mock -ModuleName HermesConsoleUI Read-Host { '' }
        Wait-ConsoleKey -Message 'Back to the menu'
        Should -Invoke -ModuleName HermesConsoleUI Read-Host -Times 1 -Exactly
        $script:captured | Should -Be @('', '  Back to the menu ')
    }

    It 'uses the localized message by default and returns when input runs out' {
        Start-HandlerCapture
        Mock -ModuleName HermesConsoleUI Read-Host { $null }
        { Wait-ConsoleKey } | Should -Not -Throw
        $script:captured[1].Trim() | Should -BeExactly (Get-LocalizedString -Key 'Menu.PressEnter')
    }
}

Describe 'Enable-ConsoleHostRedirect' {
    AfterEach {
        Unregister-ConsoleOutputHandler -Confirm:$false
        Get-Module HermesRedirectTest | Remove-Module -Force
    }

    It 'sends Write-Host in the calling module through the module, and only there' {
        Start-HandlerCapture
        $null = New-Module -Name HermesRedirectTest -ScriptBlock {
            HermesConsoleUI\Enable-ConsoleHostRedirect -Confirm:$false
            function Invoke-RedirectTest { Write-Host "safe$([char]27)[31mtext" -ForegroundColor Cyan; Write-Host 'a', 'b' -Separator '-' -NoNewline; Write-Host '' }
            function Disable-RedirectTest { HermesConsoleUI\Disable-ConsoleHostRedirect -Confirm:$false }
            function Get-RedirectTestCommand { (Get-Command Write-Host).CommandType }
            Export-ModuleMember -Function Invoke-RedirectTest, Disable-RedirectTest, Get-RedirectTestCommand
        } | Import-Module -PassThru
        Invoke-RedirectTest
        $script:captured | Should -Be @('safetext', 'a-b')
        ($script:pieces | Where-Object Text -EQ 'safetext').Color | Should -Be 'Cyan'
        Get-RedirectTestCommand | Should -Be 'Function'
        (Get-Command Write-Host).CommandType | Should -Be 'Cmdlet'
        Disable-RedirectTest
        Get-RedirectTestCommand | Should -Be 'Cmdlet'
    }
}
}
