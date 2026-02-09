; PORTREAD.ASM - Simple Port FFEA Reader/Writer
; Based on DEBUG script from PORT_FFEA_TEST.md
;
; Assemble with: TASM PORTREAD.ASM
; Link with: TLINK /T PORTREAD.OBJ
; Creates PORTREAD.COM
;
; This program reads Port FFEA, displays it, sets bit 4 to disable ROM,
; writes it back, and displays the new value.

.MODEL TINY
.CODE
ORG 100h        ; COM file starts at offset 100h

start:
    ; Read current Port FFEA value
    mov dx, 0FFEAh
    in  al, dx

    ; Save original value
    push ax

    ; Display original value
    call DisplayHex
    call PrintSpace

    ; Restore value
    pop ax

    ; Set bit 4 (disable ROM at E000)
    or  al, 10h

    ; Write back to Port FFEA
    out dx, al

    ; Read Port FFEA again to verify
    in  al, dx

    ; Display new value
    call DisplayHex
    call NewLine

    ; Exit to DOS
    mov ax, 4C00h
    int 21h

;---------------------------------------------------------------------------
; DisplayHex - Display AL register in hexadecimal
; Input: AL = byte to display
; Output: None (displays to screen)
; Modifies: AX, DX
;---------------------------------------------------------------------------
DisplayHex PROC
    push ax

    ; Display high nibble
    mov dl, al
    mov cl, 4
    shr dl, cl
    add dl, '0'
    cmp dl, '9'
    jbe @high_ok
    add dl, 7           ; Convert A-F
@high_ok:
    mov ah, 02h
    int 21h

    ; Display low nibble
    pop ax
    push ax
    and al, 0Fh
    mov dl, al
    add dl, '0'
    cmp dl, '9'
    jbe @low_ok
    add dl, 7           ; Convert A-F
@low_ok:
    mov ah, 02h
    int 21h

    pop ax
    ret
DisplayHex ENDP

;---------------------------------------------------------------------------
; PrintSpace - Print a space character
;---------------------------------------------------------------------------
PrintSpace PROC
    mov dl, ' '
    mov ah, 02h
    int 21h
    ret
PrintSpace ENDP

;---------------------------------------------------------------------------
; NewLine - Print carriage return and line feed
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

END start
