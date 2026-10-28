<#
.SYNOPSIS
    Clears stuck print jobs: stops the Print Spooler, empties the spool folder, restarts it and verifies.

.DESCRIPTION
    Use it when cancelling a job from the queue does not work (see runbook 06, step 3).
      1. lists the pending spool files (*.SPL and *.SHD);
      2. stops the Spooler service;
      3. deletes the files inside the spool folder (never the folder itself);
      4. starts the Spooler service again;
      5. checks that the service is Running and that the folder is empty.

    WARNING: this deletes the pending jobs of EVERY printer on the computer.
    On a print server, warn the users first.

.PARAMETER SpoolPath
    Spool folder. Defaults to the folder configured in the registry, or
    C:\Windows\System32\spool\PRINTERS if none is set.

.EXAMPLE
    .\Reset-PrintQueue.ps1 -WhatIf
    Lists the files that would be deleted, without stopping the service.

.EXAMPLE
    .\Reset-PrintQueue.ps1
    Clears the queue. Run from an elevated PowerShell.

.NOTES
    Author : Bariu Azeez
    Compatible with Windows PowerShell 5.1 and PowerShell 7.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string] $SpoolPath
)

if (-not $SpoolPath) {
    # The spool folder can be moved by an administrator: read the configured value first
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers'
    $SpoolPath = (Get-ItemProperty -Path $key -Name DefaultSpoolDirectory -ErrorAction SilentlyContinue).DefaultSpoolDirectory
    if (-not $SpoolPath) { $SpoolPath = Join-Path $env:SystemRoot 'System32\spool\PRINTERS' }
}

if (-not (Test-Path -Path $SpoolPath -PathType Container)) {
    Write-Error "Spool folder not found: $SpoolPath"
    exit 1
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $WhatIfPreference) {
    Write-Error 'Run this script from an elevated PowerShell (Run as administrator).'
    exit 1
}

$files = @(Get-ChildItem -Path $SpoolPath -File -ErrorAction SilentlyContinue)
Write-Host "Spool folder : $SpoolPath"
Write-Host "Pending files: $($files.Count)"
$files | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize

if (-not $PSCmdlet.ShouldProcess("Spooler service and $($files.Count) spool file(s)", 'Stop, delete pending jobs, restart')) {
    exit 0
}

Stop-Service -Name Spooler -Force -ErrorAction Stop
# The service can take a moment to release the files
(Get-Service -Name Spooler).WaitForStatus('Stopped', [TimeSpan]::FromSeconds(30))

Get-ChildItem -Path $SpoolPath -File | Remove-Item -Force -ErrorAction Continue

Start-Service -Name Spooler -ErrorAction Stop
(Get-Service -Name Spooler).WaitForStatus('Running', [TimeSpan]::FromSeconds(30))

$status = (Get-Service -Name Spooler).Status
$left = @(Get-ChildItem -Path $SpoolPath -File -ErrorAction SilentlyContinue).Count
Write-Host "Spooler status: $status"
Write-Host "Files left    : $left"

if ($status -ne 'Running' -or $left -gt 0) {
    Write-Warning 'The queue is not clean. Check Event Viewer > Microsoft > Windows > PrintService for a faulty driver.'
    exit 1
}
Write-Host 'Print queue cleared. Ask the user to print the document again.' -ForegroundColor Green
exit 0
