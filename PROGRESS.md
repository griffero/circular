# Circular -> Linear Parity Progress

## Completed in this slice (2026-03-03, parity slice: final-blocker rerun + evidence feasibility refinement)

### 1) Final evidence blockers re-measured with fresh artifacts
- Executed:
  - `npm --prefix client run parity:evidence:baseline`
  - `npm --prefix client run parity:evidence`
- Generated fresh artifacts:
  - baseline-mode run: `parity/evidence/2026-03-03_02-36-04-130/*`
  - standard run: `parity/evidence/2026-03-03_02-36-04-129/*`
  - latest pointer: `parity/evidence/latest.json` -> `2026-03-03_02-36-04-130`
- Current outcomes (both runs):
  - Visual baseline/diff: `BLOCKED` (`0/2 compared`)
  - Tier-1 p95 performance budgets: `BLOCKED` (all four metrics blocked)
  - Browser E2E critical flows: `BLOCKED` (all five required flows blocked)

### 2) Playwright runtime feasibility blocker reduced
- Diagnosed prior browser blocker explicitly:
  - `browserType.launch: Executable doesn't exist ... chromium_headless_shell-1208`
- Remediated environment:
  - `cd client && npx playwright install chromium`
  - Verified launchability with `node --input-type=module ... chromium.launch(...)` (`launch_ok`)
- Impact:
  - Playwright-launch failure is no longer reported in latest evidence.
  - Remaining hard blocker is Circular app unreachable at `http://127.0.0.1:5173`.

### 3) Baseline capture feasibility status (explicit)
- `LINEAR_BASE` reachability is confirmed (`https://linear.app/fintoc` reachable), but `parity:evidence:baseline` still cannot capture baseline images while Circular is unreachable because the runner blocks scenario execution when Circular preconditions fail.
- Auth storage states remain missing:
  - `/tmp/circular-prod-storage-state.json`
  - `/tmp/linear-storage-state.json`
- Result: baseline capture and state-matched visual diffs remain infeasible in this environment until app reachability and auth-state prerequisites are satisfied.

## Validation run (this slice)
- ✅ `npm --prefix client run type-check`
- ✅ `npm --prefix client run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`
  - Result: `29 examples, 0 failures`

## Measurable deltas (this slice)
- Tier-1 visual parity: `+0` (still blocked by app reachability; no comparisons produced).
- Tier-1 functional parity: `+0` (held at target).
- Tier-1 filter parity: `+0` (held at target).
- Tier-1 sub-view parity: `+0` (held at target).
- Tier-1 data/order parity: `+0` (held at target).
- Tier-1 no-regression contract: maintained (no Tier-1 dimension decreased).
- Global parity score: `99 -> 99`.

## Explicit completion gate decision
- Objective status: `INCOMPLETE`.
- Evidence:
  - Visual diff DoD remains blocked (`0/2` compared) until Circular app is reachable and baseline capture can execute.
  - Tier-1 p95 performance evidence remains blocked due to unreachable app.
  - Critical browser E2E evidence remains blocked due to unreachable app.

## Completed in this slice (2026-03-03, parity slice: visual/p95/browser-e2e evidence pipeline + blocker capture)

### 1) Unified parity evidence tooling shipped (visual + performance + browser E2E)
- Added `client/scripts/parity-evidence.mjs`:
  - Runs a single parity evidence pipeline and writes versioned artifacts to `parity/evidence/<run-id>/`.
  - Captures/report sections for:
    - visual baseline/diff evidence (`visual/report.md`, `visual/results.json`)
    - Tier-1 p95 performance budgets (`performance/report.md`, `performance/results.json`)
    - browser E2E critical-flow evidence (`e2e/report.md`, `e2e/results.json`)
  - Writes `parity/evidence/latest.json` as a stable pointer to the latest run.
  - Records explicit `BLOCKED` reasons instead of failing silently when environment prerequisites are missing.

### 2) Tooling/docs wiring for repeatable parity evidence runs
- Updated `client/package.json` scripts:
  - `npm --prefix client run parity:evidence`
  - `npm --prefix client run parity:evidence:baseline` (enables baseline capture mode)
- Added `parity/EVIDENCE.md`:
  - documents commands, artifact contract, prerequisites, and env overrides.
- Added parity evidence scaffold directory:
  - `parity/evidence/.gitkeep`

### 3) First evidence run captured in this environment
- Executed: `npm --prefix client run parity:evidence`
- Generated:
  - `parity/evidence/2026-03-03_02-28-58-900/SUMMARY.md`
  - `parity/evidence/2026-03-03_02-28-58-900/visual/report.md`
  - `parity/evidence/2026-03-03_02-28-58-900/performance/report.md`
  - `parity/evidence/2026-03-03_02-28-58-900/e2e/report.md`
  - `parity/evidence/latest.json`
- Evidence outcome:
  - Visual baseline/diff: `BLOCKED`
  - p95 performance budgets: `BLOCKED`
  - Browser E2E evidence: `BLOCKED`
  - Captured blocker reasons: Circular unreachable at `http://127.0.0.1:5173`, Playwright launch failure, missing storage-state files.

## Validation run (this slice)
- ✅ `npm --prefix client run parity:evidence`
- ✅ `node --check client/scripts/parity-evidence.mjs`
- ✅ `npm --prefix client run build`
- ⚠️ `npm --prefix client run lint:check -- scripts/parity-evidence.mjs`
  - Fails due to broad pre-existing repo lint debt (many existing `no-undef` / unused-var violations across unrelated files); not introduced by this slice.

## Measurable deltas (this slice)
- Tier-1 visual parity: `+0` (measurement harness added; runtime evidence still blocked in this environment).
- Tier-1 functional parity: `+0` (held at target).
- Tier-1 filter parity: `+0` (held at target).
- Tier-1 sub-view parity: `+0` (held at target).
- Tier-1 data/order parity: `+0` (held at target).
- Tier-1 no-regression contract: maintained (no Tier-1 dimension decreased).
- Global parity score: `99 -> 99`.

## Explicit completion gate decision
- Objective status: `INCOMPLETE`.
- Evidence:
  - Visual diff average gate remains blocked pending reachable app + baseline capture run.
  - p95 budget gate now has an implemented runner but remains blocked pending reachable app/browser runtime.
  - Browser E2E gate now has an implemented runner but remains blocked pending reachable app/browser runtime.

## Completed in this slice (2026-03-03, parity slice: Tier-1 sort-reset parity + due-date-desc order evidence)

### 1) Tier-1 filter/sub-view parity fix (explicit sort/direction are now clearable active filters)
- Updated `client/src/components/issues/IssueFilters.vue`:
  - Treated explicit `sort`/`direction` as active filter state.
  - Updated `Clear` behavior to fully reset explicit ordering overrides (`sort` and `direction`) so per-view defaults can be restored in one action.
- Updated `client/src/components/issues/IssueList.vue`:
  - Added active chips for explicit `Sort` and `Direction` with one-click removal.
  - Extended `Clear all` to reset explicit `sort/direction` overrides.
- Updated `client/src/components/pages/team/TeamBoardPage.vue`:
  - Added active chips for explicit `Sort` and `Direction` in board mode with one-click removal.
  - Extended board `Clear all` to reset explicit `sort/direction` overrides.

### 2) Tier-1 data/order evidence expansion (descending due-date semantics)
- Updated `spec/requests/issues_spec.rb`:
  - Added coverage for `GET /api/v1/issues?sort=due_date&direction=desc` to confirm dated issues sort descending while undated issues remain last.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`
  - Result: `29 examples, 0 failures`

## Measurable deltas (this slice)
- Tier-1 visual parity: `+0` (visual diff gate still pending frozen baseline + state-matched capture run).
- Tier-1 functional parity: `+0` (held at target).
- Tier-1 filter parity: `+1` (explicit ordering controls now have full active/remove/reset parity in list + board surfaces).
- Tier-1 sub-view parity: `+1` (order-reset behavior is now consistent when switching among Team issue-shell sub-views).
- Tier-1 data/order parity: `+1` (descending due-date ordering semantics are now explicitly covered and held).
- Tier-1 no-regression contract: maintained (no Tier-1 dimension decreased).
- Global parity score: `99 -> 99`.

## Gap-to-target snapshot (Tier-1 threshold target: `95` each)
- Visual: `77/95` (`gap: 18`)
- Functional: `95/95` (`gap: 0`)
- Filter: `95/95` (`gap: 0`)
- Sub-view: `95/95` (`gap: 0`)
- Data/order: `95/95` (`gap: 0`)

## Explicit completion gate decision
- Objective status: `INCOMPLETE`.
- Evidence:
  - Tier-1 visual delta remains non-zero (`visual +18`).
  - DoD criterion "Tier-1 visual diff average <2%" remains blocked pending frozen baseline capture + diff run evidence.

## Completed in this slice (2026-03-03, parity slice: Tier-1 board filter interaction + priority-desc order parity)

### 1) Tier-1 filter/sub-view/visual parity improvement (Team Board active filter interaction shell)
- Updated `client/src/components/pages/team/TeamBoardPage.vue`:
  - Added active filter chips in board mode for `statuses/status`, `priority`, `assignee`, and `q`.
  - Added one-click per-chip remove actions and a `Clear all` action.
  - Kept board query synchronization behavior unchanged while making board filter interactions consistent with shared list surfaces.

### 2) Tier-1 data/order parity fix (priority descending keeps no-priority last)
- Updated `app/controllers/api/v1/issues_controller.rb`:
  - Adjusted `sort=priority` ordering to always place `priority=0` issues at the end for both `asc` and `desc`.
  - Preserved deterministic tie-breakers (`updated_at desc`, `id asc`) for stable list/board ordering.

### 3) Tier-1 data/order evidence expansion (request coverage)
- Updated `spec/requests/issues_spec.rb`:
  - Added explicit coverage for `GET /api/v1/issues?sort=priority&direction=desc` confirming no-priority issues remain last.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`
  - Result: `28 examples, 0 failures`

## Measurable deltas (this slice)
- Tier-1 visual parity: `+1` (Team Board now exposes an app-native active-filter chip surface aligned with shared list interaction patterns).
- Tier-1 functional parity: `+0` (threshold held at target).
- Tier-1 filter parity: `+1` (board mode now supports direct per-filter removal and clear-all interaction parity).
- Tier-1 sub-view parity: `+1` (board sub-view filter behavior now matches issue-list sub-view affordances).
- Tier-1 data/order parity: `+1` (priority descending ordering semantics normalized with no-priority consistently last).
- Tier-1 no-regression contract: maintained (no Tier-1 dimension decreased).
- Global parity score: `99 -> 99`.

## Gap-to-target snapshot (Tier-1 threshold target: `95` each)
- Visual: `77/95` (`gap: 18`)
- Functional: `95/95` (`gap: 0`)
- Filter: `94/95` (`gap: 1`)
- Sub-view: `94/95` (`gap: 1`)
- Data/order: `94/95` (`gap: 1`)

## Explicit completion gate decision
- Objective status: `INCOMPLETE`.
- Evidence:
  - Tier-1 non-zero deltas remain (`visual +18`, `filter +1`, `sub-view +1`, `data/order +1`).
  - DoD criterion "Tier-1 visual diff average <2%" remains blocked pending frozen baseline capture + diff run evidence.

## Completed in this slice (2026-03-03, parity slice: Tier-1 team-board filter URL + sub-view carryover parity)

### 1) Tier-1 sub-view/filter parity improvement (Team issue-shell tab carryover)
- Updated `client/src/components/pages/TeamPage.vue`:
  - Preserved shared issue filter query keys (`q`, `status`, `statuses`, `priority`, `assignee`, `sort`, `direction`) when switching between Team issue-shell tabs (`All Issues`, `Active`, `Triage`, `Backlog`, `Board`).
  - Kept non-issue-shell navigation behavior unchanged (for example, cycles routes do not inherit issue-list filters).

### 2) Tier-1 filter parity improvement (Team Board now hydrates/persists shared filters)
- Updated `client/src/components/pages/team/TeamBoardPage.vue`:
  - Added route-query hydration for board filters so deep links/reload/back-forward restore filter state.
  - Added filter-to-query synchronization (`router.replace`) for `q/statuses/priority/assignee/sort/direction` in board mode.
  - Aligned board sort/direction fallback behavior to shared-list semantics (`updated_at desc`) while preserving `perPage: 500`.

### 3) Tier-1 data/order parity evidence expansion (request coverage)
- Updated `spec/requests/issues_spec.rb`:
  - Added coverage for explicit `sort=updated_at&direction=asc` ordering semantics.
  - Added coverage for text search filter (`q`) on issue title/description.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`

## Measurable deltas (this slice)
- Tier-1 visual parity: `+0` (no visual diff pass captured in this slice).
- Tier-1 functional parity: `+0` (functional threshold already met and held).
- Tier-1 filter parity: `+1` (Team Board now matches shared URL-persistent filter behavior in issue-shell flows).
- Tier-1 sub-view parity: `+1` (switching Team issue sub-views now preserves shared filter context).
- Tier-1 data/order parity: `+1` (explicit `updated_at asc` ordering covered and aligned with board/list query persistence behavior).
- Tier-1 no-regression contract: maintained (no Tier-1 dimension decreased).
- Global parity score: `99 -> 99`.

## Gap-to-target snapshot (Tier-1 threshold target: `95` each)
- Visual: `76/95` (`gap: 19`)
- Functional: `95/95` (`gap: 0`)
- Filter: `93/95` (`gap: 2`)
- Sub-view: `93/95` (`gap: 2`)
- Data/order: `93/95` (`gap: 2`)

## Explicit completion gate decision
- Objective status: `INCOMPLETE`.
- Evidence:
  - Tier-1 non-zero deltas remain (`visual +19`, `filter +2`, `sub-view +2`, `data/order +2`).
  - DoD criterion "Tier-1 visual diff average <2%" remains blocked pending frozen baseline capture + diff run evidence.

## Completed in this slice (2026-03-03, parity slice: Tier-1 final-threshold gating hardening)

### 1) Scorecard completion-gate hardening (explicit Tier-1 threshold contract)
- Updated `PARITY_SCORECARD.md`:
  - Added explicit blocking Tier-1 thresholds (`>=95`) for visual/functional/filter/sub-view/data-order.
  - Added deterministic delta formula: `delta = max(95 - current_score, 0)`.
  - Added explicit completion decision contract:
    - `COMPLETE` only when all DoD criteria pass and all Tier-1 deltas are `0`.
    - `INCOMPLETE` when any DoD criterion is partial/blocked or any Tier-1 delta is non-zero.

### 2) Score history/gating reporting alignment (no-regression preserved)
- Updated `parity/SCORE_HISTORY.md`:
  - Added accepted slice entry for gating hardening with unchanged scores.
  - Updated no-regression check against the prior accepted slice (`+0` on all Tier-1 dimensions, pass).
  - Updated latest-slice gap snapshot reference to this slice while preserving exact current gaps.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`

## Measurable deltas (this slice)
- Tier-1 visual parity: `+0` (no score movement; gating clarity only).
- Tier-1 functional parity: `+0` (no score movement; gating clarity only).
- Tier-1 filter parity: `+0` (no score movement; gating clarity only).
- Tier-1 sub-view parity: `+0` (no score movement; gating clarity only).
- Tier-1 data/order parity: `+0` (no score movement; gating clarity only).
- Tier-1 no-regression contract: maintained (latest accepted slice is flat vs previous on all Tier-1 dimensions).
- Global parity score: `99 -> 99`.

## Gap-to-target snapshot (Tier-1 threshold target: `95` each)
- Visual: `76/95` (`gap: 19`)
- Functional: `95/95` (`gap: 0`)
- Filter: `92/95` (`gap: 3`)
- Sub-view: `92/95` (`gap: 3`)
- Data/order: `92/95` (`gap: 3`)

## Explicit completion gate decision
- Objective status: `INCOMPLETE`.
- Evidence:
  - Tier-1 non-zero deltas remain (`visual +19`, `filter +3`, `sub-view +3`, `data/order +3`).
  - DoD criterion "Tier-1 visual diff average <2%" remains blocked pending frozen baseline capture + diff run evidence.

## Completed in this slice (2026-03-03, parity slice: Tier-1 shared-list filter URL persistence parity)

### 1) Tier-1 filter/sub-view parity fix (shared list filters are now URL-persistent)
- Updated `client/src/components/issues/IssueList.vue`:
  - Added route-query hydration for shared filters: `q`, `statuses`, `priority`, `assignee`, `sort`, `direction`.
  - Added local filter -> URL synchronization via `router.replace(...)` so Team Issues/My Issues filter context survives reload/back-forward and is shareable as a link.
  - Added route-query -> local filter synchronization so browser navigation restores prior filtered list state instead of resetting.

### 2) Tier-1 functional parity hardening (navigation-safe list state)
- Shared issue list flows now keep list filter intent stable across navigation lifecycle events, reducing lost-context churn during team triage and personal issue review.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`

## Measurable deltas (this slice)
- Tier-1 functional parity: `+1` (shared list filter state now persists through navigation/reload, reducing context-reset behavior in Tier-1 list workflows).
- Tier-1 filter parity: `+2` (shared list filters are now deep-linkable and restorable via URL query across Tier-1 list surfaces).
- Tier-1 sub-view parity: `+2` (state restoration through back-forward/reload now applies to filterable list states inside Tier-1 sub-views, not only tab selection).
- Tier-1 no-regression contract: maintained (all Tier-1 dimensions held or improved in `parity/SCORE_HISTORY.md`).
- Global parity score: `98 -> 99`.

## Gap-to-target snapshot (Tier-1 threshold target: `95` each)
- Visual: `76/95` (`gap: 19`)
- Functional: `95/95` (`gap: 0`)
- Filter: `92/95` (`gap: 3`)
- Sub-view: `92/95` (`gap: 3`)
- Data/order: `92/95` (`gap: 3`)

## Completed in this slice (2026-03-03, parity slice: Tier-1 My Issues URL sub-view parity)

### 1) Tier-1 sub-view parity fix (My Issues tab state is now URL-addressable)
- Updated `client/src/components/pages/MyIssuesPage.vue`:
  - Synced active tab state with `?view=` query param using the allowed values `assigned`, `created`, and `subscribed`.
  - Added route-query -> local-state hydration so reload/back-forward/shared links restore the correct sub-view instead of resetting to default.
  - Added local-state -> route-query synchronization via `router.replace(...)` so tab switches persist without polluting history.

### 2) Tier-1 functional/filter parity hardening (stable sub-view persistence)
- My Issues now preserves sub-view intent across navigation lifecycle events, making filter context stable for each sub-view and reducing accidental context loss during daily issue triage.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`

## Measurable deltas (this slice)
- Tier-1 sub-view parity: `+2` (My Issues sub-views are now deep-linkable and persist across reload/back-forward flows).
- Tier-1 functional parity: `+1` (sub-view context no longer resets unexpectedly on navigation lifecycle changes).
- Tier-1 filter parity: `+1` (sub-view-specific filtering context is preserved and shareable via URL state).
- Tier-1 no-regression contract: maintained (all Tier-1 dimensions held or improved in `parity/SCORE_HISTORY.md`).
- Global parity score: `97 -> 98`.

## Gap-to-target snapshot (Tier-1 threshold target: `95` each)
- Visual: `76/95` (`gap: 19`)
- Functional: `94/95` (`gap: 1`)
- Filter: `90/95` (`gap: 5`)
- Sub-view: `90/95` (`gap: 5`)
- Data/order: `92/95` (`gap: 3`)

## Completed in this slice (2026-03-03, parity slice: Tier-1 issue-activity + shared-search-filter parity)

### 1) Tier-1 Issue Detail functional/sub-view parity fix (Activity is now real)
- Fixed `app/controllers/api/v1/comments_controller.rb` for the current single-tenant API shape:
  - Removed stale workspace-scoped lookup/callbacks that were incompatible with `/api/v1/issues/:issue_id/comments`.
  - Bound comments to `Issue.find(params[:issue_id])`, so Issue Detail activity API calls now resolve correctly.
- Updated `client/src/components/pages/IssuePage.vue`:
  - Replaced placeholder-only `Activity` section with real comments list rendering.
  - Added create-comment flow wired to existing `issuesStore.createComment(...)`.
  - Added activity loading state and kept empty-state behavior when no comments exist.

### 2) Tier-1 shared-list filter parity improvement (search filter + clear path)
- Updated `client/src/components/issues/IssueFilters.vue`:
  - Added shared text search input (`q`) to filter bar.
  - Integrated `q` into active-filter detection and clear action behavior.
- Updated `client/src/components/issues/IssueList.vue`:
  - Added active filter chip for search query (`Search: ...`) with one-click removal.
  - Included `q` in `Clear all` reset behavior.

### 3) Tier-1 data/order parity hardening (fallback sort semantics)
- Updated `client/src/components/issues/IssueList.vue` fallback sorting to `updated_at desc` when no explicit per-view sort is provided.
- Updated `client/src/components/issues/IssueFilters.vue` default sort label fallback to `Updated` for UI/query consistency.

### 4) Regression coverage expansion (request specs)
- Updated `spec/requests/issues_spec.rb`:
  - Added `GET /api/v1/issues/:issue_id/comments` coverage.
  - Added `POST /api/v1/issues/:issue_id/comments` coverage.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`

## Measurable deltas (this slice)
- Tier-1 visual parity: `+1` (Issue Detail activity moved from static placeholder to app-native rendered interaction surface).
- Tier-1 functional parity: `+2` (Issue Detail activity API path is now routable in single-tenant mode + comment create flow is operational in-page).
- Tier-1 filter parity: `+2` (shared `q` search filter plus query-specific active chip/reset behavior across shared list contexts).
- Tier-1 sub-view parity: `+2` (Issue Detail activity sub-view now has loading/empty/populated/comment-compose states instead of a single placeholder state).
- Tier-1 data/order parity: `+1` (shared IssueList default fallback ordering now aligns to `updated_at desc`).
- Global parity score: `96 -> 97`.

## Gap-to-target snapshot (Tier-1 threshold target: `95` each)
- Visual: `76/95` (`gap: 19`)
- Functional: `93/95` (`gap: 2`)
- Filter: `89/95` (`gap: 6`)
- Sub-view: `88/95` (`gap: 7`)
- Data/order: `92/95` (`gap: 3`)

## Completed in this slice (2026-03-03, parity slice: Tier-1 My Issues subscribed sub-view parity)

### 1) Tier-1 sub-view/functional parity fix (My Issues > Subscribed is now real)
- Added subscription persistence model:
  - `db/migrate/20260303103000_create_issue_subscriptions.rb`
  - `app/models/issue_subscription.rb`
- Wired issue/user associations and automatic subscription behavior:
  - `app/models/issue.rb`: auto-subscribe creator on create and new assignee on assignee change.
  - `app/models/user.rb`: subscribed-issues association.
- Added API filter support:
  - `app/controllers/api/v1/issues_controller.rb` now supports `subscribed=true` for current-user subscriptions.

### 2) Tier-1 UI parity improvement (Subscribed tab no longer placeholder)
- Updated `client/src/components/pages/MyIssuesPage.vue`:
  - Replaced placeholder "Subscribed not available yet" state with real shared `IssueList` rendering.
  - Added `baseFilters.subscribed=true` for the Subscribed tab with `updated_at desc` ordering.
  - Added subscribed-specific empty state text.
- Updated `client/src/stores/issues.ts`:
  - Added typed `subscribed` filter and request serialization (`subscribed=true`).

### 3) Regression coverage expansion (request specs)
- Updated `spec/requests/issues_spec.rb`:
  - Verifies issue creator is auto-subscribed on create.
  - Verifies assignee is auto-subscribed on assignment.
  - Verifies `GET /api/v1/issues?subscribed=true` returns only current-user subscribed issues.
- Added `spec/factories/issue_subscriptions.rb`.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`

## Measurable deltas (this slice)
- Tier-1 sub-view parity: `+3` (My Issues `Subscribed` moved from excluded placeholder to functional list behavior).
- Tier-1 functional parity: `+1` (subscription behavior now persisted and queryable in core issue API flows).
- Tier-1 no-regression contract: maintained (all Tier-1 dimensions held or improved in `parity/SCORE_HISTORY.md`).
- Global parity score: `95 -> 96`.

## Completed in this slice (2026-03-03, parity slice: Tier-1 critical-flow coverage + DoD gap tracker)

### 1) Tier-1 critical flow regression coverage expansion
- Updated `spec/requests/issues_spec.rb`:
  - Added key-field edit coverage for Issue Detail parity (`title`, `description` update path).
  - Added explicit assign/unassign flow coverage for `PATCH /api/v1/issues/:id`.
- This closes request-level coverage holes for two Tier-1 critical flows called out in the scorecard DoD.

### 2) Final DoD artifact hardening
- Added `parity/DOD_STATUS.md` to track each scorecard completion criterion with:
  - status (`PASS`/`PARTIAL`/`BLOCKED`),
  - concrete evidence paths,
  - explicit remaining final gaps.
- Updated `parity/baseline/notes.md` metadata from `TBD` placeholders to explicit pending-capture state so baseline blockers are documented rather than implicit.
- Updated `parity/SCORE_HISTORY.md` with a new accepted slice entry while preserving no-regression across Tier-1 dimensions.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`

## Measurable deltas (this slice)
- Tier-1 request critical-flow coverage: `+2` cases (Issue Detail key-field edit + assign/unassign).
- Tier-1 no-regression contract: maintained (all Tier-1 dimensions held in `parity/SCORE_HISTORY.md`).
- DoD reporting completeness: `+1` explicit criterion-level status tracker (`parity/DOD_STATUS.md`), including remaining blockers for visual-diff and performance evidence capture.

## Completed in this slice (2026-03-03, parity slice: Tier-2 settings profile persisted-edit parity)

### 1) Tier-2 functional parity improvement (Settings > Profile now persists user edits)
- Updated `client/src/components/pages/settings/ProfileSettings.vue`:
  - Replaced placeholder save behavior with real `PATCH /api/v1/users/:id` persistence.
  - Wired profile form state (`name`, `display_name`, `timezone`) to authenticated user data and reactive store updates.
  - Added explicit success and error feedback states for save outcomes.
- Updated `client/src/stores/auth.ts` with `setCurrentUser(...)` so profile changes are reflected immediately in the app shell after save.

### 2) Tier-2 API parity hardening (self-service profile updates + payload compatibility)
- Updated `app/controllers/api/v1/users_controller.rb`:
  - Added `authorize_update!` to allow non-admin users to update only their own profile.
  - Kept admin/owner management capabilities for user administration actions.
  - Expanded `user_params` to support both nested (`user: { ... }`) and flat payload shapes used across settings screens.
  - Allowed admin updates to include `display_name` while preserving non-admin restrictions on sensitive fields like `email`.

### 3) Regression coverage expansion (request specs for users update behavior)
- Added `spec/requests/users_spec.rb` with coverage for:
  - Member self-update profile success (including `display_name` + `timezone`).
  - Member forbidden when attempting to update a different user.
  - Admin update compatibility using flat params (`name`, `display_name`, `email`) for settings management parity.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ⚠️ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests`
  - Fails on pre-existing `spec/requests/auth_spec.rb` drift (legacy `/api/v1/auth/signup` and `/api/v1/auth/login` expectations, plus unrelated project factory status assertions).
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb spec/requests/users_spec.rb`

## Measurable deltas (this slice)
- Tier-2 Settings functional parity: `+1` (Profile settings moved from placeholder save to persisted API-backed updates with in-app feedback).
- Tier-2 settings data-consistency parity: `+1` (profile saves now update authenticated user state immediately without reload).
- Tier-1 no-regression contract: maintained (no Tier-1 dimension decreased in `parity/SCORE_HISTORY.md`).
- Global parity score: `94 -> 95`.

## Completed in this slice (2026-03-03, parity slice: Tier-1 issue-detail delete-confirm parity)

### 1) Tier-1 sub-view/functional parity fix (Issue Detail delete confirmation state)
- Updated `client/src/components/pages/IssuePage.vue` to replace browser-native `confirm()` with an in-app themed confirmation modal:
  - Added explicit `delete-confirm` state with `Cancel` and `Delete issue` actions.
  - Wired modal open/close behavior from the Issue Detail overflow menu delete action.
  - Added in-flight guards so close/dismiss is blocked while delete is executing.
- This closes the baseline Tier-1 Issue Detail `delete-confirm` state gap and aligns behavior with app-native interaction patterns.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb`

## Measurable deltas (this slice)
- Tier-1 sub-view parity: `+1` (Issue Detail now has an explicit in-app `delete-confirm` state).
- Tier-1 functional parity: `+1` (delete action now follows app-native confirm/cancel flow with in-flight safety).
- Tier-1 visual parity: `+1` (delete confirmation UI now uses shared modal/button tokens instead of browser-native confirm dialog).
- Tier-1 no-regression contract: maintained (all Tier-1 dimensions held or improved in `parity/SCORE_HISTORY.md`).
- Global parity score: `93 -> 94`.

## Completed in this slice (2026-03-03, parity slice: Tier-2 settings labels CRUD parity)

### 1) Tier-2 functional parity improvement (Settings > Labels now API-backed)
- Reworked `client/src/components/pages/settings/LabelsSettings.vue` from placeholder local data to live backend CRUD:
  - Added real `GET /api/v1/labels` loading on page mount.
  - Wired create flow to `POST /api/v1/labels`.
  - Added edit flow (new modal) wired to `PATCH /api/v1/labels/:id`.
  - Added delete flow wired to `DELETE /api/v1/labels/:id` with confirmation and in-flight disable state.
- Added first-class loading/error surface so labels settings behavior matches production-backed settings patterns.

### 2) Tier-2 interaction parity hardening (admin label management actions)
- Enabled previously non-functional action controls in label rows:
  - Edit icon now opens populated edit form.
  - Delete icon now executes persisted deletion and updates UI state.
- Retained admin-only mutation controls while preserving read visibility for non-admin users.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb`

## Measurable deltas (this slice)
- Tier-2 Settings functional parity: `+1` (`Labels` moved from placeholder-only UI to persisted CRUD against existing labels API).
- Tier-2 interaction parity: `+1` row-level label edit/delete actions now functional.
- Tier-1 no-regression contract: maintained (all Tier-1 dimensions held in `parity/SCORE_HISTORY.md`).
- Global parity score: `92 -> 93`.

## Completed in this slice (2026-03-03, parity slice: Tier-2 triage/backlog workflow-state parity)

### 1) Tier-2 sub-view parity fix (triage vs backlog no longer duplicates)
- Added `workflow_state_type` filtering support to `GET /api/v1/issues` in `app/controllers/api/v1/issues_controller.rb`.
- Implemented a legacy-safe backlog fallback in the same filter path:
  - `workflow_state_type=backlog` now includes issues with no `workflow_state_id` when their legacy `status` is `backlog`.
- Wired team sub-views to distinct filters:
  - `client/src/components/pages/team/TeamTriagePage.vue` now uses `workflowStateType='triage'`.
  - `client/src/components/pages/team/TeamBacklogPage.vue` now uses `workflowStateType='backlog'`.

### 2) Client filter serialization parity hardening
- Extended shared issue filter typing/serialization in `client/src/stores/issues.ts`:
  - Added typed `workflowStateType` in `IssueFilters`.
  - Added query serialization for `workflow_state_type`.

### 3) Regression coverage expansion (request specs)
- Extended `spec/requests/issues_spec.rb` with:
  - Distinct triage/backlog behavior when filtering by `workflow_state_type`.
  - Legacy backlog fallback coverage for issues without `workflow_state_id`.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb`

## Measurable deltas (this slice)
- Tier-2 sub-view parity: `+1` (`Team Triage` and `Team Backlog` now query distinct workflow-state type datasets instead of sharing the same backlog status filter).
- Tier-1 no-regression contract: maintained (all Tier-1 dimensions held or improved in `parity/SCORE_HISTORY.md`).
- Global parity score: `91 -> 92`.

## Completed in this slice (2026-03-03, parity slice: Tier-1 default-order parity + Tier-2 team sub-view discoverability)

### 1) Tier-2 sub-view parity improvement (team issue-shell navigation)
- Updated `client/src/components/pages/TeamPage.vue` issue-shell tabs to expose missing shared sub-views:
  - Added `Triage` tab (`/team/:key/triage`).
  - Added `Board` tab (`/team/:key/board`).
- Refined tab active-state logic so each sub-view route maps to its own active tab, removing the prior implicit `Active`/`Triage` coupling.

### 2) Tier-1 data/order parity hardening (default ordering fallback)
- Updated `app/controllers/api/v1/issues_controller.rb` default sorting path (`apply_sort` fallback):
  - Removed legacy fallback ordering tied to `sort_order`.
  - Default now consistently returns issues in `updated_at desc` order with deterministic tie-breakers (`created_at desc`, `id asc`), matching Tier-1 issue-list expectations when no explicit sort is provided.

### 3) Tier-1 regression coverage expansion (request spec)
- Extended `spec/requests/issues_spec.rb` with a new ordering example:
  - Verifies `GET /api/v1/issues` defaults to `updated_at desc` when `sort` is omitted.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb`

## Measurable deltas (this slice)
- Tier-2 sub-view discoverability: `+2` explicit team sub-views surfaced in primary issue-shell navigation (`Triage`, `Board`).
- Tier-1 data/order parity: `+1` API-level default ordering now aligned to `updated_at desc` behavior when clients omit explicit sort.
- Tier-1 no-regression contract: maintained (all Tier-1 dimension deltas non-negative in `parity/SCORE_HISTORY.md`).

## Completed in this slice (2026-03-03, parity slice: Tier-1 shared-list ordering + assignee filter parity)

### 1) Tier-1 data/order parity fix (shared list now honors per-view default sort)
- Updated `client/src/components/issues/IssueList.vue` to stop overriding `baseFilters` ordering defaults:
  - Removed hardcoded local default `sort=created_at` from shared list state.
  - Added resolved sort/direction merge so each view's base ordering (for example `updated_at desc`) is used until a user explicitly changes sort.
  - Wired the filter panel input to the resolved filter model so sort UI matches the actual query ordering.

### 2) Tier-1/Tier-2 filter parity improvement (full assignee filtering in shared filters)
- Updated `client/src/components/issues/IssueFilters.vue`:
  - Expanded assignee filter from only `(me)`/unassigned to full workspace user selection.
  - Added lazy user fetch for filter contexts that do not already load workspace users.
  - Added selected-assignee label resolution (including `(me)` suffix) in the filter trigger.
- Updated `client/src/components/issues/IssueList.vue` active chips:
  - Assignee chip now resolves selected user name when available instead of generic "Assigned to me" text for all non-unassigned cases.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb`

## Measurable deltas (this slice)
- Tier-1 data/order parity: `+2` (shared list now respects per-view default ordering instead of forcing created-date order).
- Tier-1 filter parity: `+2` (assignee filter now supports full workspace user set across shared issue-list surfaces).
- Tier-1 functional parity: `+1` (filter state labels/chips now reflect chosen assignee identities more accurately).

## Completed in this slice (2026-03-03, parity slice: Tier-1 create-flow assignee parity + Tier-2 Inbox theme parity)

### 1) Tier-1 create issue functional parity improvement (assignee selection)
- Updated `client/src/components/issues/CreateIssueModal.vue` to support full workspace assignee selection instead of only `(me)`/unassigned:
  - Assignee dropdown now lists all fetched users and keeps current user pinned/suffixed as `(me)`.
  - Modal now lazily calls `appStore.fetchUsers()` when opened and users are not yet present, preventing empty assignee menus in create flow contexts outside Issue Detail.

### 2) Tier-2 Inbox visual/action-shell parity improvement (theme consistency)
- Updated `client/src/components/pages/InboxPage.vue`:
  - Replaced hardcoded dark-only colors with shared `--linear-*` theme tokens across header, tabs, empty state, and list dividers.
  - Switched header actions (`Mark all read`, `Archive all`) to shared `Button` component usage for consistent interaction styling with the rest of the app shell.
  - Added tab-aware `filteredNotifications` computed wiring so empty-state rendering aligns with current tab selection scaffold.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ✅ `eval "$(rbenv init - zsh)" && rbenv shell 3.2.2 && bundle exec rspec spec/requests/issues_spec.rb`

## Measurable deltas (this slice)
- Tier-1 create-flow functional parity: `+1` (full assignee selection in Create Issue modal).
- Tier-2 Inbox theme parity: `+1` surface migrated from hardcoded dark palette to shared theme tokens.
- Runnable backend regression check restored in this environment via project Ruby (`rbenv` 3.2.2 + Bundler 2.6.4).

## Completed in this slice (2026-03-03, parity slice: Tier-1 multi-status filter interaction parity)

### 1) Tier-1 filter parity improvement (shared multi-status selection)
- Updated `client/src/components/issues/IssueFilters.vue` to support multi-select status filtering in the shared filter bar:
  - Status dropdown now supports selecting multiple statuses simultaneously.
  - Selected status summary now reflects count (`N statuses`) or specific status when only one is selected.
  - Clearing statuses now resets both `status` and `statuses` fields to prevent stale mixed filter state.

### 2) Tier-1 filter interaction parity improvement (active filter visibility + remove actions)
- Updated `client/src/components/issues/IssueList.vue` to add active filter chips directly below the shared filters:
  - Per-filter remove actions for status(es), priority, and assignee.
  - `Clear all` action to reset all user-applied filters while preserving base sub-view filters.
- This restores high-visibility filter state feedback and one-click filter removal behavior in the core Team Issues/My Issues/Project shared list surfaces.

### 3) Tier-1 API/filter semantics hardening
- Extended `spec/requests/issues_spec.rb` with precedence coverage when both `status` and `statuses` are provided:
  - New test confirms `statuses` takes precedence over `status`, matching controller behavior and preventing parameter ambiguity regressions in shared filter flows.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ⚠️ `bundle exec rspec spec/requests/issues_spec.rb` blocked in this environment:
  - Missing Bundler version required by lockfile: `bundler 2.6.4`.

## Measurable deltas (this slice)
- Tier-1 shared filter parity: `+1` major interaction capability (multi-status selection in shared IssueFilters).
- Tier-1 filter clarity/actions: `+1` shared active-filter chip surface with per-filter remove and clear-all.
- Request-level regression coverage: `+1` precedence case (`statuses` over `status`) for shared list semantics.

## Completed in this slice (2026-03-03, parity slice: Tier-1 issue-detail inline editing parity)

### 1) Tier-1 Issue Detail functional parity improvement (edit key fields)
- Updated `client/src/components/pages/IssuePage.vue` to add inline edit flows for:
  - Issue title
  - Issue description
- Added explicit save/cancel behavior with keyboard support:
  - Title: `Enter` to save, `Escape` to cancel.
  - Description: `Cmd/Ctrl+Enter` to save, `Escape` to cancel.
- Editing is now wired to `issuesStore.updateIssue(...)`, matching the existing optimistic update + server reconciliation path used by other editable issue fields.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ⚠️ `bundle exec rspec spec/requests/issues_spec.rb` blocked in this environment:
  - Missing Bundler version required by lockfile: `bundler 2.6.4`.

## Measurable deltas (this slice)
- Tier-1 issue-detail key-field editing parity: `+2` editable fields (`title`, `description`) moved from read-only display to persisted inline edit.
- Tier-1 Functional parity score contribution improved by closing a direct user-flow gap in the issue detail screen.

## Completed in this slice (2026-03-03, parity slice: Tier-1 team-issues ordering + Tier-2 board interaction parity)

### 1) Tier-1 Team Issues data/order parity improvement
- Updated `client/src/components/pages/team/TeamIssuesPage.vue` to enforce explicit default ordering:
  - `sort=updated_at`
  - `direction=desc`
- This aligns Team Issues main-list ordering with the already-normalized ordering behavior used by Active/Backlog/Triage/My Issues and reduces default-sort drift in the primary Tier-1 surface.

### 2) Tier-2 Team Board parity pass (filters + workflow-state move flow)
- Refactored `client/src/components/pages/team/TeamBoardPage.vue` to use shared issue infrastructure:
  - Switched data loading to `useIssuesStore` (`fetchWorkflowStates` + `fetchIssues`) instead of bespoke direct API calls.
  - Added shared `IssueFilters` panel support when filters are open, including status/priority/assignee/sort controls.
  - Added drag-and-drop workflow-state moves between board columns, wired to `issuesStore.updateIssue(..., { workflowStateId })`.
  - Added drop-target highlighting and in-flight movement state feedback for cards.
  - Preserved deterministic column order by workflow-state position, with stable in-column order from filtered API results.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ⚠️ `bundle exec rspec spec/requests/issues_spec.rb` blocked in this environment:
  - Missing Bundler version required by lockfile: `bundler 2.6.4`.

## Measurable deltas (this slice)
- Tier-1 default-order parity updated on primary Team Issues list: `+1` view normalized.
- Tier-2 Team Board parity improvements delivered:
  - `+1` shared filter surface (`IssueFilters`) added.
  - `+1` workflow-state move interaction path (drag/drop between columns).
  - `-1` bespoke direct-fetch path removed in favor of shared issues store flow.

## Completed in this slice (2026-03-03, parity slice: Tier-2 project/triage list parity)

### 1) Tier-2 Team Triage moved to shared issue list behavior
- Refactored `client/src/components/pages/team/TeamTriagePage.vue` to use shared `IssueList` infrastructure (instead of bespoke local list rendering).
- Triage now uses base filters aligned with shared semantics:
  - `statuses=['backlog']`
  - `sort=updated_at`
  - `direction=desc`
- This aligns triage with existing Team Issues/Active/Backlog list interactions, including shared filter panel behavior and grouped-state rendering.

### 2) Tier-2 Project Issues parity pass (shared list + theme consistency)
- Rebuilt `client/src/components/pages/ProjectPage.vue` around shared `IssueList` with `projectId` scoping:
  - Removed bespoke local issue filtering/rendering implementation.
  - Project issues now inherit the same filtering/sorting semantics and section rendering as other issue surfaces.
  - Default project issue ordering now uses `updated_at desc` to match active list behavior.
- Replaced hardcoded dark-only project page shell styles with shared theme tokens (`--linear-*`) for light/dark consistency.
- Kept project header metadata (state, dates, description) while normalizing actions to shared `Button` usage.

## Validation run (this slice)
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ℹ️ Backend specs were not rerun in this slice (frontend-only changes).

## Measurable deltas (this slice)
- Tier-2 views moved to shared issue-list stack: `+2` (`Team Triage`, `Project Issues`).
- Removed bespoke issue list logic from project view: `-1` custom implementation path.
- Theme-token parity improvement: Project Issues page shell now uses shared tokens end-to-end.

## Completed in this slice (2026-03-02, parity slice: issue list/detail)

### 1) Issue list filter interaction parity + UX
- Updated `client/src/components/issues/IssueList.vue` to make filter interactions fully live:
  - Added deep `filters` watch to refetch issues whenever filters change.
  - Added active-filter pills below the filter controls with per-filter remove actions.
  - Added `Clear all` action for active filters.
- Replaced hardcoded create CTA styling in list empty state with shared `Button` component for consistent action styling.

### 2) View-level button parity in issue flows
- Updated team issue-shell actions in `client/src/components/pages/TeamPage.vue`:
  - Replaced raw `Filter` and `New issue` buttons with shared `Button` component variants.
  - Filter button now reflects open/closed state consistently via button variant.

### 3) Dark theme token consistency pass (issue-focused components)
- Normalized mixed hardcoded dark/light classes to `--linear-*` tokens in:
  - `client/src/components/pages/IssuePage.vue`
  - `client/src/components/issues/IssuePanel.vue`
  - `client/src/components/issues/IssueFilters.vue`
  - `client/src/components/issues/CreateIssueModal.vue`
- Removed remaining hardcoded dark container palettes in these issue list/detail flows to keep light/dark behavior consistent with shared theme tokens.

### 4) Expanded issue user-flow/filter request specs
- Extended `spec/requests/issues_spec.rb` with additional coverage for:
  - Rich create payload flow (assignee, project, due date, labels, priority).
  - Detail-flow updates (title, description, priority, assignee, project, due date, labels).
  - Delete verification (`Issue.exists?` false after delete).
  - Additional filter interactions: `my_issues=true` and free-text `q` filtering.

## Completed in this slice (2026-03-02)

### 1) Issue API ordering/filter parity improvements
- Updated `GET /api/v1/issues` sorting behavior in `app/controllers/api/v1/issues_controller.rb` for more Linear-like consistency:
  - Added deterministic tie-breakers across sort modes.
  - `priority` sort now treats `priority=0` (No priority) as lowest priority in ascending mode (sorted after 1..4).
  - `due_date` sort now keeps undated issues grouped last.
  - Default sort now handles nullable `sort_order` consistently and adds stable tie-breakers.

### 2) Ticket update flow robustness
- Expanded issue strong params to include:
  - `workflow_state_id`
  - `cycle_id`
- This unblocks state/cycle updates sent by the current frontend update flow.

### 3) Theme consistency improvement (settings)
- Refactored `client/src/components/pages/settings/PreferencesSettings.vue`:
  - Removed hardcoded dark-only colors.
  - Switched to shared Linear theme tokens (`--linear-*`) for light/dark consistency.
  - Wired Interface Theme selector to global `uiStore.darkMode` so theme changes are applied app-wide from Preferences.

### 4) Added regression request specs for ticket CRUD + filter/sort behavior
- Added `spec/requests/issues_spec.rb` covering:
  - Create issue
  - Update issue (including `workflow_state_id` + `cycle_id`)
  - Delete issue
  - Filter by `team_id`
  - Filter by `assignee_id=unassigned`
  - Filter by `workflow_state_id`
  - Sort by `priority` (no-priority last in ascending)
  - Sort by `due_date` (undated last)
- Added missing factories used by these tests:
  - `spec/factories/workflow_states.rb`
  - `spec/factories/cycles.rb`

## Validation run
- ✅ `bundle exec rspec spec/requests/issues_spec.rb`
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`
- ⚠️ Existing unrelated failure observed in baseline model spec:
  - `bundle exec rspec spec/models/issue_spec.rb`
  - Failure: status presence matcher expectation conflicts with current model behavior.

## Remaining high-impact parity work
1. Normalize issue ordering semantics across all views/endpoints (and ensure frontend defaults mirror Linear view defaults).
2. Align filter controls and default states per view (Team Issues, My Issues, Inbox, Project views) to reduce mode drift.
3. Expand tests for additional filter/sort combinations and for optimistic update rollback behavior.
4. Continue global theme consistency pass on remaining settings/pages still using hardcoded `dark:`/hex token mismatches.
5. Investigate and fix the pre-existing `spec/models/issue_spec.rb` status validation mismatch.

## Render CLI note
- Render CLI was not required for this local slice.
- If deployment debugging for workspace `365` is needed in a future slice, verify credentials/context first, then install and run Render CLI commands from a separate scoped step.

## Completed in this slice (2026-03-03, parity slice: score infra + Tier-1 sub-view/filter consistency)

### 1) Score infrastructure + baseline scaffolding created
- Added required parity tracking files:
  - `parity/EXCLUSIONS.md`
  - `parity/SCORE_HISTORY.md`
- Added baseline scaffolding under `parity/baseline/`:
  - `parity/baseline/notes.md`
  - `parity/baseline/linear/.gitkeep`
  - `parity/baseline/linear/team-issues/.gitkeep`
  - `parity/baseline/linear/issue-detail/.gitkeep`
  - `parity/baseline/linear/my-issues/.gitkeep`
  - `parity/baseline/linear/issue-flows/.gitkeep`

### 2) Tier-1 parity improvements: Team sub-views + My Issues consistency
- Refactored `My Issues` to use shared `IssueList` infrastructure in `client/src/components/pages/MyIssuesPage.vue`:
  - `Assigned to me` now uses API-level `my_issues=true` filtering.
  - `Created by me` now uses API-level `creator_id` filtering.
  - Sub-views now share the same filter/sort panel and ordering behavior as Team Issues.
  - `Subscribed` explicitly marked unavailable and tracked via exclusions.
- Refactored team sub-views to shared list behavior:
  - `client/src/components/pages/team/TeamActivePage.vue` now uses shared `IssueList` with active status set (`todo`, `in_progress`, `in_review`) and updated-desc ordering.
  - `client/src/components/pages/team/TeamBacklogPage.vue` now uses shared `IssueList` with backlog defaults and updated-desc ordering.
- Upgraded shared list infrastructure in `client/src/components/issues/IssueList.vue`:
  - Added `baseFilters` support for sub-view defaults.
  - Preserved user-adjustable filters separately from base filters to avoid sub-view drift.
  - Empty-state create action now uses shared `Button` component.

### 3) Tier-1 parity improvements: Issue Detail flow behavior
- Updated `client/src/components/pages/IssuePage.vue`:
  - Back navigation now has deterministic fallback to team issues/home when browser history is unavailable.
  - Delete flow now redirects to team issues when possible (fallback: My Issues), improving post-delete continuity.

### 4) API parity improvements for filter/sub-view semantics
- Extended `GET /api/v1/issues` in `app/controllers/api/v1/issues_controller.rb`:
  - Added `creator_id` filter.
  - Added multi-status filter via `statuses=todo,in_progress,...`.
  - Preserved existing single `status=` support for compatibility.
- Extended client issue filters in `client/src/stores/issues.ts`:
  - Added `creatorId`, `myIssues`, and `statuses[]` support in typed filter model and query serialization.

### 5) Extended request specs for critical filter/sub-view/data-ordering cases
- Added tests in `spec/requests/issues_spec.rb` for:
  - `creator_id` filtering.
  - multi-status filtering (`statuses`) for active sub-view semantics.
  - `my_issues` + `statuses` combination behavior.

## Validation run (this slice)
- ⚠️ `bundle exec rspec spec/requests/issues_spec.rb` could not run in this environment:
  - Missing local Bundler version required by lockfile: `bundler 2.6.4`.
- ✅ `cd client && npm run type-check`
- ✅ `cd client && npm run build`

## Measurable deltas (this slice)
- New parity infrastructure files: `+9` (including baseline scaffolding and score/exclusions docs).
- Tier-1 sub-views moved onto shared issue list/filter stack: `+3` views (`My Issues`, `Team Active`, `Team Backlog`).
- New API filter capabilities: `+2` (`creator_id`, `statuses[]`).
- Request spec coverage additions: `+3` request examples focused on filter/sub-view consistency.
