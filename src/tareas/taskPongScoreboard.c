#include "task_lib.h"

#define WIDTH TASK_VIEWPORT_WIDTH
#define HEIGHT TASK_VIEWPORT_HEIGHT
#define C_FG_LIGHT_GREY    (0x7)
#define CANT_PONGS 3
#define SHARED_SCORE_BASE_VADDR (PAGE_ON_DEMAND_BASE_VADDR + 0xF00)

void task(void) {
	screen pantalla;

	while (true){
		uint32_t* puntajes = SHARED_SCORE_BASE_VADDR;
		for (int i = 0; i < CANT_PONGS; i++){
			uint32_t puntaje1 = puntajes[i*2];
			uint32_t puntaje2 = puntajes[i*2 + 1];
			
			task_print_dec(pantalla, puntaje1, 10, WIDTH, HEIGHT, C_FG_LIGHT_GREY); 
			task_print_dec(pantalla, puntaje2, 10, WIDTH + 2, HEIGHT, C_FG_LIGHT_GREY);
		}
		syscall_draw(pantalla);
	}
} 
 