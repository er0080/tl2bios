# Bits 0-3 ROM Disable Theory

## Discovery

After testing on real hardware, setting **only bit 4** of Port FFEA doesn't consistently disable ROM at E000:0000. However, a closer examination of the ROM paging definition table in `doc/TL2_ROM_paging.pdf` reveals a potentially better approach.

## ROM Paging Table Analysis

Looking at the **2 Meg x 8 ROM configuration table** (page 57, second table), there's a critical row:

```
Address         Bits 4,3,2,1,0    ROM CS #0 #1    SELECT    64K Page
E0000-EFFFF     0  1  1  1  1     1   1          x x x     (disabled)
```

When Port FFEA bits are set to **0,1,1,1,1** (lower nibble = 0x0F):
- ROM CS #0 = 1 (high/inactive - ROM chip 0 **disabled**)
- ROM CS #1 = 1 (high/inactive - ROM chip 1 **disabled**)
- SELECT = x x x (don't care - no ROM active)

**Both ROM chips are disabled simultaneously!**

## The Handwritten Note Reinterpreted

The original handwritten note stated:
> "Writing 1 to bit 4 disables access to the ROM segment at E0000"

This may have meant "**the first 4 bits**" (bits 0-3) rather than "**bit number 4**". This could be:
- A translation ambiguity ("bit 4" vs "4 bits")
- A documentation shorthand ("bit 4" meaning "bits 0-3 pattern")
- An incomplete note (should have said "bits 0-3 all to 1")

## New Approach

Instead of setting just bit 4 (0x10), we should set bits 0-3 to create pattern 0x0F:

### Old Method (Inconsistent)
```assembly
IN  AL, 0xFFEA      ; Read current value (e.g., 0xC8 = 11001000)
OR  AL, 0x10        ; Set bit 4 only (becomes 0xD8 = 11011000)
OUT 0xFFEA, AL      ; Write back
```

Result: 0xD8 = 11011000
- Bit 4 = 1 (set)
- Bits 0-3 = 1000 (not the 0x0F pattern needed)

### New Method (Based on ROM Table)
```assembly
IN  AL, 0xFFEA      ; Read current value (e.g., 0xC8 = 11001000)
AND AL, 0xE0        ; Clear bits 0-4, keep bits 5-7 (becomes 0xC0 = 11000000)
OR  AL, 0x0F        ; Set bits 0-3 (becomes 0xCF = 11001111)
OUT 0xFFEA, AL      ; Write back
```

Result: 0xCF = 11001111
- Bits 0-3 = 1111 (0x0F pattern - **disables both ROMs**)
- Bits 5-7 preserved (memory config and system type)

## Why This Should Work

According to the ROM paging table:
1. The memory controller decodes Port FFEA bits 0-4 to generate ROM chip select signals
2. When bits 0-3 = 1111 (and bit 4 = 0), the decode logic pulls **both ROMCS pins high**
3. High ROMCS = chip disabled, no ROM access
4. Both ROM0 (U54/U55) and ROM1 (U56/U57) are disabled
5. E000-EFFF becomes unoccupied address space
6. DOS can use it as UMB memory

## Test Programs

### TESTBITS.COM
Quick test utility to verify this method works:
- Reads Port FFEA before (should be ~0xC8)
- Reads E000:0000 before (should be 0xEB - ROM signature)
- Sets bits 0-3 to 0x0F pattern (becomes ~0xCF)
- Reads E000:0000 after (should be 0xFF if ROM disabled)
- Restores original value

### NOROMBITS.SYS
Production device driver using bits 0-3 method:
- Loads in CONFIG.SYS
- Sets Port FFEA bits 0-3 to 0x0F
- Verifies the pattern was set
- Reports success/failure
- Unloads (zero resident memory)

## Expected Results

### If Theory is Correct:
1. Port FFEA writes 0xCF successfully (or 0xEF if 640K config)
2. Port FFEA reads back with bits 0-3 = 1111
3. E000:0000 changes from 0xEB to 0xFF (floating bus)
4. Memory becomes writable at E000
5. System remains stable
6. EMM386 can allocate E000-EFFF as UMBs

### If Theory is Incorrect:
1. Bits 0-3 may not persist (hardware forces different pattern)
2. E000:0000 still shows 0xEB (ROM still visible)
3. System may become unstable
4. Need to investigate other patterns in the table

## Other Patterns to Try

If 0x0F doesn't work, the ROM paging table shows other patterns. Looking at patterns with ROM CS = 1 1:

Currently known:
- **0x0F** (01111): Both ROM chips disabled ← **Primary candidate**

To investigate:
- Check if any other bit patterns also produce ROM CS = 1 1
- Review the decode logic in `doc/TL2_mem_controller.pdf`
- May need to try different page select combinations

## Hardware Testing Plan

1. **Test TESTBITS.COM first**
   - Safest - restores original value
   - Quick test of the theory
   - Document before/after values

2. **If TESTBITS works, test NOROMBITS.SYS**
   - Boot with DEVICE=NOROMBITS.SYS in CONFIG.SYS
   - Check boot messages
   - Verify system stability
   - Test with EMM386

3. **Compare with original NOROM.SYS**
   - Document which method is more reliable
   - Update production driver with working method

## Files Created

- `src/testbits.asm` - Test utility for bits 0-3 method
- `src/norombits.asm` - Device driver using bits 0-3 method
- Updated `src/BUILD.BAT` to build both new files

## Next Steps

1. Build the new test programs on real hardware
2. Run TESTBITS.COM and document results
3. If successful, test NOROMBITS.SYS
4. Update main NOROM.SYS if bits 0-3 method proves superior
5. Document findings in PORT_FFEA_TEST.md
6. Update NOROM_DRIVER.md with correct method

## References

- `doc/TL2_ROM_paging.pdf` - ROM paging table (page 57, second table)
- `doc/TL2_mem_controller.pdf` - Memory controller specifications
- Original handwritten note about "bit 4"
