# Create project
create_project riscv_fpga . -part xc7a35tcpg236-1

# Set project properties
set_property board_part digilentinc.com:basys3:part0:1.1 [current_project]
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

# Add source files
add_files -norecurse {
    riscv_fpga_top.sv
    reset_sync.sv
    memory_controller.sv
    debug_interface.sv
    seg7_controller.sv
    uart_tx.sv
}

# Add constraints file
add_files -fileset constrs_1 -norecurse constraints.xdc

# Set top module
set_property top riscv_fpga_top [current_fileset]

# Create IP directory
set_property ip_repo_paths {ip_repo} [current_project]
update_ip_catalog

# Create clock wizard IP
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {true} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.CLKIN1_JITTER_PS {100.0} \
    CONFIG.CLKOUT1_DRIVES {BUFG} \
    CONFIG.CLKOUT1_JITTER {114.829} \
    CONFIG.CLKOUT1_PHASE_ERROR {89.971} \
] [get_ips clk_wiz_0]

# Generate IP
generate_target all [get_ips]

# Create runs
create_run synth_1 -flow {Vivado Synthesis 2020}
create_run impl_1 -flow {Vivado Implementation 2020} -parent_run synth_1

# Set implementation strategy
set_property strategy Performance_ExploreWithRemap [get_runs impl_1]

# Save project
save_project_as -force riscv_fpga 