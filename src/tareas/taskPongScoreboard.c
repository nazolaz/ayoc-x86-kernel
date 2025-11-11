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
		for (uint8_t i = 0; i < CANT_PONGS; i++){
			//uint32_t* puntajes = (uint32_t*) (SHARED_SCORE_BASE_VADDR + ((uint32_t) i * sizeof(uint32_t)*2));
			uint8_t puntaje1 = puntajes[i*2];
			uint8_t puntaje2 = puntajes[i*2 + 1];

			task_print(pantalla, "Run", 10, 9, C_BG_LIGHT_GREY);
			task_print(pantalla, "P1", 10, 10, C_BG_LIGHT_GREY);
			task_print(pantalla, "P2", 10, 11, C_BG_LIGHT_GREY);
			
			task_print_dec(pantalla, puntaje1, 3, 20, 20, C_FG_LIGHT_GREY); 
			task_print_dec(pantalla, puntaje2, 3, 20, 21, C_FG_LIGHT_GREY);
		}
		syscall_draw(pantalla);
	}
} 
 