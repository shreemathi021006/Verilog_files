`timescale 1ns/1ps
//=============================================================================
// self_correct — adaptive, hysteresis-gated margin controller (Layer 5)
// Watches overlap_now; on sustained (not single-event) anomalies, pads the
// dead-time going forward, bounded by MAX_MARGIN_ADD; relaxes back down
// after a sustained clean run.
//=============================================================================
module self_correct #(
    parameter THRESH         = 3,
    parameter MARGIN_STEP    = 3'd1,
    parameter MAX_MARGIN_ADD = 3'd3
)(
    input             clk,
    input             rst,
    input             new_period,
    input             anomaly,
    output reg [2:0]  margin_add
);
    reg [3:0] bad_streak, good_streak;
    reg       anomaly_latched;

    always @(posedge clk) begin
        if (rst)               anomaly_latched <= 1'b0;
        else if (new_period)   anomaly_latched <= 1'b0;
        else if (anomaly)      anomaly_latched <= 1'b1;
    end

    always @(posedge clk) begin
        if (rst) begin
            bad_streak  <= 0;
            good_streak <= 0;
            margin_add  <= 0;
        end else if (new_period) begin
            if (anomaly_latched) begin
                good_streak <= 0;
                if (bad_streak == THRESH - 1) begin
                    bad_streak <= 0;
                    margin_add <= (margin_add + MARGIN_STEP <= MAX_MARGIN_ADD)
                                   ? margin_add + MARGIN_STEP
                                   : MAX_MARGIN_ADD;
                end else begin
                    bad_streak <= bad_streak + 1'b1;
                end
            end else begin
                bad_streak <= 0;
                if (good_streak == 4'd7) begin
                    good_streak <= 0;
                    margin_add  <= (margin_add >= MARGIN_STEP)
                                    ? margin_add - MARGIN_STEP
                                    : 3'd0;
                end else begin
                    good_streak <= good_streak + 1'b1;
                end
            end
        end
    end
endmodule