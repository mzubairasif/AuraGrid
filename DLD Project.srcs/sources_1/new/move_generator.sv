`timescale 1ns / 1ps

module move_generator(
    input logic [5:0] eval_coord,
    input logic [3:0] eval_piece,
    input logic current_turn,     // Added: 0 = White, 1 = Black
    input logic [3:0] board [0:63],
    output logic [63:0] computed_moves
);
    logic piece_color;
    assign piece_color = eval_piece[3]; 

    logic [63:0] pawn_moves;
    logic [63:0] bishop_moves;

    // Sub-module instances
    pawn_rules pawn_logic (.coord(eval_coord), .piece_color(piece_color), .board(board), .valid_moves(pawn_moves));
    bishop_rules bishop_logic (.coord(eval_coord), .piece_color(piece_color), .board(board), .valid_moves(bishop_moves));

    always_comb begin
        // BLOCK: If the piece color doesn't match the turn, NO moves are valid.
        if (eval_piece == 4'b0000 || piece_color != current_turn) begin
            computed_moves = 64'b0;
        end else begin
            case (eval_piece[2:0])
                3'b001:  computed_moves = pawn_moves;
                3'b011:  computed_moves = bishop_moves;
                default: computed_moves = 64'b0; 
            endcase
        end
    end
endmodule