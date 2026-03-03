#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CIRCULAR_BASE="${CIRCULAR_BASE:-http://127.0.0.1:5173}"
LINEAR_BASE="${LINEAR_BASE:-https://linear.app/fintoc}"

cd "$ROOT_DIR"

./script/parity-bootstrap-circular-auth.sh "${PARITY_AUTH_EMAIL:-cristobal@fintoc.com}"

echo "Running baseline capture evidence..."
CIRCULAR_BASE="$CIRCULAR_BASE" LINEAR_BASE="$LINEAR_BASE" npm --prefix client run parity:evidence:baseline

BASELINE_RUN_ID="$(node -e "const fs=require('fs');const p='parity/evidence/latest.json';const j=JSON.parse(fs.readFileSync(p,'utf8'));console.log(j.runId)")"

echo "Running standard evidence..."
CIRCULAR_BASE="$CIRCULAR_BASE" LINEAR_BASE="$LINEAR_BASE" npm --prefix client run parity:evidence

STANDARD_RUN_ID="$(node -e "const fs=require('fs');const p='parity/evidence/latest.json';const j=JSON.parse(fs.readFileSync(p,'utf8'));console.log(j.runId)")"

echo "baseline_run_id=${BASELINE_RUN_ID}"
echo "standard_run_id=${STANDARD_RUN_ID}"
