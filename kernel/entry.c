
void kernel_entry() {
	__asm__("mov ah, 0x0E;"
				  "mov al, 0x41;"
					"xor bh, bh;"
				  "mov bl, 0x07;"
				  "int 0x10;");
}
