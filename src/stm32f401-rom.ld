ENTRY(reset_handler)

MEMORY{
    FLASH(rx): ORIGIN = 0x08000000, LENGTH = 256K
    SRAM(rwx): ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS{
   /* combinar todas as secoes .isr_vectors de todos arquivos de entrada */
   /* combinar todas as secoes .text de todos arquivos de entrada */
   /* combinar todas as secoes .rodata de todos arquivos de entrada */
    .text :
    {
       KEEP(*(.isr_vectors))
       *(.text)
       *(.rodata)
       . = ALIGN(4);
       _etext = .;
       _la_data = _etext;
    }> FLASH
    /* Esta secao deve incluir a secao .data de todos arquivos objeto de entrada */
    .data :
    {
        _sdata = .;
        *(.data)
        . = ALIGN(4);
        _edata = .;
    }> SRAM AT> FLASH
    /* Esta secao deve incluir a secao .bss de todos arquivos objeto de entrada */
    .bss :{
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        . = ALIGN(4);
        _ebss = .;
    }> SRAM
}