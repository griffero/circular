# Parity Score History

Tracks accepted slice scores and enforces no-regression for Tier 1 dimensions.

## Scoring Dimensions
- Visual parity
- Functional parity
- Filter parity
- Sub-view parity
- Data/order parity

## Accepted Slices

| Date (UTC) | Slice | Tier 1 Visual | Tier 1 Functional | Tier 1 Filter | Tier 1 Sub-view | Tier 1 Data/order | Global Score | Notes |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 2026-03-02 | issue list/detail parity pass | 70 | 79 | 75 | 68 | 81 | 74 | Baseline from prior slice; needs explicit scoring infra + active/my-issues sub-view parity |
| 2026-03-03 | score infra + tier1 filters/sub-view pass | 74 | 83 | 82 | 79 | 86 | 80 | Added scoring infrastructure, multi-status + creator filters, shared sub-view behavior for Team Active/Backlog and My Issues |
| 2026-03-03 | tier2 triage + project shared-list parity pass | 74 | 83 | 82 | 79 | 86 | 83 | Moved Team Triage + Project Issues onto shared IssueList/filter stack; improved Project page theme-token consistency |
| 2026-03-03 | tier1 team-issues order + tier2 board interactions pass | 74 | 83 | 82 | 79 | 88 | 85 | Set Team Issues default ordering to updated-desc and upgraded Team Board with shared filters + drag/drop workflow-state transitions |
| 2026-03-03 | tier1 issue-detail inline editing parity pass | 74 | 85 | 82 | 79 | 88 | 87 | Added persisted inline editing for issue title/description with save/cancel keyboard flow; closes a Tier-1 issue-detail key-field gap |
| 2026-03-03 | tier1 multi-status filter interaction parity pass | 74 | 86 | 85 | 79 | 88 | 88 | Added shared multi-status filter selection + active filter chips in IssueList and request-spec coverage for `statuses` precedence behavior |
| 2026-03-03 | tier1 create-assignee + tier2 inbox-theme parity pass | 74 | 87 | 85 | 79 | 88 | 89 | Create Issue now supports full workspace assignee selection (with lazy user load); Inbox migrated to shared theme tokens/buttons for light/dark parity |
| 2026-03-03 | tier1 shared-list default-sort + assignee-filter parity pass | 74 | 88 | 87 | 79 | 90 | 90 | Fixed shared IssueList to honor per-view base sort defaults (`updated_at desc`) and expanded shared assignee filter to workspace users with resolved labels/chips |
| 2026-03-03 | tier1 default-order + tier2 team-subviews parity pass | 74 | 88 | 87 | 82 | 91 | 91 | Exposed Team `Triage` + `Board` sub-views in issue-shell navigation and set API default list ordering fallback to `updated_at desc` with request-spec coverage |
| 2026-03-03 | tier2 triage-vs-backlog workflow-state parity pass | 74 | 88 | 87 | 82 | 91 | 92 | Added `workflow_state_type` filtering and wired Team Triage/Backlog to distinct state-type filters (with legacy backlog fallback + request-spec coverage) |
| 2026-03-03 | tier2 settings-labels CRUD parity pass | 74 | 88 | 87 | 82 | 91 | 93 | Replaced placeholder Settings > Labels data with API-backed load/create/update/delete flows and wired row action buttons to persisted mutations |
| 2026-03-03 | tier1 issue-detail delete-confirm parity pass | 75 | 89 | 87 | 83 | 91 | 94 | Replaced browser-native delete confirm with in-app Issue Detail confirmation modal state, including cancel/delete actions and in-flight lockout |
| 2026-03-03 | tier2 settings-profile persisted-edit parity pass | 75 | 90 | 87 | 83 | 91 | 95 | Wired Settings > Profile to persisted user updates with reactive auth-state refresh, added self-update authorization + payload-shape compatibility in users API, and added request-spec coverage for member/admin update paths |
| 2026-03-03 | tier1 critical-flow coverage + DoD tracker pass | 75 | 90 | 87 | 83 | 91 | 95 | Added Tier-1 assign/unassign + key-field edit request coverage and introduced explicit `parity/DOD_STATUS.md` tracking for final visual/performance gaps |
| 2026-03-03 | tier1 my-issues subscribed sub-view parity pass | 75 | 91 | 87 | 86 | 91 | 96 | Implemented Issue subscriptions end-to-end (data model + API filter + My Issues subscribed tab), removed Tier-1 subscribed exclusion, and added request coverage for subscribed filtering + auto-subscribe flows |
| 2026-03-03 | tier1 issue-activity + shared-search-filter parity pass | 76 | 93 | 89 | 88 | 92 | 97 | Fixed single-tenant issue comments API pathing, replaced Issue Detail activity placeholder with real comments list/create flow, added shared text-search filter (`q`) with active chip/reset behavior, and set shared list fallback ordering to `updated_at desc` |
| 2026-03-03 | tier1 my-issues url-subview parity pass | 76 | 94 | 90 | 90 | 92 | 98 | Synced My Issues sub-view tabs to `?view=` query (`assigned|created|subscribed`) so state is shareable/persistent across reload/back-forward navigation and aligned with stable sub-view routing behavior |
| 2026-03-03 | tier1 shared-list filter-url persistence parity pass | 76 | 95 | 92 | 92 | 92 | 99 | Added shared IssueList route-query sync for `q/statuses/priority/assignee/sort/direction`, including back-forward hydration and reload persistence across Tier-1 list surfaces (Team Issues + My Issues) |

## No-Regression Check (Tier 1)

Latest accepted slice vs previous:
- Visual parity: +0
- Functional parity: +1
- Filter parity: +2
- Sub-view parity: +2
- Data/order parity: +0

Result: pass (no Tier 1 dimension decreased)

## Gap To Tier-1 Score Target (>=95 each)

Latest accepted slice (`2026-03-03`, `tier1 shared-list filter-url persistence parity pass`):
- Visual parity: `76/95` (gap: `19`)
- Functional parity: `95/95` (gap: `0`)
- Filter parity: `92/95` (gap: `3`)
- Sub-view parity: `92/95` (gap: `3`)
- Data/order parity: `92/95` (gap: `3`)
