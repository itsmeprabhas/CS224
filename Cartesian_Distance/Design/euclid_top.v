// ============================================================
// euclid_top.v  -  Euclidean Distance Demo  (Nexys A7-100T)
// CS224 Hardware Lab - Group 19
// ============================================================
//
// ┌─ INPUTS ──────────────────────────────────────────────────┐
// │  SW[3:0]   = x1  (0-15)     SW[7:4]   = x2  (0-15)      │
// │  SW[11:8]  = y1  (0-15)     SW[15:12] = y2  (0-15)      │
// │  btnC  = trigger computation (press after setting switches)│
// └───────────────────────────────────────────────────────────┘
//
// ┌─ 7-SEG DISPLAY  (8 digits, left → right) ─────────────────┐
// │  DIG7  DIG6  DIG5  DIG4 │ DIG3 │ DIG2  DIG1  DIG0       │
// │   x1    x2    y1    y2  │  --  │  H     T     U          │
// │  ← hex coordinates →    │blank │ ← decimal distance →    │
// │                      DP on DIG4 acts as separator         │
// └───────────────────────────────────────────────────────────┘
//
// ┌─ LEDs ────────────────────────────────────────────────────┐
// │  IDLE     → mirrors SW[15:0]                             │
// │  COMPUTE  → all LEDs ON (shows computation in progress)  │
// │  DONE     → dist_result[15:0] in binary                  │
// └───────────────────────────────────────────────────────────┘
//
// Formula:  dist = floor( sqrt( (x1-x2)² + (y1-y2)² ) )
// Max value with 4-bit inputs: floor(sqrt(450)) = 21
// ============================================================
`timescale 1ns/1ps

module euclid_top (
    input  wire        clk,     // 100 MHz (pin E3)
    input  wire        rst,     // btnCpuReset active-HIGH (pin C12)
    input  wire        btnC,    // centre button (pin N17)
    input  wire [15:0] sw,      // 16 switches
    output wire [6:0]  seg,     // 7-seg cathodes, active LOW
    output wire        dp,      // decimal point,  active LOW
    output wire [7:0]  an,      // digit anodes,   active LOW
    output wire [15:0] led      // LEDs
);

    // ──────────────────────────────────────────────────────────
    // 1.  Extract coordinates from switches
    // ──────────────────────────────────────────────────────────
    wire [3:0] y2 = sw[3:0];
    wire [3:0] x2 = sw[7:4];
    wire [3:0] y1 = sw[11:8];
    wire [3:0] x1 = sw[15:12];

    // ──────────────────────────────────────────────────────────
    // 2.  Combinational pre-computation:  dx² + dy²
    //     dx, dy ∈ [0,15]  →  dx², dy² ∈ [0,225]  →  sum ∈ [0,450]
    // ──────────────────────────────────────────────────────────
    wire [3:0] dx    = (x1 >= x2) ? (x1 - x2) : (x2 - x1);
    wire [3:0] dy    = (y1 >= y2) ? (y1 - y2) : (y2 - y1);
    wire [7:0] dx2   = dx * dx;          // 4-bit × 4-bit = 8-bit, max 225
    wire [7:0] dy2   = dy * dy;
    wire [8:0] sum_sq = {1'b0, dx2} + {1'b0, dy2};   // 9-bit, max 450

    // ──────────────────────────────────────────────────────────
    // 3.  Button debounce  (≈10 ms at 100 MHz)
    //     Two-FF synchroniser + counter-based debounce
    // ──────────────────────────────────────────────────────────
    reg        btn_sync;
    reg [19:0] db_cnt;
    reg        btn_db, btn_db_r;

    // Stage 1: synchronise to clock domain
    always @(posedge clk or posedge rst)
        if (rst) btn_sync <= 1'b0;
        else     btn_sync <= btnC;

    // Stage 2: 20-bit counter debounce (~10 ms window)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            db_cnt <= 20'd0;
            btn_db <= 1'b0;
        end else if (btn_sync == btn_db) begin
            db_cnt <= 20'd0;           // signal stable, reset counter
        end else begin
            db_cnt <= db_cnt + 20'd1;
            if (&db_cnt) btn_db <= btn_sync;  // stable for 2^20 cycles
        end
    end

    // Rising-edge detector
    always @(posedge clk or posedge rst)
        if (rst) btn_db_r <= 1'b0;
        else     btn_db_r <= btn_db;

    wire btn_rise = btn_db & ~btn_db_r;

    // ──────────────────────────────────────────────────────────
    // 4.  SQRT unit instantiation
    // ──────────────────────────────────────────────────────────
    reg         sqrt_start;
    reg  [31:0] sqrt_in;
    wire [15:0] sqrt_result;
    wire        sqrt_done;

    sqrt_unit u_sqrt (
        .clk    (clk),
        .rst    (rst),
        .start  (sqrt_start),
        .D      (sqrt_in),
        .result (sqrt_result),
        .done   (sqrt_done)
    );

    // ──────────────────────────────────────────────────────────
    // 5.  Control FSM: IDLE → COMPUTE → DONE
    //     Both IDLE and DONE accept a new button press.
    // ──────────────────────────────────────────────────────────
    localparam [1:0]
        IDLE    = 2'd0,
        COMPUTE = 2'd1,
        DONE    = 2'd2;

    reg [1:0]  state;
    reg [15:0] dist_result;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            sqrt_start  <= 1'b0;
            sqrt_in     <= 32'd0;
            dist_result <= 16'd0;
        end else begin
            sqrt_start <= 1'b0;        // default: no start pulse

            case (state)

                IDLE, DONE: begin
                    if (btn_rise) begin
                        // Latch current switch values and kick off SQRT
                        sqrt_in    <= {23'd0, sum_sq};  // zero-extend to 32 bits
                        sqrt_start <= 1'b1;
                        state      <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    if (sqrt_done) begin
                        dist_result <= sqrt_result;
                        state       <= DONE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

    // ──────────────────────────────────────────────────────────
    // 6.  BCD conversion of result for decimal display
    // ──────────────────────────────────────────────────────────
    wire [3:0] bcd4, bcd3, bcd2, bcd1, bcd0;

    bin_to_bcd u_bcd (
        .bin  (dist_result),
        .bcd4 (bcd4),
        .bcd3 (bcd3),
        .bcd2 (bcd2),
        .bcd1 (bcd1),
        .bcd0 (bcd0)
    );

    // ──────────────────────────────────────────────────────────
    // 7.  7-segment display
    //
    //  Digit  7    6    5    4    3    2    1    0
    //         x1   x2   y1   y2  [  ] H    T    U
    //         ←── hex inputs ──→  gap  ← decimal dist →
    //
    //  Decimal point on digit-4 (rightmost input) = separator
    // ──────────────────────────────────────────────────────────
    seg7_display u_seg (
        .clk   (clk),
        .rst   (rst),
        .d7    (x1),
        .d6    (y1),
        .d5    (x2),
        .d4    (y2),
        .d3    (4'hF),   // blank separator
        .d2    (bcd2),   // hundreds  (0 for results ≤ 99)
        .d1    (bcd1),   // tens
        .d0    (bcd0),   // ones
        .dp_en (8'b0001_0000),  // DP on digit-4 (separator marker)
        .seg   (seg),
        .dp    (dp),
        .an    (an)
    );

    // ──────────────────────────────────────────────────────────
    // 8.  LED feedback
    //     IDLE    → show switch values
    //     COMPUTE → all LEDs ON  (busy indicator)
    //     DONE    → show result in binary
    // ──────────────────────────────────────────────────────────
    assign led = (state == COMPUTE) ? 16'hFFFF :
                 (state == DONE)    ? dist_result :
                                     sw;

endmodule
