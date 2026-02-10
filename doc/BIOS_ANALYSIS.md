# BIOS ROM Paging Analysis

## Summary

Found **7 references to Port FFEA** in the BIOS code. Two locations write **0xC8** during initialization.

## Key BIOS Locations

### Location 1: F000:C4C6 (ROM offset 0x7C4C6)

```assembly
BA EA FF        MOV DX, 0xFFEA    ; Load Port FFEA address
B0 C8           MOV AL, 0xC8      ; Load value 0xC8
EE              OUT DX, AL        ; Write to Port FFEA
```

**Value 0xC8 = 11001000 binary:**
- Bits 0-3: **1000** (selects ROM page 8)
- Bit 4: **0** (ROM enabled)
- Bit 5: **1** (system type)
- Bits 6-7: **11** (640K memory configuration)

### Location 2: F000:C91B (ROM offset 0x7C91B)

```assembly
BA EA FF        MOV DX, 0xFFEA    ; Load Port FFEA address
BB 00 00        MOV BX, 0x0000    ; Setup segment registers
8E DB           MOV DS, BX
BF 00 80        MOV DI, 0x8000    ; DI = 0x8000
B0 C8           MOV AL, 0xC8      ; Load value 0xC8
EE              OUT DX, AL        ; Write to Port FFEA
B9 08 00        MOV CX, 0x0008    ; Loop counter = 8
26 8A 1F        MOV BL, ES:[DI]   ; Loop begins (8 ROM pages?)
E2 FB           LOOP ...
```

This appears to be ROM initialization with a loop through all 8 pages.

## All Port FFEA References

| ROM Offset | F000:Offset | Type | Description |
|------------|-------------|------|-------------|
| 0x7C4C6 | F000:C4C6 | WRITE | **Writes 0xC8 to Port FFEA** |
| 0x7C91B | F000:C91B | WRITE | **Writes 0xC8 to Port FFEA** (with loop) |
| 0x7D76D | F000:D76D | READ | Reads Port FFEA (IN AL, DX) |
| 0x7D795 | F000:D795 | WRITE | Writes computed value |
| 0x7DAD0 | F000:DAD0 | READ | Reads Port FFEA |
| 0x7DAE3 | F000:DAE3 | READ | Reads Port FFEA |
| 0x7DB67 | F000:DB67 | READ | Reads Port FFEA |

## Critical Finding: BIOS vs Hardware State Mismatch

### BIOS writes: 0xC8 (11001000)
- ROM page 8 selected
- 640K memory config

### Hardware test showed: 0x22 (00100010)
- ROM page 2 selected
- 512K memory config

**Why the difference?**
1. Something else writes to Port FFEA after BIOS initialization
2. DOS or a driver changes the page
3. Our test utility changed it before reading
4. The system has 512K, so bits 6-7 get forced to 00

## Patch Strategy Options

### Option A: NOP Out the OUT Instruction

**At F000:C4C6 (ROM 0x7C4C6):**
```
Before: BA EA FF B0 C8 EE        MOV DX,0xFFEA; MOV AL,0xC8; OUT DX,AL
After:  BA EA FF B0 C8 90        MOV DX,0xFFEA; MOV AL,0xC8; NOP
```

**Pros:**
- Simple one-byte change (EE → 90)
- Prevents Port FFEA write at this location
- Reversible

**Cons:**
- Port FFEA will contain undefined/random value
- May cause instability if ROM paging is needed
- Still need to patch location 2 (F000:C91B)

### Option B: Change 0xC8 to Disable ROM

**At F000:C4C6 (ROM 0x7C4C6):**
```
Before: B0 C8        MOV AL, 0xC8
After:  B0 XX        MOV AL, 0xXX   (where XX disables ROM)
```

**Problem:** We don't know what value disables ROM!
- 0x10 doesn't work (bit 4 inverts)
- 0x0F doesn't work (hardware rejects it)
- 0x?? = Unknown

**Need to find the magic value through:**
1. More hardware testing
2. Analysis of ROM paging decode logic
3. Trial and error with BIOS patches

### Option C: Add Code to Disable ROM After OUT

Insert additional instructions after the OUT to disable ROM:

```assembly
BA EA FF        MOV DX, 0xFFEA
B0 C8           MOV AL, 0xC8
EE              OUT DX, AL        ; Original initialization
; ADD NEW CODE HERE:
B0 XX           MOV AL, 0xXX      ; Load disable value
EE              OUT DX, AL        ; Disable ROM
90 90           NOP; NOP          ; Padding if needed
```

**Pros:**
- Allows normal BIOS ROM setup first
- Then disables ROM for DOS
- More likely to be stable

**Cons:**
- Requires more space (need to fit 3-5 bytes)
- May need to relocate other code
- Still need the magic disable value

### Option D: Change ROM Page to Invalid/High Value

Try writing a page number above 8 (e.g., 0x0F, 0x1F):

```
Before: B0 C8        MOV AL, 0xC8   (page 8)
After:  B0 CF        MOV AL, 0xCF   (page 15 - invalid?)
```

This might cause hardware to disable ROM when selecting invalid page.

## Hardware Testing Needed

Before patching BIOS, we need to find a Port FFEA value that actually disables ROM:

### Test 1: Try High Page Numbers
```
Pattern 0x0F: 11001111 (bits 0-3 = 1111, page 15)
Pattern 0x1F: 11011111 (bit 4=1, bits 0-3=1111)
Pattern 0x2F: 11101111 (bit 5=0, bits 0-3=1111)
```

### Test 2: Try Clearing All Paging Bits
```
Pattern 0xC0: 11000000 (clear bits 0-4, keep 6-7)
Pattern 0x20: 00100000 (only bit 5 set)
Pattern 0x00: 00000000 (all clear)
```

### Test 3: Study the Decode Logic
Review `doc/TL2_mem_controller.pdf` to understand:
- How ROMCS signals are generated
- What patterns disable both ROM chips
- If there's a master disable

## Recommended Next Steps

### Step 1: Create Comprehensive Port FFEA Test Utility

Test ALL possible patterns (0x00-0xFF) systematically:
- Write each pattern
- Read back Port FFEA
- Check E000:0000 content
- Document which patterns actually disable ROM

### Step 2: Analyze POST Flow

Disassemble the POST code starting at F000:E05B to understand:
- When are the Port FFEA writes called?
- What initialization depends on ROM being mapped?
- Can we safely skip ROM initialization?

### Step 3: Examine Location 2 Code (F000:C91B)

The loop with CX=8 suggests it's reading all 8 ROM pages:
```assembly
B9 08 00        MOV CX, 0x0008    ; 8 iterations
26 8A 1F        MOV BL, ES:[DI]   ; Read from ROM
E2 FB           LOOP ...
```

This might be:
- Checksumming ROM pages
- Detecting ROM size
- Copying data from ROM

We need to understand if this loop is critical for boot.

### Step 4: Create Test BIOS Image

1. Copy `8079044.BIN` to `8079044_MODIFIED.BIN`
2. Apply patch to Location 1 (F000:C4C6)
3. Apply patch to Location 2 (F000:C91B)
4. Test in emulator first
5. Flash to spare ROM chip
6. Test on real hardware

## Risks and Safety

### Low Risk Patches:
- Changing 0xC8 to another page number (0x00-0x0D)
- Adding NOP instructions

### Medium Risk Patches:
- Changing 0xC8 to untested values (0x0F-0xFF)
- Skipping the CX=8 loop at F000:C91B

### High Risk Patches:
- NOPing out critical initialization code
- Changing jump targets
- Modifying reset vector

### Safety Measures:
1. **Always keep original ROM chip**
2. **Test in emulator first** (if TL/2 emulator available)
3. **Use socketed ROM** for easy recovery
4. **Have backup boot method** (floppy)
5. **Document all changes** for reversibility

## Files Needed

- [ ] ROM disassembler output (full BIOS section)
- [ ] Comprehensive Port FFEA test utility (all patterns 0x00-0xFF)
- [ ] BIOS patch utility (to modify ROM file)
- [ ] Checksum calculator (if BIOS has checksum)

## Next Actions

1. Create comprehensive Port FFEA pattern test (0x00-0xFF)
2. Run on hardware to find ROM disable pattern
3. Disassemble POST entry and ROM init sections
4. Create patch once we know the correct pattern
5. Test modified BIOS in safe environment
