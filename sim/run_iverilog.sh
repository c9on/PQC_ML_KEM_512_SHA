#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
IVERILOG_BIN="${IVERILOG_BIN:-$(command -v iverilog || true)}"
if [ -z "$IVERILOG_BIN" ]; then
  echo "iverilog not found in PATH. Build local copy via tools/build_iverilog_local.sh first." >&2
  exit 1
fi

FUNCTIONAL_TESTS=(
  tb_intt_256.sv
  tb_keccak_f1600.sv
  tb_ml_kem_512_random_roundtrip.sv
  tb_ml_kem_512_randomized.sv
  tb_ntt_256.sv
  tb_poly_arith.sv
  tb_poly_core.sv
  tb_sha3_256.sv
  tb_sha3_512.sv
  tb_shake128.sv
  tb_shake256.sv
)

ACVP_TESTS=(
  tb_ml_kem_512_acvp_full.sv
)

RTL_SOURCES=(
  "$ROOT/rtl/common/ml_kem_fips203_pkg.sv"
  "$ROOT/rtl/keccak/keccak_f1600.sv"
  "$ROOT/rtl/sha3/sha3_256.sv"
  "$ROOT/rtl/sha3/sha3_512.sv"
  "$ROOT/rtl/sha3/shake128.sv"
  "$ROOT/rtl/sha3/shake256.sv"
  "$ROOT/rtl/ntt/ntt_256.sv"
  "$ROOT/rtl/ntt/intt_256.sv"
  "$ROOT/rtl/poly/poly_arith.sv"
  "$ROOT/rtl/poly/poly_core.sv"
  "$ROOT/rtl/ml_kem/ml_kem_512_engine.sv"
  "$ROOT/rtl/ml_kem/ml_kem_512_top.sv"
)

case "${1:-all}" in
  functional) tests=("${FUNCTIONAL_TESTS[@]}") ;;
  acvp)       tests=("${ACVP_TESTS[@]}") ;;
  all)        tests=("${FUNCTIONAL_TESTS[@]}" "${ACVP_TESTS[@]}") ;;
  *)
    echo "Usage: $0 [functional|acvp|all]" >&2
    exit 2
    ;;
esac

status=0
for test_file in "${tests[@]}"; do
  tb="$ROOT/sim/tb/$test_file"
  top="$(basename "$tb" .sv)"
  exe="$(mktemp "${TMPDIR:-/tmp}/${top}.XXXXXX")"
  echo "===== $top ====="
  if "$IVERILOG_BIN" -g2012 -s "$top" -I "$ROOT/rtl" \
      "${RTL_SOURCES[@]}" "$tb" -o "$exe" && vvp "$exe"; then
    echo "RESULT: PASS"
  else
    echo "RESULT: FAIL"
    status=1
  fi
  rm -f "$exe"
done

exit "$status"
