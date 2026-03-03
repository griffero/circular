# Parity DoD Status

Last updated: 2026-03-03 (UTC, evidence runs `2026-03-03_04-02-37-395` baseline + `2026-03-03_04-03-16-972` standard)

## Definitive Completion Criteria Status

| DoD Criterion | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Global score >= 92/100 | PASS | `parity/SCORE_HISTORY.md` (latest global score: 99) | Threshold met and held. |
| Tier 1 visual diff average < 2% | PASS | `parity/evidence/latest.json`, `parity/evidence/2026-03-03_04-03-16-972/visual/report.md`, `parity/evidence/2026-03-03_04-02-37-395/visual/report.md`, `parity/baseline/notes.md` | Latest standard run compared `2/2` scenarios with average diff `1.379%` (`team-issues default-list: 1.837%`, `my-issues assigned: 0.921%`). |
| Tier 1 functional/filter/sub-view checklist >= 95% per view | PASS | `spec/requests/issues_spec.rb`, `spec/requests/users_spec.rb`, `PROGRESS.md`, `parity/SCORE_HISTORY.md` | Tier-1 filter/sub-view order-reset interactions are now aligned across shared list and board surfaces (explicit `sort/direction` state is clearable and defaults restore deterministically). Current score gaps to `95`: functional `0`, filter `0`, sub-view `0`. |
| Tier 2 functional/filter/sub-view checklist >= 90% per view | PASS | `PROGRESS.md`, `parity/SCORE_HISTORY.md` | Tier-2 slices (board/triage/settings/inbox/project) are tracked as accepted. |
| Tier 1 critical data/order cases 100% match; remaining >=95% | PASS | `spec/requests/issues_spec.rb` | Covered: default order, explicit `updated_at asc`, priority ordering (asc/desc), due-date ordering (asc/desc, undated last), workflow-state and status filters. |
| Tier 1 p95 performance budgets met | PASS | `parity/evidence/latest.json`, `parity/evidence/2026-03-03_04-03-16-972/performance/report.md` | Latest standard run is fully green: `initial_list_render` `907ms`, `issue_detail_open` `262ms`, `filter_apply_stable_list` `868ms`, `cud_feedback` `580ms` (all within budgets). |
| Critical E2E flows all green | PASS | `parity/evidence/latest.json`, `parity/evidence/2026-03-03_04-03-16-972/e2e/report.md`, `spec/requests/issues_spec.rb` | Latest standard run has `5/5` PASS (`create`, `edit`, `move/assign`, `filter+sub-view`, `delete`). |
| No open P0/P1 blockers for daily usage | PASS | `PROGRESS.md` | No active P0/P1 functional blocker currently tracked. |

## Tier-1 Threshold Gap Snapshot (score proxy vs target `95`)

- Visual parity: `95` (`gap: 0`)
- Functional parity: `95` (`gap: 0`)
- Filter parity: `95` (`gap: 0`)
- Sub-view parity: `95` (`gap: 0`)
- Data/order parity: `95` (`gap: 0`)

## Open Final Gaps

1. None for parity DoD gates in this scorecard cycle. Objective is complete on current evidence.
2. Optional (non-blocking): provide `/tmp/linear-storage-state.json` if future baseline refreshes require authenticated Linear state captures.
