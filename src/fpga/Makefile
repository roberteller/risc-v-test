# FPGA build Makefile

# Variables
VIVADO = vivado
PROJECT_NAME = riscv_fpga
PART = xc7a35tcpg236-1
TOP_MODULE = riscv_fpga_top

# Source files
SRC_FILES = \
    riscv_fpga_top.sv \
    reset_sync.sv \
    memory_controller.sv \
    debug_interface.sv \
    seg7_controller.sv \
    uart_tx.sv

# Constraints file
CONSTRAINTS = constraints.xdc

# Default target
all: build

# Create project
create_project:
	$(VIVADO) -mode batch -source create_project.tcl

# Build project
build: create_project
	$(VIVADO) -mode batch -source build.tcl

# Program FPGA
program:
	$(VIVADO) -mode batch -source program.tcl

# Clean
clean:
	rm -rf $(PROJECT_NAME).xpr $(PROJECT_NAME).cache $(PROJECT_NAME).runs $(PROJECT_NAME).hw $(PROJECT_NAME).ip_user_files $(PROJECT_NAME).sim

# Help
help:
	@echo "Available targets:"
	@echo "  all           - Build the project"
	@echo "  create_project - Create Vivado project"
	@echo "  build         - Build the project"
	@echo "  program       - Program the FPGA"
	@echo "  clean         - Remove generated files"
	@echo "  help          - Show this help message"

.PHONY: all create_project build program clean help 