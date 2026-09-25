`timescale 1ns / 1ps

module subt(input [7:0] x , y , output reg [7:0] z);
always @(*)
z  = x - y;
endmodule
