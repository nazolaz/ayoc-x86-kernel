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
extern sched_init
extern task_init

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

    ;deshabilitamos interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ;bienvenida a modo real
    print_text_rm start_rm_msg, start_rm_len, C_FG_CYAN, 0, 0

    ;habilitamos A20
    call A20_check
    call A20_disable
    call A20_check
    call A20_enable

    ; cargamos la GDT
    lgdt [GDT_DESC]

    ;seteamos el bit PE del cr0 para pasar a modo protegido
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; salto a modo protegido
    jmp CS_RING_0_SEL:modo_protegido

BITS 32
modo_protegido:
    ; establecemos selectores de segmento en segmento de datos de nivel 0
    mov ax, DS_RING_0_SEL
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax

    ;establecemos pila
    mov esp, 0x25000
    mov ebp, esp

    ;bienvenida a modo protegido
    print_text_pm start_pm_msg, start_pm_len, C_FG_CYAN, 30, 0

    ;inicializamos pantalla
    call screen_draw_layout
    
    ;inicializamos directorio de kernel
    call mmu_init_kernel_dir

    ;cargamos directorio de paginas 
    mov cr3, eax

    ;habilitamos paginacion
    mov eax, cr0
    or eax, HIGHEST_BIT 
    mov cr0, eax
    
    ;cargamos la IDT
    call idt_init
    lidt [IDT_DESC]

    ;reiniciamos y habilitamos el controlador de interrupciones 
    call pic_reset      ; remapeamos PIC
    call pic_enable     ; habilitamos PIC
    sti                 ; habilitamos interrupciones

    ;inicializamos gdt entries con sus tss para tarea idle e inicial
    call tss_init
    ;inicializamos el scheduler
    call sched_init
    ;
    call task_init

    ;preparamos pantalla para nuestras tareas
    call tasks_screen_draw

    ;cargamos la tarea inicial en la TR
    mov ax, GDT_IDX_TASK_INITIAL_SELECTOR
    ltr ax

    ;saltamos a la tarea IDLE
    jmp GDT_IDX_TASK_IDLE_SELECTOR:0x0
    

    ; COMPLETAR - Inicializar las tareas

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

   ;ejercicio 3F
    ; mov eax, cr3
    ; push eax
    ; push 0x00018000
    ; call mmu_init_task_dir
    ; mov cr3, eax        
    
    ; mov byte [0x07000001], 3
    ; mov byte [0x07000001], 3

    ; pop eax
    ; pop eax
    ; mov cr3, eax