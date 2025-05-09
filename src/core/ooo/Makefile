# Compiler and flags
VERILATOR = verilator
VERILATOR_FLAGS = --sv --assert --trace --timing --coverage --binary -j 0 -Wall

# Source files
SRC_FILES = \
    reorder_buffer.sv \
    reservation_station.sv \
    register_rename.sv \
    free_list.sv \
    load_store_queue.sv \
    ooo_execution_unit.sv \
    ooo_execution_unit_tb.sv

# Testbench module
TB_MODULE = ooo_execution_unit_tb

# Default target
all: compile run

# Compile
compile:
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TB_MODULE) $(SRC_FILES)

# Run simulation
run:
	@echo "Running simulation..."
	./obj_dir/V$(TB_MODULE)

# Clean
clean:
	rm -rf obj_dir *.vcd *.log coverage.dat

# Coverage
coverage:
	verilator_coverage coverage.dat

# Help
help:
	@echo "Available targets:"
	@echo "  all      - Compile and run simulation"
	@echo "  compile  - Compile the design"
	@echo "  run      - Run the simulation"
	@echo "  clean    - Remove generated files"
	@echo "  coverage - Generate coverage report"
	@echo "  help     - Show this help message"

.PHONY: all compile run clean coverage help 