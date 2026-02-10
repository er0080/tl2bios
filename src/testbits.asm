; TESTBITS.ASM - Test ROM disable using bits 0-3 set (0x0F pattern)
; Based on TL2_ROM_paging.pdf table showing bits 0-3=1111 disables both ROM chips
;
; Assemble with: TASM TESTBITS.ASM
; Link with: TLINK /T TESTBITS.OBJ
; Creates TESTBITS.COM
;
; This program tests the theory that setting bits 0-3 to 1 (0x0F pattern)
; disables both ROM chips by pulling both ROMCS pins high.

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

    mov ax, 0E000h
    mov es, ax
    mov al, es:[0]          ; Read first byte at E000:0000
    call DisplayHex
    call NewLine

    ; NEW APPROACH: Set bits 0-3 to disable ROM
    ; According to ROM paging table, bits 0-3 = 1111 (0x0F) disables both ROM chips
    mov dx, 0FFEAh
    mov al, bl
    and al, 0E0h            ; Clear bits 0-4, preserve bits 5-7 (memory config)
    or  al, 0Fh             ; Set bits 0-3 to 1 (creates 0x0F pattern)
    out dx, al

    ; Small delay for hardware to settle
    jmp short $+2
    jmp short $+2

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

    mov ax, 0E000h
    mov es, ax
    mov al, es:[0]          ; Read first byte at E000:0000 again
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
                db 'Testing bits 0-3 method (0x0F pattern)', 13, 10
                db '========================================', 13, 10
                db 13, 10, '$'

ffea_before_msg db 'Port FFEA before: 0x', '$'
e000_before_msg db 'E000:0000 before: 0x', '$'
ffea_after_msg  db 'Port FFEA after:  0x', '$'
e000_after_msg  db 'E000:0000 after:  0x', '$'

interpret_msg   db 13, 10
                db 'Interpretation:', 13, 10
                db '  Testing theory: bits 0-3 = 1111 (0x0F)', 13, 10
                db '  should disable BOTH ROM chips (ROMCS #0 and #1 high)', 13, 10
                db '  If E000:0000 changed from EB to FF (or other),', 13, 10
                db '  then this method WORKS!', 13, 10
                db '  If E000:0000 still shows EB (ROM boot signature),', 13, 10
                db '  then we need to try other patterns.', 13, 10
                db 13, 10, '$'

restored_msg    db 'Port FFEA restored to original value.', 13, 10
                db 'Test complete.', 13, 10, '$'

END start
