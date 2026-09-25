`timescale 1ns/1ps
//=============================================================================
// glitch_filter — 3-sample majority-in-TIME filter on eq (Layer 3)
// Catches a transient glitch in transit between zero_d and controlpath;
// this is distinct from TMR, which only protects stored state.
//=============================================================================
module glitch_filter (
    input  clk,
    input  rst,
    input  eq_raw,
    output eq_filtered
);
    reg s0, s1, s2;
    always @(posedge clk) begin
        if (rst) begin s0 <= 0; s1 <= 0; s2 <= 0; end
        else begin
            s2 <= s1;
            s1 <= s0;
            s0 <= eq_raw;
        end
    end
    assign eq_filtered = (s0 & s1) | (s1 & s2) | (s0 & s2);
endmodule