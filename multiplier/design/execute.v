`timescale 1ns / 1ps

module execute (
    input wire clk,
    input wire rst,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    input wire [3:0] alu_ctrl,
    output reg [31:0] final_result,
    output wire execute_stall      
);

    wire is_rv32m = (opcode == 7'b0110011) && (funct7 == 7'b0000001);
    wire is_mul  = is_rv32m && (funct3[2] == 1'b0);
    wire is_div  = is_rv32m && (funct3[2] == 1'b1);
    
    wire is_mau  = (opcode == 7'b0001011);
    wire is_sqrt = is_mau && (funct3 == 3'b011);

    wire [63:0] product_64;
    wire mul_valid;
    
    multiplier hw_mul (
        .clk(clk),
        .rst(rst),
        .start(is_mul),       
        .funct3(funct3),      
        .operand_a(rs1_data),
        .operand_b(rs2_data),
        .product(product_64),
        .valid(mul_valid)
    );

    wire [31:0] div_result_32 = 32'b0; 
    wire div_valid = 1'b1; 
    wire [31:0] mau_result_32 = 32'b0;
    wire sqrt_valid = 1'b1; 

    reg [31:0] alu_result;
    always @(*) begin
        case (alu_ctrl)
            4'b0000: alu_result = rs1_data + rs2_data; 
            4'b1000: alu_result = rs1_data - rs2_data; 
            default: alu_result = 32'b0;
        endcase
    end

    reg [31:0] mul_result_32;
    always @(*) begin
        case (funct3)
            3'b000: mul_result_32 = product_64[31:0];  
            3'b001: mul_result_32 = product_64[63:32]; 
            3'b010: mul_result_32 = product_64[63:32]; 
            3'b011: mul_result_32 = product_64[63:32]; 
            default: mul_result_32 = 32'b0;
        endcase
    end

    always @(*) begin
        if (is_mul)      final_result = mul_result_32;
        else if (is_div) final_result = div_result_32;
        else if (is_mau) final_result = mau_result_32;
        else             final_result = alu_result;
    end

    wire mul_stall  = is_mul  & ~mul_valid;
    wire div_stall  = is_div  & ~div_valid;
    wire sqrt_stall = is_sqrt & ~sqrt_valid;

    assign execute_stall = mul_stall | div_stall | sqrt_stall;
endmodule
