`timescale 1ns / 1ps

module pipo(input clk,input load, input [7:0] x, output reg [7:0] z);
always @(posedge clk)
if (load)
z <= x;

endmodule
