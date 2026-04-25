`timescale 1ns / 1ps

module top_divider_demo (
    input  wire        clk,
    input  wire        rst_n,   // active low reset (CPU_RESETN)
    input  wire [15:0] sw,      // physical switches
    input  wire        btnC,    // center button pulse to start
    
    output wire [7:0]  anodes,
    output wire [7:0]  cathodes,
    output wire [15:0] led
);

    // Convert to active high reset
    wire rst = ~rst_n;

    // ----- Operand construction (7-bit sign‑extended) -----
    wire [31:0] operand_a = {{25{sw[13]}}, sw[13:7]};
    wire [31:0] operand_b = {{25{sw[6]}},  sw[6:0]};
    
    // ----- funct3 generation from top‑level operation switches -----
    // sw[15:14] → div_op (2 bits) → RV32 funct3 encoding:
    //   00 -> DIV  (100)   01 -> DIVU (101)
    //   10 -> REM  (110)   11 -> REMU (111)
    wire [2:0]  funct3 = {1'b1, sw[15:14]};

    // ----- Button edge detection → single‑cycle start pulse -----
    reg btnC_sync1, btnC_sync2, btnC_last;
    wire start_pulse = btnC_sync2 & ~btnC_last;
    
    always @(posedge clk) begin
        if (rst) begin
            btnC_sync1 <= 0;
            btnC_sync2 <= 0;
            btnC_last  <= 0;
        end else begin
            btnC_sync1 <= btnC;
            btnC_sync2 <= btnC_sync1;
            btnC_last  <= btnC_sync2;
        end
    end

    // ----- Divider instantiation (matching actual divider.v) -----
    wire [31:0] result;
    wire        valid, busy;

    divider u_divider (
        .clk        (clk),
        .rst        (rst),
        .start      (start_pulse),
        .funct3     (funct3),
        .operand_a  (operand_a),
        .operand_b  (operand_b),
        .result     (result),
        .valid      (valid),
        .busy       (busy)
    );

    // ----- Display register (holds result after valid) -----
    reg [31:0] display_result;
    always @(posedge clk) begin
        if (rst)
            display_result <= 32'd0;
        else if (valid)
            display_result <= result;      // result already encodes quotient/remainder
    end

    // ----- Seven‑segment driver -----
    seven_seg_driver u_seven_seg (
        .clk           (clk),
        .rst           (rst),
        .display_value (display_result),
        .anodes        (anodes),
        .cathodes      (cathodes)
    );

    // ----- LED status: op, operand_a, operand_b -----
    assign led[15:14] = sw[15:14];         // current operation
    assign led[13:7]  = operand_a[6:0];    // a[6:0] (matches switches)
    assign led[6:0]   = operand_b[6:0];    // b[6:0]

endmodule
