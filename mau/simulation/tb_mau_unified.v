`timescale 1ns / 1ps

module tb_mau_unified();
    reg [2:0] funct3;
    reg [31:0] operand_a, operand_b;
    
    wire [31:0] mau_simple_res, log2_res;
    reg [31:0] actual_result;

    integer infile, outfile, scan_file;
    reg [31:0] expected_result;

    // Instantiate both MAU modules
    mau_simple uut_mau (.funct3(funct3), .operand_a(operand_a), .operand_b(operand_b), .result(mau_simple_res));
    clz_unit uut_clz (.operand_a(operand_a), .log2_result(log2_res));

    // Mux the output just like the pipeline does
    always @(*) begin
        if (funct3 == 3'b100) actual_result = log2_res;
        else actual_result = mau_simple_res;
    end

    initial begin
        // --- CHANGE THESE TO YOUR ABSOLUTE PATHS ---
        infile = $fopen("input.txt", "r");
        outfile = $fopen("output.txt", "w");

        if (infile == 0) begin
            $display("ERROR: Cannot open input.txt! Fix the path.");
            $finish;
        end

        $fdisplay(outfile, "F3  | A (Hex)  | B (Hex)  | Got (Hex)  | Expected (Hex) | Status");
        $fdisplay(outfile, "------------------------------------------------------------------");

        while (!$feof(infile)) begin
            // Format: Funct3(Binary) OpA(Hex) OpB(Hex) Expected(Hex)
            scan_file = $fscanf(infile, "%b %h %h %h\n", funct3, operand_a, operand_b, expected_result);
            
            if (scan_file == 4) begin
                #10; // Wait for combinational logic to resolve
                
                if (actual_result === expected_result)
                    $fdisplay(outfile, "%b | %h | %h | %h | %h | PASS", funct3, operand_a, operand_b, actual_result, expected_result);
                else begin
                    $fdisplay(outfile, "%b | %h | %h | %h | %h | FAIL", funct3, operand_a, operand_b, actual_result, expected_result);
                    $display("FAIL: F3=%b, A=%h, B=%h. Got %h, Exp %h", funct3, operand_a, operand_b, actual_result, expected_result);
                end
            end
        end
        
        $display("--- Verification Complete. Check output.txt ---");
        $fclose(infile);
        $fclose(outfile);
        $finish;
    end
endmodule
