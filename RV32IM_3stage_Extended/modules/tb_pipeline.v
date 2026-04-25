`timescale 1ns / 1ps

module tb_pipeline;

    // Clock and Reset
    reg clk;
    reg reset;

    // IMEM Wires
    wire [31:0] inst_mem_address;
    wire [31:0] inst_mem_read_data;
    wire        inst_mem_is_ready;

    // DMEM Wires
    wire [31:0] dmem_read_address;
    wire        dmem_read_ready;
    wire [31:0] dmem_read_data;
    wire [31:0] dmem_write_address;
    wire        dmem_write_ready;
    wire [31:0] dmem_write_data;
    wire [ 3:0] dmem_write_byte;

    // Pipeline Outputs
    wire        exception;
    wire [31:0] pc_out;

    // ---------------------------------------------------------
    // 1. Instantiate the CPU Pipeline
    // ---------------------------------------------------------
    pipe uut (
        .clk                 (clk),
        .reset               (reset),
        .stall               (1'b0),
        .exception           (exception),
        .pc_out              (pc_out),

        .inst_mem_address    (inst_mem_address),
        .inst_mem_is_valid   (1'b1), // Always valid for block RAM
        .inst_mem_read_data  (inst_mem_read_data),
        .inst_mem_is_ready   (inst_mem_is_ready),

        .dmem_read_address   (dmem_read_address),
        .dmem_read_ready     (dmem_read_ready),
        .dmem_read_data_temp (dmem_read_data),
        .dmem_read_valid     (1'b1), // Always valid for block RAM
        .dmem_write_address  (dmem_write_address),
        .dmem_write_ready    (dmem_write_ready),
        .dmem_write_data     (dmem_write_data),
        .dmem_write_byte     (dmem_write_byte),
        .dmem_write_valid    (1'b1)
    );

    // ---------------------------------------------------------
    // 2. Instantiate Instruction Memory
    // ---------------------------------------------------------
    instr_mem IMEM (
        .clk   (clk),
        .pc    (inst_mem_address),
        .instr (inst_mem_read_data)
    );

    // ---------------------------------------------------------
    // 3. Instantiate Data Memory
    // ---------------------------------------------------------
    data_mem DMEM (
        .clk   (clk),
        .re    (dmem_read_ready),
        .raddr (dmem_read_address),
        .rdata (dmem_read_data),
        .we    (dmem_write_ready),
        .waddr (dmem_write_address),
        .wdata (dmem_write_data),
        .wstrb (dmem_write_byte)
    );

    // ---------------------------------------------------------
    // Clock Generation (100 MHz)
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // ---------------------------------------------------------
    // Test Sequence
    // ---------------------------------------------------------
    initial begin
        // Generate waveform file for Vivado/Icarus
        $dumpfile("pipeline_tb.vcd");
        $dumpvars(0, tb_pipeline);

        // Apply Active-Low Reset
        reset = 0;
        #20;
        reset = 1;

        // Allow enough time for multi-cycle operations to finish
        // The divider takes 32 cycles, SQRT takes 16 cycles.
        #2000;
        
        $display("Simulation timeout reached.");
        $finish;
    end

endmodule