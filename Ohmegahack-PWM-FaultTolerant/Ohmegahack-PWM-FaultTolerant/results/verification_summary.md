# Verification Summary — Baseline vs. Protected Model

| Time (ns) | Event / Injection | Old Output (a, b) | New Output (a_safe, b_safe) | Status / Result |
|---|---|---|---|---|
| 0  | System Reset | (0, 0) | (0, 0) | Both safe |
| 20 | Normal Operation (State S0) | (1, 0) | (1, 0) | Channel A active |
| 50 | 1-Cycle Noise Spike on `eq` | (0,0) → (0,1) — state jumps S0→S1→S2 early | (1, 0) | OLD: premature switch. NEW: glitch filter blocks it. |
| 60 | Main Power Transistor Turn-off (delayed switching overlap) | Shoot-Through! (1,1) DETECTED | Clean Dead-Time (0,0) — override active | OLD: boards blow up. NEW: hard override saves it. |

See [`drc_report.txt`](./drc_report.txt) for the Vivado DRC report and
[`screenshots/`](./screenshots) for the synthesis schematic and simulation
run captured during the event.

Full architecture write-up, the 4-layer defense mechanism, and the
power/performance/area (PPA) trade-off analysis are in
[`../docs/report/PWM_Fault_Tolerant_Report.docx`](../docs/report/PWM_Fault_Tolerant_Report.docx).
