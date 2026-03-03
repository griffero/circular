# Performance Evidence

Generated: 2026-03-03T03:35:09.684Z
Samples per metric: 5

| Metric | Budget (ms) | p95 (ms) | Status | Notes |
|---|---:|---:|---|---|
| initial_list_render | 1800 | 1056 | PASS | - |
| issue_detail_open | 1200 | 265 | PASS | - |
| filter_apply_stable_list | 1000 | 1022 | FAIL | - |
| cud_feedback | 1000 | N/A | BLOCKED | TimeoutError: locator.click: Timeout 8000ms exceeded.
Call log:
[2m  - waiting for getByRole('button', { name: /New issue|Create issue/i }).first()[22m
 |