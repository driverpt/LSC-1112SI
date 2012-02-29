#include "tools_perf_util_types.h"
#include "arch_x86_boot_vesa.h"
#include "lsc_io.h"
#include "bitmap.h"
#define MAX_MODES     6
#define COUNTER_0     0x40
#define TIMER_CTRL    0x43
#define LFB_BASE_ADDR 0x3FE00000
#define PAGE_FRAME    0x00200000
#define VGA_HEIGHT    800
#define VGA_WIDTH     600

#define TRUE          1
#define FALSE         0

typedef enum {
    BLACK, DBLUE, DGREEN, DCYAN, DRED, DMAGENTA, BROWN,  LGRAY,
    DGRAY, LBLUE, LGREEN, LCYAN, LRED, LMAGENTA, YELLOW, WHITE
} Color;

typedef struct {
    unsigned b : 5;
    unsigned g : 6;
    unsigned r : 5;
} __attribute__((packed)) PixelCell;

typedef PixelCell PCScreen[VGA_WIDTH][VGA_HEIGHT];

static char tempString[200];

PCScreen * screen = ( PCScreen* ) LFB_BASE_ADDR;

extern char vbe_modes[];

extern char vesa_info_struct[];
extern char vesa_mode_info_struct[];

struct vesa_general_info * const vesa = ( struct vesa_general_info * ) ( vesa_info_struct      + 0x10000 );
struct vesa_mode_info    * const mode = ( struct vesa_mode_info    * ) ( vesa_mode_info_struct + 0x10000 );

#define SCREEN ( *screen )

extern unsigned char bootdrv;

char* itoa( int val ){
    static char buf[32];
    int i = 30, j, base = 10;
    for(; val != 0; --i, val /= base) {
        buf[i] = "0123456789"[val % base];
    }
    for( j = 0; buf[++i] != 0; ++j ) {
        tempString[j] = buf[i];
    }
    tempString[j] = 0;
    return tempString;
}

u16 getCounter() {
  u8  lower;
  u8  higher;
  u16 counter;
  
  outb( 0, TIMER_CTRL );
  
  lower  = inb( COUNTER_0 );
  higher = inb( COUNTER_0 );
  
  counter = higher;
  counter = counter << 8;
  counter = counter | lower;
  
  return counter;
}

void sleep( u32 seconds ) {
  u32 sec, mil;
  u16 count, previous;
  sec = 0;
  mil = 0;
  previous = getCounter();
  while( sec < seconds ) {
    count = getCounter();
    if ( count >= previous ) {
      ++mil;
    }
    
    if ( mil >= 100 ) {
      ++sec;
      mil = 0;
    }    
    previous = count;
  }
}

// #define RGB16(red, green, blue) ( ((red >> 3) << 11) | ((green >> 2) << 5) | (blue >> 3))

void lsc_main() {
  u8  bool;
  u32 i, j;
  u32 lbaAddress;
  char * buffer;
  char * image;
  u32 accumulator;
  u32 sectors;

  BITMAPFILEHEADER * fileHeader;
  BITMAPINFOHEADER * infoHeader;
  RGBTRIPLE        * rgbPointer;
  RGBTRIPLE        * aux;
  
  bool = TRUE;
  sectors = 2813;
  lbaAddress = 2;
  image  = ( char * ) PAGE_FRAME;
  
  while( TRUE ) {
    if ( bool == TRUE ) {
      buffer = ( char *  ) PAGE_FRAME;
      while( sectors ) {
        if ( sectors < 127 ) {
          accumulator = sectors;
        } else {
          accumulator = 127;
        }
        readSectors( lbaAddress, accumulator, buffer );
        lbaAddress += accumulator;
        buffer += accumulator * SECTOR_SIZE;
        sectors -= accumulator;
      }
      
      fileHeader = ( BITMAPFILEHEADER * ) PAGE_FRAME;
      infoHeader = ( BITMAPINFOHEADER * ) ( fileHeader + 1 );
      rgbPointer = ( RGBTRIPLE * ) ( ( ( u8 * ) fileHeader ) + fileHeader->bfOffBits );
      
      for ( i = infoHeader->biHeight ; i > 0 ; --i ) {
        for( j = 0; j < infoHeader->biWidth; ++j ) {
          SCREEN[i-1][j].r = ( rgbPointer->rgbtRed   >> 3 );
          SCREEN[i-1][j].g = ( rgbPointer->rgbtGreen >> 2 );
          SCREEN[i-1][j].b = ( rgbPointer->rgbtBlue  >> 3 );
          ++rgbPointer;
        }
      }   
      bool = FALSE;
    } else {
      for ( i = VGA_WIDTH ; i > 0 ; --i ) {
        for( j = 0; j < VGA_HEIGHT; ++j ) {
          SCREEN[i-1][j].r = 0;
          SCREEN[i-1][j].g = 150;
          SCREEN[i-1][j].b = 0;
          ++rgbPointer;      
        }
      }
      bool = TRUE;
    }
    sleep( 5 );
  }
}

