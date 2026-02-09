# NOROM.SYS - DOS Device Driver for ROM Disable

## Overview

**NOROM.SYS** is a DOS device driver that disables the ROM at E000:0000 on the Tandy 1000 TL/2 by setting bit 4 of Port FFEA during system boot. This frees 64KB of upper memory (E000-EFFF) for DOS UMB (Upper Memory Block) allocation.

## Status

✅ **VERIFIED WORKING** on Tandy 1000 TL/2 hardware (see src/OUT.LOG)

## How It Works

1. Driver loads during CONFIG.SYS processing
2. Reads current Port FFEA value (typically 0xC8)
3. Sets bit 4 to disable ROM (value becomes 0xD8)
4. Writes back to Port FFEA
5. Verifies bit 4 persisted
6. Displays status message
7. Unloads itself (zero resident memory footprint)

## Installation

### Step 1: Build the Driver

```batch
CD C:\TL2BIOS\SRC
BUILD.BAT
```

This creates **NOROM.SYS** in the src directory.

### Step 2: Copy to Boot Drive

```batch
COPY NOROM.SYS C:\DOS\
```

Or place it anywhere on your boot drive.

### Step 3: Edit CONFIG.SYS

Add this line to your CONFIG.SYS (must be loaded BEFORE EMM386):

```
DEVICE=C:\DOS\NOROM.SYS
```

### Step 4: Configure EMM386 for UMBs

After NOROM.SYS, add EMM386 with E000-EFFF included:

```
DEVICE=C:\DOS\HIMEM.SYS
DEVICE=C:\DOS\NOROM.SYS
DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF
DOS=HIGH,UMB
```

**Important:** NOROM.SYS must load BEFORE EMM386.EXE!

### Step 5: Reboot and Verify

```batch
C:\> MEM /C /P
```

Look for E000-EFFF in the upper memory region.

## Complete CONFIG.SYS Example

```
REM Memory Management
DEVICE=C:\DOS\HIMEM.SYS
DEVICE=C:\DOS\NOROM.SYS
DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF
DOS=HIGH,UMB

REM Load drivers into UMBs
DEVICEHIGH=C:\DOS\ANSI.SYS
DEVICEHIGH=C:\MOUSE\MOUSE.SYS

REM System Configuration
FILES=30
BUFFERS=20
STACKS=9,256
```

## Boot Messages

### Success

```
NOROM: ROM at E000 disabled successfully (Port FFEA bit 4 set)
```

### Already Disabled

```
NOROM: ROM at E000 already disabled
```

This can happen if:
- You're loading NOROM.SYS twice
- Another driver already disabled the ROM
- The ROM was disabled by previous boot

### Failure

```
NOROM: WARNING - Failed to set Port FFEA bit 4
```

This indicates:
- Hardware may not support this method
- Port FFEA bit 4 is read-only
- System incompatibility

If you see this message, the E000 region will NOT be available for UMBs.

## Memory Savings

Before NOROM.SYS:
```
655,360 bytes total conventional memory
640,000 bytes available to MS-DOS
```

After NOROM.SYS + EMM386 with E000-EFFF:
```
655,360 bytes total conventional memory
640,000 bytes available to MS-DOS
 65,536 bytes total UMB
 60,000+ bytes available UMB (after EMM386 overhead)
```

**Result:** ~60KB more RAM for drivers and TSRs!

## Loading Programs into UMBs

Once configured, load programs high:

### In CONFIG.SYS
```
DEVICEHIGH=C:\DOS\ANSI.SYS
DEVICEHIGH=C:\MOUSE\MOUSE.SYS
```

### In AUTOEXEC.BAT
```
LOADHIGH C:\DOS\DOSKEY.COM
LOADHIGH C:\DOS\MOUSE.COM
```

### Manual Loading
```
C:\> LOADHIGH DOSKEY
C:\> LH MOUSE
```

## Troubleshooting

### "Not enough memory to load NOROM.SYS"

This shouldn't happen as the driver is tiny (~200 bytes). Check:
- CONFIG.SYS has no syntax errors above this line
- Sufficient conventional memory available

### "EMM386 reports no UMBs at E000-EFFF"

Check:
1. NOROM.SYS loaded successfully (check boot messages)
2. NOROM.SYS loads BEFORE EMM386.EXE
3. EMM386.EXE has `I=E000-EFFF` parameter
4. Run `DEBUG` and examine E000:0000 - should be 0xFF not 0xEB

### "System hangs on boot after loading NOROM.SYS"

This is unlikely but possible if:
- Hardware is not Tandy 1000 TL/2
- BIOS expects ROM to be present
- Port FFEA has different meaning on your system

**Recovery:**
1. Boot from floppy
2. Edit C:\CONFIG.SYS
3. Remove or comment out DEVICE=NOROM.SYS line

### "MEM shows E000-EFFF as unavailable"

Possible causes:
- EMM386 doesn't have `I=E000-EFFF` parameter
- Another device is using E000 range (VGA, network card)
- EMM386 detected something at E000 and excluded it

Check EMM386 messages during boot.

## Technical Details

### Port FFEA Register (Tandy 1000 TL/2)

```
Bit   Function
---   -------------------
0-3   ROM Page Select       Which 64KB page appears at E000
4     ROM Disable           1 = ROM disabled, 0 = ROM enabled
5     System Type           TL/SL detection (inverted on read)
6-7   Memory Config         00/01/10 = 512K, 11 = 640K
```

NOROM.SYS only modifies bit 4, preserving all other bits.

### Memory Footprint

- **Load time:** ~512 bytes
- **Resident:** 0 bytes (driver unloads after initialization)
- **Overhead:** None

### Hardware Compatibility

✅ **Tested and Working:**
- Tandy 1000 TL/2

⚠️ **Untested (use at your own risk):**
- Tandy 1000 TL/3
- Tandy 1000 TL (original)

❌ **Will NOT work:**
- Other Tandy 1000 models (SL, SX, TX, etc.)
- Non-Tandy systems
- Emulators (DOSBox, PCem, etc.)

## Comparison to Other Methods

### NOROM.SYS (This Method)
✅ No BIOS modification required
✅ Zero resident memory
✅ Easily reversible (remove from CONFIG.SYS)
✅ No hardware changes
✅ Safe and tested

### BIOS Patching
❌ Requires ROM programmer
❌ Permanent modification
❌ Risk of bricking system
✅ No CONFIG.SYS changes needed

### Hardware Modification
❌ Requires soldering
❌ Permanent modification
❌ Can damage motherboard
✅ No software needed

## Source Code

The complete source code is in **src/norom.asm**

Key features:
- Standard DOS device driver structure
- Strategy/Interrupt routines
- Init-only (discards itself after loading)
- Proper error handling
- Status messages for debugging

## License

This driver is part of the TL2BIOS project and is provided as-is for educational and personal use on Tandy 1000 TL/2 hardware.

## Credits

- Based on handwritten note in Tandy 1000 TL technical documentation
- Tested and verified on real TL/2 hardware
- Developed as part of the TL2BIOS ROM disable project

## Support

For issues, questions, or test results:
- GitHub: https://github.com/er0080/tl2bios
- See PORT_FFEA_TEST.md for hardware test results
- See ANALYSIS.md for technical background

---

**Last Updated:** 2026-02-08
**Status:** Production Ready
**Hardware Verified:** Yes (Tandy 1000 TL/2)
