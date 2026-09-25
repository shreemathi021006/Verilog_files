# Fault-Tolerant Multi-Layer PWM Generator with Dynamic Dead-Time Control

🏆 **1st Place — Ohmegahack: Design, Innovate, Tapeout**
ICSD × TechnoVIT × IEEE CEDA Madras Section, VIT Chennai — 29 Aug 2026

Team 4 · M. Shreemathi (SSN College of Engineering)

---

## Problem Statement

> Two power transistors control a motor. If both turn on at the same time,
> the board short-circuits. Generate two continuous PWM signals that are
> exact inverses of each other, enforcing a programmable dead time (both
> signals forced low) before either transitions high. The dead-time value
> can change dynamically, but the new value must only take effect at the
> start of the next full PWM period.
>
> **Evaluation:** zero overlap events in simulation, correct delayed
> application of the parameter update.

Full problem set for the hackathon (Problems 1–10) is in
[`docs/problem_statement.md`](docs/problem_statement.md).

---

## Part 1 — The old (baseline) code

`rtl/baseline/` is the first-pass design: it satisfies the letter of the
spec — two complementary PWM outputs with a programmable dead time that
only takes effect at the next period boundary — but has no protection
against anything going wrong in the hardware itself.

### Modules

| File | Module | Role |
|---|---|---|
| `top.v` | `top` | Wires everything together; exposes `clk`, `rst`, `on_time`, `dead_in`, `a`, `b` |
| `control_path.v` | `controlpath` | 4-state FSM (`S0`–`S3`) that sequences the outputs |
| `datapath.v` | `datapath` | Picks `on_time` or `dead_time` as the counter's reload value |
| `counter.v` | `count` | 3-bit down-counter, reloads on `rst`/`cnt` |
| `zero_d.v` | `zero_d` | Combinational zero-detect (`eq = ~|data`) on the counter |
| `tb.v` | `tb_top` | Testbench: reset, one full period, mid-cycle `dead_in` update, `on_time` update, re-reset |

### How it works

The FSM in `controlpath` walks four states every PWM period:

1. **S0** — `a=1, b=0`, counter counts down `on_time` (channel A's on-time).
2. **S1** — `a=0, b=0`, counter counts down `dead_time` (the gap before B turns on).
3. **S2** — `a=0, b=1`, counter counts down `on_time` again (channel B's on-time).
4. **S3** — `a=0, b=0`, counter counts down `dead_time` again, then returns to **S0** and pulses `new_period`.

`dead_time` itself is latched in `top` on `posedge clk`: it only loads the
new `dead_in` value when `new_period` fires, which is exactly the "changes
apply only at the start of the next period" requirement from the spec.

### How to run it

Using [Icarus Verilog](http://iverilog.icarus.com/):

```bash
cd rtl/baseline
iverilog -o tb_baseline.vvp top.v control_path.v datapath.v counter.v zero_d.v tb.v
vvp tb_baseline.vvp        # writes wave.vcd
gtkwave wave.vcd           # inspect a / b and the dead-time gap
```

`tb.v` drives: power-on reset → one full PWM period → a mid-cycle
`dead_in` change (must **not** apply until the next period) → a dynamic
`on_time` change → a re-reset check — with a continuous
`always @(posedge clk)` assertion that flags any cycle where `a` and `b`
are both high at once.

### Faults in the old code

This design only works if the hardware behaves perfectly. It has **no
protection** against any of the following, all of which were fault-injected
during verification:

- **Single Event Upsets (bit-flips).** The FSM state and counters are each
  a single, unprotected register. A single bit-flip (radiation, EMI)
  silently corrupts the state with no way to detect or recover from it.
- **Sub-cycle noise glitches.** A 1-cycle glitch forced onto the `eq`
  compare wire triggers an immediate, premature state transition — the FSM
  has no way to tell a real zero-count from a transient spike.
- **Thermal / turn-off delay drift.** The dead time is a fixed, static
  value. If the actual transistors turn off slower than expected (thermal
  drift), the fixed dead time is no longer enough margin, and the design
  has no way to notice or compensate.
- **FSM corruption reaching the pins directly.** If the control FSM is
  ever forced into an illegal state where both `a` and `b` are driven
  high, that failure propagates straight to the output pins — there's no
  last-line hardware interlock to stop it. In the fault-injection test,
  forcing `a=1` and `b=1` internally produced a real shoot-through
  (`a=1, b=1` on the physical pins).

In short: the old code proves the *idea* is correct, but a single glitch,
bit-flip, or delay drift is enough to blow up the power stage. See
[`results/verification_summary.md`](results/verification_summary.md) for the
exact old-vs-new event timeline captured during the hackathon.

---

## Part 2 — The new (protected) code

`rtl/protected/` keeps the exact same baseline chain (reused, unmodified,
for side-by-side comparison) and wraps it in **4 independent defense
layers**, each aimed at one of the faults above.

`top.v` in this folder instantiates **both** chains off the same inputs:
the original baseline (`a_base`, `b_base` — left completely unprotected,
for comparison) and the new protected chain (`a`, `b`).

### The 4 layers

**Layer 1 — Spatial Redundancy (`voter3.v`, `dead_latch_tmr.v`, `tmr_wrapped_counter.v`, `tmr_wrapped_ns.v`)**
Triple Modular Redundancy: the dead-time latch, the down-counter, and the
FSM state register are each triplicated. `voter3` does a bitwise 2-of-3
majority vote on every clock edge, so a single bit-flip in any one copy
is scrubbed away before it can affect the output — it never even needs to
be individually detected.

**Layer 2 — Temporal Filtering (`glitch_filter.v`)**
Sits between `zero_d` and the FSM. It only lets `eq` (the counter's
zero-detect signal) through once it has been observed as stable across
multiple consecutive samples, so a 1-cycle noise spike on the compare wire
is filtered out before it can trigger a premature transition.

**Layer 3 — Dynamic Self-Correction (`self_correct.v`)**
Watches `overlap_now` (fed back from Layer 4, below). If it sees a
*sustained* overlap condition — not just one glitchy event — it grows
`margin_add`, which is added on top of the TMR-voted `dead_latched` value
to widen the dead-time band going forward. This is what compensates for
thermal drift or transistor turn-off delay that a fixed dead time can't
absorb, and it relaxes back down once the anomaly clears.

**Layer 4 — Hard Override Gate (`hard_override_gate.v`)**
The last line of defense: pure combinational logic with **no clock at
all**, wired directly to the output pins:

```
a_safe = a_raw · ¬b_raw
b_safe = b_raw · ¬a_raw
```

If every layer above somehow still produces `a_raw=1` and `b_raw=1` at
the same time (e.g. Layers 1–3 don't catch a novel failure mode), this
gate reacts within a single gate-propagation delay — not a clock period —
and forces both pins low instead. It's the only layer that can't be
outrun by a synchronous fault.

### How the layers connect

```
[on_time, dead_in] ──► Layer 1: TMR-voted dead-time latch & counter
                              │
      [eq_raw] ──► Layer 2: Glitch Filter ──► eq (into FSM)
                              │
                    [FSM: a_raw, b_raw]
                              │
                    Layer 4: Hard Override Gate ──► [a, b]  (safe outputs)
                              │
                    overlap_now ──► Layer 3: Self-Correction ──► margin_add
                                          (feeds back into Layer 1's dead-time)
```

### How to run it

```bash
cd rtl/protected
iverilog -o tb_protected.vvp \
    top.v control_path.v datapath.v counter.v zero_d.v \
    voter3.v dead_latch_tmr.v tmr_wrapped_counter.v tmr_wrapped_ns.v \
    glitch_filter.v self_correct.v hard_override_gate.v testbench.v
vvp tb_protected.vvp      # writes pwm_deadtime.vcd
gtkwave pwm_deadtime.vcd  # compare a/b against a_base/b_base
```

`testbench.v` runs the same kind of stimulus as the baseline testbench
(reset, normal operation, dynamic `on_time`/`dead_in` updates, mid-run
reset) plus **explicit fault injection for each of the 4 layers** — an SEU
on a TMR'd register, a 1-cycle glitch on `eq`, a sustained overlap
condition, and a forced `a_raw=b_raw=1` — and prints a pass/fail summary
for each layer at the end.

### Result

Zero shoot-through events on the protected outputs under every injected
fault, against a confirmed shoot-through on the unprotected baseline
outputs run in parallel in the same simulation. Full comparison table:
[`results/verification_summary.md`](results/verification_summary.md).

---

## Repository layout

```
├── docs/
│   ├── problem_statement.md         # full hackathon problem set
│   ├── report/                      # full write-up: architecture, PPA analysis
│   └── event/                       # event poster
├── rtl/
│   ├── baseline/                    # Part 1: original, unprotected design
│   │   ├── top.v, control_path.v, datapath.v, counter.v, zero_d.v
│   │   └── tb.v                     # testbench (dead-time / mid-cycle-update / reset checks)
│   └── protected/                   # Part 2: 4-layer fault-tolerant design
│       ├── top.v                    # instantiates baseline + protected chains together
│       ├── voter3.v, dead_latch_tmr.v, tmr_wrapped_counter.v, tmr_wrapped_ns.v   (Layer 1)
│       ├── glitch_filter.v                                                       (Layer 2)
│       ├── self_correct.v                                                        (Layer 3)
│       ├── hard_override_gate.v                                                  (Layer 4)
│       ├── control_path.v, datapath.v, counter.v, zero_d.v  # baseline chain reused for comparison
│       └── testbench.v              # full 4-layer fault-injection testbench
├── sim/
│   ├── baseline/                    # .vcd waveforms from the baseline run
│   └── protected/                   # .vcd waveforms from the protected run
├── results/
│   ├── verification_summary.md      # baseline vs. protected event timeline
│   ├── drc_report.txt               # Vivado DRC report (post-synthesis)
│   └── screenshots/                 # synthesis schematic, Vivado run capture
└── .gitignore
```

## Additional results

- Synthesized in Vivado 2025.2 (target `xc7vx485tffg1157-1`); DRC came back
  clean apart from one informational `CFGBVS` property warning — see
  [`results/drc_report.txt`](results/drc_report.txt).
- Full architecture diagram and a layer-by-layer Power/Performance/Area
  trade-off analysis (TMR dominates area/power cost, the hard override
  gate is essentially free) are in
  [`docs/report/PWM_Fault_Tolerant_Report.docx`](docs/report/PWM_Fault_Tolerant_Report.docx).

## Event

![Ohmegahack poster](docs/event/ohmegahack_poster.jpeg)

Organized by ICSD, TechnoVIT, and IEEE CEDA Madras Section at VIT Chennai.
