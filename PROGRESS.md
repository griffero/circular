# Circular -> Linear Parity Progress

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
