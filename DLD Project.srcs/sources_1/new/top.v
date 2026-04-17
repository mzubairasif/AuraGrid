`timescale 1ns / 1ps

module top (
    input wire clk,       
    input wire rst,   
    
    // CONTROL PINS
    output reg sr_load,   
    output reg sr_clk,    
    
    // PARALLEL DATA BUS (6 Pins)
    input wire [5:0] sr_data_bus,   
    
    // UART Pin
    output wire tx,        
    
    // DEBUG: LEDs & 7-Segment
    output wire [0:7] board_leds,
    output reg [6:0] seg, 
    output reg [3:0] an   
);

    // --- 1. CLOCK DIVIDER (~6kHz) ---
    reg [13:0] scan_clk_div = 0; 
    wire scan_tick = (scan_clk_div == 0);
    always @(posedge clk) scan_clk_div <= scan_clk_div + 1;

    // --- 2. PARALLEL SHIFT REGISTER SCANNER ---
    reg [4:0] state = 0;
    reg [3:0] bit_idx = 0;       
    reg [7:0] row_data [0:5];    // 6x8 Matrix memory
    reg [47:0] stable_state = 0; // 48-bit state
    reg scan_done = 0;

    assign board_leds = stable_state[47:40]; // Show row 1 on green LEDs

    always @(posedge clk) begin
        if (rst) begin
            sr_load <= 0; 
            sr_clk <= 1;  
            state <= 0;
        end else if (scan_tick) begin
            case (state)
                0: begin sr_load <= 1; state <= 1; end                      
                1: begin sr_load <= 0; state <= 2; bit_idx <= 0; end      
                2: begin 
                    // READ ALL 6 ROWS SIMULTANEOUSLY
                    row_data[0] <= {row_data[0][6:0], ~sr_data_bus[0]};
                    row_data[1] <= {row_data[1][6:0], ~sr_data_bus[1]};
                    row_data[2] <= {row_data[2][6:0], ~sr_data_bus[2]};
                    row_data[3] <= {row_data[3][6:0], ~sr_data_bus[3]};
                    row_data[4] <= {row_data[4][6:0], ~sr_data_bus[4]};
                    row_data[5] <= {row_data[5][6:0], ~sr_data_bus[5]};
                    state <= 3; 
                end
                3: begin sr_clk <= 0; state <= 4; end                      
                4: begin 
                    sr_clk <= 1;                                           
                    bit_idx <= bit_idx + 1;
                    if (bit_idx == 8) state <= 5;                        
                    else state <= 2;                                       
                end
                5: begin
                    // Flatten the matrix into the 48-bit register
                    stable_state <= {row_data[0], row_data[1], row_data[2], 
                                     row_data[3], row_data[4], row_data[5]};                          
                    scan_done <= 1;                                        
                    state <= 6;
                end
                6: begin scan_done <= 0; state <= 0; end
            endcase
        end
    end

    // --- 3. UART TRANSMITTER (6-Byte Burst) ---
    reg [13:0] uart_timer = 0;
    reg [3:0] uart_bit = 0;
    reg [9:0] tx_shift = 10'b1111111111; 
    reg tx_busy = 0;
    reg [47:0] last_sent_state = ~0; 
    reg [2:0] tx_byte_idx = 0;       
    
    assign tx = tx_shift; 

    always @(posedge clk) begin
        if (rst) begin
            tx_busy <= 0;
            tx_shift <= 10'b1111111111;
        end else begin
            if (scan_done && !tx_busy && (stable_state != last_sent_state)) begin
                tx_shift <= {1'b1, stable_state[47:40], 1'b0}; 
                tx_busy <= 1;
                tx_byte_idx <= 0;
                uart_timer <= 0;
                uart_bit <= 0;
                last_sent_state <= stable_state;
            end
            
            if (tx_busy) begin
                if (uart_timer == 10415) begin
                    uart_timer <= 0;
                    tx_shift <= {1'b1, tx_shift[9:1]};  
                    if (uart_bit == 9) begin
                        if (tx_byte_idx == 5) begin // Stop after 6 bytes
                            tx_busy <= 0;
                        end else begin
                            tx_byte_idx <= tx_byte_idx + 1;
                            uart_bit <= 0;
                            case (tx_byte_idx + 1)
                                1: tx_shift <= {1'b1, stable_state[39:32], 1'b0};
                                2: tx_shift <= {1'b1, stable_state[31:24], 1'b0};
                                3: tx_shift <= {1'b1, stable_state[23:16], 1'b0};
                                4: tx_shift <= {1'b1, stable_state[15:8], 1'b0};
                                5: tx_shift <= {1'b1, stable_state[7:0], 1'b0};
                            endcase
                        end
                    end else begin
                        uart_bit <= uart_bit + 1;
                    end
                end else begin
                    uart_timer <= uart_timer + 1;
                end
            end
        end
    end

    // --- 4. 7-SEGMENT DISPLAY ---
    reg [5:0] active_sq;
    integer i;
    always @* begin
        active_sq = 0;
        for (i = 0; i < 48; i = i + 1) begin
            if (stable_state[i]) active_sq = i + 1; 
        end
    end

    wire [3:0] tens = active_sq / 10;
    wire [3:0] ones = active_sq % 10;

    reg [17:0] refresh_counter = 0;
    always @(posedge clk) refresh_counter <= refresh_counter + 1;
    wire digit_sel = refresh_counter; 

    reg [3:0] current_digit;
    always @* begin
        if (digit_sel == 0) begin
            an = 4'b1110; 
            current_digit = ones;
        end else begin
            an = 4'b1101; 
            current_digit = tens;
        end
    end

    always @* begin
        case (current_digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule