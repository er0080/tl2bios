; NOROMBITS.SYS - DOS Device Driver to Disable ROM at E000 (bits 0-3 method)
; Tandy 1000 TL/2 ROM Disable Driver - Alternative Implementation
;
; Assemble with: TASM NOROMBITS.ASM
; Link with: TLINK /T NOROMBITS.OBJ
; Rename to: NOROMBITS.SYS
;
; Load in CONFIG.SYS:
;   DEVICE=C:\PATH\TO\NOROMBITS.SYS
;
; This driver sets Port FFEA bits 0-3 during boot to disable ROM at E000:0000,
; based on ROM paging table showing pattern 0x0F disables both ROM chips.

.MODEL TINY
.CODE
 ORG 0               ; Device drivers start at offset 0

;---------------------------------------------------------------------------
; Device Driver Header
;---------------------------------------------------------------------------
DeviceHeader:
    dd -1                   ; Link to next device driver (-1 = last)
    dw 8000h                ; Device attributes:
                            ; Bit 15 = 1 (character device)
                            ; Bit 14 = 0 (not IOCTL)
                            ; Bit 13 = 0 (not block device)
                            ; Bit 3  = 0 (not CLOCK$)
    dw Strategy             ; Offset to Strategy routine
    dw Interrupt            ; Offset to Interrupt routine
    db 'NOROMBTS'           ; Device name (8 characters)

;---------------------------------------------------------------------------
; Variables
;---------------------------------------------------------------------------
RequestHeader   dd ?        ; Pointer to request header from DOS

;---------------------------------------------------------------------------
; Strategy Routine
; DOS calls this first with ES:BX pointing to request header
;---------------------------------------------------------------------------
Strategy PROC FAR
    ; Save request header pointer
    mov word ptr cs:[RequestHeader], bx
    mov word ptr cs:[RequestHeader+2], es
    retf
Strategy ENDP

;---------------------------------------------------------------------------
; Interrupt Routine
; DOS calls this after Strategy to process the request
;---------------------------------------------------------------------------
Interrupt PROC FAR
    push ax
    push bx
    push cx
    push dx
    push ds
    push es
    push di
    push si

    ; Get request header pointer
    lds bx, cs:[RequestHeader]

    ; Get command code from request header (offset 2)
    mov al, [bx+2]

    ; Check if this is INIT command (0)
    cmp al, 0
    je Init
    jmp Done

Init:
    ; Read current Port FFEA value
    mov dx, 0FFEAh
    in  al, dx
    mov cl, al              ; Save original in CL

    ; Check what pattern is currently set in bits 0-3
    and al, 0Fh
    cmp al, 0Fh             ; Are bits 0-3 already set?
    je AlreadyDisabled

    ; NEW APPROACH: Set bits 0-3 to disable ROM
    ; According to ROM paging table, bits 4,3,2,1,0 = 0,1,1,1,1 (0x0F)
    ; disables both ROM chips (ROMCS #0 and #1 go high)
    mov al, cl
    and al, 0E0h            ; Clear bits 0-4, preserve bits 5-7
    or  al, 0Fh             ; Set bits 0-3 (pattern 0x0F in lower nibble)
    out dx, al

    ; Small delay to let hardware settle
    jmp short $+2
    jmp short $+2

    ; Verify bits 0-3 were set
    in al, dx
    and al, 0Fh
    cmp al, 0Fh
    jne Failed

    ; Success - ROM disabled
    mov si, OFFSET MsgSuccess
    call PrintMessage
    jmp SetReturnValues

AlreadyDisabled:
    ; ROM was already disabled
    mov si, OFFSET MsgAlready
    call PrintMessage
    jmp SetReturnValues

Failed:
    ; Failed to set bits 0-3
    mov si, OFFSET MsgFailed
    call PrintMessage
    ; Continue anyway with error status

SetReturnValues:
    ; Set end address of resident portion (offset 14)
    ; Since this is init-only, we discard everything after Init
    mov word ptr [bx+14], OFFSET EndResident
    mov word ptr [bx+16], cs

    ; Set status word (offset 3)
    ; Bit 15 = 0 (no error), Bit 8 = 1 (done)
    mov word ptr [bx+3], 0100h

Done:
    pop si
    pop di
    pop es
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    retf
Interrupt ENDP

;---------------------------------------------------------------------------
; PrintMessage - Display message to console during boot
; Input: CS:SI = pointer to '$'-terminated string
;---------------------------------------------------------------------------
PrintMessage PROC
    push ax
    push dx
    push ds

    push cs
    pop ds
    mov dx, si
    mov ah, 09h
    int 21h

    pop ds
    pop dx
    pop ax
    ret
PrintMessage ENDP

;---------------------------------------------------------------------------
; Messages
;---------------------------------------------------------------------------
MsgSuccess  db 13, 10
            db 'NOROMBITS: ROM disabled using bits 0-3 method (0x0F pattern)'
            db 13, 10, '$'

MsgAlready  db 13, 10
            db 'NOROMBITS: ROM already disabled (bits 0-3 set)'
            db 13, 10, '$'

MsgFailed   db 13, 10
            db 'NOROMBITS: WARNING - Failed to set bits 0-3 pattern'
            db 13, 10, '$'

;---------------------------------------------------------------------------
; End of Resident Portion
; Everything after this is discarded after initialization
;---------------------------------------------------------------------------
EndResident:

END
