# Reading the Headers of a Suspicious E-mail

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-10%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Outlook%20%7C%20Microsoft%20365-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | The internet headers of an e-mail: the hidden lines that record who sent it, through which servers, and whether the sender's domain vouched for it. |
| **Sender** | **bazeeza** |
| **Message** | Copy the headers without touching the links or the attachments, read the From, Reply-To and Return-Path addresses, the SPF, DKIM, DMARC and compauth results, and the Received chain, then write the red flags in the ticket. |
| **Receiver** | Help desk technicians who receive a "is this e-mail real?" question. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · Windows PowerShell 5.1 |
| **Reference** | [Microsoft Learn: Anti-spam message headers](https://learn.microsoft.com/en-us/defender-office-365/message-headers-eop-mdo) · [Microsoft Support: View internet message headers in Outlook](https://support.microsoft.com/office/cd039382-dc6e-4264-ac74-c048563d212c) · [RFC 5322, Internet Message Format](https://www.rfc-editor.org/rfc/rfc5322) · [Canadian Centre for Cyber Security: Spotting malicious e-mail messages (ITSAP.00.100)](https://www.cyber.gc.ca/en/guidance/spotting-malicious-email-messages-itsap00100) |

Back to [14 Phishing Report and First Response](README.md).

---

## Why the headers matter

The name and the address shown in the message list are written by the sender, so they can say anything. The headers are added by the **mail servers** along the way, and the `Authentication-Results` line is written by the receiving mail system after it checked the sender's domain. Reading them answers two questions with facts instead of impressions:

1. Did the message really come from the domain it claims?
2. If someone answers, where does the answer go?

> [!WARNING]
> Work only on the **headers**. Do not click a link, open an attachment, scan a QR code or reply, even "to test". To read where a link goes, hover over it and read the address shown at the bottom of the window, or let the security team analyze it.

## Step 1 — Copy the headers

| Client | Path |
|---|---|
| Classic Outlook for Windows | Double-click the message to open it in its own window › **File** › **Properties** › the **Internet headers** box. Select all, copy. |
| New Outlook for Windows | Open the message › **More actions** (`...`) › **View** › **View message details**. Copy. |
| Outlook on the web | **More actions** (`...`) › **View** › **View message details**. Copy. |

Paste the text into Notepad and save it as `headers.txt` in the ticket folder. A saved `.eml` file works too.

**Expected result:** a text file that starts with several `Received:` lines and contains `From:`, `Subject:` and, in Microsoft 365, `Authentication-Results:`.

## Step 2 — Run the summary script

[`Get-EmailHeaderSummary.ps1`](Get-EmailHeaderSummary.ps1) reads only the header block (it stops at the first empty line), never connects to the network, and lists the red flags in plain language.

```powershell
.\Get-EmailHeaderSummary.ps1 -Path .\headers.txt | Format-List
.\Get-EmailHeaderSummary.ps1 -Path .\headers.txt | Select-Object -ExpandProperty Hops | Format-Table
```

To practice, run it on the fictional [`sample-headers-suspicious.txt`](sample-headers-suspicious.txt): it should report a soft-failed SPF, no DKIM signature, no DMARC record, `compauth=fail`, a Reply-To in another domain and a display name that pretends to be an internal address.

Microsoft's [Message Header Analyzer](https://mha.azurewebsites.net/) gives the same information in a web page. Paste headers there only if your organization allows it, since they contain internal server names and addresses.

**Expected result:** the sender fields, the authentication results, the hop list and a **Findings** list.

## Step 3 — Compare the three sender addresses

| Header | Who writes it | What to check |
|---|---|---|
| `From:` | The sender (shown to the user) | Display name and real address: `"IT Support" <it-support@contoso-helpdesk.example>` is **not** `contoso.com`. Look for added words, swapped letters (`rn` for `m`), or a different top-level domain. |
| `Reply-To:` | The sender | Answers go here. A Reply-To in another domain than the From is a classic sign of credential or invoice fraud. |
| `Return-Path:` | The sending server (envelope sender, `5321.MailFrom`) | Bounces go here, and SPF checks this domain. Mailing services often use their own domain here, so a difference is normal **only** when SPF, DKIM and DMARC pass. |

## Step 4 — Read the authentication results

The first (top-most) `Authentication-Results` header is added by the receiving system: it is the one to trust. Lower ones may have been written by the sender.

| Check | Question it answers | Results to note |
|---|---|---|
| **SPF** | Is the sending server allowed to send for the `smtp.mailfrom` domain? | `pass` is good. `fail` (`-all`) and `softfail` (`~all`) mean the server is not listed; `none` means the domain publishes no SPF record. |
| **DKIM** | Is the message signed by the domain in `header.d`, and unchanged since? | `pass` is good. `none` means not signed; `fail` means the signature does not match. |
| **DMARC** | Does an SPF or DKIM pass **align** with the `From:` domain the user sees? | `pass` (or `bestguesspass` when the domain has no DMARC record) is good. `fail` with a From domain the user trusts means spoofing. `none` means no DMARC record. |
| **compauth** | Microsoft 365's overall verdict on the From address | `pass` or `softpass` is good; `fail` (with a `reason` code) means Microsoft 365 could not confirm the sender. |

Passing checks prove only that the message came from the domain in the From address, **not** that the domain is honest: an attacker can register `contoso-helpdesk.example` and pass SPF, DKIM and DMARC for it. Always read the domain itself.

The `X-Forefront-Antispam-Report` header shows how Microsoft 365 classified the message: `CAT:PHSH` is phishing, `CAT:SPOOF` spoofing, `SFV:SPM` spam, `SFV:SFE` a message delivered because the sender was in the user's Safe Senders list.

## Step 5 — Follow the Received chain

Each server adds a `Received:` line **on top**, so read them from the bottom to the top to go from the origin to the mailbox. The script does this for you (`Hops`, hop 1 is the origin).

- The first hop shows the server that really sent the message: does its name belong to the claimed sender?
- The dates should increase by seconds or minutes. A gap of hours or a date in the future points to a forged or delayed line.

## Step 6 — Write the findings in the ticket

```text
Suspicious e-mail analysis
Reported by / time      :
Subject                 :
From (display / address):
Reply-To / Return-Path  :
SPF / DKIM / DMARC      :
compauth / CAT          :
Origin server (hop 1)   :
Red flags               :
Other recipients        : (same subject or sender in other mailboxes, if known)
User action             : none / clicked / entered credentials / opened attachment
Headers file attached   : yes
```

Then continue with the [first response checklist](FIRST-RESPONSE-CHECKLIST.md) for the user's action.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| The script says "No header found" | Only the body was copied, or the file starts with an empty line from the paste | Copy again from **Internet headers** or **View message details**; the file must start with `Received:` or another header |
| No `Authentication-Results` line | Message forwarded by the user (new headers), or an internal message | Ask the user to report the original with the **Report** button instead of forwarding it |
| Everything passes but the message is clearly fake | Attacker uses a look-alike domain they own | Report it anyway: authentication proves the domain, not the intent |
| Legitimate newsletter with a different Return-Path | Mailing service that sends on behalf of the company | Normal when SPF, DKIM and DMARC pass |

---

<sub>Written by bazeeza · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
