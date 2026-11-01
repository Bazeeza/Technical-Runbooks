<#
.SYNOPSIS
    Collects read-only facts about the Outlook client of the current user, for an Outlook ticket.

.DESCRIPTION
    Answers the first questions of most Outlook tickets without opening Outlook:

      - Which Outlook is installed: classic Outlook (Microsoft 365 Apps, Click-to-Run),
        the new Outlook for Windows, or both, and the Office version and update channel URL
      - Which classic Outlook profiles exist for the current user, and which one is the default
      - Which Outlook data files (.ost and .pst) exist, how large they are and when they changed
      - How much free space is left on the drive that holds the data files
      - Whether Outlook is running now

    The script reads the registry and the file system only. It changes nothing, does not
    open the data files, and does not contact Microsoft 365. Run it as the user who has the
    problem (not as another administrator account), since profiles and data files are per user.

.PARAMETER OutputPath
    Optional. Path of a text file where the same report is saved for the ticket.

.EXAMPLE
    .\Get-OutlookClientInfo.ps1
    Shows the report on screen.

.EXAMPLE
    .\Get-OutlookClientInfo.ps1 -OutputPath "$env:USERPROFILE\Desktop\outlook-info.txt"
    Shows the report and saves it to a text file on the desktop.

.NOTES
    Author : bazeeza
    Tested : Windows PowerShell 5.1 on Windows 11
    Source : https://learn.microsoft.com/en-us/microsoft-365-apps/outlook/configuration/cached-exchange-mode
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Get-RegistryValue {
    param([string]$Key, [string]$Name)
    try {
        $item = Get-ItemProperty -LiteralPath $Key -Name $Name -ErrorAction Stop
        return $item.$Name
    }
    catch {
        return $null
    }
}

# --- Installed clients ---------------------------------------------------------------
$c2rKey      = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
$officeVer   = Get-RegistryValue -Key $c2rKey -Name 'VersionToReport'
$channelUrl  = Get-RegistryValue -Key $c2rKey -Name 'UpdateChannel'
if (-not $channelUrl) { $channelUrl = Get-RegistryValue -Key $c2rKey -Name 'CDNBaseUrl' }
$products    = Get-RegistryValue -Key $c2rKey -Name 'ProductReleaseIds'
$platform    = Get-RegistryValue -Key $c2rKey -Name 'Platform'

$classicPath = Get-RegistryValue -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE' -Name '(default)'
$newOutlook  = $null
try {
    $newOutlook = Get-AppxPackage -Name 'Microsoft.OutlookForWindows' -ErrorAction Stop | Select-Object -First 1
}
catch {
    Write-Verbose ('Get-AppxPackage failed: {0}' -f $_.Exception.Message)
}

$clients = [pscustomobject]@{
    ClassicOutlookPath = $(if ($classicPath -and (Test-Path -LiteralPath $classicPath)) { $classicPath } else { 'Not found' })
    OfficeVersion      = $(if ($officeVer) { $officeVer } else { 'Not a Click-to-Run installation, or not installed' })
    OfficeProducts     = $products
    OfficePlatform     = $platform
    UpdateChannelUrl   = $channelUrl
    NewOutlook         = $(if ($newOutlook) { 'Installed, version {0}' -f $newOutlook.Version } else { 'Not installed' })
    OutlookRunning     = [bool](Get-Process -Name 'OUTLOOK', 'olk' -ErrorAction SilentlyContinue)
}

# --- Classic Outlook profiles (per user) ----------------------------------------------
$outlookKey     = 'HKCU:\Software\Microsoft\Office\16.0\Outlook'
$defaultProfile = Get-RegistryValue -Key $outlookKey -Name 'DefaultProfile'
$profiles = @()
$profilesKey = Join-Path -Path $outlookKey -ChildPath 'Profiles'
if (Test-Path -LiteralPath $profilesKey) {
    $profiles = @(Get-ChildItem -LiteralPath $profilesKey | ForEach-Object {
        [pscustomobject]@{
            Profile   = $_.PSChildName
            IsDefault = ($_.PSChildName -eq $defaultProfile)
        }
    })
}

# --- Data files ------------------------------------------------------------------------
$folders = @(
    (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Outlook')
    (Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'Outlook Files')
)
$dataFiles = @()
foreach ($folder in $folders) {
    if (Test-Path -LiteralPath $folder) {
        $dataFiles += @(Get-ChildItem -LiteralPath $folder -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -eq '.ost' -or $_.Extension -eq '.pst' } |
            ForEach-Object {
                [pscustomobject]@{
                    Type          = $_.Extension.TrimStart('.').ToUpperInvariant()
                    Name          = $_.Name
                    SizeGB        = [math]::Round($_.Length / 1GB, 2)
                    LastWriteTime = $_.LastWriteTime
                    Folder        = $_.DirectoryName
                }
            })
    }
}

$driveName = (Split-Path -Path $env:LOCALAPPDATA -Qualifier).TrimEnd(':')
$drive = Get-PSDrive -Name $driveName -PSProvider FileSystem -ErrorAction SilentlyContinue
$freeGB = $(if ($drive) { [math]::Round($drive.Free / 1GB, 1) } else { $null })

# --- Notes for the technician ------------------------------------------------------------
$notes = New-Object -TypeName System.Collections.Generic.List[string]
if ($clients.ClassicOutlookPath -eq 'Not found' -and -not $newOutlook) {
    $notes.Add('No Outlook client found for this user. Outlook on the web is the fallback.')
}
if ($clients.ClassicOutlookPath -ne 'Not found' -and $profiles.Count -eq 0) {
    $notes.Add('Classic Outlook is installed but this user has no profile yet: it is created at the first start.')
}
if ($profiles.Count -gt 1 -and -not $defaultProfile) {
    $notes.Add('Several profiles and no default: Outlook asks which profile to use at each start.')
}
foreach ($file in $dataFiles) {
    if ($file.Type -eq 'OST' -and $file.SizeGB -ge 40) {
        $notes.Add(('{0} is {1} GB: the default OST limit is 50 GB. Reduce the "Download email for the past" period or archive.' -f $file.Name, $file.SizeGB))
    }
    if ($file.Type -eq 'PST') {
        $notes.Add(('{0} is a local PST file: it is not on the server. Make sure it is backed up, or import it into the mailbox or archive.' -f $file.Name))
    }
}
if ($null -ne $freeGB -and $freeGB -lt 10) {
    $notes.Add(('Only {0} GB free on drive {1}: Outlook data files need room to grow and to be rebuilt.' -f $freeGB, $driveName))
}
if ($notes.Count -eq 0) {
    $notes.Add('Nothing unusual found in the local client. Continue with the account checks of runbook 15.')
}

# --- Report ------------------------------------------------------------------------------
$report = New-Object -TypeName System.Text.StringBuilder
[void]$report.AppendLine(('Outlook client report - {0} - {1}' -f $env:USERNAME, (Get-Date -Format 'yyyy-MM-dd HH:mm')))
[void]$report.AppendLine('')
[void]$report.AppendLine('Clients')
[void]$report.AppendLine(($clients | Format-List | Out-String -Width 200).Trim())
[void]$report.AppendLine('')
[void]$report.AppendLine(('Classic Outlook profiles (default: {0})' -f $(if ($defaultProfile) { $defaultProfile } else { 'none' })))
if ($profiles.Count -gt 0) {
    [void]$report.AppendLine(($profiles | Format-Table -AutoSize | Out-String -Width 200).Trim())
} else {
    [void]$report.AppendLine('  none')
}
[void]$report.AppendLine('')
[void]$report.AppendLine(('Data files (free space on {0}: {1} GB)' -f $driveName, $freeGB))
if ($dataFiles.Count -gt 0) {
    [void]$report.AppendLine(($dataFiles | Format-Table -AutoSize Type, Name, SizeGB, LastWriteTime | Out-String -Width 200).Trim())
} else {
    [void]$report.AppendLine('  none')
}
[void]$report.AppendLine('')
[void]$report.AppendLine('Notes')
foreach ($note in $notes) { [void]$report.AppendLine(('  - {0}' -f $note)) }

$text = $report.ToString()
Write-Output $text

if ($OutputPath -and $PSCmdlet.ShouldProcess($OutputPath, 'Save the Outlook client report')) {
    Set-Content -LiteralPath $OutputPath -Value $text -Encoding UTF8
    Write-Output ('Report saved to {0}' -f $OutputPath)
}
