`timescale 1ns/1ps

module zero_d(
    input [2:0]data,
    output eq
    );

assign eq = ~| data;

endmodule
