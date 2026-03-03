# Performance Evidence

Generated: 2026-03-03T03:27:12.645Z
Samples per metric: 5

| Metric | Budget (ms) | p95 (ms) | Status | Notes |
|---|---:|---:|---|---|
| initial_list_render | 1800 | 1042 | PASS | - |
| issue_detail_open | 1200 | N/A | BLOCKED | TimeoutError: locator.waitFor: Timeout 10000ms exceeded.
Call log:
[2m  - waiting for getByRole('heading', { name: 'Create issue' }) to be hidden[22m
[2m    25 × locator resolved to visible <h2 class="text-lg font-semibold text-[var(--linear-text)]">Create issue</h2>[22m
 |
| filter_apply_stable_list | 1000 | N/A | BLOCKED | TimeoutError: page.waitForSelector: Timeout 20000ms exceeded.
Call log:
[2m  - waiting for locator('[data-testid="app-shell-ready"]') to be visible[22m
 |
| cud_feedback | 1000 | N/A | BLOCKED | TimeoutError: page.waitForSelector: Timeout 20000ms exceeded.
Call log:
[2m  - waiting for locator('[data-testid="app-shell-ready"]') to be visible[22m
 |