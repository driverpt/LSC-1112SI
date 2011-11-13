OUTPUT_FORMAT("binary")
SECTIONS
{
  .bootrec 0x7C00 : {
    *(.text)
    *(.rodata)
    *(.data)
    . = 510;
    SHORT(0xAA55)
  }
}
