;  \- HenryOS Bootloader -/
; ==========================
; @ Author:   Henry LE BERRE
; @ 
; @ Copyright (C) 2021 Henry LE BERRE

%define KERNEL_SECTOR_COUNT 1

ORG  0
BITS 16

                                      ; -----------------------------------------------
boot0:

    jmp 0x07C0:boot1                  ; --->| Normalize CS:IP (CS=0x07C0)
boot1:
    cld                               ; --->| 
    
    ; Stack: SS:IP=0x0000:0x7C00
    ; Stack is under the loaded Bootloader
    cli                               ; --->| Modifying SS, so disbale Interrupts
    xor ax, ax                        ; --->| 
    mov ss, ax                        ; --->| SS=0x0000
    sti                               ; --->| Enable Interrupts

    mov bp, 0x7C00                    ; --->| BP=0x7C00
    mov sp, 0x7C00                    ; --->| SP=0x7C00

    ; Segment Registers: ES=DS=0x07C0
    mov ax, 0x07C0                    ; --->|
    mov es, ax                        ; --->|
    mov ds, ax                        ; --->|

    ; Load Kernel Into Memory (ES:BX=0x1000:0x0000)
    mov ax, 0x1000                    ; --->|
    mov es, ax                        ; --->| ES=0x1000 |
    xor bx, bx                        ; --->| BX=0x0000 |
    mov cl, 2                         ; --->| CL=2      | Current Sector Number
    mov si, KERNEL_SECTOR_COUNT       ; --->|           | Numer of Sectors left to read
read_next_sector:                     ; --->|
    call 0x07C0:func_readSector       ; --->| Read current Sector
    dec si                            ; --->| Decrement remaining Sectors to read Counter
    jnz read_next_sector              ; --->| Handle Loop
    add bx, 0x200                     ; --->| Increment the destination buffer by 1 Sector
boot2:                                ; --->|
    jmp 0x1000:0x0000                 ; --->| Jump to Kernel
                                      ; -----------------------------------------------






func_readSector:                      ; Arguments: |- DL    | Drive  Number
                                      ;            |- ES:BX | Destination Buffer
                                      ;            |- CL    | Sector Number (1-indexed)
                                      ; -----------------------------------------------
    push si                           ; --->| Save Registers
    push ax                           ; --->| 
    push dx                           ; --->| 
    push cx                           ; --->| 
    mov si, 3h                        ; --->| SI=3 | Number of remaining attempts to read the sector
func_readSector_try:                  ; --->| 
    mov ax, ((02h << 8) | 01h)        ; --->| AH=2 | Read Sectors From Drive
                                      ; --->| AL=1 | Number of sectors to read    
    xor dh, dh                        ; --->| 
    xor ch, ch                        ; --->| CX=0 | Track/Cylinder ID
    int 13h                           ; --->| Call the BIOS Interrupt
                                      ; --->| On return: - AH = Status Code
                                      ; --->|            - CF = (error) ? 1 : 0
                                      ; --->|            - AL = Number of Sectors read
    jnc func_readSector_ret           ; --->| Return if read successfully (ORG 0x0000 but it's a near jump)
    dec si                            ; --->| Decrement remaining attempts to read the sector
    jz  func_readSector_hlt           ; --->| Halt: Failed to read the sector after (%si) tries (ORG 0x0000 but it's a near jump)
    xor ah, ah                        ; --->| AH=0 | Reset Disk System
    int 0x13                          ; --->| Call the BIOS Interrupt
                                      ; --->| On return: - AH = Status Code
                                      ; --->|            - CF = (error) ? 1 : 0
    jmp func_readSector_try           ; --->| Try Again
func_readSector_hlt:                  ; --->| 
    cli                               ; --->| 
    hlt                               ; --->| 
func_readSector_ret:                  ; --->| 
    pop cx                            ; --->| Restore Registers
    pop dx                            ; --->| 
    pop ax                            ; --->| 
    pop si                            ; --->| 
                                      ; --->| 
    ret                               ; --->| 






mbr_sig:
    times 0x200-2-($-$$) db 0 ; --->| Padd Sector with 0s
    dw    0xAA55              ; --->| MBR  Signature