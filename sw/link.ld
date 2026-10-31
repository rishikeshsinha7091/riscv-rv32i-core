ENTRY(_start)

MEMORY
{
IMEM : ORIGIN = 0x00000000, LENGTH = 4K
DMEM : ORIGIN = 0x00001000, LENGTH = 4K
}

SECTIONS
{
.text : {
*(.text.init)
*(.text .text.*)
. = ALIGN(4);
} > IMEM

.data : {
*(.rodata .rodata.* .srodata .srodata.*)
. = ALIGN(4);
*(.data .data.* .sdata .sdata.*)
. = ALIGN(4);
} > DMEM

.bss (NOLOAD) : {
. = ALIGN(4);
_bss_start = .;
*(.bss .bss.* .sbss .sbss.* COMMON)
. = ALIGN(4);
_bss_end = .;
} > DMEM

_stack_top = ORIGIN(DMEM) + LENGTH(DMEM);

/DISCARD/ : { *(.eh_frame*) }
}
