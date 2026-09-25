`timescale 1ns / 1ps

module comp(input [7:0] x, input [7:0] y,output lt,gt,eq);
assign lt = x<y;
assign gt =  x>y;
assign eq = x == y ;

endmodule
