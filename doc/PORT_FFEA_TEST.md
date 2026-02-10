# Port FFEA ROM Disable Testing

## Overview

According to a handwritten note in the Tandy 1000 TL/2 technical documentation:
> "Writing 1 to bit 4 disables access to the ROM segment at E0000"

This document outlines the testing procedure to verify if this method works.

## Port FFEA Register Definition

```
Bit     Function              Value
---     -------------------   ------------------------------------------
0-4     ROM Page Select       Which 64KB ROM page appears at E000
                              00001 = Page 1 (0x00000-0x0FFFF)
                              00010 = Page 2 (0x10000-0x1FFFF)
                              00100 = Page 3 (0x20000-0x2FFFF)
                              00101 = Page 4 (0x30000-0x3FFFF)
                              01001 = Page 5 (0x40000-0x4FFFF)
                              01010 = Page 6 (0x50000-0x5FFFF)
                              01100 = Page 7 (0x60000-0x6FFFF)
                              01101 = Page 8 (0x70000-0x7FFFF)
                              1xxxx = ROM DISABLED? (UNVERIFIED)

5       System Type           Reserved for TL/SL detection
                              (bit is inverted on read for TL systems)

6-7     Memory Config         00/01/10 = 512K, 11 = 640K
```

## Theory of Operation

If bit 4 acts as a ROM disable:
- Setting bit 4 = 1 should prevent ROM mapping at E000:0000
- Memory controller won't assert ROMCS- for E000 addresses
- E000-EFFF becomes available as regular RAM/UMB space
- BIOS at F000 should continue working normally

## Test Procedure

### Phase 1: Basic Port Access Test

1. Boot DOS on Tandy 1000 TL/2
2. Run test utility to read Port FFEA
3. Display current value
4. Write value with bit 4 set
5. Read back and verify bit 4 persists
6. Check for system stability

### Phase 2: Memory Access Test

1. Set bit 4 in Port FFEA
2. Attempt to read from E000:0000
3. Expected behavior (if method works):
   - Read returns 0xFF (floating bus) or random data
   - OR read returns last value on bus
   - NOT the ROM boot sector (EB 34 90 "TAN  3.3")
4. Attempt to write to E000:0000
5. Read back to verify write
6. If write succeeded → ROM is disabled, memory is accessible

### Phase 3: System Stability Test

1. With ROM disabled:
   - Boot system normally
   - Run DOS commands
   - Test BIOS functions
   - Check for crashes or hangs
   - Verify F000 BIOS still works
2. Re-enable ROM (clear bit 4)
3. Verify ROM access restored

### Phase 4: EMM386 Integration Test

1. Configure CONFIG.SYS:
   ```
   DEVICE=C:\TEST\NOROM.SYS
   DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF
   ```
2. Boot system
3. Run MEM /C /P to check UMB allocation
4. Verify E000-EFFF shows as available UMB
5. Load programs into UMBs
6. Test system stability

## Test Programs

### Test 1: Port FFEA Reader/Writer (DOS DEBUG)

```
C:\>DEBUG
-A 100
MOV DX, FFEA      ; Port FFEA address
IN  AL, DX        ; Read current value
PUSH AX           ; Save it
CALL 0120         ; Display it (subroutine)
POP AX            ; Restore
OR  AL, 10        ; Set bit 4
OUT DX, AL        ; Write back
IN  AL, DX        ; Read again
CALL 0120         ; Display new value
INT 20            ; Exit to DOS

-A 120            ; Display subroutine
PUSH AX
MOV AH, 02
MOV DL, AL
SHR DL, 4
ADD DL, 30
CMP DL, 39
JBE 0134
ADD DL, 07
INT 21            ; Print high nibble
POP AX
PUSH AX
AND AL, 0F
MOV DL, AL
ADD DL, 30
CMP DL, 39
JBE 0147
ADD DL, 07
INT 21            ; Print low nibble
POP AX
RET

-G               ; Run program
-Q               ; Quit DEBUG
```

### Test 2: E000 Memory Access Test (Simplified)

```dos
C:\>DEBUG
-E E000:0000     ; Try to examine E000:0000
```

Expected results:
- **Before disabling**: Shows ROM data (EB 34 90 54 41 4E 20 20 33 2E 33...)
- **After Port FFEA bit 4 set**: Shows FF FF or random data or allows write

### Test 3: Simple ASM Test Program

```assembly
; TESTROM.ASM - Test Port FFEA ROM disable
; Assemble with: TASM TESTROM.ASM
; Link with: TLINK /T TESTROM.OBJ
; Creates TESTROM.COM

.MODEL TINY
.CODE
.STARTUP

main:
    ; Display banner
    mov dx, OFFSET banner
    mov ah, 09h
    int 21h

    ; Read and display initial Port FFEA value
    mov dx, 0FFFEAh
    in  al, dx
    mov bl, al              ; Save original
    call DisplayHex
    call NewLine

    ; Display ROM content at E000:0000 before disable
    mov dx, OFFSET before_msg
    mov ah, 09h
    int 21h

    push ds
    mov ax, 0E000h
    mov ds, ax
    mov al, [0]
    pop ds
    call DisplayHex
    call NewLine

    ; Disable ROM by setting bit 4
    mov dx, 0FFEAh
    mov al, bl
    or  al, 10h             ; Set bit 4
    out dx, al

    ; Read back Port FFEA
    in  al, dx
    mov dl, OFFSET after_msg
    mov ah, 09h
    int 21h
    call DisplayHex
    call NewLine

    ; Display E000:0000 after disable
    mov dx, OFFSET check_msg
    mov ah, 09h
    int 21h

    push ds
    mov ax, 0E000h
    mov ds, ax
    mov al, [0]
    pop ds
    call DisplayHex
    call NewLine

    ; Restore original value
    mov dx, 0FFEAh
    mov al, bl
    out dx, al

    ; Exit
    mov ax, 4C00h
    int 21h

DisplayHex PROC
    ; Display AL in hex
    push ax
    shr al, 4
    call DisplayNibble
    pop ax
    and al, 0Fh
    call DisplayNibble
    ret
DisplayHex ENDP

DisplayNibble PROC
    add al, '0'
    cmp al, '9'
    jbe @ok
    add al, 7
@ok:
    mov dl, al
    mov ah, 02h
    int 21h
    ret
DisplayNibble ENDP

NewLine PROC
    mov dx, OFFSET crlf
    mov ah, 09h
    int 21h
    ret
NewLine ENDP

banner      db 'Port FFEA ROM Disable Test', 13, 10, '$'
before_msg  db 'Before: FFEA=', '$'
after_msg   db 'After:  FFEA=', '$'
check_msg   db 'E000:0000=', '$'
crlf        db 13, 10, '$'

END
```

## Expected Results

### If Port FFEA Method Works:

1. **Port FFEA bit 4 persists** when written and read back
2. **E000:0000 content changes** after bit 4 set:
   - Before: EB 34 90 54 41 4E... (ROM boot sector)
   - After: FF or random data (no ROM)
3. **Memory becomes writeable** at E000
4. **System remains stable** with ROM disabled
5. **BIOS at F000 continues working** normally
6. **EMM386 can allocate E000-EFFF** as UMBs

### If Port FFEA Method Fails:

1. Bit 4 may not persist (resets to 0 on read)
2. E000:0000 still shows ROM data
3. Memory remains read-only at E000
4. System may become unstable
5. Need to pursue BIOS modification approach

## Safety Precautions

- ⚠️ **Test on real hardware at your own risk**
- Have a backup boot disk ready
- Don't flash modified BIOS until Port method tested
- Be prepared to power cycle if system hangs
- Document all observations carefully

## Troubleshooting

**System hangs after setting bit 4:**
- Power cycle to restore
- ROM disable may have broken critical function
- Try setting different bit patterns
- Consider BIOS modification instead

**Bit 4 doesn't persist:**
- May be read-only or have special behavior
- Check if bit 5 detection affects bit 4
- Hardware may force bit 4 low
- Proceed to BIOS disassembly

**E000 still shows ROM data:**
- Port FFEA control may work differently
- Bit 4 may not be ROM disable
- Need to find actual ROM control mechanism
- Analyze BIOS code for answers

## Next Steps Based on Results

### If Port FFEA Works:
1. Create DOS device driver (NOROM.SYS)
2. OR create BIOS patch that sets bit 4 during POST
3. Test with various DOS configurations
4. Release solution to community

### If Port FFEA Fails:
1. Disassemble BIOS starting at F000:E05B
2. Trace POST initialization
3. Find ROM page frame setup code
4. Identify where to patch
5. Create modified BIOS ROM
6. Test in emulator before hardware
7. Flash to spare ROM chip

## Documentation of Test Results

Please document your findings here:

**Test Date:** _________________

**Hardware:** Tandy 1000 TL/2 Serial #: _________________

**Initial Port FFEA Value:** 0x____

**After Setting Bit 4:** 0x____

**E000:0000 Before:** ____________________________________

**E000:0000 After:** ____________________________________

**System Stability:** □ Stable  □ Unstable  □ Crash

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
