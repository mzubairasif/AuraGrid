`timescale 1ns / 1ps

module fpga_bd_test (
    input wire clk,
    input wire sr_data,
    output reg sr_latch,
    output reg sr_clk,
    output reg tx
//    output wire [7:0] leds // * [7:0] means an 8-bit bus, indices 7 down to 0, representing the 8 squares
);

    // --- Clock Divider (~1.5kHz Scan Rate) ---
    reg [15:0] scan_div = 0; // * [15:0] means a 16-bit register, indices 15 down to 0, holding values up to 65535
    wire scan_tick = (scan_div == 16'd65535);
    
    always @(posedge clk) begin
        scan_div <= scan_div + 1;
    end

    // --- Shift Register FSM (NPN Inverted) ---
    reg [4:0] scan_state = 0; // * [4:0] means a 5-bit register, indices 4 down to 0, holding values up to 31
    reg [7:0] board_state = 8'hFF; // * [7:0] means an 8-bit register, initialized to all 1s
    reg [7:0] tx_buffer = 0; // * [7:0] means an 8-bit register to freeze data for UART
    reg trigger_tx = 0;
    
    always @(posedge clk) begin
        if (scan_tick) begin
            case (scan_state)
                5'd0: begin
                    sr_latch <= 1'b1; // NPN inverted: drives physical latch LOW
                    sr_clk <= 1'b1;   // NPN inverted: drives physical clk LOW
                    scan_state <= scan_state + 1;
                end
                5'd1: begin
                    sr_latch <= 1'b0; // NPN inverted: physical latch HIGH (locked)
                    scan_state <= scan_state + 1;
                end
                default: begin
                    if (scan_state < 5'd18) begin
                        if (scan_state[0] == 1'b0) begin // * means the lowest single bit at index 0
                            sr_clk <= 1'b0; // NPN inverted: physical clk HIGH (Rising Edge)
                            board_state <= {board_state[6:0], sr_data}; // * [6:0] means taking 7 bits from index 6 down to 0 and appending 1 bit
                        end else begin
                            sr_clk <= 1'b1; // NPN inverted: physical clk LOW
                        end
                        scan_state <= scan_state + 1;
                    end else begin
                        scan_state <= 0;
                        if (board_state != tx_buffer) begin
                            tx_buffer <= board_state;
                            trigger_tx <= 1'b1;
                        end
                    end
                end
            endcase
        end else begin
            trigger_tx <= 1'b0;
        end
    end

    // Invert active-LOW sensors so 1 = magnet present. Drive onboard LEDs.
//    assign leds = ~board_state;

    // --- UART Transmitter (9600 Baud at 100MHz) ---
    reg [13:0] uart_div = 0; // * [13:0] means a 14-bit register, indices 13 down to 0
    wire baud_tick = (uart_div == 14'd10416);
    
    reg [3:0] tx_state = 0; // * [3:0] means a 4-bit register, indices 3 down to 0
    reg byte_count = 0; 
    reg [7:0] current_byte = 0; // * [7:0] means an 8-bit register
    reg [15:0] full_payload = 0; // * [15:0] means a 16-bit register, holding 2 bytes (Sync + Data)
    
    always @(posedge clk) begin
        if (baud_tick) uart_div <= 0;
        else uart_div <= uart_div + 1;
        
        if (trigger_tx && tx_state == 0) begin
            full_payload <= {8'hAA, ~tx_buffer}; // Send inverted state (1 = active)
            tx_state <= 1;
            byte_count <= 0;
            tx <= 1'b1;
        end else if (baud_tick && tx_state != 0) begin
            case (tx_state)
                1: begin // Start bit
                    tx <= 1'b0;
                    current_byte <= byte_count ? full_payload[7:0] : full_payload[15:8]; // * [7:0] means the lower 8 bits, [15:8] means the upper 8 bits
                    tx_state <= 2;
                end
                10: begin // Stop bit
                    tx <= 1'b1;
                    if (byte_count == 1) tx_state <= 0;
                    else begin
                        byte_count <= 1;
                        tx_state <= 1;
                    end
                end
                default: begin // Data bits
                    tx <= current_byte[0]; // * means the lowest single bit at index 0
                    current_byte <= {1'b0, current_byte[7:1]}; // * [7:1] means 7 bits from index 7 down to 1
                    tx_state <= tx_state + 1;
                end
            endcase
        end
    end
endmodule