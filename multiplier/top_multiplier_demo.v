`timescale 1ns / 1ps

module top_multiplier_demo(
    input clk,            
    input reset_btn,      
    input start_btn,      
    input [15:0] sw,      
    output [7:0] an,      
    output [6:0] seg,     
    output done_led       
);

    // Active-Low Reset fix for Nexys A7
    wire sys_reset = ~reset_btn; 

    // --- NEW SIGN-EXTENSION LOGIC ---
    // If the 8th switch is UP (1), it pads with 24 ones (making it a negative number).
    // If the 8th switch is DOWN (0), it pads with 24 zeros (making it a positive number).
    wire [31:0] rs1_data = {{24{sw[7]}}, sw[7:0]};   
    wire [31:0] rs2_data = {{24{sw[15]}}, sw[15:8]};  
    
    wire [63:0] mul_result_64;
    
    // Button edge detector for the start signal
    reg btn_sync_0, btn_sync_1, btn_prev;
    wire start_pulse;
    
    always @(posedge clk) begin
        btn_sync_0 <= start_btn;
        btn_sync_1 <= btn_sync_0;
        btn_prev   <= btn_sync_1;
    end
    assign start_pulse = (btn_sync_1 == 1'b1 && btn_prev == 1'b0); 

    // Instantiate Multiplier
    multiplier my_mul_unit (
        .clk(clk),
        .rst(sys_reset),
        .start(start_pulse),
        .funct3(3'b000),      // Standard MUL (Signed x Signed)
        .operand_a(rs1_data),
        .operand_b(rs2_data),
        .product(mul_result_64),
        .valid(done_led)
    );

    // Format display: [Operand B (8-bit)] [Operand A (8-bit)] [Lower 16 bits of Result]
    wire [31:0] display_data = {sw[15:8], sw[7:0], mul_result_64[15:0]};

    // Instantiate Display Driver
    seven_seg_driver display_unit (
        .clk(clk),
        .reset(sys_reset),
        .data_in(display_data),
        .an(an),
        .seg(seg)
    );
endmodule
