/* =====================================================================
 *  Minimal Boot Kodu - CV32E40P
 *  --------------------------------------------------
 *  - Stack pointer'i hard-code et (linker sembolune bagimli degil)
 *  - BSS'i sifirla (global/static degiskenler icin)
 *  - .rodata KOPYALANMAZ: IMEM'de kalir, CPU data port'tan
 *    dual-port boot ROM uzerinden okur (interconnect m7)
 *  - .data yok (bu testte initialized global yok)
 *  - main()'e atla
 * ===================================================================== */

.section .vectors, "ax"
.global _start

_start:
    /* Stack pointer = DMEM sonu (0x20000000 + 4K = 0x20001000) */
    li    sp, 0x20001000

    /* --- BSS sifirla --- */
    la    t0, _sbss
    la    t1, _ebss
_bss_loop:
    bge   t0, t1, _bss_done
    sw    zero, 0(t0)
    addi  t0, t0, 4
    j     _bss_loop
_bss_done:

    /* main()'e gec */
    call  main

_hang:
    j     _hang
