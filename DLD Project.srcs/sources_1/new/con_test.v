`timescale 1ns / 1ps

module con_test (
    input clk,  // 100MHz
    input rst,  // Hardware reset button
    output tx   // Wire to Arduino RX (Pin 0)
);

    // 300ms at 100MHz = 30,000,000 clock cycles
    parameter TIMER_MAX = 30_000_000;
    reg [24:0] timer = 0;
    reg [5:0] current_sq = 0;

    reg [7:0] tx_data;
    reg tx_start = 0;
    wire tx_ready;

    uart_tx my_uart (
        .clk(clk),
        .data(tx_data),
        .send_en(tx_start),
        .tx(tx),
        .ready(tx_ready)
    );

    localparam S_IDLE = 0, S_SEND_ADDR = 1, S_WAIT_ADDR = 2, S_SEND_CMD = 3, S_WAIT_CMD = 4;
    reg [2:0] state = S_IDLE;

    always @(posedge clk) begin
        if (rst) begin
            timer <= 0;
            current_sq <= 0;
            state <= S_IDLE;
            tx_start <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    // Wait for 300ms tick
                    if (timer == TIMER_MAX - 1) begin
                        timer <= 0;
                        if (tx_ready) begin
                            tx_data <= {2'b00, current_sq}; // Byte 1: Square Index (0-63)
                            tx_start <= 1;
                            state <= S_SEND_ADDR;
                        end
                    end else begin
                        timer <= timer + 1;
                    end
                end
                S_SEND_ADDR: begin
                    tx_start <= 0;
                    if (!tx_ready) state <= S_WAIT_ADDR;
                end
                S_WAIT_ADDR: begin
                    if (tx_ready) begin
                        tx_data <= 8'd1; // Byte 2: Command (1 = Turn On)
                        tx_start <= 1;
                        state <= S_SEND_CMD;
                    end
                end
                S_SEND_CMD: begin
                    tx_start <= 0;
                    if (!tx_ready) state <= S_WAIT_CMD;
                end
                S_WAIT_CMD: begin
                    if (tx_ready) begin
                        current_sq <= current_sq + 1; // Auto-rolls over after 63
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end
endmodule

// Don't forget the UART transmitter
module uart_tx (
    input clk,
    input [7:0] data,
    input send_en,
    output reg tx = 1,
    output reg ready = 1
);
    parameter BIT_PERIOD = 10416; // 9600 Baud
    reg [13:0] clk_cnt = 0;
    reg [3:0] bit_idx = 0;
    reg [7:0] shift_reg = 0;
    reg [1:0] state = 0;

    always @(posedge clk) begin
        case (state)
            0: begin 
                ready <= 1;
                tx <= 1;
                if (send_en) begin
                    shift_reg <= data;
                    state <= 1;
                    ready <= 0;
                    clk_cnt <= 0;
                end
            end
            1: begin // START BIT
                tx <= 0;
                if (clk_cnt == BIT_PERIOD - 1) begin
                    clk_cnt <= 0;
                    state <= 2;
                    bit_idx <= 0;
                end else clk_cnt <= clk_cnt + 1;
            end
            2: begin // DATA BITS
                tx <= shift_reg[bit_idx];
                if (clk_cnt == BIT_PERIOD - 1) begin
                    clk_cnt <= 0;
                    if (bit_idx == 7) state <= 3;
                    else bit_idx <= bit_idx + 1;
                end else clk_cnt <= clk_cnt + 1;
            end
            3: begin // STOP BIT
                tx <= 1;
                if (clk_cnt == BIT_PERIOD - 1) state <= 0;
                else clk_cnt <= clk_cnt + 1;
            end
        endcase
    end
endmodule