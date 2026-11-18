# Simulation utilities

## Detailed regression report

Run from the repository root:

```text
python3 sim/utils/run_regression_report.py --suite all
```

Available suites:

- `functional`: deterministic and randomized unit/round-trip tests
- `acvp`: complete ML-KEM-512 ACVP catalog
- `all`: functional plus ACVP tests

Reports are written to `sim/reports/`:

- `latest.log`: beginner-friendly readable report
- `latest.json`: machine-readable report
- Timestamped `.log` and `.json` copies are retained for comparison

The report records each test's purpose, inputs, expected result, exact compiler/simulator output, warnings/errors, command, return code, duration, and ACVP case-level input/expected/actual information.

## Other utilities

- `generate_acvp_vectors.py`: regenerate `sim/vectors/full` and its source manifest.
- `mlkem512_ref.py`: independent Python ML-KEM-512 reference and randomized checks.
