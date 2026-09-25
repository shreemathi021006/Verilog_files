module top(
    input clk,
    input rst,
    input [2:0] on_time,  
    input [2:0] dead_in,   
    output a,
    output b
);
    wire cnt, rstc, eq, sel_dead, new_period;
    reg  [2:0] dead_latched;
    always @(posedge clk) begin
        if (rst)             dead_latched <= 3'd5;   
        else if (new_period) dead_latched <= dead_in;
    end
    datapath   d(.clk(clk), .rst(rstc), .cnt(cnt),
                 .on_time(on_time), .dead_time(dead_latched),
                 .sel_dead(sel_dead), .eq(eq));
    controlpath c(.clk(clk), .eq(eq), .rst(rst), .a(a), .b(b),
                  .cnt(cnt), .rstc(rstc), .sel_dead(sel_dead), .new_period(new_period));
endmodule
