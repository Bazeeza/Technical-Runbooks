# Windows Backups: File History, Windows Server Backup and robocopy

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-20%E2%80%9340%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011%20%7C%20Windows%20Server%202019%2B-0078D4?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | A Windows workstation whose user files must be protected, or a Windows file server whose shares and system must be recoverable. |
| **Sender** | **Bariu Azeez** |
| **Message** | Choose the built-in tool that fits the machine, configure it, then restore to a separate folder and prove the restore with `Test-RestoredFiles.ps1`. |
| **Receiver** | Help desk technicians and junior Windows administrators. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · Windows PowerShell 5.1, Command Prompt |
| **Reference** | [Microsoft: Back up and restore with File History](https://support.microsoft.com/en-us/windows/backup-and-restore-with-file-history-7bf065bf-f1ea-0a78-c1cf-7dcf51cc8bfc) · [Microsoft: wbadmin start backup](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wbadmin-start-backup) · [Microsoft: wbadmin start recovery](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wbadmin-start-recovery) · [Microsoft: robocopy](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy) · [Microsoft: Return codes used by robocopy](https://learn.microsoft.com/en-us/troubleshoot/windows-server/backup-and-storage/return-codes-used-robocopy-utility) |

---

## Objective

Give every Windows machine a backup that matches what it holds, and a restore that has been **tested**. This guide is part of [runbook 13](README.md), which explains the 3-2-1 rule and the restore test record.

## Which tool for which machine

| Machine | What must come back | Tool | Keeps old versions |
|---|---|---|---|
| User workstation | Documents, desktop, pictures | **File History** to an external disk or a network share | Yes, every hour by default |
| Workstation with OneDrive | The same folders | OneDrive folder backup | Version history and recycle bin of OneDrive, for a limited time: a sync, not a full backup |
| Windows Server (file server) | Shares, system state, whole volumes | **Windows Server Backup** (`wbadmin`) | Yes, several versions on the target disk |
| Any machine, second copy | A data folder | **robocopy** to a NAS | No: a mirror, like rsync |

On a domain, the company backup software, if there is one, comes first: these tools are for small sites, labs and single machines.

## Option A — File History (workstation)

1. Connect the external disk, or have a network share ready.
2. Open **Control Panel** › **System and Security** › **Save backup copies of your files with File History**.
3. Select **Select drive** to choose the disk or network location, then **Turn on**.
4. In **Advanced settings**, set **Save copies of files** (every hour by default) and **Keep saved versions** (for example 3 months).

File History protects the user's libraries, desktop, contacts and favorites. It does **not** back up applications or Windows itself: those are reinstalled ([runbooks 02](../02-Windows-11-Clean-Installation/README.md) and [03](../03-Software-Deployment/README.md)).

**Restore test:** in **File Explorer**, right-click the folder › **Restore previous versions**. On the **Previous Versions** tab, select a version, then expand **Restore** › **Restore to...** and pick an empty test folder, so the live files are not overwritten.

**Expected result:** the folder appears in the test location with the content it had on that date.

## Option B — Windows Server Backup (server)

Install the feature, then run a one-time backup to a dedicated disk or a share, from an elevated PowerShell:

```powershell
Install-WindowsFeature -Name Windows-Server-Backup
wbadmin start backup -backupTarget:E: -include:D: -allCritical -quiet
wbadmin get versions
```

- `-include:D:` backs up the data volume; `-allCritical` adds what is needed for a bare-metal recovery of the system.
- `-backupTarget` can be a local volume or a network share (`\\<backup-server>\<share>`). A dedicated local disk keeps several versions; on a network share, each new backup **overwrites** the previous one, so a failed run can leave you with no usable backup.
- For a daily schedule, use **Windows Server Backup** › **Backup Schedule**, or `wbadmin enable backup`.

**Restore test** of a folder, to an alternate location (the version identifier comes from `wbadmin get versions`):

```powershell
wbadmin start recovery -version:<MM/DD/YYYY-HH:MM> -itemType:File -items:D:\Shares\Finance -recoveryTarget:E:\RestoreTest -recursive
```

**Expected result:** `The recovery operation completed successfully` and the folder under `E:\RestoreTest`.

> [!WARNING]
> Without `-recoveryTarget`, files are restored to their **original** location. Always restore a test to another folder.

## Option C — robocopy mirror to a NAS (second copy)

```powershell
robocopy D:\Data \\<nas>\backup\Data /MIR /COPY:DAT /DCOPY:DAT /R:2 /W:5 /L /NP /LOG:C:\Logs\robocopy-data.log
robocopy D:\Data \\<nas>\backup\Data /MIR /COPY:DAT /DCOPY:DAT /R:2 /W:5 /NP /LOG:C:\Logs\robocopy-data.log
$LASTEXITCODE
```

| Option | Why |
|---|---|
| `/L` (first run) | Lists what would be copied **and deleted**, without doing it |
| `/MIR` | Exact mirror: also **deletes** in the destination what no longer exists in the source |
| `/COPY:DAT /DCOPY:DAT` | Data, attributes and time stamps for files and folders |
| `/R:2 /W:5` | Two retries five seconds apart, instead of the default one million retries |
| `/LOG:` | A log to attach to the ticket or check later |

Robocopy's exit code is a set of flags, not a simple success or failure: **0 to 7 means no failure**, **8 or more means at least one file failed**. A scheduled task that treats any non-zero code as an error raises false alarms.

> [!CAUTION]
> A mirror copies mistakes too: a file deleted or encrypted by ransomware is deleted or encrypted in the mirror at the next run. robocopy is a second copy, never the only backup.

## Prove the restore with Test-RestoredFiles.ps1

Whatever the tool, finish the restore test with a comparison of the restored folder and the original:

```powershell
.\Test-RestoredFiles.ps1 -SourcePath D:\Shares\Finance -RestoredPath E:\RestoreTest\Finance -ReportPath .\restore-test.csv
```

| Result | Meaning |
|---|---|
| Exit code **0**, `Restore test PASSED` | Every file came back with an identical SHA-256 hash |
| Exit code **1**, `Different` lines | Content differs: the file changed after the backup, or the copy is damaged |
| Exit code **1**, `Missing` lines | Files not in the backup: check the backup selection |
| Exit code **2** | One of the folders does not exist |

Files edited between the backup and the test appear as `Different`. Choose a folder that does not change during the day, or explain the expected differences in the record.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| File History: `Reconnect your drive` | External disk disconnected or drive letter changed | Reconnect it, or **Select drive** again |
| File History skips files | Path too long, or file open and locked | Shorten deep folder paths; files in use are copied at the next run |
| `wbadmin` not recognized | Feature not installed | `Install-WindowsFeature Windows-Server-Backup` |
| Only one version on the network share | Normal: each backup to the same share overwrites the previous one | Use a dedicated local disk for history, or a subfolder per backup |
| `wbadmin start recovery` fails on files | Items from different parent folders in one command | Restore one parent folder per command |
| robocopy exit code 8 or 16 | Access denied, path not found, share unreachable | Read the `ERROR` lines of the log; check the account rights on the NAS |
| robocopy deleted files in the copy | `/MIR` and files removed from the source | Expected behavior: restore them from the real backup, and keep `/L` as a first step |

---

<sub>Part of [runbook 13, Backup and Restore](README.md) · Written by Bariu Azeez</sub>
