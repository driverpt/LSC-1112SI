
      .text
      .code64
      .global start64
start64: 
      # Clear BSS
      movl   $__bss_start, %edi
      movl   $__bss_quads, %ecx
      xorq   %rax, %rax
      cld
      rep    stosq

      movl   $0x10000, %esp
      call   vesa_modes_main
#      call   lsc_main
      
1:    hlt
      jmp 1b

      .global bootdrv
bootdrv:
      .byte 0

      .end
