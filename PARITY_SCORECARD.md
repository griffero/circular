# Circular → Linear Parity Scorecard (v1.0)

## Global Objective
Make `griffero/circular` operationally equivalent to Linear for daily team migration, under single-tenant constraints and without introducing dependencies on missing third-party integrations.

## Non-Negotiable Constraints
1. Keep Circular single-tenant (no new multi-tenant/org abstractions).
2. Do not implement features requiring non-existing third-party integrations.
3. Enforce dark/light consistency across all touched surfaces.
4. Ship incrementally to `main` with validation.

## Scope of Parity

### Tier 1 (Migration blockers)
- Team Issues (main list)
- Issue Detail
- My Issues
- Create / Update / Delete issue flows

### Tier 2 (Important)
- Inbox
- Project Issues
- Team Active / Board
- Team Backlog / Triage
- Settings / Preferences

## Evaluation Dimensions (per view)
1. Visual parity (layout/spacing/hierarchy/states)
2. Functional parity (buttons/actions/behaviors)
3. Filter parity (available filters/defaults/combinations/reset)
4. Sub-view parity (tabs/modes and behavior)
5. Data/order parity (query results and sort semantics)

## Definitive Completion Criteria (DoD)
Objective is complete only if **all** are true:

1. Global score **≥ 92/100**
2. Tier 1 visual diff average **< 2%** (state-matched screenshots)
3. Functional/Filter/Sub-view checklist completion:
   - Tier 1: **≥ 95%** per view
   - Tier 2: **≥ 90%** per view
4. Data/order parity:
   - Tier 1 critical cases: **100% match**
   - Remaining cases: **≥ 95% match**
5. Critical E2E flows all green:
   - Create issue
   - Edit issue (key fields)
   - Move workflow/state
   - Assign/unassign
   - Filter + switch sub-views
   - Delete issue
6. No open P0/P1 blockers for daily usage

---

## Additions (Hardening)

### A) Frozen Linear Baseline (required)
Before each parity run, baseline snapshots must be fixed to avoid moving targets.

Baseline set (must remain stable during scoring cycle):
- Linear workspace reference + date/time stamp
- Route + state fixtures for each measured view
- Screenshot set + interaction notes stored under:
  - `parity/baseline/linear/<view>/<state>.png`
  - `parity/baseline/notes.md`

### B) Performance Budget (required)
Parity includes responsiveness, not only visual similarity.

Budgets (Tier 1):
- p95 initial list render: **≤ 1.8s**
- p95 issue detail open: **≤ 1.2s**
- p95 filter apply → stable list: **≤ 1.0s**
- p95 create/update/delete action completion feedback: **≤ 1.0s**

If any budget regresses by >10% vs last accepted slice, slice is not accepted.

### C) Explicit Exclusions Matrix (required)
Anything out of scope must be written to prevent ambiguity/scope creep.

Track in `parity/EXCLUSIONS.md` with:
- Item
- Why excluded (missing integration / strategic defer)
- Owner
- Revisit condition

### D) No Regression Rule for Tier 1 (required)
Any slice that lowers Tier 1 score is rejected unless explicitly approved.

Enforcement:
- Keep `parity/SCORE_HISTORY.md`
- Compare current vs previous accepted slice
- Reject merge if Tier 1 dimension score decreases

---

## Reporting Contract
Each progress report must include:
- New commits (hash + summary)
- `main` vs `origin/main` sync state
- Score deltas by dimension
- Current blockers and next slice plan

No-update rule:
- Send no message if there is no meaningful change
- But if no outbound update for 20+ minutes, send a short keepalive status to avoid silent-failure risk
