`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.12.2025 11:02:50
// Design Name: 
// Module Name: half_adder_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module half_adder_tb();

reg a,b;
wire y,z;
half_adder_source half_add_sim(a,b,y,z);
initial begin
a=0;
b=0;
#10;
a=1;
b=0;
#10;
a=0;
b=1;
#10;
a=1;
b=1;
#10;
end
endmodule
