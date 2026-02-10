# Tandy 1000 TL/2 BIOS ROM Analysis

## ROM Dump Information

**File:** `8079044.BIN`
**Size:** 524,288 bytes (512KB / 0x80000 bytes)
**Date:** April 14, 1989 (04/14/89)
**BIOS Version:** 02.00.00

## ROM Structure

The ROM is organized into two main sections:

### 1. ROM Drive Filesystem (0x00000 - 0x7BFFF)
- **Size:** ~496KB
- **Type:** DOS FAT filesystem
- **OEM-ID:** "TAN  3.3" (Tandy DOS 3.3)
- **Boot Signature:** 0x55AA at offset 0x1FE-0x1FF
- **Purpose:** Contains DOS system files and utilities

#### Boot Sector Analysis (0x00000 - 0x001FF)
```
Offset  Content
------  -------
0x000   EB 34 90        JMP short 0x36, NOP (boot code jump)
0x003   "TAN  3.3"      OEM identifier
0x00B   DOS BPB (BIOS Parameter Block):
        - 512 bytes per sector
        - 1 sector per cluster
        - 1 reserved sector
        - 1 FAT copy
        - 16 root directory entries
        - 292 total sectors
        - Media descriptor: 0xF8
        - 1 sector per FAT

0x036   Boot code begins
0x1E0   "IBMBIO  COM"   System file to load
0x1EB   "IBMDOS  COM"   DOS kernel to load
0x1FE   55 AA           Boot signature
```

**Boot Error Messages:**
- "Non-System disk or disk error"
- "Disk Boot failure"

### 2. System BIOS Code (0x7C000 - 0x7FFFF)
- **Size:** 16KB
- **Type:** Phoenix BIOS
- **Copyright:** Phoenix Software Associates Ltd. and Tandy Corporation
- **Years:** 1984, 1985, 1986, 1987, 1988

#### BIOS Banner (at 0x7C000):
```
!BIOS ROM version 02.00.00
Compatibility Software
Copyright (C) 1984,1985,1986,1987,1988
Phoenix Software Associates Ltd.
All rights reserved.
$and Tandy Corporation.
```

#### Reset Vector (at 0x7FFF0):
```
EA 5B E0 00 F0    JMP F000:E05B
```

This is the CPU reset entry point. On power-up or reset, the CPU jumps to F000:E05B.

#### BIOS Date String (at 0x7FFF5):
```
30 34 2F 31 34 2F 38 39    "04/14/89"
```

## Memory Mapping

When the system boots, the ROM is mapped to different segments:

### ROM Physical to Logical Mapping
```
Physical ROM    Logical Address    Content
------------    ---------------    -------
0x00000         E000:0000          ROM Drive filesystem
...
0x7BFFF         E7BF:000F          End of ROM drive
0x7C000         F000:C000          BIOS code start
...
0x7FFF0         F000:FFF0          Reset vector
```

## ROM Paging System at E000:0000

**CRITICAL FINDING**: The E000 segment is NOT a fixed ROM drive, but rather a **64KB page frame window** used to access the 512KB ROM in chunks.

### ROM Paging Architecture:
- **Total ROM Size**: 512KB (two 256KB chips: ROM0 and ROM1)
- **Page Frame**: 64KB window at E000:0000
- **Control Port**: I/O Port **FFEA** (hex)
- **Page Selection**: Bits 0-4 select which 64KB page is visible at E000

### Port FFEA Bit Definitions:
```
Bit 0-4: ROM PAGING 0-4 (select 1 of 8 64KB pages from 512KB ROM)
Bit 5:   System Type (Reserved - TL vs SL detection)
Bit 6-7: Memory Configuration
         00 = 512K System Memory
         01 = 512K System Memory
         10 = 512K System Memory
         11 = 640K System Memory
```

### How ROM Paging Works:
1. BIOS writes to Port FFEA to select which 64KB page appears at E000:0000
2. The ROM contains 8 pages total (512KB ÷ 64KB = 8 pages)
3. Page 1 contains the DOS filesystem boot sector and files
4. Different pages contain different utilities and data
5. The BIOS code itself (16KB) is separately mapped at F000:C000-F000:FFFF

### Disabling E000 ROM Access:
**KEY FINDING**: According to the technical manual's handwritten notes:
- Writing **1** to Port FFEA, Bit 4 **disables access to the ROM segment at E0000**
- This immediately frees the E000-EFFF range for UMB use
- No BIOS code modification required!

### Memory Impact:
- When enabled: Occupies 64KB of upper memory (E000-EFFF)
- When disabled: Frees 64KB for DOS UMBs
- Does not affect BIOS operation at F000 segment

## BIOS Features Detected

From string analysis, the BIOS includes:
- Memory testing and configuration
- Keyboard controller support
- Display adapter support (CGA/EGA compatible)
- Disk controller (INT 13h)
- Bootstrap loader (INT 19h)
- Tandy-specific features (joystick, sound, etc.)

### Tandy-Specific Components Found:
- TANDY JOY.MOD VERSION 02.00.00 (Joystick support)
- COPYRIGHT 1987, 1988 TANDY CORP.
- DeskMate support (Tandy's GUI environment)

## DOS Files in ROM Drive

Based on string analysis, the ROM contains:
- MS-DOS Version 3.30
- Copyright Microsoft Corp 1981-1987
- DISKCOPY.COM utility
- Various DOS system files
- DeskMate application files
- Printer drivers dated 1989

## Key Findings for Modification

### Potential Approaches

Based on the technical documentation and ROM analysis, there are several potential approaches to disable ROM access at E000:

### Approach 1: Hardware Port Control (POTENTIAL - NEEDS TESTING)

**Theory**: According to a handwritten note in the technical documentation, Port FFEA bit 4 may control E000 ROM access.

**Port FFEA (ROM Paging Control)**:
- Bit 0-4: ROM Page selection (which 64KB page of 512KB ROM appears at E000)
- Bit 4: **May disable E000 ROM access when set to 1** (per handwritten note)
- Bit 5: System type detection (Reserved)
- Bit 6-7: Memory configuration (512K vs 640K)

**Implementation** (if this method works):
```assembly
; Attempt to disable ROM at E000
IN  AL, 0xFFEA      ; Read current value
OR  AL, 0x10        ; Set bit 4
OUT 0xFFEA, AL      ; Write back
```

**Advantages**:
- No BIOS modification required
- Reversible (can re-enable by clearing bit 4)
- Can be done via DOS driver or utility

**Risks**:
- Handwritten note may be speculation, not confirmed
- May have unintended side effects
- Needs testing to verify it actually works
- May not fully disable ROM if BIOS re-enables it

**Status**: ⚠️ UNVERIFIED - This approach needs testing

---

### Approach 2: BIOS Code Modification (TRADITIONAL)

Modify the BIOS ROM to prevent initialization of the ROM page frame at E000.

**Steps**:
1. Disassemble BIOS code starting at POST entry point (F000:E05B)
2. Locate ROM page frame initialization code
3. Find where Port FFEA is written during POST
4. Identify INT 13h disk handler setup for ROM drive
5. Patch code to skip ROM initialization or set bit 4 permanently

**Specific targets to locate**:
- Code that writes to Port FFEA (I/O address 0xFFEA)
- INT 13h vector setup for ROM drive access
- INT 19h bootstrap code that may try to boot from ROM
- Memory controller setup routines

**Advantages**:
- Permanent solution
- ROM always disabled at boot
- No DOS drivers needed

**Disadvantages**:
- Requires ROM reprogramming
- Risk of bricking system if done incorrectly
- Need ROM programmer hardware
- Must understand BIOS code flow

**Status**: ⚠️ REQUIRES DISASSEMBLY - Need to analyze BIOS code

---

### Approach 3: DOS Device Driver

Create a device driver that disables ROM access before EMM386 loads.

**Implementation**:
```
DEVICE=C:\DRIVERS\NOROM.SYS
DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF
```

**Driver would**:
1. Attempt Port FFEA bit 4 method (if it works)
2. Or hook INT 13h to filter out ROM drive
3. Or modify memory controller settings
4. Report success/failure to user

**Advantages**:
- No hardware modification
- Easy to install/remove
- Can be updated if approach changes

**Disadvantages**:
- Loads after BIOS initialization
- May not work if BIOS resets Port FFEA
- Takes up some conventional memory

**Status**: ✅ FEASIBLE - Can implement regardless of other methods

---

### Approach 4: Memory Controller Manipulation

Directly manipulate the DRAM/DMA Control IC (U22) to prevent ROM mapping.

**Theory**: The memory controller generates ROMCS- signal for address ranges including 0E0000-0FFFFF. If we can prevent this signal or modify the address decode logic, E000 won't map to ROM.

**Potential methods**:
- Modify address decode logic equations (requires PAL/GAL reprogramming)
- Cut trace to ROMCS- signal (hardware mod)
- Force ROMCS- inactive via pull-up resistor
- Modify PLS173 IFL (U44) ROM select logic

**Advantages**:
- True hardware disable
- Cannot be overridden by software

**Disadvantages**:
- Requires hardware modification
- Destructive (may be irreversible)
- Risk of damage
- Advanced skill level required

**Status**: ⚠️ LAST RESORT - Only if other methods fail

---

### Recommended Testing Order:

1. **Test Port FFEA bit 4 method first** (easiest, reversible)
   - Boot to DOS
   - Write utility to set/clear bit 4
   - Test if E000 becomes accessible to DOS
   - Verify no system instability

2. **If Port FFEA works**: Create DOS driver or BIOS patch

3. **If Port FFEA doesn't work**: Disassemble BIOS to find ROM initialization

4. **If BIOS modification fails**: Consider hardware modification

---

### Port FFEA Test Utility (DOS Assembly):

```assembly
; TEST.ASM - Test if Port FFEA bit 4 disables E000 ROM
.MODEL SMALL
.CODE
.STARTUP

    ; Display current Port FFEA value
    IN   AL, 0xFFEA
    CALL DisplayHex

    ; Try to disable ROM (set bit 4)
    OR   AL, 0x10
    OUT  0xFFEA, AL

    ; Read back
    IN   AL, 0xFFEA
    CALL DisplayHex

    ; Test if E000 is accessible
    MOV  AX, 0xE000
    MOV  DS, AX
    MOV  AL, [0]        ; Try to read from E000:0000

    .EXIT
END
```

## Next Steps

1. Disassemble the BIOS code section (0x7C000-0x7FFFF)
2. Locate the POST routine starting at offset E05B
3. Trace through the initialization code to find ROM drive setup
4. Identify the specific instructions that need to be patched
5. Create a modified ROM with ROM drive disabled
6. Test in emulator before flashing to hardware

## Tools Needed

- Disassembler (IDA Pro, Ghidra, or x86 disassembler)
- Hex editor for patching
- Tandy 1000 emulator for testing
- ROM programmer for flashing modified BIOS

## Safety Notes

⚠️ **WARNING:** Modifying and flashing BIOS is risky!
- Always keep a backup of the original ROM
- Test modifications in an emulator first
- Ensure you have a way to recover if the modified BIOS fails
- Consider using a socket for the ROM chip to allow easy replacement
