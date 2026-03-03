# Performance Evidence

Generated: 2026-03-03T03:29:52.963Z
Samples per metric: 5

| Metric | Budget (ms) | p95 (ms) | Status | Notes |
|---|---:|---:|---|---|
| initial_list_render | 1800 | N/A | BLOCKED | TimeoutError: page.waitForSelector: Timeout 20000ms exceeded.
Call log:
[2m  - waiting for locator('[data-testid="app-shell-ready"]') to be visible[22m
 |
| issue_detail_open | 1200 | 266 | PASS | - |
| filter_apply_stable_list | 1000 | 1015 | FAIL | - |
| cud_feedback | 1000 | 552 | PASS | - |