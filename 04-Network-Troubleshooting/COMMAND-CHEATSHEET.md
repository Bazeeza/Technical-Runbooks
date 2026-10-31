# Network Command Cheat Sheet (Windows · Linux · Cisco IOS)

| Element | Content |
|---|---|
| **Referent** | Equivalent network diagnostic commands on Windows, Linux and Cisco IOS. |
| **Sender** | **Bariu Azeez** |
| **Message** | Find the right command quickly, whatever the system in front of you. |
| **Receiver** | Help desk and network technicians. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing |
| **Reference** | [Windows commands](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands) · `man ip`, `man ss` · Cisco IOS command references |

---

## Objective

Keep one page open during a diagnosis instead of searching for syntax. Use it with the [troubleshooting runbook](README.md).

## Configuration and addressing

| Task | Windows | Linux | Cisco IOS |
|---|---|---|---|
| Show IP configuration | `ipconfig /all` | `ip a` | `show ip interface brief` |
| Show interfaces and link state | `Get-NetAdapter` | `ip link` | `show interfaces status` |
| Show routing table | `route print` | `ip route` | `show ip route` |
| Show default gateway | `ipconfig` | `ip route show default` | `show ip route 0.0.0.0` |
| Renew DHCP lease | `ipconfig /release` then `/renew` | `sudo dhclient -r && sudo dhclient` (or `nmcli con up <name>`) | — |
| Show ARP table (IP ↔ MAC) | `arp -a` | `ip neigh` | `show arp` |
| Show MAC address table | — | — | `show mac address-table` |
| Show VLANs | — | — | `show vlan brief` |
| Show access, voice VLAN and trunk mode of a port | — | — | `show interfaces <port> switchport` |
| Show trunks and allowed VLANs | — | — | `show interfaces trunk` |
| Show blocked ports and the reason | — | — | `show interfaces status err-disabled` |
| Show PoE power per port | — | — | `show power inline` |

The configuration behind these Cisco commands is explained in [11 Cisco Switch Baseline](../11-Cisco-Switch-Baseline/README.md).

## Connectivity

| Task | Windows | Linux | Cisco IOS |
|---|---|---|---|
| Test reachability | `ping 1.1.1.1` | `ping -c 4 1.1.1.1` | `ping 1.1.1.1` |
| Continuous ping | `ping -t 1.1.1.1` | `ping 1.1.1.1` (stop with `Ctrl+C`) | `ping 1.1.1.1 repeat 1000` |
| Trace the path | `tracert 1.1.1.1` | `traceroute 1.1.1.1` or `tracepath` | `traceroute 1.1.1.1` |
| Path with loss statistics | `pathping 1.1.1.1` | `mtr 1.1.1.1` | — |
| Test a TCP port | `Test-NetConnection host -Port 443` | `nc -zv host 443` | `telnet host 443` |

## DNS

| Task | Windows | Linux |
|---|---|---|
| Resolve a name | `nslookup example.com` | `dig example.com` or `nslookup example.com` |
| Ask a specific DNS server | `nslookup example.com 1.1.1.1` | `dig @1.1.1.1 example.com` |
| Query a record type | `Resolve-DnsName example.com -Type MX` | `dig example.com MX` |
| Clear the DNS cache | `ipconfig /flushdns` | `sudo resolvectl flush-caches` |
| Show DNS servers in use | `Get-DnsClientServerAddress` | `resolvectl status` |

## Sessions and ports

| Task | Windows | Linux | Cisco IOS |
|---|---|---|---|
| Listening ports + process | `netstat -ano` or `Get-NetTCPConnection -State Listen` | `sudo ss -tulpn` | `show control-plane host open-ports` |
| Find the process for a PID | `tasklist /fi "PID eq 1234"` | `ps -p 1234 -o comm=` | — |
| Firewall state | `Get-NetFirewallProfile` | `sudo ufw status verbose` | `show access-lists` |
| Test a TCP port from another machine | `Test-NetConnection <host> -Port 22` | `nc -zv <host> 22` | `telnet <host> 22` |
| Ports published by containers | — | `docker ps --format 'table {{.Names}}\t{{.Ports}}'` | — |

> [!TIP]
> On a Linux server, a container port listed on `0.0.0.0` by `ss` is reachable even when `ufw` denies it: see [Docker ports and the firewall](../12-Linux-Server-Hardening/DOCKER-PORT-BINDING.md).

## Capture

| Task | Windows | Linux |
|---|---|---|
| Capture packets | Wireshark | `sudo tcpdump -i eth0 -n` |
| Capture only one host and port | Wireshark filter `ip.addr==10.0.0.5 && tcp.port==443` | `sudo tcpdump -i eth0 host 10.0.0.5 and port 443` |
| Save to a file for Wireshark | — | `sudo tcpdump -i eth0 -w capture.pcap` |

> [!WARNING]
> Capture traffic only on networks you are authorized to analyze: captures can contain passwords and personal data.

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
