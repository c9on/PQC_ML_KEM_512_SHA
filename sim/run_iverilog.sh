#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
IVERILOG_BIN="${IVERILOG_BIN:-$(command -v iverilog || true)}"
if [ -z "$IVERILOG_BIN" ]; then
  echo "iverilog not found in PATH. Build local copy via tools/build_iverilog_local.sh first." >&2
  exit 1
fi

RTL_SOURCES=(
  "$ROOT/rtl/common/ml_kem_512_pkg.sv"
  "$ROOT/rtl/keccak/keccak_f1600.sv"
  "$ROOT/rtl/sha3/sha3_256.sv"
  "$ROOT/rtl/sha3/sha3_512.sv"
  "$ROOT/rtl/sha3/shake128.sv"
  "$ROOT/rtl/sha3/shake256.sv"
  "$ROOT/rtl/ntt/ntt_256.sv"
  "$ROOT/rtl/ntt/intt_256.sv"
  "$ROOT/rtl/poly/poly_arith.sv"
  "$ROOT/rtl/poly/poly_core.sv"
  "$ROOT/rtl/ml_kem/ml_kem_512_keygen.sv"
  "$ROOT/rtl/ml_kem/ml_kem_512_encaps.sv"
  "$ROOT/rtl/ml_kem/ml_kem_512_decaps.sv"
  "$ROOT/rtl/ml_kem/ml_kem_512_kdf.sv"
  "$ROOT/rtl/ml_kem/ml_kem_512_top.sv"
)

status=0
for tb in "$ROOT"/sim/tb_*.sv; do
  top="$(basename "$tb" .sv)"
  exe="$(mktemp "${TMPDIR:-/tmp}/${top}.XXXXXX")"
  echo "===== $top ====="
  if "$IVERILOG_BIN" -g2012 -s "$top" -I "$ROOT/rtl" "${RTL_SOURCES[@]}" "$tb" -o "$exe" && vvp "$exe"; then
    echo "RESULT: PASS"
  else
    echo "RESULT: FAIL"
    status=1
  fi
  rm -f "$exe"
done

exit "$status"
