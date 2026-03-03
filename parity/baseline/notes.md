# Frozen Linear Baseline Notes

## Baseline Metadata
- Reference workspace: `TBD`
- Capture window (UTC): `TBD`
- Captured by: `TBD`
- Browser/viewport: `TBD`
- Theme variants: light + dark (required)

## Measured Tier 1 Views + States

### Team Issues
- Route: `/team/<key>/issues`
- States:
  - `default-list`
  - `filters-open`
  - `status-filtered`
  - `empty-state`

### Issue Detail
- Route: `/issue/<id>`
- States:
  - `default`
  - `field-edit-open` (status/priority/assignee/project)
  - `delete-confirm`

### My Issues
- Route: `/my-issues`
- States:
  - `assigned`
  - `created`
  - `with-filters`
  - `empty-state`

### Critical Flows
- Create issue
- Edit key fields
- Move workflow/state
- Assign/unassign
- Filter + switch sub-views
- Delete issue

## File Convention
- Screenshots:
  - `parity/baseline/linear/<view>/<state>.png`
- Notes and interaction scripts:
  - this file (`parity/baseline/notes.md`)

## Change Control
- Baseline remains frozen for the active scoring cycle.
- If recaptured, append a new dated section instead of mutating old baseline metadata.
