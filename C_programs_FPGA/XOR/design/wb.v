module WB_Stage (
    input wire clk, valid_in, is_store,
    input wire [31:0] ex_res, store_data,
    input wire [4:0] rd_addr,
    output reg reg_wen, dmem_wen,
    output reg [4:0] reg_waddr,
    output reg [31:0] reg_wdata, dmem_addr, dmem_wdata
);
    always @(posedge clk) begin
        reg_wen <= 0; dmem_wen <= 0;
        if (valid_in) begin
            if (is_store) begin dmem_addr <= ex_res; dmem_wdata <= store_data; dmem_wen <= 1; end
            else if (rd_addr != 0) begin reg_waddr <= rd_addr; reg_wdata <= ex_res; reg_wen <= 1; end
        end
    end
endmodule
