`timescale 1ns / 1ps

module chess_timers(
    input logic clk,
    input logic rst,
    input logic current_turn, // 0 = White, 1 = Black
    output logic [6:0] white_seconds, // Max 99
    output logic [6:0] black_seconds  // Max 99
);

    // 100MHz / 100,000,000 = 1Hz
    logic [26:0] one_sec_counter;
    logic one_sec_tick;

    always_ff @(posedge clk) begin
        if (rst) begin
            one_sec_counter <= 0;
            one_sec_tick <= 0;
        end else if (one_sec_counter == 99_999_999) begin
            one_sec_counter <= 0;
            one_sec_tick <= 1;
        end else begin
            one_sec_counter <= one_sec_counter + 1;
            one_sec_tick <= 0;
        end
    end

    // Timer Registers
    always_ff @(posedge clk) begin
        if (rst) begin
            white_seconds <= 7'd99; // Starting with 99 seconds for the demo
            black_seconds <= 7'd99;
        end else if (one_sec_tick) begin
            if (current_turn == 1'b0 && white_seconds > 0)
                white_seconds <= white_seconds - 1;
            else if (current_turn == 1'b1 && black_seconds > 0)
                black_seconds <= black_seconds - 1;
        end
    end
endmodule