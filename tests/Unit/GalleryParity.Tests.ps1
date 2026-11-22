BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '..\..\HermesConsoleUI.psd1'
    Get-Module HermesConsoleUI | Remove-Module -Force
    Import-Module $manifestPath -Force

    function Start-HostCapture {
        $script:hostOutput = [System.Collections.Generic.List[object]]::new()
        Mock -ModuleName HermesConsoleUI Write-Host {
            $script:hostOutput.Add([pscustomobject]@{ Text = ($Object -join ' '); Color = "$ForegroundColor"; NoNewline = [bool]$NoNewline })
        }
    }

    # Drives Read-ConsoleSelection as if a console were attached, with these keys.
    function Use-Keys([string[]]$Keys) {
        $queue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new()
        foreach ($k in $Keys) { $queue.Enqueue([System.ConsoleKeyInfo]::new([char]0, [System.ConsoleKey]$k, $false, $false, $false)) }
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
    }
    Get-Module HermesConsoleUI | Remove-Module -Force
}

Describe 'Read-ConsoleSelection with the arrow keys' {
    BeforeEach { Start-HostCapture }

    It 'returns the option chosen with Down and Enter' {
        Use-Keys 'DownArrow', 'DownArrow', 'Enter'
        Read-ConsoleSelection -Options 'Dev', 'Staging', 'Prod' | Should -Be 'Prod'
    }

    It 'wraps around from the first option to the last' {
        Use-Keys 'UpArrow', 'Enter'
        Read-ConsoleSelection -Options 'Dev', 'Staging', 'Prod' | Should -Be 'Prod'
    }

    It 'starts at -Default and returns the index with -ReturnIndex' {
        Use-Keys 'Enter'
        Read-ConsoleSelection -Options 'a', 'b', 'c' -Default 1 -ReturnIndex | Should -Be 1
    }

    It 'returns $null when cancelled with Escape' {
        Use-Keys 'DownArrow', 'Escape'
        Read-ConsoleSelection -Options 'a', 'b' | Should -BeNullOrEmpty
    }

    It 'marks several options with Space and returns them as an array' {
        Use-Keys 'Spacebar', 'DownArrow', 'DownArrow', 'Spacebar', 'Enter'
        $result = Read-ConsoleSelection -Options 'a', 'b', 'c' -Multiple
        , $result | Should -BeOfType [object[]]
        $result | Should -Be @('a', 'c')
    }

    It 'returns a one-item array with -Multiple' {
        Use-Keys 'Enter'
        $result = Read-ConsoleSelection -Options 'a', 'b' -Multiple
        $result.GetType().IsArray | Should -BeTrue
        $result | Should -Be @('a')
    }

    It 'marks and unmarks everything with A' {
        Use-Keys 'A', 'Enter'
        $result = Read-ConsoleSelection -Options 'a', 'b', 'c' -Multiple -ReturnIndex
        $result | Should -Be @(0, 1, 2)
    }

    It 'shows objects with -DisplayProperty and returns the objects' {
        $items = @([pscustomobject]@{ Name = 'one'; Id = 1 }, [pscustomobject]@{ Name = 'two'; Id = 2 })
        Use-Keys 'End', 'Enter'
        (Read-ConsoleSelection -Options $items -DisplayProperty Name).Id | Should -Be 2
        ($script:hostOutput.Text -join "`n") | Should -Match 'two'
    }

    It 'scrolls long lists and shows the position' {
        Use-Keys 'PageDown', 'PageDown', 'Enter'
        Read-ConsoleSelection -Options (1..20 | ForEach-Object { "item $_" }) -PageSize 5 | Should -Be 'item 11'
        ($script:hostOutput.Text -join "`n") | Should -Match '\(11/20\)'
    }

    It 'removes escape sequences from the options it shows' {
        Use-Keys 'Enter'
        $null = Read-ConsoleSelection -Options "evil$([char]27)[2Jname"
        ($script:hostOutput.Text -join '') | Should -Not -Match ([char]27)
    }
}

Describe 'Read-ConsoleSelection without an interactive console' {
    BeforeEach {
        Start-HostCapture
        InModuleScope HermesConsoleUI { $script:HermesInteractiveOverride = $false }
    }

    It 'falls back to a numbered list' {
        Mock -ModuleName HermesConsoleUI Read-Host { '2' }
        Read-ConsoleSelection -Options 'Dev', 'Staging' | Should -Be 'Staging'
    }

    It 'returns $null when the user chooses 0' {
        Mock -ModuleName HermesConsoleUI Read-Host { '0' }
        Read-ConsoleSelection -Options 'Dev', 'Staging' | Should -BeNullOrEmpty
    }

    It 'reads several numbers with -Multiple' {
        Mock -ModuleName HermesConsoleUI Read-Host { '2,1' }
        $result = Read-ConsoleSelection -Options 'a', 'b', 'c' -Multiple -ReturnIndex
        $result | Should -Be @(1, 0)
    }
}

Describe 'Write-ConsoleTable sizes columns automatically' {
    BeforeEach { Start-HostCapture }

    It 'makes each column as wide as its longest value' {
        [pscustomobject]@{ Name = 'a-rather-long-service-name'; Status = 'Running' } | Write-ConsoleTable
        $row = ($script:hostOutput | Where-Object Text -Match 'a-rather-long').Text
        $row | Should -Match 'a-rather-long-service-name Running'
    }

    It 'aligns numeric columns to the right' {
        @([pscustomobject]@{ Name = 'a'; Size = 5 }, [pscustomobject]@{ Name = 'b'; Size = 12345 }) | Write-ConsoleTable
        ($script:hostOutput | Where-Object Text -Match '^\s+a\s').Text.TrimEnd() | Should -Match '\s{4}5$'
    }

    It 'writes a line under the header' {
        [pscustomobject]@{ Name = 'x' } | Write-ConsoleTable
        $script:hostOutput.Text | Should -Contain '  ----'
    }

    It 'keeps an explicit Width and Align' {
        [pscustomobject]@{ N = 7 } | Write-ConsoleTable -Columns @{ Header = 'N'; Property = 'N'; Width = 6; Align = 'Left' }
        ($script:hostOutput | Where-Object Text -Match '7').Text | Should -BeExactly '  7     '
    }

    It 'narrows automatic columns to fit the console window' {
        Mock -ModuleName HermesConsoleUI Get-ConsoleWidth { 40 }
        [pscustomobject]@{ A = 'x' * 60; B = 'y' * 60 } | Write-ConsoleTable
        foreach ($line in $script:hostOutput.Text | Where-Object { $_ }) { $line.TrimEnd().Length | Should -BeLessOrEqual 40 }
    }
}

Describe 'Read-ConsoleInput validation' {
    BeforeEach { Start-HostCapture }

    It 'asks again until -Validate accepts the answer' {
        $script:answers = [System.Collections.Generic.Queue[string]]::new([string[]]@('abc', '70000', '8080'))
        Mock -ModuleName HermesConsoleUI Read-Host { $script:answers.Dequeue() }
        Read-ConsoleInput -Prompt 'Port' -Validate { [int]::TryParse($_, [ref]$null) -and [int]$_ -le 65535 } -ErrorMessage 'bad port' | Should -Be '8080'
        @($script:hostOutput | Where-Object Text -Match 'bad port').Count | Should -Be 2
    }

    It 'matches -Pattern against the whole answer' {
        $script:answers = [System.Collections.Generic.Queue[string]]::new([string[]]@('12a', '12'))
        Mock -ModuleName HermesConsoleUI Read-Host { $script:answers.Dequeue() }
        Read-ConsoleInput -Pattern '\d+' | Should -Be '12'
    }

    It 'refuses an empty answer with -Required' {
        $script:answers = [System.Collections.Generic.Queue[string]]::new([string[]]@('', 'x'))
        Mock -ModuleName HermesConsoleUI Read-Host { $script:answers.Dequeue() }
        Read-ConsoleInput -Required | Should -Be 'x'
    }

    It 'still returns the default when the user presses Enter' {
        Mock -ModuleName HermesConsoleUI Read-Host { '' }
        Read-ConsoleInput -DefaultValue '8080' -Pattern '\d+' | Should -Be '8080'
    }
}

Describe 'Write-ConsoleText color marks' {
    BeforeEach { Start-HostCapture }

    It 'writes each marked part in its color' {
        Write-ConsoleText 'a {Red}b{/} c'
        $parts = @($script:hostOutput | Where-Object Text)
        ($parts | ForEach-Object Text) -join '' | Should -BeExactly 'a b c'
        ($parts | Where-Object Text -EQ 'b').Color | Should -Be 'Red'
        ($parts | Where-Object Text -EQ ' c').Color | Should -BeNullOrEmpty
    }

    It 'accepts theme roles' {
        Write-ConsoleText '{Success}ok{/}'
        ($script:hostOutput | Where-Object Text -EQ 'ok').Color | Should -Be (Get-UIColor -ColorType Success)
    }

    It 'writes {{ and unknown marks as text' {
        Write-ConsoleText '{{x} and {Nope}'
        (($script:hostOutput | ForEach-Object Text) -join '') | Should -BeExactly '{x} and {Nope}'
    }
}

Describe 'NO_COLOR' {
    BeforeEach { Start-HostCapture; $script:savedNoColor = $env:NO_COLOR }
    AfterEach { $env:NO_COLOR = $script:savedNoColor }

    It 'drops colors when NO_COLOR is set' {
        $env:NO_COLOR = '1'
        Write-ConsoleStatus -Message 'done' -Type Success
        Write-ConsoleText '{Red}x{/}'
        @($script:hostOutput | Where-Object Color).Count | Should -Be 0
    }

    It 'keeps colors when NO_COLOR is empty' {
        $env:NO_COLOR = ''
        Write-ConsoleText '{Red}x{/}'
        ($script:hostOutput | Where-Object Text -EQ 'x').Color | Should -Be 'Red'
    }
}

Describe 'Register-ConsoleOutputHandler' {
    AfterEach { Unregister-ConsoleOutputHandler }

    It 'passes every write to the handler, with the text cleaned and the color' {
        Start-HostCapture
        $script:copies = [System.Collections.Generic.List[object]]::new()
        Register-ConsoleOutputHandler { param($Text, $NoNewline, $Color) $script:copies.Add([pscustomobject]@{ Text = $Text; NoNewline = $NoNewline; Color = $Color }) }
        Write-ConsoleText "a {Red}b$([char]27)[2J{/}"
        ($script:copies | ForEach-Object Text) -join '' | Should -BeExactly 'a b'
        ($script:copies | Where-Object Text -EQ 'b').Color | Should -Be 'Red'
        $script:copies[-1].NoNewline | Should -BeFalse
        @($script:hostOutput).Count | Should -BeGreaterThan 0
    }

    It 'writes nothing on screen with -Quiet' {
        Start-HostCapture
        $script:copies = [System.Collections.Generic.List[string]]::new()
        Register-ConsoleOutputHandler -Quiet { param($Text) $script:copies.Add($Text) }
        Write-ConsoleStatus -Message 'saved' -Type Success
        @($script:hostOutput).Count | Should -Be 0
        ($script:copies -join '') | Should -Match 'saved'
    }

    It 'ignores a handler that fails' {
        Start-HostCapture
        Register-ConsoleOutputHandler { throw 'broken' }
        { Write-ConsoleInfo -Message 'still works' } | Should -Not -Throw
    }

    It 'stops after Unregister-ConsoleOutputHandler' {
        Start-HostCapture
        $script:copies = [System.Collections.Generic.List[string]]::new()
        Register-ConsoleOutputHandler { param($Text) $script:copies.Add($Text) }
        Unregister-ConsoleOutputHandler
        Write-ConsoleInfo -Message 'x'
        $script:copies.Count | Should -Be 0
    }
}
