`timescale 1ns / 1ps

module mau_simple (
    input wire [2:0] funct3,        
    input wire [31:0] operand_a,    
    input wire [31:0] operand_b,    
    output reg [31:0] result        
);
    wire [31:0] abs_result = (operand_a[31]) ? (~operand_a + 1) : operand_a;
    wire signed [32:0] a_ext = {operand_a[31], operand_a};
    wire signed [32:0] b_ext = {operand_b[31], operand_b};
    wire signed [32:0] diff = a_ext - b_ext;
    
    wire [31:0] max_result = (~diff[32]) ? operand_a : operand_b;
    wire [31:0] min_result = ( diff[32]) ? operand_a : operand_b;

    always @(*) begin
        case (funct3)
            3'b000: result = abs_result; 
            3'b001: result = max_result; 
            3'b010: result = min_result; 
            default: result = 32'b0;
        endcase
    end
endmodule
