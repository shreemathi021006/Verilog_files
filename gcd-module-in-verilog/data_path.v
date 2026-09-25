`timescale 1ns / 1ps

module data_path(input clk,lda,ldb,sel_a,sel_b,sel_in,output gt,eq,lt,input [7:0] data_in);
wire [7:0] a,b;
wire [7:0] bus;
wire [7:0] ma,mb,mc,cout;

pipo p1 (.load(lda),.x(bus),.z(a),.clk(clk));
pipo p2 (.load(ldb),.clk(clk),.x(bus),.z(b));
mux ma1 (.sel(sel_a),.x(a),.y(b),.z(ma));
mux mb1 (.sel(sel_b),.x(a),.y(b),.z(mb));
comp c (.x(a),.y(b),.gt(gt),.lt(lt),.eq(eq));
subt s (.x(ma),.y(mb),.z(cout));
mux mc1 (.sel(sel_in),.x(cout),.y(data_in),.z(bus));

endmodule
