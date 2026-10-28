# Remote Desktop (RDP) with Network Level Authentication

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-15%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011%20Pro%20%7C%20Windows%20Server-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | Enabling, restricting and testing Remote Desktop on a Windows workstation or server. |
| **Sender** | **Bariu Azeez** |
| **Message** | Open RDP only to the people and networks that need it, with Network Level Authentication, and prove it works. |
| **Receiver** | Help desk and system administration technicians. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · Windows Settings, PowerShell, `mstsc` |
| **Reference** | [Microsoft Learn: Enable Remote Desktop on your PC](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/remotepc/remote-desktop-allow-access) · [Change the Remote Desktop listening port](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/remotepc/change-listening-port) · [Test-NetConnection](https://learn.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection) |

Back to [07 Remote Support](README.md).

---

## Objective

Remote Desktop opens a **full Windows session** on another computer, with the technician's own account. Unlike Quick Assist, nobody needs to be in front of the screen, which makes it the tool for servers and after-hours work, and also a favourite target of attackers. The end state: RDP enabled with **NLA**, reachable only from the internal network or a VPN, and limited to named accounts.

## Key facts

| Item | Value |
|---|---|
| Default port | **TCP 3389** (and UDP 3389 for better performance) |
| Can act as RDP **host** | Windows Pro, Enterprise, Education, Windows Server. **Windows Home cannot**, it can only connect to others |
| Who can connect | Members of the local **Administrators** group and of **Remote Desktop Users** |
| Client | Remote Desktop Connection (`mstsc.exe`) or the Windows App |
| NLA | The user authenticates **before** the remote session is created |

**Why NLA matters:** without NLA, the computer starts a full logon screen for anyone who reaches port 3389, before knowing who they are. With NLA, the credentials are checked first, which uses fewer resources on the host and reduces the exposure to attacks on the logon screen. Microsoft recommends keeping it enabled.

## Prerequisites

- [ ] Administrator rights on the target computer (to change the setting)
- [ ] An edition that can host RDP (not Windows Home)
- [ ] The list of accounts that really need access, ideally a **security group** rather than individual users
- [ ] Network access from the technician's PC to the target: same network, or through the organization's **VPN**

> [!WARNING]
> Never forward port 3389 from the Internet to a workstation. Exposed RDP ports are scanned and attacked constantly. Reach RDP through a VPN or a Remote Desktop Gateway.

---

## Procedure

### Step 1 — Enable Remote Desktop with NLA

**Settings → System → Remote Desktop** → turn **Remote Desktop** on → **Confirm**. Expand the setting and check that **Require devices to use Network Level Authentication to connect** is checked.

The same, in an elevated PowerShell (useful on many PCs or on Server Core):

```powershell
$ts = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
Set-ItemProperty -Path $ts -Name fDenyTSConnections -Value 0
Set-ItemProperty -Path "$ts\WinStations\RDP-Tcp" -Name UserAuthentication -Value 1
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
```

| Line | What it does |
|---|---|
| `fDenyTSConnections = 0` | Allows incoming Remote Desktop connections (1 = denied) |
| `UserAuthentication = 1` | Requires Network Level Authentication |
| `Enable-NetFirewallRule` | Opens the built-in Windows Firewall rules for RDP |

> [!NOTE]
> `-DisplayGroup 'Remote Desktop'` only matches an English Windows. On a French or other localized system, use the language-neutral group name instead: `Enable-NetFirewallRule -Group '@FirewallAPI.dll,-28752'`. The same applies to step 3 and to the rollback.

**Expected result:** the Settings page shows Remote Desktop **On** and NLA checked.

### Step 2 — Allow only the right accounts

In **Settings → System → Remote Desktop → Remote Desktop users**, add the account or group. Or:

```powershell
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member 'EXAMPLE\Helpdesk-RDP'
Get-LocalGroupMember -Group 'Remote Desktop Users'
```

**Why a group:** when a technician joins or leaves the team, you change one AD group instead of every computer.

### Step 3 — Restrict the firewall rule to internal addresses

The built-in rule accepts connections from any address on the selected profile. Limit it to the IT subnet or the VPN range:

```powershell
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' |
    Set-NetFirewallRule -RemoteAddress '192.0.2.0/24'
```

Replace `192.0.2.0/24` with the real management or VPN subnet. In a domain, this is usually set once by Group Policy instead of on each PC.

### Step 4 — Test from the technician's PC

```powershell
Test-NetConnection pc-0001.corp.example.com -Port 3389
mstsc /v:pc-0001.corp.example.com
```

**Expected result:** `TcpTestSucceeded : True`, then the credential prompt **before** the remote desktop appears (that is NLA working).

### Step 5 — Close the session properly

Use **Start → user icon → Sign out** in the remote session. Closing the window with the **X** only *disconnects*: the session keeps running on the host with the applications open, and it holds a license or a seat on a server.

---

## Verification

- [ ] `Test-NetConnection <host> -Port 3389` succeeds from an allowed address, fails from another network
- [ ] The credential prompt appears before the remote desktop (NLA)
- [ ] `Get-LocalGroupMember 'Remote Desktop Users'` lists only the intended accounts
- [ ] The connection and sign-out are written in the ticket

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "Remote Desktop can't connect to the remote computer" | RDP disabled, PC off or asleep, firewall blocks 3389, wrong name | `Test-NetConnection -Port 3389`, then check step 1 and the firewall rule |
| No Remote Desktop page in Settings, or it cannot be turned on | Windows Home edition | Upgrade the edition, or use Quick Assist |
| "The connection was denied because the user account is not authorized" | Account not in **Remote Desktop Users** or Administrators | Add it (step 2) |
| An old client cannot connect after NLA was enabled | The client does not support NLA | Update the client; do not disable NLA permanently |
| The name does not resolve, the IP works | DNS problem | See [04 Network Troubleshooting](../04-Network-Troubleshooting/README.md), step 5 |
| Works on the LAN, not from home | No VPN, or the firewall rule is limited to the LAN range | Connect the VPN first; add the VPN range to the rule if approved |

## Rollback

Turn **Remote Desktop** off in Settings, or:

```powershell
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 1
Disable-NetFirewallRule -DisplayGroup 'Remote Desktop'
```

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
