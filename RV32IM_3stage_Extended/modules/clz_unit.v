`timescale 1ns / 1ps

module clz_unit (
    input wire [31:0] operand_a,
    output wire [31:0] log2_result
);
    function [4:0] clz_32(input [31:0] val);
        if (val[31:16] != 0) clz_32 = clz_16(val[31:16]);
        else clz_32 = 5'd16 + clz_16(val[15:0]);
    endfunction
    function [3:0] clz_16(input [15:0] val);
        if (val[15:8] != 0) clz_16 = clz_8(val[15:8]);
        else clz_16 = 4'd8 + clz_8(val[7:0]);
    endfunction
    function [2:0] clz_8(input [7:0] val);
        if (val[7:4] != 0) clz_8 = clz_4(val[7:4]);
        else clz_8 = 3'd4 + clz_4(val[3:0]);
    endfunction
    function [1:0] clz_4(input [3:0] val);
        if (val[3:2] != 0) clz_4 = clz_2(val[3:2]);
        else clz_4 = 2'd2 + clz_2(val[1:0]);
    endfunction
    function clz_2(input [1:0] val);
        if (val[1]) clz_2 = 1'b0;
        else clz_2 = 1'b1;
    endfunction

    wire [4:0] zeros = (operand_a == 0) ? 5'd31 : clz_32(operand_a);
    assign log2_result = (operand_a == 0) ? 32'b0 : (32'd31 - zeros);
endmodule