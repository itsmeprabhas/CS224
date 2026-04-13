`timescale 1ns / 1ps

module multiplier (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [2:0] funct3,        // Decodes MUL, MULH, MULHU, MULHSU
    input wire [31:0] operand_a,    // rs1
    input wire [31:0] operand_b,    // rs2
    output reg [63:0] product,      // Full 64-bit result
    output reg valid                // Result ready flag
);

    reg [1:0] state;
    
    // 33-bit registers to handle the extra sign bit for unsigned/signed math
    reg signed [32:0] a_reg, b_reg;
    
    // Force Vivado to use DSP slices for this register
    (* use_dsp = "yes" *) reg signed [65:0] prod_reg;

    // Decode which operands should be treated as signed
    wire a_is_signed = (funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010);
    wire b_is_signed = (funct3 == 3'b000 || funct3 == 3'b001);

    // Append the 31st bit if signed, append 1'b0 if unsigned
    wire [32:0] a_ext = {(a_is_signed & operand_a[31]), operand_a};
    wire [32:0] b_ext = {(b_is_signed & operand_b[31]), operand_b};

    always @(posedge clk) begin
        if (rst) begin
            a_reg    <= 0;
            b_reg    <= 0;
            prod_reg <= 0;
            product  <= 0;
            valid    <= 0;
            state    <= 0;
        end else begin
            case (state)
                2'd0: begin
                    valid <= 0;
                    if (start) begin
                        // Stage 1: Latch extended inputs
                        a_reg <= $signed(a_ext);
                        b_reg <= $signed(b_ext);
                        state <= 2'd1;
                    end
                end
                
                2'd1: begin
                    // Stage 2: Compute multiplication
                    prod_reg <= a_reg * b_reg; 
                    state    <= 2'd2;
                end
                
                2'd2: begin
                    // Stage 3: Latch 64-bit result and assert valid
                    product <= prod_reg[63:0];
                    valid   <= 1;
                    state   <= 2'd0; 
                end
                
                default: state <= 2'd0;
            endcase
        end
    end
endmodule
