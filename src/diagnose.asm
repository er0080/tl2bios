; DIAGNOSE.ASM - Diagnostic tool for ROM reading issues
; Assemble with: TASM DIAGNOSE.ASM
; Link with: TLINK /T DIAGNOSE.OBJ
; Creates DIAGNOSE.COM

.MODEL TINY
.CODE
ORG 100h        ; COM file starts at offset 100h

start:
    ; Display banner
    mov dx, OFFSET banner
    mov ah, 09h
    int 21h

    ; Test 1: Display known values to verify DisplayHex works
    mov dx, OFFSET test1_msg
    mov ah, 09h
    int 21h

    mov al, 0EBh            ; Should display "EB"
    call DisplayHex
    call PrintSpace

    mov al, 034h            ; Should display "34"
    call DisplayHex
    call NewLine

    ; Test 2: Read Port FFEA
    mov dx, OFFSET test2_msg
    mov ah, 09h
    int 21h

    mov dx, 0FFEAh
    in  al, dx
    mov bl, al              ; Save for later
    call DisplayHex
    call NewLine

    ; Test 3: Read first 4 bytes from E000:0000
    mov dx, OFFSET test3_msg
    mov ah, 09h
    int 21h

    push ds
    mov ax, 0E000h
    mov ds, ax

    xor si, si              ; SI = 0
    mov al, [si]            ; Read E000:0000
    pop ds
    push ax                 ; Save first byte
    call DisplayHex
    call PrintSpace

    push ds
    mov ax, 0E000h
    mov ds, ax
    mov al, [1]             ; Read E000:0001
    pop ds
    push ax                 ; Save second byte
    call DisplayHex
    call PrintSpace

    push ds
    mov ax, 0E000h
    mov ds, ax
    mov al, [2]             ; Read E000:0002
    pop ds
    push ax                 ; Save third byte
    call DisplayHex
    call PrintSpace

    push ds
    mov ax, 0E000h
    mov ds, ax
    mov al, [3]             ; Read E000:0003
    pop ds
    call DisplayHex
    call NewLine

    ; Pop and verify saved values
    mov dx, OFFSET verify_msg
    mov ah, 09h
    int 21h

    pop ax                  ; Get 4th byte back
    call DisplayHex
    call PrintSpace
    pop ax                  ; Get 3rd byte back
    call DisplayHex
    call PrintSpace
    pop ax                  ; Get 2nd byte back
    call DisplayHex
    call PrintSpace
    pop ax                  ; Get 1st byte back
    call DisplayHex
    call NewLine

    ; Test 4: Try reading E000:0000 using different method
    mov dx, OFFSET test4_msg
    mov ah, 09h
    int 21h

    mov ax, 0E000h
    mov es, ax              ; Use ES instead of DS
    mov al, es:[0]
    call DisplayHex
    call PrintSpace
    mov al, es:[1]
    call DisplayHex
    call NewLine

    ; Test 5: Set Port FFEA bit 4 and re-read E000:0000
    mov dx, OFFSET test5_msg
    mov ah, 09h
    int 21h

    mov dx, 0FFEAh
    mov al, bl              ; Original Port FFEA value
    or  al, 10h             ; Set bit 4
    out dx, al

    ; Read back Port FFEA
    in  al, dx
    call DisplayHex
    call PrintSpace

    ; Read E000:0000 after disable
    mov ax, 0E000h
    mov es, ax
    mov al, es:[0]
    call DisplayHex
    call NewLine

    ; Restore Port FFEA
    mov dx, 0FFEAh
    mov al, bl
    out dx, al

    ; Done
    mov dx, OFFSET done_msg
    mov ah, 09h
    int 21h

    ; Exit to DOS
    mov ax, 4C00h
    int 21h

;---------------------------------------------------------------------------
; DisplayHex - Display AL register in hexadecimal
;---------------------------------------------------------------------------
DisplayHex PROC
    push ax
    push bx

    mov bh, al              ; Save original in BH

    ; Display high nibble
    mov al, bh
    mov cl, 4
    shr al, cl
    and al, 0Fh
    add al, '0'
    cmp al, '9'
    jbe @high_ok
    add al, 7
@high_ok:
    mov dl, al
    mov ah, 02h
    int 21h

    ; Display low nibble
    mov al, bh
    and al, 0Fh
    add al, '0'
    cmp al, '9'
    jbe @low_ok
    add al, 7
@low_ok:
    mov dl, al
    mov ah, 02h
    int 21h

    pop bx
    pop ax
    ret
DisplayHex ENDP

;---------------------------------------------------------------------------
; PrintSpace - Print a space character
;---------------------------------------------------------------------------
PrintSpace PROC
    push ax
    push dx
    mov dl, ' '
    mov ah, 02h
    int 21h
    pop dx
    pop ax
    ret
PrintSpace ENDP

;---------------------------------------------------------------------------
; NewLine - Print carriage return and line feed
;---------------------------------------------------------------------------
NewLine PROC
    push ax
    push dx
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    pop dx
    pop ax
    ret
NewLine ENDP

;---------------------------------------------------------------------------
; Data Section
;---------------------------------------------------------------------------
banner          db 13, 10
                db '========================================', 13, 10
                db 'ROM Diagnostic Tool', 13, 10
                db '========================================', 13, 10
                db 13, 10, '$'

test1_msg       db 'Test 1 - Display EB 34:     ', '$'
test2_msg       db 'Test 2 - Port FFEA:         ', '$'
test3_msg       db 'Test 3 - E000:0000-0003:    ', '$'
verify_msg      db 'Verify - Reverse order:     ', '$'
test4_msg       db 'Test 4 - Using ES segment:  ', '$'
test5_msg       db 'Test 5 - After bit 4 set:   ', '$'
done_msg        db 13, 10, 'Diagnostic complete.', 13, 10, '$'

END start
