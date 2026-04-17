`timescale 1ns / 1ps

module main (
    input logic clk,
    input logic rst,
    
    // Shift Register Pins
    output logic sr_load,
    output logic sr_clk,
    input logic sr_data_in,
    
    // Board Output (UART to Arduino LEDs)
    output logic uart_tx_out,

    // Onboard Visuals
    output logic [6:0] seg,
    output logic [3:0] an,
    output logic [15:0] led,

    // VGA Outputs (Matches Constraints)
    output logic hsync,
    output logic vsync,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b
);

    // --- 1. INTERNAL WIRES ---
    // IO Wires (Physical Board)
    logic [47:0] raw_sensors;
    logic [5:0] logical_coord;
    logic event_type;
    logic event_trigger;

    // Game Logic Wires
    logic [63:0] game_led_mask; 
    logic game_error;
    logic turn_wire;
    logic [6:0] w_time, b_time;
    logic [5:0] w_score, b_score;
    logic [3:0] board_bus [0:63]; // Carries board state to VGA

    // VGA specific wires
    logic w_video_on, w_p_tick;
    logic [9:0] w_x, w_y;
    logic [11:0] rgb_next;
    logic [11:0] rgb_reg;

    // Split 12-bit RGB register into 4-bit constraint ports
    assign vga_r = rgb_reg[11:8];
    assign vga_g = rgb_reg[7:4];
    assign vga_b = rgb_reg[3:0];

    // --- 2. INPUT & SCANNER (The Physical Board) ---
    shift_reg_scanner #(.TRANSISTOR_INVERT(1)) scanner (
        .clk(clk), .rst(rst), .sr_load(sr_load), .sr_clk(sr_clk), 
        .sr_data_in(sr_data_in), .raw_hall_sensors(raw_sensors)
    );

    board_io input_handler (
        .clk(clk), .rst(rst), .raw_hall_sensors(raw_sensors), 
        .coord(logical_coord), .in_type(event_type), .event_ready(event_trigger)
    );

    // --- 3. THE BRAIN (Game Logic) ---
    game_logic game_engine (
        .clk(clk), .reset(rst), .ready(event_trigger), .coord(logical_coord), .in_type(event_type),
        .valid_squares(game_led_mask), .status_code(game_error), .current_turn(turn_wire), 
        .w_score(w_score), .b_score(b_score), .board_out(board_bus)
    );

    // --- 4. TIMERS & 7-SEGMENT ---
    chess_timers timers (.clk(clk), .rst(rst), .current_turn(turn_wire), .white_seconds(w_time), .black_seconds(b_time));
    seven_seg_drive dspl (.clk(clk), .rst(rst), .white_time(w_time), .black_time(b_time), .seg(seg), .an(an));

    // --- 5. TIMER TRANSLATOR FOR VGA ---
    // Converts raw seconds into Min/Tens/Ones. Assumes Top = Black, Bottom = White.
    logic [6:0] w_sec_rem, b_sec_rem;
    logic [3:0] t_min, t_sec_t, t_sec_o;
    logic [3:0] b_min, b_sec_t, b_sec_o;
    
    always_comb begin
        // White (Bottom)
        b_min = w_time / 60;
        w_sec_rem = w_time % 60;
        b_sec_t = w_sec_rem / 10;
        b_sec_o = w_sec_rem % 10;
        
        // Black (Top)
        t_min = b_time / 60;
        b_sec_rem = b_time % 60;
        t_sec_t = b_sec_rem / 10;
        t_sec_o = b_sec_rem % 10;
    end

    // --- 6. VGA SUBSYSTEM ---
    vga_controller vc(
        .clk_100MHz(clk), .reset(rst), .video_on(w_video_on), 
        .hsync(hsync), .vsync(vsync), .p_tick(w_p_tick), .x(w_x), .y(w_y)
    );

    pixel_gen pg(
        .video_on(w_video_on), .pixel_x(w_x), .pixel_y(w_y),
        .board_state(board_bus), .valid_squares(game_led_mask), .coord(logical_coord), .in_type(event_type),
        .top_min(t_min), .top_sec_tens(t_sec_t), .top_sec_ones(t_sec_o),
        .bot_min(b_min), .bot_sec_tens(b_sec_t), .bot_sec_ones(b_sec_o),
        .rgb(rgb_next)
    );

    // VGA Output Register
    always_ff @(posedge clk) begin
        if (w_p_tick) rgb_reg <= rgb_next;
    end

    // --- 7. DEBUG & PHYSICAL OUTPUTS ---
    uart_tx_driver led_comms (.clk(clk), .rst(rst), .tx_start(event_trigger), .data_in(game_led_mask[47:0]), .tx_out(uart_tx_out));

    always_comb begin
        led = 16'b0;
        led[5:0]   = w_score;       // White score
        led[11:6]  = b_score;       // Black score
        led[13:12] = logical_coord[1:0]; // Look at 2 LSBs of physical board coord just to verify IO is alive
        led    = game_error;    // Error indicator
        led    = turn_wire;     // Turn indicator
    end

endmodule