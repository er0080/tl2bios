# BIOS Patch Strategy - ROM Disable

## Critical Discovery

**The BIOS NEVER writes the 0x?F pattern (bits 0-3 = 1111) to Port FFEA.**

This means:
- Port FFEA is ONLY used for ROM page selection (pages 0-7)
- There is NO "disable ROM" pattern in Port FFEA
- The handwritten note about "bit 4 disables ROM" was incorrect
- Hardware testing confirmed: pattern 0x0F gets rejected by hardware

## The Real Question

**If Port FFEA doesn't have a disable mode, how do we free E000?**

### Theory 1: Don't Initialize Port FFEA

If BIOS never writes to Port FFEA, what happens?
- Port FFEA contains random/undefined value after reset
- ROM page frame may not be mapped at E000
- E000 region might be unoccupied memory

**Test this by:**
- NOP out the OUT instruction at F000:C4C6
- NOP out the OUT instruction at F000:C91B
- See if system boots and E000 is available

### Theory 2: Write Invalid Page Number

Write a page number outside valid range (8-15):
- Pages 0-7 are valid (512KB = 8 pages)
- Maybe page 8+ results in no ROM mapped

**Test values:**
- 0xC9 (page 9) - one beyond last page
- 0xCF (page 15) - maximum page number
- 0xD0 (page 16) - requires bit 4 = 1

### Theory 3: There's Another Control Port

Maybe Port FFEA works with another port to enable/disable ROM:
- A master enable/disable bit elsewhere
- A memory controller configuration port
- A chipset-specific register

**Need to review:**
- `doc/TL2_mem_controller.pdf` for all I/O ports
- Memory controller specifications
- Chipset documentation

### Theory 4: BIOS Sets ROM Page Then Expects DOS to Control It

Maybe the BIOS just initializes ROM paging and expects:
- DOS or drivers to change pages as needed
- Programs to request ROM drive access
- INT 13h handler to manage page switching

If we prevent BIOS from setting up ROM paging, INT 13h won't work, but E000 might be free.

## Proposed BIOS Patches

### Patch A: NOP Out All Port FFEA Writes (Most Conservative)

**Location 1: F000:C4C6 (ROM 0x7C4C6)**
```
Before: BA EA FF B0 C8 EE
        MOV DX, 0xFFEA
        MOV AL, 0xC8
        OUT DX, AL

After:  BA EA FF B0 C8 90
        MOV DX, 0xFFEA
        MOV AL, 0xC8
        NOP
```
Change byte at 0x7C4CB from 0xEE to 0x90

**Location 2: F000:C91B (ROM 0x7C91B)**
```
Before: BA EA FF ... B0 C8 EE
        MOV DX, 0xFFEA
        ...
        MOV AL, 0xC8
        OUT DX, AL

After:  BA EA FF ... B0 C8 90
        MOV DX, 0xFFEA
        ...
        MOV AL, 0xC8
        NOP
```
Change byte at 0x7C927 from 0xEE to 0x90

**Expected result:**
- Port FFEA never gets written by BIOS
- ROM paging remains uninitialized
- E000 region might be inaccessible (desired!)
- System should still boot from F000 BIOS

**Risks:**
- BIOS might depend on ROM being mapped for some operations
- INT 13h ROM drive handler won't work (acceptable)
- System might hang if BIOS expects ROM available

### Patch B: Write Invalid Page Number

Change 0xC8 to 0xC9 (page 9, invalid):

**Location 1: F000:C4C6 (ROM 0x7C4C8)**
```
Before: B0 C8        MOV AL, 0xC8
After:  B0 C9        MOV AL, 0xC9
```
Change byte at 0x7C4C8 from 0xC8 to 0xC9

**Location 2: F000:C91B (ROM 0x7C925)**
```
Before: B0 C8        MOV AL, 0xC8
After:  B0 C9        MOV AL, 0xC9
```
Change byte at 0x7C925 from 0xC8 to 0xC9

**Expected result:**
- Hardware tries to map page 9 (doesn't exist)
- ROM chip selects might both go inactive
- E000 region becomes unoccupied

### Patch C: Set Page 0 (Conservative Test)

Change 0xC8 to 0xC0 (page 0):

This maps a different ROM page. If page 0 has no boot signature, DOS might ignore it.

## Testing Plan

### Step 1: Create Test BIOS Images

Create three modified ROM files:
1. `NOROM_PATCH_A.BIN` - NOP out Port FFEA writes
2. `NOROM_PATCH_B.BIN` - Write invalid page 9
3. `NOROM_PATCH_C.BIN` - Write page 0 instead of page 8

### Step 2: Test in Emulator (if available)

Boot each modified BIOS in TL/2 emulator to check:
- Does system boot?
- Any BIOS errors?
- Can we get to DOS prompt?

### Step 3: Test on Real Hardware

Using socketed ROM or ROM emulator:
1. Boot with modified BIOS
2. Check if system boots to DOS
3. Run DEBUG to check E000:0000 content
4. Run MEM to see if E000 is available
5. Test EMM386 with I=E000-EFFF

### Step 4: Document Results

For each patch, record:
- Boot success/failure
- E000:0000 content
- Port FFEA value
- System stability
- UMB availability

## Alternative: POST Hook Method

Instead of modifying BIOS ROM, use a bootable floppy with custom boot sector that:
1. Boots minimal DOS from floppy
2. Early in boot, write to Port FFEA (try various patterns)
3. Then load DOS normally
4. Check if E000 is free

This is **safer** than BIOS modification and easier to test.

## Memory Controller Deep Dive Needed

Before patching BIOS, we should:

1. **Read doc/TL2_mem_controller.pdf thoroughly**
   - Find all I/O ports used by memory controller
   - Look for ROM enable/disable bits
   - Check for address decode configuration

2. **Search for other control ports**
   - Port ranges: 0x60-0x6F, 0x80-0x9F, 0xA0-0xBF
   - Chipset-specific ports
   - DIP switch or jumper settings

3. **Understand ROMCS signal generation**
   - How are ROMCS#0 and ROMCS#1 generated?
   - Can they be forced inactive?
   - Is there a master ROM enable bit?

## Recommended Next Action

**Before modifying BIOS, let's thoroughly analyze the memory controller documentation.**

The answer might be:
- A different I/O port controls ROM enable/disable
- Port FFEA works with another port
- A specific initialization sequence is needed
- Hardware doesn't support ROM disable at all

Would you like to:
1. Create the test BIOS patches and try them?
2. Deep dive into memory controller documentation first?
3. Try POST hook method (safer)?
