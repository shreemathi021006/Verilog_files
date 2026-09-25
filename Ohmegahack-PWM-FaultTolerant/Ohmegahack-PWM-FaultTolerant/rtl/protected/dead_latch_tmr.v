`timescale 1ns/1ps
//=============================================================================
// dead_latch_tmr - TMR-protected dead-time latch register (Layer 2)
// Depends on: voter3.v
//=============================================================================
module dead_latch_tmr (
    input        clk,
    input        rst,
    input        new_period,
    input  [2:0] dead_in,
    output [2:0] dead_latched,
    output       dead_mismatch
);
    reg [2:0] d0, d1, d2;
    always @(posedge clk) begin
        if (rst) begin
            d0 <= 3'd5; d1 <= 3'd5; d2 <= 3'd5;
        end else if (new_period) begin
            d0 <= dead_in; d1 <= dead_in; d2 <= dead_in;
        end
    end
    voter3 #(.WIDTH(3)) dead_voter (
        .in0(d0), .in1(d1), .in2(d2),
        .out(dead_latched), .mismatch(dead_mismatch)
    );
endmodule