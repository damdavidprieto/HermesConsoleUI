BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '..\..\HermesConsoleUI.psd1'
    Get-Module HermesConsoleUI | Remove-Module -Force
    Import-Module $manifestPath -Force

    # Records what the components write: one entry per Write-Host call.
    function Start-HostCapture {
        $script:hostOutput = [System.Collections.Generic.List[object]]::new()
        Mock -ModuleName HermesConsoleUI Write-Host {
            $script:hostOutput.Add([pscustomobject]@{ Text = ($Object -join ' '); Color = "$ForegroundColor"; NoNewline = [bool]$NoNewline })
        }
    }

    function Get-CapturedText { ($script:hostOutput | ForEach-Object Text) -join "`n" }
}

AfterAll {
    Get-Module HermesConsoleUI | Remove-Module -Force
}

Describe 'Themes' {
    AfterEach {
        Set-ConsoleTheme -ThemeName Default
    }

    It 'lists the themes from the configuration file' {
        Get-AvailableTheme | Should -Contain 'Cyberpunk'
        Get-AvailableTheme | Should -Contain 'Monochrome'
    }

    It 'keeps the old plural names as aliases' {
        (Get-Command Get-AvailableThemes).ResolvedCommandName | Should -Be 'Get-AvailableTheme'
        (Get-Command Get-AvailableLocales).ResolvedCommandName | Should -Be 'Get-AvailableLocale'
    }

    It 'changes the default color of the components' {
        Start-HostCapture
        Write-ConsoleTitle -Title 'Default theme'
        $defaultColor = ($script:hostOutput | Where-Object Text -Match '^=+$' | Select-Object -First 1).Color

        Set-ConsoleTheme -ThemeName Cyberpunk
        Start-HostCapture
        Write-ConsoleTitle -Title 'Cyberpunk theme'
        $cyberpunkColor = ($script:hostOutput | Where-Object Text -Match '^=+$' | Select-Object -First 1).Color

        $defaultColor | Should -Be 'Cyan'
        $cyberpunkColor | Should -Be 'Magenta'
    }

    It 'lets an explicit -Color win over the theme' {
        Set-ConsoleTheme -ThemeName Cyberpunk
        Start-HostCapture
        Write-ConsoleTitle -Title 'Explicit' -Color Red
        ($script:hostOutput | Where-Object Text -Match '^=+$' | Select-Object -First 1).Color | Should -Be 'Red'
    }

    It 'colors status messages by type from the theme' {
        Set-ConsoleTheme -ThemeName Monochrome
        Start-HostCapture
        Write-ConsoleStatus -Message 'saved' -Type Success
        $script:hostOutput[0].Color | Should -Be 'White'
    }

    It 'supports -WhatIf' {
        Set-ConsoleTheme -ThemeName Classic -WhatIf
        Get-ConsoleTheme | Should -Be 'Default'
    }

    It 'builds a custom theme from the colors given and the Default theme' {
        Set-ConsoleTheme -ThemeName Custom -CustomColors @{ Primary = 'DarkCyan' }
        Get-UIColor -ColorType Primary | Should -Be 'DarkCyan'
        Get-UIColor -ColorType Error | Should -Be 'Red'
    }
}

Describe 'Localization' {
    AfterEach {
        Set-UILocale -Locale en-US
    }

    It 'loads en-US, es-ES and fr-FR' {
        Get-AvailableLocale | Should -Contain 'es-ES'
        Get-AvailableLocale | Should -Contain 'fr-FR'
    }

    It 'reads accented text correctly (UTF-8 locale files)' {
        Get-LocalizedString -Key 'Menu.SelectPrompt' -Locale es-ES | Should -BeExactly "Selecciona una opci$([char]0x00F3)n"
    }

    It 'uses the active locale for menu prompts' {
        Set-UILocale -Locale es-ES
        Start-HostCapture
        Mock -ModuleName HermesConsoleUI Read-Host { '1' }
        Read-ConsoleChoice -MaxChoice 2 | Should -Be 1
        Get-CapturedText | Should -Match '0 para salir'
        Get-CapturedText | Should -Match 'Selecciona una opci'
    }

    It 'uses the active locale for the empty table message' {
        Set-UILocale -Locale fr-FR
        Start-HostCapture
        Write-ConsoleTable -Data @()
        Get-CapturedText | Should -Match 'Aucune donn'
    }

    It 'accepts the locale yes letter in Read-ConsoleConfirmation' {
        Set-UILocale -Locale es-ES
        Mock -ModuleName HermesConsoleUI Read-Host { 'Si' }
        Read-ConsoleConfirmation -Message 'Continuar?' | Should -BeTrue
    }

    It 'treats an empty answer as no' {
        Mock -ModuleName HermesConsoleUI Read-Host { '' }
        Read-ConsoleConfirmation -Message 'Continue?' | Should -BeFalse
    }

    It 'rejects a locale that is not loaded' {
        { Set-UILocale -Locale 'xx-XX' } | Should -Throw
    }
}

Describe 'Text components' {
    BeforeEach { Start-HostCapture }

    It 'Write-ConsoleTitle keeps accented characters' {
        Write-ConsoleTitle -Title "Configuraci$([char]0x00F3)n"
        Get-CapturedText | Should -Match "Configuraci$([char]0x00F3)n"
    }

    It 'Write-ConsoleSubtitle shows the count only when given' {
        Write-ConsoleSubtitle -Text 'Items'
        Write-ConsoleSubtitle -Text 'Items' -Count 3
        Get-CapturedText | Should -Match '\[Items\]'
        Get-CapturedText | Should -Match '\[Items \(3\)\]'
    }

    It 'Write-ConsoleStatus accepts pipeline input' {
        'one', 'two' | Write-ConsoleStatus -Type Info
        ($script:hostOutput | Where-Object Text -Match 'one|two').Count | Should -Be 2
    }

    It 'Write-ConsoleMetadata keeps the order of an ordered dictionary' {
        Write-ConsoleMetadata -Metadata ([ordered]@{ B = 1; A = 2 })
        $keys = $script:hostOutput | Where-Object { $_.NoNewline -and $_.Text -match ': $' } | ForEach-Object { ($_.Text -replace '.*\s(\w+): $', '$1') }
        $keys | Should -Be @('B', 'A')
    }

    It 'Write-ConsoleBreadcrumb joins the path' {
        Write-ConsoleBreadcrumb -Path 'Home', 'Docs' -Separator ' / '
        Get-CapturedText | Should -Match 'Home / Docs'
    }

    It 'Write-ConsoleDiff accepts empty values' {
        { Write-ConsoleDiff -Label 'Value' -OldValue '' -NewValue 'x' } | Should -Not -Throw
    }
}

Describe 'Visual components' {
    BeforeEach { Start-HostCapture }

    It 'Show-ConsoleList numbers items and returns lines' {
        Show-ConsoleList -Items 'a', 'b' -Numbered -ReturnLines | Should -Be @('1. a', '2. b')
    }

    It 'Show-ConsoleList accepts pipeline input' {
        'x', 'y' | Show-ConsoleList
        ($script:hostOutput | Where-Object Text -Match 'x|y').Count | Should -Be 2
    }

    It 'Show-ConsoleList with no items writes nothing' {
        Show-ConsoleList -Items @() -ReturnLines | Should -BeNullOrEmpty
    }

    It 'Write-ConsoleChart returns the percentage and a full-width bar' {
        $line = Write-ConsoleChart -Label 'CPU' -Value 50 -Width 10 -ReturnLines
        $line | Should -Match '^CPU: 50% \['
        ($line -replace '^.*\[|\]$', '').Length | Should -Be 10
    }

    It 'Write-ConsoleChart caps values above Max' {
        Write-ConsoleChart -Label 'Over' -Value 250 -Max 100 -Width 10 -ReturnLines | Should -Match ([regex]::Escape(([string][char]0x2588) * 10))
    }

    It 'Write-ConsoleBox sizes the box to the longest line' {
        $lines = Write-ConsoleBox -Message "short`nlonger line" -ReturnLines
        $lines[0] | Should -Be ('+' + ('-' * 13) + '+')
        $lines.Count | Should -Be 4
    }

    It 'Write-ConsoleTree draws nested branches and leaves' {
        Write-ConsoleTree -TreeData ([ordered]@{ root = [ordered]@{ child = 'leaf' } })
        Get-CapturedText | Should -Match 'root'
        Get-CapturedText | Should -Match 'child'
        Get-CapturedText | Should -Match 'leaf'
    }

    It 'Write-ConsolePanel puts returned lines inside the border' {
        Write-ConsolePanel -Title 'T' -Content { 'inside' } -Width 30
        $line = $script:hostOutput | Where-Object Text -EQ 'inside'
        $line | Should -Not -BeNullOrEmpty
    }

    It 'Write-ConsoleSparkline draws one character per value' {
        Write-ConsoleSparkline -Data 1, 5, 3, 9
        ($script:hostOutput[0].Text.Trim()).Length | Should -Be 4
    }
}

Describe 'Write-ConsoleTable' {
    BeforeEach { Start-HostCapture }

    It 'creates columns from the properties when -Columns is omitted' {
        [pscustomobject]@{ Name = 'svc'; Status = 'Running' } | Write-ConsoleTable
        Get-CapturedText | Should -Match 'Name'
        Get-CapturedText | Should -Match 'Running'
    }

    It 'colors rows with -ColorMapProperty and -ColorMap' {
        $data = @(
            [pscustomobject]@{ Name = 'a'; Status = 'Running' }
            [pscustomobject]@{ Name = 'b'; Status = 'Stopped' }
        )
        Write-ConsoleTable -Data $data -Columns @{ Header = 'Name'; Property = 'Name'; Width = 10 } -ColorMapProperty Status -ColorMap @{ Running = 'Green'; Stopped = 'Red' }
        ($script:hostOutput | Where-Object Text -Match '^\s+a\s*$').Color | Should -Be 'Green'
        ($script:hostOutput | Where-Object Text -Match '^\s+b\s*$').Color | Should -Be 'Red'
    }

    It 'cuts long values so the columns stay aligned' {
        Write-ConsoleTable -Data ([pscustomobject]@{ A = 'x' * 50; B = 'y' }) -Columns @(
            @{ Header = 'A'; Property = 'A'; Width = 10 }
            @{ Header = 'B'; Property = 'B'; Width = 5 }
        )
        ($script:hostOutput | Where-Object Text -Match 'y').Text | Should -Match '^\s+x{9} y'
    }
}

Describe 'Menus' {
    BeforeEach { Start-HostCapture }

    It 'Show-ConsoleMenu numbers only selectable options' {
        $count = Show-ConsoleMenu -Title 'Menu' -Options '[Section]', 'One', '---', 'Two' -NoClear
        $count | Should -Be 2
    }

    It 'Show-ConsoleMenu does not clear the screen when HERMESCONSOLEUI_NOCLEAR is set' {
        Mock -ModuleName HermesConsoleUI Clear-Host { }
        $env:HERMESCONSOLEUI_NOCLEAR = '1'
        try {
            Show-ConsoleMenu -Title 'Menu' -Options 'One' | Out-Null
            Should -Invoke -ModuleName HermesConsoleUI Clear-Host -Times 0 -Exactly
        }
        finally {
            Remove-Item Env:\HERMESCONSOLEUI_NOCLEAR
        }
    }

    It 'Invoke-ConsoleMenu runs the selected action, skipping headers, then exits on 0' {
        $script:answers = [System.Collections.Generic.Queue[string]]::new([string[]]@('2', '', '0'))
        Mock -ModuleName HermesConsoleUI Read-Host { $script:answers.Dequeue() }
        Mock -ModuleName HermesConsoleUI Clear-Host { }
        $script:ran = @()

        Invoke-ConsoleMenu -Title 'Menu' -MenuItems @(
            @{ Label = '[Section]' }
            @{ Label = 'First'; Action = { $script:ran += 'first' } }
            @{ Label = 'Second'; Action = { $script:ran += 'second' } }
        )

        $script:ran | Should -Be @('second')
    }
}

Describe 'Layout' {
    BeforeEach { Start-HostCapture }

    It 'draws columns side by side' {
        $layout = New-ConsoleLayout -Rows @(
            New-ConsoleRow -Columns @(
                New-ConsoleColumn -Content 'LEFT' -WidthPercent 50
                New-ConsoleColumn -Content { param($Width, [switch]$ReturnLines) Show-ConsoleList -Items 'RIGHT' -Width $Width -ReturnLines } -WidthPercent 50
            )
        )
        Write-ConsoleLayout -Layout $layout -TotalWidth 40
        Get-CapturedText | Should -Match 'LEFT\s+\S+ RIGHT'
    }

    It 'shows an error placeholder when a column fails' {
        $layout = New-ConsoleLayout -Rows (New-ConsoleRow -Columns (New-ConsoleColumn -Content { throw 'boom' }))
        Write-ConsoleLayout -Layout $layout
        Get-CapturedText | Should -Match 'Error rendering column'
    }
}

Describe 'Progress and prompts' {
    BeforeEach { Start-HostCapture }

    It 'Show-ConsoleProgress draws the filled part' {
        Show-ConsoleProgress -Activity 'Copy' -PercentComplete 50 -BarLength 10
        ($script:hostOutput | Where-Object Text -EQ '#####') | Should -Not -BeNullOrEmpty
    }

    It 'Read-ConsolePassword returns a SecureString' {
        Mock -ModuleName HermesConsoleUI Read-Host { ConvertTo-SecureString 'x' -AsPlainText -Force }
        Read-ConsolePassword | Should -BeOfType [securestring]
    }

    It 'Invoke-ConsoleSpinner returns the job output and removes the job' {
        Mock -ModuleName HermesConsoleUI Start-Sleep { }
        $before = @(Get-Job).Count
        Invoke-ConsoleSpinner -Message 'Working' -Action { 21 * 2 } | Should -Be 42
        @(Get-Job).Count | Should -Be $before
    }
}

Describe 'Parameters used by existing scripts' {
    # Cassiel, the main consumer of this module, calls these forms.
    BeforeEach { Start-HostCapture }

    It 'Show-ConsoleMenu -Header -ReturnIndex shows the header and returns the choice' {
        Mock -ModuleName HermesConsoleUI Read-Host { '2' }
        Show-ConsoleMenu -Title 'Menu' -Header 'Pick one' -Options 'A', 'B' -ReturnIndex -NoClear | Should -Be 2
        Get-CapturedText | Should -Match 'Pick one'
    }

    It 'Read-ConsoleInput returns -DefaultValue when the answer is empty' {
        Mock -ModuleName HermesConsoleUI Read-Host { '' }
        Read-ConsoleInput -Prompt 'Port' -DefaultValue '8080' | Should -Be '8080'
    }

    It 'Read-ConsoleInput returns what the user typed over the default' {
        Mock -ModuleName HermesConsoleUI Read-Host { '9090' }
        Read-ConsoleInput -Prompt 'Port' -DefaultValue '8080' | Should -Be '9090'
    }

    It 'Write-ConsoleError -Exception shows the exception message' {
        try { throw 'disk full' } catch { Write-ConsoleError -Message 'Backup failed' -Exception $_ }
        Get-CapturedText | Should -Match 'disk full'
    }

    It 'accepts <Command> -<Alias>' -TestCases @(
        @{ Command = 'Read-ConsoleConfirmation'; Alias = 'Prompt' }
        @{ Command = 'Write-ConsoleHeader'; Alias = 'Title' }
        @{ Command = 'Write-ConsoleTable'; Alias = 'Header' }
        @{ Command = 'Invoke-ConsoleSpinner'; Alias = 'Label' }
        @{ Command = 'Invoke-ConsoleSpinner'; Alias = 'Job' }
    ) {
        (Get-Command $Command).Parameters.Values.Aliases | Should -Contain $Alias
    }
}
