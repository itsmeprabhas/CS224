`timescale 1ns / 1ps
`include "opcode.vh"

module execute (
    input wire clk, 
    input wire rst,
    
    // Decoded control signals and data
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire [31:0] rs1_data, 
    input wire [31:0] rs2_data,
    input wire [3:0] alu_ctrl,
    
    // Outputs
    output reg [31:0] final_result,
    output wire execute_stall      
);

    // --- 1. INSTRUCTION DECODING ---
    // Safely check if this is a Mathematical Acceleration Unit (MAU) instruction
    wire is_mau  = (opcode == `OPCODE_CUSTOM) && (funct7 == `FUNCT7_MAU);
    wire is_sqrt = is_mau && (funct3 == `F3_SQRT);

    // --- 2. HARDWARE INSTANTIATION ---
    // MAU Simple (ABS, MAX, MIN)
    wire [31:0] mau_simple_res;
    mau_simple hw_mau_s (
        .funct3(funct3), 
        .operand_a(rs1_data), 
        .operand_b(rs2_data), 
        .result(mau_simple_res)
    );

    // LOG2 Unit (CLZ)
    wire [31:0] log2_res;
    clz_unit hw_clz (
        .operand_a(rs1_data), 
        .log2_result(log2_res)
    );

    // Standard ALU Stub (Placeholder for standard additions/subtractions)
    reg [31:0] alu_result;
    always @(*) begin
        case (alu_ctrl)
            4'b0000: alu_result = rs1_data + rs2_data; // ADD
            4'b1000: alu_result = rs1_data - rs2_data; // SUB
            default: alu_result = 32'b0;
        endcase
    end

    // --- 3. FINAL RESULT MULTIPLEXER ---
    always @(*) begin
        if (is_mau && funct3 == `F3_LOG2) 
            final_result = log2_res;
        else if (is_mau && funct3 != `F3_SQRT) 
            final_result = mau_simple_res;
        else 
            final_result = alu_result; // Standard ALU routing
    end

    // --- 4. PIPELINE STALL LOGIC ---
    // Stalls the pipeline only if the multi-cycle SQRT instruction is called
    wire sqrt_valid = 1'b1; // Default to 1 (done) until Kiran finishes the real SQRT module
    assign execute_stall = (is_sqrt & ~sqrt_valid);

endmodule
