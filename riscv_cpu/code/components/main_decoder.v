// main_decoder.v - logic for main decoder

module main_decoder (
    input  [6:0] op,
    output [1:0] ResultSrc,
    output       MemWrite, Branch, ALUSrc,
    output [1:0] ALUSrcA,
    output       RegWrite, Jump, JALR,
    output [2:0] ImmSrc,
    output [1:0] ALUOp
);

reg [14:0] controls;

always @(*) begin
    case (op)
        // RegWrite_ImmSrc_ALUSrc_ALUSrcA_MemWrite_ResultSrc_Branch_ALUOp_Jump_JALR
        7'b0000011: controls = 15'b1_000_1_00_0_01_0_00_0_0; // lw
        7'b0100011: controls = 15'b0_001_1_00_1_00_0_00_0_0; // sw
        7'b0110011: controls = 15'b1_000_0_00_0_00_0_10_0_0; // R-type
        7'b1100011: controls = 15'b0_010_0_00_0_00_1_11_0_0; // beq, bne, blt, bge, bltu, bgeu
        7'b0010011: controls = 15'b1_000_1_00_0_00_0_10_0_0; // I-type ALU
        7'b1101111: controls = 15'b1_011_0_00_0_10_0_00_1_0; // jal
        7'b0110111: controls = 15'b1_100_1_10_0_00_0_00_0_0; // lui
        7'b0010111: controls = 15'b1_100_1_01_0_00_0_00_0_0; // auipc
        7'b1100111: controls = 15'b1_000_1_00_0_10_0_00_0_1; // jalr
        default:    controls = 15'bx_xxx_x_xx_x_xx_x_xx_x_x; // ???
    endcase
end

assign {RegWrite, ImmSrc, ALUSrc, ALUSrcA, MemWrite, ResultSrc, Branch, ALUOp, Jump, JALR} = controls;

endmodule