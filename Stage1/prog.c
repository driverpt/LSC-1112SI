#include "tools_perf_util_types.h"
#include "arch_x86_boot_vesa.h"
#include "lsc_io.h"
#define MAX_MODES  6
#define COUNTER_0  0x40
#define TIMER_CTRL 0x43

typedef enum {
    BLACK, DBLUE, DGREEN, DCYAN, DRED, DMAGENTA, BROWN,  LGRAY,
    DGRAY, LBLUE, LGREEN, LCYAN, LRED, LMAGENTA, YELLOW, WHITE
} Color;

typedef struct {
    unsigned b : 5;
    unsigned g : 6;
    unsigned r : 5;
} __attribute__((packed)) PixelCell;

typedef PixelCell PCScreen[600][800];

static char tempString[200];

PCScreen * screen = ( PCScreen* ) mode->lfb_ptr;

extern char vbe_modes[];

extern char vesa_info_struct[];
extern char vesa_mode_info_struct[];

struct vesa_general_info * const vesa = ( struct vesa_general_info * ) ( vesa_info_struct      + 0x10000 );
struct vesa_mode_info    * const mode = ( struct vesa_mode_info    * ) ( vesa_mode_info_struct + 0x10000 );

#define SCREEN ( *screen )

extern unsigned char bootdrv;

void init_screen() {
  screen = ( PCScreen* ) mode->lfb_ptr;
}

void clear_screen() {
    unsigned x, y, i;
    for (y = 0; y < 25; ++y) {
        for (x = 0; x < 80; ++x) {
            SCREEN[y][x].fgcolor = LGRAY;
            SCREEN[y][x].bgcolor = BLACK;
            SCREEN[y][x].blink   =   0  ;
            SCREEN[y][x].value   =  ' ' ;
        }
    }  
}

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


int strlen( const char * characters ) {
    int count = 0;
    for( ; characters[count] != 0; ++count );
    return count;
}

void printXY( unsigned y, unsigned x, const char * string ) {
    int i = 0;
    for ( i = 0; i < strlen( string ); ++i ) {
        SCREEN[y][x].fgcolor   = LGRAY;
        SCREEN[y][x].bgcolor   = BLACK;
        SCREEN[y][x].blink     = 0;
        SCREEN[y][x + i].value = string[i];
    }
}

void printXYHexa( unsigned y, unsigned x, int number ) {
    int i;
    char * numberString = itoa( number );
    printXY( y, x, numberString );
}

void clearArea( unsigned y, unsigned x, int length ) {
    int totalArea = x + length;
    for( ; totalArea != 0; --totalArea ) {
        SCREEN[y][x + totalArea].fgcolor   = LGRAY;
        SCREEN[y][x + totalArea].bgcolor   = BLACK;
        SCREEN[y][x + totalArea].blink     = 0;
        SCREEN[y][x + totalArea].value     = ' ';      
    }
}

void printSeconds( int seconds ) {
  int secondsStringLength;
  char* secondsString = itoa( seconds );
  secondsStringLength = strlen( secondsString );
  printXY( 24, 79 - secondsStringLength, secondsString );
}

u16 getCounter() {
  u8  lower;
  u8  higher;
  u16 counter;
  
  outb( TIMER_CTRL, 0 );
  
  lower  = inb( COUNTER_0 );
  higher = inb( COUNTER_0 );
  
  counter = higher;
  counter = counter << 8;
  counter = counter | lower;
  
  return counter;
}

void count() {
  int seconds, millis;
  u16 count, previous;
  seconds = 0;
  millis = 0;
  previous = getCounter();
  SCREEN[1][0].blink     = 1;
  while( seconds != 300000 ) {
    count = getCounter();
    if ( count >= previous ) {
      ++millis;
    }
    
    if ( millis >= 100 ) {
      ++seconds;
      millis = 0;
      clearArea( 20, 50, 3 );
      printSeconds( seconds );
    }    
    previous = count;
  }
  SCREEN[1][0].blink     = 0;
}


void vesa_modes_main() {
    unsigned i;
    clear_screen();
    printXYHexa( 1, 0, mode->bpp );
    printXYHexa( 1, 4, mode->h_res );
    printXYHexa( 1, 10, mode->v_res );
    //count();
    
/*    for( i = 0; i < MAX_MODES; ++i ) {
       printXYHexa( 12 + i, 36, modes[i].bpp );
    }
*/
    printXY( 0, 0, "Done" );
}
