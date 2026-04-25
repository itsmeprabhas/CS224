// ============================================================
// seg7_display.v
// Time-multiplexed 8-digit 7-segment display driver
//
// Nexys A7: common-anode display
//   Segments are ACTIVE LOW  (0 = ON,  1 = OFF)
//   Anodes   are ACTIVE LOW  (0 = digit selected)
//
// Refresh: 100 MHz / 2^17 ≈ 763 Hz total
//          Each digit active at  ≈ 95 Hz  (flicker-free)
//
// Segment bit ordering matches Nexys A7 XDC:
//   seg[0]=CA(a)  seg[1]=CB(b)  seg[2]=CC(c)  seg[3]=CD(d)
//   seg[4]=CE(e)  seg[5]=CF(f)  seg[6]=CG(g)
//
// Digit 4'hF  →  blank (all segments off)
// ============================================================
`timescale 1ns/1ps

module seg7_display (
    input  wire        clk,          // 100 MHz system clock
    input  wire        rst,
    // 8 hex nibbles, leftmost = d7, rightmost = d0
    // Pass 4'hF for a blank digit
    input  wire [3:0]  d7, d6, d5, d4,
    input  wire [3:0]  d3, d2, d1, d0,
    // Decimal-point enable per digit (active-HIGH here)
    // dp_en[7] → rightmost DP on digit d7, etc.
    input  wire [7:0]  dp_en,
    // Board outputs
    output reg  [6:0]  seg,          // cathodes, active LOW
    output reg         dp,           // decimal point, active LOW
    output reg  [7:0]  an            // anodes, active LOW
);

    // ── Clock divider ─────────────────────────────────────────
    reg [16:0] clk_cnt;
    always @(posedge clk or posedge rst)
        if (rst) clk_cnt <= 17'd0;
        else     clk_cnt <= clk_cnt + 17'd1;

    // Upper 3 bits select 1-of-8 digits
    wire [2:0] sel = clk_cnt[16:14];

    // ── Digit / anode multiplexer ─────────────────────────────
    reg [3:0] cur;   // currently selected hex nibble

    always @(*) begin
        case (sel)
            3'd7: begin an = 8'b0111_1111; cur = d7; dp = ~dp_en[7]; end
            3'd6: begin an = 8'b1011_1111; cur = d6; dp = ~dp_en[6]; end
            3'd5: begin an = 8'b1101_1111; cur = d5; dp = ~dp_en[5]; end
            3'd4: begin an = 8'b1110_1111; cur = d4; dp = ~dp_en[4]; end
            3'd3: begin an = 8'b1111_0111; cur = 4'hF; dp = 1'b1; end
            3'd2: begin an = 8'b1111_1011; cur = d2; dp = ~dp_en[2]; end
            3'd1: begin an = 8'b1111_1101; cur = d1; dp = ~dp_en[1]; end
            3'd0: begin an = 8'b1111_1110; cur = d0; dp = ~dp_en[0]; end
            default: begin an = 8'b1111_1111; cur = 4'hF; dp = 1'b1; end
        endcase
    end

    // ── Hex-to-7-segment decoder (active LOW) ─────────────────
    // seg[6:0] = { CG(g), CF(f), CE(e), CD(d), CC(c), CB(b), CA(a) }
    //
    //   ─ a ─
    //  |     |
    //  f     b
    //  |     |
    //   ─ g ─
    //  |     |
    //  e     c
    //  |     |
    //   ─ d ─
    //
    always @(*) begin
        case (cur)
          //          gfedcba
            4'h0: seg = 7'b100_0000;   // 0
            4'h1: seg = 7'b111_1001;   // 1
            4'h2: seg = 7'b010_0100;   // 2
            4'h3: seg = 7'b011_0000;   // 3
            4'h4: seg = 7'b001_1001;   // 4
            4'h5: seg = 7'b001_0010;   // 5
            4'h6: seg = 7'b000_0010;   // 6
            4'h7: seg = 7'b111_1000;   // 7
            4'h8: seg = 7'b000_0000;   // 8
            4'h9: seg = 7'b001_0000;   // 9
            4'hA: seg = 7'b000_1000;   // A
            4'hB: seg = 7'b000_0011;   // b
            4'hC: seg = 7'b100_0110;   // C
            4'hD: seg = 7'b010_0001;   // d
            4'hE: seg = 7'b000_0110;   // E
            4'hF: seg = 7'b111_1111;   // F
            default: seg = 7'b111_1111;
        endcase
    end

endmodule
