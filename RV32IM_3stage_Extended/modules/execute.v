`timescale 1ns/1ps

`include "multiplier.v"
`include "divider.v"
`include "sqrt_unit.v"
`include "mau_simple.v"
`include "clz_unit.v"

////////////////////////////////////////////////////////////// 
// Stage 2: Execute
////////////////////////////////////////////////////////////
module execute
#(
	parameter [31:0] RESET = 32'h0000_0000
)
(
	input clk,
	input reset,

	// -----------------------------	// FROM ID/EX	// -----------------------------
	input  [31:0] reg_rdata1,
	input  [31:0] reg_rdata2,
	input  [31:0] execute_imm,
	input  [31:0] pc,
	input  [31:0] fetch_pc,
	input     	immediate_sel,
	input     	mem_write,
	input     	jal,
	input     	jalr,
	input     	lui,
	input     	alu,
	input     	branch,
	input     	arithsubtype,
	input     	mem_to_reg,
	input     	stall_read,
	
	// Extension Enables
	input       mul_en,
	input       div_en,
	input       mau_en,
	input       sqrt_en,
	input [6:0] funct7,

	input  [4:0]  dest_reg_sel,
	input  [2:0]  alu_op,
	input  [1:0]  dmem_raddr,

	// -----------------------------	// FROM WB	// -----------------------------
	input     	wb_branch_i,
	input     	wb_branch_nxt_i,

	// -----------------------------	// EX → PIPE	// -----------------------------
	output [31:0] alu_operand1,
	output [31:0] alu_operand2,
	output [31:0] write_address,
	output    	branch_stall,
	output      execute_stall,

	output reg [31:0] next_pc,
	output reg    	branch_taken,

	// -----------------------------  // EX → WB	// -----------------------------
	output [31:0] wb_result,
	output    	wb_mem_write,
	output    	wb_alu_to_reg,
	output [4:0]  wb_dest_reg_sel,
	output    	wb_branch,
	output    	wb_branch_nxt,
	output    	wb_mem_to_reg,
	output [1:0]  wb_read_address,
	output [2:0]  mem_alu_operation
);

//////////////// Including OPCODES ////////////////////////////
`include "opcode.vh"

////////////////////////////////////////////////////////////// LOCAL INTERNAL SIGNALS/////////////////////////////////

reg  [31:0] ex_result;
wire [32:0] ex_result_subs;
wire [32:0] ex_result_subu;

// Extension Signals
wire [63:0] product;
wire mul_valid;
wire [31:0] div_result;
wire div_valid;
wire [31:0] sqrt_res;
wire sqrt_valid;
wire [31:0] mau_result;
wire [31:0] clz_res;

// Start logic for multi-cycle operations
wire mul_start = mul_en & ~mul_valid;
wire div_start = div_en & ~div_valid;
wire sqrt_start = sqrt_en & ~sqrt_valid;

assign execute_stall = mul_start | div_start | sqrt_start;

// Module Instantiations
multiplier u_mul (
    .clk(clk),
    .rst(!reset), // active high reset for multiplier
    .start(mul_start),
    .funct3(alu_op),
    .operand_a(alu_operand1),
    .operand_b(alu_operand2),
    .product(product),
    .valid(mul_valid)
);

divider u_div (
    .clk(clk),
    .rst(!reset),
    .start(div_start),
    .funct3(alu_op),
    .operand_a(alu_operand1),
    .operand_b(alu_operand2),
    .result(div_result),
    .valid(div_valid),
    .busy()
);

sqrt_unit u_sqrt (
    .clk(clk),
    .rst(!reset),
    .start(sqrt_start),
    .funct3(alu_op),
    .operand_a(alu_operand1),
    .operand_b(alu_operand2),
    .result(sqrt_res),
    .valid(sqrt_valid)
);

mau_simple u_mau (
    .funct3(alu_op),
    .operand_a(alu_operand1),
    .operand_b(alu_operand2),
    .result(mau_result)
);

clz_unit u_clz (
    .operand_a(alu_operand1),
    .log2_result(clz_res)
);

////////////////////////////////////////////////////////////// Operand selection///////////////////////////////////////////////////////

assign alu_operand1 = reg_rdata1;
assign alu_operand2 = immediate_sel ? execute_imm : reg_rdata2;

////////////////////////////////////////////////////////////// Subtractions////////////////////////////////////////////////////////////

assign ex_result_subs =
	{alu_operand1[31], alu_operand1} -
	{alu_operand2[31], alu_operand2};

assign ex_result_subu = {1'b0, alu_operand1} - {1'b0, alu_operand2};

////////////////////////////////////////////////////////////// Address & branch stall////////////////////////////////////////

assign write_address = alu_operand1 + execute_imm;
assign branch_stall  = wb_branch_nxt_i || wb_branch_i;

////////////////////////////////////////////////////////////// Next PC logic////////////////////////////////////////////////////////////

always @(*) begin
	next_pc  	= fetch_pc + 4;
	branch_taken = !branch_stall;

	case (1'b1)
    	jal  : next_pc = pc + execute_imm;
    	jalr : next_pc = alu_operand1 + execute_imm;

    	branch: begin
        	case (alu_op)
            	BEQ:  begin
                	next_pc = (ex_result_subs == 0) ? pc + execute_imm : fetch_pc + 4;
                	if (ex_result_subs != 0) branch_taken = 1'b0;
                end
            	BNE:  begin
                	next_pc = (ex_result_subs != 0) ? pc + execute_imm : fetch_pc + 4;
                	if(ex_result_subs == 0) branch_taken = 1'b0;
                end
            	BLT:  begin
                	next_pc = ex_result_subs[32] ? pc + execute_imm : fetch_pc + 4;
                	if (!ex_result_subs[32]) branch_taken = 1'b0;
                end
            	BGE:  begin
                	next_pc = (!ex_result_subs[32]) ? pc+execute_imm : fetch_pc + 4;
                	if(ex_result_subs[32]) branch_taken = 1'b0;
                end
            	BLTU: begin
                	next_pc = ex_result_subu[32] ? pc + execute_imm : fetch_pc + 4;
                	if (!ex_result_subu[32]) branch_taken = 1'b0;
                end
            	BGEU: begin
                	next_pc = (!ex_result_subu[32]) ? pc+execute_imm : fetch_pc+4;
                	if(ex_result_subu[32]) branch_taken = 1'b0;
                end
            	default: next_pc = fetch_pc;
        	endcase
    	end

    	default: begin     	 
        	next_pc  	= fetch_pc + 4;
        	branch_taken = 1'b0;
    	end
	endcase
end

////////////////////////////////////////////////////////////// ALU result logic////////////////////////////////////////////////////////////

always @(*) begin
	case (1'b1)
    	mem_write: ex_result = alu_operand2;
    	jal,
    	jalr:  	ex_result = pc + 4;
    	lui:   	ex_result = execute_imm;
    	mul_en: begin
			case (alu_op)
				F3_MUL: ex_result = product[31:0];
				F3_MULH, F3_MULHSU, F3_MULHU: ex_result = product[63:32];
				default: ex_result = product[31:0];
			endcase
		end
		div_en: ex_result = div_result;
		sqrt_en: ex_result = sqrt_res;
		mau_en: ex_result = (alu_op == F3_LOG2) ? clz_res : mau_result;
    	alu: begin
        	case (alu_op)
            	ADD : ex_result = arithsubtype ? alu_operand1 - alu_operand2 : alu_operand1 + alu_operand2;
            	SLL : ex_result = alu_operand1 << alu_operand2[4:0]; 
            	SLT : ex_result = ex_result_subs[32];
            	SLTU: ex_result = ex_result_subu[32];
            	XOR : ex_result = alu_operand1 ^ alu_operand2;
            	SR  : ex_result = arithsubtype ? $signed(alu_operand1) >>> alu_operand2[4:0] : alu_operand1 >>> alu_operand2[4:0];
            	OR  : ex_result = alu_operand1 | alu_operand2;
            	AND : ex_result = alu_operand1 & alu_operand2;
            	default: ex_result = 'hx;
        	endcase
    	end

    	default: ex_result = 'hx;
	endcase
end


////////////////////////////////////////////////////////////// EX → WB pipeline register/////////////////////////////////////////

ex_mem_wb_reg u_ex_mem_wb (
	.clk        	(clk),
	.reset_n    	(reset),
	.stall_n    	(stall_read),

	.ex_result  	(ex_result),

	.mem_write  	(mem_write && !branch_stall),
    // FIX APPLIED HERE: Added mau_en | sqrt_en to the alu_to_reg check
	.alu_to_reg 	(alu | lui | jal | jalr | mem_to_reg | mul_en | div_en | mau_en | sqrt_en),
	.dest_reg_sel   (dest_reg_sel),
	.branch_taken   (branch_taken),
	.mem_to_reg 	(mem_to_reg),
	.read_address   (dmem_raddr),
	.alu_operation  (alu_op),

	.ex_mem_result    	(wb_result),
	.ex_mem_mem_write 	(wb_mem_write),
	.ex_mem_alu_to_reg	(wb_alu_to_reg),
	.ex_mem_dest_reg_sel  (wb_dest_reg_sel),
	.ex_mem_branch    	(wb_branch),
	.ex_mem_branch_nxt	(wb_branch_nxt),
	.ex_mem_mem_to_reg	(wb_mem_to_reg),
	.ex_mem_read_address  (wb_read_address),
	.ex_mem_alu_operation (mem_alu_operation)
);

endmodule


module ex_mem_wb_reg (
	input     	clk,
	input     	reset_n,
	input     	stall_n,

	// Data
	input  [31:0] ex_result,

	// Control inputs from EX/MEM
	input     	mem_write,
	input     	alu_to_reg,
	input  [4:0]  dest_reg_sel,
	input     	branch_taken,
	input     	mem_to_reg,
	input  [1:0]  read_address,
	input  [2:0]  alu_operation,

	// Outputs to WB
	output reg [31:0] ex_mem_result,
	output reg    	ex_mem_mem_write,
	output reg    	ex_mem_alu_to_reg,
	output reg [4:0]  ex_mem_dest_reg_sel,
	output reg    	ex_mem_branch,
	output reg    	ex_mem_branch_nxt,
	output reg    	ex_mem_mem_to_reg,
	output reg [1:0]  ex_mem_read_address,
	output reg [2:0]  ex_mem_alu_operation
);

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
    	ex_mem_result     	<= 32'h0;
    	ex_mem_mem_write  	<= 1'b0;
    	ex_mem_alu_to_reg 	<= 1'b0;
    	ex_mem_dest_reg_sel   <= 5'h0;
    	ex_mem_branch     	<= 1'b0;
    	ex_mem_branch_nxt 	<= 1'b0;
    	ex_mem_mem_to_reg 	<= 1'b0;
    	ex_mem_read_address   <= 2'h0;
    	ex_mem_alu_operation  <= 3'h0;
    end
	else if (!stall_n) begin
    	ex_mem_result     	<= ex_result;
    	ex_mem_mem_write  	<= mem_write;
    	ex_mem_alu_to_reg 	<= alu_to_reg;
    	ex_mem_dest_reg_sel   <= dest_reg_sel;
    	ex_mem_branch     	<= branch_taken;
    	ex_mem_branch_nxt 	<= ex_mem_branch;   
    	ex_mem_mem_to_reg 	<= mem_to_reg;
    	ex_mem_read_address   <= read_address;
    	ex_mem_alu_operation  <= alu_operation;
	end
end

endmodule
