`timescale 1ns / 1ps

module pawn_rules(
    input logic [5:0] coord,
    input logic piece_color, 
    input logic [3:0] board [0:63],
    output logic [63:0] valid_moves
);
    logic [2:0] row, col;
    assign row = coord[5:3];
    assign col = coord[2:0];

    always_comb begin
        valid_moves = 64'b0;
        
        if (piece_color == 1'b0) begin 
            // WHITE PAWN
            if (row < 7 && board[coord + 8] == 4'b0000) begin
                valid_moves[coord + 8] = 1'b1;
                if (row == 1 && board[coord + 16] == 4'b0000)
                    valid_moves[coord + 16] = 1'b1;
            end
            // Captures: Check if target is not empty AND is Black (bit 3 is 1)
            if (row < 7 && col < 7 && board[coord + 9] != 4'b0000 && board[coord + 9][3] == 1'b1)
                valid_moves[coord + 9] = 1'b1;
            if (row < 7 && col > 0 && board[coord + 7] != 4'b0000 && board[coord + 7][3] == 1'b1)
                valid_moves[coord + 7] = 1'b1;
                
        end else begin
            // BLACK PAWN
            if (row > 0 && board[coord - 8] == 4'b0000) begin
                valid_moves[coord - 8] = 1'b1;
                if (row == 4 && board[coord - 16] == 4'b0000) 
                    valid_moves[coord - 16] = 1'b1;
            end
            // Captures: Check if target is not empty AND is White (bit 3 is 0)
            if (row > 0 && col < 7 && board[coord - 7] != 4'b0000 && board[coord - 7][3] == 1'b0)
                valid_moves[coord - 7] = 1'b1;
            if (row > 0 && col > 0 && board[coord - 9] != 4'b0000 && board[coord - 9][3] == 1'b0)
                valid_moves[coord - 9] = 1'b1;
        end
    end
endmodule