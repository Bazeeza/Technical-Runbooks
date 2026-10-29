<#
.SYNOPSIS
    Collects read-only Wi-Fi diagnostics into one folder that can be attached to a ticket.

.DESCRIPTION
    Runs the standard netsh wlan and IP commands and saves each output to its own text file:
    interface state, driver capabilities, nearby networks, saved profile names, IP configuration
    and network adapters. With -IncludeWlanReport (administrator rights required), it also
    generates the Windows wireless network report (last three days of Wi-Fi sessions) and copies
    the HTML file into the same folder.

    The script changes no setting. It never exports Wi-Fi keys: profiles are listed by name only.
    The output still contains network names (SSID) and hardware addresses (MAC/BSSID), so treat
    the folder as internal ticket data.

.PARAMETER OutputPath
    Folder where the files are written. Created if missing.
    Default: a WifiDiag-<computer>-<date> folder on the current user's desktop.

.PARAMETER IncludeWlanReport
    Also run "netsh wlan show wlanreport" and copy the HTML report. Needs an elevated session.

.EXAMPLE
    .\Export-WifiDiagnostics.ps1 -WhatIf
    Shows the folder and files that would be created, without running anything.

.EXAMPLE
    .\Export-WifiDiagnostics.ps1 -IncludeWlanReport
    Run from an elevated PowerShell: collects everything, including the wireless network report.

.NOTES
    Author : Bariu Azeez
    Tested : Windows PowerShell 5.1 on Windows 11
    Source : https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh-wlan
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$OutputPath = (Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath ('WifiDiag-{0}-{1}' -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd-HHmm'))),

    [switch]$IncludeWlanReport
)

$ErrorActionPreference = 'Stop'

# Each entry: output file name and the command that produces it.
$collections = @(
    @{ File = '01-wlan-interfaces.txt'; Command = { netsh.exe wlan show interfaces } }
    @{ File = '02-wlan-drivers.txt';    Command = { netsh.exe wlan show drivers } }
    @{ File = '03-wlan-networks.txt';   Command = { netsh.exe wlan show networks mode=bssid } }
    @{ File = '04-wlan-profiles.txt';   Command = { netsh.exe wlan show profiles } }
    @{ File = '05-ipconfig-all.txt';    Command = { ipconfig.exe /all } }
    @{ File = '06-net-adapters.txt';    Command = { Get-NetAdapter | Format-Table -AutoSize Name, InterfaceDescription, Status, LinkSpeed, MacAddress | Out-String -Width 200 } }
)

$wlanService = Get-Service -Name WlanSvc -ErrorAction SilentlyContinue
if (-not $wlanService) {
    Write-Warning 'The WLAN AutoConfig service (WlanSvc) is not installed: this computer has no Wi-Fi stack.'
    return
}
if ($wlanService.Status -ne 'Running') {
    Write-Warning ('The WLAN AutoConfig service is {0}. netsh wlan commands will fail until it runs: Start-Service WlanSvc' -f $wlanService.Status)
}

if ($PSCmdlet.ShouldProcess($OutputPath, 'Create diagnostics folder')) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

foreach ($item in $collections) {
    $target = Join-Path -Path $OutputPath -ChildPath $item.File
    if ($PSCmdlet.ShouldProcess($target, 'Save command output')) {
        try {
            & $item.Command 2>&1 | Out-File -FilePath $target -Encoding utf8
            Write-Verbose ('Saved {0}' -f $item.File)
        }
        catch {
            ('Command failed: {0}' -f $_.Exception.Message) | Out-File -FilePath $target -Encoding utf8
            Write-Warning ('{0}: {1}' -f $item.File, $_.Exception.Message)
        }
    }
}

if ($IncludeWlanReport) {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $identity
    $isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Warning 'The wireless network report needs an elevated PowerShell. Skipped; the other files are complete.'
    }
    elseif ($PSCmdlet.ShouldProcess('netsh wlan show wlanreport', 'Generate the wireless network report')) {
        $reportLog = Join-Path -Path $OutputPath -ChildPath '07-wlanreport-output.txt'
        netsh.exe wlan show wlanreport 2>&1 | Out-File -FilePath $reportLog -Encoding utf8

        $reportFile = Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\WlanReport\wlan-report-latest.html'
        if (Test-Path -Path $reportFile) {
            Copy-Item -Path $reportFile -Destination $OutputPath
        }
        else {
            Write-Warning ('Report not found at {0}. Read {1} for the path printed by netsh.' -f $reportFile, $reportLog)
        }
    }
}

if (-not $WhatIfPreference) {
    Get-ChildItem -Path $OutputPath | Select-Object Name, Length
    Write-Output ('Diagnostics saved to {0}' -f $OutputPath)
}
