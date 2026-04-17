`timescale 1ns / 1ps

module clock_divider (
    input wire clk_in,   // 100 MHz Basys-3 clock (Pin W5)
    input wire rst,      // A button or switch for reset
    output reg clk_out   // Your new ~1.5 kHz clock
);

    // 100,000,000 Hz / 1,500 Hz = 66,666 ticks per full cycle.
    // We flip the clock state halfway through, so we count to 33,333.
    // 33,333 requires a 16-bit register.
    reg [15:0] counter = 0; 

    always @(posedge clk_in) begin
        if (rst) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            // 33332 because we include 0
            if (counter == 16'd33332) begin 
                clk_out <= ~clk_out;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule