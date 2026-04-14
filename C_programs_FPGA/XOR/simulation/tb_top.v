`timescale 1ns/1ps

module tb_top;
    reg clk;
    reg rst_btn;
    wire [7:0] AN;
    wire [6:0] CA;

    // File descriptor for output.txt
    integer outfile;

    // Instantiate the Top Level
    top_fpga u_top (
        .clk(clk), 
        .rst_btn(rst_btn), 
        .AN(AN), 
        .CA(CA)
    );

    // Clock Generation (100MHz)
    initial begin 
        clk = 0; 
        forever #5 clk = ~clk; 
    end

    // Main Simulation Block
    initial begin
        // 1. Open the output file in write mode ("w")
        outfile = $fopen("output.txt", "w");
        if (outfile == 0) begin
            $display("Error: Could not open output.txt for writing.");
            $finish;
        end

        // 2. Load the C program into Instruction Memory
        $readmemh("input.txt", u_top.imem);
        
        // 3. Reset Sequence
        rst_btn = 0; 
        #20; 
        rst_btn = 1; 
        
        // 4. Let the processor run for enough time to execute the C code
        #5000; 
        
        // 5. Safely close the file and end the simulation
        $fclose(outfile);
        $finish;
    end

    // File Write Logic (The Eavesdropper)
    // We monitor the internal memory write signals of the top_fpga module.
    always @(posedge clk) begin
        // Check if write enable is high AND the address matches your 7-segment MMIO pointer
        if (u_top.dmem_wen && u_top.dmem_addr == 32'h00002000) begin
            // Write the 32-bit data to the text file in hex format
            $fdisplay(outfile, "%08x", u_top.dmem_wdata);
            
            // Optional: Also print to the Vivado Tcl Console so you can see it immediately
            $display("SUCCESS: Wrote %08x to output.txt at time %0t", u_top.dmem_wdata, $time);
        end
    end

endmodule
