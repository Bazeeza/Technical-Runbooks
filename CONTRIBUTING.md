# Contributing

Thank you for helping keep these runbooks accurate. A runbook is followed by someone under pressure, so a wrong command costs real time: every correction counts.

## Report an error

Open an issue with the **[Report an error in a runbook](https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml)** form. It asks for the runbook, the step, what happened and, if possible, a link to the official documentation.

> [!WARNING]
> Never paste passwords, internal IP addresses, hostnames, user names or screenshots that show them. Replace them with placeholders such as `<SERVER>` or `192.0.2.10` (an address reserved for documentation, [RFC 5737](https://www.rfc-editor.org/rfc/rfc5737)).

## Propose a change

1. Fork the repository and create a branch, for example `fix/04-dns-step`.
2. Make **one change per pull request** (one runbook, or one fix across runbooks).
3. Check your change locally, then open the pull request and describe what you verified.

## Writing rules

| Rule | Why |
|---|---|
| Follow [TEMPLATE.md](TEMPLATE.md): header table, Objective, Prerequisites, Procedure, Verification, Troubleshooting, Rollback | A technician always finds the same section in the same place |
| Every step gives the exact command, **why** it is run and the **expected result** | The reader can tell immediately whether the step worked |
| Write in English, in your own words | Copied text is not accepted as a runbook; see [archive/](archive/README.md) for how copied notes are handled |
| Check commands against official vendor documentation and list it in the **Reference** row | A source lets the next reader verify, and protects the runbook's credibility |
| Use only generic values (`<USERNAME>`, `contoso.local`, `192.0.2.0/24`) | Public documentation must never expose a real network |
| Warn before any destructive step and give a rollback | Data protection comes before speed |
| Diagrams in Mermaid, code blocks with a language (`powershell`, `bash`, `text`) | Diagrams stay editable and commands are highlighted |

## Scripts

PowerShell scripts must:

- run on **Windows PowerShell 5.1** (the default on Windows 11) as well as PowerShell 7;
- support `-WhatIf` when they change the system (`[CmdletBinding(SupportsShouldProcess)]`);
- be saved as ASCII, or UTF-8 **with BOM** if they contain accented characters (Windows PowerShell 5.1 reads a file without BOM as ANSI);
- pass PSScriptAnalyzer with the repository settings:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

## Automatic checks

Every pull request runs the same checks as the `main` branch:

| Workflow | What it checks |
|---|---|
| [Markdown](.github/workflows/markdown.yml) | markdownlint rules listed in [`.markdownlint-cli2.jsonc`](.markdownlint-cli2.jsonc), and every relative link between files |
| [PowerShell](.github/workflows/powershell.yml) | PSScriptAnalyzer (errors and warnings), and parsing of every script by Windows PowerShell 5.1 |

To run the Markdown checks locally (Node.js required):

```bash
npx markdownlint-cli2 "**/*.md"
```

## Changelog

Notable changes are listed in [CHANGELOG.md](CHANGELOG.md). Add a line under **Unreleased** in your pull request.
