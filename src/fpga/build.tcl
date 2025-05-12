# Open project
open_project riscv_fpga.xpr

# Reset runs
reset_run synth_1
reset_run impl_1

# Run synthesis
launch_runs synth_1
wait_on_run synth_1

# Run implementation
launch_runs impl_1
wait_on_run impl_1

# Generate bitstream
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Export hardware
write_hw_platform -fixed -include_bit -force -file riscv_fpga.xsa

# Close project
close_project 