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

## No-Regression Check (Tier 1)

Latest accepted slice vs previous:
- Visual parity: +0
- Functional parity: +0
- Filter parity: +0
- Sub-view parity: +0
- Data/order parity: +2

Result: pass (no Tier 1 dimension decreased)
