# Target clock for the ML-KEM-512 top-level interface.
# 100 MHz is the baseline timing target; update this value before implementation
# if the selected FPGA target requires a different clock frequency.
create_clock -name clk -period 10.000 [get_ports clk]

# Reset is asynchronous inside the RTL and is not a generated clock.
set_false_path -from [get_ports rst_n]

# Input and output timing are intentionally left unconstrained until the
# external transport interface is defined. Add input_delay/output_delay here
# when the ML-KEM core is attached to a board-level or AXI bridge.
