`include "opcode.vh"
module EX_Stage (
    input wire clk, rst,
    input wire [31:0] op_a, op_b,
    input wire [6:0] opcode, funct7,
    input wire [2:0] funct3,
    output wire stall, is_store,
    output reg valid_out,
    output reg [31:0] ex_result,
    output wire [31:0] store_data
);
    wire is_m = (opcode == `OPCODE_RV32M && funct7 == `FUNCT7_M_MAU);
    wire is_mau = (opcode == `OPCODE_MAU && funct7 == `FUNCT7_M_MAU);
    
    wire mul_en = is_m && (funct3 < 4);
    wire sqrt_en = is_mau && (funct3 == 3);
    
    wire mul_busy, sqrt_done;
    wire [63:0] mul_res;
    wire [31:0] sqrt_res, mau_res;
    
    multiplier u_mul (.clk(clk), .rst(rst), .start(mul_en), .operand_a(op_a), .operand_b(op_b), .product(mul_res), .valid(mul_busy));
    sqrt_unit  u_sqrt (.clk(clk), .rst(rst), .start(sqrt_en), .radicand(op_a), .root(sqrt_res), .done(sqrt_done));
    mau_simple u_mau  (.operand_a(op_a), .operand_b(op_b), .funct3(funct3), .result(mau_res));

    assign stall = mul_busy | sqrt_done;
    assign is_store = (opcode == `OPCODE_STORE);
    assign store_data = op_b;

    // FIX: Properly route the memory address for SW, and XOR for math.
    wire [31:0] alu_res = (is_store) ? op_a : ((funct3 == 3'b100) ? (op_a ^ op_b) : (op_a + op_b));

    always @(*) begin
        valid_out = 1; ex_result = 0;
        if (!stall) begin
            if (mul_en) ex_result = mul_res[31:0];
            else if (sqrt_en) ex_result = sqrt_res;
            else if (is_mau) ex_result = mau_res;
            else ex_result = alu_res;
        end else valid_out = 0;
    end
endmodule
