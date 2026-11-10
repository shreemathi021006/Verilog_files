// t1_riscv_cpu.v - Top Module to test riscv_cpu

module t1_riscv_cpu (
    input         clk, reset,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData, Ext_DataAdr,
    output        MemWrite,
    output [31:0] WriteData, DataAdr, ReadData,
    output [31:0] PC, Result
);

wire [31:0] Instr;
wire [31:0] DataAdr_rv32, WriteData_rv32;
wire        MemWrite_rv32;
wire [31:0] merged_wr_data;

// instantiate processor and memories
riscv_cpu rvcpu    (clk, reset, PC, Instr,
                    MemWrite_rv32, DataAdr_rv32,
                    WriteData_rv32, ReadData, Result);
instr_mem instrmem (PC, Instr);
data_mem  datamem  (clk, MemWrite, DataAdr, merged_wr_data, ReadData);

// byte/half-word read-modify-write for sb/sh (does not modify data_mem)
// merge only on the wire into data_mem, so the WriteData pin stays the raw rs2 value
assign merged_wr_data = (Instr[14:12] == 3'b000) ?                                         // sb
    ((ReadData & ~(32'h000000FF << {DataAdr[1:0], 3'b0})) |
     ({24'b0, WriteData[7:0]} << {DataAdr[1:0], 3'b0})) :
    (Instr[14:12] == 3'b001) ?                                                             // sh
    ((ReadData & ~(32'h0000FFFF << {DataAdr[1], 4'b0})) |
     ({16'b0, WriteData[15:0]} << {DataAdr[1], 4'b0})) :
    WriteData;                                                                             // sw / others

assign MemWrite  = (Ext_MemWrite && reset) ? 1 : MemWrite_rv32;
assign WriteData = (Ext_MemWrite && reset) ? Ext_WriteData : WriteData_rv32;
assign DataAdr   = reset ? Ext_DataAdr : DataAdr_rv32;

endmodule