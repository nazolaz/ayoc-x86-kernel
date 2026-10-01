# x86 Protected Mode Kernel - System Programming

Trabajo Práctico para la materia **Arquitectura y Organización del Computador (AyOC)**  
**Departamento de Computación** – [Facultad de Ciencias Exactas y Naturales (FCEyN)](https://exactas.uba.ar), **Universidad de Buenos Aires (UBA)**.

---

## 📌 Descripción del Proyecto

Este proyecto consiste en el desarrollo de un núcleo de sistema operativo básico de 32 bits (*bare-metal*) para la arquitectura Intel x86 (IA-32), ejecutado y simulado sobre el emulador **QEMU**.

A partir de un entorno de arranque base (*bootsector* de floppy disk que carga el binario en memoria a partir de `0x1200` en modo real de 16 bits), se implementaron secuencialmente todos los mecanismos esenciales del procesador para inicializar el hardware, pasar a **Modo Protegido (Protected Mode)**, habilitar la memoria virtual mediante **Paginación de dos niveles**, configurar el subsistema de **Interrupciones y Excepciones (IDT/PIC)** y gestionar multitarea mediante **Task State Segments (TSS)** ejecutando procesos de usuario en Ring 3 (videojuego Pong con Scoreboard).

La consigna y guía general del trabajo práctico provista por la cátedra se encuentra en [CONSIGNA.md](CONSIGNA.md). Adicionalmente, las consignas de cada etapa están desglosadas en:
- [Parte 1: Pasaje a modo protegido](01_modo-protegido.md)
- [Parte 2: Interrupciones](02_interrupciones.md)
- [Parte 3: Paginación](03_paginacion.md)
- [Parte 4: Tareas](04_tareas.md)

---

## 🚀 Qué se resolvió

El desarrollo se construyó completando y extendiendo la arquitectura del kernel en lenguaje **C** y **Ensamblador x86 (NASM)**:

### 1. Pasaje a Modo Protegido e Inicialización de Segmentación (Ring 0 / Ring 3)
- **Habilitación de A20 Gate**: Activación de la línea de dirección A20 para permitir el direccionamiento de memoria más allá del primer megabyte (evitando el wraparound de 8086).
- **Global Descriptor Table (GDT)**:
  - Definición de descriptores de segmento para Ring 0 (Código y Datos del Kernel en modelo plano de 4GB con privilegios de supervisor).
  - Definición de descriptores de segmento para Ring 3 (Código y Datos de Usuario con DPL=3).
  - Descriptor para la memoria de video VGA (`0xB8000`).
  - Descriptores TSS para la tarea inicial y tareas de usuario.
- **Transición de Modo**: Carga del registro `GDTR` (`lgdt`), activación del bit PE (*Protection Enable*) en `CR0` y ejecución de un salto lejano (*far jump*) para vaciar el pipeline de instrucciones y cargar el selector de código de 32 bits en `CS`.
- Inicialización de los selectores de datos (`DS`, `ES`, `FS`, `GS`, `SS`) y configuración del puntero de pila del kernel (`ESP`).

### 2. Manejo de Interrupciones y Excepciones (IDT, PIC y Rutinas ISR)
- **Interrupt Descriptor Table (IDT)**: Creación y registro de descriptores de interrupción (Interrupt Gates) en `idt.c` y carga del registro `IDTR` (`lidt`).
- **Reprogramación del Controlador de Interrupciones (8259 PIC)**: Remapeo de los puertos del PIC Master y Slave (enviando palabras de inicialización ICW1–ICW4) para desplazar los vectores de interrupción de hardware (IRQs 0 a 15) a los números 32 a 47, evitando solapamientos con las excepciones reservadas de Intel (0–31).
- **Rutinas de Atención en Assembler (`isr.asm`)**:
  - Captura y manejo de excepciones del CPU (#DE, #UD, #GP, #PF con lectura del registro `CR2`, etc.) salvando el contexto completo de registros (`pushad`), invocando handlers en C y retornando de forma segura mediante `iret`.
  - Rutina para el Timer Tick del procesador (IRQ 0 / PIT) encargada de refrescar el reloj y arbitrar el tiempo de CPU.
  - Rutina para el teclado (IRQ 1) con lectura del scan code desde el puerto `0x60` y visualización.
  - Rutina de atención de llamadas al sistema (*syscalls*) con compuertas de interrupción accesibles desde Ring 3 (DPL=3).

### 3. Memoria Virtual y Paginación de Dos Niveles (MMU)
- **Estructuras de Paginación x86**: Configuración de directorios de páginas (*Page Directory*) y tablas de páginas (*Page Tables*) de 4 KB con flags de presencia (`P`), lectura/escritura (`R/W`) y usuario/supervisor (`U/S`).
- **Mapeo de Identidad (*Identity Mapping*)**: Mapeo 1:1 de los primeros megabytes de memoria para el kernel y los buffers de hardware (video VGA).
- **Administrador de Memoria (`mmu.c`)**:
  - `mmu_map_page`: Creación bajo demanda de tablas de páginas intermedias y vinculación de direcciones virtuales con marcos de página físicos.
  - `mmu_unmap_page`: Desasociación de páginas e invalidación selectiva en la TLB mediante `invlpg`.
  - `mmu_init_task_dir`: Aislamiento de memoria por proceso, mapeando el código de usuario en `0x08000000`, la pila de usuario y preservando el espacio de kernel.
- **Activación de Paginación**: Carga del directorio del kernel en `CR3` y encendido del bit PG (*Paging*) en el registro `CR0`.

### 4. Multitarea y Conmutación por Hardware (TSS)
- **Task State Segments (TSS)**:
  - Estructuración de la TSS inicial para registrar el estado previo del CPU.
  - Inicialización de la TSS de la tarea *Idle* y de las tareas de usuario (`taskPong` y `taskPongScoreboard`).
  - Configuración de los registros de segmento, selectores de pila de usuario, punteros de instrucción (`EIP`) y la pila de privilegio 0 (`ESP0`, `SS0`) requerida para atender interrupciones que eleven el privilegio desde Ring 3 a Ring 0.
- **Conmutación de Tareas**: Carga del registro de tarea `TR` (`ltr`) y ejecución de saltos lejanos (`jmp far`) hacia los descriptores TSS de la GDT para conmutar contextualmente por hardware entre tareas.
- **Juego Pong y Scoreboard**: Ejecución concurrente del clásico juego Pong y su respectivo marcador visual en modo texto VGA.

### 5. Documentación Teórica y Respuestas
- Respuestas exhaustivas a las preguntas conceptuales de cada módulo, cálculos de estructuras, segmentación y paginación documentadas en [respuestas.md](respuestas.md).

---

## 📂 Estructura del Proyecto

```text
ayoc-x86-kernel/
├── CONSIGNA.md                 # Enunciado general del trabajo práctico
├── 01_modo-protegido.md        # Consigna Parte 1: Pasaje a modo protegido
├── 02_interrupciones.md        # Consigna Parte 2: Interrupciones y PIC
├── 03_paginacion.md            # Consigna Parte 3: Paginación y MMU
├── 04_tareas.md                # Consigna Parte 4: Tareas y Multitasking
├── respuestas.md               # Respuestas teóricas y justificaciones de diseño
├── img/                        # Diagramas y capturas de soporte
└── src/
    ├── Makefile                # Build system (compilación, enlace e imagen de diskette)
    ├── kernel.asm              # Entrada del kernel (Real Mode -> Protected Mode, setup)
    ├── defines.h               # Constantes de arquitectura, selectores y offsets
    ├── gdt.c / gdt.h           # Inicialización y descriptores de la GDT
    ├── idt.c / idt.h           # Inicialización y descriptores de la IDT
    ├── isr.asm                 # Rutinas de atención de interrupciones en Assembly
    ├── pic.c / pic.h           # Controladores de interrupciones programables 8259
    ├── mmu.c / mmu.h           # Administración de memoria física y virtual (paginación)
    ├── tss.c / tss.h           # Task State Segments y multitasking por hardware
    ├── screen.c / screen.h     # Driver de pantalla en modo texto (VGA 0xB8000)
    ├── sched.c / sched.h       # Scheduler para arbitrar la ejecución de tareas
    ├── tasks.c / tasks.h       # Carga e inicialización de tareas
    └── tareas/                 # Código de las tareas de usuario (Pong, Scoreboard, Idle)
```

---

## 🛠️ Compilación y Simulación

### Requisitos

- `gcc` (soporte multilib para `-m32` / arquitectura i386)
- `nasm` (ensamblador Netwide Assembler)
- `make`, `bzip2`, `mtools` (`mcopy`)
- `qemu-system-i386` (para emular la máquina x86)
- `gdb` (opcional, para depuración conectándose a QEMU vía puerto 1234)

### Compilación de la Imagen

Desde el directorio `src/`:

```bash
cd src
make
```

Esto generará el archivo `diskette.img` con el sector de booteo y el ejecutable `kernel.bin`.

### Ejecución en QEMU

Para iniciar la simulación de la máquina con el sistema operativo:

```bash
make qemu
```

O si se desea ejecutar con la interfaz gráfica de depuración de QEMU:

```bash
make qemu-gdb
```

---

## 💻 Tecnologías Utilizadas

- **C (C99 Freestanding)** sin biblioteca estándar (`-ffreestanding`, `-nostdlib`).
- **x86 Assembly (NASM)** (sintaxis Intel, 16 bits y 32 bits).
- **GNU Linker (ld)** con scripts y directivas de sección ELF a binario plano.
- **QEMU System i386** para virtualización de hardware compatible con IBM-PC.
- **GDB** con soporte para inspección remota de registros y memoria en tiempo real.
