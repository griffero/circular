# Parity DoD Status

Last updated: 2026-03-03 (UTC, evidence runs `2026-03-03_02-36-04-130` baseline + `2026-03-03_02-36-04-129` standard)

## Definitive Completion Criteria Status

| DoD Criterion | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Global score >= 92/100 | PASS | `parity/SCORE_HISTORY.md` (latest global score: 99) | Threshold met and held. |
| Tier 1 visual diff average < 2% | BLOCKED | `parity/evidence/latest.json`, `parity/evidence/2026-03-03_02-36-04-129/visual/report.md`, `parity/evidence/2026-03-03_02-36-04-130/visual/report.md`, `parity/baseline/notes.md` | `parity:evidence:baseline` and `parity:evidence` were re-run after installing Playwright Chromium runtime. Browser-launch blocker is cleared, but baseline/diff remained blocked because Circular is unreachable at `http://127.0.0.1:5173`; no state-matched comparisons were produced (`0/2 compared`). Visual score proxy remains `77` (`gap: 18`). |
| Tier 1 functional/filter/sub-view checklist >= 95% per view | PASS | `spec/requests/issues_spec.rb`, `spec/requests/users_spec.rb`, `PROGRESS.md`, `parity/SCORE_HISTORY.md` | Tier-1 filter/sub-view order-reset interactions are now aligned across shared list and board surfaces (explicit `sort/direction` state is clearable and defaults restore deterministically). Current score gaps to `95`: functional `0`, filter `0`, sub-view `0`. |
| Tier 2 functional/filter/sub-view checklist >= 90% per view | PASS | `PROGRESS.md`, `parity/SCORE_HISTORY.md` | Tier-2 slices (board/triage/settings/inbox/project) are tracked as accepted. |
| Tier 1 critical data/order cases 100% match; remaining >=95% | PASS | `spec/requests/issues_spec.rb` | Covered: default order, explicit `updated_at asc`, priority ordering (asc/desc), due-date ordering (asc/desc, undated last), workflow-state and status filters. |
| Tier 1 p95 performance budgets met | BLOCKED | `parity/evidence/latest.json`, `parity/evidence/2026-03-03_02-36-04-129/performance/report.md` | Metric harness runs and browser runtime is available, but all budget checks remain blocked in this environment (`initial_list_render`, `issue_detail_open`, `filter_apply_stable_list`, `cud_feedback`) because Circular is unreachable at `http://127.0.0.1:5173`. |
| Critical E2E flows all green | BLOCKED | `parity/evidence/latest.json`, `parity/evidence/2026-03-03_02-36-04-129/e2e/report.md`, `spec/requests/issues_spec.rb` | Browser E2E evidence harness exists and records all required flow keys, but all remain blocked while Circular is unreachable. Request-level create/edit/move/assign/filter/delete coverage remains green. |
| No open P0/P1 blockers for daily usage | PASS | `PROGRESS.md` | No active P0/P1 functional blocker currently tracked. |

## Tier-1 Threshold Gap Snapshot (score proxy vs target `95`)

- Visual parity: `77` (`gap: 18`)
- Functional parity: `95` (`gap: 0`)
- Filter parity: `95` (`gap: 0`)
- Sub-view parity: `95` (`gap: 0`)
- Data/order parity: `95` (`gap: 0`)

## Open Final Gaps

1. Start local app stack (at minimum frontend reachable at `http://127.0.0.1:5173`); this is the current hard blocker across visual/performance/browser-E2E evidence.
2. Capture frozen Linear baseline screenshots for Tier-1 measured states under `parity/baseline/linear/<view>/<state>.png` via `npm --prefix client run parity:evidence:baseline` once Circular is reachable.
3. Provide authenticated storage states (`/tmp/circular-prod-storage-state.json`, `/tmp/linear-storage-state.json`) or equivalent env overrides for protected routes so baseline and flow captures are state-matched/authenticated.
4. Re-run `npm --prefix client run parity:evidence` after (1)-(3) to populate visual diff percentages, p95 measurements, and critical browser E2E pass/fail evidence.
