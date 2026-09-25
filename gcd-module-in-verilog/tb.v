`timescale 1ns / 1ps


module tb;
reg [7:0] data_in;
reg start,clk;
wire finish;

data_path dp (clk,lda,ldb,sel_a,sel_b,sel_in,gt,eq,lt,data_in);
fsm f(clk,lt,gt,eq,start,data_in,finish,lda,ldb,sel_in,sel_a,sel_b);

initial 
begin
clk = 0;
#5;
start = 1;
#300;
$finish;
end

always #5 clk = ~clk;

initial 
begin
$monitor("t=%0t state=%b lda=%b ldb=%b A=%d B=%d",
         $time,f.s,lda,ldb,dp.a,dp.b);
$dumpfile("tb.vcd");
$dumpvars(0,tb);
end

initial 
begin
data_in = 143;
#10 data_in = 78;
end



endmodule
