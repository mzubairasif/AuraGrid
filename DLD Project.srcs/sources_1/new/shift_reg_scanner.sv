`timescale 1ns / 1ps

module shift_reg_scanner #(
    // SET TO 1 if your transistors invert the signal (e.g., standard NPN level shifter)
    // SET TO 0 if you are using a proper non-inverting level shifter IC
    parameter TRANSISTOR_INVERT = 1 
)(
    input logic clk, 
    input logic rst,
    output logic sr_load, 
    output logic sr_clk,
    input logic sr_data_in,
    output logic [47:0] raw_hall_sensors
);
    logic [7:0] bit_count;
    logic [47:0] temp_data;
    logic [4:0] clk_div; 
    
    // Physical logic states expected by 74HC165
    logic target_load;
    logic target_clk;

    // Apply transistor inversion if necessary
    assign sr_load = TRANSISTOR_INVERT ? ~target_load : target_load;
    assign sr_clk  = TRANSISTOR_INVERT ? ~target_clk : target_clk;

    always_ff @(posedge clk) begin
        if(rst) begin
            target_load <= 1; // 74HC165 Idle HIGH
            target_clk <= 0;  // 74HC165 Idle LOW
            bit_count <= 0; 
            clk_div <= 0;
            raw_hall_sensors <= 48'hFFFF_FFFF_FFFF;
        end else begin
            clk_div <= clk_div + 1;
            
            if (clk_div == 0) begin 
                if (bit_count == 0) begin
                    target_load <= 0; // Pulse LOW to latch physical data
                    bit_count <= 1;
                end else if (bit_count == 1) begin
                    target_load <= 1; // Return HIGH to allow shifting
                    bit_count <= 2;
                end else if (bit_count <= 97) begin // 48 bits * 2 states = 96 steps
                    target_clk <= ~target_clk; 
                    
                    // Suck in data on the RISING edge of the target clock
                    if (!target_clk) begin 
                        temp_data <= {temp_data[46:0], sr_data_in};
                    end
                    bit_count <= bit_count + 1;
                end else begin
                    raw_hall_sensors <= temp_data; // Dump to debounce module
                    bit_count <= 0; // Loop
                end
            end
        end
    end
endmodule