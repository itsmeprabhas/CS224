`timescale 1ns / 1ps

module seven_seg_driver(
    input clk,
    input reset,
    input [31:0] data_in, 
    output reg [7:0] an,  
    output reg [6:0] seg  
);

    reg [16:0] refresh_counter;
    always @(posedge clk or posedge reset) begin
        if (reset) refresh_counter <= 0;
        else refresh_counter <= refresh_counter + 1;
    end
    
    wire [2:0] digit_select = refresh_counter[16:14]; 
    reg [3:0] current_hex;

    always @(*) begin
        case(digit_select)
            3'b000: begin an = 8'b11111110; current_hex = data_in[3:0];   end 
            3'b001: begin an = 8'b11111101; current_hex = data_in[7:4];   end 
            3'b010: begin an = 8'b11111011; current_hex = data_in[11:8];  end 
            3'b011: begin an = 8'b11110111; current_hex = data_in[15:12]; end 
            3'b100: begin an = 8'b11101111; current_hex = data_in[19:16]; end 
            3'b101: begin an = 8'b11011111; current_hex = data_in[23:20]; end 
            3'b110: begin an = 8'b10111111; current_hex = data_in[27:24]; end 
            3'b111: begin an = 8'b01111111; current_hex = data_in[31:28]; end 
        endcase
    end

    always @(*) begin
        case(current_hex)
            4'h0: seg = 7'b1000000; 4'h1: seg = 7'b1111001; 
            4'h2: seg = 7'b0100100; 4'h3: seg = 7'b0110000; 
            4'h4: seg = 7'b0011001; 4'h5: seg = 7'b0010010; 
            4'h6: seg = 7'b0000010; 4'h7: seg = 7'b1111000; 
            4'h8: seg = 7'b0000000; 4'h9: seg = 7'b0010000; 
            4'hA: seg = 7'b0001000; 4'hB: seg = 7'b0000011; 
            4'hC: seg = 7'b1000110; 4'hD: seg = 7'b0100001; 
            4'hE: seg = 7'b0000110; 4'hF: seg = 7'b0001110; 
            default: seg = 7'b1111111; 
        endcase
    end
endmodule
