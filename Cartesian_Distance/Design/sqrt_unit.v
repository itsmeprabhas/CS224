// ============================================================
// sqrt_unit.v
// Bit-by-bit integer square root  (16 clock cycles)
//
// Algorithm: tests bits 15 down to 0 one per cycle.
//   Each cycle, trial = accumulated_result | (1 << bit_pos)
//   If trial² ≤ D  →  accept that bit into the result.
//
// Input  : 32-bit radicand D
// Output : 16-bit result  = floor(sqrt(D))
//          1-cycle 'done' pulse when result is valid
// ============================================================
`timescale 1ns/1ps

module sqrt_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,   // 1-cycle HIGH to begin
    input  wire [31:0] D,       // radicand (latched on start)
    output reg  [15:0] result,  // floor(sqrt(D))
    output reg         done     // 1-cycle pulse: result is valid
);

    reg [4:0]  bit_pos;    // current test bit position: 15..0
    reg [15:0] res;        // accumulated result so far
    reg [31:0] D_latch;    // latched copy of D
    reg        busy;

    // Combinational trial value and its square (16×16 → 32 bits)
    wire [15:0] trial    = res | (16'd1 << bit_pos);
    wire [31:0] trial_sq = trial * trial;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy    <= 1'b0;
            done    <= 1'b0;
            result  <= 16'd0;
            res     <= 16'd0;
            bit_pos <= 5'd15;
            D_latch <= 32'd0;
        end else begin
            done <= 1'b0;          // default: no done pulse

            if (start && !busy) begin
                // Latch radicand and start iteration from bit 15
                D_latch <= D;
                res     <= 16'd0;
                bit_pos <= 5'd15;
                busy    <= 1'b1;

            end else if (busy) begin
                // Accept this bit if trial² ≤ D
                if (trial_sq <= D_latch)
                    res <= trial;

                if (bit_pos == 5'd0) begin
                    // Final iteration - output result
                    result <= (trial_sq <= D_latch) ? trial : res;
                    done   <= 1'b1;
                    busy   <= 1'b0;
                end else begin
                    bit_pos <= bit_pos - 5'd1;
                end
            end
        end
    end

endmodule
