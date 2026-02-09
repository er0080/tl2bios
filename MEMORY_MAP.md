# Tandy 1000 TL/2 ROM Memory Map

## Physical ROM Layout (8079044.BIN)

**Total ROM Size:** 512KB (0x80000 bytes) on two 256KB chips

The ROM is organized as **eight 64KB pages** that can be mapped to segment E000:

```
Physical ROM        Page#    Size     Description
------------------  -----    ------   ------------------------------------
0x00000 - 0x0FFFF   Page 1   64 KB    DOS Filesystem (Boot sector + files)
0x10000 - 0x1FFFF   Page 2   64 KB    DOS Files continuation
0x20000 - 0x2FFFF   Page 3   64 KB    DeskMate and utilities
0x30000 - 0x3FFFF   Page 4   64 KB    DeskMate and utilities
0x40000 - 0x4FFFF   Page 5   64 KB    DeskMate and utilities
0x50000 - 0x5FFFF   Page 6   64 KB    DeskMate and utilities
0x60000 - 0x6FFFF   Page 7   64 KB    DeskMate and utilities
0x70000 - 0x7BFFF   Page 8*  48 KB    Remaining DOS files/data
0x7C000 - 0x7FFFF   BIOS     16 KB    System BIOS Code (mapped to F000)
```

*Page 8 is partial, containing ~48KB of data before BIOS code begins

### ROM Paging Control:
- Controlled by **Port FFEA** bits 0-4
- Only one 64KB page visible at E000:0000 at a time
- BIOS switches pages to access different parts of ROM
- Bit 4 of Port FFEA disables all ROM access at E000

## Key Addresses in Physical ROM

### Boot Sector (0x00000)
```
0x00000    EB 34 90              Jump to boot code
0x00003    "TAN  3.3"            OEM ID
0x0000B    DOS BPB               BIOS Parameter Block
0x00036    Boot code start
0x001E0    "IBMBIO  COM"         System file name
0x001EB    "IBMDOS  COM"         DOS kernel name
0x001FE    55 AA                 Boot signature
```

### BIOS Code Section (0x7C000)
```
0x7C000    "!BIOS ROM version 02.00.00"
0x7C01C    "Compatibility Software"
0x7C034    "Copyright (C) 1984,1985,1986,1987,1988"
0x7C05C    "Phoenix Software Associates Ltd."
0x7C07E    "All rights reserved."
0x7C094    "$and Tandy Corporation."

0x7E05B    BIOS entry point (referenced by reset vector)
           This is where POST begins after CPU reset

0x7FFE0    System date marker area
0x7FFF0    EA 5B E0 00 F0        Reset vector (JMP F000:E05B)
0x7FFF5    "04/14/89"            BIOS date string
```

## Logical Memory Map (Runtime)

### ROM Page Frame Window (E000:0000 - E000:FFFF)

The E000 segment is a **64KB page frame window** that can display any one of the eight ROM pages:

```
Logical Address    Physical ROM      Page    Controlled By
-----------------  ----------------  ------  -----------------------------
E000:0000-EFFF     0x00000-0x0FFFF   Page 1  Port FFEA bits 0-4 = 00001
E000:0000-EFFF     0x10000-0x1FFFF   Page 2  Port FFEA bits 0-4 = 00010
E000:0000-EFFF     0x20000-0x2FFFF   Page 3  Port FFEA bits 0-4 = 00100
E000:0000-EFFF     0x30000-0x3FFFF   Page 4  Port FFEA bits 0-4 = 00101
E000:0000-EFFF     0x40000-0x4FFFF   Page 5  Port FFEA bits 0-4 = 01001
E000:0000-EFFF     0x50000-0x5FFFF   Page 6  Port FFEA bits 0-4 = 01010
E000:0000-EFFF     0x60000-0x6FFFF   Page 7  Port FFEA bits 0-4 = 01100
E000:0000-EFFF     0x70000-0x7FFFF   Page 8  Port FFEA bits 0-4 = 01101
E000:0000-EFFF     DISABLED          None    Port FFEA bit 4 = 1
```

### BIOS ROM Mapping (F000:0000 - F000:FFFF)

The BIOS code is separately mapped to F000 segment (not through page frame):

```
Logical Address    Physical ROM       Description
-----------------  -----------------  -----------------------------------
F000:C000          0x7C000            BIOS Code Start
F000:E05B          0x7E05B            POST Entry Point
F000:FFF0          0x7FFF0            Reset Vector (JMP F000:E05B)
F000:FFF5          0x7FFF5            BIOS Date "04/14/89"
F000:FFFF          0x7FFFF            End of BIOS ROM
```

### Memory Controller Address Decode

The DRAM/DMA Control IC (U22) generates **ROMCS-** (ROM Chip Select) for three address ranges:
- **0E0000-0FFFFF** → Maps to E000 segment (page frame)
- **EE0000-EFFFFF** → High memory alias
- **FE0000-FFFFFF** → Maps to F000 segment (BIOS code)

## Standard PC Memory Map (for reference)

```
Address Range      Size     Description
-----------------  -------  ---------------------------------------------
0000:0000          1 KB     Interrupt Vector Table (IVT)
0040:0000          256 B    BIOS Data Area (BDA)
0050:0000          ~638 KB  Conventional Memory
A000:0000          64 KB    Video RAM (EGA/VGA graphics)
B000:0000          32 KB    Monochrome text video RAM
B800:0000          32 KB    Color text video RAM
C000:0000          128 KB   Adapter ROMs and RAM
  C000:0000        16-32KB  Video BIOS
  C800:0000        varies   XT Hard Disk BIOS (if present)
D000:0000          64 KB    Reserved/Adapter ROM space
E000:0000          64 KB    *** ROM PAGE FRAME (TARGET FOR REMOVAL) ***
F000:0000          64 KB    System BIOS
F000:C000          16 KB    System BIOS code (actual code location)
F000:FFF0          16 B     Reset vector
```

## I/O Port Map for ROM Control

### Port FFEA (ROM Paging Control Register)

```
Bit     Function              Description
---     -------------------   ------------------------------------------
0-4     ROM Page Select       Selects which 64KB ROM page appears at E000
                              00000 = No valid page (reserved)
                              00001 = Page 1 (0x00000-0x0FFFF)
                              00010 = Page 2 (0x10000-0x1FFFF)
                              00100 = Page 3 (0x20000-0x2FFFF)
                              00101 = Page 4 (0x30000-0x3FFFF)
                              01001 = Page 5 (0x40000-0x4FFFF)
                              01010 = Page 6 (0x50000-0x5FFFF)
                              01100 = Page 7 (0x60000-0x6FFFF)
                              01101 = Page 8 (0x70000-0x7FFFF)
                              1xxxx = ROM DISABLED (E000 not mapped)

5       System Type           Reserved for TL/SL detection
                              Read-back inverted on TL, normal on SL

6-7     Memory Config         System RAM configuration
                              00 = 512K System Memory
                              01 = 512K System Memory
                              10 = 512K System Memory
                              11 = 640K System Memory
```

**To disable ROM at E000:** Write any value with bit 4 = 1 to Port FFEA
**To enable ROM at E000:** Write page number (0-7) to bits 0-4, with bit 4 = 0

## Memory Usage Analysis

### Current State (ROM Drive Enabled)
- Conventional Memory: 640 KB (0-640KB)
- Upper Memory: Partially occupied
  - Video: A000-BFFF (128 KB)
  - Adapters: C000-DFFF (128 KB)
  - **ROM Drive: E000-EFFF (64 KB) ← OCCUPIED**
  - System BIOS: F000-FFFF (64 KB)

### Target State (ROM Drive Disabled)
- Conventional Memory: 640 KB (unchanged)
- Upper Memory: More available for UMBs
  - Video: A000-BFFF (128 KB)
  - Adapters: C000-DFFF (128 KB)
  - **FREE: E000-EFFF (64 KB) ← AVAILABLE FOR UMBs**
  - System BIOS: F000-FFFF (64 KB)

## DOS UMB (Upper Memory Block) Allocation

With the ROM drive disabled, DOS can use E000-EFFF as UMBs:

```
Example DOS=HIGH,UMB configuration:
  DOS=HIGH,UMB
  DEVICE=HIMEM.SYS
  DEVICE=EMM386.EXE NOEMS I=E000-EFFF
```

This would provide approximately 64 KB of additional upper memory for:
- TSR programs (Terminate and Stay Resident)
- Device drivers
- Network drivers
- Other utilities

## Interrupt Vectors Potentially Affected

The ROM drive likely hooks these interrupts:

```
INT 13h  Disk Services
         - Function to handle ROM drive as a disk
         - Need to ensure it doesn't try to access E000

INT 19h  System Bootstrap Loader
         - Determines boot device
         - May need patching to skip ROM drive

INT 40h  Original INT 13h vector (sometimes)
         - BIOS may chain disk services
```

## Critical Code Sections to Locate

For the modification, we need to find:

1. **POST Initialization Code**
   - Starts at F000:E05B
   - Sets up interrupt vectors
   - Initializes hardware

2. **ROM Drive Detection/Setup**
   - Code that maps E000 segment
   - Sets up INT 13h for ROM drive
   - Registers ROM drive as bootable device

3. **Bootstrap Code**
   - INT 19h handler
   - Boot device selection logic
   - May try to boot from E000 first

## Segment Registers and E000

Watch for these instruction patterns that set up E000:

```assembly
MOV  AX, 0E000h    ; Load E000 into AX
MOV  DS, AX        ; Set data segment to E000
; or
MOV  ES, AX        ; Set extra segment to E000

PUSH 0E000h        ; Push E000 onto stack
POP  ES            ; Pop into ES
```

These patterns indicate ROM drive access and are candidates for patching.

## Hardware Implementation Details

### Memory Controller (DRAM/DMA Control IC - U22)

The ROM paging is controlled by a custom memory controller IC:

**Address Decode Logic**:
- Monitors CPU address lines A17-A23
- Generates ROMCS- signal for three address ranges:
  - 0E0000-0FFFFF (E000 segment - 64KB page frame)
  - EE0000-EFFFFF (high memory alias)
  - FE0000-FFFFFF (F000 segment - BIOS code)
- Active only when REFRESH- is inactive and CPHLDA is inactive
- Latched by ALE (Address Latch Enable) signal

**Page Register Control**:
- Port FFEA stores the ROM paging configuration
- Bits 0-4 select which 64KB page is visible at E000
- According to handwritten notes in technical docs, bit 4 may disable ROM when set
- This needs verification through testing

**Physical ROM Chips**:
- U54, U55: ROM0 (256KB) - Contains pages 1-4
- U56, U57: ROM1 (256KB) - Contains pages 5-8
- PLS173 IFL (U44) generates chip enables (RPCS-1, RPCS-2)
- Address lines SA1-SA15 provide lower address bits
- Page select provides upper address bits

## Next Analysis Steps

### Phase 1: Test Port FFEA Method (PRIORITY)

1. **Create test utility** to manipulate Port FFEA
   - Read current value
   - Set bit 4 to attempt ROM disable
   - Verify bit 4 persists when read back
   - Test memory access at E000:0000

2. **Verify system stability**
   - Boot with ROM disabled via Port FFEA
   - Test BIOS functions (no crashes)
   - Check if DeskMate or ROM utilities affected
   - Confirm E000 range is accessible to DOS

3. **If successful**: Create DOS driver or BIOS patch

### Phase 2: BIOS Code Analysis (if Port FFEA fails)

1. **Disassemble BIOS**
   - Start at F000:E05B (ROM offset 0x7E05B) - POST entry point
   - Trace initialization sequence
   - Look for Port FFEA I/O operations
   - Document ROM page frame setup

2. **Locate key code sections**:
   - INT 13h disk handler setup
   - INT 19h bootstrap loader
   - Port FFEA write operations
   - Memory controller initialization
   - ROM drive registration

3. **Identify patch points**:
   - Code that enables ROM at E000
   - Minimal changes needed to skip ROM init
   - Preserve other BIOS functions
   - Calculate checksums if needed

4. **Create modified BIOS**:
   - Apply patches
   - Verify checksum (if used)
   - Test in emulator first
   - Flash to ROM chip with recovery plan

### Phase 3: Hardware Modification (last resort)

If software methods fail:
1. Trace ROMCS- signal path
2. Consider cutting trace or pull-up resistor
3. Modify PLS173 IFL logic (requires PAL programmer)
4. Document changes for reversibility

### Testing Requirements

- Test hardware (real Tandy 1000 TL/2 or emulator)
- ROM programmer (if BIOS modification needed)
- Backup ROM chips
- DOS boot disk with diagnostic tools
- EMM386.EXE or similar UMB manager for testing
