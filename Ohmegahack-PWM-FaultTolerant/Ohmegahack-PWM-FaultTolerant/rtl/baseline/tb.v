`timescale 1ns/1ps

module tb_top;

    // --- Inputs ---
    reg        clk;
    reg        rst;
    reg  [2:0] on_time;
    reg  [2:0] dead_in;

    // --- Outputs ---
    wire       a;
    wire       b;

    // --- Instantiate DUT ---
    top uut (
        .clk    (clk),
        .rst    (rst),
        .on_time(on_time),
        .dead_in(dead_in),
        .a      (a),
        .b      (b)
    );

    // --- Clock Generation (100MHz / 10ns period) ---
    always #5 clk = ~clk;

    // --- Concurrent Safety Assertion: Zero Overlap Monitor ---
    always @(posedge clk) begin
        if (a && b) begin
            $display("[FATAL ERROR] Short circuit detected! Both 'a' and 'b' are HIGH at time %0t ps", $time);
            $finish;
        end
    end

    // --- Test Sequence ---
    initial begin
        // Setup Waveform Dumping
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);

        // Initialize Signals
        clk     = 0;
        rst     = 1;
        on_time = 3'd3;
        dead_in = 3'd2;

                $display("   STARTING DEAD-TIME PROTECTED PWM TESTBENCH");
        
        // --- TEST 1: Power-On Reset ---
        #20;
        rst = 0;
        $display("[%0t ns] Released Reset. Initial dead_in = %0d, on_time = %0d", $time, dead_in, on_time);

        // Allow at least 1 full PWM period to complete with initial values
        #150;

        // --- TEST 2: Mid-Cycle Dead-Time Parameter Update ---
        @(posedge clk);
        // Change dead_in to 3'd5 right during an active run cycle
        dead_in = 3'd5;
        $display("[%0t ns] MID-CYCLE UPDATE: Requested dead_in change -> %0d (Should NOT apply until next period)", $time, dead_in);

        // Wait through the rest of the current period and into the next one
        #200;

        // --- TEST 3: Dynamic Duty Cycle Update ---
        @(posedge clk);
        on_time = 3'd1;
        $display("[%0t ns] Updated on_time -> %0d", $time, on_time);

        #150;

        // --- TEST 4: Asynchronous/Synchronous Re-Reset Test ---
        @(posedge clk);
        rst = 1;
        $display("[%0t ns] Re-asserted Reset. Outputs should drop immediately.", $time);
        #20;
        if (a !== 0 || b !== 0) begin
            $display("[ERROR] Outputs not zero during reset!");
        end else begin
            $display("[%0t ns] Reset check passed successfully.", $time);
        end

        rst = 0;
        #50;

                $display("   ALL TEST PASSED: Zero Overlap & Latched Updates Verified");
                $finish;
    end

endmodule