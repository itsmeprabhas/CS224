`timescale 1ns / 1ps

module IF_ID #(
    parameter [31:0] RESET = 32'h0000_0000
) (
    input      clk,
    input      reset,
    input      stall,
    output reg exception,

    // IMEM interface
    input        inst_mem_is_valid,
    input [31:0] inst_mem_read_data,

    // ----------------------------- // Signals previously read from pipe  // -----------------------------
    input        stall_read_i,
    input [31:0] inst_fetch_pc,
    input [31:0] instruction_i,

    // -----------------------------    // WB-stage signals (passed in)    // -----------------------------
    input        wb_stall,
    input        wb_alu_to_reg,
    input        wb_mem_to_reg,
    input [ 4:0] wb_dest_reg_sel,
    input [31:0] wb_result,
    input [31:0] wb_read_data,

    // -----------------------------    // Instruction memory address info    // -----------------------------
    input  [ 1:0] inst_mem_offset,
    output [31:0] execute_immediate_w,
    output        immediate_sel_w,
    output        alu_w,
    output        lui_w,
    output        jal_w,
    output        jalr_w,
    output        branch_w,
    output        mem_write_w,
    output        mem_to_reg_w,
    output        arithsubtype_w,
    output        mul_en_w,
    output        div_en_w,
    output        mau_en_w,
    output        sqrt_en_w,
    output [31:0] pc_w,
    output [ 4:0] src1_select_w,
    output [ 4:0] src2_select_w,
    output [ 4:0] dest_reg_sel_w,
    output [ 2:0] alu_operation_w,
    output [ 6:0] funct7_w,
    output        illegal_inst_w,
    output [31:0] instruction_o
);

  //////////////// Including OPCODES ////////////////////////////
  `include "opcode.vh"
  //////////////////////////////
  //////////////////////////////// LOCAL INTERNAL SIGNALS////////////////////////////////////////////////////////////

  reg [31:0] immediate;
  reg        illegal_inst;

  ////////////////////////////////////////////////////////////// IF stage////////////////////////////////////////////////////////////


  // TODO-1:
  // Implement IF-stage instruction selection.
  // - On stall_read_i = 1, insert a NOP
  // - Otherwise, pass instruction/data from instruction memory

  reg [31:0] saved_inst;
  reg        was_stalled;

  always @(posedge clk or negedge reset) begin
      if (!reset) begin
          saved_inst  <= NOP;
          was_stalled <= 1'b0;
      end else begin
          was_stalled <= stall_read_i;
          
          // Only save the memory output on the EXACT cycle the stall begins
          if (stall_read_i && !was_stalled) begin
              saved_inst <= inst_mem_read_data;
          end
      end
  end

  // If stalled -> insert NOP bubble.
  // If recovering from stall -> output the saved instruction so it isn't lost.
  // Otherwise -> output live memory data.
  wire [31:0] decoded_inst = was_stalled ? saved_inst : inst_mem_read_data;
  assign instruction_o = stall_read_i ? NOP : decoded_inst;

  ////////////////////////////////////////////////////////////// Exception detection////////////////////////////////////////////////////////////

  // TODO-2:
  // Assert exception when:
  // - illegal instruction is detected
  // - instruction fetch is misaligned (inst_mem_offset != 2'b00)

  always @(posedge clk or negedge reset) begin
    if (!reset) exception <= 1'b0;
    else if (illegal_inst || inst_mem_offset != 2'b00) exception <= 1'b1;
    else exception <= 1'b0;
  end

  ////////////////////////////////////////////////////////////// ID stage: immediate generation ///////////////////////////////////////////////////////////

  // Generate 32-bit immediates for:
  // JAL, JALR, BRANCH, LOAD, STORE, ARITH-I, LUI
  // For unsupported opcodes, set illegal_inst = 1
  //
  // Definitions:
  // - instruction_i[31] is the sign bit
  // - "Sign-extend" means: replicate instruction_i[31] to fill all unused MSBs
  // - The number of replicated bits is implied by the immediate bit ranges below
  // - All immediates must be exactly 32 bits wide

  always @(*) begin
    immediate    = 32'h0;
    illegal_inst = 1'b0;

    case (decoded_inst[`OPCODE])
      // JALR:
      // Lower 12 bits  = decoded_inst[31:20]
      // Upper 20 bits  = Sign-extend
      JALR: immediate = {{20{decoded_inst[31]}}, decoded_inst[31:20]};

      // BRANCH:
      // immediate[12]   = decoded_inst[31]   (sign bit)
      // immediate[11]   = decoded_inst[7]
      // immediate[10:5] = decoded_inst[30:25]
      // immediate[4:1]  = decoded_inst[11:8]
      // immediate[0]	= 1'b0
      // immediate[31:13]= Sign-extend
      BRANCH:
      immediate = {
        {20{decoded_inst[31]}}, decoded_inst[7], decoded_inst[30:25], decoded_inst[11:8], 1'b0
      };

      // LOAD:
      // Lower 12 bits  = decoded_inst[31:20]
      // Upper 20 bits  = Sign-extend
      LOAD: immediate = {{20{decoded_inst[31]}}, decoded_inst[31:20]};

      // STORE:
      // Lower 5 bits   = decoded_inst[11:7]
      // Next 7 bits	= decoded_inst[31:25]
      // Upper 20 bits  = Sign-extend
      STORE: immediate = {{20{decoded_inst[31]}}, decoded_inst[31:25], decoded_inst[11:7]};

      // ARITH-I:
      // If FUNC3 is SLL or SR:
      //   immediate[4:0]  = decoded_inst[24:20]
      //   immediate[31:5] = 0
      // Else:
      //   Lower 12 bits  = decoded_inst[31:20]
      //   Upper 20 bits  = Sign-extend
      ARITHI:
      immediate =
                 (decoded_inst[`FUNC3] == SLL ||
                  decoded_inst[`FUNC3] == SR)
                 ? {27'b0, decoded_inst[24:20]}
                 : {{20{decoded_inst[31]}}, decoded_inst[31:20]};

      // ARITH-R:
      // No immediate
      ARITHR: immediate = 32'h0;

      // LUI:
      // Upper 20 bits = decoded_inst[31:12]
      // Lower 12 bits = 0
      LUI: immediate = {decoded_inst[31:12], 12'b0};

      // JAL:
      // immediate[20]	= decoded_inst[31]   (sign bit)
      // immediate[19:12] = decoded_inst[19:12]
      // immediate[11]	= decoded_inst[20]
      // immediate[10:1]  = decoded_inst[30:21]
      // immediate[0] 	= 1'b0
      // immediate[31:21] = Sign-extend
      JAL:
      immediate = {
        {12{decoded_inst[31]}}, decoded_inst[19:12], decoded_inst[20], decoded_inst[30:21], 1'b0
      };

      // CUSTOM_0:
      // No immediate
      CUSTOM_0: immediate = 32'h0;

      default: illegal_inst = 1'b1;
    endcase
  end

  ////////////////////////////////////////////////////////////// ID -> EX Register////////////////////////////////////////////////////////////

  // TODO-4:
  // Generate control signals based on opcode
  // alu, lui, jal, jalr, branch, mem_write, mem_to_reg, arithsubtype

  id_ex_reg u_id_ex (
      .clk    (clk),
      .reset  (reset),
      .stall_n(stall_read_i),

      // From ID
      .immediate_i(immediate),
      .immediate_sel_i(
        (decoded_inst[`OPCODE] == JALR)  || (decoded_inst[`OPCODE] == LOAD)  ||
        (decoded_inst[`OPCODE] == ARITHI)
    ),
      .alu_i((decoded_inst[`OPCODE] == ARITHI) || (decoded_inst[`OPCODE] == ARITHR)),
      .lui_i(decoded_inst[`OPCODE] == LUI),
      .jal_i(decoded_inst[`OPCODE] == JAL),
      .jalr_i(decoded_inst[`OPCODE] == JALR),
      .branch_i(decoded_inst[`OPCODE] == BRANCH),
      .mem_write_i(decoded_inst[`OPCODE] == STORE),
      .mem_to_reg_i(decoded_inst[`OPCODE] == LOAD),
      .arithsubtype_i (
        decoded_inst[`SUBTYPE] &&
        !(decoded_inst[`OPCODE] == ARITHI &&
          decoded_inst[`FUNC3] == ADD)
    ),
      .mul_en_i(decoded_inst[`OPCODE] == OP_M && decoded_inst[31:25] == RV32M_FUNCT7 && decoded_inst[`FUNC3] <= F3_MULHU),
      .div_en_i(decoded_inst[`OPCODE] == OP_M && decoded_inst[31:25] == RV32M_FUNCT7 && decoded_inst[`FUNC3] >= F3_DIV),
      .mau_en_i(decoded_inst[`OPCODE] == CUSTOM_0 && decoded_inst[31:25] == RV32M_FUNCT7 && decoded_inst[`FUNC3] != F3_SQRT),
      .sqrt_en_i(decoded_inst[`OPCODE] == CUSTOM_0 && decoded_inst[31:25] == RV32M_FUNCT7 && decoded_inst[`FUNC3] == F3_SQRT),
      .pc_i(inst_fetch_pc),
      .src1_sel_i(decoded_inst[`RS1]),
      .src2_sel_i(decoded_inst[`RS2]),
      .dest_reg_sel_i(decoded_inst[`RD]),
      .alu_op_i(decoded_inst[`FUNC3]),
      .funct7_i(decoded_inst[31:25]),
      .illegal_inst_i(illegal_inst),

      // To EX (WIRES)
      .execute_immediate_o(execute_immediate_w),
      .immediate_sel_o    (immediate_sel_w),
      .alu_o              (alu_w),
      .lui_o              (lui_w),
      .jal_o              (jal_w),
      .jalr_o             (jalr_w),
      .branch_o           (branch_w),
      .mem_write_o        (mem_write_w),
      .mem_to_reg_o       (mem_to_reg_w),
      .arithsubtype_o     (arithsubtype_w),
      .mul_en_o           (mul_en_w),
      .div_en_o           (div_en_w),
      .mau_en_o           (mau_en_w),
      .sqrt_en_o          (sqrt_en_w),
      .pc_o               (pc_w),
      .src1_sel_o         (src1_select_w),
      .src2_sel_o         (src2_select_w),
      .dest_reg_sel_o     (dest_reg_sel_w),
      .alu_op_o           (alu_operation_w),
      .funct7_o           (funct7_w),
      .illegal_inst_o     (illegal_inst_w)
  );
endmodule


////////////////////////////////////////////////////////////// ID -> EX register module////////////////////////////////////////////////////////////

module id_ex_reg (
    input clk,
    input reset,
    input stall_n,

    // Inputs from ID
    input [31:0] immediate_i,
    input        immediate_sel_i,
    input        alu_i,
    input        lui_i,
    input        jal_i,
    input        jalr_i,
    input        branch_i,
    input        mem_write_i,
    input        mem_to_reg_i,
    input        arithsubtype_i,
    input        mul_en_i,
    input        div_en_i,
    input        mau_en_i,
    input        sqrt_en_i,
    input [31:0] pc_i,
    input [ 4:0] src1_sel_i,
    input [ 4:0] src2_sel_i,
    input [ 4:0] dest_reg_sel_i,
    input [ 2:0] alu_op_i,
    input [ 6:0] funct7_i,
    input        illegal_inst_i,

    // Outputs to EX
    output reg [31:0] execute_immediate_o,
    output reg        immediate_sel_o,
    output reg        alu_o,
    output reg        lui_o,
    output reg        jal_o,
    output reg        jalr_o,
    output reg        branch_o,
    output reg        mem_write_o,
    output reg        mem_to_reg_o,
    output reg        arithsubtype_o,
    output reg        mul_en_o,
    output reg        div_en_o,
    output reg        mau_en_o,
    output reg        sqrt_en_o,
    output reg [31:0] pc_o,
    output reg [ 4:0] src1_sel_o,
    output reg [ 4:0] src2_sel_o,
    output reg [ 4:0] dest_reg_sel_o,
    output reg [ 2:0] alu_op_o,
    output reg [ 6:0] funct7_o,
    output reg        illegal_inst_o
);

  always @(posedge clk or negedge reset) begin
    if (!reset) begin
      execute_immediate_o <= 32'h0;
      immediate_sel_o     <= 1'b0;
      alu_o               <= 1'b0;
      lui_o               <= 1'b0;
      jal_o               <= 1'b0;
      jalr_o              <= 1'b0;
      branch_o            <= 1'b0;
      mem_write_o         <= 1'b0;
      mem_to_reg_o        <= 1'b0;
      arithsubtype_o      <= 1'b0;
      mul_en_o            <= 1'b0;
      div_en_o            <= 1'b0;
      mau_en_o            <= 1'b0;
      sqrt_en_o           <= 1'b0;
      pc_o                <= 32'h0;
      src1_sel_o          <= 5'h0;
      src2_sel_o          <= 5'h0;
      dest_reg_sel_o      <= 5'h0;
      alu_op_o            <= 3'h0;
      funct7_o            <= 7'h0;
      illegal_inst_o      <= 1'b0;
    end else if (!stall_n) begin
      execute_immediate_o <= immediate_i;
      immediate_sel_o     <= immediate_sel_i;
      alu_o               <= alu_i;
      lui_o               <= lui_i;
      jal_o               <= jal_i;
      jalr_o              <= jalr_i;
      branch_o            <= branch_i;
      mem_write_o         <= mem_write_i;
      mem_to_reg_o        <= mem_to_reg_i;
      arithsubtype_o      <= arithsubtype_i;
      mul_en_o            <= mul_en_i;
      div_en_o            <= div_en_i;
      mau_en_o            <= mau_en_i;
      sqrt_en_o           <= sqrt_en_i;
      pc_o                <= pc_i;
      src1_sel_o          <= src1_sel_i;
      src2_sel_o          <= src2_sel_i;
      dest_reg_sel_o      <= dest_reg_sel_i;
      alu_op_o            <= alu_op_i;
      funct7_o            <= funct7_i;
      illegal_inst_o      <= illegal_inst_i;
    end
  end

endmodule
