`timescale 1ns / 1ps

module divider (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,          // pulsed or held request
    input  wire [2:0]  funct3,
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    output reg  [31:0] result,
    output reg         valid,
    output reg         busy            // NEW: 1 = divider cannot accept a new request
);

    `include "opcode.vh"
    wire is_signed = (funct3 == F3_DIV || funct3 == F3_REM);
    wire is_rem    = (funct3 == F3_REM || funct3 == F3_REMU);

    // ---- State machine ----
    localparam IDLE = 2'd0, DIVIDE = 2'd1, DONE = 2'd2;
    reg [1:0] state;
    reg [5:0] count;

    // ---- Internal registers ----
    reg [31:0] Q, M, A;
    reg        sign_q, sign_r, div_by_zero, overflow;

    // ---- Absolute values & subtract result ----
    wire [31:0] abs_a = (is_signed & operand_a[31]) ? (~operand_a + 1) : operand_a;
    wire [31:0] abs_b = (is_signed & operand_b[31]) ? (~operand_b + 1) : operand_b;
    wire [32:0] sub_res = {1'b0, A[30:0], Q[31]} - {1'b0, M};

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            valid <= 1'b0;
            busy  <= 1'b0;
            result <= 32'd0;
            Q <= 32'd0;
            M <= 32'd0;
            A <= 32'd0;
            count <= 6'd0;
        end else begin
            // ---- Default values ----
            valid <= 1'b0;          // result is only valid for one cycle (see DONE)

            // ---- Busy flag is purely combinational: high when not IDLE ----
            // (registered here for timing; could also be a continuous assignment)
            busy <= (state != IDLE);

            case (state)

                IDLE: begin
                    if (start) begin   // only accepted when not busy
                        // Load operands
                        Q           <= abs_a;
                        M           <= abs_b;
                        A           <= 32'd0;
                        count       <= 6'd32;
                        div_by_zero <= (operand_b == 32'd0);
                        overflow    <= (is_signed && operand_a == 32'h8000_0000 &&
                                                       operand_b == 32'hFFFF_FFFF);
                        sign_q      <= is_signed & (operand_a[31] ^ operand_b[31]);
                        sign_r      <= is_signed & operand_a[31];
                        state       <= DIVIDE;
                    end
                end

                DIVIDE: begin
                    if (count == 0)
                        state <= DONE;
                    else begin
                        if (sub_res[32]) begin
                            A <= {A[30:0], Q[31]};
                            Q <= {Q[30:0], 1'b0};
                        end else begin
                            A <= sub_res[31:0];
                            Q <= {Q[30:0], 1'b1};
                        end
                        count <= count - 1;
                    end
                end

                DONE: begin
                    valid <= 1'b1;                     // result ready for ONE cycle
                    if (div_by_zero)
                        result <= is_rem ? operand_a : 32'hFFFF_FFFF;
                    else if (overflow)
                        result <= is_rem ? 32'b0 : 32'h8000_0000;
                    else begin
                        if (is_rem)
                            result <= sign_r ? (~A + 1) : A;
                        else
                            result <= sign_q ? (~Q + 1) : Q;
                    end
                    // Automatically return to IDLE next cycle – no handshake needed.
                    // The pipeline must capture 'result' while valid is high.
                    state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule
