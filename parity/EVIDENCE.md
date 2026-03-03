# Parity Evidence Pipeline

This repo now ships a single evidence runner for the remaining parity blockers:

- visual baseline/diff capture and report
- Tier-1 p95 performance budget report
- browser E2E critical-flow evidence report

## Command

From repo root:

```bash
npm --prefix client run parity:evidence
```

Capture missing Linear baseline screenshots during the same run:

```bash
npm --prefix client run parity:evidence:baseline
```

Bootstrap authenticated Circular storage state (magic-link flow for `cristobal@fintoc.com` by default):

```bash
./script/parity-bootstrap-circular-auth.sh
```

Run the full unblock pipeline (auth bootstrap + baseline + standard evidence):

```bash
./script/parity-run-final-evidence.sh
```

## Output Contract

Each run writes artifacts under:

- `parity/evidence/<run-id>/SUMMARY.md`
- `parity/evidence/<run-id>/summary.json`
- `parity/evidence/<run-id>/visual/report.md`
- `parity/evidence/<run-id>/visual/results.json`
- `parity/evidence/<run-id>/performance/report.md`
- `parity/evidence/<run-id>/performance/results.json`
- `parity/evidence/<run-id>/e2e/report.md`
- `parity/evidence/<run-id>/e2e/results.json`

Latest run pointer:

- `parity/evidence/latest.json`

## Prerequisites

- Circular app reachable at `CIRCULAR_BASE` (default `http://127.0.0.1:5173`)
- Playwright browser installed for local environment
- Optional authenticated storage states:
  - `CIRCULAR_STORAGE_STATE` (default `/tmp/circular-prod-storage-state.json`)
  - `LINEAR_STORAGE_STATE` (default `/tmp/linear-storage-state.json`)
- For baseline capture mode (`parity:evidence:baseline`): Linear reachable at `LINEAR_BASE` (default `https://linear.app/fintoc`)

If prerequisites are missing, the runner does not crash the parity process; it records explicit `BLOCKED` evidence with reasons.

## Environment Variables

- `CIRCULAR_BASE`
- `LINEAR_BASE`
- `CIRCULAR_STORAGE_STATE`
- `LINEAR_STORAGE_STATE`
- `PARITY_CAPTURE_BASELINE` (`1` enables baseline capture)
- `PARITY_PERF_SAMPLES` (default `5`, min `3`)
