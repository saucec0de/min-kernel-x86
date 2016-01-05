ENTRY(start)    /* entry point after loading the kernel */

SECTIONS {
    . = 1M;     /* the load address of 1st section */

    .boot :
    {
        *(.multiboot_header)    /* must at the beginning */
    }

    .text :
    {
        *(.text)
    }
}

