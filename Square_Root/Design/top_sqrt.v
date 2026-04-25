`timescale 1ns / 1ps

module top_sqrt(
    input clk, reset_btn, start_btn,        
    input [15:0] sw,      
    output [7:0] an, output [6:0] seg, output done_led
);
    wire sys_reset = ~reset_btn; 
    
    // We treat the 16 switches as an unsigned integer for SQRT
    wire [31:0] rs1_data = {16'b0, sw[15:0]};   
    
    // Pulse Generator to trigger the FSM exactly once per button press
    reg btn_sync_0, btn_sync_1, btn_prev; 
    always @(posedge clk) begin 
        btn_sync_0 <= start_btn; 
        btn_sync_1 <= btn_sync_0; 
        btn_prev <= btn_sync_1; 
    end
    wire start_pulse = (btn_sync_1 == 1'b1 && btn_prev == 1'b0); 

    // Instantiate the SQRT unit
    wire [31:0] sqrt_result;
    wire sqrt_valid;
    
    sqrt_unit my_sqrt (
        .clk(clk), 
        .rst(sys_reset), 
        .start(start_pulse), 
        .funct3(3'b011), // F3_SQRT
        .operand_a(rs1_data), 
        .operand_b(32'b0), // Ignored
        .result(sqrt_result), 
        .valid(sqrt_valid)
    );

    // Turn on the LED when the 16 cycles are complete
    assign done_led = sqrt_valid;

    // Display Format: [Input (16-bit)] [Result (16-bit)]
    wire [31:0] display_data = {sw[15:0], sqrt_result[15:0]};
    
    seven_seg_driver disp (
        .clk(clk), 
        .reset(sys_reset), 
        .data_in(display_data), 
        .an(an), 
        .seg(seg)
    );

endmodule
