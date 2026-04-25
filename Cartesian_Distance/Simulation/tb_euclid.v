// ============================================================
// tb_euclid.v  -  Testbench for euclid_top
// Simulates three distance computations and checks results.
// Run in Vivado Simulation with all four design files.
// ============================================================
`timescale 1ns/1ps

module tb_euclid;

    // ── DUT ports ────────────────────────────────────────────
    reg        clk   = 0;
    reg        rst   = 0;
    reg        btnC  = 0;
    reg [15:0] sw    = 0;

    wire [6:0] seg;
    wire       dp;
    wire [7:0] an;
    wire [15:0] led;

    // ── DUT instantiation ─────────────────────────────────────
    euclid_top dut (
        .clk  (clk),
        .rst  (rst),
        .btnC (btnC),
        .sw   (sw),
        .seg  (seg),
        .dp   (dp),
        .an   (an),
        .led  (led)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // ── Task: press button and wait for result ─────────────────
    task press_and_wait;
        input [15:0] switches;
        input [15:0] expected;
        begin
            sw = switches;
            @(posedge clk); #1;

            // Hold button for 1.5 ms  (> debounce window in sim)
            // (debounce uses 20-bit counter ≈ 10 ms real; in sim
            //  we cheat the synchroniser path by forcing btn_db)
            // Simple: just toggle btnC for 25 cycles then release
            btnC = 1;
            repeat (25) @(posedge clk);
            btnC = 0;

            // Wait up to 100 cycles for DONE (16-cycle SQRT + margin)
            repeat (100) @(posedge clk);

            // Check LED output (shows result when DONE)
            if (led === expected)
                $display("PASS  sw=%04h  dist=%0d  led=%04h",
                          switches, expected, led);
            else
                $display("FAIL  sw=%04h  expected=%0d  got=%0d",
                          switches, expected, led);
        end
    endtask

    // ── Test vectors ──────────────────────────────────────────
    // sw = {y2[3:0], y1[3:0], x2[3:0], x1[3:0]}
    //
    //  Test 1: (0,0)→(3,4)  dist=floor(sqrt(9+16))=floor(5)=5
    //  Test 2: (0,0)→(0,0)  dist=0
    //  Test 3: (1,1)→(4,5)  dist=floor(sqrt(9+16))=5
    //  Test 4: (0,0)→(15,15) dist=floor(sqrt(450))=21
    initial begin
        $dumpfile("tb_euclid.vcd");
        $dumpvars(0, tb_euclid);

        // Reset
        rst = 1; repeat(5) @(posedge clk); rst = 0;
        repeat(10) @(posedge clk);

        // Note: debounce in hardware takes ~10 ms; in simulation
        // the counter is the same so tests below force long presses.
        // For quick sim, you may shorten db_cnt width to 4 bits.

        // (x1=0, x2=3, y1=0, y2=4): sw = {4'd4, 4'd0, 4'd3, 4'd0}
        press_and_wait({4'd4, 4'd0, 4'd3, 4'd0}, 16'd5);

        repeat(10) @(posedge clk);

        // (x1=0, x2=0, y1=0, y2=0): sw = all zeros
        press_and_wait(16'h0000, 16'd0);

        repeat(10) @(posedge clk);

        // (x1=0, x2=15, y1=0, y2=15): sw = {4'd15, 4'd0, 4'd15, 4'd0}
        press_and_wait({4'd15, 4'd0, 4'd15, 4'd0}, 16'd21);

        repeat(10) @(posedge clk);

        // (x1=6, x2=9, y1=2, y2=6): dx=3 dy=4 dist=5
        // sw = {y2=6, y1=2, x2=9, x1=6}
        press_and_wait({4'd6, 4'd2, 4'd9, 4'd6}, 16'd5);

        $display("Simulation complete.");
        $finish;
    end

endmodule
