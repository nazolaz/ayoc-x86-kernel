/* ** por compatibilidad se omiten tildes **
================================================================================
 TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Rutinas del controlador de interrupciones.
*/
#include "pic.h"

#define PIC1_PORT 0x20
#define PIC2_PORT 0xA0

//#define ICW1_ICW4 0x01
//#define ICW1_INIT 0x10
//define PIC1_DATA (PIC1_PORT+1)
//define PIC2_DATA (PIC2_PORT+1)

static __inline __attribute__((always_inline)) void outb(uint32_t port,
                                                         uint8_t data) {
  __asm __volatile("outb %0,%w1" : : "a"(data), "d"(port));
}
void pic_finish1(void) { outb(PIC1_PORT, 0x20); }
void pic_finish2(void) {
  outb(PIC1_PORT, 0x20);
  outb(PIC2_PORT, 0x20);
}

// COMPLETAR: implementar pic_reset()
void pic_reset() {
  // ¿Que orden?

  // Inicialización PIC1 
  // ICW1: IRQs activas, modo cascada e indica que ICW4 va a estar presente.
  outb(PIC1_PORT, 0x11); 
  // ICW2: INT base para el PIC1, tipo x08 (?).
  outb(PIC1_PORT+1, 0x08);
  // ICW3: PIC1 Master, tiene Slave conectado a IRQ2
  outb(PIC1_PORT+1, 0x04);
  // ICW4: Modo no Buffered, fin de interrupción normal; deshabilitar interrupciones del PIC1
  outb(PIC1_PORT+1, 0x01);
  // OCW1: Set o Clearel IMR
  outb(PIC1_PORT+1, 0xFF);

  // Inicialización PIC2
  // ICW1: IRQs activas, modo cascada e indica que ICW4 va a estar presente.
  outb(PIC2_PORT, 0x11);
  // ICW2: INT base para el PIC2, tipo x70 (?).
  outb(PIC2_PORT+1, 0x70);
  // ICW3: PIC2 Slave, IRQ2 es lo que envia al Master.
  outb(PIC2_PORT+1, 0x02);
  // IC4W: Modo no Buffered; fin de interrupción normal.
  outb(PIC2_PORT+1, 0x01);
  // OCW1: Set o Clearel IMR
  outb(PIC2_PORT+1, 0xFF);
}

void pic_enable() {
  outb(PIC1_PORT + 1, 0x00);
  outb(PIC2_PORT + 1, 0x00);
}

void pic_disable() {
  outb(PIC1_PORT + 1, 0xFF);
  outb(PIC2_PORT + 1, 0xFF);
}
