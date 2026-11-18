# Installation and Ubuntu setup guide

This guide installs everything needed to clone, simulate, verify, generate reports, and optionally synthesize this ML-KEM-512 project on Ubuntu.

## 1. Tool overview

### Required for normal development and regression

| Tool | Purpose |
|---|---|
| `git` | Clone and manage the repository |
| Bash | Runs `sim/run_iverilog.sh` |
| Icarus Verilog (`iverilog` and `vvp`) | Compiles and runs SystemVerilog testbenches |
| Python 3 | Runs vector generation, reference checks, and detailed reports |
| `coreutils`, `grep`, `sed`, `find` | Shell scripts and normal workspace utilities |
| Internet access | Needed only to regenerate ACVP vectors from the NIST ACVP-Server |

The Python scripts use only Python's standard library. **No pip package is required**.

### Optional development tools

| Tool | Purpose |
|---|---|
| AMD/Xilinx Vivado | FPGA project creation, synthesis, utilization, and timing reports |
| `make` and build tools | Building software tools from source or extending the project |
| GTKWave | Optional waveform viewing |
| Verilator | Optional extra RTL linting and simulation |
| VS Code | Optional editor |

Vivado is not available from Ubuntu's standard package repository. It requires a separate AMD/Xilinx download and license setup.

## 2. Recommended Ubuntu versions

The project has been verified on Ubuntu Linux. A currently supported 64-bit Ubuntu LTS release is recommended.

The current development environment uses:

- Git 2.53.0
- Python 3.14.4
- Icarus Verilog 12.0
- GNU Bash 5.3
- Vivado 2026.2 for the optional FPGA flow

Older compatible tool versions can also work, but use Python 3.10 or newer and Icarus Verilog 11/12 or newer for the simplest setup.

## 3. Update Ubuntu

Open a terminal and run:

```text
sudo apt update
sudo apt upgrade -y
```

Do not run the project installation as root. Only use `sudo` for the package installation commands.

## 4. Install required tools

Install Git, Icarus Verilog, Python, and standard build utilities:

```text
sudo apt install -y git iverilog python3 python3-venv build-essential make bash coreutils grep sed findutils curl ca-certificates
```

`iverilog` installs both required simulator commands:

- `iverilog`: SystemVerilog compiler
- `vvp`: Icarus simulation runtime

Verify them:

```text
git --version
python3 --version
iverilog -V
vvp -V
bash --version
```

Expected behavior: every command prints a version. If `vvp -V` does not print a version on your distribution, check:

```text
command -v vvp
```

## 5. Optional tools

### GTKWave

Install if you want to inspect waveform `.vcd` files later:

```text
sudo apt install -y gtkwave
```

Check:

```text
gtkwave --version
```

### Verilator

Install as an additional RTL linter/simulator:

```text
sudo apt install -y verilator
```

Check:

```text
verilator --version
```

Verilator is not used by the current regression script, but it is useful for additional linting during iterative hardware development.

### Python packaging tools

The project's Python scripts do not need pip packages. If you later need standard Python package tooling:

```text
sudo apt install -y python3-pip
```

Check:

```text
python3 -m pip --version
```

### Optional Python virtual environment

A virtual environment is not required because the scripts use the standard library. If your policy prefers isolation:

```text
python3 -m venv .venv
source .venv/bin/activate
```

Return to the normal shell environment with:

```text
deactivate
```

## 6. Install optional Vivado

Vivado is required only for FPGA project creation and synthesis.

1. Create or sign in to an AMD/Xilinx account.
2. Download **AMD Vivado Design Suite** for Linux from the AMD download site.
3. Install a version that supports your required device. This repository was tested with Vivado 2026.2.
4. Add the Vivado installation's `bin` directory to `PATH`, for example:

```text
export PATH=/home/<user>/Xilinx/Vivado/<version>/bin:$PATH
```

Add that line to `~/.bashrc` if you want it after every login:

```text
echo 'export PATH=/home/<user>/Xilinx/Vivado/<version>/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

Replace `<user>` and `<version>` with the actual installation path.

Check:

```text
vivado -version
```

Vivado may request a license or account-linked entitlement. The exact installation and licensing steps depend on the downloaded AMD/Xilinx release and license type.

### Important synthesis limitation

The production hierarchy is accepted and elaborated by Vivado, but the current package-function implementation expands as an extremely large combinational graph and may require more than 10 GB RAM without completing. The 100 MHz constraint is a target, not a met timing result. Read `docs/SYNTHESIS.md` before running synthesis.

## 7. Clone the project

Using HTTPS:

```text
git clone https://github.com/c9on/PQC_ML_KEM_512_SHA.git
cd PQC_ML_KEM_512_SHA
```

If the remote URL changes, copy the URL shown by the repository host.

Check the project root:

```text
pwd
ls
```

You should see directories such as:

```text
docs/  rtl/  sim/  vivado/
```

## 8. Run the basic functional regression

From the repository root:

```text
bash sim/run_iverilog.sh functional
```

This runs unit and randomized functional tests.

## 9. Run the NIST ACVP regression

The repository contains generated ACVP memory files. Run:

```text
bash sim/run_iverilog.sh acvp
```

Expected summary:

```text
ML-KEM-512 keygen: 25/25 ACVP PASS
ML-KEM-512 encapsulation: 25/25 ACVP PASS
ML-KEM-512 decapsulation: 10/10 ACVP PASS
ML-KEM-512 key checks: 20/20 ACVP PASS
```

Run all tests:

```text
bash sim/run_iverilog.sh all
```

## 10. Generate a detailed regression report

Run:

```text
python3 sim/utils/run_regression_report.py --suite all
```

This produces:

```text
sim/reports/latest.log
sim/reports/latest.json
```

The text report is designed for beginners and includes inputs, expected outputs, actual simulator output, warnings, errors, commands, and ACVP case details.

## 11. Regenerate official ACVP vector memories

This step requires internet access:

```text
python3 sim/utils/generate_acvp_vectors.py
```

The script downloads the official NIST ACVP prompt/expected-result JSON, regenerates `sim/vectors/full/*.mem`, and writes `sim/vectors/full/manifest.json` with source SHA-256 hashes.

## 12. Run the independent Python reference checks

```text
python3 sim/utils/mlkem512_ref.py
```

This checks the independent Python ML-KEM-512 reference and randomized round trips. It is not a hardware synthesis tool.

## 13. Run the Vivado flow

First make sure `vivado` is in `PATH`:

```text
command -v vivado
```

Then run from the repository root:

```text
vivado -mode batch -source vivado/run_synth.tcl
```

Generated reports would be under:

```text
vivado_build/reports/
```

If Vivado is not installed in `PATH`, either source the Vivado environment script supplied by your installation or call its absolute executable path.

## 14. Troubleshooting

### `iverilog: command not found`

Install Icarus Verilog:

```text
sudo apt install -y iverilog
```

### `vvp: command not found`

`vvp` is normally installed with Icarus Verilog. Reinstall:

```text
sudo apt install --reinstall -y iverilog
```

### `python3: command not found`

Install Python:

```text
sudo apt install -y python3
```

### `Permission denied` running a shell script

Run through Bash:

```text
bash sim/run_iverilog.sh all
```

Or make it executable:

```text
chmod +x sim/run_iverilog.sh
```

### ACVP download fails

Check internet/DNS/TLS and retry:

```text
curl -I https://raw.githubusercontent.com
python3 sim/utils/generate_acvp_vectors.py
```

### Missing vector files

Regenerate vectors:

```text
python3 sim/utils/generate_acvp_vectors.py
```

### Vivado cannot create the board

This project uses the exact FPGA part `xc7a100tcsg324-1` without depending on a Digilent board-definition package. Ensure the installed Vivado release supports 7-series Artix-7 devices and that the part license is available.

## 15. Recommended first-time sequence

Use this exact order:

```text
sudo apt update
sudo apt install -y git iverilog python3 build-essential make bash coreutils grep sed findutils curl ca-certificates
git clone https://github.com/c9on/PQC_ML_KEM_512_SHA.git
cd PQC_ML_KEM_512_SHA
bash sim/run_iverilog.sh all
python3 sim/utils/run_regression_report.py --suite all
```

Then read:

1. `docs/README.md`
2. `docs/ALGORITHM.md`
3. `docs/RTL_README.md`
4. `docs/TESTBENCH_README.md`
5. `docs/ARCHITECTURE.md`
6. `docs/SYNTHESIS.md`
7. `docs/SECURITY.md`

## 16. Minimum disk and memory recommendations

For simulation and reports:

- Several GB of free disk space
- 4 GB RAM is generally sufficient for Icarus regression

For Vivado synthesis attempts:

- More than 16 GB RAM is recommended
- 20 GB or more free disk space is recommended
- The current non-iterative RTL has already required over 10 GB RSS during combinational netlist expansion and may not complete

## 17. Certification warning

These tools and instructions install a functional ML-KEM-512 simulation project. They do not make the implementation FIPS certified. Read `docs/SECURITY.md` before any deployment decision.
