# Linear parity: measured ground truth

Every number in this document was read off the running Linear web app
(`linear.app`, authenticated, dark theme, captured 2026-08-27) using
`getBoundingClientRect()` and `getComputedStyle()` in the page — not estimated
from screenshots and not copied from Linear's marketing site. Where a value
looks oddly specific (`43.5px`, `-0.26px`, `lch(9.232% 0.85 272 / 1)`) that is
because it is the literal computed value, sub-pixel included.

The point of writing them down is that the parity scorecard can be checked
against a fixed reference instead of against someone's eye.

## How the values were captured

1. Authenticated session in the real browser (Linear keeps auth state in
   IndexedDB, so a cookie-only headless session does not work).
2. For each view, run in the page console:
   ```js
   const el = document.querySelector(selector)
   const r = el.getBoundingClientRect()
   const c = getComputedStyle(el)
   ```
   and dump the properties of interest.
3. For colours, read the raw `--variable` declarations off `document.documentElement`
   rather than the resolved RGB, so the LCH authoring values survive.

## Colour system

Linear authors its entire palette in **LCH on hue 272**, not in hex or in the
`282.863` hue this repo previously used. Chroma stays between 0 and 1.5 for
every surface — the tint is almost imperceptible individually but it is what
keeps the greys from looking flat.

### Dark theme

| Role | Value |
| --- | --- |
| App frame / sidebar | `lch(2.595% 0.4 272 / 1)` |
| Content pane | `lch(5.52% 0.4 272)` |
| Secondary surface | `lch(7.32% 0.85 272 / 1)` |
| Raised surface | `lch(8.22% 1.3 272 / 1)` |
| Row hover | `lch(8.5% 0.85 272 / 1)` |
| Row selected | `lch(11.2% 1.1 272 / 1)` |
| Border primary | `lch(9.84% 1.48 272 / 1)` |
| Border secondary | `lch(14.16% 1.48 272 / 1)` |
| Border tertiary | `lch(16.32% 1.48 272 / 1)` |
| Header border | `lch(13.08% 1.48 272 / 1)` |
| Group header bg | `lch(9.232% 0.85 272 / 1)` |
| Tab active bg | `lch(16.706% 0.979 272 / 1)` |
| Tab idle bg | `lch(10.149% 0.593 272 / 1)` |
| Text primary | `lch(100% 0 272 / 1)` |
| Text secondary | `lch(90.451% 1.2 272 / 1)` |
| Text tertiary | `lch(61.803% 1.2 272 / 1)` |
| Text quaternary | `lch(36.975% 1.2 272 / 1)` |
| Accent | `#5e6ad2` |
| Link | `lch(57.028% 70 288.421)` |

The sidebar and the app background are the **same colour**. The content pane is
lighter and floats above them — that separation is what reads as "Linear", and
it is lost if the sidebar is darkened separately (the previous
`rgb(9 9 9)` / `rgb(16 16 17)` pair inverted the relationship).

### Light theme

| Role | Value |
| --- | --- |
| App frame | `#f9f9fa` |
| Sidebar | `#efeff0` |
| Content pane | `#ffffff` |
| Secondary surface | `#f4f4f5` |
| Border secondary | `#e2e2e2` |
| Text primary | `#17171a` |
| Text tertiary | `#6b6f76` |

## Typography

Linear ships Inter Variable with **default OpenType features**. This repo was
setting `font-feature-settings: 'cv02', 'cv03', 'cv04', 'cv11'`, which swaps the
single-storey `a`, the `g`, the `l` and the `1` for alternates. Every glyph in
those four classes was therefore wrong shape before the feature list was reset
to `normal`.

| Token | Value |
| --- | --- |
| micro / mini / small / regular / large | 11 / 12 / 13 / 14 / 15 px |
| weight book / medium / semibold | 450 / 500 / 550 |

Issue identifiers (`PAY-8884`) are rendered in the **UI face, not a monospace
face**, with `font-variant-numeric: tabular-nums` and `letter-spacing: -0.26px`.
This matters more than it sounds: with tabular figures the string `PAY-8884`
measures 64.45px, without them 60.14px, and that ~4px is what keeps the title
column landing on the same x for every row.

## Geometry

| Element | Measurement |
| --- | --- |
| Sidebar width | `244px` |
| Primary header row | `44px` |
| Secondary header row | `43.5px` |
| Issue row | `44px`, padding-left `19px`, padding-right `26px` |
| Group header | `36px`, margin `0 8px 2px`, padding `0 8px 0 12px`, gap `8px` |
| Nav item | `28px`, margin `0 12px`, padding `0 8px`, gap `4px`, radius `8px`, margin-bottom `1px` |
| Content pane | margin `8px 8px 8px 0`, radius `12px`, border `0.5px`, shadow `0 0.5px 1px 1px lch(0 0 0 / 0.3)` |
| Board | gap `26px`, padding `15px 17px 0` |
| Board column | `322px` |
| Board card | padding `8px`, radius `8px`, background = group-header surface |
| Issue detail body | max-width `756px`, padding `62px 0 80px 68px` |
| Issue detail sidebar | `396px` fixed |
| Status chip | height `24px`, padding `0 8px`, radius `48px`, border `1px`, gap `6px`, icon `14px` |
| Badge row | gap `3px` |

### Column x-positions in the issue list

Measured on a row in the Active view, dark theme, 1512px viewport:

| Column | x |
| --- | --- |
| Priority glyph | `289.5` |
| Identifier | `310.5` |
| Status glyph | `382` |
| Title | `408.5` |

These fall out of the paddings and the tabular-figure identifier width above;
they are listed so the parity harness has an absolute check rather than only a
relative one.

## Status glyphs

Linear does not use a generic circle/clock/check icon set. Each workflow state
is one 14x14 SVG built the same way:

- an outer ring at `r=6`, `stroke-width: 1.5`
- an inner arc drawn as a **very fat dashed stroke used as a pie fill** —
  `r=2 stroke-width=4` when partial, `r=3 stroke-width=6` when solid — with the
  dash offset controlling the filled fraction
- for completed and cancelled states, a check or cross **punched out** of the
  solid disc in the surrounding background colour, not drawn on top of it

Fill fractions and colours by state name:

| State | Colour | Fill | Glyph |
| --- | --- | --- | --- |
| Triage | `lch(66% 80 48)` | 0 | triage arrows |
| Backlog / Icebox | `#bec2c8` | 0 (dashed ring `1.4 1.74`) | — |
| Todo / Next / This week | `#e2e2e2` | 0 | — |
| Spec | `lch(80% 90 85)` | 0.25 | — |
| In Progress / In Development | `lch(80% 90 85)` | 0.5 | — |
| In Review / Shipped / Maintenance | `#f2994a` | 0.75 | — |
| Staging | `#26b5ce` | 1 | check |
| Done / Completed / Production / Launched | `lch(60% 64.37 141.95)` | 1 | check |
| Canceled / Duplicate | `#95a2b3` | 1 | cross |

Backlog is the only state with a dashed ring. The 0.25 / 0.5 / 0.75 progression
is real — Linear conveys progress through the pie fill, so collapsing every
in-flight state to one "clock" icon loses the distinction the user reads first.

Implemented in `client/src/components/icons/LinearStatusIcon.vue`.

## Priority glyphs

| Priority | Rendering |
| --- | --- |
| 0 — No priority | three 1.5px dashes |
| 1 — Urgent | filled `#f2994a` rounded square with white bars |
| 2 — High | three bars, all full opacity |
| 3 — Medium | three bars, top bar dimmed |
| 4 — Low | three bars, top and middle dimmed |

Linear reserves the priority slot on every row even at priority 0, drawing the
dashes rather than collapsing the column — otherwise the identifier column
shifts between rows.

Implemented in `client/src/components/icons/LinearPriorityIcon.vue`.

## Known divergences

- **Fonts.** Linear self-hosts Inter Variable; this repo loads Inter from Google
  Fonts. The metrics match, the variable axis coverage does not exactly.
- **`sortOrder`.** Linear's manual issue ordering is not exposed through its
  public API, so any ordering here is reconstructed rather than authoritative.
- **Sidebar composition.** Deliberately different — this is a different product,
  not a pixel-for-pixel clone of the navigation.
