# RISC-V Linux-Capable Multicore Processor

This repository contains the implementation of a multicore RISC-V processor capable of running Linux. The design implements the RV64GC ISA (64-bit RISC-V with General-purpose extensions and Compressed instructions) with supervisor mode and virtual memory support required for a full Linux OS.

## Architecture Overview

The processor has the following key features:

- **Multicore Design**: 4 CPU cores that can work independently or cooperatively
- **RV64GC Support**: Full 64-bit RISC-V with atomic operations, FPU, and compressed instructions 
- **Memory Management**: Sv39 virtual memory mode with full MMU and TLB support
- **Cache Hierarchy**: Per-core L1 instruction and data caches with shared L2 cache
- **Cache Coherence**: MESI protocol for multi-core coherency
- **Linux Support**: Full supervisor mode with privileged instructions and CSRs
- **Memory Controller**: Support for large external memory
- **UART Interface**: Basic console I/O

## Design Structure

The project is organized into the following key components:

### Core Components

- `src/riscv_core.sv`: RISC-V core implementation (single core)
- `src/linux_multicore.sv`: Top-level multicore implementation with Linux support
- `src/multicore.sv`: Original multicore implementation (without Linux support)
- `src/mmu.sv`: Memory Management Unit for virtual memory translation
- `src/supervisor_csr.sv`: Supervisor mode CSRs required for Linux
- `src/privilege_controller.sv`: Privilege mode controller
- `src/top.sv`: Top-level system connections

### Memory Hierarchy

- `src/l1_cache.sv`: L1 cache implementation (separate I$ and D$ instances per core)
- `src/l2_cache.sv`: Shared L2 cache with coherence support
- `src/boot_rom.sv`: Boot ROM for initializing system at startup

### Testing & Simulation

- `src/linux_multicore_tb.sv`: Testbench for the complete system
- `test/`: Test programs and utilities
- `sim/`: Simulation configurations

## RISC-V Linux Support Features

The processor implements key features required for running Linux:

1. **Privilege Modes**:
   - Machine Mode (M-mode): Highest privilege
   - Supervisor Mode (S-mode): For the OS kernel
   - User Mode (U-mode): For user applications

2. **Memory Management**:
   - Sv39 address translation (39-bit virtual addresses)
   - 3-level page tables
   - TLB with efficient replacement policy

3. **Supervisor-Mode Features**:
   - SBI (Supervisor Binary Interface) implementation
   - Virtual memory control
   - Inter-process isolation
   - System calls from user to supervisor mode

4. **Interrupts and Exceptions**:
   - Precise exception handling
   - External, timer, and software interrupts
   - Interrupt delegation to supervisor mode

## Cache Architecture

The processor implements a two-level cache hierarchy:

1. **L1 Caches**:
   - 32KB L1 instruction cache per core
   - 32KB L1 data cache per core
   - 4-way set associative
   - Write-through policy with write allocation

2. **L2 Cache**:
   - 1MB shared L2 cache
   - 8-way set associative
   - Write-back policy with write allocation
   - Cache coherence support

3. **Cache Coherence**:
   - Directory-based protocol for multi-core operation
   - Implements MESI (Modified, Exclusive, Shared, Invalid) protocol
   - Efficient bus-based snooping

## Building and Simulation

To synthesize the design:

```bash
make synth
```

To run simulation:

```bash
make sim
```

To run tests:

```bash
make test
```

## Running Linux

To run Linux on the processor, you'll need:

1. A RISC-V Linux kernel compiled for RV64GC
2. A compatible bootloader (e.g., OpenSBI)
3. A root filesystem

We've provided a simple boot ROM that initializes the processor and jumps to the Linux kernel entry point.

### Boot Process

1. Core 0 starts execution at the boot ROM address
2. The bootloader initializes the MMU, stack, and other hardware
3. The bootloader jumps to Linux kernel entry point
4. Linux initializes all cores in SMP mode

## Performance Features

The processor includes several performance optimizations:

1. **Pipelining**: 5-stage pipeline with hazard detection/forwarding
2. **Branch Prediction**: Simple branch target buffer with 2-bit predictor
3. **Out-of-Order Execution**: Limited OoO capabilities for improved IPC
4. **Superscalar**: Dual-issue capability on some instructions

## FPGA Implementation

The design is synthesizable and has been tested on various FPGA platforms. Target frequencies:

- Xilinx Ultrascale+: ~100MHz
- Intel Agilex: ~90MHz

## License

This project is released under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 