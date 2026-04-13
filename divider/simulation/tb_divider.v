`timescale 1ns / 1ps

module tb_divider();

    reg clk;
    reg rst;
    reg [31:0] operand_a;
    reg [31:0] operand_b;
    reg [1:0] div_op;
    reg start;

    wire [31:0] quotient;
    wire [31:0] remainder;
    wire valid;
    wire busy;

    // Instantiate the divider module
    divider uut (
        .clk(clk),
        .rst(rst),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .div_op(div_op),
        .start(start),
        .quotient(quotient),
        .remainder(remainder),
        .valid(valid),
        .busy(busy)
    );

    // Generate 100MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    integer file;
    integer scan_count;
    reg [31:0] a_in, b_in, exp_in;
    reg [1:0]  op_in;

    initial begin
        // Init Inputs
        rst = 1;
        operand_a = 0;
        operand_b = 0;
        div_op = 0;
        start = 0;

        // Reset Sequence
        #20;
        rst = 0;
        #10;

        // Open input file
        file = $fopen("input.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open input.txt");
            $finish;
        end

        // Read and Execute File Values
        scan_count = $fscanf(file, "%h %h %h %h", a_in, b_in, op_in, exp_in);
        while (scan_count == 4) begin
            
            @(negedge clk);
            operand_a = a_in;
            operand_b = b_in;
            div_op    = op_in;
            start     = 1;
            
            @(negedge clk);
            start = 0;
            
            // Wait for the divider to finish
            while (!valid) @(negedge clk);
            
            // Select proper result based on operator
            // Verify Output
            if (((op_in == 2'd2 || op_in == 2'd3) ? remainder : quotient) !== exp_in) begin
                $display("========================================");
                $display("ERROR!");
                $display("A=0x%08X B=0x%08X OP=%0d", a_in, b_in, op_in);
                $display("Expected : 0x%08X", exp_in);
                $display("Got      : 0x%08X (Q:0x%08X R:0x%08X)", ((op_in == 2'd2 || op_in == 2'd3) ? remainder : quotient), quotient, remainder);
                $display("========================================");
                $finish;
            end else begin
                $display("PASS: A=0x%08X B=0x%08X OP=%0d Result=0x%08X (Q:0x%08X R:0x%08X)", a_in, b_in, op_in, ((op_in == 2'd2 || op_in == 2'd3) ? remainder : quotient), quotient, remainder);
            end
            
            @(negedge clk);
            scan_count = $fscanf(file, "%h %h %h %h", a_in, b_in, op_in, exp_in);
        end

        $fclose(file);
        $display("All tests from input.txt passed Successfully!");
        $finish;
    end

endmodule
