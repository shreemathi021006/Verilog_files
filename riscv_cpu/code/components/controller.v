// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
    input        Taken,
    output       [1:0] ResultSrc,
    output       MemWrite,
    output       [1:0] PCSrc,
    output       ALUSrc,
    output       [1:0] ALUSrcA,
    output       RegWrite, Jump,
    output [2:0] ImmSrc,
    output [3:0] ALUControl
);

wire [1:0] ALUOp;
wire       Branch;
wire       JALR;

main_decoder    md (op, ResultSrc, MemWrite, Branch,
                    ALUSrc, ALUSrcA, RegWrite, Jump, JALR, ImmSrc, ALUOp);

alu_decoder     ad (op[5], funct3, funct7b5, ALUOp, ALUControl);

// PCSrc[0]: branch taken or jal -> use PC + ImmExt (PCTarget)
// PCSrc[1]: jalr -> use ALU result (rs1 + ImmExt)
assign PCSrc[1] = JALR;
assign PCSrc[0] = (Branch & Taken) | Jump;

endmodule