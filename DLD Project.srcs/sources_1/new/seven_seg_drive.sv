`timescale 1ns / 1ps

module seven_seg_drive(
    input logic clk,
    input logic rst,
    input logic [6:0] white_time,
    input logic [6:0] black_time,
    output logic [6:0] seg,
    output logic [3:0] an
);

    // Refresh counter (~400Hz refresh rate)
    logic [17:0] refresh_counter;
    always_ff @(posedge clk) begin
        if (rst) refresh_counter <= 0;
        else refresh_counter <= refresh_counter + 1;
    end

    logic [1:0] active_digit;
    assign active_digit = refresh_counter[17:16];

    logic [3:0] current_val;
    
    // Split binary seconds into BCD (Tens and Ones)
    // Note: This is a "quick and dirty" hardware way for small numbers
    always_comb begin
        case(active_digit)
            2'b00: begin // White Ones
                an = 4'b1110;
                current_val = white_time % 10;
            end
            2'b01: begin // White Tens
                an = 4'b1101;
                current_val = white_time / 10;
            end
            2'b10: begin // Black Ones
                an = 4'b1011;
                current_val = black_time % 10;
            end
            2'b11: begin // Black Tens
                an = 4'b0111;
                current_val = black_time / 10;
            end
            default: begin
                an = 4'b1111;
                current_val = 4'h0;
            end
        endcase
    end

    // Segment Decoder (0-9)
    always_comb begin
        case(current_val)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            default: seg = 7'b1111111;
        endcase
    end
endmodule