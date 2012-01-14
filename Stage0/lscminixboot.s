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
      call   LoadDap
      movw   $ROOT_DIR   , %di

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
      movw   %bx             , %di
      movw   (%di)           , %bx
            
      movw   $LSC_SYS_INODE  , (dap_offset)
      movw   $0              , (dap_segment)
      movl   $INODE_LBA_START, (dap_lba_address)
      
      call   LoadDap
      movw   $LSC_SYS_INODE  , %si
set_inode:
      decw   %bx
      jz     set_inode_done
      addw   $0x40           , %si
      jmp    set_inode
# Move the INode into the temporary Structure the bottom of this code
set_inode_done:
      movw   %bx             , %cx
      movw   $inode          , %di
      movw   $64             , %cx
      cld
      rep movsb
      movl   $i_zone0        , %edi   # Set the EDI Pointer to the top of the structure
      movw   $7              , %cx   # We will read 7 Inodes, which will be the Direct ones
      xorw   %bx             , %bx    # Lets clear BX that will work as our offset to control memory fill
# This Label will start reading the INode into memory
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
      
      addw   $4              , %di     # Set EDI to point to the next 4byte pointer
      addw   $1024           , %bx     # Set the Offset to the next Block
      decw   %cx
      jnz    load_mem
      
load_mem_indirection:
      movl   (%edi)          , %ecx
      orl    %ecx            , %ecx
      jz     jump_mem
      
      movw   $LSC_SYS_INODE  , (dap_offset)
      movw   $0              , (dap_segment)
      shll   $1              , %ecx
      addl   $PARTITION_BASE_ADDR, %ecx
      movl   %ecx            , (dap_lba_address)
      call   LoadDap

      ## WARNING, TO IMPLEMENT 2nd Indirection, MUST PRESERVE EDI AND EDX
      movl   $LSC_SYS_INODE  , %edi
      
load_mem_indirection_zones:

      movl   (%edi)          , %ecx
      orl    %ecx            , %ecx
      jz     jump_mem
      
      shll   $1              , %ecx
      addl   $PARTITION_BASE_ADDR, %ecx
      movl   %ecx            , (dap_lba_address)
      movw   %bx             , (dap_offset)
      movw   $MEM_BUFFER     , (dap_segment)  
      call   LoadDap
      
      addw   $4              , %di
      addw   $1024           , %bx
      
      jmp    load_mem_indirection_zones
      
jump_mem:
      movw   $0x10, %ax
      movw   %ax  , %ds
      movw   %ax  , %es
      movw   %ax  , %fs
      movw   %ax  , %gs
      movw   %ax  , %ss
      
      ljmp   $MEM_BUFFER, $0

ReadDirectoryNextEntry:
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
      orw    $0xFF, %ax
      jmp    FunctionComplete

StringFound:
      movw   $msgb, %si
      call   PrintInfo
      xorw   %ax           , %ax
      jmp    FunctionComplete
  
LoadDap:
      pushl  %esi
      pushl  %eax
      pushl  %edx
      
      movw   $dap      , %si
      movb   $0x42     , %ah
      movb   (driveid) , %dl
      movb   $16       , (dap)
      movb   $0        , (dap_reserved)
      movb   $2        , (dap_sectors)
      int    $0x13
      jc     PrintError      
      
      popl   %edx
      popl   %eax
      popl   %esi
      
FunctionComplete:
      ret

stop:
      hlt
      jmp stop

.section .rodata                  # program constants (no real protection)
msgb:            .ascii "Starting LSC..."
                 .byte  13, 10, 0
            
msgerror:        .ascii "Error"
                 .byte 0

msgnotfound:     .ascii "LSC.SYS Not Found"
                 .byte  0    

lscsysfilename:  .ascii "lsc.sys"
                 .byte  0
                

.data                             # program variables (probably not needed)
driveid:
      .byte  0
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
      .long  BASE_DIR_LBA
dap_lba_address_high:
      .long  0

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
#    i_zone8:    .long  0    # These ones will be deactivated, not supported for now
#    i_zone9:    .long  0
    
.end
