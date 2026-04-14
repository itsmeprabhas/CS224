module sqrt_unit (
    input wire clk, rst, start,
    input wire [31:0] radicand,
    output reg [15:0] root,
    output reg done
);
    reg [1:0] state;
    always @(posedge clk) begin
        if (rst) begin state <= 0; done <= 0; end
        else if (start && state == 0) begin state <= 1; done <= 1; end
        else begin state <= 0; done <= 0; end
    end
endmodule
