`timescale 1ns / 1ps

module tb_multiplier();

    reg clk;
    reg rst;
    reg start;
    reg [2:0] funct3;
    reg [31:0] operand_a;
    reg [31:0] operand_b;

    wire [63:0] product;
    wire valid;

    integer infile, outfile, scan_file;
    reg [63:0] expected_result;

    multiplier uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .funct3(funct3),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .product(product),
        .valid(valid)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; start = 0; funct3 = 0; operand_a = 0; operand_b = 0;

        // NOTE: Replace these with the absolute paths on your PC to avoid Vivado I/O errors.
        infile = $fopen("input.txt", "r");
        outfile = $fopen("output.txt", "w");

        if (infile == 0) begin
            $display("ERROR: Could not open input.txt!");
            $finish;
        end

        #100; rst = 0; #20;

        $fdisplay(outfile, "A(Hex)   | B(Hex)   | F3  | Hardware Product(Hex)    | Expected Product(Hex)    | Status");
        $fdisplay(outfile, "------------------------------------------------------------------------------------------");

        while (!$feof(infile)) begin
            scan_file = $fscanf(infile, "%h %h %b %h\n", operand_a, operand_b, funct3, expected_result);
            if (scan_file == 4) begin
                start = 1; #10; start = 0;
                wait(valid == 1'b1);
                
                if (product === expected_result) begin
                    $fdisplay(outfile, "%h | %h | %b | %h | %h | PASS", operand_a, operand_b, funct3, product, expected_result);
                end else begin
                    $fdisplay(outfile, "%h | %h | %b | %h | %h | FAIL", operand_a, operand_b, funct3, product, expected_result);
                    $display("FAIL: A=%h, B=%h, F3=%b. Got %h, Expected %h", operand_a, operand_b, funct3, product, expected_result);
                end
                #10;
            end
        end
        $fclose(infile);
        $fclose(outfile);
        $finish;
    end
endmodule
