.equ START_ADDR         , 0x7C00            # .equ defines a textual substitution
.equ MEM_BUFFER         , 0x1000            # mem buffer position
.equ ROOT_DIR           , 0x7E00            # Root Directory Buffer Offset
.equ BASE_MINIX_ADDR    , 0xA950            # Base Disk Address
.equ INODE_START_ADDR   , 0x2800            # Start Address of Inodes in Hard-Disk
.equ INODE_SIZE         , 0x0040            # INode Size
.equ LSC_SYS_INODE      , 0x8000            # LSC.SYS INODE OFFSET  (ROOT_DIR + 1024)
.equ LSC_SYS_STRING_SIZE, 8                 # LSC.SYS String Size
.equ PARTITION_BASE_ADDR, 43344
.equ BASE_DIR_LBA       , 45150
.equ INODE_LBA_START    , 43364
.equ INODES_IN_A_BLOCK  , 16

.text                         # code section starts here
.code16                       # this is real mode (16 bit) code
cli                           # no interrupts while initializing
# ... init ...                # initialization code...
      ljmp $0, $norm_cs
norm_cs:
      xorw %ax        , %ax
      movw %ax        , %ds
      movw %ax        , %ss
      movw %ax        , %es
      movw $START_ADDR, %sp 
      movb %dl        , driveid

sti                           # interrupts enabled after initializing

# ... prog ...                # main program body.../
main_prog:
      movw  $dap        , %si
      movb  $0x42       , %ah
      movb  driveid     , %dl
      int   $0x13
   #   jc    PrintError
      #movw  $msgb       , %si
      #call  PrintInfo
      movw  $ROOT_DIR   , %di

ReadDirectoryInit:  
      movw   $20  , %cx
ReadDirectory:
      movw   (%di), %bx              # Move Di content to BX to preserve the Base address of the directory entry
      orw    %bx  , %bx              # Provoke the Trigger of the Zero Flag
      jz     ReadDirectoryNextEntry
      movw   %di  , %dx              # Move DI to DX
      movw   %di  , %bx
      addw   $0x02, %dx              # Set the DI address into the String
      movw   %dx  , %si
      movw   $lscsysfilename, %di
      pushw  %cx
      call   StringCompare
      popw   %cx
      orw    %ax, %ax
      jnz    ReadDirectoryNextEntry
# String Found, we can now override all registers
      
      subw   $0x02           , %dx
      movw   %dx             , %di
      movw   (%di)           , %bx
      
      call   LoadDap
      
      movw   $LSC_SYS_INODE  , (dap_offset)
      movw   $0              , (dap_segment)
      #movl   $0              , (dap_lba_address+4)
      movl   $INODE_LBA_START, (dap_lba_address)
      int    $0x13
      jc     PrintError
      #movw   $msgloaded      , %si
      #call   PrintInfo
      xorl   %esi            , %esi
      movw   $LSC_SYS_INODE  , %si
      movw   %bx             , %cx
set_inode:
      decw   %cx
      jz     set_inode_done
      addw   $0x40           , %si
      jmp    set_inode
set_inode_done:
      movw   $inode          , %di
      movw   $64             , %cx
      cld
      rep movsb
      xorl   %edi            , %edi
      movw   $i_zone0        , %di
      movl   $7              , %ecx
      xorw   %bx             , %bx
      #xorw   %dx             , %dx
load_mem:
      movl   (%edi)          , %eax
      orl    %eax            , %eax
      jz     jump_mem
      
      shll   $1              , %eax
      addl   $PARTITION_BASE_ADDR, %eax
      
      
      movl   %eax            , (dap_lba_address)
      movw   %bx             , (dap_offset)
      movw   $MEM_BUFFER     , (dap_segment)
      
      call   LoadDap
      
      int    $0x13     
      jc     PrintError
      addl   $4              , %edi
      addw   $1024           , %bx
      decw   %cx
      jnz    load_mem
      
load_mem_indirection:
      movl   (%edi)          , %ecx
      orl    %ecx            , %ecx
      jz     jump_mem
      
      call   LoadDap
      movw   $LSC_SYS_INODE  , (dap_offset)
      movw   $0              , (dap_segment)
      shll   $1              , %ecx
      addl   $PARTITION_BASE_ADDR, %ecx
      movl   %ecx            , (dap_lba_address)
      int    $0x13
      jc     PrintError

      ## WARNING, TO IMPLEMENT 2nd Indirection, MUST PRESERVE EDI AND EDX
      movl   $LSC_SYS_INODE  , %edi
      
load_mem_indirection_zones:

      movl   (%edi)          , %ecx
      orl    %ecx            , %ecx
      jz     jump_mem
      
      call   LoadDap
      
      shll   $1              , %ecx
      addl   $PARTITION_BASE_ADDR, %ecx
      movl   %ecx            , (dap_lba_address)
      movw   %bx             , (dap_offset)
      movw   $MEM_BUFFER     , (dap_segment)  
      
      addl   $4              , %edi
      addw   $1024           , %bx
      
      jmp    load_mem_indirection_zones
      
jump_mem:
      movw   $0x10, %ax
      movw   %ax  , %ds
      movw   %ax  , %es
      movw   %ax  , %fs
      movw   %ax  , %gs
      movw   %ax  , %ss
      
      ljmp $MEM_BUFFER, $0

ReadDirectoryNextEntry:
#      movw   %dx  , %si
#      call   PrintInfo
      movw   %bx  , %di
      addw   $0x20, %di
      decw   %cx
      jnz    ReadDirectory
      movw   $msgnotfound, %si
      call   PrintInfo
      jmp    stop
       
PrintError:
      movw   $msgerror, %si
      call   PrintInfo
      jmp    stop

PrintInfo:
      lodsb                         # load next byte from string from SI to AL
      orb    %al, %al               # Does AL=0?
      jz     FunctionComplete       # Yep, null terminator found-bail out
      movb   $0x0E, %ah             # Nope-Print the character
      int    $0x10
      jmp    PrintInfo              # Repeat until null terminator found

StringCompare:
      movw   $LSC_SYS_STRING_SIZE, %cx
      cld
      repe   cmpsb
      je     StringFound
      movw   $99, %ax
      jmp    FunctionComplete

StringFound:
      movw   $msgloadingsys, %si
      call   PrintInfo
      xorw   %ax           , %ax
      jmp    FunctionComplete
  
LoadDap:
      movw   $dap      , %si
      movb   $0x42     , %ah
      movb   (driveid) , %dl
      movb   $16       , (dap)
      movb   $0        , (dap_reserved)
      movb   $2        , (dap_sectors)

FunctionComplete:
      ret

stop:
    hlt
    jmp stop

.section .rodata                  # program constants (no real protection)
#msgb:       .ascii "Starting LSC..."
#            .byte  13, 10, 0
            
msgerror:   .ascii "Error"# while loading LSC..."
            .byte 0
#            .byte  13, 10, 0

msgnotfound:  .ascii "LSC.SYS Not Found"
              .byte 0
#              .byte  13, 10, 0    

msgloadingsys:  .ascii "Loading"# lsc.sys"
                .byte 0
#                .byte  13, 10, 0              

lscsysfilename:  .ascii "lsc.sys"
                 .byte  0
                

.data                             # program variables (probably not needed)
driveid:
      .byte  0
#lsc:
#      .long  2011
dap:
      .byte  16
dap_reserved:
      .byte  0
dap_sectors:
      .word  2
dap_offset:    
      .word  ROOT_DIR
dap_segment:
      .word  0
dap_lba_address:
      .quad  BASE_DIR_LBA

#superblock:
#    s_ninodes:       .word 0
#    s_nzones:        .word 0
#    s_imap_blocks:   .word 0
#    s_zmap_blocks:   .word 0
#    s_firstdatazone: .word 0
#    s_log_zone_size: .word 0
#    s_max_size:      .long 0
#    s_magic:         .word 0
#    s_state:         .word 0
#    s_zones:         .long 0
    
inode:
    i_mode:     .word  0
    i_nlinks:   .word  0
    i_uid:      .word  0
    i_gid:      .word  0
    i_size:     .long  0
    i_atime:    .long  0
    i_mtime:    .long  0
    i_ctime:    .long  0
    i_zone0:    .long  0
    i_zone1:    .long  0
    i_zone2:    .long  0
    i_zone3:    .long  0
    i_zone4:    .long  0
    i_zone5:    .long  0
    i_zone6:    .long  0
    i_zone7:    .long  0
#    i_zone8:    .long  0    
#    i_zone9:    .long  0
    
.end
