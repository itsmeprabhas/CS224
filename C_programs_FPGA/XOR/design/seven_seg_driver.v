module seven_seg_driver (
    input wire clk, rst,
    input wire [31:0] data_in,
    output reg [7:0] anode,
    output reg [6:0] cathode
);
    reg [16:0] refresh;
    always @(posedge clk) if (rst) refresh <= 0; else refresh <= refresh + 1;
    wire [2:0] sel = refresh[16:14];
    reg [3:0] hex;

    always @(*) begin
        case(sel)
            0: begin anode = 8'b11111110; hex = data_in[3:0];   end
            1: begin anode = 8'b11111101; hex = data_in[7:4];   end
            2: begin anode = 8'b11111011; hex = data_in[11:8];  end
            3: begin anode = 8'b11110111; hex = data_in[15:12]; end
            4: begin anode = 8'b11101111; hex = data_in[19:16]; end
            5: begin anode = 8'b11011111; hex = data_in[23:20]; end
            6: begin anode = 8'b10111111; hex = data_in[27:24]; end
            7: begin anode = 8'b01111111; hex = data_in[31:28]; end
        endcase
        case(hex)
            4'h0: cathode = 7'b1000000; 4'h1: cathode = 7'b1111001;
            4'h2: cathode = 7'b0100100; 4'h3: cathode = 7'b0110000;
            4'h4: cathode = 7'b0011001; 4'h5: cathode = 7'b0010010;
            4'h6: cathode = 7'b0000010; 4'h7: cathode = 7'b1111000;
            4'h8: cathode = 7'b0000000; 4'h9: cathode = 7'b0010000;
            4'hA: cathode = 7'b0001000; 4'hB: cathode = 7'b0000011;
            4'hC: cathode = 7'b1000110; 4'hD: cathode = 7'b0100001;
            4'hE: cathode = 7'b0000110; 4'hF: cathode = 7'b0001110;
        endcase
    end
endmodule
