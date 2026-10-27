# Software Deployment on Windows (winget and MSI)

![Level](https://img.shields.io/badge/Level-Beginner%20to%20Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-15%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | Installing, verifying, updating and removing software on Windows from the command line, silently and reproducibly. |
| **Sender** | **Bariu Azeez** |
| **Message** | Install software the same way on every workstation, without clicking through wizards, and prove that the installation succeeded. |
| **Receiver** | Help desk technicians, junior system administrators. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · PowerShell |
| **Reference** | [Microsoft: winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) · [msiexec](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/msiexec) · [MSI error codes](https://learn.microsoft.com/en-us/windows/win32/msi/error-codes) |

---

## Objective

Clicking "Next, Next, Finish" on twenty PCs is slow and produces different results each time. A **silent installation** (no user interaction) is faster, can be scripted, and leaves a log that proves what was done. This runbook covers the two methods a technician meets every day: **winget** (Windows Package Manager) and **MSI packages**, plus the [`Install-StandardApps.ps1`](Install-StandardApps.ps1) script that installs a standard list of applications in one command.

## Prerequisites

- [ ] Windows 10 (1809+) or Windows 11, with *App Installer* up to date (`winget --version` answers)
- [ ] Administrator rights for software installed for all users
- [ ] The list of approved software: only install what the organization allows
- [ ] Internet access, or access to the internal software share for MSI files

---

## Method 1 — winget (preferred)

winget downloads software from a curated repository, checks the installer's hash, and installs it silently.

### Step 1 — Find the exact package ID

```powershell
winget search firefox
```

Use the **Id** column (e.g. `Mozilla.Firefox`). An ID is exact; a name can match several packages.

### Step 2 — Install silently

```powershell
winget install --id Mozilla.Firefox --exact --silent --accept-package-agreements --accept-source-agreements
```

| Option | Why |
|---|---|
| `--id ... --exact` | Installs exactly this package, never a similarly named one |
| `--silent` | No window, no question to the user |
| `--accept-...-agreements` | Accepts licenses in advance, otherwise the command waits for an answer |
| `--scope machine` | (optional) installs for all users when the package supports it |

### Step 3 — Verify

```powershell
winget list --id Mozilla.Firefox --exact
```

**Expected result:** a line with the name, the ID and the installed version.

### Maintenance

```powershell
winget upgrade                                   # list available updates
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
winget uninstall --id Mozilla.Firefox --exact --silent
winget export -o apps.json                       # save the list of installed software
winget import -i apps.json --accept-package-agreements --accept-source-agreements   # reinstall it on another PC
```

---

## Method 2 — MSI package (msiexec)

Many business applications are distributed as `.msi` files, the standard format for enterprise deployment (GPO, Intune, Configuration Manager).

### Install silently with a log

```powershell
New-Item -ItemType Directory -Force C:\Temp | Out-Null
Start-Process msiexec.exe -Wait -PassThru -ArgumentList '/i "\\fileserver\software\app.msi" /qn /norestart /l*v "C:\Temp\app-install.log"'
```

| Option | Meaning |
|---|---|
| `/i` | Install |
| `/qn` | Quiet, no interface |
| `/norestart` | Never restart the PC automatically: the user may lose work |
| `/l*v file` | Verbose log, essential for diagnosis |

### Read the exit code

`-PassThru` returns the process; its `ExitCode` tells what happened:

| Code | Meaning | Action |
|---|---|---|
| `0` | Success | None |
| `3010` | Success, **restart required** | Plan a restart with the user |
| `1603` | Fatal error during installation | Read the log: search for `Return value 3` |
| `1618` | Another installation is already running | Wait and retry |
| `1619` | Package could not be opened | Check the path and the access rights |

### Uninstall

```powershell
# Find the product code (GUID) in the registry
Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*,
                 HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object DisplayName -like '*App Name*' |
    Select-Object DisplayName, DisplayVersion, PSChildName

msiexec /x "{PRODUCT-CODE-GUID}" /qn /norestart
```

> [!WARNING]
> Avoid `Get-WmiObject Win32_Product` to list software: querying it makes Windows check, and sometimes **repair**, every MSI product installed. Read the registry keys above instead.

### EXE installers

`.exe` installers have no standard switches. The usual ones depend on the tool that built the installer:

| Installer type | Silent switch |
|---|---|
| NSIS | `/S` (capital S) |
| Inno Setup | `/VERYSILENT /NORESTART` |
| InstallShield (with embedded MSI) | `/s /v"/qn"` |

Always confirm in the vendor's documentation and test on one PC first.

---

## Install a standard set of applications in one command

The script [`Install-StandardApps.ps1`](Install-StandardApps.ps1) reads a list of winget IDs, skips software that is already present, installs the rest, **checks** each result and writes a log.

```powershell
# Preview what would be installed, without changing anything
.\Install-StandardApps.ps1 -WhatIf

# Install
.\Install-StandardApps.ps1
```

---

## Verification

- [ ] Each application appears in `winget list` or in **Settings → Apps → Installed apps**
- [ ] Each application opens for a standard user
- [ ] Exit codes and logs are attached to the ticket

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `winget` is not recognized | App Installer missing or outdated | Update **App Installer** from the Microsoft Store |
| Installation hangs | A license or a prompt is waiting for an answer | Add `--accept-package-agreements --accept-source-agreements` and `--silent` |
| `Installer hash does not match` | The vendor changed the file, repository not yet updated | Run `winget source update` and retry later; never bypass the hash check |
| MSI code `1603` | Insufficient rights, older version present, missing prerequisite | Read the `/l*v` log, run as administrator, remove the old version |

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
