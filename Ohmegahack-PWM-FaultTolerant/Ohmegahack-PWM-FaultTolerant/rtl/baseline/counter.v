`timescale 1ns/1ps
module count(
    input clk, rst, cnt,
    input [2:0] data,
    output reg [2:0] out
);
    always @(posedge clk) begin
        if (rst)      out <= data;
        else if (cnt) out <= out - 1'b1;
    end
endmodule
