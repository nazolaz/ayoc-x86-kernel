/* ** por compatibilidad se omiten tildes **
==============================================================================
TALLER System Programming - Arquitectura y Organizacion de Computadoras - FCEN
==============================================================================

  Definicion de funciones de impresion por pantalla.
*/

#include "screen.h"

void print(const char* text, uint32_t x, uint32_t y, uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; 
  int32_t i;
  for (i = 0; text[i] != 0; i++) {
    p[y][x].c = (uint8_t)text[i];
    p[y][x].a = (uint8_t)attr;
    x++;
    if (x == VIDEO_COLS) {
      x = 0;
      y++;
    }
  }
}

void print_dec(uint32_t numero, uint32_t size, uint32_t x, uint32_t y,
               uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; 
  uint32_t i;
  uint8_t letras[16] = "0123456789";

  for (i = 0; i < size; i++) {
    uint32_t resto = numero % 10;
    numero = numero / 10;
    p[y][x + size - i - 1].c = letras[resto];
    p[y][x + size - i - 1].a = attr;
  }
}

void print_hex(uint32_t numero, int32_t size, uint32_t x, uint32_t y,
               uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; 
  int32_t i;
  uint8_t hexa[8];
  uint8_t letras[16] = "0123456789ABCDEF";
  hexa[0] = letras[(numero & 0x0000000F) >> 0];
  hexa[1] = letras[(numero & 0x000000F0) >> 4];
  hexa[2] = letras[(numero & 0x00000F00) >> 8];
  hexa[3] = letras[(numero & 0x0000F000) >> 12];
  hexa[4] = letras[(numero & 0x000F0000) >> 16];
  hexa[5] = letras[(numero & 0x00F00000) >> 20];
  hexa[6] = letras[(numero & 0x0F000000) >> 24];
  hexa[7] = letras[(numero & 0xF0000000) >> 28];
  for (i = 0; i < size; i++) {
    p[y][x + size - i - 1].c = hexa[i];
    p[y][x + size - i - 1].a = attr;
  }
}

void screen_draw_box(uint32_t fInit, uint32_t cInit, uint32_t fSize,
                     uint32_t cSize, uint8_t character, uint8_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO;
  uint32_t f;
  uint32_t c;
  for (f = fInit; f < fInit + fSize; f++) {
    for (c = cInit; c < cInit + cSize; c++) {
      p[f][c].c = character;
      p[f][c].a = attr;
    }
  }
}

void screen_draw_layout(void) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO;

    int coloreado[][2] = { 
      {21,23}, {21,29}, {22, 24}, {22, 26}, {22,28}, {23, 23}, {23, 24}, {23, 25}, {23, 26}, {23, 27}, {23, 28}, {23, 29},
      {24, 22}, {24, 23}, {24, 25}, {24, 26}, {24, 27}, {24, 29}, {24, 30}, {25, 21}, {25, 22}, {25, 23}, {25, 24}, {25, 25},
      {25, 26}, {25, 27}, {25, 28}, {25, 29}, {25, 30}, {25, 31}, {26, 21}, {26, 23}, {26, 24}, {26, 25}, {26, 26},
      {26, 27}, {26, 28}, {26, 29}, {26, 31}, {27, 21}, {27, 23}, {27, 29}, {27, 31}, {28, 24}, {28, 25}, {28, 27}, {28, 28}, 
    };

    int n = sizeof(coloreado) / sizeof(coloreado[0]);
    for(int i = 0; i < n; i++) {
        int r = coloreado[i][0];
        int c = coloreado[i][1];
        p[r][c].c = '#';
        p[r][c].a = 2;
    }
}
