`timescale 1ns / 1ps

module divider (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [1:0]  div_op,      // 00=DIV, 01=DIVU, 10=REM, 11=REMU
    input  wire        start,
    
    output reg  [31:0] quotient,
    output reg  [31:0] remainder,
    output reg         valid,
    output wire        busy
);

    localparam IDLE    = 1'b0;
    localparam COMPUTE = 1'b1;
    
    reg state;
    reg [5:0] counter;
    
    // Operation decode
    wire is_signed = (div_op == 2'b00) || (div_op == 2'b10);
    
    reg sign_quot, sign_rem, div_by_zero, overflow;
    reg [31:0] A_orig;
    
    reg [31:0] P;
    reg [31:0] A;
    reg [31:0] B;
    
    assign busy = (state != IDLE) || (start && !valid);
    
    wire [31:0] P_shift = {P[30:0], A[31]};
    wire [31:0] A_shift = {A[30:0], 1'b0};
    
    wire [31:0] next_P = (P_shift >= B) ? (P_shift - B) : P_shift;
    wire [31:0] next_A = (P_shift >= B) ? (A_shift | 32'd1) : A_shift;
    
    // Final result adjustments
    wire [31:0] fin_Q = sign_quot ? (~next_A + 1) : next_A;
    wire [31:0] fin_R = sign_rem  ? (~next_P + 1) : next_P;

    // Cleanly check overflow conditions
    wire is_a_min   = (operand_a == 32'h80000000);
    wire is_b_neg_1 = (operand_b == 32'hFFFFFFFF);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            valid <= 0;
            quotient <= 0;
            remainder <= 0;
            P <= 0;
            A <= 0;
            B <= 0;
            counter <= 0;
            sign_quot <= 0;
            sign_rem <= 0;
            div_by_zero <= 0;
            overflow <= 0;
            A_orig <= 0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 0;
                    if (start) begin
                        sign_quot <= is_signed && (operand_a[31] ^ operand_b[31]);
                        sign_rem  <= is_signed && operand_a[31];
                        
                        A <= (is_signed && operand_a[31]) ? (~operand_a + 1) : operand_a;
                        B <= (is_signed && operand_b[31]) ? (~operand_b + 1) : operand_b;
                        
                        P <= 32'd0;
                        counter <= 6'd32;
                        
                        div_by_zero <= (operand_b == 32'd0);
                        overflow    <= (is_signed && is_a_min && is_b_neg_1);
                        A_orig      <= operand_a; // Stored to serve edge cases correctly (0/0 and generic fast tracking)
                        
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    P <= next_P;
                    A <= next_A;
                    
                    if (counter == 1) begin
                        valid <= 1;
                        if (div_by_zero) begin
                            // Fast override for RISC-V Div by Zero semantics
                            quotient  <= 32'hFFFFFFFF;
                            remainder <= A_orig;
                        end else if (overflow) begin
                            // Override for Overflow edge case perfectly
                            quotient  <= 32'h80000000;
                            remainder <= 32'd0;
                        end else begin
                            quotient  <= fin_Q;
                            remainder <= fin_R;
                        end
                        state <= IDLE;
                    end else begin
                        counter <= counter - 1;
                    end
                end
            endcase
        end
    end

endmodule
