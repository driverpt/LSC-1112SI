

typedef struct tagRGBTRIPLE {
  u8 rgbtBlue;
  u8 rgbtGreen;
  u8 rgbtRed;
} __attribute__((packed)) RGBTRIPLE;

typedef struct tagBITMAPFILEHEADER {
  u16  bfType;
  u32  bfSize;
  u16  bfReserved1;
  u16  bfReserved2;
  u32  bfOffBits;
} __attribute__((packed)) BITMAPFILEHEADER, *PBITMAPFILEHEADER;

typedef struct tagBITMAPINFOHEADER {
  u32  biSize;
  u32  biWidth;
  u32  biHeight;
  u16  biPlanes;
  u16  biBitCount;
  u32  biCompression;
  u32  biSizeImage;
  u32  biXPelsPerMeter;
  u32  biYPelsPerMeter;
  u32  biClrUsed;
  u32  biClrImportant;
} __attribute__((packed)) BITMAPINFOHEADER, *PBITMAPINFOHEADER;
