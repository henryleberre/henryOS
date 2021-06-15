
void kernel_entry() {
	__asm__("mov ah, 0x09;"
				  "mov al, 0x42;"
				  "xor bh, bh;"
				  "mov bl, 0xF;"
				  "mov cx, 0x1;"
				  "int 0x10;"
				  "hlt;");
}
