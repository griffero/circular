# Browser E2E Evidence

Generated: 2026-03-03T03:30:43.128Z

| Flow | Status | Evidence | Notes |
|---|---|---|---|
| Create issue | PASS | Modal submit + close observed | - |
| Edit issue key fields | PASS | Title edit + save completed | - |
| Move workflow/state + assign/unassign | PASS | Assignee dropdown interaction completed | - |
| Filter + switch sub-views | PASS | statuses query persisted across issue-shell sub-view switch | - |
| Delete issue | BLOCKED | - | TimeoutError: locator.click: Timeout 4000ms exceeded.
Call log:
[2m  - waiting for getByText('Delete issue').first()[22m
 |