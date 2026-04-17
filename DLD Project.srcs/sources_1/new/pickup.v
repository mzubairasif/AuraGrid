`timescale 1ns / 1ps

module board_io (
    input logic clk,
    input logic rst,
    input logic [47:0] raw_hall_sensors,
    
    // Outputs to game_logic
    output logic [5:0] coord,
    output logic in_type, // 1 = pickup, 0 = putdown
    output logic event_ready // Pulses HIGH for 1 clock cycle when an event occurs
);

    // Double-flop synchronizer to prevent metastability from raw hardware inputs
    logic [47:0] sync_1, sync_2;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            sync_1 <= 48'hFFFF_FFFF_FFFF; 
            sync_2 <= 48'hFFFF_FFFF_FFFF;
        end else begin
            sync_1 <= raw_hall_sensors;
            sync_2 <= sync_1;                  
        end
    end

    // Debounce Logic (~50ms at 100MHz)
    parameter DEBOUNCE_TIME = 23'd5_000_000; 
    logic [22:0] debounce_counter = 0;
    
    logic [47:0] candidate_state = 48'hFFFF_FFFF_FFFF;
    logic [47:0] stable_state = 48'hFFFF_FFFF_FFFF;
    logic [47:0] prev_stable_state = 48'hFFFF_FFFF_FFFF;

    always_ff @(posedge clk) begin
        if (rst) begin
            debounce_counter <= 0;
            stable_state <= 48'hFFFF_FFFF_FFFF;
            candidate_state <= 48'hFFFF_FFFF_FFFF;
            prev_stable_state <= 48'hFFFF_FFFF_FFFF;
            event_ready <= 0;
        end else begin
            // Default pulse state
            event_ready <= 0; 

            // Debouncing
            if (sync_2 != candidate_state) begin
                candidate_state <= sync_2;
                debounce_counter <= 0;
            end else if (debounce_counter < DEBOUNCE_TIME) begin
                debounce_counter <= debounce_counter + 1;
            end else if (stable_state != candidate_state) begin
                // State has stabilized and is different from current stable state
                prev_stable_state <= stable_state;
                stable_state <= candidate_state;
            end

            // Event Generation
            // If states differ, find the bit that changed
            if (stable_state != prev_stable_state) begin
                logic [47:0] diff;
                diff = stable_state ^ prev_stable_state;
                
                // Find the index of the changed bit (Basic priority encoder approach)
                for (int i = 0; i < 48; i++) begin
                    if (diff[i] == 1'b1) begin
                        coord <= i[5:0]; // Cast integer to 6-bit
                        
                        // Sensor logic is Active LOW (0 = Magnet Present)
                        // If bit went from 0 to 1 -> Magnet removed -> PICKUP
                        // If bit went from 1 to 0 -> Magnet placed -> PUTDOWN
                        in_type <= stable_state[i] ? 1'b1 : 1'b0;
                        event_ready <= 1'b1; // Trigger game_logic execution
                        
                        // Update prev_state so we don't fire continuously for the same diff
                        prev_stable_state[i] <= stable_state[i]; 
                    end
                end
            end
        end
    end
endmodule