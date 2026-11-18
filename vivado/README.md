# Vivado FPGA flow

## Files

- `create_ml_kem_project.tcl` creates a project for the exact `xc7a100tcsg324-1` part.
- `ml_kem_512.xdc` defines a 100 MHz baseline clock constraint.
- `run_synth.tcl` launches synthesis and writes utilization, timing, and methodology reports.

Run from the repository root:

```text
vivado -mode batch -source vivado/run_synth.tcl
```

## Current synthesis status

The project now contains the real production hierarchy:

- `ml_kem_512_top`
- `ml_kem_512_engine`
- `ml_kem_fips203_pkg`

Vivado 2026.2 successfully parsed and elaborated the hierarchy. Netlist expansion did not complete: the current package-based cryptographic functions are evaluated in the engine's `COMPUTE` state, producing an enormous unbounded combinational graph. During the checked run, synthesis remained in expansion for more than seven minutes and exceeded 10 GB resident memory before termination.

Consequently, LUT/FF/BRAM/DSP utilization and post-synthesis timing reports could not be produced from the current RTL. This is a hardware-architecture blocker, not an HDL syntax problem.

## Required architecture before meaningful timing reports

1. Implement one Keccak round, or a small fixed round group, per cycle.
2. Implement iterative absorb, padding, and squeeze control.
3. Implement NTT/INTT as staged coefficient-memory butterflies.
4. Replace whole-polynomial function calls with coefficient- or block-based operations.
5. Store key, ciphertext, and polynomial data in BRAM-compatible memories.
6. Re-run synthesis and collect the generated reports.

The 100 MHz target must be treated as a baseline requirement, not as a met timing result.
