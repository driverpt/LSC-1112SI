#include "tools_perf_util_types.h"
#include "arch_x86_boot_vesa.h"
#include "lsc_io.h"
#define MAX_MODES     6
#define COUNTER_0     0x40
#define TIMER_CTRL    0x43
#define LFB_BASE_ADDR 0x3FE00000
#define VGA_HEIGHT    800
#define VGA_WIDTH     600

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

void clear_screen() {
    unsigned x, y;
    for (y = 0; y < VGA_WIDTH; ++y) {
        for (x = 0; x < VGA_HEIGHT; ++x) {
            SCREEN[y][x].r = 0;
            SCREEN[y][x].g = 0;
            SCREEN[y][x].b = 0;
        }
    }  
}

void fill_screen( unsigned r, unsigned g, unsigned b ) {
    unsigned x, y;
    for (y = 0; y < VGA_WIDTH; ++y) {
        for (x = 0; x < VGA_HEIGHT; ++x) {
            SCREEN[y][x].r = r;
            SCREEN[y][x].g = g;
            SCREEN[y][x].b = b;
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

void lsc_main() {
    fill_screen( 0, 255, 0 );
}
