`timescale 1ns / 1ps

module top_divider_demo (
    input  wire        clk,
    input  wire        rst_n,   // Push button mapped mapped to CPU_RESETN (active low)
    input  wire [15:0] sw,      // Physical switches
    input  wire        btnC,    // Center button pulse to start execution
    
    output wire [7:0]  anodes,
    output wire [7:0]  cathodes,
    output wire [15:0] led
);

    wire rst = ~rst_n; // Convert to active high within the system

    // Operand parameterizations via switches (physical subset mapping)
    // For full coverage, we rely on the testbench. For the physical board, 
    // we use a simplified bit slicing for visual feedback
    wire [31:0] operand_a = {{25{sw[13]}}, sw[13:7]};   // Sign-extended 7-bit
    wire [31:0] operand_b = {{25{sw[6]}}, sw[6:0]};     // Sign-extended 7-bit
    wire [1:0]  div_op    = sw[15:14];

    wire [31:0] quotient;
    wire [31:0] remainder;
    wire valid;
    wire busy;

    // Button edge detection for pulse formatting
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

    // Divider Module Hookup
    divider u_divider (
        .clk(clk),
        .rst(rst),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .div_op(div_op),
        .start(start_pulse),
        .quotient(quotient),
        .remainder(remainder),
        .valid(valid),
        .busy(busy)
    );

    // Keep display stable when done
    wire [31:0] selected_result = (div_op == 2'b10 || div_op == 2'b11) ? remainder : quotient;
    reg [31:0] display_result;
    always @(posedge clk) begin
        if (rst) display_result <= 32'd0;
        else if (valid) display_result <= selected_result;
    end

    seven_seg_driver u_seven_seg (
        .clk(clk),
        .rst(rst),
        .display_value(display_result),
        .anodes(anodes),
        .cathodes(cathodes)
    );

    // Direct status outputs
    assign led[15:14] = div_op;
    assign led[13:7]  = operand_a[6:0];
    assign led[6:0]   = operand_b[6:0];
    
endmodule
