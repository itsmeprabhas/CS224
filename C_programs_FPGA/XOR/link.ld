OUTPUT_ARCH(riscv)
ENTRY(main)
MEMORY {
    imem (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    dmem (rwx) : ORIGIN = 0x00001000, LENGTH = 4K
}
SECTIONS {
    .text : { *(.text*) } > imem
    .data : { *(.data*) *(.sdata*) *(.rodata*) } > dmem
    .bss : { *(.bss*) *(.sbss*) } > dmem
}
