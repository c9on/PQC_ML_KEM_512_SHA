#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
IVERILOG_BIN="${IVERILOG_BIN:-$(command -v iverilog || true)}"
if [ -z "$IVERILOG_BIN" ]; then
  echo "iverilog not found in PATH. Build local copy via tools/build_iverilog_local.sh first." >&2
  exit 1
fi

$IVERILOG_BIN -g2012   -I "$ROOT/rtl"   "$ROOT/rtl/common/ml_kem_512_pkg.sv"   "$ROOT/rtl/keccak/keccak_f1600.sv"   "$ROOT/rtl/sha3/sha3_256.sv"   "$ROOT/rtl/sha3/shake128.sv"   "$ROOT/rtl/ntt/ntt_256.sv"   "$ROOT/rtl/poly/poly_core.sv"   "$ROOT/rtl/ml_kem/ml_kem_512_top.sv"   "$ROOT/sim/tb_keccak_f1600.sv"   "$ROOT/sim/tb_sha3_256.sv"   "$ROOT/sim/tb_shake128.sv"   "$ROOT/sim/tb_ntt_256.sv"   "$ROOT/sim/tb_poly_core.sv"   "$ROOT/sim/tb_ml_kem_512_top.sv"   -o "$ROOT/sim/ml_kem_512_tb"

vvp "$ROOT/sim/ml_kem_512_tb"
