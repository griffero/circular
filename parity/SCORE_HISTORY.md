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

## No-Regression Check (Tier 1)

Latest accepted slice vs previous:
- Visual parity: +4
- Functional parity: +4
- Filter parity: +7
- Sub-view parity: +11
- Data/order parity: +5

Result: pass (no Tier 1 dimension decreased)
