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

# Clean generated files
clean:
	rm -rf $(SIM_DIR)
	rm -rf *.vcd
	rm -rf *.log
	rm -rf test/testsuite/**/*.log

.PHONY: all compile run wave clean test unit_test integration_test functional_test regression_test verilator_test verilator_clean list_tests 