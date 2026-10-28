# Changelog

All notable changes to these runbooks are listed here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/): a new runbook is a minor version, a correction is a patch.

## [Unreleased]

### Added

- 06 Printer Troubleshooting: queue, Print Spooler, network ports 9100/631/515, port and driver checks, with `Reset-PrintQueue.ps1` and a guide to deploy printers with Group Policy Preferences.
- 07 Remote Support: consent-first Quick Assist procedure, Remote Desktop with Network Level Authentication, and a remote support security checklist.
- Continuous integration: markdownlint, relative link check, PSScriptAnalyzer, and a Windows PowerShell 5.1 parse check of every script.
- `CONTRIBUTING.md` with the writing rules, the script rules and the local checks.
- Issue form **Report an error in a runbook**.
- This changelog.

### Changed

- 04 Network Troubleshooting: printing ports added to the common port list, with links to runbooks 06 and 07.
- README index, connection diagram and error report form list runbooks 06 and 07.
- Copied study notes (`LAN.md`, `ABC-Cybersecurity.md`, `RoadMAP.md`) moved to [`archive/`](archive/README.md), each with a note that credits its source. They are no longer presented as original runbooks.

### Removed

- Empty `Software Vulnerabilities.md` placeholder.
- A list of personal lab servers from the archived roadmap notes.

## [0.1.0] - 2026-10-20

### Added

- Runbook template (`TEMPLATE.md`) with header table, Objective, Prerequisites, Procedure, Verification, Troubleshooting and Rollback.
- 01 PC Boot Process and BIOS / UEFI, with a no-boot troubleshooting decision tree.
- 02 Windows 11 Clean Installation, with a post-installation checklist.
- 03 Software Deployment (winget and MSI), with `Install-StandardApps.ps1`.
- 04 Network Troubleshooting, with a Windows / Linux / Cisco IOS command cheat sheet.
- 05 Active Directory User Management.
- README with the runbook index and the writing standard.
