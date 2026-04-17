`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference Book: 
// Chu, Pong P.
// Wiley, 2008
// "FPGA Prototyping by Verilog Examples: Xilinx Spartan-3 Version" 
// 
// Adapted for the Basys 3 by David J. Marion
// Comments by David J. Marion
//
// FOR USE WITH AN FPGA THAT HAS A 100MHz CLOCK SIGNAL ONLY.
// VGA Mode
// 640x480 pixels VGA screen with 25MHz pixel rate based on 60 Hz refresh rate
// 800 pixels/line * 525 lines/screen * 60 screens/second = ~25.2M pixels/second
//
// A 25MHz signal will suffice. The Basys 3 has a 100MHz signal available, so a
// 25MHz tick is created for syncing the pixel counts, pixel tick, horiz sync, 
// vert sync, and video on signals.
//////////////////////////////////////////////////////////////////////////////////

module vga_controller(
    input clk_100MHz,   
    input reset,        
    output video_on,    
    output hsync,       
    output vsync,       
    output p_tick,      
    output [9:0] x,     
    output [9:0] y      
    );
    
    // VGA Standards for 640x480 @ 60Hz
    localparam HD = 640; // Display
    localparam HF = 16;  // Front Porch
    localparam HR = 96;  // Sync Pulse
    localparam HB = 48;  // Back Porch
    localparam HMAX = 799;

    localparam VD = 480;
    localparam VF = 10; 
    localparam VR = 2;  
    localparam VB = 33; 
    localparam VMAX = 524;
    
    // Generate 25MHz enable pulse (p_tick)
    reg [1:0] r_25MHz;
    always @(posedge clk_100MHz or posedge reset) begin
        if(reset) r_25MHz <= 0;
        else      r_25MHz <= r_25MHz + 1;
    end
    assign p_tick = (r_25MHz == 2'b11); // Pulse every 4th 100MHz cycle

    reg [9:0] h_cnt = 0, v_cnt = 0;
    reg h_sync_reg = 0, v_sync_reg = 0;

    // All logic runs on 100MHz clock for stability
    always @(posedge clk_100MHz or posedge reset) begin
        if(reset) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end
        else if(p_tick) begin
            // Horizontal Counter
            if(h_cnt == HMAX) h_cnt <= 0;
            else              h_cnt <= h_cnt + 1;

            // Vertical Counter
            if(h_cnt == HMAX) begin
                if(v_cnt == VMAX) v_cnt <= 0;
                else              v_cnt <= v_cnt + 1;
            end

            // Sync Generation (Active Low)
            // Pulse occurs AFTER Display and Front Porch
            h_sync_reg <= ~((h_cnt >= (HD + HF)) && (h_cnt < (HD + HF + HR)));
            v_sync_reg <= ~((v_cnt >= (VD + VF)) && (v_cnt < (VD + VF + VR)));
        end
    end
    
    assign hsync    = h_sync_reg;
    assign vsync    = v_sync_reg;
    assign video_on = (h_cnt < HD) && (v_cnt < VD);
    assign x        = h_cnt;
    assign y        = v_cnt;
            
endmodule