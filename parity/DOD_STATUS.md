# Parity DoD Status

Last updated: 2026-03-03 (UTC, evidence runs `2026-03-03_03-27-08-879` baseline + `2026-03-03_03-35-05-813` standard)

## Definitive Completion Criteria Status

| DoD Criterion | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Global score >= 92/100 | PASS | `parity/SCORE_HISTORY.md` (latest global score: 99) | Threshold met and held. |
| Tier 1 visual diff average < 2% | PASS | `parity/evidence/latest.json`, `parity/evidence/2026-03-03_03-35-05-813/visual/report.md`, `parity/evidence/2026-03-03_03-27-08-879/visual/report.md`, `parity/baseline/notes.md` | Visual evidence is unblocked with authenticated captures. Latest standard run compared `2/2` scenarios with average diff `1.462%` (`team-issues default-list: 1.94%`, `my-issues assigned: 0.984%`). |
| Tier 1 functional/filter/sub-view checklist >= 95% per view | PASS | `spec/requests/issues_spec.rb`, `spec/requests/users_spec.rb`, `PROGRESS.md`, `parity/SCORE_HISTORY.md` | Tier-1 filter/sub-view order-reset interactions are now aligned across shared list and board surfaces (explicit `sort/direction` state is clearable and defaults restore deterministically). Current score gaps to `95`: functional `0`, filter `0`, sub-view `0`. |
| Tier 2 functional/filter/sub-view checklist >= 90% per view | PASS | `PROGRESS.md`, `parity/SCORE_HISTORY.md` | Tier-2 slices (board/triage/settings/inbox/project) are tracked as accepted. |
| Tier 1 critical data/order cases 100% match; remaining >=95% | PASS | `spec/requests/issues_spec.rb` | Covered: default order, explicit `updated_at asc`, priority ordering (asc/desc), due-date ordering (asc/desc, undated last), workflow-state and status filters. |
| Tier 1 p95 performance budgets met | BLOCKED | `parity/evidence/latest.json`, `parity/evidence/2026-03-03_03-35-05-813/performance/report.md` | Performance capture is now partially unblocked with real measurements (`initial_list_render` PASS `1056ms`, `issue_detail_open` PASS `265ms`, `filter_apply_stable_list` FAIL `1022ms` vs `1000ms`, `cud_feedback` intermittently BLOCKED due flaky `New issue` control discovery in repeated samples). |
| Critical E2E flows all green | BLOCKED | `parity/evidence/latest.json`, `parity/evidence/2026-03-03_03-35-05-813/e2e/report.md`, `parity/evidence/2026-03-03_03-28-52-443/e2e/report.md`, `spec/requests/issues_spec.rb` | Browser E2E flow automation is implemented and reproducible. Best recent run shows `4/5` PASS (`create/edit/move/filter`) with remaining delete-flow selector instability; latest run also exhibits intermittent auth-shell timeout before flow start in one context, so full all-green gate is not yet met. |
| No open P0/P1 blockers for daily usage | PASS | `PROGRESS.md` | No active P0/P1 functional blocker currently tracked. |

## Tier-1 Threshold Gap Snapshot (score proxy vs target `95`)

- Visual parity: `95` (`gap: 0`)
- Functional parity: `95` (`gap: 0`)
- Filter parity: `95` (`gap: 0`)
- Sub-view parity: `95` (`gap: 0`)
- Data/order parity: `95` (`gap: 0`)

## Open Final Gaps

1. Stabilize repeated authenticated contexts in the evidence runner (intermittent `app-shell-ready` timeout) so all metrics/flows are measured in a single run.
2. Remove remaining flaky selectors:
   - `performance.cud_feedback` (`New issue` trigger across repeated samples)
   - `e2e.delete_issue` dropdown action targeting.
3. Tighten `filter_apply_stable_list` performance from `1022ms` p95 to `<=1000ms`.
4. Optionally provide `/tmp/linear-storage-state.json` if true state-matched authenticated Linear baseline capture is required for future baseline refresh cycles.
