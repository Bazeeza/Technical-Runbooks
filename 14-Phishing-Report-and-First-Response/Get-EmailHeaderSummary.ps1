<#
.SYNOPSIS
    Summarizes the internet headers of a suspicious e-mail: sender addresses, SPF, DKIM,
    DMARC and composite authentication results, the Received chain, and red flags.

.DESCRIPTION
    Reads a text file that contains the message headers (copied from Outlook, see
    READING-EMAIL-HEADERS.md) or a saved .eml file, and returns one object with:

      - From, Reply-To, Return-Path, Subject, Date and Message-ID
      - SPF, DKIM, DMARC and compauth results from the first Authentication-Results header
        (the one added by the receiving mail system, which is the one to trust)
      - The Received hops, listed from the origin to the final server
      - Findings: plain-language red flags, such as a Reply-To in another domain

    The script is read-only. It never opens links or attachments, never connects to the
    network, and only reads the header part of the file (everything before the first
    empty line). The result helps the technician fill the ticket; the final verdict
    belongs to the security team.

.PARAMETER Path
    Path to a .txt file with the headers, or to a .eml file. Accepts pipeline input.

.EXAMPLE
    .\Get-EmailHeaderSummary.ps1 -Path .\sample-headers-suspicious.txt
    Shows the summary and the findings for the fictional sample in this folder.

.EXAMPLE
    .\Get-EmailHeaderSummary.ps1 -Path .\headers.txt | Select-Object -ExpandProperty Findings
    Lists only the red flags.

.NOTES
    Author : bazeeza
    Tested : Windows PowerShell 5.1 on Windows 11
    Source : https://learn.microsoft.com/en-us/defender-office-365/message-headers-eop-mdo
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('FullName')]
    [string]$Path
)

begin {
    function Get-AddressDomain {
        param([string]$Value)
        if (-not $Value) { return $null }
        $match = [regex]::Match($Value, '[A-Za-z0-9._%+=-]+@([A-Za-z0-9.-]+\.[A-Za-z]{2,})')
        if ($match.Success) { return $match.Groups[1].Value.ToLowerInvariant() }
        return $null
    }

    function Get-Address {
        param([string]$Value)
        if (-not $Value) { return $null }
        $angle = [regex]::Match($Value, '<([^>]+@[^>]+)>')
        if ($angle.Success) { return $angle.Groups[1].Value.Trim() }
        $plain = [regex]::Match($Value, '[A-Za-z0-9._%+=-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')
        if ($plain.Success) { return $plain.Value }
        return $null
    }

    function Get-AuthValue {
        param([string]$Text, [string]$Name)
        if (-not $Text) { return $null }
        $match = [regex]::Match($Text, ('(?i)\b{0}=([A-Za-z]+)' -f [regex]::Escape($Name)))
        if ($match.Success) { return $match.Groups[1].Value.ToLowerInvariant() }
        return $null
    }

    # The registrable part of a domain, good enough to compare two addresses:
    # mail.contoso.com and contoso.com both give contoso.com.
    function Get-BaseDomain {
        param([string]$Domain)
        if (-not $Domain) { return $null }
        $labels = $Domain.Split('.')
        if ($labels.Count -le 2) { return $Domain }
        return ($labels[-2..-1] -join '.')
    }
}

process {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Error ('File not found: {0}' -f $Path)
        return
    }

    # Keep only the header block: it ends at the first empty line.
    $headerLines = New-Object -TypeName System.Collections.Generic.List[string]
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match '^\s*$') {
            if ($headerLines.Count -gt 0) { break } else { continue }
        }
        $headerLines.Add($line)
    }

    # Unfold continuation lines (RFC 5322: a line that starts with a space or a tab
    # belongs to the previous header), then split each header into name and value.
    $headers = New-Object -TypeName System.Collections.Generic.List[object]
    foreach ($line in $headerLines) {
        if ($line -match '^[ \t]' -and $headers.Count -gt 0) {
            $headers[$headers.Count - 1].Value = ('{0} {1}' -f $headers[$headers.Count - 1].Value, $line.Trim())
        }
        elseif ($line -match '^([!-9;-~]+):\s*(.*)$') {
            $headers.Add([pscustomobject]@{ Name = $Matches[1]; Value = $Matches[2].Trim() })
        }
    }

    if ($headers.Count -eq 0) {
        Write-Error ('No header found in {0}. Copy the full internet headers, not only the message body.' -f $Path)
        return
    }

    $first = {
        param([string]$Name)
        $item = $headers | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
        if ($item) { $item.Value } else { $null }
    }

    $from       = & $first 'From'
    $replyTo    = & $first 'Reply-To'
    $returnPath = & $first 'Return-Path'
    $authText   = & $first 'Authentication-Results'

    $fromAddress   = Get-Address -Value $from
    $fromDomain    = Get-AddressDomain -Value $fromAddress
    $replyDomain   = Get-AddressDomain -Value (Get-Address -Value $replyTo)
    $returnDomain  = Get-AddressDomain -Value (Get-Address -Value $returnPath)

    $spf      = Get-AuthValue -Text $authText -Name 'spf'
    $dkim     = Get-AuthValue -Text $authText -Name 'dkim'
    $dmarc    = Get-AuthValue -Text $authText -Name 'dmarc'
    $compauth = Get-AuthValue -Text $authText -Name 'compauth'

    # Received headers are added on top by each server: reverse them to read
    # the path from the origin to the mailbox.
    $received = @($headers | Where-Object { $_.Name -eq 'Received' })
    [array]::Reverse($received)
    $hops = @()
    $hopNumber = 0
    foreach ($item in $received) {
        $hopNumber++
        $fromHost = [regex]::Match($item.Value, '(?i)\bfrom\s+(\S+)')
        $byHost   = [regex]::Match($item.Value, '(?i)\bby\s+(\S+)')
        $stamp    = ''
        $semicolon = $item.Value.LastIndexOf(';')
        if ($semicolon -ge 0) { $stamp = $item.Value.Substring($semicolon + 1).Trim() }
        $hops += [pscustomobject]@{
            Hop  = $hopNumber
            From = $(if ($fromHost.Success) { $fromHost.Groups[1].Value } else { '' })
            By   = $(if ($byHost.Success) { $byHost.Groups[1].Value } else { '' })
            Date = $stamp
        }
    }

    # Red flags, in plain language for the ticket.
    $findings = New-Object -TypeName System.Collections.Generic.List[string]

    if (-not $authText) {
        $findings.Add('No Authentication-Results header: the headers may be incomplete, or the message did not come through a filtering service.')
    }
    else {
        if ($spf -and $spf -ne 'pass') {
            $findings.Add(('SPF = {0}: the sending server is not authorized by the domain of the envelope sender.' -f $spf))
        }
        if ($dkim -and $dkim -ne 'pass') {
            $findings.Add(('DKIM = {0}: the message has no valid signature from the sending domain.' -f $dkim))
        }
        if ($dmarc -and @('pass', 'bestguesspass') -notcontains $dmarc) {
            $findings.Add(('DMARC = {0}: the From domain is not confirmed by an aligned SPF or DKIM result.' -f $dmarc))
        }
        if ($compauth -eq 'fail') {
            $findings.Add('compauth = fail: Microsoft 365 could not confirm that the From address is genuine (possible spoofing).')
        }
    }

    if ($replyDomain -and $fromDomain -and (Get-BaseDomain $replyDomain) -ne (Get-BaseDomain $fromDomain)) {
        $findings.Add(('Reply-To domain ({0}) differs from the From domain ({1}): answers would go to someone else.' -f $replyDomain, $fromDomain))
    }
    if ($returnDomain -and $fromDomain -and (Get-BaseDomain $returnDomain) -ne (Get-BaseDomain $fromDomain)) {
        $findings.Add(('Return-Path domain ({0}) differs from the From domain ({1}): normal for some mailing services, suspicious with failed authentication.' -f $returnDomain, $fromDomain))
    }

    # A display name that contains another address: "it-support@contoso.com" <x@other.example>
    if ($from -and $fromAddress) {
        $displayName = $from.Replace($fromAddress, '')
        $nameAddress = [regex]::Match($displayName, '[A-Za-z0-9._%+=-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')
        if ($nameAddress.Success -and $nameAddress.Value -ne $fromAddress) {
            $findings.Add(('The display name shows {0} but the real sender is {1}.' -f $nameAddress.Value, $fromAddress))
        }
    }

    if ($findings.Count -eq 0) {
        $findings.Add('No red flag found in the headers. This does not prove the message is safe: check the links, the request and the sender through another channel.')
    }

    [pscustomobject]@{
        File        = (Resolve-Path -LiteralPath $Path).Path
        Subject     = & $first 'Subject'
        Date        = & $first 'Date'
        From        = $from
        ReplyTo     = $replyTo
        ReturnPath  = $returnPath
        MessageId   = & $first 'Message-ID'
        SPF         = $spf
        DKIM        = $dkim
        DMARC       = $dmarc
        CompAuth    = $compauth
        HopCount    = $hops.Count
        Hops        = $hops
        Findings    = $findings.ToArray()
    }
}
