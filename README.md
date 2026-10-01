# x86 Protected Mode Kernel

Course project for **Arquitectura y Organización del Computador** (Computer Architecture and Organization)  
Departamento de Computación, Facultad de Ciencias Exactas y Naturales (FCEyN)  
Universidad de Buenos Aires (UBA)

---

## Overview

This repository contains a bare-metal 32-bit x86 operating system kernel developed incrementally throughout the practical coursework of Computer Architecture and Organization. The system boots from a virtual floppy disk image in 16-bit real mode and executes on **QEMU**.

Starting from a starter template provided by the teaching team, we implemented the low-level subsystems required to bring the processor into **32-bit Protected Mode**, initialize **hardware interrupts and exceptions (IDT/PIC)**, set up virtual memory with **two-level paging (MMU)**, and implement **hardware task switching (TSS)** running user-space processes (Pong game and Scoreboard) in Ring 3.

The original course assignment is available in [CONSIGNA.md](CONSIGNA.md), and the stage guides are located in:
- [Part 1: Transition to Protected Mode](01_modo-protegido.md)
- [Part 2: Interrupts and PIC](02_interrupciones.md)
- [Part 3: Paging and MMU](03_paginacion.md)
- [Part 4: Tasks and Multitasking](04_tareas.md)

---

## Starter Template vs. Our Implementation

The course provided:
- Bootsector code responsible for reading `KERNEL.BIN` from the floppy disk into memory at `0x1200` in real mode.
- Build infrastructure (Makefile for compiling freestanding 32-bit binaries, linking with `ld`, creating the disk image, and launching QEMU).
- Skeleton files with structure declarations and `/* COMPLETAR */` markers.
- Graphics assets, user task templates (Pong logic), and basic screen drawing routines.

Our implementation developed the core kernel mechanics:

### 1. Protected Mode Transition & Segmentation (`kernel.asm`, `gdt.c`)
- Enabled the A20 address line to bypass the 1 MB memory boundary limitation.
- Configured the Global Descriptor Table (GDT):
  - Ring 0 Code and Data descriptors (flat 4 GB model).
  - Ring 3 Code and Data descriptors (DPL=3).
  - Video memory segment descriptor (`0xB8000`).
  - TSS descriptors for initial and user tasks.
- Loaded the GDTR register, enabled the Protection Enable (`PE`) bit in `CR0`, and executed a far jump to serialize execution and reload `CS`.
- Initialized segment registers (`DS`, `ES`, `FS`, `GS`, `SS`) and set up the kernel stack (`ESP`).

### 2. Interrupts, PIC and Low-Level Handlers (`idt.c`, `pic.c`, `isr.asm`)
- Populated the Interrupt Descriptor Table (IDT) with interrupt and trap gates, and loaded `IDTR`.
- Reprogrammed Master and Slave 8259 PICs (ICW1–ICW4), remapping IRQ vectors 0–15 to interrupts 32–47 to avoid conflicts with Intel CPU exception vectors (0–31).
- Implemented assembly ISR routines in `isr.asm`:
  - CPU exception handlers (saving registers with `pushad`, invoking C handlers, and returning with `iret`).
  - Timer tick handler (IRQ 0 / PIT) updating the on-screen clock and driving scheduling.
  - Keyboard handler (IRQ 1) reading scan codes from port `0x60`.
  - System call gate exposed to user privilege (Ring 3).

### 3. Paging and Virtual Memory (`mmu.c`)
- Configured two-level x86 paging structures using 4 KB page directories (PDE) and page tables (PTE).
- Set up kernel identity mapping for the initial megabytes of memory.
- Implemented dynamic virtual memory management:
  - `mmu_map_page`: On-demand allocation of intermediate page tables and mapping of virtual addresses to physical frames with appropriate access flags (`P`, `R/W`, `U/S`).
  - `mmu_unmap_page`: Page unmapping with explicit TLB invalidation (`invlpg`).
  - `mmu_init_task_dir`: Isolated virtual address spaces for user processes, mapping user code, private user stack, and preserving kernel space mappings.
- Loaded `CR3` and activated the Paging (`PG`) bit in `CR0`.

### 4. Hardware Multitasking (`tss.c`, `tasks.c`)
- Configured Task State Segments (TSS) for the initial task, an idle task, and user-space tasks (`taskPong` and `taskPongScoreboard`).
- Allocated dedicated Ring 0 kernel stacks (`ESP0`, `SS0`) inside each TSS to allow safe privilege elevation upon interrupts.
- Loaded the Task Register (`ltr`) and implemented task switching via far jumps to GDT TSS selectors.
- Integrated concurrent execution of the Pong game and live scoreboard in VGA text mode.

### 5. Theoretical Analysis
- Detailed justifications for descriptor configurations, memory maps, address calculations, and architecture questions are documented in [respuestas.md](respuestas.md).

---

## Repository Structure

```text
ayoc-x86-kernel/
├── CONSIGNA.md                 # General course assignment prompt
├── 01_modo-protegido.md        # Part 1 guide: Protected mode transition
├── 02_interrupciones.md        # Part 2 guide: IDT & PIC
├── 03_paginacion.md            # Part 3 guide: Paging & MMU
├── 04_tareas.md                # Part 4 guide: Multitasking & TSS
├── respuestas.md               # Detailed theoretical questions and analysis
├── img/                        # Reference diagrams
└── src/
    ├── Makefile                # Build and execution targets
    ├── kernel.asm              # Kernel entry point (Real -> Protected mode)
    ├── defines.h               # Architecture constants and selectors
    ├── gdt.c / gdt.h           # GDT initialization and descriptors
    ├── idt.c / idt.h           # IDT initialization and gate descriptors
    ├── isr.asm                 # Assembly interrupt service routines
    ├── pic.c / pic.h           # 8259 PIC drivers
    ├── mmu.c / mmu.h           # Memory management unit & page mapping
    ├── tss.c / tss.h           # Task State Segments & descriptors
    ├── screen.c / screen.h     # VGA text mode driver (0xB8000)
    ├── sched.c / sched.h       # Scheduler logic
    ├── tasks.c / tasks.h       # Task loader
    └── tareas/                 # User tasks (Pong, Scoreboard, Idle)
```

---

## Building and Running

### Prerequisites

- `gcc` (with multilib support for 32-bit targets: `-m32`)
- `nasm`
- `make`, `bzip2`, `mtools` (`mcopy`)
- `qemu-system-i386`
- `gdb` (optional, for debugging)

### Build the Floppy Disk Image

From the `src/` directory:

```bash
cd src
make
```

This compiles all C and assembly source files, links the kernel binary, creates `kernel.bin`, and copies it to `diskette.img`.

### Run in QEMU

```bash
make qemu
```

To run with GDB debugging enabled (listening on `localhost:1234`):

```bash
make qemu-gdb
```
