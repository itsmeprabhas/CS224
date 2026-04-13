`timescale 1ns / 1ps

module top_mau_demo(
    input clk, reset_btn,      
    input btnU, btnD, btnL, btnR,    
    input [15:0] sw,      
    output [7:0] an,      
    output [6:0] seg      
);
    wire sys_reset = ~reset_btn; 

    wire [31:0] rs1_data = {{24{sw[7]}}, sw[7:0]};   
    wire [31:0] rs2_data = {{24{sw[15]}}, sw[15:8]}; 
    
    wire [31:0] mau_simple_result, log2_result; reg [31:0] final_result;
    
    reg [2:0] current_funct3;
    always @(*) begin
        if (btnU)      current_funct3 = 3'b001; // MAX
        else if (btnD) current_funct3 = 3'b010; // MIN
        else           current_funct3 = 3'b000; // ABS
    end

    mau_simple my_mau_basic (.funct3(current_funct3), .operand_a(rs1_data), .operand_b(rs2_data), .result(mau_simple_result));
    clz_unit my_log2 (.operand_a(rs1_data), .log2_result(log2_result));

    always @(*) begin
        if (btnR) final_result = log2_result;
        else      final_result = mau_simple_result;
    end

    wire [31:0] display_data = {sw[15:8], sw[7:0], final_result[15:0]};
    seven_seg_driver display_unit (.clk(clk), .reset(sys_reset), .data_in(display_data), .an(an), .seg(seg));
endmodule
