// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 10:37:10 AM
// Design Name: 
// Module Name: board_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module board_test (
    input wire clk,
    input wire rst,        // Center Button (btnC)
    input wire btnU,       // Up Button (Simulates Pickup)
    input wire btnD,       // Down Button (Simulates Putdown)
    input wire [5:0] sw,   // First 6 Switches (Binary Coordinate 0-63)
    
    output wire [15:0] led // The 16 physical LEDs above the switches
);

    // Internal wires connecting to game_logic
    wire [63:0] mask_from_game;
    wire error_from_game;

    // Wake the game up if either button is pressed
    wire event_ready = btnU | btnD; 
    
    // 1 = Lifted (btnU), 0 = Placed (btnD)
    wire event_action = btnU;       

    // Instantiating your friend's exact game logic module
    game_logic game_engine (
        .clk(clk),
        .reset(rst),
        .ready(event_ready),                   
        .coord(sw),                 // Feed the switches directly as the coordinate
        .in_type(event_action),                
        .valid_squares(mask_from_game),        
        .status_code(error_from_game)          
    );

    // ==========================================
    // MAPPING THE OUTPUT TO THE BOARD LEDs
    // ==========================================
    // LEDs 0 to 14 will show Valid Moves for Squares 16 to 30 (Rows 3 and 4)
    assign led[14:0] = mask_from_game[30:16]; 
    
    // LED 15 (The far left one) is our Error Indicator
    assign led[15] = error_from_game;

endmodule