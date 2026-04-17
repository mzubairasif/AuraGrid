## Clock signal (100MHz)
set_property PACKAGE_PIN W5 [get_ports clk]							
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
 
## Center Button (Hardware Reset)
set_property PACKAGE_PIN U18 [get_ports rst]						
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## Pmod Header JA - Pin 1 (UART TX to Arduino RX)
set_property PACKAGE_PIN J1 [get_ports tx]					
set_property IOSTANDARD LVCMOS33 [get_ports tx]