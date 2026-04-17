# 100MHz Clock
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Center Button for Reset
set_property PACKAGE_PIN U18 [get_ports rst]						
	set_property IOSTANDARD LVCMOS33 [get_ports rst]

# JA1: Latch to Shift Register Pin 1
set_property PACKAGE_PIN J1 [get_ports sr_load]					
	set_property IOSTANDARD LVCMOS33 [get_ports sr_load]
	
# JA2: Clock to Shift Register Pin 2
set_property PACKAGE_PIN L2 [get_ports sr_clk]					
	set_property IOSTANDARD LVCMOS33 [get_ports sr_clk]
	
# JA3: Data In from Shift Register Pin 9
set_property PACKAGE_PIN J2 [get_ports sr_data]					
	set_property IOSTANDARD LVCMOS33 [get_ports sr_data]
	
# JA4: UART TX to Arduino RX (Pin 0)
set_property PACKAGE_PIN G2 [get_ports tx]					
	set_property IOSTANDARD LVCMOS33 [get_ports tx]

# LEDs
set_property PACKAGE_PIN U16 [get_ports {board_leds[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {board_leds[0]}]
set_property PACKAGE_PIN E19 [get_ports {board_leds[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {board_leds[1]}]
set_property PACKAGE_PIN U19 [get_ports {board_leds[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {board_leds[2]}]
set_property PACKAGE_PIN V19 [get_ports {board_leds[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {board_leds[3]}]
set_property PACKAGE_PIN W18 [get_ports {board_leds[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {board_leds[4]}]
set_property PACKAGE_PIN U15 [get_ports {board_leds[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {board_leds[5]}]
set_property PACKAGE_PIN U14 [get_ports {board_leds[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {board_leds[6]}]
set_property PACKAGE_PIN V14 [get_ports {board_leds[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {board_leds[7]}]