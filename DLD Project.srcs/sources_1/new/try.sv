module chess_board_input #(
    parameter SYS_CLK_FREQ = 100_000_000, // 100MHz
    parameter TARGET_FREQ  = 1500         // 1.5kHz Sampling
)(
    input  wire        clk,       // System Clock
    input  wire        reset,     // Active high reset
    input  wire        data_in,   // DATA_PIN (Serial from register)
    output reg         latch_out, // LATCH_PIN (to Transistor)
    output reg         clk_out,   // CLK_PIN (to Transistor)
    output reg [63:0]  board_data // 64-bit parallel output
);

    // --- Timing Constants ---
    localparam SAMPLE_COUNT = SYS_CLK_FREQ / TARGET_FREQ;
    localparam SHIFT_DIV    = 100; // Shift clock speed (approx 1MHz)

    // --- State Machine ---
    typedef enum reg [2:0] {
        IDLE    = 3'b000,
        LATCH   = 3'b001,
        PRE_CLK = 3'b010,
        SHIFT   = 3'b011,
        DONE    = 3'b100
    } state_t;

    state_t state = IDLE;
    
    reg [31:0] sample_timer = 0;
    reg [7:0]  shift_timer  = 0;
    reg [6:0]  bit_counter  = 0;
    reg [63:0] shift_reg    = 0;

    always @(posedge clk) begin
        if (reset) begin
            state        <= IDLE;
            sample_timer <= 0;
            latch_out    <= 0; // Transistor makes this HIGH (Shift Mode)
            clk_out      <= 1; // Transistor makes this LOW (Idle)
            board_data   <= 0;
        end else begin
            case (state)
                
                IDLE: begin
                    latch_out <= 0; 
                    clk_out   <= 1;
                    if (sample_timer >= SAMPLE_COUNT) begin
                        sample_timer <= 0;
                        state        <= LATCH;
                    end else begin
                        sample_timer <= sample_timer + 1;
                    end
                end

                LATCH: begin
                    latch_out <= 1; // Transistor outputs LOW (LOAD)
                    if (shift_timer >= SHIFT_DIV) begin
                        shift_timer <= 0;
                        latch_out   <= 0; // Back to SHIFT mode
                        state       <= PRE_CLK;
                    end else begin
                        shift_timer <= shift_timer + 1;
                    end
                end

                PRE_CLK: begin
                    // Stabilize after latch before first shift
                    if (shift_timer >= SHIFT_DIV) begin
                        shift_timer <= 0;
                        state       <= SHIFT;
                    end else begin
                        shift_timer <= shift_timer + 1;
                    end
                end

                SHIFT: begin
                    // To get a RISING edge at the register, we need a FALLING edge here
                    if (shift_timer == 0) begin
                        clk_out <= 0; // Transistor outputs HIGH (The Edge)
                        shift_reg <= {shift_reg[62:0], data_in}; 
                    end else if (shift_timer == SHIFT_DIV / 2) begin
                        clk_out <= 1; // Transistor outputs LOW
                    end

                    if (shift_timer >= SHIFT_DIV) begin
                        shift_timer <= 0;
                        if (bit_counter == 63) begin
                            bit_counter <= 0;
                            state       <= DONE;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end else begin
                        shift_timer <= shift_timer + 1;
                    end
                end

                DONE: begin
                    board_data <= shift_reg;
                    state      <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule