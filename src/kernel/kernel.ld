OUTPUT_FORMAT("binary")

/* Used to specify the first instruction         */
/* This section is created in src/kernel/entry.c */
ENTRY(kernel_entry)

SECTIONS {
    . = 0x10000; /* Kernel load address            */
                 /* Mainly used for absolute jumps */

    .text : ALIGN(512) {
        *(.text*);
    }

    .rdata : ALIGN(512) {
	    *(.rdata*);
    }

    .bss : ALIGN(512) {
        *(.bss*);
    }
}
