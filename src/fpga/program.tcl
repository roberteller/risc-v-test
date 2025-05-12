# Open project
open_project riscv_fpga.xpr

# Open hardware manager
open_hw

# Connect to target
connect_hw_server
open_hw_target

# Program device
current_hw_device [get_hw_devices xc7a35t_0]
set_property PROGRAM.FILE {riscv_fpga.runs/impl_1/riscv_fpga_top.bit} [get_hw_devices xc7a35t_0]
program_hw_devices [get_hw_devices xc7a35t_0]

# Close hardware manager
close_hw

# Close project
close_project 