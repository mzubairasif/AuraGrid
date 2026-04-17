//`timescale 1ns / 1ps

//module main_debug (
//    input logic clk,
//    input logic btnC, btnU, btnD,
//    input logic [5:0] sw,
    
//    output logic [6:0] seg,
//    output logic [3:0] an,
//    output logic [15:0] led, 
//    output logic uart_tx_out
//);
//    // Grouped wires for brevity
//    logic p_pulse, d_pulse, turn_w, g_err;
//    logic [63:0] mask;
//    logic [6:0] w_t, b_t;
//    logic [5:0] w_s, b_s;

//    // 1. Edge Detectors
//    button_edge_det det_u (.clk(clk), .btn(btnU), .pulse(p_pulse));
//    button_edge_det det_d (.clk(clk), .btn(btnD), .pulse(d_pulse));

//    // 2. The Brain
//    game_logic game_engine (
//        .clk(clk), .reset(btnC), .ready(p_pulse | d_pulse), .coord(sw), .in_type(p_pulse),
//        .valid_squares(mask), .status_code(g_err), .current_turn(turn_w), .w_score(w_s), .b_score(b_s)
//    );

//    // 3. Timers & 7-Segment
//    chess_timers timers (.clk(clk), .rst(btnC), .current_turn(turn_w), .white_seconds(w_t), .black_seconds(b_t));
//    seven_seg_drive dspl (.clk(clk), .rst(btnC), .white_time(w_t), .black_time(b_t), .seg(seg), .an(an));
    
//    // 4. UART
//    uart_tx_driver uart (.clk(clk), .rst(btnC), .tx_start(p_pulse | d_pulse), .data_in(mask[47:0]), .tx_out(uart_tx_out));

//    // 5. LED Mapping
//    always_comb begin
//        led = 16'b0;
//        led[5:0] = w_s;       // White score on rightmost 6 LEDs
//        led[11:6] = b_s;      // Black score on next 6 LEDs
//        led[13:12] = sw[1:0]; // Just showing 2 bits of switches to verify life
//        led[14] = g_err;      // Error indicator
//        led[15] = turn_w;     // Turn indicator
//    end
//endmodule