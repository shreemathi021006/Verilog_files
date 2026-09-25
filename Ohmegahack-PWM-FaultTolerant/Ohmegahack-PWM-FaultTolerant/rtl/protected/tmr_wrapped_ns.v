`timescale 1ns/1ps
//=============================================================================
// controlpath_tmr — TMR-protected FSM (Layer 2)
// Three copies of the state register vote before next-state/output logic
// evaluates, so a single upset in one copy is masked, not just detected.
// Depends on: voter3.v
//=============================================================================
module controlpath_tmr (
    input      clk,
    input      eq,
    input      rst,
    output reg a,
    output reg b,
    output reg cnt,
    output reg rstc,
    output reg sel_dead,
    output reg new_period,
    output     ns_mismatch
);
    localparam S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;

    reg [1:0] ns0, ns1, ns2;
    wire [1:0] ns_voted;

    voter3 #(.WIDTH(2)) ns_voter (
        .in0(ns0), .in1(ns1), .in2(ns2),
        .out(ns_voted), .mismatch(ns_mismatch)
    );

    reg [1:0] ns_next;
    always @(*) begin
        case (ns_voted)
            S0: ns_next = eq ? S1 : S0;
            S1: ns_next = eq ? S2 : S1;
            S2: ns_next = eq ? S3 : S2;
            S3: ns_next = eq ? S0 : S3;
            default: ns_next = S0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            ns0 <= S0; ns1 <= S0; ns2 <= S0;
        end else begin
            ns0 <= ns_next; ns1 <= ns_next; ns2 <= ns_next;
        end
    end

    always @(*) begin
        if (rst) begin
            a=0; b=0; cnt=0; rstc=1; sel_dead=0; new_period=0;
        end else begin
            case (ns_voted)
                S0: begin a=1; b=0; cnt=1; sel_dead=0; rstc=eq; new_period=0;  end
                S1: begin a=0; b=0; cnt=1; sel_dead=1; rstc=eq; new_period=0;  end
                S2: begin a=0; b=1; cnt=1; sel_dead=0; rstc=eq; new_period=0;  end
                S3: begin a=0; b=0; cnt=1; sel_dead=1; rstc=eq; new_period=eq; end
                default: begin a=0; b=0; cnt=0; sel_dead=0; rstc=1; new_period=0; end
            endcase
        end
    end
endmodule