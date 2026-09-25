`timescale 1ns/1ps
//=============================================================================
// hard_override_gate — pure combinational last-line-of-defense (Layer 4)
// No clock input at all: reacts within gate-propagation delay, not clock
// period, so it catches faults no synchronous layer above it structurally can.
//=============================================================================
module hard_override_gate (
    input  a_in,
    input  b_in,
    output a_safe,
    output b_safe,
    output overlap_now
);
    wire not_overlap;
    and (overlap_now, a_in, b_in);
    not (not_overlap, overlap_now);
    and (a_safe, a_in, not_overlap);
    and (b_safe, b_in, not_overlap);
endmodule