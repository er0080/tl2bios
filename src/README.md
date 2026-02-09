# Source Code - Port FFEA Test Utilities

This directory contains assembly language test utilities for the Tandy 1000 TL/2 ROM disable project.

## Programs

### 1. PORTREAD.ASM
**Purpose:** Simple utility to read Port FFEA, set bit 4, and display results

**Output:**
```
XX YY
```
Where:
- `XX` = Original Port FFEA value (hex)
- `YY` = Port FFEA value after setting bit 4 (hex)

**Use Case:** Quick test to see if bit 4 persists when written to Port FFEA

---

### 2. DIAGNOSE.ASM
**Purpose:** Diagnostic tool to isolate ROM reading issues and verify display routines

**Output:**
```
========================================
ROM Diagnostic Tool
========================================

Test 1 - Display EB 34:     EB 34
Test 2 - Port FFEA:         XX
Test 3 - E000:0000-0003:    EB 34 90 54
Verify - Reverse order:     54 90 34 EB
Test 4 - Using ES segment:  EB 34
Test 5 - After bit 4 set:   YY ZZ
```

**Use Case:**
- Verify DisplayHex routine works with known values (EB, 34)
- Test reading from E000:0000 using both DS and ES segments
- Read multiple bytes to confirm ROM signature
- Verify values are preserved on stack
- Test Port FFEA bit 4 effect on ROM access

---

### 3. TESTROM.ASM
**Purpose:** Comprehensive test that checks ROM content before/after Port FFEA bit 4 is set

**Output:**
```
========================================
Tandy 1000 TL/2 Port FFEA ROM Test
========================================

Port FFEA before: 0xC8
E000:0000 before: 0xEB
Port FFEA after:  0xD8
E000:0000 after:  0xFF

Interpretation:
  If E000:0000 changed from EB to FF (or other),
  then ROM disable via Port FFEA bit 4 WORKS!
  If E000:0000 still shows EB (ROM boot signature),
  then Port FFEA bit 4 does NOT disable ROM.

Port FFEA restored to original value.
Test complete.
```

**Use Case:** Final verification that Port FFEA bit 4 disables ROM access at E000:0000

---

### 4. NOROM.ASM ⭐ PRODUCTION DRIVER
**Purpose:** DOS device driver that disables ROM at E000:0000 during boot

**Status:** ✅ **VERIFIED WORKING** on Tandy 1000 TL/2 hardware

**Installation:**
1. Build with `BUILD.BAT` to create NOROM.SYS
2. Copy to boot drive (e.g., C:\DOS\)
3. Add to CONFIG.SYS: `DEVICE=C:\DOS\NOROM.SYS`
4. Configure EMM386: `DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF`
5. Reboot

**Boot Message:**
```
NOROM: ROM at E000 disabled successfully (Port FFEA bit 4 set)
```

**Benefits:**
- Zero resident memory footprint (driver unloads after init)
- Frees 64KB (E000-EFFF) for DOS UMBs
- Safe and reversible (just remove from CONFIG.SYS)
- No BIOS modification required

**See:** [NOROM_DRIVER.md](../NOROM_DRIVER.md) for complete documentation

---

## Building with TASM (Turbo Assembler)

### Requirements
- Turbo Assembler (TASM) version 2.0 or later
- Turbo Link (TLINK)
- DOS or DOS emulator (DOSBox, FreeDOS)

### Build Commands

**PORTREAD.COM:**
```batch
TASM PORTREAD.ASM
TLINK /T PORTREAD.OBJ
```

**TESTROM.COM:**
```batch
TASM TESTROM.ASM
TLINK /T TESTROM.OBJ
```

The `/T` option tells TLINK to create a .COM file (Tiny model).

### Batch File for Building Both

Create `BUILD.BAT`:
```batch
@ECHO OFF
ECHO Building Port FFEA test utilities...
ECHO.

ECHO Assembling PORTREAD.ASM...
TASM PORTREAD.ASM
IF ERRORLEVEL 1 GOTO error

ECHO Linking PORTREAD.COM...
TLINK /T PORTREAD.OBJ
IF ERRORLEVEL 1 GOTO error

ECHO Assembling TESTROM.ASM...
TASM TESTROM.ASM
IF ERRORLEVEL 1 GOTO error

ECHO Linking TESTROM.COM...
TLINK /T TESTROM.OBJ
IF ERRORLEVEL 1 GOTO error

ECHO.
ECHO Build successful!
ECHO Created: PORTREAD.COM, TESTROM.COM
GOTO end

:error
ECHO.
ECHO Build failed!

:end
```

---

## Building with MASM (Microsoft Macro Assembler)

### Build Commands

**PORTREAD.COM:**
```batch
MASM PORTREAD.ASM;
LINK PORTREAD.OBJ;
EXE2BIN PORTREAD.EXE PORTREAD.COM
DEL PORTREAD.EXE
```

**TESTROM.COM:**
```batch
MASM TESTROM.ASM;
LINK TESTROM.OBJ;
EXE2BIN TESTROM.EXE TESTROM.COM
DEL TESTROM.EXE
```

---

## Building with NASM (Netwide Assembler)

NASM requires slight syntax modifications. To use NASM, you would need to convert the TASM syntax to NASM syntax (different directives for .MODEL, ORG, etc.).

---

## Running on Tandy 1000 TL/2

1. Copy the .COM files to a DOS boot floppy
2. Boot the Tandy 1000 TL/2 from floppy
3. Run the programs:
   ```
   A:\> PORTREAD
   A:\> TESTROM
   ```

4. Document the results in the PORT_FFEA_TEST.md file

---

## Running in DOSBox (For Development/Testing)

**Note:** DOSBox will NOT accurately test Port FFEA behavior since it's emulating a standard PC, not a Tandy 1000 TL/2. These programs will compile and run but won't produce meaningful results for ROM testing.

However, you can verify the programs compile and display correctly:

```
C:\> mount d ~/Documents/code/tl2bios/src
C:\> d:
D:\> TESTROM
```

---

## File Sizes

Expected .COM file sizes:
- **PORTREAD.COM:** ~200-300 bytes
- **TESTROM.COM:** ~700-900 bytes

Very small, suitable for copying to floppy or including in boot disk.

---

## Troubleshooting

**"Out of memory" error:**
- These are .COM files and should be very small
- Check if you have sufficient conventional memory

**"Divide overflow" or crash:**
- May indicate Port FFEA access caused system instability
- Power cycle the system
- Port FFEA bit 4 may not be the correct method

**Programs run but show same values before/after:**
- Port FFEA bit 4 may not disable ROM
- Proceed to BIOS disassembly approach
- Document results for future reference

---

## Next Steps After Testing

### If Port FFEA Method Works:
1. Create DOS device driver (NOROM.SYS) using this method
2. OR create BIOS patch that sets bit 4 during POST
3. Test with EMM386 for UMB allocation

### If Port FFEA Method Fails:
1. Begin BIOS disassembly at offset 0x7E05B
2. Locate ROM initialization code
3. Plan BIOS modification strategy
4. Create patched ROM image

---

## Safety Notes

⚠️ **These programs write to I/O port FFEA**
- Intended for Tandy 1000 TL/2 hardware only
- May cause instability on other systems
- Always have a backup boot method ready
- Test on non-critical system first

---

## Contributing

If you test these programs on real hardware, please document:
- Port FFEA values before/after
- E000:0000 values before/after
- System stability (stable/hang/crash)
- Any other observations

Add your results to the main PORT_FFEA_TEST.md documentation file.
