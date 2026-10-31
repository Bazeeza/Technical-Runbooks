# Windows 11 Post-Installation Checklist

![Level](https://img.shields.io/badge/Level-Beginner-3fe0a0?style=flat-square)
![Time](https://img.shields.io/badge/Time-30%E2%80%9345%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D6?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | Checks and settings to complete after installing Windows 11, before handing the workstation to a user. |
| **Sender** | **Bariu Azeez** |
| **Message** | Deliver a workstation that is updated, secured, identified and verified, the same way every time. |
| **Receiver** | Help desk technicians. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing |
| **Reference** | [Windows Update](https://learn.microsoft.com/en-us/windows/deployment/update/) · [BitLocker](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/) · [Join a computer to a domain](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/join-a-computer-to-a-domain) |

---

## Objective

A checklist removes "I forgot" from the job: every workstation leaves the bench in the same known state. Copy this list into the ticket and tick each item.

> All commands run in **PowerShell as administrator** unless noted otherwise.

---

## 1. Updates and drivers

- [ ] **Windows Update**: Settings → Windows Update → *Check for updates*. Repeat until nothing is left (several restarts are normal).
- [ ] **Manufacturer drivers and firmware** with the vendor's tool: Dell Command | Update, Lenovo System Update / Commercial Vantage, HP Image Assistant / Support Assistant.
- [ ] **Device Manager** (`devmgmt.msc`): no device with a yellow warning sign.

```powershell
# List devices with a problem (empty result = all good)
Get-PnpDevice | Where-Object Status -ne 'OK' | Select-Object Class, FriendlyName, Status
```

## 2. Activation

- [ ] Settings → System → Activation shows **Windows is activated**.

```powershell
slmgr /xpr    # opens a window showing the activation status
```

## 3. Identity of the workstation

- [ ] Rename the PC according to the organization's naming convention (example: `MTL-LT-0042` = site, type, asset number).

```powershell
Rename-Computer -NewName "MTL-LT-0042" -Restart
```

- [ ] **Domain join** (on-premises Active Directory, Pro or Enterprise edition), after the rename:

```powershell
Add-Computer -DomainName "corp.example.com" -OUPath "OU=Workstations,DC=corp,DC=example,DC=com" -Credential (Get-Credential) -Restart
```

- [ ] Or **Entra ID / Intune**: Settings → Accounts → Access work or school → Connect.
- [ ] Record the serial number and asset tag in the inventory (GLPI or equivalent):

```powershell
Get-CimInstance Win32_BIOS | Select-Object SerialNumber
```

## 4. Security

- [ ] **Microsoft Defender** (or the organization's antivirus/EDR) active and up to date: Windows Security → Virus & threat protection.
- [ ] **Firewall** on for all profiles:

```powershell
Get-NetFirewallProfile | Select-Object Name, Enabled   # all must be True
```

- [ ] **BitLocker** enabled on the system drive, recovery key saved to AD / Entra ID (never only on the PC itself):

```powershell
manage-bde -status C:
```

- [ ] The daily-use account is a **standard user**, not a local administrator (principle of least privilege).
- [ ] Remove unwanted pre-installed software (trial antivirus, games).

## 5. Applications and user setup

- [ ] Install the standard applications: see [runbook 03 — Software Deployment](../03-Software-Deployment/README.md).
- [ ] Printers, mapped drives and VPN as required by the user's department.
- [ ] Restore the user's data from the backup, then let the user confirm their files are there (to prove the restore file by file, see [runbook 13 — Backup and Restore](../13-Backup-and-Restore/README.md#step-5--test-the-restore-mandatory)).
- [ ] Turn on the workstation's own backup (File History or the site's tool): see [Windows backups](../13-Backup-and-Restore/WINDOWS-BACKUP.md#option-a--file-history-workstation).

## 6. Final verification

- [ ] Restart once more: the PC starts without error
- [ ] Network, Internet and internal resources reachable (see [runbook 04](../04-Network-Troubleshooting/README.md))
- [ ] Sound, camera, Wi-Fi, Bluetooth, docking station tested
- [ ] Ticket updated with the work done, then closed with the user's confirmation

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
