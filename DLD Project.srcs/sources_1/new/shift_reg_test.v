`timescale 1ns / 1ps

module shift_register_tester (
    input wire clk_100MHz,  // Basys 3 system clock
    input wire reset,       // BTNC (Center button)
    input wire sr_data_in,  // From Shift Register (Q7/Serial Out)
    output reg sr_clk,      // To Shift Register Clock
    output reg sr_latch,    // To Shift Register Latch/Load (Active Low)
    output reg [7:0] leds   // Basys 3 LEDs to verify read
);

    // Clock divider: 100MHz down to ~100Hz tick
    // This kills any high-frequency breadboard ringing issues.
    reg [19:0] clk_div;
    wire tick = (clk_div == 0);

    always @(posedge clk_100MHz or posedge reset) begin
        if (reset) clk_div <= 0;
        else clk_div <= (clk_div >= 999_999) ? 0 : clk_div + 1;
    end

    reg [4:0] state;
    reg [7:0] shift_reg_internal;

    always @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            state <= 0;
            sr_clk <= 0;
            sr_latch <= 1; 
            leds <= 8'b0;
            shift_reg_internal <= 0;
        end else if (tick) begin
            case (state)
                // State 0: Pull Latch LOW to load parallel data into the register
                0: begin
                    sr_latch <= 0; 
                    sr_clk <= 0;
                    state <= 1;
                end
                // State 1: Pull Latch HIGH to enable shifting
                1: begin
                    sr_latch <= 1; 
                    state <= 2;
                end
                // States 2-17: Shift in 8 bits. 
                // Rising edge shifts the register, we sample right after.
                2, 4, 6, 8, 10, 12, 14, 16: begin
                    sr_clk <= 1; 
                    shift_reg_internal <= {shift_reg_internal[6:0], sr_data_in};
                    state <= state + 1;
                end
                3, 5, 7, 9, 11, 13, 15, 17: begin
                    sr_clk <= 0; 
                    state <= state + 1;
                end
                // State 18: Dump to Basys 3 LEDs and restart loop
                18: begin
                    leds <= shift_reg_internal;
                    state <= 0;
                end
                default: state <= 0;
            endcase
        end
    end
endmodule