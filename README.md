# RTL Projects

Verilog designs for a single-cycle RISC-V processor, a fault-tolerant PWM generator, and an 8-bit GCD calculator.

| Project | What it is |
| --- | --- |
| [Single-cycle RV32I CPU](#1-single-cycle-rv32i-risc-v-cpu) | One-instruction-per-cycle RISC-V core  |
| [Fault-tolerant PWM generator](#2-fault-tolerant-multi-layer-pwm-generator) | Complementary PWM with dynamic dead time and four hardware protection layers. 1st place, Ohmegahack 2026 |
| [GCD module](#3-gcd-module) | Euclidean GCD in an FSM plus datapath, simulated with Icarus Verilog |

---

## 1. Single-cycle RV32I RISC-V CPU

A **single-cycle 32-bit RISC-V (RV32I)** processor 
The core fetches one instruction per clock, decodes it, executes it in the ALU, and writes the result back in the same cycle. Instruction and data memories sit beside the processor in the top-level module `riscv_cpu`.

Target device in the Quartus project: **Cyclone IV E (EP4CE22F17C6)**.

### Supported instructions

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

### Design

```
riscv_cpu
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

### Layout

```
riscv_cpu/
├── code/                   RTL
│   ├── riscv_cpu.v      top module
│   ├── riscv_cpu.v
│   ├── instr_mem.v
│   ├── data_mem.v
│   ├── components/         ALU, decoder, datapath, register file, muxes
│   ├── rv32i.s     Task 1C assembly test
│   └── rv32i.hex   machine code loaded by instr_mem
├── .test/                  ModelSim testbenches (tb_1b.v, tb_1c.v)
├── riscv_cpu.qpf        Quartus project
└── riscv_cpu.qsf        device and file assignments
```

`instr_mem` reads `rv32i_test_1c.hex` at simulation start. 

Quartus and ModelSim also write `db/`, `incremental_db/`, `output_files/`, and `simulation/`. Those folders are generated and do not need to be committed.



## 2. Fault-tolerant multi-layer PWM generator

**1st place — Ohmegahack: Design, Innovate, Tapeout.**  
ICSD × TechnoVIT × IEEE CEDA Madras Section, VIT Chennai — 29 Aug 2026.  
Team 4 · M. Shreemathi (SSN College of Engineering).

Two power transistors drive a motor. If both turn on together, the board short-circuits. This design generates two continuous PWM signals that are exact inverses of each other, and forces both low for a programmable dead time before either goes high. A new dead-time value can arrive at any time, but it takes effect only at the start of the next full PWM period.

The hackathon check was zero overlap in simulation, and a delayed apply of the new dead time.

The full problem set (Problems 1–10) is in [`docs/problem_statement.md`](docs/problem_statement.md).

### Baseline

`rtl/baseline/` meets the spec and nothing more. Two complementary PWM outputs, dead time applied only on the next period boundary, and no protection if the hardware itself is wrong.

| File | Module | Role |
| --- | --- | --- |
| `top.v` | `top` | Wires the design; ports are `clk`, `rst`, `on_time`, `dead_in`, `a`, `b` |
| `control_path.v` | `controlpath` | 4-state FSM (`S0`–`S3`) that sequences the outputs |
| `datapath.v` | `datapath` | Selects `on_time` or `dead_time` as the counter reload |
| `counter.v` | `count` | 3-bit down-counter, reloads on `rst` / `cnt` |
| `zero_d.v` | `zero_d` | Combinational zero-detect (`eq = ~\|data`) |
| `tb.v` | `tb_top` | Reset, one period, mid-cycle `dead_in` update, `on_time` update, re-reset |

The FSM walks four states every PWM period:

1. **S0** — `a=1`, `b=0`. Counter runs for `on_time` (channel A on).
2. **S1** — `a=0`, `b=0`. Counter runs for `dead_time` (gap before B turns on).
3. **S2** — `a=0`, `b=1`. Counter runs for `on_time` (channel B on).
4. **S3** — `a=0`, `b=0`. Counter runs for `dead_time`, then returns to **S0** and pulses `new_period`.

`dead_time` is latched in `top` on `posedge clk`, and only when `new_period` fires. That is the “apply at the next period” rule.

```bash
cd rtl/baseline
iverilog -o tb_baseline.vvp top.v control_path.v datapath.v counter.v zero_d.v tb.v
vvp tb_baseline.vvp        # writes wave.vcd
gtkwave wave.vcd           # inspect a, b, and the dead-time gap
```

`tb.v` drives power-on reset, one full period, a mid-cycle `dead_in` change (must wait for the next period), a dynamic `on_time` change, and a second reset. An `always @(posedge clk)` check flags any cycle where `a` and `b` are both high.

Fault injection on this version showed four holes:

- **Single-event upsets.** The FSM state and the counter are each one unprotected register. One bit-flip corrupts them with no detect or recover path.
- **Sub-cycle glitches.** A 1-cycle spike on the `eq` compare wire causes an early state change. The FSM cannot tell a real zero-count from noise.
- **Turn-off delay drift.** Dead time is a fixed number. If the transistors turn off more slowly than expected, that gap is no longer enough, and the design does not notice.
- **Illegal FSM outputs on the pins.** If the FSM drives both `a` and `b` high, that value reaches the pins. There is no final interlock. Forcing `a=1` and `b=1` inside the design produced a real shoot-through on the pins.

The baseline shows the PWM idea is right. One glitch, bit-flip, or delay drift is enough to damage the power stage. The old-versus-new timeline is in [`results/verification_summary.md`](results/verification_summary.md).

### Protected design

`rtl/protected/` keeps that baseline chain unchanged, for comparison, and wraps a second copy in four independent layers. `top.v` runs both from the same inputs: unprotected `a_base` / `b_base`, and protected `a` / `b`.

**Layer 1 — spatial redundancy** (`voter3.v`, `dead_latch_tmr.v`, `tmr_wrapped_counter.v`, `tmr_wrapped_ns.v`).  
The dead-time latch, the down-counter, and the FSM state register are each triplicated. `voter3` takes a bitwise 2-of-3 majority every clock, so one flipped bit is removed before it reaches the output.

**Layer 2 — temporal filtering** (`glitch_filter.v`).  
Sits between `zero_d` and the FSM. `eq` is accepted only after it stays stable for several samples, so a 1-cycle spike cannot advance the state.

**Layer 3 — dynamic self-correction** (`self_correct.v`).  
Watches `overlap_now` from Layer 4. A sustained overlap increases `margin_add`, which is added to the voted dead time so the gap grows. That covers thermal drift and slower transistor turn-off. The margin shrinks again once the overlap clears.

**Layer 4 — hard override** (`hard_override_gate.v`).  
Combinational, with no clock, wired to the pins:

```
a_safe = a_raw & ~b_raw
b_safe = b_raw & ~a_raw
```

If Layers 1–3 still produce `a_raw` and `b_raw` high together, this gate forces both pins low in one gate delay, not one clock.

```
[on_time, dead_in] ──► Layer 1: TMR dead-time latch and counter
                              │
      [eq_raw] ──► Layer 2: glitch filter ──► eq (into FSM)
                              │
                    [FSM: a_raw, b_raw]
                              │
                    Layer 4: hard override ──► [a, b]
                              │
                    overlap_now ──► Layer 3: self-correction ──► margin_add
                                    (added back into Layer 1 dead time)
```

```bash
cd rtl/protected
iverilog -o tb_protected.vvp \
    top.v control_path.v datapath.v counter.v zero_d.v \
    voter3.v dead_latch_tmr.v tmr_wrapped_counter.v tmr_wrapped_ns.v \
    glitch_filter.v self_correct.v hard_override_gate.v testbench.v
vvp tb_protected.vvp      # writes pwm_deadtime.vcd
gtkwave pwm_deadtime.vcd  # compare a/b with a_base/b_base
```

`testbench.v` repeats the baseline stimulus and then injects one fault per layer: an SEU on a TMR register, a 1-cycle glitch on `eq`, a sustained overlap, and a forced `a_raw = b_raw = 1`. It prints pass or fail for each layer.

Protected outputs showed zero shoot-through under every injected fault. The baseline outputs, run in the same simulation, did shoot through. The comparison is in [`results/verification_summary.md`](results/verification_summary.md).

### Layout

```
├── docs/
│   ├── problem_statement.md
│   ├── report/                      # architecture and PPA write-up
│   └── event/                       # event poster
├── rtl/
│   ├── baseline/                    # unprotected design and tb.v
│   └── protected/                   # four layers plus the reused baseline chain
├── sim/
│   ├── baseline/
│   └── protected/
├── results/
│   ├── verification_summary.md
│   ├── drc_report.txt
│   └── screenshots/
└── .gitignore
```

Synthesized in Vivado 2025.2 (target `xc7vx485tffg1157-1`). DRC was clean apart from one informational `CFGBVS` warning. See [`results/drc_report.txt`](results/drc_report.txt). The architecture diagram and the power, performance, and area notes are in [`docs/report/PWM_Fault_Tolerant_Report.docx`](docs/report/PWM_Fault_Tolerant_Report.docx). TMR is most of the area and power. The override gate is almost free.

![Ohmegahack poster](docs/event/ohmegahack_poster.jpeg)

**Tools:** Icarus Verilog, GTKWave, Vivado 2025.2.

---

## 3. GCD module

An **8-bit greatest-common-divisor** block. It uses the subtractive Euclidean algorithm: keep replacing the larger number with the difference of the two until they are equal. That equal value is the GCD.

The picture below is the hardware and the states used to build the FSM.

![Hardware and FSM states](<WhatsApp Image 2026-06-14 at 7.21.23 AM.jpeg>)

### Datapath

1. Registers A and B (parallel-in, parallel-out)
2. Mux, to put the larger operand on the subtractor
3. Comparator
4. Subtractor

### FSM

| State | What it does |
| --- | --- |
| **S0** Idle | Load A |
| **S1** | Load B |
| **S2** | Compare A and B. `A > B` goes to S3. `A < B` goes to S4. `A = B` goes to S5 |
| **S3** | Subtract, drive the difference on the bus, write `A - B` back into A, return to S2 |
| **S4** | Subtract, drive the difference on the bus, write `B - A` back into B, return to S2 |
| **S5** | Present the GCD and stay in S5 |

### Synthesized hardware

![Synthesized hardware](image.png)

Synthesized datapath:

![Synthesized datapath](<Screenshot 2026-06-14 073254.png>)

Synthesized controller:

![Synthesized controller](<Screenshot 2026-06-14 073458.png>)

### How to run

Icarus Verilog and GTKWave need to be installed. Put every `.v` file in one folder, open a terminal there, and run:

```bash
iverilog -o tb-of.vvp pipo.v mux.v subt.v comp.v data_path.v fsm.v tb.v
vvp tb-of.vvp
gtkwave tb.vcd
```

`iverilog` compiles the testbench and every module it instantiates. `tb.v` instantiates `data_path` and `fsm`. Those instantiate `pipo`, `mux`, `subt`, and `comp`, so all of those files have to be on the command line. The compile writes `tb-of.vvp`.

`vvp` runs that file and prints simulation time and the values of A and B.

`gtkwave` opens `tb.vcd` so the same run can be checked on a waveform.

To try other inputs, edit the `initial` block in `tb.v`:

```verilog
data_in = 143;
#10 data_in = 78;
```

Each value must be from 0 to 255. The registers are 8 bits wide.

**Tools:** Icarus Verilog, GTKWave.
