# Compiler and flags
IVERILOG = iverilog
IVERILOG_FLAGS = -g2012 -I$(SRC_DIR)
VVP = vvp
GTKWAVE = gtkwave

# Source files
SRC_DIR = src
TEST_DIR = test
SRC_FILES = $(wildcard $(SRC_DIR)/*.sv)
TEST_FILES = $(wildcard $(TEST_DIR)/*.sv)

# Output files
SIM_DIR = sim
VCD_FILE = $(SIM_DIR)/riscv.vcd
EXEC_FILE = $(SIM_DIR)/riscv

# Default target
all: compile run

# Create simulation directory
$(SIM_DIR):
	mkdir -p $(SIM_DIR)

# Compile
compile: $(SIM_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(EXEC_FILE) $(SRC_FILES) $(TEST_FILES)

# Run simulation
run: compile
	$(VVP) $(EXEC_FILE)

# View waveforms
wave: run
	$(GTKWAVE) $(VCD_FILE)

# Clean
clean:
	rm -rf $(SIM_DIR)

# Multicore test
multicore_test: sim/multicore
	./sim/multicore

sim/multicore: src/alu.sv src/control_unit.sv src/csr.sv src/immediate_generator.sv src/register_file.sv src/riscv_core.sv src/multicore.sv test/multicore_tb.sv
	$(IVERILOG) -g2012 -Isrc -o sim/multicore src/alu.sv src/control_unit.sv src/csr.sv src/immediate_generator.sv src/register_file.sv src/riscv_core.sv src/multicore.sv test/multicore_tb.sv

# Comprehensive test suite
testsuite: sim/testsuite
	./sim/testsuite

sim/testsuite: src/alu.sv src/control_unit.sv src/csr.sv src/immediate_generator.sv src/register_file.sv src/riscv_core.sv src/multicore.sv test/riscv_testsuite.sv
	$(IVERILOG) -g2012 -Isrc -o sim/testsuite src/alu.sv src/control_unit.sv src/csr.sv src/immediate_generator.sv src/register_file.sv src/riscv_core.sv src/multicore.sv test/riscv_testsuite.sv

.PHONY: all compile run wave clean multicore_test testsuite 