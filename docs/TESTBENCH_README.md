# Testbench and verification guide

## 1. Recommended test order

A new user should run tests in this order:

```text
1. Keccak and hash primitives
2. NTT and polynomial arithmetic
3. Randomized polynomial verification
4. Randomized end-to-end ML-KEM round trips
5. Complete NIST ACVP catalog
6. Detailed regression report
```

From the repository root:

```text
bash sim/run_iverilog.sh functional
bash sim/run_iverilog.sh acvp
bash sim/run_iverilog.sh all
python3 sim/utils/run_regression_report.py --suite all
```

`run_iverilog.sh` compiles every bench independently, so a failure in one bench does not hide another bench.

---

## 2. Testbench directory

All SystemVerilog benches are under `sim/tb/`.

### 2.1 `tb_keccak_f1600.sv`

- DUT: `keccak_f1600`
- Input: all-zero 1600-bit state
- Expected: lane zero equals `F1258F7940E1DDE7`
- Purpose: checks the 24-round permutation baseline.

### 2.2 SHA3/SHAKE benches

- `tb_sha3_256.sv`
- `tb_sha3_512.sv`
- `tb_shake128.sv`
- `tb_shake256.sv`

Each bench supplies an official ACVP message, starts the DUT, waits for `valid`, and compares the complete digest with a fixed expected value.

These benches test the standalone RTL under `rtl/sha3`, not the production package functions directly. The complete ML-KEM ACVP suite additionally exercises the package hash/XOF functions inside key generation, encapsulation, and decapsulation.

### 2.3 `tb_ntt_256.sv`

- Input: coefficients $1,2,\ldots,256$.
- Checks: no `X` output, complete `valid`, and four exact NTT reference coefficients.
- Limitation: this is a small standalone unit bench, not a full 256-coefficient KAT.

### 2.4 `tb_intt_256.sv`

- Input: same coefficient sequence.
- Checks: four inverse-NTT reference coefficients and `valid`.
- Limitation: full randomized NTT/INTT coverage is provided separately by `tb_ml_kem_512_randomized.sv`.

### 2.5 `tb_poly_arith.sv`

Checks coefficient-zero addition, subtraction, and coefficient-wise multiplication of the standalone `poly_arith` unit.

### 2.6 `tb_poly_core.sv`

Checks coefficient-zero addition and difference of `poly_core`.

### 2.7 `tb_ml_kem_512_randomized.sv`

This bench verifies the actual FIPS 203 package helpers:

- 32 deterministic random polynomial pairs
- full 256-coefficient NTT/INTT round trip
- direct negacyclic convolution comparison with `basemul`
- 12-bit pack/unpack
- 10-bit pack/unpack field checks
- 4-bit pack/unpack field checks
- compression range checks
- message encode/decode round trips

The LFSR makes the input reproducible, unlike simulator-dependent `$random` values.

### 2.8 `tb_ml_kem_512_random_roundtrip.sv`

This bench uses the **production** `ml_kem_512_top` interface.

For each of 8 deterministic trials:

1. Generate random $d$ and $z$.
2. Run key generation.
3. Use resulting EK and DK.
4. Generate a random message.
5. Encapsulate and save ciphertext/shared secret.
6. Decapsulate the ciphertext.
7. Require the shared secrets to match.

This checks that the complete KEM path is internally consistent independently of one stored ACVP key.

### 2.9 `tb_ml_kem_512_acvp_full.sv`

This is the primary conformance regression.

It loads the official generated memories under `sim/vectors/full` and checks:

- 25 ML-KEM-512 key-generation cases
- 25 encapsulation cases
- 10 decapsulation cases
- 10 decapsulation-key checks
- 10 encapsulation-key checks

Every functional value is compared over the full width, including complete 800-byte EK, 1632-byte DK, 768-byte ciphertext, and 32-byte shared secret.

---

## 3. ACVP memory workflow

### Regenerate vectors

```text
python3 sim/utils/generate_acvp_vectors.py
```

The script downloads prompt and expected-result JSON from the NIST ACVP-Server repository and writes one hexadecimal vector per line.

Generated outputs:

```text
kg_d.mem kg_z.mem kg_ek.mem kg_dk.mem
enc_ek.mem enc_m.mem enc_c.mem enc_k.mem
dec_dk.mem dec_c.mem dec_k.mem
dkcheck_dk.mem dkcheck_passed.mem
ekcheck_ek.mem ekcheck_passed.mem
```

`manifest.json` records:

- source repository
- revision/branch
- source URLs
- SHA-256 hashes of downloaded JSON
- test counts per operation

Do not hand-edit generated memory files. Regenerate them and inspect the manifest.

### Why two validation levels?

- ACVP proves exact agreement for selected official deterministic vectors.
- Randomized tests cover broad polynomial and end-to-end behavior beyond the selected catalog.

Neither alone is a substitute for side-channel, synthesis, formal, or certification work.

---

## 4. Detailed reports

Run:

```text
python3 sim/utils/run_regression_report.py --suite all
```

The utility writes `sim/reports/latest.log` and timestamped reports. Reports are ignored by Git.

Each test section contains:

- purpose
- input description
- expected result
- exact compile command
- exact VVP command
- compiler/simulator return codes
- raw simulator output
- warnings/errors extracted for debugging
- ACVP case-by-case source values for the complete catalog

### Reading a failure

1. Find `FAILED TESTS` at the end.
2. Open the corresponding `TEST ... [FAIL]` section.
3. Check compile return code first. Nonzero means RTL/syntax/module resolution failed.
4. Check simulation return code next. Nonzero usually means `$fatal`, timeout, or runtime error.
5. Read `ERRORS/WARNINGS` before the full output.
6. For ACVP, identify the operation and vector number.
7. Re-run only that bench manually or use `--suite acvp`.

---

## 5. Utility script roles

- `sim/utils/mlkem512_ref.py`: independent Python arithmetic/KEM model and randomized checks.
- `sim/utils/generate_acvp_vectors.py`: downloads/normalizes official vectors and creates the manifest.
- `sim/utils/run_regression_report.py`: compiles/runs benches and produces detailed logs.

---

## 6. Test limitations

- The standalone SHA3/SHAKE, Keccak, NTT, and polynomial benches are unit-level examples and are not substitutes for all ML-KEM KATs.
- Simulation does not prove physical hardware timing.
- Icarus execution of package functions does not prove synthesis quality.
- Current ACVP pass coverage does not constitute FIPS validation or certification.
- Power, EM, timing, fault injection, formal equivalence, and randomized interface protocol testing require further work.
