# TESTPAT.COM Hardware Test Findings

## Test Output Summary

```
Original Port FFEA: 0x24
Test 1 (bits 0-3=1111): 0x22 -> 0x2F -> 0x56
Test 2 (bit 4 only):    0x22 -> 0x32 -> 0x22
Test 3 (valid patterns): All resulted in 0x22 (unchanged)
Final Port FFEA: 0x22
E000:0000: 0x01
```

## Critical Discovery 1: Bit 4 Inversion

**Test 2 Results:**
- Wrote: 0x32 (00110010) - bit 4 = 1
- Read:  0x22 (00100010) - bit 4 = 0

**Bit 4 is inverted on readback!**

### What the Documentation Says

From TL2_ROM_paging.pdf:
> "When reading Port FFEA, Bit 4 will be inverted from what was written...
> Bit 4 can be used to determine the system type. If Bit 4 is read back
> inverted, the system is identified as a Tandy 1000 SL. If Bit 4 is NOT
> inverted, the system is identified as a Tandy 1000 TL."

### Interpretation

Since bit 4 **IS inverted**, this suggests:
- The TL/2 may have SL-like behavior for bit 4
- OR the documentation is TL/SL generic, not TL/2-specific
- OR this particular TL/2 unit has hybrid behavior

**This explains why setting bit 4 alone doesn't disable ROM - it gets inverted back!**

## Critical Discovery 2: Complex Write Behavior

**Test 1 - Writing 0x2F resulted in 0x56:**

```
Wrote:    0x2F = 00101111
Read:     0x56 = 01010110
```

Bit-by-bit changes:
```
Bit 0: 1 -> 0 (inverted/cleared)
Bit 1: 1 -> 1 (unchanged)
Bit 2: 1 -> 1 (unchanged)
Bit 3: 1 -> 0 (inverted/cleared)
Bit 4: 0 -> 1 (set/inverted!)
Bit 5: 1 -> 0 (inverted/cleared)
Bit 6: 0 -> 1 (unexpectedly set!)
Bit 7: 0 -> 0 (unchanged)
```

### Analysis

This is **not simple bit inversion**. The pattern suggests:
1. Some bits are protected or force-set by hardware
2. Invalid paging patterns may trigger protection logic
3. Bits 6-7 (memory config) may have constraints
4. The hardware actively prevents certain bit combinations

## Critical Discovery 3: Valid Patterns Don't Change Port

**Test 3 tried valid page patterns:**
- 0x01 (page 7, ROM 0) → stayed 0x22
- 0x09 (page 3, ROM 1) → stayed 0x22
- 0x00 (page 8, ROM 0) → stayed 0x22

### Why This Matters

The current state is 0x22 (bits 0-4 = 00010 = pattern 0x02).

According to the ROM paging table:
- 0x02 = page 6, ROM 0 active

**But we tried to change to other valid pages and it didn't work!**

### Possible Explanations

1. **BIOS Lock**: BIOS may have locked the paging register
2. **Write Protection**: Some bits may be write-protected after boot
3. **Code Error**: Our code isn't actually writing correctly (need to verify)
4. **Hardware State**: System may be in a mode where paging is disabled

## Critical Discovery 4: E000:0000 = 0x01 (Not ROM Signature!)

**Expected:** 0xEB (ROM boot sector signature: JMP instruction)
**Actual:** 0x01

### What This Means

The ROM is **NOT** showing its normal boot sector. Possibilities:

1. **ROM is already disabled** - E000 is reading something else
2. **Different page mapped** - We're seeing a different 64KB page
3. **Hardware state** - System configuration has ROM in unusual state
4. **Memory contents** - There's actual data at E000, not ROM

## Investigation: Why Did 0x24 Become 0x22?

```
Original Port FFEA: 0x24 (00100100)
Test 1 before:      0x22 (00100010)
```

Between the initial read and Test 1, bit 1 changed from 0 to 1.

This could be:
1. The program restored something between reads
2. Bit 1 is unstable or has special behavior
3. A hardware state change occurred

## Investigation: Current ROM Paging State

Port FFEA = 0x22 = 00100010
- Bits 0-4 = 00010 (0x02)
- Bit 5 = 1
- Bits 6-7 = 00 (512K memory config)

According to ROM paging table (2 Meg x 8 ROMs):
- Pattern 0x02 (00010) = Page 6, ROM CS #0=1 #1=0

This means:
- ROM 0 is **disabled** (CS=1)
- ROM 1 is **active** (CS=0)
- Page 6 should be visible at E000

But E000:0000 = 0x01, which doesn't match typical ROM content.

## Revised Understanding

### The Handwritten Note Was Wrong

The note said "Writing 1 to bit 4 disables access to ROM segment at E0000"

**This is incorrect because:**
1. Bit 4 gets inverted on readback (SL behavior)
2. Writing 1 to bit 4 results in 0 being read back
3. Bit 4 alone cannot disable ROM on this hardware

### What Actually Controls ROM

Looking at the ROM CS signals in the paging table:
- ROM CS #0 = 1 means ROM 0 disabled
- ROM CS #1 = 1 means ROM 1 disabled
- Both = 1 means all ROM disabled

The pattern 0x0F (01111) in the table shows ROM CS = 1,1 (both disabled).

**But we can't write 0x0F successfully - hardware rejects it!**

## New Theories

### Theory A: BIOS Protection
The BIOS may set a hardware lock that prevents changing the ROM paging after boot. This would explain why valid patterns don't change the register.

### Theory B: Multi-Step Process
Maybe there's a multi-step process:
1. Write to a control register to unlock paging
2. Then write the page pattern
3. Then lock it again

### Theory C: Different Port
Maybe Port FFEA isn't the only control. There could be:
- A separate enable/disable bit elsewhere
- Multiple ports that must be set in sequence
- A companion port that gates writes to FFEA

### Theory D: Bit 5 is the Key
Bit 5 is marked "System Type (Reserved)". Maybe bit 5 is actually the ROM disable control, not bit 4?

Current value has bit 5 = 1. Let's test:
- Try setting bit 5 = 0
- Try setting bit 5 = 1 with different bit 0-4 patterns

## Recommended Next Tests

### Test A: Try Bit 5 Manipulation
Create test that toggles bit 5 while keeping bits 0-4 constant:
- Write 0x02 (bit 5 = 0)
- Write 0x22 (bit 5 = 1)  [current state]
- Check E000:0000 each time

### Test B: Try Reading Multiple Bytes from E000
```
E000:0000, E000:0001, E000:0002, E000:0003
```
This will show if we're seeing actual ROM data or something else.

### Test C: Try Pattern 0x1F (bit 4=1, bits 0-3=1111)
This combines bit 4 with the 0x0F pattern:
- Write 0x1F (00011111)
- See what we get back
- Check E000:0000

### Test D: Try OUT Commands with Delays
Maybe writes need more time to settle:
```assembly
OUT DX, AL
call LongDelay  ; 10-100ms
IN AL, DX
```

### Test E: Examine BIOS Code
Disassemble the BIOS to find where it writes to Port FFEA during POST. This will show:
- What pattern the BIOS uses
- If there's an unlock sequence
- How the BIOS sets up ROM paging

## Current Status

❓ **Port FFEA behavior is MORE COMPLEX than documented**
❌ **Simple bit 4 method doesn't work** (bit inverts)
❌ **Bits 0-3 = 0x0F method doesn't work** (gets rejected)
❌ **Valid page patterns don't change register** (locked?)
❓ **E000:0000 = 0x01 is unexplained** (ROM disabled? Different page?)

## Next Steps

1. Create test to manipulate bit 5
2. Create test to read multiple bytes from E000
3. Try pattern 0x1F (combine bit 4 + bits 0-3)
4. Consider BIOS disassembly approach
5. Review TL/2 technical manual for additional control ports
