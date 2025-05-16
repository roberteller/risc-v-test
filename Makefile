# Compiler and simulator settings
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Source files
SRC_DIR = src
TB_DIR = src/tb
MEM_DIR = src/memory

# Source files
SRC_FILES = \
    $(MEM_DIR)/dram_controller.sv \
    $(TB_DIR)/dram_controller_tb.sv

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

# Clean generated files
clean:
	rm -rf $(SIM_DIR)
	rm -rf *.vcd
	rm -rf *.log

.PHONY: all compile run wave clean 