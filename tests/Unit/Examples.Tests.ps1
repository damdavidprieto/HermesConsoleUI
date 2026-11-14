BeforeDiscovery {
    # 05-InteractiveMenu.ps1 waits for input, so it is not run here.
    $script:examples = Get-ChildItem -Path (Join-Path $PSScriptRoot '..\..\examples') -Filter '*.ps1' |
        Where-Object Name -NE '05-InteractiveMenu.ps1' |
        ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
}

Describe 'Example <Name>' -ForEach $examples {
    It 'runs without errors' {
        { & $Path 6>$null } | Should -Not -Throw
    }
}

Describe 'Examples folder' {
    It 'contains the interactive example' {
        Join-Path $PSScriptRoot '..\..\examples\05-InteractiveMenu.ps1' | Should -Exist
    }
}
