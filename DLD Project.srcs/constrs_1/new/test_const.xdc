# Clock signal (100MHz)
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# Reset Button (Center Button - BTNC)
set_property PACKAGE_PIN U18 [get_ports rst]						
	set_property IOSTANDARD LVCMOS33 [get_ports rst]

# ----------------------------------------------------------------------------
# JA Pmod Header (Top Row)
# ----------------------------------------------------------------------------
# Pin 1 (JA1) - Shift Register Load/Latch
set_property PACKAGE_PIN J1 [get_ports sr_load]					
	set_property IOSTANDARD LVCMOS33 [get_ports sr_load]
	
# Pin 2 (JA2) - Shift Register Clock
set_property PACKAGE_PIN L2 [get_ports sr_clk]					
	set_property IOSTANDARD LVCMOS33 [get_ports sr_clk]

# Pin 3 (JA3) - Shift Register Data IN (From 74HC165)
set_property PACKAGE_PIN J2 [get_ports sr_data_in]					
	set_property IOSTANDARD LVCMOS33 [get_ports sr_data_in]
	
# Pin 4 (JA4) - UART TX (To Arduino RX)
set_property PACKAGE_PIN G2 [get_ports tx]					
	set_property IOSTANDARD LVCMOS33 [get_ports tx]