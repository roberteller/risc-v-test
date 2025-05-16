# Create work library
vlib work

# Compile design files
vlog -work work src/memory/dram_controller.sv
vlog -work work src/tb/dram_controller_tb.sv

# Start simulation
vsim -t 1ps -voptargs="+acc" work.dram_controller_tb

# Add waves
add wave -position insertpoint sim:/dram_controller_tb/clk
add wave -position insertpoint sim:/dram_controller_tb/rst_n

# Core interface
add wave -position insertpoint -group "Core Interface" sim:/dram_controller_tb/core_addr
add wave -position insertpoint -group "Core Interface" sim:/dram_controller_tb/core_wdata
add wave -position insertpoint -group "Core Interface" sim:/dram_controller_tb/core_we
add wave -position insertpoint -group "Core Interface" sim:/dram_controller_tb/core_be
add wave -position insertpoint -group "Core Interface" sim:/dram_controller_tb/core_rdata
add wave -position insertpoint -group "Core Interface" sim:/dram_controller_tb/core_req
add wave -position insertpoint -group "Core Interface" sim:/dram_controller_tb/core_ack

# SDRAM interface
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_addr
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_bank
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_dq_out
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_dq_in
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_cke
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_cs_n
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_ras_n
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_cas_n
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_we_n
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_dqm
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_dq
add wave -position insertpoint -group "SDRAM Interface" sim:/dram_controller_tb/sdram_dq_oe

# DRAM Controller internal signals
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/current_state
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/next_state
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/counter
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/refresh_counter
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/burst_counter
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/current_row
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/current_bank
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/current_col
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/read_buffer
add wave -position insertpoint -group "DRAM Controller" sim:/dram_controller_tb/dut/write_buffer

# SDRAM model internal signals
add wave -position insertpoint -group "SDRAM Model" sim:/dram_controller_tb/sdram/current_row
add wave -position insertpoint -group "SDRAM Model" sim:/dram_controller_tb/sdram/current_bank
add wave -position insertpoint -group "SDRAM Model" sim:/dram_controller_tb/sdram/current_col
add wave -position insertpoint -group "SDRAM Model" sim:/dram_controller_tb/sdram/dq_out
add wave -position insertpoint -group "SDRAM Model" sim:/dram_controller_tb/sdram/dq_oe

# Run simulation
run -all

# Save waveform
write wave wave.do

# Exit simulation
quit 