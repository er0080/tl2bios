# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Tandy 1000 TL/2 ROM Disable Project** - a vintage computing project providing a DOS device driver to disable ROM at memory address E000:0000 on Tandy 1000 TL/2 hardware. The project enables ~60KB of additional upper memory (UMBs) for DOS by freeing the ROM page frame window.

**Current Status:** ✅ PRODUCTION READY - The NOROM.SYS device driver has been verified working on real Tandy 1000 TL/2 hardware.

## Build Commands

### Building All Utilities

```batch
cd src
BUILD.BAT
```

This creates:
- `PORTREAD.COM` - Simple Port FFEA test utility
- `TESTROM.COM` - Comprehensive ROM disable verification test
- `DIAGNOSE.COM` - Diagnostic tool for ROM reading issues
- `NOROM.SYS` - Production DOS device driver (main deliverable)

### Building Individual Programs

All programs use Turbo Assembler (TASM) and Turbo Link (TLINK):

```batch
TASM NOROM.ASM
TLINK /T NOROM.OBJ
REN NOROM.COM NOROM.SYS
```

The `/T` flag creates tiny model executables (.COM files). NOROM.SYS is technically a .COM renamed to .SYS for DOS device driver loading.

### Build Requirements

- **Assembler:** TASM (Turbo Assembler) 2.0 or later
- **Linker:** TLINK (Turbo Link)
- **Environment:** DOS or DOS emulator (DOSBox, FreeDOS)
- **Target Platform:** Real Tandy 1000 TL/2 hardware (emulators won't accurately test Port FFEA behavior)

## Architecture & Key Concepts

### ROM Paging System

The Tandy 1000 TL/2 uses a **paging system** for its 512KB ROM:
- Total ROM: 512KB organized as 8 pages of 64KB each
- Page frame window: 64KB at memory address E000:0000
- Control port: I/O Port FFEA (hex)
- Only ONE page visible at E000 at any given time
- System BIOS code is separately mapped at F000:C000-F000:FFFF

### Port FFEA Register (Critical)

```
Bit     Function
0-4     ROM Page Select (which 64KB page appears at E000)
4       ROM Disable (1 = disabled, 0 = enabled) ⭐ KEY FEATURE
5       System Type (TL/SL detection)
6-7     Memory Configuration (512K vs 640K)
```

**The handwritten note in the TL/2 technical documentation was correct:** Setting bit 4 to 1 disables ROM access at E000, freeing the memory range for DOS UMBs.

### Memory Layout

```
Address Range      Description
A000-BFFF         Video RAM (128KB)
C000-DFFF         Adapter ROMs/RAM (128KB)
E000-EFFF         ROM Page Frame Window (64KB) ← TARGET FOR REMOVAL
F000-FFFF         System BIOS (64KB, separately mapped)
```

### Solution Architecture

**NOROM.SYS** is a DOS device driver that:
1. Loads during CONFIG.SYS processing (before EMM386)
2. Reads current Port FFEA value
3. Sets bit 4 to disable ROM at E000
4. Verifies the bit persisted
5. Displays status message
6. Unloads itself (zero resident memory footprint)

The driver uses standard DOS device driver structure with Strategy/Interrupt routines and init-only code section.

## Code Structure

### Source Files (`src/`)

- **norom.asm** - Production device driver (MAIN DELIVERABLE)
  - Standard DOS device driver header at offset 0
  - Strategy routine: Saves request header pointer from DOS
  - Interrupt routine: Processes INIT command, sets Port FFEA bit 4
  - PrintMessage routine: Displays boot messages via INT 21h
  - Init-only driver (discards all code after initialization)

- **testrom.asm** - Hardware verification utility
  - Reads Port FFEA before/after bit 4 set
  - Checks E000:0000 content before/after ROM disable
  - Restores original Port FFEA value
  - Used to verify the method works on hardware

- **diagnose.asm** - Diagnostic tool
  - Tests display routines with known values
  - Verifies ROM reading via DS and ES segments
  - Isolates issues when ROM reading fails

- **portread.asm** - Minimal Port FFEA test
  - Reads Port FFEA, sets bit 4, displays results
  - Simplest test to verify bit 4 persistence

### Documentation Files

- **README.md** - Project overview and quick start
- **doc/NOROM_DRIVER.md** - Complete NOROM.SYS installation guide
- **doc/ANALYSIS.md** - ROM structure analysis and approach evaluation
- **doc/MEMORY_MAP.md** - Detailed memory layout and Port FFEA documentation
- **doc/PORT_FFEA_TEST.md** - Hardware testing procedures

### Data Files

- **8079044.BIN** - Original 512KB ROM dump from Tandy 1000 TL/2
  - Phoenix BIOS version 02.00.00 dated 04/14/89
  - Contains DOS filesystem with Tandy DOS 3.3 and DeskMate
  - BIOS code in last 16KB (offset 0x7C000-0x7FFFF)
  - Reset vector at 0x7FFF0 jumps to F000:E05B (POST entry point)

## Important Technical Details

### 8086 vs 80286 Compatibility

The TL/2 has an 80286 processor but runs in real mode (8086 compatible). All assembly code uses 8086 instruction set and avoids 286-specific instructions for maximum compatibility.

### Segment Usage in Assembly

When reading E000:0000, the code uses explicit segment override:
```assembly
push ds
mov ax, 0E000h
mov ds, ax
mov al, [0]        ; Read from E000:0000
pop ds
```

### Device Driver Structure

DOS device drivers MUST:
- Start at offset 0 (use `ORG 0`)
- Have device header as first structure
- Implement Strategy and Interrupt routines
- Return proper status codes in request header
- Set end address of resident code (or 0 for init-only)

### Port I/O Timing

After writing to Port FFEA, the code includes small delays:
```assembly
out dx, al
jmp short $+2      ; Delay for hardware to settle
jmp short $+2
in al, dx          ; Now read back
```

This ensures the hardware has time to latch the new value.

## Testing Notes

### Hardware Testing Only

The Port FFEA method **cannot be tested in emulators** (DOSBox, PCem, etc.). These utilities will compile and run but won't produce meaningful results since emulators emulate standard PC hardware, not Tandy-specific Port FFEA functionality.

### Hardware Test Results

See `src/OUT.LOG` for actual test results from real Tandy 1000 TL/2 hardware. Key findings:
- Port FFEA before: 0xC8 (ROM enabled)
- Port FFEA after: 0xD8 (bit 4 set successfully)
- E000:0000 before: 0xEB (ROM boot signature)
- E000:0000 after: 0xFF (ROM disabled, floating bus)
- System stability: STABLE ✅

## CONFIG.SYS Integration

Proper CONFIG.SYS order is critical:

```
DEVICE=C:\DOS\HIMEM.SYS
DEVICE=C:\DOS\NOROM.SYS         ← MUST be before EMM386
DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF
DOS=HIGH,UMB
```

NOROM.SYS must load **before** EMM386.EXE so the ROM is disabled when EMM386 scans upper memory.

## Development Conventions

### Assembly Style

- Use TASM syntax (not MASM or NASM)
- `.MODEL TINY` for .COM programs
- `.CODE` section starts code
- Use `PROC`/`ENDP` for procedures
- `$`-terminated strings for INT 21h function 09h

### Commenting

Code includes detailed comments explaining:
- Purpose of each section
- Register usage
- DOS/BIOS interrupt conventions
- Hardware-specific behavior

### Error Handling

NOROM.SYS handles three states:
1. Success - ROM disabled successfully
2. Already disabled - ROM was already disabled
3. Failure - Bit 4 didn't persist (shows warning)

All states are non-fatal; driver always completes initialization.

## Project History

This project explored multiple approaches to disable ROM at E000:

1. **Port FFEA Control** ✅ - WORKING SOLUTION
   - Simplest approach based on handwritten documentation note
   - Verified on hardware
   - Became the production solution

2. **BIOS Code Modification** ⏳ - Not needed
   - Would require disassembly of BIOS POST code
   - Higher risk (could brick system)
   - Unnecessary since Port FFEA method works

3. **Hardware Modification** ⚠️ - Last resort
   - Would require cutting traces or modifying PALs
   - Destructive and risky
   - Unnecessary since Port FFEA method works

The Port FFEA method proved to be the correct approach, validating the handwritten note in the technical documentation.

## File Path Conventions

- Root directory: Documentation and ROM dump
- `src/`: Assembly source code and BUILD.BAT
- `doc/`: Technical reference materials
- All assembly source uses `.asm` extension
- Executables use `.COM` or `.SYS` extension

## Safety and Compatibility

- NOROM.SYS is specific to Tandy 1000 TL/2
- May work on TL/3 and original TL (untested)
- Will NOT work on other Tandy 1000 models (different architecture)
- Safe to use - simply remove from CONFIG.SYS to revert
- No BIOS modification or hardware changes required
- Zero risk of damaging the system

## Known Limitations

- Only tested on Tandy 1000 TL/2 hardware
- Requires DOS with UMB support (DOS 5.0+ with EMM386)
- ROM page frame becomes completely inaccessible (can't boot from ROM drive)
- DeskMate and ROM utilities won't work with ROM disabled
