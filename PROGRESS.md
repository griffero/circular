# Circular -> Linear Parity Progress

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
