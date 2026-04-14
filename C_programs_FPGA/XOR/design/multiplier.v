module multiplier (
    input wire clk, rst, start,
    input wire [31:0] operand_a, operand_b,
    output reg [63:0] product,
    output reg valid
);
    reg [1:0] state;
    always @(posedge clk) begin
        if (rst) begin state <= 0; valid <= 0; product <= 0; end
        else if (start && state == 0) begin state <= 1; valid <= 1; product <= $signed(operand_a) * $signed(operand_b); end // Simplified 1-cycle for stub
        else if (state > 0 && state < 3) state <= state + 1;
        else begin state <= 0; valid <= 0; end
    end
endmodule
