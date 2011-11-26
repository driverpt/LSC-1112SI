
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

##########################
### TODO: Timer Clock ####
##########################

# Calcular o valor que com a frequência ( ver enunciado ) dá 10ms, que é valor
# ideal de acerto.

# Fazer Polling ao contador, quando o valor do contador for superior ao último valor medido
# significa que passaram 10 ms.
configure_timer:
      movb   $0x34 , %al
      out    %al   , $TIMER_CTRL
      
      out    $0    , $COUNTER_O
      out    $0    , $COUNTER_O
      
      
      movb   

######################
######################      
      
      call   vesa_modes_main
#      call   lsc_main
      
1:    hlt
      jmp 1b

      .global bootdrv
bootdrv:
      .byte 0

      .end
