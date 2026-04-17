`timescale 1ns / 1ps

module button_edge_det(
    input logic clk,
    input logic btn,
    output logic pulse
);
    logic q1, q2, q3;

    // Shift register to debounce and detect rising edge
    always_ff @(posedge clk) begin
        q1 <= btn;
        q2 <= q1;
        q3 <= q2;
    end

    // Pulse is HIGH only on the transition from LOW to HIGH
    assign pulse = q2 && !q3;
endmodule