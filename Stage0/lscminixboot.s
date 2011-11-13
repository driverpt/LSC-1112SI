.equ START_ADDR         , 0x7C00      		# .equ defines a textual substitution
.equ MEM_BUFFER         , 0x1000		  		# mem buffer position
.equ ROOT_DIR           , 0x7E00		  		# Root Directory Buffer Offset
.equ BASE_MINIX_ADDR    , 0xA950      		# Base Disk Address
.equ INODE_START_ADDR   , 0x2800		  		# Start Address of Inodes in Hard-Disk
.equ INODE_SIZE         , 0x0040		  		# INode Size
.equ LSC_SYS_INODE      , ROOT_DIR + 1024 # LSC.SYS INODE OFFSET
.equ LSC_SYS_STRING_SIZE, 8				  			# LSC.SYS String Size
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
    jc    PrintError
    movw  $msgb       , %si
    call  PrintInfo
    movw  $ROOT_DIR   , %di
    call  ReadDirectoryInit
    jmp   stop
  
read_superblock:
	
read_inode:

ReadDirectoryInit:	
	  movw   $10  , %cx	
ReadDirectory:
	  movw   (%di), %bx              # Move Di content to BX to preserve the Base address of the directory entry
	  orw    %bx  , %bx              # Provoke the Trigger of the Zero Flag
	  jz     ReadDirectoryNextEntry
	  movw   %di  , %dx              # Move DI to DX
	  addw   $0x02, %dx              # Set the DI address into the String
	  movw   %dx  , %si
	  pushw  %di
	  pushw  %cx
		movw   $lscsysfilename, %di
		call   StringCompare
		popw   %cx
		popw   %di
		orw    %ax  , %ax
	
		jmp    ReadDirectoryNextEntry
	
	
ReadDirectoryNextEntry:
		addw   $0x20, %di
		decw   %cx
		jz     ReadDirectoryExit
		jmp    ReadDirectory

ReadDirectoryExit:
		ret	
	
	
PrintDirectoryInit:	
		movw   $10  , %cx
PrintDirectory:
		movw   (%di), %bx           # Move Di content to BX to preserve the Base address of the directory entry
		orw    %bx  , %bx           # Provoke the Trigger of the Zero Flag
		jz     DirectoryNextEntry   
		movw   %di  , %dx           # Move DI to DX
		addw   $0x02, %dx           # Set the DI address into the String
		movw   %dx  , %si
		call   PrintInfo
		movw   %dx  , %si
		movw   $lscsysfilename , %di
		call   StringCompare
		jmp    DirectoryNextEntry
PrintDirectoryExit:
		ret
	
DirectoryNextEntry:
		addw   $0x20, %di
		call   PrintInfo
		decw   %cx
		jz     PrintDirectoryExit
		movb   $13  , %al
		movb   $0x0E, %ah
		int    $0x10
		movb   $10  , %al
		movb   $0x0E, %ah
		int    $0x10	
		jmp    PrintDirectory
	
	
PrintError:
    pushw  %si
    movw   $msgerror, %si
    call   PrintInfo
    popw   %si
    jmp    stop


PrintInfo:
    lodsb                         # load next byte from string from SI to AL
    orb    %al, %al               # Does AL=0?
    jz     PrintDone              # Yep, null terminator found-bail out
    movb   $0x0E, %ah             # Nope-Print the character
    int    $0x10
    jmp    PrintInfo              # Repeat until null terminator found
    
PrintDone:
    ret
 
StringCompare:
		movw   $LSC_SYS_STRING_SIZE, %cx
		cld
		repe 	 cmpsb
		orw    %cx, %cx
		jz     StringFound
		movw	 $99, %ax
		jmp    FunctionComplete
	
    
StringFound:
		movw $msgloadingsys, %si
		movw $0            , %ax
		call PrintInfo
		jmp  FunctionComplete
  
FunctionComplete:
		ret
  

  
  
    movb   $'@'    , %al         # The character: â@â
    movb   $7      , %bl         # Light gray on black
    xorb   %bh     , %bh         # Using page 0
    movb   $0x0E   , %ah         # Identifying the service
    int    $0x10                 # Invoking the BIOS service
    
# ... term ...                 # end of execution...

init_vga:
    mov %es, 0xB800			     # INode Number * 64

stop:
    hlt
    jmp stop

.section .rodata                  # program constants (no real protection)
msgb: 		.ascii "Starting LSC..."
			    .byte  13, 10, 0
			
msgerror: 	.ascii "Error while loading LSC..."
			      .byte  13, 10, 0

msgloaded: 	.ascii "LSC.SYS Not Found"
			      .byte  13, 10, 0				

msgloadingsys: 	.ascii "Loading lsc.sys"
			          .byte  13, 10, 0				

lscsysfilename:  .asciz "lsc.sys"
		             .byte  0
				

.data 	                          # program variables (probably not needed)
driveid:
      .byte  0
lsc:
      .long 2011
dap:
      .byte  16
      .byte  0
      .byte  2
      .byte  0
dap_offset:    
      .word  ROOT_DIR
dap_segment:
      .word  0
dap_lba_address:
      .quad  45150

superblock:
	s_ninodes:       .word 0
	s_nzones:        .word 0
	s_imap_blocks:   .word 0
	s_zmap_blocks:   .word 0
	s_firstdatazone: .word 0
	s_log_zone_size: .word 0
	s_max_size:      .long 0
	s_magic:         .word 0
	s_state:         .word 0
	s_zones:         .long 0
    
inode:
	i_mode:     .word  0
	i_nlinks:   .word  0
	i_uid:      .word  0
	i_gid:      .word  0
	i_size:     .long  0
	i_atime:    .long  0
	i_mtime:    .long  0
	i_ctime:	  .long  0
	i_zone1:	  .long  0
	i_zone2:	  .long  0
	i_zone3:	  .long  0
	i_zone4:    .long  0
	i_zone5:    .long  0
	i_zone6:    .long  0
	i_zone7:    .long  0
	i_zone8:    .long  0
	i_zone9:    .long  0
	i_zone10:   .long  0
    
.end
