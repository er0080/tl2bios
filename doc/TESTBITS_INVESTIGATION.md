# TESTBITS Investigation

## Problem

Running `TESTBITS.COM` on real Tandy 1000 TL/2 hardware shows unexpected behavior:
- We attempted to write bits 0-3 = **1111** (0x0F pattern)
- Port FFEA after write: **0x24** (binary: 00100100)
- Bits 0-3 result: **0100** (only bit 2 set)

## Analysis

### What We Expected
If original Port FFEA was 0xC8 (11001000):
1. AND with 0xE0 → 0xC0 (11000000) - clears bits 0-4
2. OR with 0x0F → 0xCF (11001111) - sets bits 0-3
3. Should read back: 0xCF

### What We Got
- Read back: 0x24 (00100100)
- Bits 0-3 = 0100 (only bit 2)
- Bits 0-4 = 00100 (value 0x04)

### Code Review
The testbits.asm logic is correct:
```assembly
mov al, bl              ; Original value
and al, 0E0h            ; Clear bits 0-4, preserve 5-7
or  al, 0Fh             ; Set bits 0-3
out dx, al              ; Write to port
```

0xE0 = 11100000 (correctly masks bits 0-4)
0x0F = 00001111 (correctly sets bits 0-3)

**The code is doing the right thing.**

## Theories

### Theory 1: Hardware Rejects Invalid Patterns
The ROM paging hardware may only accept **specific valid patterns** from the ROM paging table. Pattern 0x0F (01111) might not be a valid page select, so the hardware forces it to a nearby valid pattern.

Looking at 0x04 (00100) in the ROM paging table:
- Bits 4,3,2,1,0 = 0,0,1,0,0
- This selects Page 4 (a valid page)
- ROM CS #0=1, #1=0 (ROM 0 disabled, ROM 1 active)

### Theory 2: Bit 5 Interference
The documentation mentions bit 5 is used for system type detection and behaves differently on TL vs SL systems. If the original value had bit 5 set differently, it might affect the paging logic.

### Theory 3: Write-Protect or Decode Logic
Certain bit combinations might be write-protected or forced by hardware decode logic for system stability.

### Theory 4: Documentation Error
The handwritten note and/or ROM paging table may have errors or may not fully describe the hardware behavior.

## Diagnostic Plan

Created **TESTPAT.COM** to systematically test:

1. **Original value** - What is Port FFEA at boot?

2. **Test 1: Bits 0-3 = 1111 (0x0F)**
   - Shows: original → calculated write value → actual readback
   - Confirms if 0x0F pattern is rejected

3. **Test 2: Bit 4 only (0x10)**
   - Tests the original "bit 4" method
   - Shows if bit 4 alone has any effect

4. **Test 3: Valid patterns from table**
   - Try 0x01 (page 7, ROM 0)
   - Try 0x09 (page 3, ROM 1)
   - Try 0x00 (page 8, ROM 0)
   - Confirms if valid patterns work correctly

5. **E000:0000 content check**
   - See if any pattern actually disables ROM

## Questions to Answer

1. What is the original Port FFEA value?
2. Do valid page patterns (0x00-0x0D) write correctly?
3. Does pattern 0x0F get rejected? If so, what does it become?
4. Does bit 4 (0x10) persist when set alone?
5. Is there a pattern that makes E000:0000 show 0xFF instead of 0xEB?

## Next Steps

1. Run TESTPAT.COM on hardware
2. Document all output
3. Analyze which patterns work
4. Look for pattern that actually disables ROM
5. May need to try combinations not in the table

## Alternative Approaches

If 0x0F doesn't work:

### Approach A: Invalid Pattern Above Range
Try setting bits 0-4 to values above the max page (e.g., 0x10-0x1F) to see if going out-of-range disables ROM.

### Approach B: Specific Undocumented Pattern
There may be an undocumented pattern that disables ROM that's not in the table.

### Approach C: Multiple ROM Chips
The table shows ROM CS #0 and #1 can be independently controlled. Maybe we need a pattern that sets BOTH to 1 (disabled), but 0x0F might not be it.

### Approach D: BIOS Modification
If no Port FFEA pattern works, revert to BIOS code modification approach.

## Files Created for Investigation

- `src/testpat.asm` - Comprehensive pattern test utility
- Updated `src/BUILD.BAT` to build TESTPAT.COM
- This document (TESTBITS_INVESTIGATION.md)
