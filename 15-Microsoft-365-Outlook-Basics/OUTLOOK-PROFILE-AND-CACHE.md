# Outlook Profiles and Cached Exchange Mode

![Level](https://img.shields.io/badge/Level-Beginner-3fe0a0?style=flat-square)
![Time](https://img.shields.io/badge/Time-15%E2%80%9345%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Classic%20Outlook%20for%20Windows-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | The local side of classic Outlook for Windows: the profile that holds the accounts, and the offline data file (`.ost`) kept by Cached Exchange Mode. |
| **Sender** | **bazeeza** |
| **Message** | Tell a client problem from an account problem, start in safe mode, create a clean profile without deleting the old one, set Cached Exchange Mode and the offline period, and rebuild an `.ost` file safely. |
| **Receiver** | Help desk technicians. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · Windows PowerShell 5.1 |
| **Reference** | [Microsoft Learn: Plan and configure Cached Exchange Mode](https://learn.microsoft.com/en-us/microsoft-365-apps/outlook/configuration/cached-exchange-mode) · [Microsoft Support: Turn on Cached Exchange Mode](https://support.microsoft.com/office/7885af08-9a60-4ec3-850a-e221c1ed0c1c) · [Microsoft Support: Create an Outlook profile](https://support.microsoft.com/office/f544c1ba-3352-4b3b-be0b-8d42a540459d) · [Microsoft Support: Change or update e-mail account settings in Outlook for Windows](https://support.microsoft.com/en-us/outlook/change-or-update-email-account-settings-in-outlook-for-windows) |

Back to [15 Microsoft 365 and Outlook Basics](README.md).

---

## Classic or new Outlook?

Windows 11 can have two different Outlook applications. Ask the user which one they open, or run [`Get-OutlookClientInfo.ps1`](Get-OutlookClientInfo.ps1).

| | Classic Outlook | New Outlook for Windows |
|---|---|---|
| Comes with | Microsoft 365 Apps (Word, Excel...) | Windows 11, or the Microsoft Store |
| Process name | `OUTLOOK.EXE` | `olk.exe` |
| Profiles | Yes, managed in this guide | No: accounts are added in **Settings** › **Accounts** |
| Offline data | `.ost` file (Cached Exchange Mode) | Managed by the application |
| Add-ins | COM add-ins and web add-ins | Web add-ins only |

The rest of this guide applies to **classic Outlook**.

## Step 1 — Check that the problem is the client

Before changing anything on the PC, open **Outlook on the web** with the same account in a browser.

| Outlook on the web | Conclusion | Next |
|---|---|---|
| Same problem (mail missing, cannot send, error) | The **account or the mailbox** | [Runbook 15, account checks](README.md#step-1--check-the-account-and-its-license) |
| Works normally | The **client** on this PC | Continue below |

**Expected result:** you know whether to work on the PC or on the account.

## Step 2 — Start in safe mode

Safe mode starts Outlook without add-ins and without the reading pane customizations. Close Outlook, then run:

```powershell
outlook.exe /safe
```

The same switch works from **Win + R**. If Outlook works in safe mode, disable the add-ins one by one: **File** › **Options** › **Add-ins** › **Manage: COM Add-ins** › **Go**.

**Expected result:** Outlook starts, and you know whether an add-in is the cause.

## Step 3 — Create a new profile (keep the old one)

A profile holds the accounts and points to the `.ost` file. A damaged profile causes endless password prompts, a loop at "Loading profile", or folders that never update. A **new** profile is quicker and safer than repairing the old one, and the old one stays available if something was missed.

1. Close Outlook.
2. Open the profile list with one of these:
   - **Control Panel** (view: **Large icons**) › **Mail (Microsoft Outlook)** › **Show Profiles**
   - `outlook.exe /profiles`, then **Options**
   - In Outlook: **File** › **Account Settings** › **Manage Profiles** › **Show Profiles**
3. Select **Add**, name the profile with the date (for example `Outlook-2026-11`), select **OK**.
4. Enter the user's e-mail address and let Autodiscover configure the account. The user signs in with their password and MFA.
5. Under **When starting Microsoft Outlook, use this profile**, choose **Always use this profile** and select the new one (or **Prompt for a profile to be used** while you test).
6. Start Outlook and wait for the first synchronization.

Shared mailboxes with Full Access appear again by themselves (auto-mapping) after a few minutes; see [Shared mailboxes and permissions](SHARED-MAILBOXES-AND-PERMISSIONS.md).

**Expected result:** Outlook opens with the new profile, mail and calendar are up to date. Remove the old profile only after the user confirms that nothing is missing (signatures, rules, local PST files).

> [!WARNING]
> Before removing an old profile, check for **PST files** (`Get-OutlookClientInfo.ps1` lists them). A PST file exists only on this PC: it is not on the server and is not rebuilt with the profile.

## Step 4 — Set Cached Exchange Mode and the offline period

Cached Exchange Mode keeps a copy of the mailbox in an `.ost` file on the PC, so Outlook stays fast and keeps working offline. Microsoft recommends it for Microsoft 365 accounts.

1. **File** › **Account Settings** › **Account Settings**.
2. Select the Microsoft 365 account › **Change**.
3. Under **Offline Settings**, check **Use Cached Exchange Mode** (on some versions: **Use Cached Exchange Mode to download email to an Outlook data file**).
4. Set the slider for how much mail to keep offline. By default, Outlook keeps **12 months**. Older mail stays on the server and is shown with **Click here to view more on Microsoft Exchange** at the end of a folder.
5. Exit and restart Outlook.

| Situation | Setting |
|---|---|
| Normal laptop or desktop | Cached mode, default 12 months |
| Small disk, or large mailbox | Cached mode, a shorter period (for example 3 or 6 months) |
| Shared kiosk PC with many users, or data must not be stored locally | Online Mode (cached mode off), as described by Microsoft |

**Expected result:** after the restart, the status bar shows **Connected to: Microsoft Exchange** and **All folders are up to date** once the synchronization ends.

## Step 5 — Rebuild the offline data file

The `.ost` file is only a **copy** of the mailbox: Outlook can download it again. Rebuild it when one folder stays out of date, the file is damaged, or it grew too large.

```powershell
# 1. Close Outlook and check that it is closed
Get-Process -Name OUTLOOK -ErrorAction SilentlyContinue

# 2. List the data files and their size
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Outlook" -Filter *.ost | Select-Object Name, @{n='SizeGB';e={[math]::Round($_.Length/1GB,2)}}, LastWriteTime

# 3. Rename it (do not delete it yet)
Rename-Item "$env:LOCALAPPDATA\Microsoft\Outlook\user@contoso.com.ost" "user@contoso.com.ost.old"
```

Start Outlook: it creates a new `.ost` and downloads the mailbox again. This takes from minutes to hours depending on the size and the connection, so plan it with the user. Delete the `.old` file after a few days, once everything is confirmed.

> [!NOTE]
> Microsoft notes that `.ost` files are **50 to 80 percent larger** than the mailbox size reported by Exchange, and that the default maximum size is **50 GB**. Check the free disk space before a rebuild.

**Expected result:** a new `.ost` file, the folders up to date, and the user's mail visible in classic Outlook.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Outlook stays on "Loading profile" | Damaged profile, or an add-in | `outlook.exe /safe`, then a new profile (step 3) |
| Password prompt that keeps coming back | Old credentials stored, damaged profile, or MFA not completed | Remove the Outlook entries in **Credential Manager** › **Windows Credentials**, sign in again; new profile if it persists |
| One folder is not updated | Damaged `.ost` | Rebuild the `.ost` (step 5) |
| Old mail "missing" | Cached Exchange Mode keeps only the chosen period offline | **Click here to view more on Microsoft Exchange**, or a longer slider period |
| Outlook very slow, disk almost full | `.ost` close to its limit | Shorter offline period, archive, free disk space |
| Mail works on the web but not in Outlook | Client problem | Steps 2 to 5 |
| Mail does not work on the web either | Account, license or mailbox problem | [Runbook 15, account checks](README.md#step-1--check-the-account-and-its-license) |

## Rollback

Select the old profile again in **Mail (Microsoft Outlook)** › **Show Profiles** › **Always use this profile**. To go back to the old offline file, close Outlook, rename the new `.ost` and remove `.old` from the previous one.

---

<sub>Written by bazeeza · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
