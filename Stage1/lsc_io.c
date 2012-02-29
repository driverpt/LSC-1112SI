#include "lsc_io.h"

int strlen( const char * characters ) {
    int count = 0;
    for( ; characters[count] != 0; ++count );
    return count;
}

int strcmp( const char * original, const char * comparator ) {
    int count = strlen( original );
    for(; count > 0; --count) {
      if ( original[count] != comparator[count] ) {
        return -1;
      }
    }
    return 0;
}

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

  return sectors_read;
}

int readZone( u32 base, void * dest ) {
  return readSectors(base, ( BLOCK_SIZE / SECTOR_SIZE ), dest );
}

void readSuperBlock( minix_super_block * superblock ) {
  char sb[BLOCK_SIZE];
  minix_super_block * retrieved;
  readSectors( BASE_LBA_PARTITION_ADDRESS + 1, 2, sb );
  retrieved = (minix_super_block *) sb;
  
  superblock->s_ninodes       = retrieved->s_ninodes;
  superblock->s_nzones        = retrieved->s_nzones;
  superblock->s_imap_blocks   = retrieved->s_imap_blocks;
  superblock->s_zmap_blocks   = retrieved->s_zmap_blocks;
  superblock->s_firstdatazone = retrieved->s_firstdatazone;
  superblock->s_log_zone_size = retrieved->s_log_zone_size;
  superblock->s_max_size      = retrieved->s_max_size;
  superblock->s_magic         = retrieved->s_magic;
  superblock->s_state         = retrieved->s_state;
  superblock->s_zones         = retrieved->s_zones;
  
}

void readINode( minix2_inode * inode, u32 number, u32 lbaBaseInode ) {
  u32 sectorReadOffset;
  u32 sectorInodeOffset;
  u8  i;
  minix2_inode inodes[INODES_PER_ZONE];
  
  sectorReadOffset  = number / INODES_PER_ZONE;
  sectorInodeOffset = number % INODES_PER_ZONE;
  
  readSectors( lbaBaseInode + sectorReadOffset, 1, inodes );
  
  inode->i_mode   = inodes[sectorInodeOffset].i_mode;
  inode->i_nlinks = inodes[sectorInodeOffset].i_nlinks;
  inode->i_uid    = inodes[sectorInodeOffset].i_uid;
  inode->i_gid    = inodes[sectorInodeOffset].i_gid;
  inode->i_size   = inodes[sectorInodeOffset].i_size;
  inode->i_atime  = inodes[sectorInodeOffset].i_atime;
  inode->i_mtime  = inodes[sectorInodeOffset].i_mtime;
  inode->i_ctime  = inodes[sectorInodeOffset].i_ctime;
  
  for( i=0; i<10; ++i ) {
    inode->i_zone[i] = inodes[sectorInodeOffset].i_zone[i];
  }
}

int readOneIndirection( u32 lbaStartZone, void * dest ) {
  u32 indirectionLevel[ZONE_SIZE/4];
  u32 i, zonesRead = 0;
  readZone( lbaStartZone, indirectionLevel );
  for(i=0; i<(ZONE_SIZE/4); ++i) {
    if( indirectionLevel[i] == 0 ) {
      break;
    }
    dest = ( ( char * ) dest ) + readZone( BASE_LBA_PARTITION_ADDRESS + indirectionLevel[i], dest ) * SECTOR_SIZE;
    ++zonesRead;
  }
  return zonesRead * ( BLOCK_SIZE/SECTOR_SIZE );
}

int readTwoIndirection( u32 lbaStartZone, void * dest ) {
  u32 indirectionLevelOne[ZONE_SIZE/4];
  u32 i, tempZonesRead = 0, zonesRead = 0;
  readZone( lbaStartZone, indirectionLevelOne );
  for(i=0; i<(ZONE_SIZE/4); ++i) {
    if( indirectionLevelOne[i] == 0 ) {
      break;
    }
    tempZonesRead = readOneIndirection( indirectionLevelOne[i] + BASE_LBA_PARTITION_ADDRESS, dest );
    dest = ( (char * ) dest ) + tempZonesRead;
    zonesRead += tempZonesRead;
  }
  return zonesRead * ( BLOCK_SIZE/SECTOR_SIZE );
}

int readThreeIndirection( u32 lbaStartZone, void * dest ) {
  u32 indirectionLevelOne[ZONE_SIZE/4];
  u32 i, tempZonesRead = 0, zonesRead = 0;
  readZone( lbaStartZone, indirectionLevelOne );
  for(i=0; i<(ZONE_SIZE/4); ++i) {
    if( indirectionLevelOne[i] == 0 ) {
      break;
    }
    tempZonesRead = readTwoIndirection( indirectionLevelOne[i] + BASE_LBA_PARTITION_ADDRESS, dest ) * ZONE_SIZE;
    dest = ( (char * ) dest ) + tempZonesRead;
    zonesRead += tempZonesRead;
  }
  return zonesRead * ( BLOCK_SIZE/SECTOR_SIZE );
}

int readFile( const char * filename, void * dest ) {
  u32 inodebaseLBAAddress, i,j;
  minix_super_block superblock;
  minix_dir_entry rootDirData[50];
  minix2_inode rootDir;
  minix2_inode file;
  char * destination = ( char * ) dest;
  readSuperBlock( &superblock );
  inodebaseLBAAddress = BASE_LBA_PARTITION_ADDRESS + ( superblock.s_imap_blocks + superblock.s_zmap_blocks + 1 ) * ( BLOCK_SIZE / SECTOR_SIZE );
  readINode( &rootDir, 0, inodebaseLBAAddress );
  // TODO: Read Directory Entries
  readSectors( rootDir.i_zone[0], ( BLOCK_SIZE / SECTOR_SIZE ), rootDirData );
  for(i=0; i<50; ++i) {
    if (strcmp(filename, rootDirData->name) == 0 ) {
      readINode(&file, rootDirData->inode, inodebaseLBAAddress);
      for(j=0; j<7; ++j) {
        destination += readZone( file.i_zone[j] + BASE_LBA_PARTITION_ADDRESS, destination ) * SECTOR_SIZE;
      }
      destination += readOneIndirection  ( file.i_zone[j++] + BASE_LBA_PARTITION_ADDRESS, destination );
      destination += readTwoIndirection  ( file.i_zone[j++] + BASE_LBA_PARTITION_ADDRESS, destination );
      destination += readThreeIndirection( file.i_zone[j++] + BASE_LBA_PARTITION_ADDRESS, destination );
      return 0;
    }
  }
  return -1;
}
