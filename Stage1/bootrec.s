
      .equ STACK_TOP, 0x7C00
      .equ PROG_SEGM, 0x1000

      .text                   # code section starts here
      .code16                 # this is real mode (16 bit) code

      ljmp   $0, $1f
1:    xorw   %bx, %bx
      movw   %bx, %ds
      cli
      movw   %bx, %ss
      movw   $STACK_TOP, %sp
      sti

      push   %dx

      # Read 8KiB from floppy
      movb   $2,  %ah         # Service:      Read (CHS)
      xorb   %ch, %ch         # From:         C(7..0)=0
      movb   $2,  %cl         # From:         C(9..8)=0 | S(5..0)=2
      xorb   %dh, %dh         # From:         H(7..0)=0
      # dl == boot disk       # From:         disk
      movb   $0x10, %al       # Length:       16 sectors
      movw   $PROG_SEGM, %si
      movw   %si, %es         # To (segment): 0x1000
      # bx == 0x0000          # To (offset) : 0x0000
      stc
      int    $0x13
      jc     2f               # Carry set on error
      testb  %ah, %ah
      jnz    2f               # AH == 0 on success

      # Stop the floppy motor
      movb   STACK_TOP-2, %al
      orb    $4, %al
      movw   $0x3f2, %dx
      outb   %al, %dx

      # Let dl carry boot drive id
      movb   STACK_TOP-2, %dl
      ljmp   $PROG_SEGM, $0

2:    hlt
      jmp    2b

      .end
