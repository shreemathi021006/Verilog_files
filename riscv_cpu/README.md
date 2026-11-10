# Single-Cycle RV32I RISC-V CPU

Verilog implementation of a **single-cycle 32-bit RISC-V (RV32I)** processor for **e-Yantra Logic Quest, Task 1C** (team `lq_2062`).

The core fetches one instruction per clock, decodes it, executes it in the ALU, and writes the result back in the same cycle. Instruction and data memories sit beside the processor in the top-level module `t1_riscv_cpu`.

Target device in the Quartus project: **Cyclone IV E (EP4CE22F17C6)**.

## Supported instructions

| Group | Instructions |
| --- | --- |
| I-type ALU | `addi`, `slti`, `sltiu`, `xori`, `ori`, `andi`, `slli`, `srli`, `srai` |
| R-type | `add`, `sub`, `sll`, `slt`, `sltu`, `xor`, `srl`, `sra`, `or`, `and` |
| Upper immediate | `lui`, `auipc` |
| Loads | `lb`, `lh`, `lw`, `lbu`, `lhu` |
| Stores | `sb`, `sh`, `sw` |
| Branches | `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` |
| Jumps | `jal`, `jalr` |

Loads sign- or zero-extend the addressed byte or half-word. Stores do a read-modify-write on the word so `sb` and `sh` only update the selected bytes.

## Design

```
t1_riscv_cpu
├── riscv_cpu
│   ├── controller
│   │   ├── main_decoder    opcode → control signals
│   │   └── alu_decoder     funct3 / funct7 → ALU operation
│   └── datapath
│       ├── PC + adders + PC mux (sequential, branch, jalr)
│       ├── register file (x0 hardwired to 0)
│       ├── immediate extender
│       └── ALU
├── instr_mem               512 words, loaded from a .hex file
└── data_mem                64 words, synchronous write
```

- **PC next:** `PC+4`, `PC+immediate` (branch / `jal`), or `rs1+immediate` (`jalr`).
- **ALU operand A:** register (`rs1`), `PC` (`auipc`), or `0` (`lui`).
- **Result writeback:** ALU result, extended load data, or `PC+4` (link address for jumps).

## Repository layout

```
t1_riscv_cpu/
├── code/                   RTL (this is the design)
│   ├── t1_riscv_cpu.v      top module
│   ├── riscv_cpu.v
│   ├── instr_mem.v
│   ├── data_mem.v
│   ├── components/         ALU, decoder, datapath, register file, muxes
│   ├── rv32i_test_1c.s     Task 1C assembly test
│   └── rv32i_test_1c.hex   machine code loaded by instr_mem
├── .test/                  ModelSim testbenches (tb_1b.v, tb_1c.v)
├── t1_riscv_cpu.qpf        Quartus project
└── t1_riscv_cpu.qsf        device and file assignments
```

`instr_mem` reads `rv32i_test_1c.hex` at simulation start. Swap the `$readmemh` path in `code/instr_mem.v` to load `rv32i_test_1b.hex` or `rv32i_book.hex` instead.

Quartus and ModelSim also write `db/`, `incremental_db/`, `output_files/`, and `simulation/`. Those are generated and do not need to be committed.

## Simulate

1. Open `t1_riscv_cpu/t1_riscv_cpu.qpf` in **Intel Quartus Prime**.
2. Set the simulation tool to **ModelSim-Altera** (Tools → Options → EDA Tool Options) if it is not already.
3. Run **RTL Simulation** (Tools → Run Simulation Tool → RTL Simulation).
4. In the ModelSim transcript, compile and run `tb_1c`:

```tcl
do t1_riscv_cpu_run_msim_rtl_verilog.do
```

The testbench steps through the program in `rv32i_test_1c.s` and prints whether each instruction produced the expected result. A clean run ends with `No Faults`.

## Tools

- Intel Quartus Prime (Cyclone IV E)
- ModelSim-Altera
- Verilog HDL
