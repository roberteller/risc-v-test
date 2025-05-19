# RISC-V Multicore CPU Test Suite

This directory contains a comprehensive test suite for verifying the RISC-V multicore CPU design with Linux support. The test suite is organized into different categories to validate various aspects of the CPU design from basic functionality to complex features.

## Directory Structure

```
test/
├── run_tests.py             # Test runner script
├── riscv_testsuite.sv       # Original test framework
├── multicore_tb.sv          # Original multicore testbench
├── riscv_tb.sv              # Original RISC-V testbench
└── testsuite/               # Organized test suite
    ├── unit/                # Unit tests for individual components
    │   ├── mmu_test.sv      # Tests for Memory Management Unit
    │   └── l1_cache_test.sv # Tests for L1 cache
    ├── integration/         # Integration tests for connected components
    │   └── cache_coherence_test.sv # Tests for cache coherence
    ├── functional/          # Functional tests for complete features
    │   └── supervisor_mode_test.sv # Tests for supervisor mode and VM
    └── regression/          # Regression tests to prevent regressions
        └── multicore_performance_test.sv # Performance regression tests
```

## Test Categories

1. **Unit Tests**: Validate individual components in isolation
   - `mmu_test.sv`: Tests virtual memory translation, TLB, and page faults
   - `l1_cache_test.sv`: Tests cache read/write, hits/misses, and eviction

2. **Integration Tests**: Validate interactions between components
   - `cache_coherence_test.sv`: Tests MESI protocol between cores and caches

3. **Functional Tests**: Validate complete features
   - `supervisor_mode_test.sv`: Tests supervisor mode operation with virtual memory

4. **Regression Tests**: Detect performance regressions
   - `multicore_performance_test.sv`: Tracks performance metrics for matrix multiplication

## Running Tests

The test suite can be run using the provided Python script:

```bash
# Run all tests
make test

# Run a specific test by name
make test TEST=mmu_test

# Run tests by category
make unit_test
make integration_test
make functional_test
make regression_test

# List available tests
make list_tests
```

## Test Reports

Each test generates a report with test results, and optionally VCD waveform files for further analysis. Performance regression tests also compare against baseline metrics to detect performance degradation.

## Adding New Tests

To add a new test:

1. Create a new SystemVerilog file in the appropriate category directory
2. Follow the test template structure as shown in existing tests
3. Implement test cases with clear pass/fail criteria
4. Add appropriate assertions and error checking
5. Run the test to verify functionality

## Test Environment

The test environment provides:

- Simulated memory with configurable latency
- Core monitoring for performance metrics
- Automated checking of results
- Waveform capture for debug

## Verilator Support

For faster simulation, tests can also be run using Verilator:

```bash
make verilator_test
```

## Continuous Integration

The test suite is designed to be integrated with CI/CD pipelines, with a proper exit code to indicate test success or failure.

## Test Coverage

The test suite aims to cover:

- Basic CPU functionality (instructions, registers, pipeline)
- Memory hierarchy (caches, coherence)
- Virtual memory and supervisor mode
- Multicore operation and synchronization
- Performance characteristics
- Exception handling
- Linux compatibility features 