# Architecture, ports, byte order, commands, and latency

## Production hierarchy

```text
ml_kem_512_top
└── ml_kem_512_engine
    └── ml_kem_fips203_pkg functions
        ├── Keccak / SHA3 / SHAKE
        ├── NTT / INTT / base multiplication
        ├── rejection / CBD sampling
        ├── serialization / compression
        └── key validation
```

## Port table

| Port | Direction | Width | Meaning |
|---|---|---:|---|
| `clk` | input | 1 | Interface/control clock |
| `rst_n` | input | 1 | Active-low asynchronous reset |
| `start` | input | 1 | Request pulse; accept only when idle |
| `cmd` | input | 2 | Select keygen/encap/decap |
| `seed_d` | input | 256 | 32-byte deterministic key seed |
| `seed_z` | input | 256 | 32-byte implicit-rejection seed |
| `msg_in` | input | 256 | 32-byte message |
| `pk_in` | input | 6400 | 800-byte encapsulation key |
| `sk_in` | input | 13056 | 1632-byte decapsulation key |
| `ct_in` | input | 6144 | 768-byte ciphertext |
| `pk_out` | output | 6400 | Generated EK |
| `sk_out` | output | 13056 | Generated DK |
| `ct_out` | output | 6144 | Encapsulation ciphertext |
| `ss_out` | output | 256 | 32-byte shared secret |
| `busy` | output | 1 | Accepted operation in progress |
| `valid` | output | 1 | Single-cycle completion/error response |
| `status` | output | 8 | Command/error/result status |

## Byte and bit ordering

The module buses are MSB-first for presentation. The first byte in an ACVP hexadecimal string is placed in the highest byte of the corresponding packed bus by testbench loading logic.

Examples:

- EK is `logic [6399:0]`; byte 0 uses `[6399:6392]`.
- DK is `logic [13055:0]`; byte 0 uses `[13055:13048]`.
- ciphertext is `logic [6143:0]`; byte 0 uses `[6143:6136]`.

Inside coefficient functions, polynomial coefficient zero is in the low 12-bit portion of its 3072-bit polynomial bus. Serialization functions convert between this internal coefficient order and ACVP/FIPS byte order.

Any future AXI or streaming adapter must document and test this conversion explicitly.

## Commands

| `cmd` | Operation | Required inputs | Expected outputs |
|---|---|---|---|
| `00` | ML-KEM.KeyGen | `seed_d`, `seed_z` | `pk_out`, `sk_out` |
| `01` | ML-KEM.Encaps | `pk_in`, `msg_in` | `ct_out`, `ss_out` |
| `10` | ML-KEM.Decaps | `sk_in`, `ct_in` | `ss_out` |
| `11` | Reserved | none | error status |

## Status values

| Value | Meaning |
|---:|---|
| `00` | reset/idle |
| `10` | key generation completed |
| `20` | encapsulation completed |
| `30` | decapsulation completed after ciphertext match |
| `34` | decapsulation completed using implicit rejection |
| `80` | request accepted/in progress |
| `E1` | malformed EK/DK rejected |
| `F1` | invalid command (`11`) |
| `F2` | start presented while busy |
| `FE` | invalid FSM state recovery |

`valid` is pulsed both for successful completion and for request errors. A consumer must inspect `status` before accepting output data.

## Request handshake

1. Hold command/input values stable.
2. Pulse `start` in idle state for at least one clock.
3. Observe `busy=1` and `status=80`.
4. Do not start another request while busy.
5. Wait for `valid=1` and inspect status.
6. `busy` is cleared on completion.

Inputs are copied into `*_r` registers when accepted, so they may change while the engine is busy without changing the active request.

## Current latency

The control FSM advances through:

```text
IDLE -> ACQUIRE -> RUN_HASH -> RUN_POLY -> COMPUTE -> DONE
```

Therefore a normal accepted operation currently takes a fixed number of visible state transitions plus a single combinational `COMPUTE` event. This is an interface/control latency, not a useful FPGA timing closure result.

Inside `COMPUTE`, package functions still perform complete hash, NTT, polynomial, packing, and re-encryption calculations. The real physical critical path is not bounded by one small arithmetic operation.

## Required future hardware timing architecture

A practical synthesizable redesign should replace package-wide `COMPUTE` with:

- one or a small number of Keccak rounds per cycle
- rate-block absorb/squeeze FSM
- coefficient-memory NTT butterflies
- iterative base multiplication
- BRAM-based key/ciphertext/polynomial storage
- iterative serialization and compare loops

Then latency should be documented as cycle counts per operation at the chosen clock frequency.
