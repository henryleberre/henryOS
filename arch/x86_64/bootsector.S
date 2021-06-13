ORG     0
BITS    16
GLOBAL  bootsector
SECTION .text

bootsector:
    ; Get Current Device Parameters
    MOV AH, 0x08 ; 
                 ; DL is already equal to the drive number
    INT 0x13     ; Call BIOS Interrupt 0x13:set ft=nasm


    ; Load Kernel To 0x1000:0
    MOV DH, 1
    XOR DI, DI
    MOV BX, 0x1000
    MOV ES, BX
    XOR BX, BX

    ; Enter Protected Mode: x86-32
    CLI

;	LGDT []
;	MOV  AX, CR0
;	OR   AL, 1
;	MOV  CR0, AX
	
    STI 

    ; Jump To x86-32 Kernel Code
    JMP 0x1000:0

    HLT

; GDT: Global Descriptor Table
	

; Boot Sector Signature
TIMES 510 - ($-$$) DB 0
DW    0xAA55
