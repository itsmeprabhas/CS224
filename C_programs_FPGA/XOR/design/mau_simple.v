module mau_simple (
    input wire [31:0] operand_a, operand_b,
    input wire [2:0] funct3,
    output reg [31:0] result
);
    wire [31:0] abs_res = (operand_a[31]) ? (~operand_a + 1) : operand_a;
    wire [32:0] diff = {1'b0, operand_a} - {1'b0, operand_b}; 
    wire [31:0] max_res = (~diff[32]) ? operand_a : operand_b;
    wire [31:0] min_res = (~diff[32]) ? operand_b : operand_a;

    always @(*) begin
        case(funct3)
            3'b000: result = abs_res;
            3'b001: result = max_res;
            3'b010: result = min_res;
            default: result = 32'b0;
        endcase
    end
endmodule
