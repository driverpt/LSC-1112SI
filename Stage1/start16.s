
      # Adapted from:
      # http://wiki.osdev.org/Entering_Long_Mode_Directly

      .equ   START16_SEG, 0x1000
      .equ   COUNTER_0  , 0x40
      .equ   TIMER_CTRL , 0x43
      .text
      .code16
start16:
      movw   $START16_SEG, %ax
      movw   %ax, %ds

      # Save boot drive id
      
      movl   $bootdrv, %eax   # eax <- Linear address with 20 bits
      movw   %ax, %di
      andw   $0xf, %di        # di <- lowest 4 bits of eax
      shrl   $4, %eax
      movw   %ax, %es         # es <- remaining 16 bits from eax
      movb   %dl, %es:(%di)   # save dl at es:di

      # Enable A20

      inb    $0x92, %al
      orb    $0x02, %al
      andb   $0xfe, %al
      outb   %al, $0x92

######################
### ADD VESA INFO ####
######################
      
      movw  $vesa_info          , %di
      movw  %ds                 , %bx    # Lets put DS into ES, since VESA uses ES:DI
      movw  %bx                 , %es    # We need to use an intermediary register
      movw  $0x4F00             , %ax    # Put the Interruption Code in AX register
      int   $0x10                        # Provoke an Interruption in BIOS

      movw  (video_mode_ptr)    , %si    # its Far_PRT, we need to extract Offset and Segment
      movw  (video_mode_ptr + 2), %fs
      
      
iterate_video_modes_start:
      movw  %ds                 , %bx
      movw  %bx                 , %es    # Since it works with ES:DI, lets put the vesa_mode_info structure      
      movw  $vbe_modes          , %di    # down below as the buffer pointer
      xorw  %dx                 , %dx
      
iterate_video_modes:
      movw  %fs:(%si)           , %cx   # Set the FS and DI to the video mode PTR inside vesa_mode_info
      cmpw  $0xFFFF             , %cx   # Lets see if the mode is FF FF which means end of modes array
      je    end_of_iterate_video_modes   
      

      movw  $0x4F01             , %ax    # Lets set the Bios Op Code as get vesa info
      int   $0x10
      
      ##
      ##  TODO : Comparison with Modes 8bpp and Resolutions 1024, 800, 640
      ##     
      
check_video_mode:
      
      cmpb  $8   , 25(%di)
      je    valid_video_mode
      cmpw  $16  , 25(%di)
      je    valid_color_mode
      jmp   next_video_mode
      
valid_color_mode:
      
      cmpw  $640 , 18(%di)
      je    valid_hres_mode
      cmpw  $800 , 18(%di)
      je    valid_hres_mode
      cmpw  $1024, 18(%di)
      je    valid_hres_mode
      jmp   next_video_mode
        
valid_hres_mode:

      cmpw  $480, 20(%di)
      je    valid_video_mode
      cmpw  $600, 20(%di)
      je    valid_video_mode
      cmpw  $768, 20(%di)
      je    valid_video_mode
      jmp   next_video_mode
      
      ##  
      ##  TODO : Move the structure to one of the spaces
      ##    

valid_video_mode:

#mem_cpy_start:
      #movw  $256, %cx
      #pushw %ds
      #pushw %si
      
      #pushw %es
      #pushw %di      
#mem_cpy:

      #movw  $vesa_mode_info   , %bx
      #movw  %bx               , %es
      #xorw  %di               , %di
      
      #movw  $256*%dx+vbe_modes, %bx 
      #movw  %bx               , %ds
      #xorw  %si               , %si
      
      #cld

      #rep   movsb
      
      #popw  %di
      #popw  %es
      #popw  %si
      #popw  %ds
      
      incw  %dx
      addw  $256, %di
      
next_video_mode:

      addw  $2  , %si
      cmpw  $6 , %dx
      je    end_of_iterate_video_modes
      jmp   iterate_video_modes
      
end_of_iterate_video_modes:

      # Build page tables

      xorw   %bx, %bx
      movw   %bx, %es
      cld
      movw   $0xa000, %di

      movw   $0xb00f, %ax
      stosw

      xorw   %ax, %ax
      movw   $0x07ff, %cx
      rep    stosw

      movw   $0xc00f, %ax
      stosw

      xorw   %ax, %ax
      movw   $0x07ff, %cx
      rep    stosw

      movw   $0x018f, %ax
      stosw

      xorw   %ax, %ax
      movw   $0x07ff, %cx
      rep    stosw

      # Enter long mode

      cli                       # No IDT. Keep interrupts disabled.

      movl   $0xA0, %eax        # Set PAE and PGE
      movl   %eax, %cr4

      movl   $0x0000a000, %edx  # Point CR3 at PML4
      movl   %edx, %cr3

      movl   $0xC0000080, %ecx  # Specify EFER MSR

      rdmsr
      orl    $0x00000100, %eax  # Enable long mode
      wrmsr

      movl   %cr0, %ebx
      orl    $0x80000001, %ebx  # Activate long mode
      movl   %ebx, %cr0         # by enabling paging and protection simultaneously

      lgdtl  gdt_ptr            # Set Global Descriptor Table
      
      ljmpl  $1<<3, $start64    # Jump to 64-bit code start

      .align 16
gdt:
      .quad  0x0000000000000000
      .quad  0x0020980000000000
      .quad  0x0000900000000000

gdt_ptr:
      .word  (gdt_ptr-gdt-1)
      .long  (START16_SEG*16+gdt)
      .long  0
      
      
.data
  
.global vesa_info
vesa_info:
  signature:      .ascii "VBE2"
  version:        .word  0
  vendor_string:  .word  0
                  .word  0
  capabilities:   .long  0
  video_mode_ptr: .word  0
                  .word  0
  total_memory:   .word  0
                  .space 748

.global vesa_mode_info
vesa_mode_info:
  mode_attr:      .word  0
  win_attr:       .byte  0
                  .byte  0
  win_grain:      .word  0
  win_size:       .word  0
  win_seq:        .word  0
                  .word  0
  win_scheme:     .word  0
                  .word  0
  logical_scan:   .word  0
  h_res:          .word  0
  v_res:          .word  0 
  char_width:     .byte  0
  char_height:    .byte  0
  memory_planes:  .byte  0
  bpp:            .byte  0
  banks:          .byte  0
  memory_layout:  .byte  0
  bank_size:      .byte  0
  image_planes:   .byte  0
  page_function:  .byte  0
  rmask:          .byte  0
  rpos:           .byte  0
  gmask:          .byte  0
  gpos:           .byte  0
  bmask:          .byte  0
  bpos:           .byte  0  
  resv_mask:      .byte  0
  resv_pos:       .byte  0
  dcm_info:       .byte  0
  lfb_ptr:        .long  0
  offscreen_ptr:  .long  0
  offscreen_size: .word  0
                  .space 206
              

.global vbe_modes
vbe_modes:
  .space 6*256
       
      .end
