module top_fpga (
    input wire clk,             
    input wire rst_btn,         
    output wire [7:0] AN,       
    output wire [6:0] CA        
);
    wire rst = ~rst_btn;

    wire stall_sig, ex_valid, is_st, dmem_wen, reg_wen;
    wire [31:0] pc_out, inst_out, ex_res, st_data, dmem_addr, dmem_wdata, reg_wdata;
    wire [4:0]  reg_waddr;

    // ==========================================
    // 1. HARDCODED INSTRUCTION MEMORY
    // ==========================================
    reg [31:0] imem [0:1023];
    initial begin
        imem[0] = 32'h0020c233; // xor x4, x1, x2  (Calculates: ABCD ^ 1234)
        imem[1] = 32'h0041a023; // sw  x4, 0(x3)   (Writes result to 7-Segment address)
        imem[2] = 32'h0000006f; // j pc            (Infinite loop)
    end
    wire [31:0] fetch_inst = imem[pc_out >> 2];

    // ==========================================
    // 2. HARDCODED REGISTER FILE
    // ==========================================
    wire [4:0] rs1 = inst_out[19:15];
    wire [4:0] rs2 = inst_out[24:20];
    wire [31:0] reg_rdata1, reg_rdata2;
    
    reg [31:0] regs [0:31];
    integer i;
    initial begin
        for(i=0; i<32; i=i+1) regs[i] = 0;
        // Injecting the C-code variables directly into hardware registers!
        regs[1] = 32'h0000ABCD; // Operand A
        regs[2] = 32'h00001234; // Operand B
        regs[3] = 32'h00002000; // 7-Segment MMIO Target Address
    end

    always @(posedge clk) begin
        if (reg_wen && reg_waddr != 0) regs[reg_waddr] <= reg_wdata;
    end

    assign reg_rdata1 = (rs1 == 0) ? 32'b0 : regs[rs1];
    assign reg_rdata2 = (rs2 == 0) ? 32'b0 : regs[rs2];

    // ==========================================
    // 3. PIPELINE INSTANTIATIONS
    // ==========================================
    IF_ID_Stage u_if (.clk(clk), .rst(rst), .stall(stall_sig), .next_pc(pc_out + 4), .fetch_inst(fetch_inst), .if_id_pc(), .if_id_inst(inst_out), .pc_reg(pc_out));
    EX_Stage u_ex (.clk(clk), .rst(rst), .op_a(reg_rdata1), .op_b(reg_rdata2), .opcode(inst_out[6:0]), .funct3(inst_out[14:12]), .funct7(inst_out[31:25]), .stall(stall_sig), .ex_result(ex_res), .valid_out(ex_valid), .is_store(is_st), .store_data(st_data));
    WB_Stage u_wb (.clk(clk), .valid_in(ex_valid), .ex_res(ex_res), .rd_addr(inst_out[11:7]), .is_store(is_st), .store_data(st_data), .reg_waddr(reg_waddr), .reg_wdata(reg_wdata), .reg_wen(reg_wen), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_wen(dmem_wen));

    // ==========================================
    // 4. MEMORY MAPPED I/O
    // ==========================================
    reg [31:0] seg_reg;
    always @(posedge clk) begin
        if (rst) seg_reg <= 32'b0;
        else if (dmem_wen && dmem_addr == 32'h00002000) seg_reg <= dmem_wdata;
    end

    seven_seg_driver u_seg (.clk(clk), .rst(rst), .data_in(seg_reg), .anode(AN), .cathode(CA));
endmodule
