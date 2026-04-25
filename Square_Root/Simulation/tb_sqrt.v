`timescale 1ns / 1ps

module tb_sqrt();
    reg clk, rst, start;
    reg [2:0] funct3;
    reg [31:0] operand_a, operand_b;
    wire [31:0] result; wire valid;

    sqrt_unit uut (.clk(clk), .rst(rst), .start(start), .funct3(funct3), .operand_a(operand_a), .operand_b(operand_b), .result(result), .valid(valid));

    integer infile, outfile, scan_file;
    reg [31:0] expected_result;

    always #5 clk = ~clk; // 100MHz

    initial begin
        clk = 0; rst = 1; start = 0; funct3 = 0; operand_a = 0; operand_b = 0;

        // Change these to your actual Windows paths!
        infile = $fopen("C:/Users/kasir/Downloads/sqrt/sqrt.srcs/sim_1/imports/prane/input.txt", "r");
        outfile = $fopen("C:/Users/kasir/Downloads/sqrt/sqrt.srcs/sim_1/imports/prane/output.txt", "w");

        #20; rst = 0; #20;

        while (!$feof(infile)) begin
            scan_file = $fscanf(infile, "%b %h %h %h\n", funct3, operand_a, operand_b, expected_result);
            if (scan_file == 4) begin
                start = 1; #10; start = 0; 
                
                // Wait for the FSM to finish its 16 cycles
                wait(valid == 1'b1); #1; 
                
                if (result === expected_result) 
                    $fdisplay(outfile, "PASS | A: %h | Got: %h", operand_a, result);
                else 
                    $fdisplay(outfile, "FAIL | A: %h | Got: %h | Exp: %h", operand_a, result, expected_result);
                #20; 
            end
        end
        $fclose(infile); $fclose(outfile); $finish;
    end
endmodule
