# RISC-V Multicore Processor Documentation

## Overview

This documentation provides comprehensive information about the RISC-V multicore processor implementation and its test suite. The project implements a 4-core RISC-V processor with specialized cores for different types of operations.

## Documentation Structure

### 1. [Architecture Documentation](architecture.md)
- Core architecture details
- Pipeline stages
- Memory hierarchy
- Interconnect design
- Register files
- Performance features
- Debug capabilities

### 2. [Test Suite Documentation](test_suite.md)
- Test structure
- Test cases
- Verification points
- Test infrastructure
- Running tests
- Test results
- Performance metrics

### 3. [Implementation Guide](implementation_guide.md)
- Development environment
- Implementation steps
- Testing strategy
- Performance optimization
- Debug features
- Verification methodology
- Build automation

## Quick Start

### Prerequisites
- SystemVerilog simulator
- Git
- Make
- Python (optional)

### Getting Started
1. Clone the repository:
   ```bash
   git clone https://github.com/roberteller/risc-v-test.git
   cd risc-v-test
   ```

2. Build the project:
   ```bash
   make compile
   ```

3. Run the test suite:
   ```bash
   make test
   ```

## Project Structure

```
.
├── src/                    # Source code
│   ├── core/              # Core implementation
│   ├── alu/               # ALU implementation
│   ├── control/           # Control unit
│   └── utils/             # Utility modules
├── test/                  # Test files
│   └── riscv_testsuite.sv # Main test suite
├── docs/                  # Documentation
│   ├── architecture.md    # Architecture details
│   ├── test_suite.md     # Test suite documentation
│   ├── implementation_guide.md # Implementation guide
│   └── index.md          # This file
├── scripts/              # Build and test scripts
└── Makefile             # Build automation
```

## Core Features

### Core 0: Arithmetic Operations
- Basic arithmetic (ADD, SUB)
- Logical operations (AND, OR, XOR)
- Shift operations (SLL, SRL, SRA)
- Comparison operations (SLT, SLTU)

### Core 1: Memory Operations
- Load operations (LW, LH, LB, LD)
- Store operations (SW, SH, SB, SD)
- Memory alignment handling
- Access pattern optimization

### Core 2: Branch Operations
- Conditional branches (BEQ, BNE, BLT, BLTU)
- Jump operations (JAL, JALR)
- Branch prediction
- Pipeline control

### Core 3: CSR Operations
- CSR access (CSRRS, CSRRC, CSRRW)
- Performance counters
- Machine mode CSRs
- Exception handling

## Development Guidelines

### Code Style
- Follow SystemVerilog coding standards
- Use meaningful variable names
- Include detailed comments
- Maintain consistent formatting

### Testing Requirements
- Unit test coverage > 90%
- Integration test coverage > 80%
- System test coverage > 70%
- Performance test coverage > 60%

### Documentation Requirements
- Update documentation with code changes
- Include interface descriptions
- Document timing requirements
- Maintain test documentation

## Contributing

### Development Process
1. Create feature branch
2. Implement changes
3. Add tests
4. Update documentation
5. Submit pull request

### Code Review
- Review coding standards
- Verify test coverage
- Check documentation
- Validate performance

## Support

### Getting Help
- Check documentation
- Review test cases
- Examine debug output
- Contact maintainers

### Reporting Issues
- Use GitHub issues
- Include test case
- Provide debug information
- Describe environment

## License

This project is licensed under the MIT License - see the LICENSE file for details. 