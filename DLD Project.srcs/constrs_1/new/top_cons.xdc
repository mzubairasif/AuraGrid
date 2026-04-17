# Clock
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Shift Register Control & Data (Pmod JA)
set_property PACKAGE_PIN J1 [get_ports sr_latch]
set_property IOSTANDARD LVCMOS33 [get_ports sr_latch]
set_property PACKAGE_PIN L2 [get_ports sr_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sr_clk]
set_property PACKAGE_PIN J2 [get_ports sr_data]
set_property IOSTANDARD LVCMOS33 [get_ports sr_data]

# UART TX
set_property PACKAGE_PIN G2 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

## Onboard LEDs (using round brackets for bus indices)
#set_property PACKAGE_PIN U16 [get_ports {leds[0]}] # * targets the 1st LED [r]ghtmost)
#set_property IOSTANDARD LVCMOS33 [get_ports {leds[0]}]
#set_property PACKAGE_PIN E19 [get_ports {leds[1]}] # * targets the 2nd LED
#set_property IOSTANDARD LVCMOS33 [get_ports {leds[1]}]
#set_property PACKAGE_PIN U19 [get_ports {leds[2]}] # * targets the 3rd LED
#set_property IOSTANDARD LVCMOS33 [get_ports {leds[2]}]
#set_property PACKAGE_PIN V19 [get_ports {leds[3]}] # * targets the 4th LED
#set_property IOSTANDARD LVCMOS33 [get_ports {leds[3]}]
#set_property PACKAGE_PIN W18 [get_ports {leds[4]}] # * targets the 5th LED
#set_property IOSTANDARD LVCMOS33 [get_ports {leds[4]}]
#set_property PACKAGE_PIN U15 [get_ports {leds[5]}] # * targets the 6th LED
#set_property IOSTANDARD LVCMOS33 [get_ports {leds[5]}]
#set_property PACKAGE_PIN U14 [get_ports {leds[6]}] # * targets the 7th LED
#set_property IOSTANDARD LVCMOS33 [get_ports {leds[6]}]
#set_property PACKAGE_PIN V14 [get_ports {leds[7]}] # * targets the 8th LED
#set_property IOSTANDARD LVCMOS33 [get_ports {leds[7]}]