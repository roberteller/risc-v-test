# Compiler and simulator settings
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave
VERILATOR = verilator

# Verilator flags
VERILATOR_FLAGS = -Wall -Wno-fatal --trace -cc --exe -O3

# Source directories
SRC_DIR = src
TB_DIR = test
TEST_DIR = test/testsuite
MEM_DIR = src/memory
VDIR = sim/verilator/verilated

# Source files
SRC_FILES = \
    $(MEM_DIR)/dram_controller.sv \
    $(TB_DIR)/dram_controller_tb.sv

# Test variables
TEST ?= 
TEST_FILE ?= $(TEST_DIR)/$(TEST).sv

# Output files
SIM_DIR = sim
VCD_FILE = $(SIM_DIR)/dram_controller.vcd
EXEC_FILE = $(SIM_DIR)/dram_controller

# Default target
all: compile run

# Create simulation directory
$(SIM_DIR):
	mkdir -p $(SIM_DIR)

# Compile the design
compile: $(SIM_DIR)
	$(IVERILOG) -g2012 -I$(SRC_DIR) -o $(EXEC_FILE) $(SRC_FILES)

# Run simulation
run: compile
	$(VVP) $(EXEC_FILE)

# View waveforms
wave: run
	$(GTKWAVE) $(VCD_FILE)

# Test targets
test:
	@if [ -z "$(TEST)" ]; then \
		python3 test/run_tests.py; \
	else \
		python3 test/run_tests.py --test $(TEST); \
	fi

unit_test:
	python3 test/run_tests.py --category unit $(if $(TEST),--test $(TEST),)

integration_test:
	python3 test/run_tests.py --category integration $(if $(TEST),--test $(TEST),)

functional_test:
	python3 test/run_tests.py --category functional $(if $(TEST),--test $(TEST),)

regression_test:
	python3 test/run_tests.py --category regression $(if $(TEST),--test $(TEST),)

# Verilator test
verilator_test:
	cd sim/verilator && $(MAKE) run

verilator_clean:
	cd sim/verilator && $(MAKE) clean

# List all tests
list_tests:
	python3 test/run_tests.py --list

# RISC-V Compliance Tests
compliance_test:
	python3 test/compliance_tests.py

compliance_rv64ui:
	python3 test/compliance_tests.py rv64ui

compliance_rv64um:
	python3 test/compliance_tests.py rv64um

compliance_rv64ua:
	python3 test/compliance_tests.py rv64ua

compliance_all:
	python3 test/compliance_tests.py

# CoreMark Benchmark
coremark_build:
	mkdir -p benchmarks/build
	cd benchmarks && riscv64-unknown-elf-gcc -O3 -static -mcmodel=medany \
		-fno-common -funroll-loops -finline-functions \
		-falign-functions=16 -falign-jumps=4 -falign-loops=4 \
		-finline-limit=1000 -fno-if-conversion2 -fselective-scheduling \
		-fno-tree-dominator-opts -fno-reg-struct-return \
		-DPERFORMANCE_RUN=1 -DITERATIONS=10000 \
		coremark_port.c -o build/coremark.elf

coremark_test: coremark_build
	cd benchmarks/build && spike --isa=rv64gc coremark.elf

# Linux Build
linux_build:
	cd linux && chmod +x build_linux.sh && ./build_linux.sh

linux_test_qemu:
	cd linux/build/output && ./test_qemu.sh

# Debian Support (Future)
debian_setup:
	@echo "Debian support planned for future implementation"
	@echo "Requires: VirtIO drivers, network stack, storage controllers"

# Hardware Synthesis
synth_fpga:
	mkdir -p syn/fpga
	cd syn/fpga && vivado -mode batch -source ../../scripts/synthesis.tcl

# Performance Analysis
perf_analysis:
	cd benchmarks && python3 performance_analysis.py

# Clean generated files
clean:
	rm -rf $(SIM_DIR)
	rm -rf *.vcd
	rm -rf *.log
	rm -rf test/testsuite/**/*.log
	rm -rf benchmarks/build
	rm -rf linux/build
	rm -rf test/compliance

clean_all: clean
	rm -rf syn/
	rm -rf reports/

.PHONY: all compile run wave clean clean_all test unit_test integration_test functional_test regression_test verilator_test verilator_clean list_tests compliance_test compliance_rv64ui compliance_rv64um compliance_rv64ua compliance_all coremark_build coremark_test linux_build linux_test_qemu debian_setup synth_fpga perf_analysis