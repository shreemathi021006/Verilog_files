`timescale 1ns/1ps
//=============================================================================
// top — full integration: BOTH the original baseline chain (dp/cp) AND the
// fault-tolerant chain (dl/c1/zd/gf/ctrl/ov/sc) instantiated side by side,
// off the same inputs, for direct PPA/area comparison and single-hierarchy
// synthesis reporting.
//
// Depends on (separate files):
//   voter3.v, zero_d.v, count.v, datapath.v, control_path.v,
//   glitch_filter.v, tmr-wrapped.v (dead_latch_tmr),
//   tmr-wrapped-counter.v (count_tmr), tmr-wrapped-ns.v (controlpath_tmr),
//   hard_override_gate.v, self_crct.v (self_correct)
//=============================================================================
module top(
    input        clk, rst,
    input  [2:0] on_time,
    input  [2:0] dead_in,
    output       a, b,           // fault-tolerant, protected outputs
    output       a_base, b_base  // baseline outputs, no protection at all
);
    //-------------------------------------------------------------------
    // Fault-tolerant chain
    //-------------------------------------------------------------------
    wire       cnt, rstc, eq_raw, eq, sel_dead, new_period;
    wire [2:0] dead_latched, count_out, dead_time_eff, margin_add;
    wire [3:0] total_dead;
    wire       a_raw, b_raw, overlap_now;
    wire       dead_mismatch, cnt_mismatch, ns_mismatch;

    dead_latch_tmr dl (.clk(clk), .rst(rst), .new_period(new_period),
                        .dead_in(dead_in), .dead_latched(dead_latched),
                        .dead_mismatch(dead_mismatch));

    // Self-correction margin sits on top of the TMR-voted latched value;
    // saturate rather than wrap since the sum can exceed 3 bits.
    assign total_dead    = dead_latched + margin_add;
    assign dead_time_eff = (total_dead > 4'd7) ? 3'd7 : total_dead[2:0];

    wire [2:0] reload_val = sel_dead ? dead_time_eff : on_time;

    count_tmr c1 (.clk(clk), .rst(rstc), .cnt(cnt), .data(reload_val),
                  .out(count_out), .cnt_mismatch(cnt_mismatch));

    zero_d zd (.data(count_out), .eq(eq_raw));

    glitch_filter gf (.clk(clk), .rst(rst), .eq_raw(eq_raw), .eq_filtered(eq));

    controlpath_tmr ctrl (.clk(clk), .eq(eq), .rst(rst),
                           .a(a_raw), .b(b_raw), .cnt(cnt), .rstc(rstc),
                           .sel_dead(sel_dead), .new_period(new_period),
                           .ns_mismatch(ns_mismatch));

    hard_override_gate ov (.a_in(a_raw), .b_in(b_raw),
                            .a_safe(a), .b_safe(b),
                            .overlap_now(overlap_now));

    self_correct sc (.clk(clk), .rst(rst), .new_period(new_period),
                      .anomaly(overlap_now), .margin_add(margin_add));

    //-------------------------------------------------------------------
    // Baseline chain — original, unprotected design, run in parallel
    // purely for area/PPA comparison. Fully independent wires/registers
    // from the fault-tolerant chain above.
    //-------------------------------------------------------------------
    wire       cnt_b, rstc_b, eq_b, sel_dead_b, new_period_b;
    reg  [2:0] dead_latched_b;

    always @(posedge clk) begin
        if (rst)               dead_latched_b <= 3'd5;
        else if (new_period_b) dead_latched_b <= dead_in;
    end

    datapath dp (.clk(clk), .rst(rstc_b), .cnt(cnt_b),
                 .on_time(on_time), .dead_time(dead_latched_b),
                 .sel_dead(sel_dead_b), .eq(eq_b));

    controlpath cp (.clk(clk), .eq(eq_b), .rst(rst),
                     .a(a_base), .b(b_base), .cnt(cnt_b), .rstc(rstc_b),
                     .sel_dead(sel_dead_b), .new_period(new_period_b));

endmodule