# Parity DoD Status

Last updated: 2026-03-03 (UTC)

## Definitive Completion Criteria Status

| DoD Criterion | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Global score >= 92/100 | PASS | `parity/SCORE_HISTORY.md` (latest global score: 96) | Threshold met and held. |
| Tier 1 visual diff average < 2% | BLOCKED | `parity/baseline/notes.md` | Frozen Linear screenshot set has scaffold only; state-matched visual diff run not yet captured. |
| Tier 1 functional/filter/sub-view checklist >= 95% per view | PARTIAL | `spec/requests/issues_spec.rb`, `spec/requests/users_spec.rb`, `PROGRESS.md`, `parity/SCORE_HISTORY.md` | `My Issues > Subscribed` is now implemented and validated; remaining gap is final checklist evidence to reach >=95% per Tier-1 view. |
| Tier 2 functional/filter/sub-view checklist >= 90% per view | PASS | `PROGRESS.md`, `parity/SCORE_HISTORY.md` | Tier-2 slices (board/triage/settings/inbox/project) are tracked as accepted. |
| Tier 1 critical data/order cases 100% match; remaining >=95% | PASS | `spec/requests/issues_spec.rb` | Covered: default order, priority/due-date ordering, workflow-state and status filters. |
| Critical E2E flows all green | PARTIAL | `spec/requests/issues_spec.rb` | Request-level create/edit/move/assign/filter/delete coverage is green; browser E2E run not yet captured. |
| No open P0/P1 blockers for daily usage | PASS | `PROGRESS.md` | No active P0/P1 functional blocker currently tracked. |

## Open Final Gaps

1. Capture frozen Linear baseline screenshots for Tier-1 measured states under `parity/baseline/linear/<view>/<state>.png`.
2. Run and record state-matched visual diff averages (<2%) for Tier-1.
3. Collect and track Tier-1 p95 performance budget values (render/open/filter/CUD feedback).
