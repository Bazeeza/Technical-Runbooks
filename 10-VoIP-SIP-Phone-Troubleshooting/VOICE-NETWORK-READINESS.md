# Voice Network Readiness: Codecs, Bandwidth, QoS, Voice VLAN and PoE

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-20%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Cisco%20IOS%20%7C%20SIP-1BA0D7?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | What the network must provide so IP phones sound good: enough bandwidth, priority for voice, a voice VLAN and power. |
| **Sender** | **Bariu Azeez** |
| **Message** | Size the bandwidth of a set of calls, check the DSCP marking, the voice VLAN and the PoE budget of a switch before blaming a phone. |
| **Receiver** | Field and network technicians who install or support IP phones, telecom students. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · Cisco IOS CLI |
| **Reference** | [Cisco: Voice over IP, per call bandwidth consumption](https://www.cisco.com/c/en/us/support/docs/voice/voice-quality/7934-bwidth-consume.html) · [RFC 4594: Configuration guidelines for DiffServ service classes](https://www.rfc-editor.org/rfc/rfc4594) · [RFC 6716: Opus codec](https://www.rfc-editor.org/rfc/rfc6716) · [Cisco: Voice VLAN configuration example](https://www.cisco.com/c/en/us/support/docs/switches/catalyst-2950-series-switches/113260-voice-vlan-00.html) · ITU-T G.114 (one-way transmission time) |

---

## Objective

Choppy, robotic or delayed voice is rarely the phone's fault. Voice needs a small but **steady** flow of packets: a few lost or late packets are heard immediately, while a file download would not notice. This page lists what to check on the network side, with the numbers to compare against.

Back to the main runbook: [10 VoIP / SIP Phone Troubleshooting](README.md).

## Prerequisites

- [ ] The number of simultaneous calls the site needs (or the number of trunk channels)
- [ ] Read access to the access switch (`show` commands)
- [ ] The phone model's data sheet (PoE class)

---

## Quality targets

| Measure | Target for good voice | What the user hears beyond it |
|---|---|---|
| One-way delay (mouth to ear) | 150 ms or less (ITU-T G.114) | People talk over each other |
| Jitter (variation of delay) | Under about 30 ms | Choppy or robotic voice when the jitter buffer runs dry |
| Packet loss | Under 1 % | Missing syllables, clicks |

Jitter and loss come from **congestion**: an uplink or an Internet link full at the busy hour. That is why QoS and bandwidth planning matter more than raw speed.

## Codecs

| Codec | Audio band | Codec bit rate | Ethernet bandwidth per call, per direction (20 ms packets) | Notes |
|---|---|---|---|---|
| **G.711** (µ-law in North America, A-law elsewhere) | Narrowband, telephone quality | 64 kbps | 87.2 kbps | Universal, no compression, best for the local network and most SIP trunks |
| **G.722** | Wideband ("HD voice") | 64 kbps | Same as G.711 | Clearer voice between phones that support it; same bandwidth |
| **G.729** | Narrowband | 8 kbps | 31.2 kbps | Saves bandwidth on slow links; lower quality, poor for fax and tones |
| **Opus** | Narrowband to fullband, adaptive | 6 to 510 kbps, variable | Varies with the configured rate | Adapts to the network, common in softphones and WebRTC |

The Ethernet figure is larger than the codec rate because every 20 ms packet also carries RTP, UDP, IP and Ethernet headers. Bandwidth is needed **in each direction**: on a symmetric link, 10 G.711 calls need about 872 kbps up **and** 872 kbps down, before any VPN overhead.

> [!NOTE]
> Both ends must share a codec. When they do not, the call fails with `488 Not Acceptable Here`, or the PBX **transcodes** (converts) between codecs, which costs CPU and some quality. See [Reading a SIP call](SIP-CALL-FLOW.md).

## QoS marking: DSCP

Voice packets are marked in the IP header so every router and switch on the path can serve them first.

| Traffic | DSCP name | DSCP value | Notes |
|---|---|---|---|
| Voice media (RTP) | **EF** (Expedited Forwarding) | **46** | Same in RFC 4594 and vendor designs: put in a priority queue |
| Call signaling (SIP) | CS3 | 24 | Common in Cisco designs; RFC 4594 recommends CS5 (40). Follow the site QoS policy |
| Everything else from the PC | Default | 0 | Unless the site policy says otherwise |

Most IP phones mark EF and CS3 by default (a setting in the phone or in its provisioning template). Marking only helps where the network **trusts** it and has a priority queue: on the LAN switches, and on the WAN router before a slow link. The public Internet ignores DSCP, which is why voice over a plain Internet link depends on having spare bandwidth.

To see the marking, capture a call with Wireshark on a mirrored port and read **Differentiated Services Field** in the IP header of RTP packets.

## Voice VLAN

The phone and the PC share one cable and one switch port, but not one VLAN:

```mermaid
flowchart LR
    PC[PC<br/>untagged frames] --> PH[IP phone<br/>built-in switch]
    PH -->|"data: untagged, VLAN 10<br/>voice: tagged 802.1Q, VLAN 20"| SW[Access switch port<br/>switchport voice vlan 20]
    SW -->|trunk| CORE[Network]
```

1. The switch tells the phone which VLAN to use for voice: **CDP** for Cisco phones, **LLDP-MED** for most other brands (`lldp run` on the switch), or DHCP options on some systems.
2. The phone tags its own frames with VLAN 20 and a priority; it passes the PC's frames untagged, so they land in the access VLAN 10.
3. Voice is in its own subnet: separate DHCP scope, easy to prioritize and to filter.

Check on the switch:

```text
show interfaces GigabitEthernet1/0/7 switchport
show cdp neighbors GigabitEthernet1/0/7 detail
show lldp neighbors GigabitEthernet1/0/7 detail
```

**Expected result:** `Access Mode VLAN: 10`, `Voice VLAN: 20`, and the phone listed as a neighbour. A phone that boots into VLAN 10 and gets a **data** address did not learn the voice VLAN: check that CDP or LLDP is enabled on the port.

The full port configuration is in the [Cisco switch baseline](../11-Cisco-Switch-Baseline/README.md).

## Power over Ethernet

| Standard | PoE type | Power at the switch port | Power available at the device |
|---|---|---|---|
| IEEE 802.3af (PoE) | Type 1 | 15.4 W | 12.95 W |
| IEEE 802.3at (PoE+) | Type 2 | 30 W | 25.5 W |
| IEEE 802.3bt (PoE++) | Type 3 | 60 W | 51 W |
| IEEE 802.3bt (PoE++) | Type 4 | 90 W | 71.3 W |

Most desk phones fit in 802.3af; a phone with a colour screen and an expansion module may need PoE+. The switch also has a **total power budget**: a 24-port switch cannot always give full power to every port at once.

```text
show power inline
show power inline GigabitEthernet1/0/7 detail
```

**Expected result:** the port shows `on` with the power drawn and the device class. `off`, `faulty` or `power-deny` means the device asked for more than the port or the remaining budget can give.

> [!TIP]
> A phone that reboots when its expansion module is plugged in, or several phones that go dark when a new access point is connected, point to the PoE budget, not to the phones.

---

## Verification

- [ ] Bandwidth for the expected number of simultaneous calls, in each direction, is below the link capacity at the busy hour
- [ ] RTP packets are marked EF (46) in a capture
- [ ] The phone is in the voice VLAN with an address from the voice scope
- [ ] `show power inline` shows the phone powered, with budget left on the switch

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Voice choppy only at busy hours | Congested uplink or Internet link, no priority queue | Check link usage; ask the network team for QoS on that link |
| Phone gets an address in the data subnet | Voice VLAN not learned (CDP or LLDP off, or not supported) | Enable CDP or `lldp run`; check the phone's VLAN setting |
| Phone does not power on, PC behind it works | PoE off on the port, budget exhausted, or non-PoE switch | `show power inline`; use a PoE injector as a test |
| Calls fine on site, poor over the VPN | VPN overhead plus a slow home connection | Use G.711 only where bandwidth allows, or a lower-rate codec for remote users |

## Rollback

This page only checks the network. Changes to QoS, VLANs or PoE are made by the network team, with their own change procedure.

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
