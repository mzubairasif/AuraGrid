`timescale 1ns / 1ps

module uart_tx_driver (
    input logic clk,
    input logic rst,
    input logic tx_start,
    input logic [47:0] data_in,
    output logic tx_out
);

    // 100MHz / 9600 baud = 10416
    parameter BAUD_LIMIT = 14'd10415; 
    
    logic [13:0] baud_timer;
    logic [2:0] bit_idx;
    logic [2:0] byte_idx;
    logic [9:0] tx_shift_reg; // 1 Start + 8 Data + 1 Stop
    logic transmitting;

    // Buffer to hold the 6 bytes we are sending
    logic [7:0] bytes_to_send [0:5];

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_out <= 1'b1; // UART Idle HIGH
            transmitting <= 0;
            baud_timer <= 0;
            byte_idx <= 0;
        end else begin
            if (tx_start && !transmitting) begin
                // Latch data and begin transmission
                bytes_to_send[0] <= data_in[7:0];
                bytes_to_send[1] <= data_in[15:8];
                bytes_to_send[2] <= data_in[23:16];
                bytes_to_send[3] <= data_in[31:24];
                bytes_to_send[4] <= data_in[39:32];
                bytes_to_send[5] <= data_in[47:40];
                
                transmitting <= 1'b1;
                byte_idx <= 0;
                bit_idx <= 0;
                baud_timer <= 0;
                // Frame: {Stop(1), Data, Start(0)}
                tx_shift_reg <= {1'b1, data_in[7:0], 1'b0}; 
            end 
            else if (transmitting) begin
                if (baud_timer == BAUD_LIMIT) begin
                    baud_timer <= 0;
                    tx_out <= tx_shift_reg;
                    tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
                    
                    if (bit_idx == 9) begin
                        bit_idx <= 0;
                        if (byte_idx == 5) begin
                            transmitting <= 0; // Done sending all 6 bytes
                        end else begin
                            byte_idx <= byte_idx + 1;
                            // Load next byte frame
                            tx_shift_reg <= {1'b1, bytes_to_send[byte_idx + 1], 1'b0};
                        end
                    end else begin
                        bit_idx <= bit_idx + 1;
                    end
                end else begin
                    baud_timer <= baud_timer + 1;
                end
            end
        end
    end
endmodule