`timescale 1ns / 1ps

module game_logic(
    input logic clk,
    input logic reset,
    input logic ready, 
    input logic [5:0] coord,
    input logic in_type, 

    output logic [63:0] valid_squares,
    output logic status_code, 
    output logic current_turn, 
    output logic [5:0] w_score, // Added proper ports
    output logic [5:0] b_score,
    output logic [3:0] board_out [0:63] // <-- NEW PORT: The VGA Window

);

    logic [3:0] board [0:63];
    logic [3:0] piece_name;
    logic [5:0] src_coord;
    logic piece_lifted;
    
    // Starting total material value is 39
    logic [5:0] white_material = 6'd39;
    logic [5:0] black_material = 6'd39;
    
    assign w_score = white_material;
    assign b_score = black_material;

    // Piece Value Function
    function [3:0] get_val(input [3:0] p);
        case(p[2:0])
            3'b001: get_val = 4'd1; // Pawn
            3'b010: get_val = 4'd3; // Knight
            3'b011: get_val = 4'd3; // Bishop
            3'b100: get_val = 4'd5; // Rook
            3'b101: get_val = 4'd9; // Queen
            default: get_val = 4'd0;
        endcase
    endfunction

    // POWER-ON INITIALIZATION (The Fix)
    initial begin
        for (int i=0; i<64; i++) board[i] = 4'b0000;
        // White
        board[0] = 4'b0100; board[1] = 4'b0010; board[2] = 4'b0011; board[3] = 4'b0101;
        board[4] = 4'b0110; board[5] = 4'b0011; board[6] = 4'b0010; board[7] = 4'b0100;
        for (int i=8; i<=15; i++) board[i] = 4'b0001;
        // Black (6-Row Hack)
        for (int i=32; i<=39; i++) board[i] = 4'b1001;
        board[40] = 4'b1100; board[41] = 4'b1010; board[42] = 4'b1011; board[43] = 4'b1101;
        board[44] = 4'b1110; board[45] = 4'b1011; board[46] = 4'b1010; board[47] = 4'b1100;
        
        status_code = 0;
        current_turn = 0;
        piece_lifted = 0;
    end

    // --- MOVE GENERATOR ---
    logic [63:0] moves;
    move_generator engine (
        .eval_coord((in_type && !piece_lifted) ? coord : src_coord),
        .eval_piece((in_type && !piece_lifted) ? board[coord] : piece_name),
        .current_turn(current_turn),
        .board(board),
        .computed_moves(moves)
    );
    assign valid_squares = moves;

    always_ff @(posedge clk) begin
        if (reset) begin
            current_turn <= 1'b0;
            piece_lifted <= 1'b0;
            white_material <= 6'd39;
            black_material <= 6'd39;
            status_code <= 1'b0;
        end else if (ready) begin
            if (in_type == 1'b1 && !piece_lifted) begin
                if (board[coord] == 4'b0000 || board[coord][3] != current_turn) begin
                    status_code <= 1'b1; // Error if empty or wrong turn
                end else begin
                    piece_name <= board[coord];
                    src_coord <= coord;
                    piece_lifted <= 1'b1;
                    status_code <= 1'b0;
                end
            end else if (in_type == 1'b0 && piece_lifted) begin
                if (moves[coord]) begin
                    if (board[coord] != 4'b0000) begin
                        if (current_turn == 0) black_material <= black_material - get_val(board[coord]);
                        else white_material <= white_material - get_val(board[coord]);
                    end
                    board[coord] <= piece_name;
                    board[src_coord] <= 4'b0000;
                    piece_lifted <= 1'b0;
                    current_turn <= ~current_turn;
                    status_code <= 1'b0;
                end else begin
                    status_code <= 1'b1;
                end
            end
        end
    end
    assign board_out = board;
endmodule