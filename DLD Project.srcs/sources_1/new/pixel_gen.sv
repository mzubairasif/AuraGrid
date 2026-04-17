`timescale 1ns / 1ps

module pixel_gen(
    input wire video_on,
    input wire [9:0] pixel_x,
    input wire [9:0] pixel_y,
    input logic [3:0] board_state [0:63],
    input logic [63:0] valid_squares,
    input wire [5:0]  coord,      // square index (0-63) of selected piece
    input wire        in_type,    // 1 = highlight selected square
    
    // Timer Inputs from chess_timers
    input wire [3:0] top_min, top_sec_tens, top_sec_ones,
    input wire [3:0] bot_min, bot_sec_tens, bot_sec_ones,
    
    output reg [11:0] rgb
);

    // --- Configuration Parameters ---
    localparam BOARD_SIZE  = 480;
    localparam SQUARE_SIZE = 60;
    localparam X_START     = 80;
    localparam Y_START     = 0;

    localparam ART_SCALE   = 4; 
    localparam ART_SIZE    = 32;
    localparam OFFSET      = (SQUARE_SIZE - ART_SIZE) / 2;

    // --- Colors ---
    localparam RGB_WHITE_SQ    = 12'hA54;
    localparam RGB_BLACK_SQ    = 12'hDBA;
    localparam RGB_WHITE_PIECE = 12'hFFF;
    localparam RGB_BLACK_PIECE = 12'h222;
    localparam RGB_MARGIN      = 12'h111;
    localparam RGB_HIGHLIGHT   = 12'hF70; 
    localparam RGB_TIMER_TEXT  = 12'h0F0; // Green for timers

    // --- Piece Type Definitions ---
    localparam PIECE_NONE   = 3'b000;
    localparam PIECE_PAWN   = 3'b001;
    localparam PIECE_KNIGHT = 3'b010;
    localparam PIECE_BISHOP = 3'b011;
    localparam PIECE_ROOK   = 3'b100;
    localparam PIECE_QUEEN  = 3'b101;
    localparam PIECE_KING   = 3'b110;

    // --- Artwork Bitmaps (8x8) ---
    wire [0:7] art [0:6][0:7];
    assign art[1][0]=8'b00011000; assign art[1][1]=8'b00011000; assign art[1][2]=8'b00011000; assign art[1][3]=8'b00011000;
    assign art[1][4]=8'b00111100; assign art[1][5]=8'b01111110; assign art[1][6]=8'b01111110; assign art[1][7]=8'b00000000;

    assign art[2][0]=8'b00011000; assign art[2][1]=8'b01111100; assign art[2][2]=8'b11111110; assign art[2][3]=8'b11101111;
    assign art[2][4]=8'b00000111; assign art[2][5]=8'b00011111; assign art[2][6]=8'b00111111; assign art[2][7]=8'b01111110;

    assign art[3][0]=8'b00011000; assign art[3][1]=8'b00111100; assign art[3][2]=8'b00111100; assign art[3][3]=8'b00011000;
    assign art[3][4]=8'b00011000; assign art[3][5]=8'b00111100; assign art[3][6]=8'b11100111; assign art[3][7]=8'b00000000;

    assign art[4][0]=8'b01011010; assign art[4][1]=8'b01111110; assign art[4][2]=8'b00111100; assign art[4][3]=8'b00011000;
    assign art[4][4]=8'b00011000; assign art[4][5]=8'b00111100; assign art[4][6]=8'b01111110; assign art[4][7]=8'b00000000;

    assign art[5][0]=8'b01010101; assign art[5][1]=8'b01010101; assign art[5][2]=8'b01010101; assign art[5][3]=8'b01111111;
    assign art[5][4]=8'b01111111; assign art[5][5]=8'b01111111; assign art[5][6]=8'b00000000; assign art[5][7]=8'b00000000;

    assign art[6][0]=8'b00011000; assign art[6][1]=8'b01111110; assign art[6][2]=8'b00011000; assign art[6][3]=8'b00011000;
    assign art[6][4]=8'b00111100; assign art[6][5]=8'b01111110; assign art[6][6]=8'b01111110; assign art[6][7]=8'b00111100;

    // --- Board Coordinate Logic ---
    wire in_board = (pixel_x >= X_START && pixel_x < X_START + BOARD_SIZE) &&
                    (pixel_y >= Y_START && pixel_y < Y_START + BOARD_SIZE);

    wire [2:0] grid_x = (pixel_x - X_START) / SQUARE_SIZE;
    //wire [2:0] grid_y = (pixel_y - Y_START) / SQUARE_SIZE;
    wire [2:0] grid_y = 3'd7 - ((pixel_y - Y_START) / SQUARE_SIZE);
    wire [5:0] square_idx = ((grid_y) * 8) + grid_x;

    //wire [3:0] piece_data = board_state[(square_idx * 4) +: 4];
    wire [3:0] piece_data = board_state[square_idx];
    wire [2:0] p_type  = piece_data[2:0];
    wire       p_color = piece_data[3];

    wire is_selected_square = in_type && (square_idx == coord);
    wire is_valid_square    = in_type && valid_squares[square_idx];;

    // --- Artwork Scaling Logic ---
    wire [5:0] rel_x = (pixel_x - X_START) % SQUARE_SIZE;
    wire [5:0] rel_y = (pixel_y - Y_START) % SQUARE_SIZE;

    wire in_art_area = (rel_x >= OFFSET && rel_x < OFFSET + ART_SIZE) &&
                       (rel_y >= OFFSET && rel_y < OFFSET + ART_SIZE);

    wire [2:0] art_x = (rel_x - OFFSET) / ART_SCALE;
    wire [2:0] art_y = (rel_y - OFFSET) / ART_SCALE;

    reg art_bit;
    always @(*) begin
        if (p_type == PIECE_NONE) art_bit = 0;
        else                      art_bit = art[p_type][art_y][art_x];
    end

    // --- Corrected Timer Display Logic ---
    localparam TIMER_X_START = 580;
    localparam TOP_Y_START   = 20;
    localparam BOT_Y_START   = 420;
    localparam DIGIT_W       = 15;
    localparam DIGIT_H       = 25;

    reg [3:0] current_digit;
    reg timer_hit;
    reg [9:0] rel_timer_y; // To track Y relative to the active timer
    reg [9:0] rel_timer_x; // To track X relative to the start of a digit

    always @(*) begin
        timer_hit = 0;
        current_digit = 0;
        rel_timer_y = 0;
        rel_timer_x = 0;
        
        // Top Timer Logic
        if (pixel_y >= TOP_Y_START && pixel_y < TOP_Y_START + DIGIT_H) begin
            rel_timer_y = pixel_y - TOP_Y_START;
            if (pixel_x >= TIMER_X_START && pixel_x < TIMER_X_START + DIGIT_W) begin
                timer_hit = 1; current_digit = top_min; rel_timer_x = pixel_x - TIMER_X_START;
            end else if (pixel_x >= TIMER_X_START + 20 && pixel_x < TIMER_X_START + 20 + DIGIT_W) begin
                timer_hit = 1; current_digit = top_sec_tens; rel_timer_x = pixel_x - (TIMER_X_START + 20);
            end else if (pixel_x >= TIMER_X_START + 40 && pixel_x < TIMER_X_START + 40 + DIGIT_W) begin
                timer_hit = 1; current_digit = top_sec_ones; rel_timer_x = pixel_x - (TIMER_X_START + 40);
            end
        // Bottom Timer Logic
        end else if (pixel_y >= BOT_Y_START && pixel_y < BOT_Y_START + DIGIT_H) begin
            rel_timer_y = pixel_y - BOT_Y_START;
            if (pixel_x >= TIMER_X_START && pixel_x < TIMER_X_START + DIGIT_W) begin
                timer_hit = 1; current_digit = bot_min; rel_timer_x = pixel_x - TIMER_X_START;
            end else if (pixel_x >= TIMER_X_START + 20 && pixel_x < TIMER_X_START + 20 + DIGIT_W) begin
                timer_hit = 1; current_digit = bot_sec_tens; rel_timer_x = pixel_x - (TIMER_X_START + 20);
            end else if (pixel_x >= TIMER_X_START + 40 && pixel_x < TIMER_X_START + 40 + DIGIT_W) begin
                timer_hit = 1; current_digit = bot_sec_ones; rel_timer_x = pixel_x - (TIMER_X_START + 40);
            end
        end
    end

    // Bitmap lookup for digits
    reg [14:0] digit_bitmap;
    always @(*) begin
        case(current_digit)
            0: digit_bitmap = 15'b111_101_101_101_111;
            1: digit_bitmap = 15'b010_010_010_010_010;
            2: digit_bitmap = 15'b111_001_111_100_111;
            3: digit_bitmap = 15'b111_001_111_001_111;
            4: digit_bitmap = 15'b101_101_111_001_001;
            5: digit_bitmap = 15'b111_100_111_001_111;
            6: digit_bitmap = 15'b111_100_111_101_111;
            7: digit_bitmap = 15'b111_001_001_001_001;
            8: digit_bitmap = 15'b111_101_111_101_111;
            9: digit_bitmap = 15'b111_101_111_001_111;
            default: digit_bitmap = 15'b000_000_000_000_000;
        endcase
    end

    // Corrected Scaling: map 15x25 pixels to 3x5 bitmap
    // X scale: 15/3 = 5 pixels per bit
    // Y scale: 25/5 = 5 pixels per bit
    wire [2:0] bitmap_x = rel_timer_x / 5;
    wire [2:0] bitmap_y = rel_timer_y / 5;
    wire draw_digit_pixel = timer_hit && digit_bitmap[14 - (bitmap_y * 3 + bitmap_x)];

    // --- Final Color Multiplexer ---
    always @(*) begin
        if (!video_on) begin
            rgb = 12'h000;
        end
        else if (timer_hit && draw_digit_pixel) begin
            rgb = RGB_TIMER_TEXT; 
        end
        else if (in_board) begin
            if (in_art_area && art_bit) begin
                rgb = (p_color == 1'b0) ? RGB_WHITE_PIECE : RGB_BLACK_PIECE;
            end 
            else if (is_selected_square) begin
                rgb = 12'h1DD; // Pure Blue
            end
            else if (is_valid_square) begin
                rgb = RGB_HIGHLIGHT; // Orange/Gold
            end
            else begin
                rgb = (grid_x[0] ^ grid_y[0]) ? RGB_WHITE_SQ : RGB_BLACK_SQ;
            end
        end
        else begin
            rgb = RGB_MARGIN;
        end
    end
   endmodule