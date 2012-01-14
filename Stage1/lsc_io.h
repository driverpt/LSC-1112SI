#pragma once
#include "tools_perf_util_types.h"

#define MASTER_DRIVE                  (0<<4)
#define SLAVE_DRIVE                   (1<<4)

#define SECTOR_SIZE                   512

#define ERR                           0x01
#define DRQ                           0x08
#define DF                            0x20
#define RDY                           0x40
#define BSY                           0x80


#define ATA_DATA_REGISTER             0x01F0
#define ATA_ERROR_FEATURES_REGISTER   0x01F1
#define ATA_SECTOR_COUNT_REGISTER     0x01F2
#define ATA_LBA_7_0_REGISTER          0x01F3
#define ATA_LBA_15_8_REGISTER         0x01F4
#define ATA_LBA_23_16_REGISTER        0x01F5
#define ATA_DRIVE_LBA_27_24           0x01F6
#define ATA_STATUS_REGISTER           0x01F7
#define ATA_COMMAND_REGISTER          0x01F7

#define ATA_PAUSE() \
    {inb(ATA_STATUS_REGISTER);inb(ATA_STATUS_REGISTER);inb(ATA_STATUS_REGISTER);inb(ATA_STATUS_REGISTER);}

static inline void outb(u8 v, u16 port)
{
  asm volatile("outb %0,%1" : : "a" (v), "dN" (port));
}

static inline u8 inb(u16 port)
{
  u8 v;
  asm volatile("inb %1,%0" : "=a" (v) : "dN" (port));
  return v;
}

// 1
// 32256
static inline void rep_insw( u16 port, void * dest, u32 n ) {
  asm volatile (
      "rep insw"
    : "=D"(dest), "=c"(n)
    : "d"(port) , "D"(dest), "c"(n)
    );
}

int readSectors( u32 base, u32 n, void * dest );
