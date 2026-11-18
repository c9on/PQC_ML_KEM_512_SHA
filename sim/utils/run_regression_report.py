#!/usr/bin/env python3
"""Run all Icarus benches and create a beginner-friendly detailed text/JSON report."""

import argparse
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[2]
SIM = ROOT / "sim"
VECTORS = SIM / "vectors" / "full"
DEFAULT_REPORT_DIR = ROOT / "sim" / "reports"

FUNCTIONAL_TESTS = [
    "tb_intt_256.sv",
    "tb_keccak_f1600.sv",
    "tb_ml_kem_512_random_roundtrip.sv",
    "tb_ml_kem_512_randomized.sv",
    "tb_ntt_256.sv",
    "tb_poly_arith.sv",
    "tb_poly_core.sv",
    "tb_sha3_256.sv",
    "tb_sha3_512.sv",
    "tb_shake128.sv",
    "tb_shake256.sv",
]
ACVP_TESTS = ["tb_ml_kem_512_acvp_full.sv"]

RTL_SOURCES = [
    "rtl/common/ml_kem_fips203_pkg.sv",
    "rtl/keccak/keccak_f1600.sv",
    "rtl/sha3/sha3_256.sv",
    "rtl/sha3/sha3_512.sv",
    "rtl/sha3/shake128.sv",
    "rtl/sha3/shake256.sv",
    "rtl/ntt/ntt_256.sv",
    "rtl/ntt/intt_256.sv",
    "rtl/poly/poly_arith.sv",
    "rtl/poly/poly_core.sv",
    "rtl/ml_kem/ml_kem_512_engine.sv",
    "rtl/ml_kem/ml_kem_512_top.sv",
]

DESCRIPTIONS = {
    "tb_intt_256.sv": "Runs the standalone inverse transform on coefficients 1..256 and compares four reference coefficients.",
    "tb_keccak_f1600.sv": "Permutes the zero Keccak state and checks a known lane result.",
    "tb_ml_kem_512_random_roundtrip.sv": "Generates 8 deterministic random keypairs, encapsulates 8 messages, decapsulates them, and compares shared secrets through ml_kem_512_top.",
    "tb_ml_kem_512_randomized.sv": "Runs 32 randomized NTT/INTT and direct-convolution checks, plus encoding and compression boundaries.",
    "tb_ntt_256.sv": "Runs the standalone NTT on coefficients 1..256 and compares four reference coefficients.",
    "tb_poly_arith.sv": "Checks coefficient-wise modular addition, subtraction, and multiplication at coefficient zero.",
    "tb_poly_core.sv": "Checks polynomial coefficient addition and subtraction at coefficient zero.",
    "tb_sha3_256.sv": "Checks NIST ACVP SHA3-256 tgId=1 tcId=19.",
    "tb_sha3_512.sv": "Checks NIST ACVP SHA3-512 tgId=1 tcId=25.",
    "tb_shake128.sv": "Checks NIST ACVP SHAKE128 tcId=54 with 256-bit output.",
    "tb_shake256.sv": "Checks NIST ACVP SHAKE256 tcId=188 with 256-bit output.",
    "tb_ml_kem_512_acvp_full.sv": "Runs every ML-KEM-512 NIST ACVP keygen, encapsulation, decapsulation, and key-check case.",
}

EXPECTED = {
    "tb_intt_256.sv": "out[0:3] = 128, 129, -1963, -1963; valid=1",
    "tb_keccak_f1600.sv": "state_out[63:0] = F1258F7940E1DDE7; done=1",
    "tb_ml_kem_512_random_roundtrip.sv": "8/8 encapsulated shared secrets equal decapsulated shared secrets",
    "tb_ml_kem_512_randomized.sv": "32/32 NTT/base-multiplication rounds; 12/10/4-bit boundaries; message and compression checks pass",
    "tb_ntt_256.sv": "out[0:3] = -1251, -835, 795, 1165; valid=1",
    "tb_poly_arith.sv": "sum[0]=256, sub[0]=3073 in unsigned 12-bit representation (-1023 displayed signed), mul[0]=0",
    "tb_poly_core.sv": "sum[0]=256, diff[0]=3073 in unsigned 12-bit representation (-1023 displayed signed)",
    "tb_sha3_256.sv": "416810B652DE89C206024D8BD14E22249809F55625F0FE23A5B61557501BF8D8",
    "tb_sha3_512.sv": "2CE82BA7D697120F03DB3010538E7E0FCF22C84E21610FCD6736D983ECAB56B5039C36C96E68F1F03654E1C6DA6F0FDFDE7FC7F072F49296D4D571D75FC1438A",
    "tb_shake128.sv": "93C658214E0287CA26732DF2847C4CF8B24B1FB14A9435BDFD088BDDDA9FCB75",
    "tb_shake256.sv": "B8DDCBC9E42B9A7A0E235D29F0A917390C8650313C83380FCC730691540FC5D0",
    "tb_ml_kem_512_acvp_full.sv": "25 keygen, 25 encapsulation, 10 decapsulation, 10 DK checks, and 10 EK checks pass with exact full-width outputs",
}

INPUTS = {
    "tb_intt_256.sv": "coeffs[i] = i + 1 for i=0..255",
    "tb_keccak_f1600.sv": "state_in = 1600'b0",
    "tb_ml_kem_512_random_roundtrip.sv": "Deterministic LFSR seed = A5C39E71D204F86B; eight generated d,z,m values",
    "tb_ml_kem_512_randomized.sv": "Deterministic LFSR seed = 1BADF00DCAFE1234; 32 polynomial pairs; 256 coefficients each",
    "tb_ntt_256.sv": "coeffs[i] = i + 1 for i=0..255",
    "tb_poly_arith.sv": "a[i] = i and b[i] = 256-i for i=0..255",
    "tb_poly_core.sv": "a[i] = i and b[i] = 256-i for i=0..255",
    "tb_sha3_256.sv": "21-byte ACVP message B01239C26852698FBF73156C3C5E3DF12783200902",
    "tb_sha3_512.sv": "12-byte ACVP message BE5D626A3D0C52B60875D62A",
    "tb_shake128.sv": "136-byte ACVP message from tcId 54; requested output = 32 bytes",
    "tb_shake256.sv": "21-byte ACVP message DB0E6BC71E17E888558517180B776991A926B23A75; output = 32 bytes",
    "tb_ml_kem_512_acvp_full.sv": "Official memories under sim/vectors/full: kg_*, enc_*, dec_*, ekcheck_*, dkcheck_*",
}


def shell_join(parts):
    return " ".join(str(x) for x in parts)


def read_lines(path):
    if not path.exists():
        return []
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]


def run_checked(command, cwd, timeout):
    started = time.monotonic()
    result = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
        check=False,
    )
    return result, time.monotonic() - started


def acvp_cases(bench_passed):
    """Build a readable one-case-per-record explanation from generated memories."""
    cases = []
    groups = [
        ("keygen", "kg_d.mem", "kg_z.mem", "kg_ek.mem", "kg_dk.mem"),
        ("encapsulation", "enc_ek.mem", "enc_m.mem", "enc_c.mem", "enc_k.mem"),
        ("decapsulation", "dec_dk.mem", "dec_c.mem", "dec_k.mem", None),
    ]
    for operation, input_a_name, input_b_name, expected_a_name, expected_b_name in groups:
        input_a = read_lines(VECTORS / input_a_name)
        input_b = read_lines(VECTORS / input_b_name)
        expected_a = read_lines(VECTORS / expected_a_name)
        expected_b = read_lines(VECTORS / expected_b_name) if expected_b_name else []
        for index in range(max(len(input_a), len(input_b), len(expected_a), len(expected_b))):
            case = {
                "case": index + (1 if operation != "decapsulation" else 76),
                "operation": operation,
                "input_a_name": input_a_name,
                "input_a": input_a[index] if index < len(input_a) else "",
                "input_b_name": input_b_name,
                "input_b": input_b[index] if index < len(input_b) else "",
                "expected_a_name": expected_a_name,
                "expected_a": expected_a[index] if index < len(expected_a) else "",
                "expected_b_name": expected_b_name or "",
                "expected_b": expected_b[index] if index < len(expected_b) else "",
                "actual": "Exact full-width output matched expected" if bench_passed else "Unavailable because the bench failed before all-case completion",
                "status": "PASS" if bench_passed else "FAIL/NOT COMPLETED",
            }
            cases.append(case)

    for prefix, field in (("dkcheck", "dk"), ("ekcheck", "ek")):
        values = read_lines(VECTORS / f"{prefix}_{field}.mem")
        expected = read_lines(VECTORS / f"{prefix}_passed.mem")
        for index, (value, outcome) in enumerate(zip(values, expected)):
            cases.append({
                "case": index + (106 if prefix == "dkcheck" else 116),
                "operation": prefix,
                "input_a_name": f"{prefix}_{field}.mem",
                "input_a": value,
                "input_b_name": "",
                "input_b": "",
                "expected_a_name": f"{prefix}_passed.mem",
                "expected_a": "accepted" if outcome == "01" else "rejected",
                "expected_b_name": "",
                "expected_b": "",
                "actual": "Same as expected key-check result" if bench_passed else "Unavailable because the bench failed before all-case completion",
                "status": "PASS" if bench_passed else "FAIL/NOT COMPLETED",
            })
    return cases


def format_case(case):
    lines = [
        f"    CASE {case['case']} [{case['operation']}] {case['status']}",
        f"      INPUT  {case['input_a_name']}: {case['input_a']}",
    ]
    if case["input_b_name"]:
        lines.append(f"      INPUT  {case['input_b_name']}: {case['input_b']}")
    lines.append(f"      EXPECT {case['expected_a_name']}: {case['expected_a']}")
    if case["expected_b_name"]:
        lines.append(f"      EXPECT {case['expected_b_name']}: {case['expected_b']}")
    lines.append(f"      ACTUAL: {case['actual']}")
    return "\n".join(lines)


def run_regression(suite, output_dir, timeout):
    iverilog = os.environ.get("IVERILOG_BIN") or shutil.which("iverilog")
    vvp = shutil.which("vvp")
    if not iverilog or not vvp:
        raise RuntimeError("iverilog and vvp must be available in PATH")

    tests = FUNCTIONAL_TESTS if suite == "functional" else ACVP_TESTS if suite == "acvp" else FUNCTIONAL_TESTS + ACVP_TESTS
    started_at = datetime.now(timezone.utc)
    records = []

    for test_file in tests:
        bench = SIM / "tb" / test_file
        top = bench.stem
        with tempfile.TemporaryDirectory(prefix=f"{top}_") as temp_dir:
            executable = pathlib.Path(temp_dir) / top
            compile_command = [
                iverilog,
                "-g2012",
                "-s", top,
                "-I", str(ROOT / "rtl"),
                *[str(ROOT / source) for source in RTL_SOURCES],
                str(bench),
                "-o", str(executable),
            ]
            try:
                compile_result, compile_seconds = run_checked(compile_command, ROOT, timeout)
            except subprocess.TimeoutExpired as exc:
                compile_result = type("Result", (), {"returncode": 124, "stdout": exc.stdout or ""})()
                compile_seconds = timeout

            run_result = None
            run_seconds = 0.0
            if compile_result.returncode == 0:
                try:
                    run_result, run_seconds = run_checked([vvp, str(executable)], ROOT, timeout)
                except subprocess.TimeoutExpired as exc:
                    run_result = type("Result", (), {"returncode": 124, "stdout": exc.stdout or ""})()
                    run_seconds = timeout

            output = compile_result.stdout
            if run_result is not None:
                output += "\n" + run_result.stdout
            passed = compile_result.returncode == 0 and run_result is not None and run_result.returncode == 0
            error_lines = [
                line for line in output.splitlines()
                if any(token in line.lower() for token in ("fatal", "error", "mismatch", "failed", "timeout", "warning"))
            ]
            records.append({
                "test_file": test_file,
                "top": top,
                "description": DESCRIPTIONS[test_file],
                "input_summary": INPUTS[test_file],
                "expected": EXPECTED[test_file],
                "compile_command": shell_join(compile_command),
                "run_command": f"{vvp} {executable}",
                "compile_returncode": compile_result.returncode,
                "run_returncode": run_result.returncode if run_result else None,
                "compile_seconds": round(compile_seconds, 4),
                "run_seconds": round(run_seconds, 4),
                "actual": output.strip(),
                "errors_or_warnings": error_lines,
                "status": "PASS" if passed else "FAIL",
                "acvp_cases": acvp_cases(passed) if test_file == "tb_ml_kem_512_acvp_full.sv" else [],
            })

    ended_at = datetime.now(timezone.utc)
    failed = [record for record in records if record["status"] == "FAIL"]
    report = {
        "started_utc": started_at.isoformat(),
        "ended_utc": ended_at.isoformat(),
        "suite": suite,
        "root": str(ROOT),
        "iverilog": iverilog,
        "vvp": vvp,
        "summary": {
            "tests": len(records),
            "passed": len(records) - len(failed),
            "failed": len(failed),
            "status": "PASS" if not failed else "FAIL",
        },
        "tests": records,
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    timestamp = started_at.strftime("%Y%m%d_%H%M%S")
    text_path = output_dir / f"regression_{suite}_{timestamp}.log"
    json_path = output_dir / f"regression_{suite}_{timestamp}.json"
    text_path.write_text(render_text(report))
    json_path.write_text(json.dumps(report, indent=2) + "\n")
    (output_dir / "latest.log").write_text(text_path.read_text())
    (output_dir / "latest.json").write_text(json_path.read_text())
    return report, text_path, json_path


def render_text(report):
    lines = [
        "=" * 90,
        "ML-KEM-512 DETAILED REGRESSION REPORT",
        "=" * 90,
        f"Started UTC : {report['started_utc']}",
        f"Ended UTC   : {report['ended_utc']}",
        f"Suite       : {report['suite']}",
        f"Repository  : {report['root']}",
        f"Icarus      : {report['iverilog']}",
        f"VVP         : {report['vvp']}",
        f"Summary     : {report['summary']['passed']}/{report['summary']['tests']} passed; status={report['summary']['status']}",
        "",
        "HOW TO READ THIS REPORT",
        "- INPUT explains what the test applies to the DUT.",
        "- EXPECTED is the independently specified result checked by the test.",
        "- ACTUAL is the unmodified compiler/simulator output.",
        "- ERRORS/WARNINGS lists useful lines to inspect first when STATUS is FAIL.",
        "- The ACVP section expands every vector with full input and expected data.",
        "",
    ]
    for index, test in enumerate(report["tests"], 1):
        lines.extend([
            "=" * 90,
            f"TEST {index}/{report['summary']['tests']}: {test['test_file']} [{test['status']}]",
            "=" * 90,
            f"Purpose     : {test['description']}",
            f"Top module  : {test['top']}",
            f"INPUT       : {test['input_summary']}",
            f"EXPECTED    : {test['expected']}",
            f"Compile cmd : {test['compile_command']}",
            f"Run cmd     : {test['run_command']}",
            f"Compile rc  : {test['compile_returncode']} ({test['compile_seconds']} s)",
            f"Run rc      : {test['run_returncode']} ({test['run_seconds']} s)",
            "ACTUAL OUTPUT BEGIN",
            test["actual"] or "<no output>",
            "ACTUAL OUTPUT END",
            "ERRORS/WARNINGS BEGIN",
            "\n".join(test["errors_or_warnings"]) or "<none>",
            "ERRORS/WARNINGS END",
        ])
        if test["acvp_cases"]:
            lines.append("ACVP CASE-BY-CASE DETAIL")
            lines.extend(format_case(case) for case in test["acvp_cases"])
        lines.append("")

    lines.extend([
        "=" * 90,
        "FINAL SUMMARY",
        "=" * 90,
        f"Passed: {report['summary']['passed']}",
        f"Failed: {report['summary']['failed']}",
        f"Overall status: {report['summary']['status']}",
    ])
    if report["summary"]["failed"]:
        lines.append("FAILED TESTS: " + ", ".join(test["test_file"] for test in report["tests"] if test["status"] == "FAIL"))
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--suite", choices=("functional", "acvp", "all"), default="all")
    parser.add_argument("--output-dir", type=pathlib.Path, default=DEFAULT_REPORT_DIR)
    parser.add_argument("--timeout", type=int, default=1800, help="Per compile/run timeout in seconds")
    args = parser.parse_args()
    try:
        report, text_path, json_path = run_regression(args.suite, args.output_dir.resolve(), args.timeout)
    except Exception as exc:
        print(f"Regression report failed: {exc}", file=sys.stderr)
        return 1

    print(f"Status : {report['summary']['status']}")
    print(f"Passed : {report['summary']['passed']}/{report['summary']['tests']}")
    print(f"Text   : {text_path}")
    print(f"JSON   : {json_path}")
    print(f"Latest : {args.output_dir.resolve() / 'latest.log'}")
    return 0 if report["summary"]["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
