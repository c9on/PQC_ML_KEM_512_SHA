# Security assumptions, limitations, and certification status

## Explicit status

# This project is not FIPS certified

Passing NIST ACVP functional vectors does **not** mean that this implementation is certified, validated, approved, or ready for regulated deployment.

Certification requires an appropriate formal validation program, implementation guidance compliance, module boundary and entropy requirements, secure design/process evidence, and accredited laboratory activities. This repository does not supply those guarantees.

## What is currently verified

The repository has strong functional simulation evidence for selected/complete ML-KEM-512 behavior:

- 25 key-generation ACVP cases
- 25 encapsulation ACVP cases
- 10 decapsulation ACVP cases
- 10 encapsulation key-check cases
- 10 decapsulation key-check cases
- deterministic randomized arithmetic and round-trip tests
- independent Python reference checks

These results support algorithmic debugging and regression, not certification by themselves.

## Security assumptions

The FIPS 203 algorithms assume that:

- key-generation seed `d` is secret and unpredictable
- implicit-rejection seed `z` is secret and unpredictable
- `seed_d` and `seed_z` arrive from an approved random/entropy source in a real deployment
- encapsulation message/random derivation follows the defined protocol
- private decapsulation-key memory is protected
- reset and zeroization behavior meet the surrounding security-module requirements
- external interfaces do not expose intermediate secret state

This repository does not implement or validate an entropy source, secure provisioning, secure storage, access control, debug locking, tamper response, or key erasure policy.

## Constant-time and side-channel limitations

The ciphertext comparison loops over every byte and both Kbar/J outputs are computed, which is a useful functional structure for implicit rejection. However, this is not proof of constant-time hardware behavior.

Unverified areas include:

- data-dependent switching/power activity in Keccak, NTT, and multipliers
- reduction implementation timing and synthesized form
- memory access patterns for secret coefficients
- routing/capacitive effects and FPGA power noise
- correlation power analysis and electromagnetic analysis
- fault injection during keygen, decapsulation, or comparison
- glitches and early error-state behavior

No countermeasures or certification measurements are claimed.

## Synthesizability and availability limitations

The current `COMPUTE` state evaluates large package functions as combinational graphs. Vivado parsing succeeds, but synthesis netlist expansion exceeded 10 GB RSS and did not produce complete utilization/timing reports.

This architecture can therefore not yet be used as evidence of a practical, timing-closed FPGA module.

## Key validation limitations

The design checks:

- EK polynomial coefficients are below 3329
- embedded `H(EK)` in DK is correct

These checks match the implemented ACVP key-check coverage, but the overall module has no secure physical module boundary, no secure key-management architecture, and no complete malformed-input policy beyond the documented statuses.

## Safe use statement

Use this repository for:

- learning ML-KEM/FIPS 203
- RTL simulation and algorithm debugging
- ACVP-style development testing
- building and validating a future iterative hardware design

Do not claim deployment, certification, side-channel resistance, or production security without further architecture, formal, FPGA, laboratory, and validation work.
