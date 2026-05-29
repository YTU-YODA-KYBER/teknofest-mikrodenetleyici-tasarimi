/* =====================================================================
 *  CV32E40P Linker Script - UART Test
 *  --------------------------------------------------
 *  IMEM (boot ROM) : 0x00000000, 4KB  -> .text + .rodata
 *  DMEM (data RAM)  : 0x20000000, 4KB  -> .bss + stack
 *
 *  .rodata IMEM'de KALIR (kopyalanmaz). CPU string/sabitlere
 *  data port + dual-port boot ROM uzerinden eriser.
 *  Stack pointer boot.S'de hard-code (li sp, 0x20001000),
 *  bu yuzden _stack_top sembolune gerek yok.
 * ===================================================================== */

OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    DMEM (rw) : ORIGIN = 0x20000000, LENGTH = 4K
}

SECTIONS
{
    /* Kod + read-only data -> IMEM (boot ROM) */
    .text : ALIGN(4) {
        KEEP(*(.vectors))
        KEEP(*(.vectors.*))
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
        *(.srodata)
        *(.srodata.*)
        . = ALIGN(4);
        _etext = .;
    } > IMEM

    /* BSS -> DMEM (boot.S sifirlar) */
    .bss : ALIGN(4) {
        _sbss = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > DMEM

    /* Kullanilmayan bolumler */
    /DISCARD/ : {
        *(.comment)
        *(.note)
        *(.note.*)
        *(.eh_frame)
        *(.eh_frame.*)
        *(.riscv.attributes)
    }
}
