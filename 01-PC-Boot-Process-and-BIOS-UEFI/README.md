# PC Boot Process and BIOS / UEFI Configuration

![Level](https://img.shields.io/badge/Level-Beginner-3fe0a0?style=flat-square)
![Time](https://img.shields.io/badge/Time-20%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Any%20x86%20PC-555?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | How a PC starts, from the power button to the Windows logon screen, and how to change firmware (BIOS/UEFI) settings safely. |
| **Sender** | **bazeeza** |
| **Message** | Understand each stage of the boot so a startup failure can be located quickly, then enter the firmware, change the boot order and check Secure Boot. |
| **Receiver** | Help desk and field technicians, IT students. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing |
| **Reference** | [Microsoft: Boot and UEFI](https://learn.microsoft.com/en-us/windows-hardware/drivers/bringup/boot-and-uefi) · [Microsoft: Secure Boot](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-secure-boot) · [Suspend-BitLocker](https://learn.microsoft.com/en-us/powershell/module/bitlocker/suspend-bitlocker) · Manufacturer manuals (Dell, HP, Lenovo) |

---

## Objective

A technician who knows the boot sequence can say **where** a PC stops ("no POST", "no boot device", "Windows crashes while loading") instead of guessing. This runbook explains the sequence, then shows how to enter the firmware, set the boot order to start from a USB key, and confirm that UEFI mode and Secure Boot are enabled (both required by Windows 11).

## Prerequisites

- [ ] Physical access to the PC and its power supply
- [ ] The firmware (BIOS) password, if the organization sets one
- [ ] Permission to change settings: on a managed fleet, firmware changes may be controlled centrally
- [ ] If the disk is encrypted with BitLocker: protection **suspended** before any firmware change, and the recovery key available

```powershell
manage-bde -status C:                                   # "Protection On" means BitLocker is active
Suspend-BitLocker -MountPoint 'C:' -RebootCount 1       # administrator; resumes after one restart
```

---

## The boot sequence

```mermaid
flowchart TD
    A[Power button] --> B[PSU stabilizes voltages<br/>sends Power Good]
    B --> C[CPU starts executing firmware<br/>stored on the motherboard]
    C --> D[POST: Power-On Self-Test<br/>CPU, RAM, GPU, keyboard]
    D -->|Failure| D1[Beep codes / LED codes<br/>no display]
    D --> E[Firmware reads the boot order]
    E --> F{Firmware mode}
    F -->|UEFI| G[EFI System Partition FAT32<br/>bootmgfw.efi]
    F -->|Legacy BIOS| H[MBR on first sector<br/>then bootmgr]
    G --> I[Windows Boot Manager]
    H --> I
    I --> J[winload.efi loads the kernel<br/>ntoskrnl.exe + boot drivers]
    J --> K[Session Manager smss.exe<br/>services start]
    K --> L[winlogon.exe<br/>logon screen]
```

| Stage | What happens | If it fails, you see |
|---|---|---|
| **Power** | The power supply (PSU) stabilizes voltages and signals the motherboard. | Nothing at all: no fans, no LEDs |
| **POST** | The firmware tests the essential hardware. | Beeps, blinking LED code, fans spin but black screen |
| **Boot device** | The firmware looks for a bootable disk following the boot order. | `No bootable device`, `Boot device not found` |
| **Boot manager** | Windows Boot Manager reads the boot configuration (BCD). | `BOOTMGR is missing`, `0xc000000f`, automatic repair loop |
| **Kernel and drivers** | Windows loads its kernel and drivers. | Blue screen (BSOD) with a stop code, spinning dots forever |
| **Logon** | Services start, then the logon screen appears. | Black screen with cursor, profile errors |

> [!TIP]
> Note the **last thing that worked**. "The Dell logo appears, then `No bootable device`" means POST passed and the problem is the disk or the boot order, not the RAM.

### UEFI vs legacy BIOS

| | UEFI (modern) | Legacy BIOS (old) |
|---|---|---|
| Partition table | **GPT** | MBR |
| Max boot disk size | No practical limit | 2 TB |
| Secure Boot | Yes | No |
| Windows 11 | **Required** | Not supported |

---

## Step 1 — Enter the firmware setup

### Option A — From Windows (most reliable)

Fast Startup often skips the keyboard detection window, so pressing a key at power-on may not work. From Windows:

1. **Settings → System → Recovery → Advanced startup → Restart now**
2. **Troubleshoot → Advanced options → UEFI Firmware Settings → Restart**

Or, in an **administrator** terminal:

```powershell
shutdown /r /fw /t 0   # restart directly into the firmware setup
```

### Option B — Key at power-on

Turn the PC on and tap the key repeatedly as soon as the logo appears.

| Manufacturer | Firmware setup | One-time boot menu |
|---|---|---|
| Dell | `F2` | `F12` |
| HP | `Esc` then `F10` | `Esc` then `F9` |
| Lenovo ThinkPad / ThinkCentre | `F1` (`Enter` first on some laptops) | `F12` |
| Lenovo IdeaPad | `F2` or the Novo button | `F12` |
| ASUS | `Del` or `F2` | `F8` (desktop) / `Esc` (laptop) |
| Acer | `F2` | `F12` (must be enabled in setup) |
| MSI | `Del` | `F11` |
| Gigabyte | `Del` | `F12` |

---

## Step 2 — Boot once from a USB key (preferred)

Use the **one-time boot menu** (table above) and pick the USB key. This avoids changing the permanent boot order, so the PC returns to normal on the next restart.

**Expected result:** the installer or tool on the USB key starts.

## Step 3 — Change the permanent boot order (if needed)

1. Enter the firmware setup.
2. Find **Boot**, **Boot Sequence** or **Boot Priority**.
3. Move the wanted device to the top. Keep **Windows Boot Manager** right after it.
4. **Save and exit** (often `F10`).

> [!WARNING]
> Once the job is done, put **Windows Boot Manager** back in first place. A forgotten USB key at the top of the list can block the next startup or start an unwanted installation.

## Step 4 — Check UEFI mode and Secure Boot

In Windows, run `msinfo32` and read the **System Summary**:

| Field | Expected value |
|---|---|
| BIOS Mode | `UEFI` |
| Secure Boot State | `On` |

In PowerShell (administrator):

```powershell
Confirm-SecureBootUEFI        # True = Secure Boot active, an error = legacy BIOS mode
Get-Tpm | Select-Object TpmPresent, TpmReady   # TPM 2.0 is also required by Windows 11
```

If Secure Boot is `Off`, enable it in the firmware under **Security** or **Boot → Secure Boot**.

> [!CAUTION]
> Never switch a working installation from Legacy to UEFI in the firmware without converting the disk first (`mbr2gpt /validate` then `mbr2gpt /convert`, from Windows). Otherwise Windows will not start. Suspend BitLocker before any firmware change, or the PC will ask for the recovery key.

---

## Verification

- [ ] The PC starts Windows normally after the changes
- [ ] `msinfo32` shows `UEFI` and Secure Boot `On`
- [ ] Windows Boot Manager is first in the boot order
- [ ] BitLocker protection is resumed (`manage-bde -status`)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| The setup key does nothing, Windows starts normally | Fast Startup skips the keyboard window | Use option A (`shutdown /r /fw /t 0`) |
| The USB key is not listed in the boot menu | Key created for legacy BIOS only, or USB boot disabled | Recreate the key in GPT/UEFI mode; enable USB boot in the firmware |
| The PC asks for the BitLocker recovery key after the change | Firmware setting changed while BitLocker was active | Enter the 48-digit key, then suspend BitLocker before the next change |
| `Confirm-SecureBootUEFI` returns `False` | UEFI mode, but Secure Boot is off | Turn Secure Boot on in the firmware (step 4) |
| `Confirm-SecureBootUEFI` returns an error | Legacy BIOS mode, or a PC without UEFI | Convert the disk with `mbr2gpt` before switching to UEFI (see the caution in step 4) |
| The PC does not start at all | Power, POST, disk or Windows fault | Follow the [no-boot troubleshooting guide](TROUBLESHOOTING.md) |

## Rollback

- **Boot order:** put **Windows Boot Manager** back in first place and save (`F10`).
- **Any other firmware setting:** most firmware setups offer **Load Optimized Defaults** or **Restore Defaults**; note the original values first, because defaults may disable settings the organization requires (TPM, Secure Boot, virtualization).
- **BitLocker:** if it was suspended without a restart count, resume it with `Resume-BitLocker -MountPoint 'C:'`.

---

<sub>Written by bazeeza · Found an error? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Report it here</a>.</sub>
