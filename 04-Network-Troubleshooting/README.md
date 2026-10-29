# Network Troubleshooting: "I Have No Internet"

![Level](https://img.shields.io/badge/Level-Beginner%20to%20Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-10%E2%80%9330%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-555?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | Structured diagnosis of a workstation that cannot reach the network, the Internet or a specific service. |
| **Sender** | **Bariu Azeez** |
| **Message** | Test the network layer by layer, from the cable to the application, so the fault is located with proof instead of guesses. |
| **Receiver** | Help desk technicians, network technicians, IT students. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · Windows commands, Linux equivalents in the [cheat sheet](COMMAND-CHEATSHEET.md) |
| **Reference** | [Microsoft: TCP/IP troubleshooting](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/tcpip-troubleshooting) · [Test-NetConnection](https://learn.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection) · Cisco CCNA troubleshooting methodology |

---

## Objective

"No Internet" can mean a cable, a DHCP failure, a gateway, DNS, a firewall or a server outage. The **bottom-up method** tests each layer of the OSI model in order: a layer can only work if the layers below it work. In a few minutes, the technician knows **which layer fails** and either fixes it or escalates with evidence.

## Prerequisites

- [ ] Access to the workstation (on site or by remote control)
- [ ] A terminal: PowerShell or Command Prompt (administrator for the repair commands)
- [ ] The expected network values, if known: subnet, gateway, DNS servers

---

## Step 0 — Define the scope

Ask before testing:

| Question | Why |
|---|---|
| One user or many? | Many users → network or server issue, not this PC |
| Everything or one site/application? | One service only → DNS, firewall or that server |
| Wired, Wi-Fi or VPN? | Different paths, different causes |
| Since when, after what change? | Updates, move, new equipment |

## Decision flow

```mermaid
flowchart TD
    A[Step 1: Link up?<br/>cable, Wi-Fi] -->|No| A1[Physical layer:<br/>cable, port, Wi-Fi, driver]
    A -->|Yes| B[Step 2: Valid IP address?<br/>ipconfig /all]
    B -->|169.254.x.x or none| B1[DHCP problem]
    B -->|Yes| C[Step 3: Ping the gateway]
    C -->|Fails| C1[Local network:<br/>VLAN, switch port, gateway]
    C -->|OK| D[Step 4: Ping 1.1.1.1]
    D -->|Fails| D1[Routing or Internet access:<br/>router, firewall, ISP]
    D -->|OK| E[Step 5: Resolve a name<br/>nslookup]
    E -->|Fails| E1[DNS problem]
    E -->|OK| F[Step 6: Test the service port<br/>Test-NetConnection]
    F -->|Fails| F1[Firewall, proxy or server down]
    F -->|OK| G[Application or browser problem]
```

---

## Step 1 — Physical layer: is there a link?

- **Wired:** link LEDs on the network card and the switch port? Cable firmly clipped? Try another cable and another wall port.
- **Wi-Fi:** connected to the right network (SSID)? Airplane mode off? Signal strength correct?

```powershell
Get-NetAdapter | Select-Object Name, Status, LinkSpeed, MacAddress
```

**Expected result:** the adapter in use shows `Up`. `Disconnected` means a cable, port or Wi-Fi problem. `Disabled` means it was turned off: `Enable-NetAdapter -Name "Ethernet"`.

Check **LinkSpeed** too: a gigabit card linked at `100 Mbps` usually means a damaged pair in the cable, because gigabit needs all four pairs. Go deeper with [08 Network Cabling and Termination](../08-Network-Cabling-and-Termination/README.md) for a wired link, or [09 Wi-Fi Troubleshooting](../09-WiFi-Troubleshooting/README.md) for a wireless one.

## Step 2 — IP configuration: did the PC get an address?

```cmd
ipconfig /all
```

Read the active adapter:

| Field | Healthy | Problem |
|---|---|---|
| IPv4 Address | In the expected subnet, e.g. `192.168.10.25` | **`169.254.x.x`** = APIPA: no DHCP server answered |
| Subnet Mask | e.g. `255.255.255.0` | Wrong mask (static configuration error) |
| Default Gateway | e.g. `192.168.10.1` | Empty → no route outside the subnet |
| DNS Servers | The organization's DNS | Empty or unknown addresses |

**APIPA address (`169.254.x.x`)**: request a new lease.

```cmd
ipconfig /release
ipconfig /renew
```

Still `169.254`? The DHCP request does not reach the server: switch port in the wrong VLAN, DHCP scope full, missing DHCP relay (`ip helper-address` on the router), or DHCP server down. **Escalate to the network team** with this information.

## Step 3 — Local network: can the PC reach its gateway?

```cmd
ping 192.168.10.1
```

Replace with the gateway from step 2. Replies (`Reply from ...`) prove that the local network works. Timeouts mean a VLAN, switch or gateway problem. (Some gateways block ping: confirm with a second PC on the same network.)

## Step 4 — Beyond the network: is the Internet reachable by IP?

```cmd
ping 1.1.1.1
tracert 1.1.1.1
```

`ping` to a public IP **without** using a name separates routing from DNS. If it fails, `tracert` shows the last hop that answers: the fault is just after it (router, firewall, Internet provider).

## Step 5 — DNS: are names resolved?

```cmd
nslookup www.microsoft.com
```

**Expected result:** one or more addresses under `Addresses`. If step 4 worked but this fails, the problem is **DNS**:

```cmd
ipconfig /flushdns
nslookup www.microsoft.com 1.1.1.1
```

The second command asks a public DNS server directly. If it works, the configured DNS server is the problem: escalate. On a corporate network, internal names (e.g. `intranet.corp.example.com`) only resolve with the internal DNS servers.

## Step 6 — Service: is the port open?

```powershell
Test-NetConnection www.microsoft.com -Port 443
```

`TcpTestSucceeded : True` means the network path and the port are open: the remaining problem is the application (browser, proxy setting, certificate, account). `False` means a firewall blocks the port or the service is down.

Common ports: `80` HTTP · `443` HTTPS · `53` DNS · `22` SSH · `3389` RDP · `445` SMB (file shares) · `5060` SIP (VoIP) · `9100` and `631` printing (raw and IPP).

For a printer that does not answer, continue with [06 Printer Troubleshooting](../06-Printer-Troubleshooting/README.md#step-4--network-printer-is-it-reachable-on-its-port). For RDP, see [07 Remote Desktop with NLA](../07-Remote-Support/RDP.md).

---

## Quick repair (after diagnosis)

Use these only after identifying the problem; they reset the network stack and require a restart.

```cmd
netsh winsock reset
netsh int ip reset
```

Or **Settings → Network & internet → Advanced network settings → Network reset**.

## Information to give when escalating

```text
User / PC / location       :
Wired, Wi-Fi or VPN         :
Link speed / Wi-Fi Rssi     : e.g. "1 Gbps" or "-72 dBm on 5 GHz"
Scope                       : this PC only / several users / whole site
Last successful step        : e.g. "Ping gateway OK, ping 1.1.1.1 fails"
ipconfig /all output        : (attached)
tracert output              : (attached)
Actions already done        :
```

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
