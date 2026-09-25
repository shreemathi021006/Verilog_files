# Verilog Files

A collection of digital design projects in Verilog HDL, spanning RTL design,
simulation (Icarus Verilog + GTKWave), and FPGA implementation (Xilinx Vivado).

## Projects

### [`gcd-module-in-verilog/`](./gcd-module-in-verilog)
A GCD (Greatest Common Divisor) computation module — classic datapath + FSM
design, simulated with Icarus Verilog and GTKWave.

- **Datapath:** registers A & B, mux, comparator, subtractor
- **FSM:** 6-state controller (`S0`–`S5`) that loads inputs, compares A and
  B, subtracts the smaller from the larger, and repeats until A = B
- Includes the design flowchart, synthesized schematic screenshots, and a
  saved GTKWave waveform (`waveform.gtkw`)

**Run it:**
```bash
cd gcd-module-in-verilog
iverilog -o tb-of.vvp pipo.v mux.v sub.v comp.v data_path.v fsm.v tb.v
vvp tb-of.vvp
gtkwave tb.vcd
```

### [`vivado-files/`](./vivado-files)
Verilog projects built and simulated in Xilinx Vivado.

- **Half Adder** (`Adder/half adder/`) — basic combinational half adder with
  testbench
- **AHB-to-APB Bridge** (`ahb to apb bridge/`) — an `AHB_slave_interface`
  and `APB_controller` bridged together (`Top.v` / `bridge_wrapper.v`),
  built as part of a design internship; internship reports (PDF) included

**Run it:** open the relevant `.xpr` file in Vivado, or open the `.srcs`
folder to browse the source and testbench files directly.

## Repository layout

## Projects

### [`Ohmegahack-PWM-FaultTolerant/`](./Ohmegahack-PWM-FaultTolerant)
🏆 **1st Place — Ohmegahack: Design, Innovate, Tapeout** (ICSD × TechnoVIT ×
IEEE CEDA Madras Section, VIT Chennai)

A 4-layer fault-tolerant PWM generator with dynamic dead-time control —
built to guarantee zero shoot-through on a motor driver's complementary
outputs even under bit-flips, glitches, and thermal drift. Includes the
original unprotected baseline design alongside the protected version, full
verification results, a Vivado DRC report, and the architecture write-up.

- **Baseline:** simple FSM-driven PWM with a fixed, updatable dead time
- **Protected:** adds Triple Modular Redundancy, a glitch filter, a
  self-correcting dead-time margin, and a combinational hard-override gate
- See its own [README](./Ohmegahack-PWM-FaultTolerant/README.md) for the
  full breakdown, simulation instructions, and results


