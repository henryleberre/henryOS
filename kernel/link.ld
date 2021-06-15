OUTPUT_FORMAT("binary")

/* Used to specify the first instruction */
/* This section is created in entry.c    */
ENTRY(kernel_entry)

SECTIONS {
    . = 0x10000; /* Kernel load address */

    .text : {
        *(.text*);
    }

    .rdata : {
    	. = ALIGN(512);
	*(.rdata*);
    }

    .bss : {
        *(.bss*);
    }
}
