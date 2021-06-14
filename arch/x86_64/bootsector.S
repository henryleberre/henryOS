;  \- HenryOS Bootloader -/
; ==========================
; @ author:   Henry LE BERRE
; @ 
; @ Copyright (C) 2021 Henry LE BERRE

; /===============\
; | Memory Layout |
; \===============/
;
; 
; 
; 
; 
; 
; 


ORG     0           ; Living Life Dangerously
BITS    16          ; 16bit Real Mode
GLOBAL  bootsector  ; Export Our 512 Byte Bootsector
SECTION .text       ; Mark it as code

bootsector:
    ; Initialize Segment Registers
    cli        ; Disable Interrupts
    
    mov ax, cs ; Fetch CS (either 0x7C0 or 0x0)
    mov ds, ax ; DS=CS
    mov es, ax ; ES=CS
    mov fs, ax ; FS=CS
    mov gs, ax ; GS=CS
    
    ; Setup the Stack Under The Bootlaoder
    ; -> SS:SP=0x7C00 -> 0x0000:0x7C00
    xor rax, rax    ; 
    mov ss,  rax    ; SS=0x0
    mov bp,  0x7C00 ; BP=0x7C00
    mov sp,  bp     ; SP=BP=0x7C00

    sti             ; Enable Interrupts

    

    ; Boot Sector Signature
    TIMES 510 - ($-$$) DB 0
    DW    0xAA55
