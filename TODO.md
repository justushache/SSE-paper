# Plan for paper

Points from the notebook plan. Checked = in `main.tex` with text and figure.
Notes say what is still open on a point.

## 1. Algorithm & task, description & motivation

- [x] Einleitung / Motivation — citations still missing (Cooley–Tukey), template line "Zitiert wird so …" still in
- Implementierung
  - [x] Eingabe — open `%TODO`: bit reversal of the addresses
  - [x] Ausgabe
  - [x] Implementierung — three `TODO: reference` / `TODO: link` still in the text
  - [ ] Arithmetik — only the template placeholder

## 2. Entwurf

- [x] NSD flowchart (`pics/FFT_flowchart.png`) — `stagepow = 2*stagepow` sits after the outer loop instead of inside it; `\label` before missing `\caption`, so the ref does not work
- [x] Unoptimized DPath (`pics/Complex Datapath architecture.png`) — figure has no `\caption` yet
- [x] Unoptimized FSM (`pics/fsm_live/FFT.png` + complex substates) — figures have no `\caption` yet; ML3 in `butterfly.json` still jumps to itself instead of ML4
- [-] Transfer analysis — section still holds the template table (R1, RCX, Rres …), not in paper, becuase irrelevant after complex + 2 ALU optimization
- [-] Optimized DPath, not in paper, see above

### Combined in paper: complex DPath + 2nd ALU

- Complex DPath
  - [x] Complex datapath elements (complex ALU, complex MUL) with figures
  - [ ] Unopt. FSM — exists as `pics/fsm_live_complex/fsmlive/butterfly.json`, not in the paper yet
  - [ ] Transfer analysis
  - [ ] Opt. DPath
- 2nd ALU
  - [ ] Unopt. DPath
  - [ ] Unopt. FSM
  - [ ] Transfer analysis
  - [ ] Opt. DPath

### Pipelining

- [ ] Further opt. DPath
- [ ] Final FSM

### Custom DPath elements

- [ ] Implementation of custom DPath elements (complex ALU/MUL drawn; `do_gen`, `2^(len)`, address generation still open)

## 3. Final implementation

- [ ] Final datapath
- [ ] FSM (incl. state encoding — template table still in)
- [ ] Control logic

## 4. Verification

- [ ] Single verification
- [ ] Verification script
- [ ] Synthesis & netlist verify
- [ ] Circuit synthesis & verify
- [ ] Layout
