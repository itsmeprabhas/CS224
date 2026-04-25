// ============================================================
// bin_to_bcd.v
// Combinational double-dabble (shift-and-add-3) converter
//
// Converts a 16-bit binary value to 5 BCD decimal digits.
// Max input: 65535  →  "6","5","5","3","5"
// For this project result ≤ 21, only bcd1/bcd0 are non-zero.
// ============================================================
`timescale 1ns/1ps

module bin_to_bcd (
    input  wire [15:0] bin,
    output reg  [3:0]  bcd4,   // ten-thousands digit
    output reg  [3:0]  bcd3,   // thousands digit
    output reg  [3:0]  bcd2,   // hundreds digit
    output reg  [3:0]  bcd1,   // tens digit
    output reg  [3:0]  bcd0    // ones digit
);
    // Scratch register: 20 BCD bits (5 digits) + 16 binary bits
    reg [35:0] scratch;
    integer    i;

    always @(*) begin
        // Initialise: BCD area = 0, binary area = input
        scratch         = 36'd0;
        scratch[15:0]   = bin;

        // 16 shift iterations
        for (i = 0; i < 16; i = i + 1) begin
            // Add 3 to any BCD column that is ≥ 5
            if (scratch[19:16] >= 4'd5) scratch[19:16] = scratch[19:16] + 4'd3;
            if (scratch[23:20] >= 4'd5) scratch[23:20] = scratch[23:20] + 4'd3;
            if (scratch[27:24] >= 4'd5) scratch[27:24] = scratch[27:24] + 4'd3;
            if (scratch[31:28] >= 4'd5) scratch[31:28] = scratch[31:28] + 4'd3;
            if (scratch[35:32] >= 4'd5) scratch[35:32] = scratch[35:32] + 4'd3;
            // Left-shift the whole register by 1
            scratch = scratch << 1;
        end

        // Extract BCD digits
        bcd0 = scratch[19:16];
        bcd1 = scratch[23:20];
        bcd2 = scratch[27:24];
        bcd3 = scratch[31:28];
        bcd4 = scratch[35:32];
    end

endmodule
