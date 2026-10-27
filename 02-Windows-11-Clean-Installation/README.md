# Windows 11 Clean Installation

![Level](https://img.shields.io/badge/Level-Beginner-3fe0a0?style=flat-square)
![Time](https://img.shields.io/badge/Time-60%E2%80%9390%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | Clean installation of Windows 11 from a bootable USB key on a PC whose disk will be erased. |
| **Sender** | **Bariu Azeez** |
| **Message** | Check compatibility, create the installation media, install Windows on a GPT disk in UEFI mode, and hand over a PC ready for the user. |
| **Receiver** | Help desk technicians preparing or reimaging a workstation. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing |
| **Reference** | [Windows 11 specifications](https://www.microsoft.com/en-us/windows/windows-11-specifications) · [Download Windows 11](https://www.microsoft.com/en-us/software-download/windows11) · [Windows client deployment](https://learn.microsoft.com/en-us/windows/deployment/) |

---

## Objective

Reinstall Windows 11 on a workstation (new disk, malware, corrupted system, change of user) and obtain a **clean, updated, activated** system. A clean install removes everything on the target disk: data protection comes first.

> [!NOTE]
> In a company, workstations are usually deployed with tools such as Intune/Autopilot, MDT or Configuration Manager. This manual procedure is the foundation those tools automate, and is still used for one-off repairs.

## Prerequisites

- [ ] **User data backed up and verified** (open a few files from the backup)
- [ ] A USB key of **8 GB or more** (it will be erased)
- [ ] Another working PC with Internet access to create the key
- [ ] The Windows edition and license to install (digital license, OEM key, or organization's volume activation)
- [ ] Network drivers for the target PC, on a second USB key (in case Windows does not detect the network card)
- [ ] BitLocker recovery key, if the disk is encrypted and data must be read first

---

## Step 1 — Check hardware compatibility

| Requirement | Minimum | How to check |
|---|---|---|
| Processor | 64-bit, 1 GHz, 2 cores, on Microsoft's supported list | `msinfo32` → Processor |
| RAM | 4 GB | `msinfo32` → Installed Physical Memory |
| Storage | 64 GB | Disk Management (`diskmgmt.msc`) |
| Firmware | UEFI with Secure Boot capability | `msinfo32` → BIOS Mode / Secure Boot State |
| TPM | Version 2.0 | `tpm.msc` → Specification Version |
| Graphics | DirectX 12 / WDDM 2.0 | `dxdiag` |

If UEFI, Secure Boot or TPM is disabled, enable it in the firmware: see [runbook 01](../01-PC-Boot-Process-and-BIOS-UEFI/README.md#5-check-uefi-mode-and-secure-boot). TPM is often called **Intel PTT** or **AMD fTPM** in the firmware menus.

## Step 2 — Create the installation USB key

On the working PC:

1. Download the **Media Creation Tool** from the official Microsoft page (link in the header). Never use an ISO from an unofficial source.
2. Run it, accept the license, choose language and edition, select **USB flash drive**, then pick the key.
3. Wait for the download and the creation to finish (15–30 min depending on the connection).

**Expected result:** the key is named `ESD-USB` and contains `setup.exe`, `boot`, `efi` and `sources`.

> [!TIP]
> **Rufus** (open source) is an alternative when starting from an ISO file. Choose partition scheme **GPT** and target system **UEFI (non CSM)**.

## Step 3 — Boot the target PC from the key

1. Plug the key into the target PC.
2. Open the **one-time boot menu** (`F12` on Dell and Lenovo, `Esc` then `F9` on HP; full table in [runbook 01](../01-PC-Boot-Process-and-BIOS-UEFI/README.md#2-enter-the-firmware-setup)).
3. Choose the entry starting with **UEFI:** followed by the key's name.

**Expected result:** the *Windows Setup* screen appears. Choosing an entry without `UEFI:` would start the installer in legacy mode and create an MBR disk incompatible with Windows 11.

## Step 4 — Run the installer

1. Choose language, time format and **keyboard** (e.g. *Canadian French* or *US*), then **Next → Install Windows 11**.
2. **Product key:** enter it, or choose **I don't have a product key** if the PC already has a digital license (it activates automatically once online).
3. Choose the **edition** matching the license (Home, Pro...). A wrong edition will not activate.
4. Accept the license, then choose the **custom installation** (clean install), not the upgrade.

## Step 5 — Prepare the disk

On the disk selection screen:

1. Identify the target disk by its **size** (Disk 0 is usually the internal disk).
2. Select each partition of that disk and click **Delete** until only **Unallocated space** remains.
3. Select the unallocated space and click **Next**. Windows creates the needed partitions itself (EFI, MSR, Windows, Recovery) in **GPT**.

> [!CAUTION]
> Deleting partitions erases their data **permanently**. Disconnect any other internal or external disk if there is any doubt about which one is the target.

**Expected result:** files are copied, then the PC restarts several times. Remove the USB key at the first restart if the PC starts the installer again.

## Step 6 — Initial setup (OOBE)

1. Region and keyboard layout.
2. **Network:** connect to Wi-Fi or Ethernet. If no network is detected, install the network driver from the second USB key.
3. Device name, then account type:
   - **Personal device:** Microsoft account (required by Windows 11 Home).
   - **Company device (Pro/Enterprise):** **Set up for work or school** to join Entra ID / Intune, or a local account then domain join (step below).
4. Set a PIN, review the privacy settings with the organization's policy in mind (turn off what is not needed).

**Expected result:** the Windows desktop appears.

## Step 7 — Finish the workstation

Follow the full [post-installation checklist](POST-INSTALL-CHECKLIST.md): updates, drivers, activation, security, naming, domain join.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "This PC can't run Windows 11" | TPM or Secure Boot disabled | Enable them in the firmware, restart setup |
| "Windows cannot be installed to this disk. The selected disk is of the MBR partition style" | Installer started in legacy mode | Restart and choose the boot entry starting with **UEFI:** |
| No disk listed | Missing storage driver (Intel RST/VMD) | **Load driver** with the manufacturer's storage driver on a USB key, or switch SATA mode to AHCI on an **empty** disk |
| Endless restart into setup | USB key still first in boot order | Remove the key, put Windows Boot Manager first |
| No network during OOBE | Missing network driver | Install it from the second USB key (`Load driver` or through File Explorer once on the desktop) |

---

<sub>Written by Bariu Azeez · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
