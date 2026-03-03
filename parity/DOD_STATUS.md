# Parity DoD Status

Last updated: 2026-03-03 (UTC)

## Definitive Completion Criteria Status

| DoD Criterion | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Global score >= 92/100 | PASS | `parity/SCORE_HISTORY.md` (latest global score: 99) | Threshold met and held. |
| Tier 1 visual diff average < 2% | BLOCKED | `parity/baseline/notes.md` | Frozen Linear screenshot set has scaffold only; state-matched visual diff run not yet captured. Explicit metric gap: `>=95 visual score target` proxy is `77` (`gap: 18`). |
| Tier 1 functional/filter/sub-view checklist >= 95% per view | PASS | `spec/requests/issues_spec.rb`, `spec/requests/users_spec.rb`, `PROGRESS.md`, `parity/SCORE_HISTORY.md` | Tier-1 filter/sub-view order-reset interactions are now aligned across shared list and board surfaces (explicit `sort/direction` state is clearable and defaults restore deterministically). Current score gaps to `95`: functional `0`, filter `0`, sub-view `0`. |
| Tier 2 functional/filter/sub-view checklist >= 90% per view | PASS | `PROGRESS.md`, `parity/SCORE_HISTORY.md` | Tier-2 slices (board/triage/settings/inbox/project) are tracked as accepted. |
| Tier 1 critical data/order cases 100% match; remaining >=95% | PASS | `spec/requests/issues_spec.rb` | Covered: default order, explicit `updated_at asc`, priority ordering (asc/desc), due-date ordering (asc/desc, undated last), workflow-state and status filters. |
| Critical E2E flows all green | PARTIAL | `spec/requests/issues_spec.rb` | Request-level create/edit/move/assign/filter/delete coverage is green; browser E2E run not yet captured. |
| No open P0/P1 blockers for daily usage | PASS | `PROGRESS.md` | No active P0/P1 functional blocker currently tracked. |

## Tier-1 Threshold Gap Snapshot (score proxy vs target `95`)

- Visual parity: `77` (`gap: 18`)
- Functional parity: `95` (`gap: 0`)
- Filter parity: `95` (`gap: 0`)
- Sub-view parity: `95` (`gap: 0`)
- Data/order parity: `95` (`gap: 0`)

## Open Final Gaps

1. Capture frozen Linear baseline screenshots for Tier-1 measured states under `parity/baseline/linear/<view>/<state>.png`.
2. Run and record state-matched visual diff averages (<2%) for Tier-1.
3. Collect and track Tier-1 p95 performance budget values (render/open/filter/CUD feedback).
