`timescale 1ns / 1ps
// q: WTH is the logic keyword?
// a: its a systemverilog thing. it replaces the reg and wire keywords of verilog and avoids the
//    confusion bw them. think of it like the wire.

module game_logic(
// power cables
input logic clk, // wire this to W5 of the board

input logic reset, // HIGH this ONCE when the game starts to initialize the game state. us k baad as needed. 
                   // ideally, wire this to one of the onboard push buttons on the BASYS-3

input logic ready, // use this as enable pin. 1 to turn game_logic execution on. (e.g. you don't
                   // want it running you're receiving noise on the input. only turn on once debouncing
                   // waghera has been done.)

// actual, real inputs
input logic [5:0] coord, // masti square address
input logic in_type, // 1 = pickup, 0 = putdown


output logic [63:0] valid_squares, // for each array member, corresponding square 1 = valid and viceversa.
output logic status_code // 0 = OK, 1 = error
    );
    
    //--------INTERNAL MEMORY--------
    
    // GAME STATE: 64 member array, each member of 4 bits (the piece name)
    logic [3:0] board [0:63];
    
    // subject piece
    logic [3:0] piece_name;
    
    // pos of the subject piece
    logic [5:0] src_coord;
    
    // inner verification of whether a piece is lifted. will b helpful in case the input signal in_type
    // gives a bad input due to hall sensor malfunction
    logic piece_lifted;  // 0 = false (waiting for pickup), 1 = true (waiting for putdown)
    
    
    //--------CONTROL UNIT--------
    
    always_ff @(posedge clk or posedge reset)
    begin
    
        //----CASE 0: RESET/INIT
        if (reset)
        begin
        
            // wipe internal memory clean
            piece_name <= 4'b0000;
            src_coord <= 6'b000000;
            piece_lifted <= 1'b0;
        
            for (int i=0; i<64; i++) board[i] <= 4'b0000;
        
            
        
            // wipe outputs clean
            status_code <= 1'b0;
            valid_squares <= 64'b0;
        
        
        
            // place white pieces
            board[0] <= 4'b0100; // rook
            board[1] <= 4'b0010; // knight
            board[2] <= 4'b0011; // bishop
        
            board[3] <= 4'b0101; // queen
            board[4] <= 4'b0110; // king
        
            board[5] <= 4'b0011; // bishop
            board[6] <= 4'b0010; // knight
            board[7] <= 4'b0100; // rook
        
            for (int i = 8; i<=15; i++) board[i] <= 4'b0001; //pawns
            
            
            // place black pieces
            for (int i = 48; i<=55; i++) board[i] <= 4'b1001; //pawns
        
            board[56] <= 4'b1100; // rook
            board[57] <= 4'b1010; // knight
            board[58] <= 4'b1011; // bishop
        
            board[59] <= 4'b1101; // queen
            board[60] <= 4'b1110; // king
        
            board[61] <= 4'b1011; // bishop
            board[62] <= 4'b1010; // knight
            board[63] <= 4'b1100; // rook 
        end
    
    
        else if (ready)
        begin
        
            //----CASE 1: PICKUP
            if (in_type == 1'b1 && piece_lifted == 1'b0)
            begin
                 // ensure pickup signal isn't coming from an empty square (could be due to noise)
                if (board[coord] == 4'b0000)
                begin
                    status_code <= 1'b1;
                    valid_squares <= 64'b0;
                end
                
                else
                begin
                    piece_name <= board[coord];
                    src_coord <= coord;
                    piece_lifted <= 1'b1;
                    status_code <= 1'b0;
                    
                    // TODO: valid squares calculation to be done here. big task. will be done in stages.
                end
            
            end
            
            //----CASE 2: PUTDOWN
            else if (in_type == 1'b0 && piece_lifted == 1'b1)
            begin
                
                if (valid_squares[coord] == 1'b1)
                begin
                    
                    status_code <= 1'b0; // send OK
                    
                    // update game state
                    board[coord] <= piece_name;
                    board[src_coord] <= 4'b0000;
                    
                    // reset internal memory for the next move
                    piece_lifted <= 1'b0;
                    valid_squares <= 64'b0;
                    
                end
                
                else if (valid_squares[coord] == 1'b0)
                begin
                    status_code <= 1'b1; // send ERROR
                        
                end
                
            end
            
        end
    end
endmodule