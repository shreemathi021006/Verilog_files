# RTL Hackathon – Phase 1 Problem Statements

Full problem set as issued in Phase 1. **This project solves Problem 8**
(highlighted below) — a dead-time-protected, fault-tolerant PWM generator.

---

## ✅ Problem 8 (solved in this repo)

**Scenario:** Two power transistors control a motor. If both turn on at the
same time, the board short-circuits.

**The Catch:** Generate two continuous pulse-width modulated (PWM) signals
that are exact inverses of each other. However, you must enforce a
programmable "dead time" (e.g., 5 clock cycles) where BOTH signals are
forced low before one transitions high. The dead time value can change
dynamically via an input register, but the new value must only apply at
the start of the next full PWM period.

**Evaluation:** Zero overlap events in simulation and correct delayed
application of the parameter update.

---

## Problem 1
A downstream peripheral requires a clock signal exactly 2.5x slower than
the main system clock, with an exact 50% duty cycle, built only from
edge-triggered flip-flops (both clock edges used, no combinational loops).

## Problem 2
Recover 8-bit serial data at 16x the baud rate using a 3-tick middle
sampling window per bit, robust to random 1-cycle noise spikes.

## Problem 3
Compute hypotenuse/angles for a robotic arm using only shift-and-add
operations (no multiplier/divider), pipelined to one result per cycle.

## Problem 4
Four cores share a memory bus with fixed priority (Core 0 highest). Any
core denied for 16 consecutive cycles gets a 3-cycle overriding lock
before returning to normal priority, with no combinational feedback loops.

## Problem 5
Detect a read-after-write hazard between consecutive instructions without
data forwarding; stall fetch for exactly one cycle to resolve it.

## Problem 6
A memory controller compares the top 20 bits of consecutive addresses:
matching addresses assert `valid_data` in 1 cycle, mismatches stall and
wait exactly 4 cycles before asserting `valid_data`.

## Problem 7 (see below, solved as-is)
An 8-bit serial receiver bracketed by `chip_enable` must discard a partial
packet and re-align to accept a new packet the very next cycle if
`chip_enable` drops early (after 3, 5, or 7 bits) — no manual reset.

## Problem 8 — see above (this project)

## Problem 9
Four parallel data streams flow diagonally through a 2x2 grid of adders;
each stream needs an exact, individually-computed cycle delay so they
arrive synchronized at each grid position.

## Problem 10
Count leading zeros of a 32-bit word and output a 5-bit result in a single
clock cycle, using purely combinational logic (no iterative/FSM shifting).
