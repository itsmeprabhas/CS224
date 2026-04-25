`timescale 1ns / 1ps

module top_fpga #(
    parameter IMEMSIZE = 4096,
    parameter DMEMSIZE = 4096
)(
    input  wire        clk,        // fast board clock (e.g. 100 MHz)
    input  wire        reset,      // active-low reset
    input  wire [15:0] sw,         // switches
    output reg  [15:0] led,        // mapped to 0x4000_0000
    output wire [7:0]  an,         // 7-segment anodes
    output wire [7:0]  seg         // 7-segment cathodes
);

    wire exception;
    wire [31:0] pc_out;

    ////////////////////////////////////////////////////////////
    // Slow clock generator (clock divider)
    ////////////////////////////////////////////////////////////
    reg [25:0] clk_cnt;
    reg        slow_clk;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            clk_cnt  <= 26'd0;
            slow_clk <= 1'b0;
        end else begin
`ifdef SIMULATION
            if (clk_cnt == 26'd10) begin
`else
            if (clk_cnt == 26'd49_999_999) begin
`endif
                clk_cnt  <= 26'd0;
                slow_clk <= ~slow_clk;   // toggle every 0.5 sec
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end
    end

    ////////////////////////////////////////////////////////////
    // PIPE ↔ MEMORY WIRES
    ////////////////////////////////////////////////////////////
    wire [31:0] inst_mem_read_data;
    wire        inst_mem_is_valid = 1'b1;

    wire [31:0] dmem_read_data_pipe;
    wire        dmem_write_valid = 1'b1;
    wire        dmem_read_valid = 1'b1;

    wire [31:0] inst_mem_address_w;
    wire        inst_mem_is_ready_w;
    wire [31:0] dmem_read_address_w;
    wire        dmem_read_ready_w;
    wire [31:0] dmem_write_address_w;
    wire        dmem_write_ready_w;
    wire [31:0] dmem_write_data_w;
    wire [ 3:0] dmem_write_byte_w;

    ////////////////////////////////////////////////////////////
    // MMIO DECODE & REGISTERS
    ////////////////////////////////////////////////////////////
    
    // Memory map:
    // 0x4000_0000 : LED (Write Only)
    // 0x4000_0004 : SW (Read Only)
    // 0x4000_000C : 7-Segment (Write Only)

    wire is_mmio_write = (dmem_write_address_w[31:28] == 4'h4) && dmem_write_ready_w;
    wire is_mmio_read  = (dmem_read_address_w[31:28]  == 4'h4) && dmem_read_ready_w;
    
    wire we_led  = is_mmio_write && (dmem_write_address_w[11:0] == 12'h000);
    wire we_seg  = is_mmio_write && (dmem_write_address_w[11:0] == 12'h00C);
    
    wire dmem_we_filtered = dmem_write_ready_w && !is_mmio_write;

    // Registers updated on clk
    reg [31:0] sev_seg_data;
    
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            led <= 16'b0;
            sev_seg_data <= 32'b0;
        end else begin
            // LED mirrors switches or MMIO
            if (we_led) begin
                led[15:0] <= dmem_write_data_w[15:0];
            end else begin
                led[15:0] <= sw[15:0];
            end            
            if (we_seg) sev_seg_data <= dmem_write_data_w;
        end
    end

    // Read Logic (Synchronous to match memory)
    reg [31:0] mmio_read_data;
    reg        mmio_read_q;
    wire [31:0] dmem_read_data_mem;
    
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            mmio_read_data <= 32'b0;
            mmio_read_q <= 1'b0;
        end else begin
            mmio_read_q <= is_mmio_read;
            if (is_mmio_read) begin
                if (dmem_read_address_w == 32'h4000_0004)
                    mmio_read_data <= {16'b0, sw};
                else
                    mmio_read_data <= 32'b0;
            end
        end
    end

    // Mux read data
    assign dmem_read_data_pipe = mmio_read_q ? mmio_read_data : dmem_read_data_mem;

    ////////////////////////////////////////////////////////////
    // PERIPHERALS (Running on 100MHz clk)
    ////////////////////////////////////////////////////////////
    
    sev_seg sev_seg_inst (
        .clk(clk),
        .rst(!reset),
        .data_in(sev_seg_data),
        .an(an),
        .seg(seg)
    );

    ////////////////////////////////////////////////////////////
    // PIPELINE CPU (NOW RUNNING AT 100MHz)
    ////////////////////////////////////////////////////////////
    pipe pipe_u (
        .clk                 (clk),
        .reset               (reset),
        .stall               (1'b0),
        .exception           (exception),
        .pc_out              (pc_out),

        .inst_mem_address    (inst_mem_address_w),
        .inst_mem_is_valid   (inst_mem_is_valid),
        .inst_mem_read_data  (inst_mem_read_data),
        .inst_mem_is_ready   (inst_mem_is_ready_w),

        .dmem_read_address   (dmem_read_address_w),
        .dmem_read_ready     (dmem_read_ready_w),
        .dmem_read_data_temp (dmem_read_data_pipe),
        .dmem_read_valid     (dmem_read_valid),
        .dmem_write_address  (dmem_write_address_w),
        .dmem_write_ready    (dmem_write_ready_w),
        .dmem_write_data     (dmem_write_data_w),
        .dmem_write_byte     (dmem_write_byte_w),
        .dmem_write_valid    (dmem_write_valid)
    );

    ////////////////////////////////////////////////////////////
    // INSTRUCTION MEMORY
    ////////////////////////////////////////////////////////////
    instr_mem IMEM (
        .clk   (clk),
        .pc    (inst_mem_address_w),
        .instr (inst_mem_read_data)
    );

    ////////////////////////////////////////////////////////////
    // DATA MEMORY
    ////////////////////////////////////////////////////////////
    data_mem DMEM (
        .clk   (clk),

        .re    (dmem_read_ready_w),
        .raddr (dmem_read_address_w),
        .rdata (dmem_read_data_mem),

        .we    (dmem_we_filtered),
        .waddr (dmem_write_address_w),
        .wdata (dmem_write_data_w),
        .wstrb (dmem_write_byte_w)
    );

endmodule
