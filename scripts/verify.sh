#!/usr/bin/env bash
# Full quality gate for the project.  One command, no arguments.
#
#   ./scripts/verify.sh
#
# Requires `moon` on PATH (see scripts/install-moonbit.sh).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> toolchain"
moon version --all

echo "==> formatting (write, then check)"
moon fmt
moon fmt --check

echo "==> type check, warnings are errors"
moon check --deny-warn

echo "==> tests (wasm + js), warnings are errors"
moon test --target wasm --deny-warn
moon test --target js --deny-warn

echo "==> build"
moon build --target wasm

echo "==> run both pipelines and refresh the exported artefacts"
moon run src/cmd/main > run_output.txt
python3 scripts/extract_traces.py
python3 scripts/make_report.py
python3 scripts/make_report_langlands.py

echo "==> dead-code scan (definitions with zero references)"
python3 scripts/dead_code_scan.py

echo "==> OK"
