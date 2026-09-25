`timescale 1ns/1ps
module controlpath (
    input      clk,
    input      eq,
    input      rst,
    output reg a,
    output reg b,
    output reg cnt,
    output reg rstc,
    output reg sel_dead,   
    output reg new_period  
);
    localparam S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    reg [1:0] ns;
    always @(posedge clk) begin
        if (rst) begin
            ns<=S0; a<=0; b<=0; cnt<=0; rstc<=1; sel_dead<=0; new_period<=0;
        end else begin
            new_period <= 1'b0;
            case (ns)
                S0: begin
                    a<=1; b<=0; cnt<=1; sel_dead<=0;
                    if (eq) begin ns<=S1; rstc<=1; end
                    else    begin ns<=S0; rstc<=0; end
                end
                S1: begin
                    a<=0; b<=0; cnt<=1; sel_dead<=1;
                    if (eq) begin ns<=S2; rstc<=1; end
                    else    begin ns<=S1; rstc<=0; end
                end
                S2: begin
                    a<=0; b<=1; cnt<=1; sel_dead<=0;
                    if (eq) begin ns<=S3; rstc<=1; end
                    else    begin ns<=S2; rstc<=0; end
                end
                S3: begin
                    a<=0; b<=0; cnt<=1; sel_dead<=1;
                    if (eq) begin ns<=S0; rstc<=1; new_period<=1; end
                    else    begin ns<=S3; rstc<=0; end
                end
                default: begin ns<=S0; a<=0; b<=0; cnt<=0; rstc<=1; sel_dead<=0; end
            endcase
        end
    end
endmodule
