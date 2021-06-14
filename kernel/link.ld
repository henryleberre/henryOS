OUTPUT_FORMAT("pe-i386")

/* Used to specify the first instruction */
/* This section is created in entry.c    */
ENTRY(kernel_entry)

SECTIONS {
    . = 0x10000; /* Kernel load address */

	.text : {
        *(.text*);
    }

    .rdata : {
        *(.rdata*);
    }

    .bss : {
        *(.bss*);
    }
}
