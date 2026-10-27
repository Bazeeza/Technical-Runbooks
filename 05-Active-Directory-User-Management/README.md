# Active Directory User Account Management

![Level](https://img.shields.io/badge/Level-Beginner%20to%20Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-5%E2%80%9320%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%20Server%20AD%20DS-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | The most common help desk requests on Active Directory accounts: locked account, password reset, new employee, departure. |
| **Sender** | **Bariu Azeez** |
| **Message** | Handle each request quickly with PowerShell or the graphical console, **after** verifying the caller's identity, and leave a trace in the ticket. |
| **Receiver** | Help desk technicians with delegated rights on user accounts. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · PowerShell (ActiveDirectory module) |
| **Reference** | [ActiveDirectory PowerShell module](https://learn.microsoft.com/en-us/powershell/module/activedirectory/) · [Event 4740: account locked out](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-4740) |

---

## Objective

"I can't log in" is the most frequent help desk call. Solving it takes minutes, but **resetting a password for the wrong person gives an attacker the account**: social engineering by phone is a classic attack. This runbook makes identity verification the mandatory first step, then gives the exact commands for each request.

## Prerequisites

- [ ] An account with **delegated rights** on the users' OU (not a Domain Admin account for daily tasks)
- [ ] **RSAT: Active Directory** tools installed on the technician's PC:

```powershell
# Windows 10/11, administrator PowerShell
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Import-Module ActiveDirectory
```

- [ ] The organization's identity verification procedure and password policy

> In the examples, the user is `jdoe` and the domain is `corp.example.com`. Replace with real values.

---

## Step 0 — Verify the caller's identity (mandatory)

Before **any** change to an account:

1. **Never trust caller ID or the name given** alone.
2. Verify with the method defined by the organization, for example:
   - call back on the number registered in the directory, not the number given by the caller;
   - confirmation by the employee's manager;
   - in person with a photo ID card;
   - a code sent to an already registered MFA method.
3. Refuse and escalate to security if the caller pressures, cannot verify, or asks for an exception.
4. Write in the ticket **how** the identity was verified.

---

## Case 1 — Locked account

### Check the account state

```powershell
Get-ADUser jdoe -Properties LockedOut, Enabled, LastLogonDate, PasswordLastSet, PasswordExpired, BadLogonCount |
    Select-Object Name, Enabled, LockedOut, PasswordExpired, PasswordLastSet, LastLogonDate, BadLogonCount
```

| Value | Meaning |
|---|---|
| `LockedOut : True` | Too many wrong passwords: unlock (below) |
| `Enabled : False` | Account **disabled** on purpose (departure, leave): do not re-enable without approval |
| `PasswordExpired : True` | The password must be changed, not just unlocked |

### Unlock

```powershell
Unlock-ADAccount -Identity jdoe
```

### If the account locks again: find the source

Repeated lockouts usually come from an **old password saved somewhere**: phone mail app, mapped drive, Wi-Fi profile, scheduled task, second PC. The domain controller that holds the *PDC emulator* role records the event **4740** with the name of the source computer.

```powershell
$pdc = (Get-ADDomain).PDCEmulator
Get-WinEvent -ComputerName $pdc -FilterHashtable @{ LogName = 'Security'; Id = 4740 } -MaxEvents 50 |
    Where-Object { $_.Properties[0].Value -eq 'jdoe' } |
    Select-Object TimeCreated, @{ n = 'SourceComputer'; e = { $_.Properties[1].Value } }
```

Then remove or update the saved password on the source device.

## Case 2 — Password reset

After step 0 only:

```powershell
Set-ADAccountPassword -Identity jdoe -Reset -NewPassword (Read-Host -AsSecureString 'Temporary password')
Set-ADUser -Identity jdoe -ChangePasswordAtLogon $true
Unlock-ADAccount -Identity jdoe
```

- `Read-Host -AsSecureString` keeps the password out of the screen, the command history and the logs.
- The temporary password follows the policy, is **unique**, and is given through a secure channel (never by email to the account being reset).
- `ChangePasswordAtLogon` makes sure only the user knows the final password.

## Case 3 — New employee

```powershell
$params = @{
    Name                  = 'Jane Doe'
    GivenName             = 'Jane'
    Surname               = 'Doe'
    SamAccountName        = 'jdoe'
    UserPrincipalName     = 'jdoe@corp.example.com'
    Path                  = 'OU=Users,OU=Montreal,DC=corp,DC=example,DC=com'
    Title                 = 'Accountant'
    Department            = 'Finance'
    AccountPassword       = (Read-Host -AsSecureString 'Temporary password')
    ChangePasswordAtLogon = $true
    Enabled               = $true
}
New-ADUser @params

# Access is given through groups, never directly to a user
Add-ADGroupMember -Identity 'GRP-Finance' -Members jdoe
Get-ADPrincipalGroupMembership jdoe | Select-Object Name
```

- Create the account **only** from an approved request (HR or manager).
- Use groups by role (`GRP-Finance`), so access is consistent and easy to remove.
- Grant the minimum needed: no administrator group "just in case".

## Case 4 — Employee departure

Disable first, delete later: a disabled account can be restored if needed, a deleted one is much harder to recover.

```powershell
$date = Get-Date -Format 'yyyy-MM-dd'
Disable-ADAccount -Identity jdoe
Set-ADUser -Identity jdoe -Description "Disabled $date - ticket #12345"

# Remove group memberships (except Domain Users) after recording them in the ticket
Get-ADPrincipalGroupMembership jdoe | Where-Object Name -ne 'Domain Users' |
    ForEach-Object { Remove-ADGroupMember -Identity $_ -Members jdoe -Confirm:$false }

Move-ADObject -Identity (Get-ADUser jdoe).DistinguishedName -TargetPath 'OU=Disabled,DC=corp,DC=example,DC=com'
```

Then follow the organization's process: mailbox, files, devices returned, deletion after the retention period.

---

## Graphical alternative (ADUC)

Everything above can also be done in **Active Directory Users and Computers** (`dsa.msc`): right-click the user → **Reset Password** (with *User must change password at next logon* and *Unlock the user's account* checked), **Disable Account**, **Add to a group**, **Move**. PowerShell is faster, repeatable, and its exact commands can be pasted into the ticket.

## Verification

- [ ] The user logs in successfully (or the departed account can no longer log in)
- [ ] `Get-ADUser jdoe -Properties LockedOut, Enabled` shows the expected state
- [ ] The ticket records: identity verification method, actions taken, groups changed

## Useful searches

```powershell
Search-ADAccount -LockedOut | Select-Object Name, SamAccountName               # all locked accounts
Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly |           # inactive for 90+ days
    Select-Object Name, LastLogonDate
Search-ADAccount -PasswordNeverExpires -UsersOnly | Select-Object Name          # policy exceptions to review
```

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
