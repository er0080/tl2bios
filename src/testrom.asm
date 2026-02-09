; TESTROM.ASM - Comprehensive Port FFEA ROM Disable Test
; From PORT_FFEA_TEST.md
;
; Assemble with: TASM TESTROM.ASM
; Link with: TLINK /T TESTROM.OBJ
; Creates TESTROM.COM
;
; This program:
; 1. Reads and displays initial Port FFEA value
; 2. Reads and displays ROM content at E000:0000 before disable
; 3. Sets Port FFEA bit 4 to disable ROM
; 4. Reads and displays Port FFEA after disable
; 5. Reads and displays E000:0000 after disable
; 6. Restores original Port FFEA value

.MODEL TINY
.CODE
ORG 100h        ; COM file starts at offset 100h

start:
    ; Display banner
    mov dx, OFFSET banner
    mov ah, 09h
    int 21h

    ; Read and display initial Port FFEA value
    mov dx, 0FFEAh
    in  al, dx
    mov bl, al              ; Save original value in BL

    mov dx, OFFSET ffea_before_msg
    mov ah, 09h
    int 21h
    mov al, bl
    call DisplayHex
    call NewLine

    ; Display ROM content at E000:0000 before disable
    mov dx, OFFSET e000_before_msg
    mov ah, 09h
    int 21h

    push ds
    mov ax, 0E000h
    mov ds, ax
    mov al, [0]             ; Read first byte at E000:0000
    pop ds
    call DisplayHex
    call NewLine

    ; Disable ROM by setting bit 4 of Port FFEA
    mov dx, 0FFEAh
    mov al, bl
    or  al, 10h             ; Set bit 4 (ROM disable)
    out dx, al

    ; Read back Port FFEA to verify write
    in  al, dx

    mov dx, OFFSET ffea_after_msg
    mov ah, 09h
    int 21h
    call DisplayHex
    call NewLine

    ; Display E000:0000 content after disable
    mov dx, OFFSET e000_after_msg
    mov ah, 09h
    int 21h

    push ds
    mov ax, 0E000h
    mov ds, ax
    mov al, [0]             ; Read first byte at E000:0000 again
    pop ds
    call DisplayHex
    call NewLine

    ; Display interpretation message
    mov dx, OFFSET interpret_msg
    mov ah, 09h
    int 21h

    ; Restore original Port FFEA value
    mov dx, 0FFEAh
    mov al, bl
    out dx, al

    mov dx, OFFSET restored_msg
    mov ah, 09h
    int 21h

    ; Exit to DOS
    mov ax, 4C00h
    int 21h

;---------------------------------------------------------------------------
; DisplayHex - Display AL register in hexadecimal
; Input: AL = byte to display
; Output: None (displays to screen)
; Modifies: AH, DX (preserves AL via stack)
;---------------------------------------------------------------------------
DisplayHex PROC
    push ax

    ; Display high nibble
    mov cl, 4
    shr al, cl
    call DisplayNibble

    ; Display low nibble
    pop ax
    and al, 0Fh
    call DisplayNibble

    ret
DisplayHex ENDP

;---------------------------------------------------------------------------
; DisplayNibble - Display a single hex digit (0-F)
; Input: AL = nibble value (0-15)
; Output: None (displays to screen)
; Modifies: AH, DX
;---------------------------------------------------------------------------
DisplayNibble PROC
    add al, '0'
    cmp al, '9'
    jbe @nibble_ok
    add al, 7           ; Convert A-F
@nibble_ok:
    mov dl, al
    mov ah, 02h
    int 21h
    ret
DisplayNibble ENDP

;---------------------------------------------------------------------------
; NewLine - Print carriage return and line feed
; Modifies: AH, DX
;---------------------------------------------------------------------------
NewLine PROC
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    ret
NewLine ENDP

;---------------------------------------------------------------------------
; Data Section
;---------------------------------------------------------------------------
banner          db 13, 10
                db '========================================', 13, 10
                db 'Tandy 1000 TL/2 Port FFEA ROM Test', 13, 10
                db '========================================', 13, 10
                db 13, 10, '$'

ffea_before_msg db 'Port FFEA before: 0x', '$'
e000_before_msg db 'E000:0000 before: 0x', '$'
ffea_after_msg  db 'Port FFEA after:  0x', '$'
e000_after_msg  db 'E000:0000 after:  0x', '$'

interpret_msg   db 13, 10
                db 'Interpretation:', 13, 10
                db '  If E000:0000 changed from EB to FF (or other),', 13, 10
                db '  then ROM disable via Port FFEA bit 4 WORKS!', 13, 10
                db '  If E000:0000 still shows EB (ROM boot signature),', 13, 10
                db '  then Port FFEA bit 4 does NOT disable ROM.', 13, 10
                db 13, 10, '$'

restored_msg    db 'Port FFEA restored to original value.', 13, 10
                db 'Test complete.', 13, 10, '$'

END start
