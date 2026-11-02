# Changelog

All notable changes to these runbooks are listed here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/): a new runbook is a minor version, a correction is a patch.

## [Unreleased]

Nothing yet.

## [1.0.0] - 2026-11-02

First complete release: 15 runbooks that all follow the same template, with automatic checks on every change.

### Added

- 06 Printer Troubleshooting: queue, Print Spooler, network ports 9100/631/515, port and driver checks, with `Reset-PrintQueue.ps1` and a guide to deploy printers with Group Policy Preferences.
- 07 Remote Support: consent-first Quick Assist procedure, Remote Desktop with Network Level Authentication, and a remote support security checklist.
- 08 Network Cabling and Termination: T568A/T568B colour codes with a pinout diagram, straight-through vs crossover, Cat 5e/6/6A limits, RJ45 crimping, a cable testing guide with wire map faults, and a patch panel and TIA-606 labeling guide.
- 09 Wi-Fi Troubleshooting: 2.4/5/6 GHz bands and channels, `netsh wlan show interfaces` and `show networks mode=bssid`, signal thresholds, profile and WPA3 fixes, with `Export-WifiDiagnostics.ps1` and a guide to the wireless network report.
- 10 VoIP / SIP Phone Troubleshooting: the PoE → voice VLAN → registration → SIP → RTP chain, Asterisk/FreePBX checks, one-way audio caused by NAT, SIP ALG and RTP ports (UDP 10000–20000), with a SIP call flow guide (SDP, response codes) and a voice network readiness guide (codec bandwidth, DSCP EF 46, voice VLAN, PoE).
- 11 Cisco Switch Baseline: a complete, commented access switch configuration (type 9 secrets, banner, SSH version 2 only, management VLAN and ACL, port security, portfast and BPDU guard, black hole VLAN, restricted trunk with an unused native VLAN), with a port security and err-disabled recovery guide.
- 12 Linux Server Hardening Basics: Ed25519 SSH keys, an `sshd_config.d` drop-in (`PasswordAuthentication no`, `PermitRootLogin no`, `AllowUsers`), ufw with default deny and `limit` on SSH, a fail2ban jail with incremental bans, unattended security upgrades, and a guide explaining why Docker published ports bypass ufw and how to bind them to `127.0.0.1`.
- 13 Backup and Restore: RPO and RTO inventory, the 3-2-1 rule, a mandatory and recorded restore test, a Windows guide (File History, `wbadmin`, robocopy and its exit codes), a Linux guide (restic with a systemd timer, retention and `restic check`, rsync as a mirror), and `Test-RestoredFiles.ps1` to compare a restored folder with the original by SHA-256.
- 14 Phishing Report and First Response: recognize, report with the built-in Outlook **Report** button, contain according to what the user did, escalate and record; a first response checklist (password reset, `Revoke-MgUserSignInSession`, MFA method review, forwarding and `Get-InboxRule -IncludeHidden` checks, device isolation), a guide to reading SPF, DKIM, DMARC, compauth and the Received chain, and `Get-EmailHeaderSummary.ps1` with a fictional sample.
- 15 Microsoft 365 and Outlook Basics: account checks in order (sign-in, license with `Get-MgUserLicenseDetail`, mailbox, MFA with an identity check before any reset), a guide to Outlook profiles, Cached Exchange Mode and `.ost` rebuilds, a guide to shared mailboxes (Full Access, Send As, Send on Behalf, auto-mapping), and `Get-OutlookClientInfo.ps1`.
- Continuous integration: markdownlint, relative link check, PSScriptAnalyzer, and a Windows PowerShell 5.1 parse check of every script.
- Weekly external link check of the vendor documentation references (`external-links.yml`), kept out of pull requests.
- `CONTRIBUTING.md` with the writing rules, the script rules and the local checks.
- Issue form **Report an error in a runbook**.
- This changelog.

### Changed

- Release review of runbooks 01 to 05, so the first five match the template like the later ones:
  - 01 Boot and BIOS / UEFI: procedure numbered Step 1 to 4, BitLocker suspend prerequisite, troubleshooting and rollback sections; the no-boot guide gains a verification checklist.
  - 02 Windows 11 Clean Installation: verification commands (UEFI, GPT, Secure Boot, activation) and a rollback section that explains why only the backup can undo a clean install.
  - 03 Software Deployment: rollback for winget, bad upgrades (previous version and `winget pin`) and MSI, and three more troubleshooting rows.
  - 04 Network Troubleshooting: warning that a network reset can erase a static IP configuration, verification, troubleshooting and rollback sections; the cheat sheet gains its badges and a built-in Windows capture with `pktmon`.
  - 05 Active Directory User Management: group memberships exported to CSV before a departure, troubleshooting and rollback sections (including AD Recycle Bin restores).
- README: index levels now match each document's badge (with a legend), the connection diagram is coloured by area, and the standard table lists the Rollback section.
- `TEMPLATE.md`: optional escalation block and related work list, and what to write when a step cannot be undone.
- "Last reviewed" badge on every document reviewed for this release.
- 04 Network Troubleshooting: printing ports added to the common port list, with links to runbooks 06 and 07; the physical layer step links to runbooks 08 and 09; the port check links to runbook 10, and the cheat sheet gains Cisco switchport, trunk, err-disabled and PoE commands with a link to runbook 11; it also gains a TCP port test and a container port command, with a link to runbook 12.
- 02 Windows 11 Clean Installation: the post-installation checklist links to the restore test and to File History.
- 05 Active Directory User Management and the 07 remote support security checklist link to the phishing first response (runbook 14); account departures link to removing shared mailbox permissions (runbook 15).
- README index, connection diagram and error report form list runbooks 06 to 15.
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
