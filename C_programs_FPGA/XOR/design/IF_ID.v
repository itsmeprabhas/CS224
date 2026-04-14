`include "opcode.vh"
module IF_ID_Stage (
    input wire clk, rst, stall,
    input wire [31:0] next_pc, fetch_inst,
    output reg [31:0] if_id_pc, if_id_inst, pc_reg
);
    always @(posedge clk) if (rst) pc_reg <= 0; else if (!stall) pc_reg <= next_pc;
    always @(posedge clk) begin
        if (rst) begin if_id_pc <= 0; if_id_inst <= 32'h00000013; end
        else if (!stall) begin if_id_pc <= pc_reg; if_id_inst <= fetch_inst; end
    end
endmodule
