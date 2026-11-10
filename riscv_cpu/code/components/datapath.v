// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input [1:0]   PCSrc,
    input         ALUSrc,
    input [1:0]   ALUSrcA,
    input         RegWrite,
    input [2:0]   ImmSrc,
    input [3:0]   ALUControl,
    output        Taken,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire [31:0] PCNext, PCPlus4, PCTarget;
wire [31:0] ImmExt, SrcA, SrcB, WriteData, ALUResult;
wire [31:0] SrcA_muxed;
wire        Zero;
wire [31:0] LdExt;

// next PC logic
reset_ff #(32) pcreg(clk, reset, PCNext, PC);
adder          pcadd4(PC, 32'd4, PCPlus4);
adder          pcaddbranch(PC, ImmExt, PCTarget);
mux3   #(32)   pcmux(PCPlus4, PCTarget, ALUResult, PCSrc, PCNext);

// register file logic
reg_file       rf (clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
imm_extend     ext (Instr[31:7], ImmSrc, ImmExt);

// ALU source A mux: register (default), PC (auipc) or 0 (lui)
mux3   #(32)   srcamux(SrcA, PC, 32'd0, ALUSrcA, SrcA_muxed);

// ALU logic
mux2 #(32)     srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
alu            alu (SrcA_muxed, SrcB, ALUControl, ALUResult, Zero);

// load data extension (lb, lh, lw, lbu, lhu) selected by funct3
wire [7:0]  ld_byte  = ReadData[ALUResult[1:0]*8 +: 8];
wire [15:0] ld_half  = ReadData[ALUResult[1]*16   +: 16];
assign LdExt = (Instr[14:12] == 3'b000) ? {{24{ld_byte[7]}}, ld_byte} :  // lb
               (Instr[14:12] == 3'b001) ? {{16{ld_half[15]}}, ld_half} : // lh
               (Instr[14:12] == 3'b100) ? {24'b0, ld_byte} :             // lbu
               (Instr[14:12] == 3'b101) ? {16'b0, ld_half} :             // lhu
                                          ReadData;                      // lw (or non-load)

mux3 #(32)     resultmux(ALUResult, LdExt, PCPlus4, ResultSrc, Result);

// branch-taken decode (funct3 from Instr[14:12])
// branch ALU op: beq/bne -> SUB (Zero set), blt/bge -> SLT, bltu/bgeu -> SLTU
assign Taken = (Instr[14:12] == 3'b000) ? Zero          : // beq
               (Instr[14:12] == 3'b001) ? ~Zero         : // bne
               (Instr[14:12] == 3'b100) ? ALUResult[0]   : // blt
               (Instr[14:12] == 3'b101) ? ~ALUResult[0]  : // bge
               (Instr[14:12] == 3'b110) ? ALUResult[0]   : // bltu
                                          ~ALUResult[0];  // bgeu

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;

endmodule