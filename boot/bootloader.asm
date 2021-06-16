;  \- HenryOS Bootloader -/
; ==========================
; @ author:   Henry LE BERRE
; @ 
; @ Copyright (C) 2021 Henry LE BERRE

ORG     0x7C00
BITS    16 ; 16bit Real Mode

SECTION .henryOS_bootsector

bootsector:
    ; [x] Initial State:
    ; |--> DL     = Drive number on which the Bootsector (& kernel, ...) lies
    ; |--> 0x7C00 = Location of the Bootloader in Memory
    ; | \--> CS   = (0x7C0 or 0x0)  
    ; |-> Processor in Real Mode

    ; [x] -> Misc Setup

    cld ; Clear Direction Flag

    ; [x] -> Initialize Stack Segment Registers
    ; 1. When modifying SS, we need to disbale interrupts
    ;    because of this bug: https://books.google.fr/books?id=1L7PVOhfUIoC&lpg=PA492&ots=zjAKTcSu3k&pg=PA492&redir_esc=y#v=onepage&q&f=false
    ; 2. We put the stack under the Bootloader:
    ;    -> SS:SP=0x7C00 -> 0x0000:0x7C00
    ;    -> SS:BP=0x7C00 -> 0x0000:0x7C00
    ;    We chose 0x0000:0x7C00 instead of 0x07C0:0000 so that SP can be decremented.
    
    cli            ; Disable Interrupts
    xor ax, ax     ; 
    mov ss, ax     ; SS = 0x0000
    sti            ; Enable Interrupts

    mov bp, 0x7C00 ; BP = 0x7C00 (BP Not required)
    mov sp, bp     ; SP = 0x7C00

    ; [x] -> Initialize other Segment Registers

    mov ax, 0x7C0 ; 
    mov ds, ax    ; DS=0x7C0
    mov es, ax    ; ES=0x7C0

    ; [x] -> Load the Kernel to 0x10000 (Segment 0x1000)
    ; 1. The BIOS Interrupt 0x13, with AH=0x02, will read a Sector
    ;    to the buffer at ES:BX. We want 0x1000:0x0000 -> 0x10000

    read_sectors:
        mov ax, 0x1000 ;
        mov es, ax     ; ES=0x1000
        xor bx, bx     ; BX=0x0000
        mov cl, 2      ; CL=2 (sector after bootsector)
        xor ch, ch     ; CH=Cylinder
        xor dh, dh     ; DH=Head

        push 0x01        ; Save the # of sectors to read (We don't have enough registers)
        jmp  read_sector ; Skip Incrementing ES:BX because we are reading the first sector

        read_next_sector:
            add bx, 0x200 ; Advance the destination Buffer by 1 Sector (512 bytes)

            read_sector: ; ES:BX=Buffer. CL=Sector # (starting from 1)
                pop  si
                cmp  si, 0
                jz   read_sectors_finished
                dec  si
                push si

                mov si, 0x02 ; Try to load the Sector 0x02+1 times

                read_sector_try_loop:
                    mov ah, 0x02 ; AH=Read Sectors From Drive (INT 0x13)
                    mov al, 0x01 ; AL=Sectors to read
                                 ; DL=Drive Number (already assigned)

                    int 0x13     ; Call the BIOS Interrupt
                                 ; On return: - AH = Status Code             - JZ = (error) ? 1 : 0
                                 ;            - AL = Number of Sectors read

                    ; If we read the Sector, we can go ahead and read the next one
                    jnc read_next_sector

                    ; Otherwise, check if we have tries left to read the current Sector
                    dec si
                    cmp si, 0
                    jz  read_sector_failed ; If we don't, terminate.

                    ; If we have tries left, let's try resetting the Disk System
                    xor ah, ah ; AH=Reset Disk System
                    int 0x13   ; Call the BIOS Interrupt
                               ; On return: - AH = Status Code
                               ;            - JZ = (error) ? 1 : 0
                    
                    ; Now, try one more time to read the current Sector
                    jmp read_sector_try_loop

                read_sector_failed:
                    ; Terminate
                    cli
                    hlt

    read_sectors_finished:
        mov sp, bp ; Reset the Stack Pointer (It should be off by 1)

    ; [x] -> Enable Protected Mode

    

    ; [x] -> Jump to the loaded Kernel

    jmp 0x1000:0x0000

    ; [x] -> Terminate
    
    cli
    hlt

    ; [x] -> EOF & Signature
    
    TIMES 510 - ($-$$) DB 0 ; 0-out Until Signature 
    DW    0xAA55            ; Boot Sector Signature