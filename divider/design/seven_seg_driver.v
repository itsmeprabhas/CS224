`timescale 1ns / 1ps

module seven_seg_driver (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] display_value,
    
    output reg  [7:0]  anodes,
    output reg  [7:0]  cathodes // includes DP
);

    // Clock divider for multiplexing (target ~1kHz refresh rate)
    reg [16:0] counter;
    reg [2:0]  digit_sel;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            digit_sel <= 0;
        end else begin
            if (counter == 100000 - 1) begin
                counter <= 0;
                digit_sel <= digit_sel + 1;
            end else begin
                counter <= counter + 1;
            end
        end
    end
    
    // Multiplexer for 4-bit nibble
    reg [3:0] current_nibble;
    always @(*) begin
        case (digit_sel)
            3'd0: current_nibble = display_value[3:0];
            3'd1: current_nibble = display_value[7:4];
            3'd2: current_nibble = display_value[11:8];
            3'd3: current_nibble = display_value[15:12];
            3'd4: current_nibble = display_value[19:16];
            3'd5: current_nibble = display_value[23:20];
            3'd6: current_nibble = display_value[27:24];
            3'd7: current_nibble = display_value[31:28];
            default: current_nibble = 4'h0;
        endcase
    end
    
    // Hex to 7-seg decoder (active low for cathodes)
    always @(*) begin
        case (current_nibble)
            4'h0: cathodes = 8'hc0;
            4'h1: cathodes = 8'hf9;
            4'h2: cathodes = 8'ha4;
            4'h3: cathodes = 8'hb0;
            4'h4: cathodes = 8'h99;
            4'h5: cathodes = 8'h92;
            4'h6: cathodes = 8'h82;
            4'h7: cathodes = 8'hf8;
            4'h8: cathodes = 8'h80;
            4'h9: cathodes = 8'h90;
            4'ha: cathodes = 8'h88;
            4'hb: cathodes = 8'h83;
            4'hc: cathodes = 8'hc6;
            4'hd: cathodes = 8'ha1;
            4'he: cathodes = 8'h86;
            4'hf: cathodes = 8'h8e;
            default: cathodes = 8'hff;
        endcase
    end
    
    // Anode activation (active low)
    always @(*) begin
        case (digit_sel)
            3'd0: anodes = 8'b11111110;
            3'd1: anodes = 8'b11111101;
            3'd2: anodes = 8'b11111011;
            3'd3: anodes = 8'b11110111;
            3'd4: anodes = 8'b11101111;
            3'd5: anodes = 8'b11011111;
            3'd6: anodes = 8'b10111111;
            3'd7: anodes = 8'b01111111;
            default: anodes = 8'hff;
        endcase
    end

endmodule
