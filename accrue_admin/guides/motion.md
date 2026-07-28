# Motion & Micro-interaction Design

Accrue Admin applies restrained, purposeful, token-based motion to interactive surfaces. Every
animation serves a functional role (feedback, continuity, or affordance) and honors
`prefers-reduced-motion`. Decorative motion is inadmissible.

## Motion Vocabulary

All new motion composes from these atoms only. Raw `ms`, `s`, or `cubic-bezier()` literals in
`app.css` are banned (see Enforcement Guard below).

### Duration atoms

| Token | Value | Intended use |
|-------|-------|--------------|
| `--ax-dur-instant` | `0ms` | reduced-motion collapse target |
| `--ax-dur-1` | `120ms` | press, hover, micro feedback |
| `--ax-dur-2` | `180ms` | default state change / enter |
| `--ax-dur-3` | `240ms` | drawer / modal enter (largest travel) |
| `--ax-dur-exit` | `140ms` | exit (snappier than enter — asymmetry) |

### Easing atoms

| Token | Curve | Intended use |
|-------|-------|--------------|
| `--ax-ease-out` | `cubic-bezier(0.2,0,0,1)` | enter / default (decelerate in) |
| `--ax-ease-in` | `cubic-bezier(0.4,0,1,1)` | exit (accelerate away) |
| `--ax-ease-inout` | `cubic-bezier(0.4,0,0.2,1)` | continuous loops (skeleton shimmer only) |
| `--ax-ease-emphasis` | `cubic-bezier(0.2,0.9,0.3,1.2)` | the single earned overshoot (scale-in) |

### Travel and scale atoms

| Token | Value | Use |
|-------|-------|-----|
| `--ax-rise-sm` | `4px` | small enter translate (dropdowns, toasts) — `0px` under reduced-motion |
| `--ax-rise-md` | `8px` | larger enter translate (drawer, palette) — `0px` under reduced-motion |
| `--ax-press-scale` | `0.97` | active-press feedback — `1` under reduced-motion |

### Property bundles (the primary mechanism — route everything through these)

| Bundle | Composition | Animates |
|--------|-------------|----------|
| `--ax-transition-colors` | `--ax-dur-2 / --ax-ease-out` on `color`, `background-color`, `border-color` | color/state changes |
| `--ax-transition-transform` | `--ax-dur-2 / --ax-ease-out` on `transform` | slide/scale |
| `--ax-transition-shadow` | `--ax-dur-2 / --ax-ease-out` on `box-shadow` | elevation |
| `--ax-transition-base` | all of the above (5-property) | general controls |

Why bundles are non-negotiable: the reduced-motion `@media` block in `theme.css` overrides each
bundle to `--ax-dur-instant` (0ms). Any motion routed through a bundle honors
`prefers-reduced-motion` for free (MOT-03). Motion written with inline durations bypasses that
override and is a contract violation.

## The Motion Contract

Every animated surface is catalogued below. The functional justification column is the
justification record — no entry means no animation is permitted.

| # | Surface (file) | Trigger | Animated property | Enter token | Exit token | Reduced-motion fallback | Justification |
|---|----------------|---------|-------------------|-------------|------------|-------------------------|---------------|
| 1 | **detail_drawer** (`detail_drawer.ex`, `.ax-detail-drawer`) | open/close (`@open` toggle / mount-remove) | `transform` (translateX `--ax-rise-md`→0) + `opacity` 0→1 | `transform --ax-dur-3 --ax-ease-out, opacity --ax-dur-3 --ax-ease-out` | `opacity --ax-dur-exit --ax-ease-in` (fade only — no travel out) | travel→0 (`--ax-rise-md`=0px), opacity crossfade retained, dur→instant via bundle | **Continuity** — the drawer slides from the edge it is anchored to, so the operator keeps spatial context with the list behind it. |
| 1b | **detail_drawer-backdrop** (`.ax-detail-drawer-backdrop`) | same as drawer | `opacity` 0→1 | `opacity --ax-dur-3 --ax-ease-out` | `opacity --ax-dur-exit --ax-ease-in` | opacity retained, dur→instant | **Affordance** — dimming signals a modal layer; click-to-dismiss target. |
| 2 | **dropdown_menu** (`dropdown_menu.ex`, `.ax-dropdown-panel`) | `<details>` open (`[open]`) | `opacity` 0→1 + `transform` (translateY `--ax-rise-sm`→0) | `--ax-transition-transform` + opacity `--ax-dur-2 --ax-ease-out` | `opacity --ax-dur-exit --ax-ease-in` | translate→0, opacity retained, dur→instant via bundle | **Affordance** — the small rise reads as "this panel belongs to the trigger above it." |
| 3 | **More overflow** (`.ax-tab-more-menu`, demonstrated in `dev/component_kitchen_live.ex`) | toggle open | identical to dropdown_menu | same as dropdown_menu | same as dropdown_menu | same as dropdown_menu | **Affordance** — a recessed-tab overflow menu reveals with the same grammar as any dropdown (consistency). |
| 5 | **global_search palette** (`global_search.ex`, `.ax-command-palette`) | Cmd-K open / Esc/backdrop close (`is_open`) | panel `opacity` 0→1 + `transform` scale `0.98`→1; backdrop `opacity` | `transform --ax-dur-2 --ax-ease-emphasis, opacity --ax-dur-2 --ax-ease-out` | `opacity --ax-dur-exit --ax-ease-in` (no scale-out) | scale→none (overshoot removed by override), opacity retained, dur→instant | **Feedback** — the subtle scale-in is the one earned `--ax-ease-emphasis` use; it announces the palette took focus. Scale is composited (perf-safe). |
| 5b | **palette backdrop** (`.ax-command-palette-backdrop`) | same | `opacity` 0→1 | `opacity --ax-dur-2 --ax-ease-out` | `opacity --ax-dur-exit --ax-ease-in` | opacity retained, dur→instant | **Affordance** — modal dimming. |
| 6 | **tabs active indicator** (`tabs.ex`, `.ax-tab` / `.ax-tab-active`) | active tab change (link nav) | `color` + `border-color` (underline indicator) via colors bundle | `--ax-transition-colors` | symmetric (colors bundle) | color change retained (no travel), dur→instant via bundle | **Feedback** — confirms selection. Crossfade the indicator color; do not slide it. Tabs are link-based (full page nav between LiveViews) so a slide has no continuous element to animate — a color crossfade is the honest, functional choice. |
| 7 | **flash / toasts** (`flash_group.ex`, `.ax-flash`) | mount (server push) / dismiss | `opacity` 0→1 + `transform` (translateY `--ax-rise-sm`→0) | `transform --ax-dur-2 --ax-ease-out, opacity --ax-dur-2 --ax-ease-out` | `opacity --ax-dur-exit --ax-ease-in` | travel→0, opacity retained, dur→instant | **Feedback** — a new notice slides in so it is noticed; snappy fade-out so dismissal feels immediate. |
| 8 | **skeleton to content** (`data_table.ex`, `.ax-skeleton`) | data arrives (skeleton removed, rows mount) | content `opacity` 0→1 (crossfade in); skeleton shimmer already exists | `opacity --ax-dur-2 --ax-ease-out` on mounted content | n/a (skeleton removed by LiveView patch) | shimmer already `animation:none` + static (`app.css:7906`); content crossfade — opacity retained, dur→instant | **Continuity** — content fades in where the skeleton was, so the table does not pop. Shimmer is the only sanctioned infinite loop (genuine loading; antipattern A4 exception). |
| 9 | **badge / state change** (`.ax-status-badge`, `.ax-badge`, nav attention badges from Phase 175) | status change / first-appear | `color` + `background` + `border` via colors bundle; first-appear adds `transform` scale `--ax-press-scale`→1 | `--ax-transition-colors`; first-appear: `--ax-transition-transform` (`--ax-ease-emphasis` optional, single pop) | symmetric (colors bundle) | scale→none (`--ax-press-scale`=1), color change retained, dur→instant | **Feedback** — a status that just changed (e.g. invoice to paid, dead-letter count appears) draws a glance without a layout shift. |

**Enter/exit asymmetry (Phase-174 D-16, now encoded):**

- Enter = gentle: `--ax-ease-out`, longer duration (`--ax-dur-2` / `--ax-dur-3`), may include travel/scale.
- Exit = snappy: `--ax-ease-in` + `--ax-dur-exit` (140ms), fade-only — no travel/scale out. Dismissal should feel immediate; an element leaving does not need to narrate where it goes.

## Antipattern List

Source: **Emil Kowalski, "Great Animations"** — <https://emilkowal.ski/ui/great-animations>
(fetched 2026-06-04). This list is the normative "do not" and the basis of the enforcement guard.

| ID | Antipattern | Rule for `accrue_admin` |
|----|-------------|-------------------------|
| A1 | `transition: all` | **Banned.** Name the exact properties (or use an `--ax-transition-*` bundle). Animating "all" animates layout props by accident and kills perf. |
| A2 | Animating layout-triggering properties (`height:auto`, `width`, `margin`, `padding`, `top`/`left`) | **Banned for motion.** Animate only `transform` and `opacity` (composited, 60fps). Reveal/collapse uses `opacity` + the structural `hidden`/`[open]` toggle, never animated `height`. |
| A3 | Raw duration / curve literals (`200ms`, `0.3s`, `cubic-bezier(...)`) in `app.css` | **Banned.** Compose from `--ax-dur-*` / `--ax-ease-*` atoms only. Genuine token gaps get flagged, not literal-ized. |
| A4 | Decorative / infinite animation (spinners, auto-loops, parallax) | **Banned** except genuine loading. The skeleton shimmer (`ax-skeleton-shimmer`) and `.ax-spinner` (active fetch only) are the sole sanctioned loops. |
| A5 | Durations outside 150–300ms | **Banned.** Enter must use `--ax-dur-2` (180ms) or `--ax-dur-3` (240ms); exit uses `--ax-dur-exit` (140ms — the only allowed sub-150 exception, intentional for snappy dismissal). Micro press/hover `--ax-dur-1` (120ms) is feedback, not entrance. |
| A6 | Ignoring `prefers-reduced-motion` | **Banned.** All motion routes through the bundles so the `theme.css:358` override collapses it. No motion may be authored that bypasses the bundle override. |
| A7 | Animating frequently-repeated / keyboard-initiated actions | **Banned.** Cmd-K to palette uses one subtle scale-in, not a heavy entrance; nav between tabs is a color crossfade, not a slide. Power-user paths stay fast. |
| A8 | Decorative motion ("looks nicer") | **Inadmissible.** Every animation in the table above cites continuity / feedback / affordance. The `motion.md` entry is the justification record; no entry means no animation. |

## Enforcement Guard

The CI script `scripts/ci/verify_package_docs.sh` contains motion antipattern guards
(Phase 177, MOT-01) that ban `transition: all`, raw `cubic-bezier()` literals, raw `ms`/`s`
duration literals in transition/animation rules (except `ax-skeleton-shimmer 1.4s`), and
layout-thrashing properties in transition lists. These guards are paired with negative tests
in `package_docs_verifier_test.exs`. Any new CSS rule violating these patterns will fail CI.

## Reduced-motion

All transitions route through `--ax-transition-*` bundles or individual `--ax-dur-*`/`--ax-ease-*`
atoms. The `@media (prefers-reduced-motion: reduce)` block in `theme.css` collapses these bundles
to `--ax-dur-instant` (0ms), removing travel and overshoot while retaining opacity crossfades.
No JS code should check `matchMedia` — the token override handles it. The reduced-motion behavior
is verified by an automated Playwright check in `e2e/reduced-motion.spec.js`.
