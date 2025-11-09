; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - Arquitectura y Organizacion de Computadoras - FCEN
; ==============================================================================

%include "print.mac"
extern GDT_DESC
extern screen_draw_layout
extern IDT_DESC
extern idt_init
extern pic_reset
extern pic_enable
extern copy_page
extern mmu_init_kernel_dir
extern mmu_init_task_dir
extern tss_init
extern tasks_screen_draw

;NO SUPIMOS COMO INCLUIR LOS DEFINES 
%define C_FG_CYAN   0x3
%define VIDEO_FILS  50
%define VIDEO_COLS  80
%define GDT_IDX_CODE_0 1
%define GDT_IDX_DATA_0 3
%define KERNEL_PAGE_DIR 0x00025000
%define ON_DEMAND_MEM_START_VIRTUAL 0x07000000
%define HIGHEST_BIT 0x80000000
%define GDT_IDX_TASK_INITIAL_SELECTOR (11 << 3)
%define GDT_IDX_TASK_IDLE_SELECTOR (12 << 3)


global start


; COMPLETAR - Agreguen declaraciones extern según vayan necesitando

; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL (GDT_IDX_CODE_0 << 3)  
%define DS_RING_0_SEL (GDT_IDX_DATA_0 << 3)  

BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; ==============================
    ; ||  Salto a modo protegido  ||
    ; ==============================

    ; COMPLETAR - Deshabilitar interrupciones (Parte 1: Pasake a modo protegido)
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO REAL (Parte 1: Pasake a modo protegido)
    ; (revisar las funciones definidas en print.mac y los mensajes se encuentran en la
    ; sección de datos)
    print_text_rm start_rm_msg, start_rm_len, C_FG_CYAN, 0, 0

    ; COMPLETAR - Habilitar A20 (Parte 1: Pasake a modo protegido)
    ; (revisar las funciones definidas en a20.asm)
    call A20_check
    call A20_disable
    call A20_check
    call A20_enable

    ; COMPLETAR - los defines para la GDT en defines.h y las entradas de la GDT en gdt.c
    ; COMPLETAR - Cargar la GDT (Parte 1: Pasake a modo protegido)
    lgdt [GDT_DESC]
    ; COMPLETAR - Setear el bit PE del registro CR0 (Parte 1: Pasake a modo protegido)
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; COMPLETAR - Saltar a modo protegido (far jump) (Parte 1: Pasake a modo protegido)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    jmp CS_RING_0_SEL:modo_protegido

BITS 32
modo_protegido:
    ; COMPLETAR (Parte 1: Pasake a modo protegido) - A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo
    mov ax, DS_RING_0_SEL
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax

    ; COMPLETAR - Establecer el tope y la base de la pila (Parte 1: Pasake a modo protegido)
    mov esp, 0x25000
    mov ebp, esp

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO PROTEGIDO (Parte 1: Pasake a modo protegido)
    print_text_pm start_pm_msg, start_pm_len, C_FG_CYAN, 30, 0
    ; COMPLETAR - Inicializar pantalla (Parte 1: Pasake a modo protegido)
    call screen_draw_layout
    
    ; ===================================
    ; ||     (Parte 3: Paginación)     ||
    ; ===================================

    ; COMPLETAR - los defines para la MMU en defines.h □ 
    ; COMPLETAR - las funciones en mmu.c □
    ; COMPLETAR - reemplazar la implementacion de la interrupcion 88 (ver comentarios en isr.asm) para despues
    ; COMPLETAR - La rutina de atención del page fault en isr.asm
    ; COMPLETAR - Inicializar el directorio de paginas
    call mmu_init_kernel_dir

    ; COMPLETAR - Cargar directorio de paginas 
    mov cr3, eax

    ; COMPLETAR - Habilitar paginacion 
    mov eax, cr0
    or eax, HIGHEST_BIT 
    mov cr0, eax

    ; ejercicio 3F.
    mov eax, cr3
    push eax
    push 0x00018000
    call mmu_init_task_dir
    mov cr3, eax        
    
    mov byte [0x0700000], 3
    mov byte [0x0700000], 3

    pop eax
    pop eax
    mov cr3, eax
    
    ; ========================
    ; ||  (Parte 4: Tareas) ||
    ; ========================

    ; COMPLETAR - reemplazar la implementacion de la interrupcion 88 (ver comentarios en isr.asm)
    ; COMPLETAR - las funciones en tss.c
    ; COMPLETAR - Inicializar tss
    call tss_init
    call tasks_screen_draw

    mov ax, GDT_IDX_TASK_INITIAL_SELECTOR
    ltr ax
    jmp GDT_IDX_TASK_IDLE_SELECTOR:0x0
    
    ; COMPLETAR - Inicializar el scheduler

    ; COMPLETAR - Inicializar las tareas


    ; ===================================
    ; ||   (Parte 2: Interrupciones)   ||
    ; ===================================

    ; COMPLETAR - las funciones en idt.c
    
    ; COMPLETAR - Inicializar y cargar la IDT
    call idt_init
    lidt [IDT_DESC]

    ; COMPLETAR - Reiniciar y habilitar el controlador de interrupciones (ver pic.c)
    call pic_reset  ; remapeamos PIC
    call pic_enable ; habilitamos PIC
    sti             ; habilitamos interrupciones

    ; COMPLETAR - Rutinas de atención de reloj, teclado, e interrupciones 88 y 89 (en isr.asm)

    ; ejemplo sysall interrupciones
    ; mov eax, 0x45
    ; int 88

    ; COMPLETAR (Parte 4: Tareas)- Cargar tarea inicial

    ; COMPLETAR - Habilitar interrupciones (!! en etapas posteriores, evaluar si se debe comentar este código !!)
    
    ; NOTA: Pueden chequear que las interrupciones funcionen forzando a que se
    ;       dispare alguna excepción (lo más sencillo es usar la instrucción
    ;       `int3`)
    ;int3

    ; COMPLETAR - Probar Sys_call (para etapas posteriores, comentar este código)

    ; COMPLETAR - Probar generar una excepción (para etapas posteriores, comentar este código)
    
    ; ========================
    ; ||  (Parte 4: Tareas)  ||
    ; ========================
    
    ; COMPLETAR - Inicializar el directorio de paginas de la tarea de prueba

    ; COMPLETAR - Cargar directorio de paginas de la tarea

    ; COMPLETAR - Restaurar directorio de paginas del kernel

    ; COMPLETAR - Saltar a la primera tarea: Idle

    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"

   ;ejercicio 3C. 
    ;mov eax, 0xB00000
    ;push eax
    ;mov eax, 0xA00000
    ;push eax
    ;call copy_page
    ;add esp, 8