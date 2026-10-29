# Patch Panels, Keystone Jacks and Labeling

![Level](https://img.shields.io/badge/Level-Beginner-3fe0a0?style=flat-square)
![Time](https://img.shields.io/badge/Time-5%20min%20per%20port-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Copper%20cabling-555?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | Punching down a cable on a patch panel or a keystone jack (110-style IDC), and labeling both ends. |
| **Sender** | **Bariu Azeez** |
| **Message** | Terminate the permanent link cleanly at both ends and label it so any technician finds the right port without tracing the cable. |
| **Receiver** | Field technicians, cabling technicians, help desk technicians, IT students. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · punch-down tool (110 blade), patch panel, keystone jacks |
| **Reference** | [Black Box: copper cable installation guidelines](https://www.blackbox.com/insights/blackbox-explains/inner/detail/copper-cable/copper-cable-for-every-environment/copper-cable-installation-guidelines) · [Fluke Networks: T568A vs T568B](https://www.flukenetworks.com/knowledge-base/application-or-standards-articles-copper/differences-between-wiring-codes-t568a-vs) · [Cabling Installation & Maintenance: boiling down the 606-A labeling standard](https://www.cablinginstall.com/connectivity/article/16465694/boiling-down-the-606-a-labeling-standard) |

Part of [08 Network Cabling and Termination](README.md), step 5.

---

## Objective

A structured cabling installation has three parts: the **patch panel** in the rack, the **permanent link** inside the walls, and the **wall jack** at the desk. Patch cords connect the panel to the switch and the jack to the PC. When the panel and the jack are terminated with the same scheme and labeled with the same identifier, a technician can go from "desk 2-14 has no network" to the right switch port in a minute.

```mermaid
flowchart LR
    SW[Switch port] ---|patch cord| PP[Patch panel port<br/>label 1A-B02]
    PP ---|permanent link<br/>max 90 m in the walls| WJ[Wall jack<br/>label 1A-B02]
    WJ ---|patch cord| PC[PC or phone]
```

## Prerequisites

- [ ] A **punch-down tool** with a 110 blade (the cutting side of the blade faces the waste end of the wire)
- [ ] Patch panel or keystone jacks of the **same category** as the cable (Cat 6 cable on Cat 6 jacks)
- [ ] The site wiring scheme: **T568A or T568B**, printed on the panel or the jack label
- [ ] A label printer or pre-printed labels, and the site labeling plan
- [ ] Cable ties with a hook-and-loop closure (Velcro type) for bundles

## Procedure

### Step 1 — Route and dress the cable at the panel

Bring the cable to the back of its port, with a service loop of slack in the rack or the ceiling. Keep the bend radius at least **4 times the cable diameter** for UTP and do not pull with more than **110 N (about 25 lbf)**.

**Expected result:** the cable reaches the port without tension and without a sharp bend.

### Step 2 — Strip the jacket

Remove about **25 mm (1 in.)** of jacket with a cable stripper, without nicking the wires. Cut the rip cord and the plastic spline (Cat 6) flush with the jacket.

**Expected result:** four intact pairs, jacket ending right at the back of the IDC.

### Step 3 — Seat the pairs in the IDC

Follow the colour labels **printed on the panel or the jack** for the chosen scheme (A or B). Untwist each pair only as much as needed to reach its slot: **no more than 13 mm (0.5 in.)** of untwisted wire for Cat 5e and higher.

**Why:** the twists are what cancel crosstalk. Every millimetre untwisted beyond the limit adds noise, and a long untwist can fail a Cat 6 certification on its own.

### Step 4 — Punch down

Place the punch-down tool straight on each wire, cutting side towards the outside, and press until the tool clicks. The tool seats the wire in the IDC and cuts the excess in one motion.

**Expected result:** each wire is fully down in its slot, the excess is cut off cleanly, and no copper is exposed outside the IDC.

> [!TIP]
> Keystone jacks and patch panels from different manufacturers place the colours differently at the back. Always follow the colour label on the part itself, not a photo of another model.

### Step 5 — Terminate the other end with the same scheme

At the desk, terminate the keystone jack the same way, with the **same scheme** as the panel. Mixing A at one end and B at the other creates **crossed pairs**, detected by the [cable test](CABLE-TESTING.md).

### Step 6 — Label both ends

Put the **same identifier** on the patch panel port and on the wall plate, and on the cable itself near each end if the site requires it.

A common format, from the ANSI/TIA-606-A labeling standard for a horizontal link, is **fs-an**:

| Part | Meaning | Example |
|---|---|---|
| **f** | Floor | `1` |
| **s** | Telecommunications space on that floor | `A` |
| **a** | Patch panel in that space | `B` |
| **n** | Port number on the panel | `02` |

Example: **`1A-B02`** is floor 1, telecommunications room A, patch panel B, port 02. The wall jack at the desk carries the same `1A-B02`.

Labeling rules:

- **Printed labels**, never handwritten: they stay readable for years.
- The **same identifier at both ends**, so nobody needs a tone generator for a labeled cable.
- The labeling plan is **written down** and kept with the site documentation, with the switch port each panel port is patched to.

### Step 7 — Dress the bundle

Group the cables of a panel with hook-and-loop ties, **loosely**: a tie that deforms the jacket changes the geometry of the pairs and can degrade performance. Never use staples on network cable.

## Verification

- [ ] Each port passes the [cable test](CABLE-TESTING.md) between the panel port and its wall jack
- [ ] Panel port and wall jack carry the same printed identifier
- [ ] Untwist at each IDC is within 13 mm; no copper visible outside the IDC
- [ ] The labeling plan is updated with the new ports and their switch ports

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Open on one wire after punching down | Wire not fully seated, or cut by the blade turned the wrong way | Re-punch the wire; if it was cut short, re-terminate the cable |
| Crossed pairs between panel and jack | One end in T568A, the other in T568B | Re-terminate one end with the site scheme |
| Cat 6 link fails certification, wire map is correct | Too much untwist or jacket stripped too far | Re-terminate with less untwist |
| Port label does not match the switch documentation | Plan not updated after a move | Trace with tone and probe or the switch port blink, then update the plan |

## Rollback

A bad termination is cut off and redone with fresh cable from the service loop. Remove the label of a port that is abandoned, and mark it as free in the labeling plan.

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
