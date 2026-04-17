`timescale 1ns / 1ps

module main_vga (
    input logic clk,
    input logic btnC, btnU, btnD,
    input logic [5:0] sw,
    
    // Physical Debug Outputs
    output logic [6:0] seg,
    output logic [3:0] an,
    output logic [15:0] led, 
    output logic uart_tx_out,

    // VGA Outputs
    output logic hsync,
    output logic vsync,
    output logic [11:0] rgb
);
    // --- 1. INTERNAL WIRES ---
    logic p_pulse, d_pulse, turn_w, g_err;
    logic event_trig, event_type;
    logic [63:0] mask;
    logic [6:0] w_t, b_t;   
    logic [5:0] w_s, b_s;
    logic [3:0] board_bus [0:63]; // Carries board state to VGA

    // VGA specific wires
    logic w_video_on, w_p_tick;
    logic [9:0] w_x, w_y;
    logic [11:0] rgb_next;

    // --- 2. INPUT DEBOUNCING (Your hardware controls) ---
    button_edge_det det_u (.clk(clk), .btn(btnU), .pulse(p_pulse));
    button_edge_det det_d (.clk(clk), .btn(btnD), .pulse(d_pulse));
    
    assign event_trig = p_pulse | d_pulse;
    assign event_type = p_pulse; // 1 = Pickup, 0 = Putdown

    // --- 3. THE BRAIN (Game Logic) ---
    game_logic game_engine (
        .clk(clk), .reset(btnC), .ready(event_trig), .coord(sw), .in_type(event_type),
        .valid_squares(mask), .status_code(g_err), .current_turn(turn_w), 
        .w_score(w_s), .b_score(b_s), .board_out(board_bus) // <-- Board routed out
    );

    // --- 4. TIMERS & 7-SEGMENT ---
    chess_timers timers (.clk(clk), .rst(btnC), .current_turn(turn_w), .white_seconds(w_t), .black_seconds(b_t));
    seven_seg_drive dspl (.clk(clk), .rst(btnC), .white_time(w_t), .black_time(b_t), .seg(seg), .an(an));
    
    // --- 5. TIMER TRANSLATOR FOR VGA ---
    // Converts raw seconds into Min/Tens/Ones. Assumes Top = Black, Bottom = White.
    logic [6:0] w_sec_rem, b_sec_rem;
    logic [3:0] t_min, t_sec_t, t_sec_o;
    logic [3:0] b_min, b_sec_t, b_sec_o;
    
    always_comb begin
        // White (Bottom)
        b_min = w_t / 60;
        w_sec_rem = w_t % 60;
        b_sec_t = w_sec_rem / 10;
        b_sec_o = w_sec_rem % 10;
        
        // Black (Top)
        t_min = b_t / 60;
        b_sec_rem = b_t % 60;
        t_sec_t = b_sec_rem / 10;
        t_sec_o = b_sec_rem % 10;
    end

    // --- 6. VGA SUBSYSTEM ---
    vga_controller vc(
        .clk_100MHz(clk), .reset(btnC), .video_on(w_video_on), 
        .hsync(hsync), .vsync(vsync), .p_tick(w_p_tick), .x(w_x), .y(w_y)
    );

    pixel_gen pg(
        .video_on(w_video_on), .pixel_x(w_x), .pixel_y(w_y),
        .board_state(board_bus), .valid_squares(mask), .coord(sw), .in_type(event_type), // Highlight currently selected switch
        .top_min(t_min), .top_sec_tens(t_sec_t), .top_sec_ones(t_sec_o),
        .bot_min(b_min), .bot_sec_tens(b_sec_t), .bot_sec_ones(b_sec_o),
        .rgb(rgb_next)
    );

    // VGA Output Register
    always_ff @(posedge clk) begin
        if (w_p_tick) rgb <= rgb_next;
    end

    // --- 7. DEBUG OUTPUTS ---
    uart_tx_driver uart (.clk(clk), .rst(btnC), .tx_start(event_trig), .data_in(mask[47:0]), .tx_out(uart_tx_out));

    always_comb begin
        led = 16'b0;
        led[5:0]   = w_s;       // White score
        led[11:6]  = b_s;       // Black score
        led[13:12] = sw[1:0];   // Switch check
        led    = g_err;     // Error indicator
        led    = turn_w;    // Turn indicator
    end

endmodule