# RISC-V Multicore Processor Test Suite

This repository contains a comprehensive test suite for a RISC-V multicore processor implementation. The test suite is designed to verify the functionality of a 4-core RISC-V processor with different test cases for each core.

## Core Test Distribution

- **Core 0**: Arithmetic Operations
  - ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
  - Immediate variants of all operations

- **Core 1**: Memory Operations
  - Load/Store operations
  - Memory access patterns
  - Data alignment verification

- **Core 2**: Branch Operations
  - BEQ, BNE, BLT, BLTU
  - Branch prediction verification
  - Jump operations

- **Core 3**: CSR and Performance Counter Operations
  - Cycle counter
  - Time counter
  - Instruction counter
  - Machine status registers

## Test Suite Features

- Comprehensive test coverage for all core functionalities
- Detailed pipeline stage monitoring
- Memory access pattern tracking
- Performance counter verification
- Detailed test reporting with pass/fail statistics
- Debug information output

## Project Structure

```
.
├── src/
│   ├── core/           # Core implementation files
│   ├── alu/            # ALU implementation
│   ├── control/        # Control unit implementation
│   └── utils/          # Utility modules
├── test/
│   └── riscv_testsuite.sv  # Main test suite
└── README.md
```

## Running the Tests

To run the test suite:

1. Ensure you have a SystemVerilog simulator installed (e.g., ModelSim, VCS, or Icarus Verilog)
2. Compile the test suite and design files
3. Run the simulation

## Test Results

The test suite provides detailed output including:
- Pass/fail status for each test
- Register values
- Memory contents
- Pipeline stage information
- Overall test statistics

## Contributing

Feel free to submit issues and enhancement requests! 