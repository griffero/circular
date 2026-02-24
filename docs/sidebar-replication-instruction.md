Sidebar replication directive (saved for long-running iterations)

- Primary objective: replicate Linear sidebar behavior and visuals in Circular as faithfully as possible.
- Scope:
  - Team section hierarchy and interaction (`Triage`, `Issues`, `Cycles > Current/Upcoming`, `Projects`, `Views`).
  - Sidebar section ordering and per-entry functionality for each linked view.
  - Match icons/SVG vectors and spacing/details where possible.
- Data parity requirement:
  - Keep API ordering and dataset alignment close to Linear to avoid diff noise from mismatched data.
- Visual QA requirement:
  - Iterate until per-view visual diff is < 1%.
  - Do not game or hack the comparison script.
  - Keep comparisons as faithful captures.

