`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.06.2026 11:10:49
// Design Name: 
// Module Name: fsm
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


module fsm(input clk,lt,gt,eq,start,input [7:0]data_in,output reg finish,lda,ldb,sel_in,sel_a,sel_b);
parameter s0 = 3'b000, s1 = 3'b001, s2 = 3'b010, s3 = 3'b011,s4 = 3'b100, s5 = 3'b101;
reg [2:0] s;
initial s = 0;
always @(posedge clk)
begin
case (s)
s0 : if (start) s<=s1;
s1 : s<=s2;
s2 : begin if (eq) s<=s5 ;
           else if (lt) s <= s3;
           else if (gt) s<=s4;
     end
s3 :  begin if (eq) s<=s5 ;
           else if (lt) s <= s3;
           else if (gt) s<=s4;
       end
s4 : begin if (eq) s<=s5 ;
           else if (lt) s <= s3;
           else if (gt) s<=s4;
       end
s5 : s <= s5;
default : s <= s0;
endcase
end


always @(s)
begin
case (s)
s0 : begin sel_in = 1; lda = 1; ldb = 0 ; finish = 0; end
s1 : begin sel_in = 1; lda = 0; ldb = 1; end
s2 : if (eq) finish = 1;
     else if (gt) begin sel_a = 0; sel_b = 1; sel_in = 0;
     lda = 1; ldb = 0;
     end
     else if (lt) begin sel_a = 1; sel_b = 0; sel_in = 0;
     #1 lda = 0 ; ldb = 1;
     end
s3 : if (eq) finish = 1;
     else if (gt) begin sel_a = 0; sel_b = 1; sel_in = 0;
     lda = 1; ldb = 0;
     end
     else if (lt) begin sel_a = 1; sel_b = 0; sel_in = 0;
     lda = 0 ; ldb = 1;
     end
s4 : if (eq) finish = 1;
     else if (gt) begin sel_a = 0; sel_b = 1; sel_in = 0;
     lda = 1; ldb = 0;
     end
     else if (lt) begin sel_a = 1; sel_b = 0; sel_in = 0;
     lda = 0 ; ldb = 1;
     end
s5 : begin finish = 1; sel_a = 0; sel_b = 0;  lda = 0; ldb = 0; end
default : begin lda = 0; ldb = 0; end
endcase
end
endmodule
