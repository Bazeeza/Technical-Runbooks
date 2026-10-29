# Testing a Copper Cable and Reading Wire Map Faults

![Level](https://img.shields.io/badge/Level-Beginner%20to%20Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-2%E2%80%9310%20min%20per%20cable-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Copper%20cabling-555?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | Testing a twisted-pair cable after termination, and identifying the fault when it fails. |
| **Sender** | **Bariu Azeez** |
| **Message** | Choose the right level of test, read each wire map fault, and know which repair it calls for. |
| **Receiver** | Field technicians, cabling technicians, help desk technicians, IT students. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · handheld cable testers, tone generator and probe |
| **Reference** | [Fluke Networks: wire map testing, it's not all about color](https://www.flukenetworks.com/blog/cabling-chronicles/wire-map-testing-it-s-not-all-about-color) · [Fluke Networks: diagnosing wiremap faults](https://www.flukenetworks.com/knowledge-base/microscanner2/diagnosing-wiremap-faults-microscanner2) · [Fluke Networks: how to use a network cable tester](https://www.flukenetworks.com/knowledge-base/how-to-use-network-cable-tester) · [Fluke Networks: 10GBASE-T field testing requirements](https://www.flukenetworks.com/knowledge-base/applicationstandards-articles-copper/10gbase-t-field-testing-requirements) |

Part of [08 Network Cabling and Termination](README.md), step 6.

---

## Objective

A cable that "looks right" can still be wrong: two pairs swapped, one wire on the wrong pin, or a split pair that passes a continuity check and fails under real traffic. Every terminated cable is tested **before** it is connected to equipment, and the result goes in the ticket or the cabling record.

## Prerequisites

- [ ] A cable tester with its **remote unit** (the part plugged at the far end)
- [ ] Two short known-good patch cords, to connect the tester to the jack and the patch panel
- [ ] The wiring scheme used on this site (T568A or T568B) set in the tester
- [ ] The cable label, to record the result against the right cable

## Three levels of test

| Level | Question it answers | Typical tool | When it is enough |
|---|---|---|---|
| **Verification** | Is every wire connected to the right pin, and how long is the cable? | Wire map tester with a remote unit | Patch cords, repairs, small offices, troubleshooting |
| **Qualification** | Can this link carry a given Ethernet speed (1 Gb/s, 10 Gb/s) and PoE? | Qualification tester | Checking that existing cabling supports an upgrade |
| **Certification** | Does this link meet every limit of its category (TIA-568 or ISO/IEC 11801)? | Certification analyzer | New installations, manufacturer warranties, handover to a client |

A help desk or field technician usually does **verification**. A cable that passes a wire map test is correctly wired; it is not proven to meet Cat 6 or Cat 6A performance. Only a certification test proves that.

## Procedure

### Step 1 — Prepare the tester

Set the wiring scheme (T568A or T568B, the same as the installation), the cable type, and the test limit if the tester has one. Check that the battery is charged: a low battery can give false results on some testers.

**Expected result:** the tester settings match the cable you are about to test.

### Step 2 — Connect both ends

Plug the main unit into one end (patch panel port) and the remote unit into the other end (wall jack), each through a short known-good patch cord.

To find which jack goes with which port on an unlabelled installation, use a **tone generator** on one end and the **probe** on the other: the probe sounds loudest on the right cable. Some testers can also make a connected switch port **blink**, which identifies the port without unplugging anything.

### Step 3 — Run the test and read the wire map

Run the automatic test. The wire map shows, for each pin at the near end, the pin it reaches at the far end.

**Expected result:** pins 1 to 8 each reach the same pin at the other end (straight-through), every pair is reported **pass**, and the length is plausible (a little more than the distance pulled, never more than 90 m for a permanent link).

### Step 4 — Identify the fault

| Fault | What the tester shows | Usual cause | Fix |
|---|---|---|---|
| **Open** | A wire reaches no pin at the far end | Wire not seated in the IDC or the plug, cut or damaged cable | Re-terminate the end where the tester locates the fault (distance to fault) |
| **Short** | Two or more wires connected together | Crushed cable, damaged connector, stray copper strand in the plug | Re-terminate; if the short is mid-cable, replace the cable |
| **Reversed pair** | The two wires of one pair are swapped (for example 1-2 arrives as 2-1) | Colours of one pair inverted at one end | Re-terminate that end, white-striped wire on the odd pin |
| **Crossed pairs** | Two pairs swapped (for example 1-2 arrives on 3-6) | One end in T568A and the other in T568B | Re-terminate one end with the site scheme |
| **Split pair** | Continuity correct pin to pin, but the wires of two pairs are mixed | Wires taken from two different pairs for pins 3-6, the same at both ends | Re-terminate both ends with the correct pairs |
| **Miswire** | Any other wrong pin assignment | Colour order not followed | Re-terminate the faulty end |

> [!WARNING]
> A **split pair** is the trap: a simple continuity tester shows it as good, because each pin reaches the same pin. But the signal travels on wires that are not twisted together, so crosstalk becomes very high and the link fails or drops to a lower speed. Only a tester that measures crosstalk detects it. Following the colour code exactly prevents it.

### Step 5 — Record the result

Save the result in the tester with the cable label as its name, or write it in the cabling record: label, date, length, pass/fail, tester used. A saved failed result is useful too: it shows what was repaired.

## Speeds and lengths to remember

| Category | Bandwidth | 1000BASE-T at 100 m | 10GBASE-T |
|---|---|---|---|
| **Cat 5e** | 100 MHz | Yes | Not supported |
| **Cat 6** | 250 MHz | Yes | Up to 37 m, and up to 55 m depending on alien crosstalk (TIA TSB-155) |
| **Cat 6A** | 500 MHz | Yes | Yes, 100 m |

The **100 m channel** is made of up to **90 m of permanent link** (patch panel to wall jack, inside the walls) plus up to **10 m of patch cords** in total at both ends.

## Verification

- [ ] Every cable tested with a pass result, both ends connected through the tester
- [ ] Length below 90 m for each permanent link
- [ ] Results saved or recorded against the cable label

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Tester shows "no remote" or every wire open | Remote unit not connected to this cable, or wrong jack | Tone and probe to find the right jack |
| Cable passes the wire map, but the PC links at 100 Mb/s only | Damaged pair (gigabit uses all four pairs), split pair, or a bad patch cord | Replace the patch cords first, then re-terminate; test with a qualification tester |
| Length far longer than expected | Cable coiled in the ceiling, or tester set to the wrong cable type (NVP) | Check the cable type setting; the extra cable is not a fault if under 90 m |
| Fault appears only when the cable is moved | Wires not fully seated, or the plug did not grip the jacket | Re-terminate with a strain relief on the jacket |

## Rollback

A failed termination is cut off and redone: keep a few centimetres of slack at each end for this. Never leave a failed cable connected "because it links": record it as failed and repair it.

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
