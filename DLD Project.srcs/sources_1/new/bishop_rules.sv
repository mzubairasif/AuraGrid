`timescale 1ns / 1ps

module bishop_rules(
    input logic [5:0] coord,
    input logic piece_color, // 0 = White, 1 = Black
    input logic [3:0] board [0:63],
    output logic [63:0] valid_moves
);
    logic [2:0] row, col;
    assign row = coord[5:3];
    assign col = coord[2:0];

    always_comb begin
        valid_moves = 64'b0;
        
        // Up-Right (+9)
        for (int i = 1; i < 8; i++) begin
            if (row + i > 7 || col + i > 7) break;
            if (board[coord + i*9] == 4'b0000) begin
                valid_moves[coord + i*9] = 1'b1;
            end else if (board[coord + i*9][3] != piece_color) begin
                valid_moves[coord + i*9] = 1'b1; // Enemy capture
                break;
            end else break; // Friendly block
        end
        
        // Down-Right (-7)
        for (int i = 1; i < 8; i++) begin
            if (row < i || col + i > 7) break; 
            if (board[coord - i*7] == 4'b0000) begin
                valid_moves[coord - i*7] = 1'b1;
            end else if (board[coord - i*7][3] != piece_color) begin
                valid_moves[coord - i*7] = 1'b1;
                break;
            end else break;
        end
        
        // Up-Left (+7)
        for (int i = 1; i < 8; i++) begin
            if (row + i > 7 || col < i) break;
            if (board[coord + i*7] == 4'b0000) begin
                valid_moves[coord + i*7] = 1'b1;
            end else if (board[coord + i*7][3] != piece_color) begin
                valid_moves[coord + i*7] = 1'b1;
                break;
            end else break;
        end
        
        // Down-Left (-9)
        for (int i = 1; i < 8; i++) begin
            if (row < i || col < i) break;
            if (board[coord - i*9] == 4'b0000) begin
                valid_moves[coord - i*9] = 1'b1;
            end else if (board[coord - i*9][3] != piece_color) begin
                valid_moves[coord - i*9] = 1'b1;
                break;
            end else break;
        end
    end
endmodule