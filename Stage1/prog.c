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

PCScreen * const screen = ( PCScreen* ) 0xb8000;

extern char vbe_modes[];
struct vesa_mode_info * const modes = ( struct vesa_mode_info * ) ( vbe_modes + 0x10000 );

#define SCREEN ( *screen )

extern unsigned char bootdrv;

void clear_screen() {
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
}

void printXYHexa( unsigned y, unsigned x, int number ) {
    SCREEN[y][x].value = number;
}

void vesa_modes_main() {
    unsigned i;
    clear_screen();
    for( i = 0; i < MAX_MODES; ++i ) {
       printXYHexa( 12, 36 + i, modes[i].bpp + '0' );
    }
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
