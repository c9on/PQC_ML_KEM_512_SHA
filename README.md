# ML-KEM-512 RTL project

This repository is a modular RTL scaffold for ML-KEM-512, organized by algorithm block and intended for pre-FPGA architecture review and Vivado integration. The design keeps the major functional domains separate so each block can be isolated, debugged, and extended independently.

Important note:
- This is not a vendor-hardened or full specification-level production implementation of ML-KEM-512.
- It is a simulation-friendly, bus-oriented RTL architecture for Keccak, SHA-3, SHAKE, NTT/INTT, polynomial arithmetic, and the KEM control flow.
- The code is written to be easy to copy into a Vivado project and to iterate on before targeting an FPGA.

Project structure

- rtl/common/: shared constants and type definitions
- rtl/keccak/: Keccak-f[1600] permutation core
- rtl/sha3/: SHA3-256, SHA3-512, SHAKE128, SHAKE256
- rtl/ntt/: NTT and INTT modules for polynomial transforms
- rtl/poly/: polynomial arithmetic helpers
- rtl/ml_kem/: ML-KEM-512 key generation, encapsulation, decapsulation, KDF, and top wrapper
- sim/: every module has a matching behavioral testbench
- vivado/: TCL script to create a Vivado project automatically
- tools/: optional local HDL toolchain bootstrap helpers

Implementation details by module

1) Common package

File: rtl/common/ml_kem_512_pkg.sv

This file defines the global ML-KEM-512 constants used throughout the design:
- MLKEM_N = 256
- MLKEM_Q = 3329
- MLKEM_Q_BITS = 12
- byte lengths for keys and ciphertexts
- typedefs for byte_t, coeff_t, and higher-level key/ciphertext bus aliases

What it is doing:
- Keeps all ML-KEM parameters centralized so the RTL stays consistent.
- Avoids repeated numeric literals in multiple modules.
- Gives the project a clean interface for public key, secret key, ciphertext, and shared-secret width definitions.

2) Keccak-f[1600]

File: rtl/keccak/keccak_f1600.sv

This is the core permutation engine used by all Keccak-based functions.

What the module does:
- Accepts a 1600-bit state input, runs the Keccak-f[1600] round function, and produces a 1600-bit output state.
- Uses the standard state layout for 25 lanes of 64 bits each.
- Applies the theta, rho, pi, chi, and iota steps in a register-driven architecture.

Interface:
- clk, rst_n
- start
- state_in [1599:0]
- state_out [1599:0]
- done

Why it matters:
- SHA3 and SHAKE are built on top of this permutation.
- The Keccak core is the algorithmic heart of all hash and extendable-output functions in the project.

3) SHA3-256

File: rtl/sha3/sha3_256.sv

This module implements SHA3-256 as a Keccak-based hash function.

What the module does:
- Absorbs the input message bytes into the Keccak state.
- Applies the SHA3 domain separation padding (0x06 and final 1-bit handling).
- Runs the 24 Keccak rounds.
- Returns the first 256 bits of state as the digest.

Interface:
- clk, rst_n
- start
- msg [0:255]
- msg_len
- digest [255:0]
- valid

Why it matters:
- SHA3-256 is used for hashing and canonicalization-style building blocks.
- It is a good reference point for FPGA-friendly hash hardware.

4) SHA3-512

File: rtl/sha3/sha3_512.sv

This is the same Keccak-based pattern as SHA3-256, but the output width is 512 bits.

What it does:
- Uses the same Keccak permutation core structure.
- Uses the full 512-bit output lane extraction.
- Accepts a variable-length message and produces a 512-bit hash.

Interface:
- clk, rst_n
- start
- msg [0:255]
- msg_len
- digest [511:0]
- valid

5) SHAKE128

File: rtl/sha3/shake128.sv

This is an extendable-output function based on Keccak.

What it does:
- Absorbs input message bytes.
- Applies the SHAKE domain padding pattern (0x1F with final bit handling).
- Produces a variable-length pseudorandom output stream.
- Returns the requested number of output bits (out_len).

Interface:
- clk, rst_n
- start
- msg [0:255]
- msg_len
- out_len
- digest [255:0]
- valid

Why it matters:
- SHAKE128 is one of the key expansion engines used in lattice-based schemes like ML-KEM.
- In a real ML-KEM implementation this would feed matrix generation, sampling, and secret-key derivation.

6) SHAKE256

File: rtl/sha3/shake256.sv

This is the same structure as SHAKE128, but with SHAKE256 parameters and a 256-bit security level.

What it does:
- Uses the same core permutation flow.
- Provides a variable-length output stream for key derivation or pseudo-random expansion.

Interface:
- clk, rst_n
- start
- msg [0:255]
- msg_len
- out_len
- digest [255:0]
- valid

7) NTT (Number Theoretic Transform)

File: rtl/ntt/ntt_256.sv

This module performs a 256-point polynomial transform in the ML-KEM modulus domain.

What it does:
- Takes a 256-element polynomial represented as signed 12-bit coefficients.
- Reduces modulo Q = 3329 at each butterfly stage.
- Applies the Cooley-Tukey style structure for forward NTT.
- Produces a transformed vector of coefficients.

Interface:
- clk, rst_n
- start
- coeffs [0:255]
- out_coeffs [0:255]
- valid

Why it matters:
- The NTT is a core operation in Kyber/ML-KEM polynomial multiplication.
- It is the transform used to move polynomial multiplication from time domain to frequency domain.

8) INTT (Inverse Number Theoretic Transform)

File: rtl/ntt/intt_256.sv

This complements the NTT and performs the inverse transform.

What it does:
- Takes a transformed polynomial vector and maps it back to the original time-domain polynomial representation.
- Uses the modular arithmetic structure needed for inverse polynomial operations.

Interface:
- clk, rst_n
- start
- coeffs [0:255]
- out_coeffs [0:255]
- valid

Why it matters:
- In a full ML-KEM datapath, the inverse transform is used in the final reconstruction paths for ciphertexts and message recovery.

9) Polynomial arithmetic

File: rtl/poly/poly_arith.sv

This block models the basic polynomial operations used by ML-KEM.

What it does:
- Adds two 256-coefficient polynomials
- Subtracts two 256-coefficient polynomials
- Multiplies two 256-coefficient polynomials modulo Q

Interface:
- a [0:255]
- b [0:255]
- sum [0:255]
- sub [0:255]
- mul [0:255]

Why it matters:
- Lattice-based schemes primarily depend on polynomial operations, so this block gives the project a direct arithmetic backbone.

10) ML-KEM-512 key generation

File: rtl/ml_kem/ml_kem_512_keygen.sv

This module models the public/secret key generation path.

What it does:
- Takes a 32-byte seed input.
- Builds a local seed register.
- Produces a public key and secret key bus.
- Emits a valid pulse and a status code when done.

Interface:
- clk, rst_n
- start
- seed [0:31]
- pk [799:0]
- sk [1631:0]
- valid
- status

Why it matters:
- In a real ML-KEM implementation, this is the starting state of the KEM: generate the public key and secret key from a seed.
- This block provides a clean interface for the FPGA datapath even though it is intentionally simplified for architecture-level work.

11) ML-KEM-512 encapsulation

File: rtl/ml_kem/ml_kem_512_encaps.sv

This models the encapsulation path of ML-KEM-512.

What it does:
- Takes a public key and a 32-bit message.
- Produces a ciphertext and a shared secret.
- Drives valid and status when the operation completes.

Interface:
- clk, rst_n
- start
- pk [799:0]
- msg [31:0]
- ct [767:0]
- ss [31:0]
- valid
- status

Why it matters:
- This is the send-side half of the KEM: the sender encapsulates a session key and returns ciphertext plus shared secret material.
- It is structured as a bus-level block so it can later expand into a full real ML-KEM datapath.

12) ML-KEM-512 decapsulation

File: rtl/ml_kem/ml_kem_512_decaps.sv

This models the decapsulation path.

What it does:
- Takes the ciphertext and the secret key.
- Reconstructs the message and derives the shared secret.
- Emits valid and status when complete.

Interface:
- clk, rst_n
- start
- ct [767:0]
- sk [1631:0]
- msg [31:0]
- ss [31:0]
- valid
- status

Why it matters:
- This is the receiver-side operation of the KEM.
- It closes the key exchange loop and is a key block for any actual FPGA-implemented ML-KEM core.

13) KDF wrapper

File: rtl/ml_kem/ml_kem_512_kdf.sv

This is a lightweight KDF-style wrapper used to map internal key material to a shared secret.

What it does:
- Takes a 512-bit input key and length information.
- Buffers the key material on the clock.
- Produces a 32-bit shared secret by combining the input bits with constant masks.
- Raises valid and status when complete.

Interface:
- clk, rst_n
- start
- input_key [511:0]
- key_len
- shared_secret [31:0]
- valid
- status

Why it matters:
- Real key encapsulation schemes derive a shared secret via a KDF after the lattice computations.
- This module is intentionally modular so it can be upgraded later to a full KDF implementation without changing the top-level system interface.

14) Top-level ML-KEM-512 wrapper

File: rtl/ml_kem/ml_kem_512_top.sv

This is the top-level controller that connects the KEM sub-blocks.

What it does:
- Accepts a command field (cmd) and chooses between keygen, encapsulation, and decapsulation.
- Routes the inputs to the correct submodule.
- Collects the output buses and status bits.
- Passes valid and data to the rest of the system.

Interface:
- clk, rst_n
- start
- cmd
- seed
- pk_in
- sk_in
- ct_in
- msg_in
- pk_out
- sk_out
- ct_out
- msg_out
- ss_out
- valid
- status

Why it matters:
- This module is the natural integration point for a larger FPGA design.
- It is the block you would hook into a higher-level control FSM or host interface.

15) Vivado project script

File: vivado/create_ml_kem_project.tcl

This script creates a Vivado project automatically.

What it does:
- Creates a project directory under vivado_build/
- Adds all RTL source files and all testbench files
- Sets the simulation top module
- Updates the compile order for Vivado

Why it matters:
- This makes it easy to open the design in Vivado and build/simulate in a standard FPGA tool flow.

Testbench explanations

Each testbench is written as a self-contained behavioral module to exercise one block at a time. They are designed so you can open the project in Vivado, select a testbench as the top module, and run a simulation.

1) tb_keccak_f1600.sv

File: sim/tb_keccak_f1600.sv

What it tests:
- Reset and start behavior for the Keccak permutation
- Execution of the round pipeline
- Completion via the done signal

How it works:
- Initializes state_in to zero
- Releases reset
- Starts the permutation
- Waits several cycles
- Checks that done has been asserted
- Prints state_out[63:0]

2) tb_sha3_256.sv

File: sim/tb_sha3_256.sv

What it tests:
- Message absorption for SHA3-256
- Padding behavior
- digest generation
- valid pulse behavior

How it works:
- Uses a simple ASCII message: abc
- Drives msg_len = 3
- Starts the block
- Waits a few cycles
- Asserts valid
- Prints the digest value

3) tb_sha3_512.sv

File: sim/tb_sha3_512.sv

Same pattern as tb_sha3_256, but for the 512-bit output variant.

4) tb_shake128.sv

File: sim/tb_shake128.sv

What it tests:
- SHAKE128 absorb phase
- out_len handling
- output validity

How it works:
- Provides a small message and requests a 32-byte output
- Starts the block
- Waits for valid
- Prints the digest value

5) tb_shake256.sv

File: sim/tb_shake256.sv

Same as SHAKE128 but for SHAKE256.

6) tb_ntt_256.sv

File: sim/tb_ntt_256.sv

What it tests:
- Forward NTT datapath
- Polynomial conversion under modular arithmetic
- valid signal assertion

How it works:
- Fills coeffs with a small deterministic vector
- Starts the transform
- Waits for completion
- Prints the first few transformed coefficients

7) tb_intt_256.sv

File: sim/tb_intt_256.sv

What it tests:
- Inverse transform on the same coefficient pattern
- Basic sanity of the transform pair

8) tb_poly_arith.sv

File: sim/tb_poly_arith.sv

What it tests:
- Addition, subtraction, and multiplication of polynomial vectors
- Modulo reduction behaviour

9) tb_ml_kem_512_keygen.sv

File: sim/tb_ml_kem_512_keygen.sv

What it tests:
- Key generation path
- Seed-driven operation
- pk and sk output assembly
- valid and status behavior

10) tb_ml_kem_512_encaps.sv

File: sim/tb_ml_kem_512_encaps.sv

What it tests:
- Encapsulation logic
- Public key handling
- Ciphertext generation and shared-secret output

11) tb_ml_kem_512_decaps.sv

File: sim/tb_ml_kem_512_decaps.sv

What it tests:
- Decapsulation logic
- Secret key and ciphertext handling
- Message and shared-secret reconstruction

12) tb_ml_kem_512_kdf.sv

File: sim/tb_ml_kem_512_kdf.sv

What it tests:
- KDF-style key expansion wrapper
- valid and status signal behavior
- output secret derivation from a 512-bit input word

How to use in Vivado

1. Open Vivado.
2. Run the TCL script:
   vivado -mode batch -source vivado/create_ml_kem_project.tcl
3. Or open Vivado and source the script from the terminal.
4. Set a desired testbench as the top module for simulation.
5. Run behavioral simulation.

Notes and limitations

- This project is intentionally modular and easy to read, not a fully optimized ASIC/FPGA implementation of the whole Kyber/ML-KEM datapath.
- The Keccak and hash modules are universal algorithm blocks, while the KEM modules act as structural placeholders for the full matrix/vector operations you would add in a production-grade design.
- The project is suitable as a foundation for:
  - algorithm exploration,
  - hardware architecture planning,
  - Vivado bring-up,
  - module-level verification,
  - and future extension into full ML-KEM-512 datapath stages.

If you want to move from this scaffold to a more complete hardware implementation, the next logical steps are:
- polynomial RAMs and memory interfaces,
- sampler and rejection logic,
- matrix generation FSM,
- constant-time polynomial multipliers,
- and a stricter ML-KEM control-state machine.
