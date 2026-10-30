# Port Security and Err-Disabled Ports: Read, Recover, Prevent

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-5%E2%80%9315%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Cisco%20IOS%20%7C%20IOS%20XE-1BA0D7?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | A user port that stops working because port security or BPDU guard reacted. |
| **Sender** | **Bariu Azeez** |
| **Message** | Find why a port is blocked or err-disabled, bring it back safely, and decide whether the protection or the user was right. |
| **Receiver** | Help desk and field technicians with read access to the switch, junior network technicians. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · Cisco IOS CLI |
| **Reference** | [Cisco: Port Security, Catalyst 9300 Security Configuration Guide (IOS XE 17.9)](https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst9300/software/release/17-9/configuration_guide/sec/b_179_sec_9300_cg/port_security.html) · [Cisco: Harden IOS Devices](https://www.cisco.com/c/en/us/support/docs/ip/access-lists/13608-21.html) |

---

## Objective

The [baseline](README.md) protects every user port with **port security** (a maximum number of MAC addresses) and **BPDU guard** (no switch may be plugged into a user port). When one of them reacts, the user only sees "the network is down". This page explains what the switch did, how to prove it and how to recover without simply switching the protection off.

## Prerequisites

- [ ] Console or SSH access to the switch, privileged EXEC (`enable`) for the recovery steps
- [ ] The port number (from the wall jack label and the patch panel, see [runbook 08](../08-Network-Cabling-and-Termination/PATCH-PANEL-AND-LABELING.md))
- [ ] What was plugged in: PC only, phone and PC, a small switch, a dock

---

## The three violation modes

| Mode | Traffic from a new MAC address | Log and counter | Port state | Typical use |
|---|---|---|---|---|
| `protect` | Dropped | **None** | Stays up | Rarely: violations are invisible |
| `restrict` | Dropped | Syslog message, SNMP trap, counter increases | Stays up | User ports in the baseline: known devices keep working |
| `shutdown` (default) | Port stops | Syslog message, counter increases | **err-disabled**, LED off | Sensitive ports where any extra device must stop everything |

> [!NOTE]
> The baseline sets `maximum 3` on user ports: the PC, the IP phone, and room for a phone that is first seen in the data VLAN while it boots. A user who adds a small unmanaged switch with two more devices goes over the limit.

## Step 1 — See the port state

```text
show interfaces status
show interfaces status err-disabled
```

**Expected result:** a working port shows `connected` with its VLAN. A port blocked by a violation in `shutdown` mode, or by BPDU guard, shows `err-disabled`. The second command adds the **reason** (`psecure-violation`, `bpduguard`, `link-flap`...).

## Step 2 — Read the port security counters

```text
show port-security
show port-security interface GigabitEthernet1/0/7
show port-security address
```

| Field | What it tells you |
|---|---|
| **Port Security** | `Enabled` |
| **Port Status** | `Secure-up`, or `Secure-shutdown` after a violation in `shutdown` mode |
| **Violation Mode** | `Restrict` on baseline user ports |
| **Maximum MAC Addresses** / **Total MAC Addresses** | Limit and current count: equal means the next new device is refused |
| **Security Violation Count** | Increases at each refused frame |
| **Last Source Address:Vlan** | The MAC address that caused the last violation |

In `restrict` mode the port stays `connected`, so this command is the only way to see that a device is being refused.

## Step 3 — Identify the extra device

```text
show mac address-table interface GigabitEthernet1/0/7
show cdp neighbors GigabitEthernet1/0/7 detail
show logging | include PSECURE|BPDUGUARD
```

The first six hex digits of a MAC address (the OUI) identify the manufacturer: a phone, a dock, a printer, a consumer switch. CDP (or LLDP) shows Cisco phones and switches by name. The log gives the time of the violation, to match with what the user did.

| What you find | Decision |
|---|---|
| A new PC replaced the old one | Legitimate: clear the old address (step 4) |
| A dock with its own network card, plus the PC | Legitimate: the user should use one network connection, not both |
| A small switch or a home router under the desk | Not allowed: remove it, then recover the port |
| An unknown device | Do not recover the port: escalate as a possible security incident |

## Step 4 — Recover the port

**Clear learned addresses** (for example after a PC replacement):

```text
clear port-security dynamic interface GigabitEthernet1/0/7
```

**Bring an err-disabled port back**, once the cause is removed:

```text
configure terminal
interface GigabitEthernet1/0/7
 shutdown
 no shutdown
end
```

**Expected result:** `show interfaces status` shows the port `connected` again within a few seconds (no spanning tree delay, thanks to `portfast`).

> [!WARNING]
> Never fix a violation by removing `switchport port-security` or `spanning-tree bpduguard enable` from the port. The protection did its job: remove the cause, then recover the port, and write both in the ticket.

## Step 5 — Optional: automatic recovery

A site may decide that err-disabled ports come back on their own after a delay:

```text
configure terminal
errdisable recovery cause psecure-violation
errdisable recovery cause bpduguard
errdisable recovery interval 300
end
show errdisable recovery
```

If the cause is still plugged in, the port is disabled again after 300 seconds. This is a site policy decision, not a help desk one: without it, a port stays err-disabled until someone recovers it by hand.

---

## Verification

- [ ] `show interfaces status` shows the port `connected` in the right VLAN
- [ ] `show port-security interface` shows a total below the maximum and no new violations
- [ ] The user's PC and phone both work (phone registered, PC has an address in the data VLAN)
- [ ] The ticket names the device that caused the violation and what was done with it

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Port `err-disabled`, reason `bpduguard` | A switch, or a PC bridging two adapters, sent spanning tree frames | Remove the device, recover the port |
| Phone works, PC behind it does not | Maximum reached by the phone in two VLANs plus the PC | Check `show port-security address`; the baseline value 3 covers this case |
| Violations every morning, no new device | A PC with a randomized or changing MAC address | Check the adapter settings, or the dock adding its own address |
| Port `err-disabled`, reason `link-flap` | Damaged cable or failing network card | [Cable testing](../08-Network-Cabling-and-Termination/CABLE-TESTING.md), then recover the port |

## Rollback

Recovering a port does not change the configuration. If a site decides to raise the maximum on one port, the change is one line (`switchport port-security maximum 4`) and is undone the same way; record the reason in the ticket and in the port description.

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
