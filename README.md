# Tandy 1000 TL/2 BIOS Modification

## Project Overview

This project focuses on modifying the Tandy 1000 TL/2 BIOS to disable the built-in ROM drive at memory address `E000:0000`. By disabling this feature, the memory range can be freed for DOS Upper Memory Block (UMB) allocation, allowing for more efficient memory usage in DOS applications.

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

## Project Contents

- `8079044.BIN` - Original ROM dump from Tandy 1000 TL/2 BIOS

## Goals

1. ✅ Analyze the original BIOS ROM dump
2. ✅ Understand the ROM paging system architecture
3. ⚠️ Test hardware method (Port FFEA) to disable ROM paging
4. 🔄 If needed: Modify BIOS code to disable ROM drive functionality
5. Test the solution to ensure:
   - The ROM page frame at E000 is properly disabled
   - Memory at E000-EFFF is available for UMB allocation
   - System stability is maintained
   - Other BIOS functions remain intact

## Memory Map Reference

Standard PC/XT Upper Memory Layout:
```
A000:0000 - AFFF:FFFF : VGA/EGA Graphics Memory
B000:0000 - BFFF:FFFF : Monochrome/Color Text Memory
C000:0000 - DFFF:FFFF : Adapter ROM/RAM
E000:0000 - EFFF:FFFF : ROM Drive (Target for modification)
F000:0000 - FFFF:FFFF : System BIOS
```

## Potential Solutions

Based on technical documentation analysis, several approaches are possible:

### Solution 1: Port FFEA Control (Testing Required)
**Status:** ⚠️ **UNVERIFIED** - Based on handwritten note in technical manual

A handwritten note in the TL/2 technical documentation suggests:
> "Writing 1 to bit 4 disables access to the ROM segment at E0000"

**Implementation:**
```assembly
IN  AL, 0xFFEA      ; Read current Port FFEA value
OR  AL, 0x10        ; Set bit 4 (disable ROM at E000)
OUT 0xFFEA, AL      ; Write back
```

**Advantages:**
- Simple software-only solution
- Reversible (can re-enable ROM)
- No BIOS modification needed
- Can be implemented as DOS driver

**Needs Testing:**
- Verify this actually works on real hardware
- Check for side effects or system instability
- Confirm BIOS doesn't re-enable ROM
- Test with EMM386/DOS UMB managers

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
