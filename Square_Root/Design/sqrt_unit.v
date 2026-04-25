`timescale 1ns / 1ps

module sqrt_unit (
    input wire clk, rst, start,
    input wire [2:0] funct3,
    input wire [31:0] operand_a, operand_b, // operand_b is ignored for SQRT
    output reg [31:0] result,
    output reg valid
);
    localparam IDLE = 2'd0, CALC = 2'd1, DONE = 2'd2;
    reg [1:0] state;
    reg [4:0] count;
    reg [31:0] d; // Radicand (Input)
    reg [31:0] q; // Root (Output)
    reg [33:0] r; // Remainder

    // Combinational checks for the FSM
    wire [33:0] next_r = {r[31:0], d[31:30]};
    wire [33:0] test_sub = next_r - {1'b0, q, 2'b01};

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; valid <= 0; result <= 0;
            d <= 0; q <= 0; r <= 0; count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 0;
                    if (start) begin
                        d <= operand_a; // Unsigned interpretation
                        q <= 0;
                        r <= 0;
                        count <= 5'd15; // Exactly 16 iterations (15 down to 0)
                        state <= CALC;
                    end
                end
                
                CALC: begin
                    if (!test_sub[33]) begin // If subtraction result is non-negative
                        r <= test_sub;
                        q <= {q[30:0], 1'b1};
                    end else begin
                        r <= next_r;
                        q <= {q[30:0], 1'b0};
                    end
                    d <= {d[29:0], 2'b00}; // Shift data left by 2 bits

                    if (count == 0) state <= DONE;
                    else count <= count - 1;
                end
                
                DONE: begin
                    valid <= 1;
                    result <= q; // Final calculated root
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
