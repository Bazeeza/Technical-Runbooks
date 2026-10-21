<#
.SYNOPSIS
    Installs a standard list of applications with winget, then verifies each one.

.DESCRIPTION
    For each winget package ID:
      1. skips it if it is already installed;
      2. installs it silently;
      3. checks with "winget list" that it is really present (an exit code alone is not proof).
    Every action is written to a log file, and a summary table is shown at the end.

.PARAMETER Apps
    winget package IDs to install. Defaults to a typical office workstation list.

.PARAMETER LogPath
    Log file location. Defaults to C:\Temp\Install-StandardApps-<date>.log

.EXAMPLE
    .\Install-StandardApps.ps1 -WhatIf
    Shows what would be installed without changing anything.

.EXAMPLE
    .\Install-StandardApps.ps1 -Apps 'Mozilla.Firefox','7zip.7zip'

.NOTES
    Author : Bariu Azeez
    Run from an elevated PowerShell for machine-wide installations.
    winget is designed to run in a user session; for deployment as SYSTEM, use Intune or another deployment tool.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]] $Apps = @(
        'Mozilla.Firefox',
        'Google.Chrome',
        '7zip.7zip',
        'Adobe.Acrobat.Reader.64-bit',
        'Notepad++.Notepad++',
        'VideoLAN.VLC'
    ),
    [string] $LogPath = "C:\Temp\Install-StandardApps-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

function Write-Log {
    param([string] $Message, [string] $Level = 'INFO')
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogPath -Value $line -WhatIf:$false
    $color = switch ($Level) { 'ERROR' { 'Red' } 'WARN' { 'Yellow' } 'OK' { 'Green' } default { 'Gray' } }
    Write-Host $line -ForegroundColor $color
}

function Test-AppInstalled {
    param([string] $Id)
    # "winget list" returns exit code 0 only when the package is found
    winget list --id $Id --exact --accept-source-agreements --disable-interactivity *> $null
    return ($LASTEXITCODE -eq 0)
}

# Prerequisite: winget must be available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error 'winget is not available. Update "App Installer" from the Microsoft Store.'
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) -WhatIf:$false | Out-Null
Write-Log "Start on $env:COMPUTERNAME by $env:USERNAME - $($Apps.Count) application(s)"

$results = foreach ($id in $Apps) {
    if (Test-AppInstalled -Id $id) {
        Write-Log "$id is already installed, skipped" 'OK'
        [pscustomobject]@{ Application = $id; Result = 'Already installed' }
        continue
    }

    if (-not $PSCmdlet.ShouldProcess($id, 'winget install')) {
        [pscustomobject]@{ Application = $id; Result = 'Would be installed' }
        continue
    }

    Write-Log "Installing $id ..."
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity *> $null
    $code = $LASTEXITCODE

    if (Test-AppInstalled -Id $id) {
        Write-Log "$id installed and verified (exit code $code)" 'OK'
        [pscustomobject]@{ Application = $id; Result = 'Installed' }
    }
    else {
        Write-Log "$id FAILED (exit code $code)" 'ERROR'
        [pscustomobject]@{ Application = $id; Result = "FAILED ($code)" }
    }
}

$results | Format-Table -AutoSize
$failed = @($results | Where-Object Result -like 'FAILED*').Count
Write-Log "End - $failed failure(s). Log: $LogPath" ($(if ($failed) { 'WARN' } else { 'OK' }))
exit $failed
