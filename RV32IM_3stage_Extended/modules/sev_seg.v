`timescale 1ns / 1ps

module sev_seg (
    input  wire        clk,      // 100 MHz clock
    input  wire        rst,
    input  wire [31:0] data_in,  // 32-bit hex data to display
    output reg  [7:0]  an,       // Anodes
    output reg  [7:0]  seg       // Cathodes (Active Low)
);

    // Refresh rate divider
    // For 100MHz, divide by 2^17 gives ~760Hz refresh rate across 8 digits
    reg [16:0] refresh_counter;
    always @(posedge clk) begin
        if (rst)
            refresh_counter <= 0;
        else
            refresh_counter <= refresh_counter + 1;
    end
    
    wire [2:0] digit_sel = refresh_counter[16:14];
    reg  [3:0] hex_digit;
    
    // Select digit
    always @(*) begin
        case(digit_sel)
            3'd0: hex_digit = data_in[3:0];
            3'd1: hex_digit = data_in[7:4];
            3'd2: hex_digit = data_in[11:8];
            3'd3: hex_digit = data_in[15:12];
            3'd4: hex_digit = data_in[19:16];
            3'd5: hex_digit = data_in[23:20];
            3'd6: hex_digit = data_in[27:24];
            3'd7: hex_digit = data_in[31:28];
        endcase
    end
    
    // Decode digit to 7-segment (Active Low)
    always @(*) begin
        case(hex_digit)
            4'h0: seg = 8'b11000000;
            4'h1: seg = 8'b11111001;
            4'h2: seg = 8'b10100100;
            4'h3: seg = 8'b10110000;
            4'h4: seg = 8'b10011001;
            4'h5: seg = 8'b10010010;
            4'h6: seg = 8'b10000010;
            4'h7: seg = 8'b11111000;
            4'h8: seg = 8'b10000000;
            4'h9: seg = 8'b10010000;
            4'hA: seg = 8'b10001000;
            4'hB: seg = 8'b10000011;
            4'hC: seg = 8'b11000110;
            4'hD: seg = 8'b10100001;
            4'hE: seg = 8'b10000110;
            4'hF: seg = 8'b10001110;
            default: seg = 8'b11111111;
        endcase
    end
    
    // Enable anode (Active Low)
    always @(*) begin
        an = 8'b11111111;
        an[digit_sel] = 1'b0;
    end

endmodule
