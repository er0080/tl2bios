# Tandy 1000 TL/2 ROM Disable Project

## Project Status: ✅ PRODUCTION READY

**NOROM.SYS device driver successfully disables ROM at E000:0000 on Tandy 1000 TL/2 hardware!**

## Project Overview

This project provides a DOS device driver to disable the ROM page frame at memory address `E000:0000` on the Tandy 1000 TL/2. By disabling ROM access at E000, the 64KB memory range becomes available for DOS Upper Memory Block (UMB) allocation, providing ~60KB additional upper memory for drivers and TSRs.

## Background

### About the Tandy 1000 TL/2

The Tandy 1000 TL/2 is a 286-based PC-XT clone manufactured by Tandy Corporation. It features:
- Intel 80286 processor
- Built-in ROM drive functionality
- Standard PC-XT architecture compatibility

### The ROM Drive Issue

The Tandy 1000 TL/2 includes a built-in ROM drive feature that occupies memory space at address `E000:0000`. While this feature was useful in its time, modern DOS users often prefer to use this memory range for UMBs (Upper Memory Blocks), which can significantly improve available conventional memory for applications.

## Technical Details

**Memory Address:** `E000:0000 - E000:FFFF` (64KB page frame window)
**ROM Size:** 512KB (organized as 8 pages of 64KB each)
**Control Port:** I/O Port FFEA (hex) - ROM paging control register
**Purpose:** Free up 64KB of upper memory for DOS UMB allocation
**Target System:** Tandy 1000 TL/2 (286 PC-XT clone)

### ROM Paging System

The TL/2 uses a **paging system** where:
- A 64KB window at E000:0000 provides access to the 512KB ROM
- Port FFEA bits 0-4 select which 64KB "page" is visible
- Only one page is visible at E000 at any given time
- The BIOS switches pages to access different parts of ROM
- The system ROM (BIOS code) is separately mapped at F000:C000

## Project Files

### Documentation
- **[NOROM_DRIVER.md](NOROM_DRIVER.md)** - Complete NOROM.SYS installation and usage guide
- **[ANALYSIS.md](ANALYSIS.md)** - ROM structure analysis and implementation approaches
- **[MEMORY_MAP.md](MEMORY_MAP.md)** - Memory layout and Port FFEA register details
- **[PORT_FFEA_TEST.md](PORT_FFEA_TEST.md)** - Hardware testing procedures

### Source Code (`src/`)
- **norom.asm** - Production DOS device driver (NOROM.SYS)
- **testrom.asm** - ROM disable verification test
- **diagnose.asm** - Comprehensive diagnostic tool
- **portread.asm** - Simple Port FFEA test utility
- **BUILD.BAT** - Batch file to build all programs
- **OUT.LOG** - Hardware test results from real TL/2

### ROM Dump
- `8079044.BIN` - Original 512KB ROM dump from Tandy 1000 TL/2 BIOS

### Technical References (`doc/`)
- TL/2 ROM paging documentation
- Memory controller specifications
- Theory of operation

## Solution: NOROM.SYS Device Driver ⭐

The project successfully developed **NOROM.SYS**, a DOS device driver that:
- Disables ROM at E000:0000 by setting Port FFEA bit 4 during boot
- Verified working on Tandy 1000 TL/2 hardware
- Zero resident memory footprint (unloads after initialization)
- Safe and reversible (no BIOS modification required)
- Enables 64KB (E000-EFFF) for DOS UMB allocation

**Quick Start:**
1. Build: Run `src/BUILD.BAT` to create NOROM.SYS
2. Install: Copy NOROM.SYS to C:\DOS\
3. Configure CONFIG.SYS:
   ```
   DEVICE=C:\DOS\NOROM.SYS
   DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF
   ```
4. Reboot and enjoy 60KB+ additional upper memory!

**See [NOROM_DRIVER.md](NOROM_DRIVER.md) for complete installation and usage guide.**

## Project Milestones

1. ✅ Analyzed original BIOS ROM dump (512KB, Phoenix BIOS v02.00.00)
2. ✅ Understood ROM paging system architecture (8 pages via Port FFEA)
3. ✅ Tested hardware method on real TL/2 - Port FFEA bit 4 WORKS!
4. ✅ Developed NOROM.SYS production device driver
5. ✅ Verified on hardware - ROM successfully disabled, system stable
6. ✅ Documented complete solution with CONFIG.SYS examples

## Memory Map Reference

Standard PC/XT Upper Memory Layout:
```
A000:0000 - AFFF:FFFF : VGA/EGA Graphics Memory
B000:0000 - BFFF:FFFF : Monochrome/Color Text Memory
C000:0000 - DFFF:FFFF : Adapter ROM/RAM
E000:0000 - EFFF:FFFF : ROM Drive (Target for modification)
F000:0000 - FFFF:FFFF : System BIOS
```

## Implementation Details

### Solution 1: Port FFEA Control ✅ VERIFIED WORKING
**Status:** ✅ **PRODUCTION READY** - Verified on Tandy 1000 TL/2 hardware

The handwritten note in the TL/2 technical documentation was correct:
> "Writing 1 to bit 4 disables access to the ROM segment at E0000"

**Hardware Test Results:**
- Port FFEA before: 0xC8 (ROM enabled)
- Port FFEA after: 0xD8 (bit 4 set successfully)
- E000:0000 before: 0xEB (ROM boot signature)
- E000:0000 after: 0xFF (ROM disabled, floating bus)
- System stability: STABLE ✅

**Implementation:**
```assembly
IN  AL, 0xFFEA      ; Read current Port FFEA value (0xC8)
OR  AL, 0x10        ; Set bit 4 (disable ROM at E000)
OUT 0xFFEA, AL      ; Write back (becomes 0xD8)
```

**Production Driver:**
- **NOROM.SYS** - DOS device driver (see [NOROM_DRIVER.md](NOROM_DRIVER.md))
- Zero resident memory
- Loads via CONFIG.SYS
- Verified working on real hardware

### Solution 2: BIOS Code Modification
**Status:** ⏳ Requires disassembly if Port FFEA method fails

Modify BIOS ROM to skip ROM page frame initialization:
- Locate POST code that writes to Port FFEA
- Patch to set bit 4 during initialization
- Or NOP out ROM page frame setup entirely

**Advantages:**
- Permanent solution
- ROM always disabled at boot

**Disadvantages:**
- Requires ROM reprogramming
- Need BIOS disassembly
- Risk of system brick if done wrong

### Solution 3: DOS Device Driver
**Status:** ✅ Can implement regardless of other methods

Create NOROM.SYS driver that:
- Attempts Port FFEA method on load
- Hooks INT 13h to filter ROM drive (if needed)
- Loads before EMM386 in CONFIG.SYS

**Advantages:**
- No hardware modification
- Easy to test and update
- Can combine multiple methods

## Development Status

**Completed:**
- ✅ ROM dump analyzed (512KB, 8 pages, BIOS version 02.00.00)
- ✅ Technical documentation reviewed
- ✅ ROM paging architecture understood
- ✅ Memory controller operation documented
- ✅ Port FFEA control register identified

**Next Steps:**
1. **Test Port FFEA bit 4 method** on real hardware
2. If successful: Create DOS driver or BIOS patch
3. If unsuccessful: Disassemble BIOS to find ROM initialization code
4. Document findings and create final solution

## Safety Warnings

- **Backup your original BIOS ROM** before attempting to flash any modified version
- Incorrect BIOS modifications can render your system unbootable
- Ensure you have a method to recover/reflash your BIOS if something goes wrong
- Test modified BIOS thoroughly in an emulator or with recovery options available

## Contributing

Contributions, suggestions, and issue reports are welcome. Please ensure any modifications are well-documented and tested.

## License

This project involves reverse engineering and modification of vintage computer hardware BIOS. Please respect applicable laws and regulations regarding BIOS modification in your jurisdiction.

## References

- Tandy 1000 TL/2 Technical Reference
- DOS Upper Memory Block (UMB) management
- x86 286 architecture documentation
