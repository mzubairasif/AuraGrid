`timescale 1ns / 1ps

module hardware_test_top (
    input wire clk,           
    input wire rst,           
    
    // Shift Register Pins
    output wire sr_load,      
    output wire sr_clk,       
    input wire sr_data_in,    
    
    // UART to Arduino
    output wire tx            
);

    wire [63:0] raw_sensors;
    
    // 1. Scan the hardware
    shift_reg_scanner scanner (
        .clk(clk),
        .rst(rst),
        .sr_load(sr_load),
        .sr_clk(sr_clk),
        .sr_data_in(sr_data_in),
        .raw_hall_sensors(raw_sensors)
    );

    // 2. Blast it straight to the Arduino
    // We invert raw_sensors because A3144 goes LOW (0) when a magnet is near.
    // light_up expects HIGH (1) to turn the LED blue.
    light_up led_driver (
        .clk(clk),
        .rst(rst),
        .list_of_possible_moves(~raw_sensors), 
        .error_flag(1'b0), // Force no errors
        .tx(tx)
    );

endmodule