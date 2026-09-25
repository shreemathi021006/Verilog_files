`timescale 1ns/1ps
//=============================================================================
// count_tmr — TMR-protected down-counter (Layer 2)
// Copies run independently (reload only on rst) so a stuck-at fault in one
// copy stays visible as a persistent mismatch rather than being silently
// re-synced every cycle.
// Depends on: voter3.v
//=============================================================================
module count_tmr (
    input        clk, rst, cnt,
    input  [2:0] data,
    output [2:0] out,
    output       cnt_mismatch
);
    reg [2:0] c0, c1, c2;
    always @(posedge clk) begin
        if (rst) begin
            c0 <= data; c1 <= data; c2 <= data;
        end else if (cnt) begin
            // Saturate at zero instead of wrapping. eq_raw (from zero_d)
            // must stay HIGH for multiple cycles so glitch_filter's
            // majority-of-3-in-time check can actually confirm it —
            // a single-cycle pulse can never satisfy a 2-of-3 filter,
            // since only one of the three shift-register bits is ever
            // set at a time as it shifts through.
            c0 <= (c0 == 3'd0) ? 3'd0 : c0 - 1'b1;
            c1 <= (c1 == 3'd0) ? 3'd0 : c1 - 1'b1;
            c2 <= (c2 == 3'd0) ? 3'd0 : c2 - 1'b1;
        end
    end
    voter3 #(.WIDTH(3)) count_voter (
        .in0(c0), .in1(c1), .in2(c2),
        .out(out), .mismatch(cnt_mismatch)
    );
endmodule