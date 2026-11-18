# Synthesis and FPGA integration

## Project target

The Vivado flow targets:

```text
xc7a100tcsg324-1
```

Files are under `vivado/`:

- `create_ml_kem_project.tcl`: creates the project and selects the production hierarchy.
- `ml_kem_512.xdc`: declares a 100 MHz baseline clock.
- `run_synth.tcl`: launches synthesis and writes reports.
- `README.md`: short execution summary.

## Run synthesis

From the repository root, using a configured Vivado environment:

```text
vivado -mode batch -source vivado/run_synth.tcl
```

Expected report outputs, after successful synthesis:

```text
vivado_build/reports/utilization.rpt
vivado_build/reports/timing_summary.rpt
vivado_build/reports/timing_paths.rpt
vivado_build/reports/methodology.rpt
vivado_build/reports/design_analysis.rpt
```

## What was observed

Vivado 2026.2 successfully parsed and elaborated `ml_kem_512_top` and `ml_kem_512_engine`. Netlist expansion then consumed more than 10 GB resident memory and did not complete in a practical run.

Therefore no trustworthy final LUT, FF, BRAM, DSP, or timing result is available for the current RTL.

## Root architectural cause

The `COMPUTE` state calls large package functions that synthesize as one combinational graph. That graph includes repeated hash permutations, NTT butterflies, polynomial operations, key serialization, encryption, and re-encryption.

Vivado has no useful register boundary around this work, so it tries to expand the entire graph. Splitting only the outer FSM does not remove the underlying combinational critical path.

## 100 MHz constraint

`ml_kem_512.xdc` contains:

```text
create_clock -name clk -period 10.000 [get_ports clk]
```

This is a target, not evidence that the design meets 100 MHz.

No board I/O delays are included. Add `set_input_delay` and `set_output_delay` only after defining the external transport interface and physical source/destination clock relationships.

## Meaningful synthesis checklist

Before the next synthesis attempt:

1. Implement a bounded Keccak round unit.
2. Add absorb/pad/squeeze controllers.
3. Implement iterative NTT/INTT butterflies.
4. Put polynomials and full keys/ciphertexts in inferred memories.
5. Implement coefficient/block-level arithmetic.
6. Partition compute states so no state spans an entire ML-KEM operation.
7. Re-run ACVP after every hardware refactor.
8. Re-run Vivado synthesis and inspect actual report values.
9. Add clock and external interface timing constraints.
10. Run implementation, place/route, and post-route timing.

## Report interpretation

- LUTs indicate combinational lookup usage.
- FFs indicate registers.
- BRAM/DSP show memory and arithmetic primitive use.
- Worst negative slack (WNS) below zero means the timing target is not met.
- A large number of logic levels indicates an oversized combinational path even if raw utilization fits.
- The design must be evaluated after implementation, not only synthesis, before making board-level claims.
