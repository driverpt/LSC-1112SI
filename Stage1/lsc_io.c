#include "lsc_io.h"

int readSectors( u32 base, u32 n, void * dest ) {
  u8 status;
  u8 drive;
  u32 base_normalized;
  u32 sectors_read = 0;
  
  do {
    status = inb( ATA_STATUS_REGISTER );
  } while( ( status & BSY ) != 0 );
  
  base_normalized = base & 0x0FFFFFFF ;
  
  drive = MASTER_DRIVE | 0xE0 | ( base_normalized >> 24 );
  outb( drive, ATA_DRIVE_LBA_27_24 );
  ATA_PAUSE();
  outb( base_normalized >> 16, ATA_LBA_23_16_REGISTER      );
  outb( base_normalized >> 8 , ATA_LBA_15_8_REGISTER       );
  outb( base_normalized      , ATA_LBA_7_0_REGISTER        );
  outb( n                    , ATA_SECTOR_COUNT_REGISTER   );
  outb( 0                    , ATA_ERROR_FEATURES_REGISTER );
  outb( 0x20                 , ATA_COMMAND_REGISTER        );

  while( sectors_read != n ) {
    ATA_PAUSE();
    do {
      status = inb( ATA_STATUS_REGISTER );
    } while( (status & BSY) != 0 );
    
    do {
      status = inb( ATA_STATUS_REGISTER );
    } while( (status & ( DF | DRQ | ERR )) == 0 );
    
    if ( ( status & ( ERR | DF ) ) != 0 ) {
      return -1;
    }
    
    rep_insw( ATA_DATA_REGISTER, dest, SECTOR_SIZE / 2 );
    ++sectors_read;
    dest = ( char * ) dest + SECTOR_SIZE;
  }

  return 0;
}
