# Reading the Windows Wireless Network Report

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-10%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | Generating and reading the HTML wireless network report built into Windows. |
| **Sender** | **Bariu Azeez** |
| **Message** | Turn "the Wi-Fi drops sometimes" into dated disconnections with a reason, before escalating. |
| **Receiver** | Help desk technicians, network technicians, IT students. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · `netsh wlan show wlanreport` |
| **Reference** | [Microsoft Support: analyze the wireless network report](https://support.microsoft.com/en-us/help/4000462) · [Microsoft Learn: netsh wlan](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh-wlan) |

Part of [09 Wi-Fi Troubleshooting](README.md), step 7.

---

## Objective

An intermittent problem is rarely there when the technician looks. Windows keeps a history of Wi-Fi events, and `netsh wlan show wlanreport` turns the **last three days** of it into one HTML page: every connection session, how long it lasted, and why it ended. This is the evidence the network team needs.

## Prerequisites

- [ ] An **elevated** Command Prompt or PowerShell (the report fails without administrator rights)
- [ ] The approximate times the user noticed the drops
- [ ] Location services on, on Windows 11 24H2 and later (see [step 2 of the runbook](README.md#step-2--read-the-connection-state))

## Procedure

### Step 1 — Generate the report

```cmd
netsh wlan show wlanreport
```

**Expected result:** the command ends by printing the path of the HTML report it wrote, by default `C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html`. Open it in a browser.

[`Export-WifiDiagnostics.ps1 -IncludeWlanReport`](Export-WifiDiagnostics.ps1) runs this command and copies the report next to the other diagnostic files.

### Step 2 — Read the summary chart first

The top of the report is a chart of the Wi-Fi sessions over the three days, with a mark for each error. A **red circle** is an error: select it to see the details.

Look for a pattern before reading details:

| Pattern | Points to |
|---|---|
| Errors at the same hour every day | Something scheduled: a backup, an update, a nearby device, a busy period |
| Errors only when the laptop wakes up | Power management on the adapter |
| Errors spread randomly, on one day only | An event on that day: driver update, office move, access point change |
| Very short sessions one after the other | The PC keeps reconnecting: roaming, authentication or signal problem |

### Step 3 — Read the sections

| Section | What it tells you |
|---|---|
| **Report info**, **General system info**, **User info** | When the report was made, the PC model, BIOS and Windows version, the user |
| **Network adapters** | Every adapter with its driver: check the Wi-Fi driver date and version here |
| **Script output** | Saved results of `ipconfig /all`, `netsh wlan show all`, certificates and Wi-Fi profiles. Keys and passwords are not shown. |
| **Summary**: session successes and failures | How many sessions succeeded, failed or had warnings |
| **Summary**: disconnect reasons | The reasons Windows recorded for each disconnection, with how often they happened |
| **Summary**: session durations | Many short sessions means an unstable connection |
| **Wireless sessions** | One block per session: interface, profile, SSID, network type, and the disconnection reason |

### Step 4 — Match the reasons to an action

Read the exact wording of each disconnection reason in the report and classify it:

| The reason mentions | Probable origin | Next step |
|---|---|---|
| The user, a disconnect request, or turning Wi-Fi off | Normal: the user or Windows ended the session | Ignore, unless the user says they did nothing |
| Sleep, power, or the adapter being removed | PC power management | Adapter **Power Management** setting, see [step 7](README.md#step-7--drops-that-come-back-collect-evidence) |
| Signal lost, the access point, or a roaming attempt | Coverage or roaming | Rssi at the desk ([step 3](README.md#step-3--judge-the-signal)), report the location |
| Authentication, security, or a key | Profile, password, certificate or account | [Step 5](README.md#step-5--fix-a-connection-that-fails) of the runbook |
| The driver or an internal error | Wi-Fi driver | Update the driver from the PC manufacturer |

Copy the exact reason text and its time into the ticket: the wording is more useful to the network team than a summary.

## Verification

- [ ] The report covers the days and hours of the user's complaint
- [ ] Each disconnection in that period has a reason classified in the table above
- [ ] After the fix, a new report one or two days later shows no new error of the same kind

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `The requested operation requires elevation` | Command run without administrator rights | Open Command Prompt or PowerShell **as administrator** |
| Report is empty or very short | The PC was off, or on a cable, during the period | Ask the user to work on Wi-Fi for a day, then generate it again |
| The problem happened more than three days ago | The report keeps three days only | Generate it as soon as the user calls, and ask them to call during the next occurrence |

## Rollback

Nothing to undo: the report only reads the event history and writes an HTML file. Delete the copy from the desktop or the ticket folder when the ticket is closed, because it contains network names and hardware addresses.

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
