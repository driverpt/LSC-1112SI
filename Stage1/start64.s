
      .equ   COUNTER_0  , 0x40
      .equ   TIMER_CTRL , 0x43
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

# Calcular o valor que com a frequência ( ver enunciado ) dá 10ms, que é valor
# ideal de acerto.

# Fazer Polling ao contador, quando o valor do contador for superior ao último valor medido
# significa que passaram 10 ms.
# Valor colocado no contador é 11932, ou seja (1/Frequencia)/10ms
configure_timer:
      movb   $0x34 , %al
      out    %al   , $TIMER_CTRL
      
      movb   $0x9C , %al
      out    %al   , $COUNTER_0
      movb   $0x2E , %al
      out    %al   , $COUNTER_0
      
######################
######################      
      
#      call   vesa_modes_main
      call   lsc_main
      
1:    hlt
      jmp 1b

      .global bootdrv
bootdrv:
      .byte 0

      .end
