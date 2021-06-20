;   _________________________________________________________________
;  /|\/‾‾\/‾\_____/‾\/‾‾\|@ An operating system by Henry LE BERRE  /|\ 
; /|||\__/|‾‾‾‾‾‾‾‾‾|\__/|@                                       /|||\
;<|||||><|| HenryOS ||><||@                                      <|||||>
; \|||/‾‾\|_________|/‾‾\|@                                       \|||/
;  \|/\__/\_/‾‾‾‾‾\_/\__/|@ Copyright (C) 2021 Henry LE BERRE      \|/ 
;   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

%define TOTAL_SECTOR_COUNT 2          ; 

[org   0]
[bits 16]

;=====================================================================================
boot16_0:
    jmp 0x07C0:boot16_1               ; --->| Normalize CS:IP (CS=0x07C0)
boot16_1:
    cld                               ; --->| 
    
    ; [X]: Stack: SS:IP=0x0000:0x7C00
    ;      Stack is under the loaded Bootloader
    cli                               ; --->| Modifying SS, so disbale Interrupts
    xor ax, ax                        ; --->| 
    mov ss, ax                        ; --->| SS=0x0000
    sti                               ; --->| Enable Interrupts

    mov bp, 0x7C00                    ; --->| BP=0x7C00
    mov sp, 0x7C00                    ; --->| SP=0x7C00

    ; [X]: Segment Registers: ES=DS=0x07C0
    mov ax, 0x07C0                    ; --->|
    mov es, ax                        ; --->|
    mov ds, ax                        ; --->|

    ; [X]: Load Kernel Into Memory (ES:BX=0x1000:0x0000)
    mov ax, 0x1000                    ; --->|
    mov es, ax                        ; --->| ES=0x1000 |
    xor bx, bx                        ; --->| BX=0x0000 |
    mov cl, 2                         ; --->| CL=2      | Current Sector Number
    mov si, (TOTAL_SECTOR_COUNT-1)    ; --->|           | Numer of Sectors left to read
read_next_sector:                     ; --->|
    call 0x07C0:func_readSector       ; --->| Read current Sector
    dec si                            ; --->| Decrement remaining Sectors to read Counter
    jnz read_next_sector              ; --->| Handle Loop
    add bx, 0x200                     ; --->| Increment the destination buffer by 1 Sector
boot16_2:
    mov ah, 0x00
    mov al, 0x13
    int 0x10

boot16_3:                             ; --->|
    cli

    lidt [DS:idt_descriptor]
    lgdt [DS:gdt_descriptor]

    mov eax, cr0 
    or al, 1       ; set PE (Protection Enable) bit in CR0 (Control Register 0)
    mov cr0, eax
    
    mov ax, x86_32_DS
    mov ds, ax
    mov es, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x40000

    jmp x86_32_CS:(0x7C00+boot32_4)

[bits 32]
boot32_4:
    sti

    ; Should be executing the kernel...
    mov eax, 0x10000
    call eax


;    mov esi, 320*200
;a:
;    mov BYTE[0xA0000+esi], 0xCC
;    dec esi
;    jnz a


    cli
    hlt

;=====================================================================================

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

;=====================================================================================

gdt_start:
gdt_null:
    dq 0
gdt_code_segment:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 0b10011010
    db 0b11001111
    db 0x00
gdt_data_segment:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 0b10010010
    db 0b11001111
    db 0x00
gdt_end:

gdt_descriptor:
    dw (gdt_end - gdt_start - 1)
    dd (0x7C00+gdt_start)

x86_32_CS equ (gdt_code_segment - gdt_start)
x86_32_DS equ (gdt_data_segment - gdt_start)

dummy_isr:
    pushad
    cld
    popad
    iret

idt_start:
irq0:
      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

      dw (0x7C00+dummy_isr)
      dw 0x0008
      db 0x00
      db 0b10101110
      dw 0x0000

idt_end:

idt_descriptor:
    dw (idt_end - idt_start - 1)
    dd (0x7C00+idt_start)

mbr_sig:
    times 0x200-2-($-$$) db 0 ; --->| Padd Sector with 0s
    dw    0xAA55              ; --->| MBR  Signature

;   _________________________________________________________________
;  /|\/‾‾\/‾\_____/‾\/‾‾\|@ An operating system by Henry LE BERRE  /|\ 
; /|||\__/|‾‾‾‾‾‾‾‾‾|\__/|@                                       /|||\
;<|||||><|| HenryOS ||><||@                                      <|||||>
; \|||/‾‾\|_________|/‾‾\|@                                       \|||/
;  \|/\__/\_/‾‾‾‾‾\_/\__/|@ Copyright (C) 2021 Henry LE BERRE      \|/ 
;   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾