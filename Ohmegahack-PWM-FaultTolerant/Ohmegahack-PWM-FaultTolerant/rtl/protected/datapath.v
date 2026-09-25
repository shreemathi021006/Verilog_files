`timescale 1ns/1ps
//=============================================================================
// datapath - ORIGINAL baseline datapath (no TMR), for area/PPA comparison
//=============================================================================
module datapath(
    input        clk, rst, cnt,
    input  [2:0] on_time,
    input  [2:0] dead_time,
    input        sel_dead,
    output       eq
);
    wire [2:0] reload_val = sel_dead ? dead_time : on_time;
    wire [2:0] inter;
    count  c1(.clk(clk), .rst(rst), .cnt(cnt), .data(reload_val), .out(inter));
    zero_d zd(.data(inter), .eq(eq));
endmodule