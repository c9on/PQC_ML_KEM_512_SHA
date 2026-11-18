# ML-KEM-512 documentation

This folder is the complete beginner-oriented documentation for this repository.

## Start here

1. `RTL_README.md` — ML-KEM-512 mathematics, every RTL file, and the complete data/control flow.
2. `TESTBENCH_README.md` — every testbench, test order, ACVP files, reports, and debugging.
3. `ARCHITECTURE.md` — ports, commands, statuses, byte order, storage, latency, and hierarchy.
4. `SYNTHESIS.md` — Vivado commands, constraints, reports, and the current combinational-path blocker.
5. `SECURITY.md` — assumptions, limitations, side-channel concerns, and certification status.

## Important status statement

**This project is not FIPS certified.** It has algorithmic and NIST ACVP simulation coverage, but ACVP pass results and a functional RTL simulation do not constitute NIST certification. The current implementation is not yet a practical timing-closed FPGA implementation because cryptographic operations are expanded as large combinational package functions during the `COMPUTE` state.

## Repository layout

```text
rtl/                         SystemVerilog source
  common/                    ML-KEM/FIPS 203 helper package
  ml_kem/                    production top and engine
  keccak/, sha3/, ntt/, poly/ standalone unit RTL
sim/tb/                      SystemVerilog testbenches
sim/utils/                   vector generation, reference model, reporting
sim/vectors/full/            generated official ACVP memories and manifest
vivado/                      FPGA project, constraints, and synthesis scripts
docs/                        this documentation
```

## Fast verification path

Run from the repository root:

```text
bash sim/run_iverilog.sh functional
bash sim/run_iverilog.sh acvp
python3 sim/utils/run_regression_report.py --suite all
```

Do not begin with synthesis. First understand the algorithm and pass the simulation suite.
