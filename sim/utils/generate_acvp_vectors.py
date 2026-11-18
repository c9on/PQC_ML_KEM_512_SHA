#!/usr/bin/env python3
"""Download and normalize the NIST ACVP ML-KEM-512 verification data."""

import hashlib
import json
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "sim" / "vectors" / "full"
BASE = "https://raw.githubusercontent.com/usnistgov/ACVP-Server/master/gen-val/json-files/"
REVISION = "master"

DATASETS = {
    "keygen": "ML-KEM-keyGen-FIPS203",
    "operations": "ML-KEM-encapDecap-FIPS203",
}


def fetch(dataset, filename):
    url = f"{BASE}{dataset}/{filename}"
    request = urllib.request.Request(url, headers={"User-Agent": "ml-kem-acvp-vector-generator"})
    with urllib.request.urlopen(request, timeout=60) as response:
        raw = response.read()
    return raw, json.loads(raw)


def write_mem(name, values):
    lines = [str(value).upper() for value in values]
    (OUT / name).write_text("\n".join(lines) + "\n")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    raw_files = []

    kg_prompt_raw, kg_prompt = fetch(DATASETS["keygen"], "prompt.json")
    kg_result_raw, kg_result = fetch(DATASETS["keygen"], "expectedResults.json")
    op_prompt_raw, op_prompt = fetch(DATASETS["operations"], "prompt.json")
    op_result_raw, op_result = fetch(DATASETS["operations"], "expectedResults.json")
    raw_files.extend([
        (DATASETS["keygen"], "prompt.json", kg_prompt_raw),
        (DATASETS["keygen"], "expectedResults.json", kg_result_raw),
        (DATASETS["operations"], "prompt.json", op_prompt_raw),
        (DATASETS["operations"], "expectedResults.json", op_result_raw),
    ])

    kg_tests = kg_prompt["testGroups"][0]["tests"]
    kg_expected = {x["tcId"]: x for x in kg_result["testGroups"][0]["tests"]}
    write_mem("kg_d.mem", [x["d"] for x in kg_tests])
    write_mem("kg_z.mem", [x["z"] for x in kg_tests])
    write_mem("kg_ek.mem", [kg_expected[x["tcId"]]["ek"] for x in kg_tests])
    write_mem("kg_dk.mem", [kg_expected[x["tcId"]]["dk"] for x in kg_tests])

    enc_tests = op_prompt["testGroups"][0]["tests"]
    enc_expected = {x["tcId"]: x for x in op_result["testGroups"][0]["tests"]}
    write_mem("enc_ek.mem", [x["ek"] for x in enc_tests])
    write_mem("enc_m.mem", [x["m"] for x in enc_tests])
    write_mem("enc_c.mem", [enc_expected[x["tcId"]]["c"] for x in enc_tests])
    write_mem("enc_k.mem", [enc_expected[x["tcId"]]["k"] for x in enc_tests])

    dec_tests = op_prompt["testGroups"][3]["tests"]
    dec_expected = {x["tcId"]: x for x in op_result["testGroups"][3]["tests"]}
    write_mem("dec_dk.mem", [x["dk"] for x in dec_tests])
    write_mem("dec_c.mem", [x["c"] for x in dec_tests])
    write_mem("dec_k.mem", [dec_expected[x["tcId"]]["k"] for x in dec_tests])

    for group_index, prefix, field in (
        (6, "dkcheck", "dk"),
        (7, "ekcheck", "ek"),
    ):
        tests = op_prompt["testGroups"][group_index]["tests"]
        expected = {x["tcId"]: x for x in op_result["testGroups"][group_index]["tests"]}
        write_mem(f"{prefix}_{field}.mem", [x[field] for x in tests])
        write_mem(
            f"{prefix}_passed.mem",
            ["01" if expected[x["tcId"]]["testPassed"] else "00" for x in tests],
        )

    manifest = {
        "source": "usnistgov/ACVP-Server",
        "revision": REVISION,
        "base_url": BASE,
        "files": {
            f"{dataset}/{filename}": hashlib.sha256(raw).hexdigest()
            for dataset, filename, raw in raw_files
        },
        "coverage": {
            "keygen": len(kg_tests),
            "encapsulation": len(enc_tests),
            "decapsulation": len(dec_tests),
            "decapsulation_key_check": 10,
            "encapsulation_key_check": 10,
        },
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

    print(f"Generated {len(list(OUT.glob('*.mem')))} memory files in {OUT}")
    print(f"Wrote source SHA-256 manifest: {OUT / 'manifest.json'}")


if __name__ == "__main__":
    main()
