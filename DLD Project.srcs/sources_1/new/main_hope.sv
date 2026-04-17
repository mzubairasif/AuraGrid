`timescale 1ns / 1ps

module main_hope ( // Changed to prevent conflict
    input logic clk, rst,
    // Board Inputs
    input logic sr_data_in,
    output logic sr_load, sr_clk,
    output logic uart_tx_out,
    // Onboard displays
    output logic [6:0] seg, output logic [3:0] an, output logic [15:0] led,
    // VGA Outputs
    output logic [3:0] vga_r, vga_g, vga_b,
    output logic hsync, vsync
);
    // Sensor & IO Wires
    logic [47:0] raw_sensors;
    logic [5:0] board_coord;
    logic event_type, event_ready;
    
    // The Shared Memory Bus (The Board)
    logic [3:0] live_board [0:63]; 
    
    // Game Logic Wires (You forgot to declare these!)
    logic [63:0] valid_mask;
    logic game_error, current_turn;
    logic [5:0] w_s, b_s;
    logic [6:0] w_time, b_time;

    // 1. SUCK IN THE DATA
    shift_reg_scanner #(.TRANSISTOR_INVERT(1)) scanner (
        .clk(clk), .rst(rst), .sr_load(sr_load), .sr_clk(sr_clk), 
        .sr_data_in(sr_data_in), .raw_hall_sensors(raw_sensors)
    );

    // 2. CLEAN THE NOISE
    board_io input_handler (
        .clk(clk), .rst(rst), .raw_hall_sensors(raw_sensors), 
        .coord(board_coord), .in_type(event_type), .event_ready(event_ready)
    );

    // 3. PROCESS THE CHESS LOGIC
    game_logic game_engine (
        .clk(clk), 
        .reset(rst),                  // Replaced btnC with actual rst pin
        .ready(event_ready),          // Replaced event_trig with event_ready
        .coord(board_coord),          // Replaced sw with board_coord
        .in_type(event_type),
        .valid_squares(valid_mask),   
        .status_code(game_error),     
        .current_turn(current_turn), 
        .w_score(w_s), 
        .b_score(b_s), 
        .board_out(live_board)            // MAKE SURE game_logic.sv output port is named 'board'
    );

    // 4. DRAW THE SCREEN
    vga_controller my_vga (
        .clk_100MHz(clk), .reset(rst), 
        .board_state(live_board), 
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b), .hsync(hsync), .vsync(vsync)
    );

    // 5. TIMERS, LEDS & UART (So your board isn't completely dark)
    chess_timers timers (.clk(clk), .rst(rst), .current_turn(current_turn), .white_seconds(w_time), .black_seconds(b_time));
    seven_seg_drive dspl (.clk(clk), .rst(rst), .white_time(w_time), .black_time(b_time), .seg(seg), .an(an));
    uart_tx_driver uart (.clk(clk), .rst(rst), .tx_start(event_ready), .data_in(valid_mask[47:0]), .tx_out(uart_tx_out));

    always_comb begin
        led = 16'b0;
        led[5:0] = w_s;       // White Score
        led[11:6] = b_s;      // Black Score
        led = game_error; // Error Light
        led = current_turn; // Turn Light
    end
endmodule