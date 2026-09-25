`timescale 1ns/1ps
//=============================================================================
// voter3 — shared majority-vote primitive, reused by all TMR'd registers
//=============================================================================
module voter3 #(
    parameter WIDTH = 1
)(
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    output [WIDTH-1:0] out,
    output             mismatch   // 1 if the three copies don't all agree
);
    assign out      = (in0 & in1) | (in1 & in2) | (in0 & in2);
    assign mismatch = (in0 != in1) || (in1 != in2) || (in0 != in2);
endmodule