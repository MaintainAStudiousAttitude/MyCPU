OUTPUT_ARCH( "riscv" )
ENTRY( _start )

SECTIONS
{
  /* CPU 复位后的启动地址 */
  . = 0x80000000;

  .text : {
    *(.text.init)  /* 确保启动汇编放在最前面 */
    *(.text)
    *(.text.*)
  }

  .rodata : {
    *(.rodata)
    *(.rodata.*)
  }

  .data : {
    *(.data)
    *(.data.*)
  }

  .bss : {
    *(.bss)
    *(.bss.*)
  }
}
