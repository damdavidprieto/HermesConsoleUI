# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

Please report security vulnerabilities by opening a GitHub Security Advisory at:
https://github.com/YOUR_USERNAME/PSConsoleUI/security/advisories/new

**Please do not report security vulnerabilities through public GitHub issues.**

### What to Include

When reporting a vulnerability, please include:

* Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
* Full paths of source file(s) related to the manifestation of the issue
* The location of the affected source code (tag/branch/commit or direct URL)
* Any special configuration required to reproduce the issue
* Step-by-step instructions to reproduce the issue
* Proof-of-concept or exploit code (if possible)
* Impact of the issue, including how an attacker might exploit it

### Response Timeline

* We will acknowledge receipt of your vulnerability report within 48 hours
* We will provide a more detailed response within 7 days
* We will work with you to understand and resolve the issue
* We will publicly disclose the vulnerability after a fix is released

## Security Update Policy

* Security updates will be released as soon as possible after a vulnerability is confirmed
* Users will be notified via GitHub releases and security advisories
* Critical vulnerabilities will be prioritized and released immediately

## Best Practices

When using PSConsoleUI:

* Always use the latest version
* Review the CHANGELOG for security-related updates
* Do not execute untrusted PowerShell scripts
* Validate all user input in your applications
* Follow PowerShell security best practices

## Contact

For any security-related questions, please open a GitHub issue or contact the maintainers.
