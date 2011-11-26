#include "tools_perf_util_types.h"
#include "arch_x86_boot_vesa.h"
#define MAX_MODES 6

typedef enum {
    BLACK, DBLUE, DGREEN, DCYAN, DRED, DMAGENTA, BROWN,  LGRAY,
    DGRAY, LBLUE, LGREEN, LCYAN, LRED, LMAGENTA, YELLOW, WHITE
} Color;

typedef struct {
    unsigned value   : 8;
    unsigned fgcolor : 4;
    unsigned bgcolor : 3;
    unsigned blink   : 1;
} __attribute__((packed)) CharCell;

typedef CharCell PCScreen[25][80];

static char tempString[200];

PCScreen * const screen = ( PCScreen* ) 0xb8000;

extern char vbe_modes[];
struct vesa_mode_info * const modes = ( struct vesa_mode_info * ) ( vbe_modes + 0x10000 );

#define SCREEN ( *screen )

extern unsigned char bootdrv;

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

void vesa_modes_main() {
    unsigned i;
    clear_screen();
    
    for( i = 0; i < MAX_MODES; ++i ) {
       printXYHexa( 12 + i, 36, modes[i].bpp );
    }
    printXY( 12 + i, 36, "Done" );
}
/*
void lsc_main() {
    unsigned x, y, i;
    for (y = 0; y < 25; ++y) {
        for (x = 0; x < 80; ++x) {
            if ((y >= 11 && y <= 13) && (x >= 34 && x <= 45)) {
                SCREEN[y][x].fgcolor = LGRAY;
                SCREEN[y][x].bgcolor = BLACK;
                SCREEN[y][x].blink   =   0  ;
                SCREEN[y][x].value   =  ' ' ;
            } else {
                SCREEN[y][x].fgcolor =  x ;
                SCREEN[y][x].bgcolor =  y ;
                SCREEN[y][x].blink   =  0 ;
                SCREEN[y][x].value   = '*';
            }
        }
    }
    for (i = 0; i < 8; ++i) {
        SCREEN[12][36 + i].value = "ISEL LSC"[i];
    }
}
*/
