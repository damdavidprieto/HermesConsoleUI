# Security Policy

## Supported Versions

Only the latest version is supported. Versions before 2.2.0 write displayed data to the console
without removing terminal escape sequences; update to 2.2.0 or later.

## Displaying untrusted data

From 2.2.0, every component removes terminal control sequences (ANSI CSI/OSC, carriage returns and
other control characters) from the text it writes, so data such as file names or log lines cannot
restyle the console, overwrite earlier lines or set the clipboard. Script blocks you pass to
`Invoke-ConsoleMenu`, `Write-ConsolePanel` or `Invoke-ConsoleSpinner` run with your own permissions:
never build them from untrusted input.

## Reporting a Vulnerability

Please **do not** report security vulnerabilities through public issues.

Use GitHub's private vulnerability reporting instead:
[Report a vulnerability](https://github.com/damdavidprieto/HermesConsoleUI/security/advisories/new)

Include a description, steps to reproduce and the potential impact. You can expect an initial response within a few days. If the report is accepted, a fix and a coordinated disclosure will follow; if not, you will receive an explanation.

## Scope

Please never include real credentials, personal data or secrets in a report. If you find exposed secrets in this repository, report them through the same private channel.
