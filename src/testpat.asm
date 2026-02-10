; TESTPAT.ASM - Test various Port FFEA bit patterns
; Diagnostic tool to understand which patterns the hardware accepts
;
; Assemble with: TASM TESTPAT.ASM
; Link with: TLINK /T TESTPAT.OBJ

.MODEL TINY
.CODE
 ORG 100h

start:
    ; Display banner
    mov dx, OFFSET banner
    mov ah, 09h
    int 21h

    ; Read and save original Port FFEA value
    mov dx, 0FFEAh
    in  al, dx
    mov byte ptr [original], al

    mov dx, OFFSET original_msg
    mov ah, 09h
    int 21h
    call DisplayHex
    call NewLine
    call NewLine

    ; Test Pattern 1: Try to set bits 0-3 = 1111 (0x0F)
    mov dx, OFFSET test1_msg
    mov ah, 09h
    int 21h

    mov al, byte ptr [original]
    mov byte ptr [before], al
    call DisplayHex
    call PrintArrow

    ; Calculate new value
    and al, 0E0h            ; Clear bits 0-4
    or  al, 0Fh             ; Set bits 0-3
    mov byte ptr [write_val], al
    call DisplayHex
    call PrintArrow

    ; Write it
    mov dx, 0FFEAh
    out dx, al
    jmp short $+2
    jmp short $+2

    ; Read back
    in  al, dx
    mov byte ptr [after], al
    call DisplayHex
    call NewLine

    ; Restore original
    mov al, byte ptr [original]
    out dx, al

    ; Test Pattern 2: Try to set bit 4 only (0x10)
    mov dx, OFFSET test2_msg
    mov ah, 09h
    int 21h

    mov al, byte ptr [original]
    call DisplayHex
    call PrintArrow

    or  al, 10h             ; Set bit 4
    mov byte ptr [write_val], al
    call DisplayHex
    call PrintArrow

    ; Write it
    mov dx, 0FFEAh
    out dx, al
    jmp short $+2
    jmp short $+2

    ; Read back
    in  al, dx
    call DisplayHex
    call NewLine

    ; Restore original
    mov al, byte ptr [original]
    out dx, al

    ; Test Pattern 3: Try various specific patterns
    ; Let's try some valid page numbers from the table
    call NewLine
    mov dx, OFFSET test3_msg
    mov ah, 09h
    int 21h

    ; Try pattern 0x01 (page 7, ROM 0)
    push 01h
    call TestPattern

    ; Try pattern 0x09 (page 3, ROM 1)
    push 09h
    call TestPattern

    ; Try pattern 0x00 (page 8, ROM 0)
    push 00h
    call TestPattern

    ; Final: Read current value
    call NewLine
    mov dx, OFFSET final_msg
    mov ah, 09h
    int 21h

    mov dx, 0FFEAh
    in  al, dx
    call DisplayHex
    call NewLine

    ; Test: Read E000:0000
    mov dx, OFFSET e000_msg
    mov ah, 09h
    int 21h

    mov ax, 0E000h
    mov es, ax
    mov al, es:[0]
    call DisplayHex
    call NewLine

    ; Exit
    mov ax, 4C00h
    int 21h

;---------------------------------------------------------------------------
; TestPattern - Test a specific bit pattern
; Input: Stack contains pattern to test (8-bit)
;---------------------------------------------------------------------------
TestPattern PROC
    push bp
    mov bp, sp
    push ax
    push dx

    ; Get pattern from stack
    mov al, [bp+4]
    mov ah, al          ; Save for display

    ; Display pattern
    mov dx, OFFSET pattern_msg
    push ax
    mov ah, 09h
    int 21h
    pop ax

    mov al, ah
    call DisplayHex
    call PrintArrow

    ; Combine with original (preserve bits 5-7)
    mov al, byte ptr [original]
    and al, 0E0h
    or  al, ah          ; Mix in our pattern

    mov byte ptr [write_val], al
    call DisplayHex
    call PrintArrow

    ; Write it
    mov dx, 0FFEAh
    out dx, al
    jmp short $+2
    jmp short $+2

    ; Read back
    in  al, dx
    call DisplayHex
    call NewLine

    ; Restore original
    mov al, byte ptr [original]
    out dx, al

    pop dx
    pop ax
    pop bp
    ret 2               ; Clean up parameter
TestPattern ENDP

;---------------------------------------------------------------------------
PrintArrow PROC
    push ax
    push dx
    mov dx, OFFSET arrow
    mov ah, 09h
    int 21h
    pop dx
    pop ax
    ret
PrintArrow ENDP

;---------------------------------------------------------------------------
DisplayHex PROC
    push ax
    mov cl, 4
    shr al, cl
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
    push ax
    push dx
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    int 21h
    pop dx
    pop ax
    ret
NewLine ENDP

;---------------------------------------------------------------------------
; Data
;---------------------------------------------------------------------------
banner          db 13, 10
                db '========================================', 13, 10
                db 'Port FFEA Pattern Test - Diagnostic', 13, 10
                db '========================================', 13, 10
                db 13, 10, '$'

original_msg    db 'Original Port FFEA: 0x', '$'
test1_msg       db 'Test 1 (bits 0-3=1111): 0x', '$'
test2_msg       db 'Test 2 (bit 4 only):    0x', '$'
test3_msg       db 'Test 3 (valid patterns from table):', 13, 10, '$'
pattern_msg     db '  Pattern 0x', '$'
final_msg       db 'Final Port FFEA: 0x', '$'
e000_msg        db 'E000:0000: 0x', '$'
arrow           db ' -> 0x', '$'

original        db 0
before          db 0
write_val       db 0
after           db 0

END start
