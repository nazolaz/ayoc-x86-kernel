# x86 Protected Mode Kernel - System Programming

Practical Work for **Computer Architecture and Organization** (*Arquitectura y Organización del Computador*)  
**Department of Computer Science** – [Faculty of Exact and Natural Sciences (FCEyN)](https://exactas.uba.ar), **University of Buenos Aires (UBA)**.

---

## 📌 Project Overview

This project implements a bare-metal 32-bit operating system kernel for the Intel x86 architecture (IA-32), simulated using **QEMU**.

Starting from a foundational floppy disk bootloader that loads the kernel binary into memory at `0x1200` in 16-bit real mode, the kernel sequentially initializes core x86 architectural subsystems: transitioning to **Protected Mode**, configuring hardware **Interrupts and Exceptions (IDT/PIC)**, establishing virtual memory via **Two-Level Paging (MMU)**, and implementing hardware-assisted multitasking using **Task State Segments (TSS)** to run user-space processes (Pong game and Scoreboard) in Ring 3.

The original course instructions are preserved in [CONSIGNA.md](CONSIGNA.md). Step-by-step module guides are organized as follows:
- [Part 1: Transition to Protected Mode](01_modo-protegido.md)
- [Part 2: Interrupts & PIC](02_interrupciones.md)
- [Part 3: Paging & Virtual Memory](03_paginacion.md)
- [Part 4: Tasks & Multitasking](04_tareas.md)

---

## 🚀 Key Implementations

The kernel was developed in **C (C99 Freestanding)** and **x86 Assembly (NASM)** across several architectural layers:

### 1. Transition to 32-Bit Protected Mode & Segmentation
- **A20 Gate Activation**: Enabled the A20 address line to eliminate 8086 address wraparound and address memory beyond 1 MB.
- **Global Descriptor Table (GDT)**:
  - Segment descriptors for Ring 0 (Kernel Code and Data in a flat 4 GB memory model with supervisor privileges).
  - Segment descriptors for Ring 3 (User Code and Data with DPL=3).
  - Video memory descriptor mapping VGA text buffer at `0xB8000`.
  - Task State Segment (TSS) descriptors for the initial task and user tasks.
- **Mode Switch**: Loaded `GDTR` (`lgdt`), set the Protection Enable (`PE`) bit in `CR0`, and performed a far jump (`jmp CS_RING_0:modo_protegido`) to flush the instruction prefetch queue and serialize execution.
- Configured data segment registers (`DS`, `ES`, `FS`, `GS`, `SS`) and initialized the kernel stack pointer (`ESP`).

### 2. Interrupts, Exceptions & Hardware Timers (IDT, PIC & ISRs)
- **Interrupt Descriptor Table (IDT)**: Defined interrupt gates for CPU exceptions, hardware IRQs, and system call traps.
- **8259 PIC Remapping**: Reprogrammed Master and Slave PICs via initialization command words (ICW1–ICW4), shifting hardware IRQ vectors (0–15) to interrupts 32–47 to avoid conflicts with Intel-reserved CPU exception vectors (0–31).
- **Interrupt Service Routines (`isr.asm`)**:
  - Exception handling (#DE, #UD, #GP, and #PF reading fault address from `CR2`) with full register context preservation (`pushad`), C dispatch, and clean resumption (`popad`, `iret`).
  - Timer Tick ISR (IRQ 0 / PIT) for screen clock updates and CPU scheduling.
  - Keyboard ISR (IRQ 1) reading raw scan codes from I/O port `0x60`.
  - System call software interrupt gate accessible from Ring 3 (DPL=3).

### 3. Virtual Memory & Two-Level Paging (MMU)
- **Two-Level Paging Structures**: Managed Page Directories (PDE) and Page Tables (PTE) with 4 KB granularity, configuring presence (`P`), read/write (`R/W`), and user/supervisor (`U/S`) flags.
- **Kernel Identity Mapping**: Mapped the first megabytes of physical memory 1:1 for kernel execution and memory-mapped hardware access.
- **Memory Management Unit (`mmu.c`)**:
  - `mmu_map_page`: On-demand page table allocation and virtual-to-physical address translation binding.
  - `mmu_unmap_page`: Page unmapping with translation lookaside buffer (TLB) cache invalidation via `invlpg`.
  - `mmu_init_task_dir`: Process address space isolation, mapping user code at `0x08000000`, user stack, and preserving kernel space mappings.
- **Paging Activation**: Loaded directory base into `CR3` and enabled the Paging (`PG`) bit in `CR0`.

### 4. Hardware Multitasking & User Processes (TSS)
- **Task State Segments (TSS)**:
  - Initial TSS capturing pre-switch CPU state.
  - Configured task TSS structures for Idle task and User tasks (`taskPong` and `taskPongScoreboard`).
  - Dedicated Ring 0 stack setup (`ESP0`, `SS0`) per task to handle privilege escalation from Ring 3 during interrupts.
- **Task Switching**: Loaded the Task Register (`ltr`) and triggered hardware-assisted context switches via far jumps (`jmp far`) targeting TSS segment selectors in the GDT.
- **Pong & Scoreboard**: Concurrent execution of an interactive Pong game alongside an independent scoreboard task displaying live state in VGA text mode.

### 5. Theoretical Documentation
- In-depth design rationale, address translation arithmetic, and architectural answers are documented in [respuestas.md](respuestas.md).

---

## 📂 Repository Structure

```text
ayoc-x86-kernel/
├── CONSIGNA.md                 # General university assignment prompt
├── 01_modo-protegido.md        # Part 1 Guide: Protected mode transition
├── 02_interrupciones.md        # Part 2 Guide: IDT & PIC
├── 03_paginacion.md            # Part 3 Guide: Paging & MMU
├── 04_tareas.md                # Part 4 Guide: Multitasking & TSS
├── respuestas.md               # Detailed theoretical questions and analysis
├── img/                        # Diagram assets and captures
└── src/
    ├── Makefile                # Build system (compilation, linking & floppy disk image)
    ├── kernel.asm              # Kernel entry point (Real -> Protected mode setup)
    ├── defines.h               # Architectural constants, selectors, and offsets
    ├── gdt.c / gdt.h           # Global Descriptor Table initialization
    ├── idt.c / idt.h           # Interrupt Descriptor Table initialization
    ├── isr.asm                 # Low-level interrupt service routines in Assembly
    ├── pic.c / pic.h           # 8259 Programmable Interrupt Controller drivers
    ├── mmu.c / mmu.h           # Memory Management Unit & paging functions
    ├── tss.c / tss.h           # Task State Segments & task descriptors
    ├── screen.c / screen.h     # VGA text mode display driver (0xB8000)
    ├── sched.c / sched.h       # Round-robin task scheduler
    ├── tasks.c / tasks.h       # Task loader & initialization
    └── tareas/                 # User-space tasks (Pong, Scoreboard, Idle)
```

---

## 🛠️ Building & Running

### Prerequisites

- `gcc` (with multilib support for `-m32` / i386 target)
- `nasm` (Netwide Assembler)
- `make`, `bzip2`, `mtools` (`mcopy`)
- `qemu-system-i386` (for x86 PC emulation)
- `gdb` (optional, for remote kernel debugging)

### Building the Diskette Image

From the `src/` directory:

```bash
cd src
make
```

This compiles all assembly and C sources, links the ELF binary, strips symbols to raw binary `kernel.bin`, and copies it into `diskette.img`.

### Running in QEMU

To run the kernel simulation:

```bash
make qemu
```

To run with GDB debugging enabled (listening on `localhost:1234`):

```bash
make qemu-gdb
```

---

## 💻 Tech Stack

- **C (C99 Freestanding)** without standard library (`-ffreestanding`, `-nostdlib`).
- **x86 Assembly (NASM)** (Intel syntax, 16-bit real mode and 32-bit protected mode).
- **GNU Linker (ld)** with custom memory layout scripts.
- **QEMU System i386** PC emulator.
- **GDB** for hardware register inspection and remote debugging.
