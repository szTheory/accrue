---
phase: 177-d-motion-micro-interaction-design
verified: 2026-06-04T19:18:24Z
status: human_needed
score: 9/9 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Run `npx playwright test e2e/reduced-motion.spec.js` from accrue_admin after starting a dev server (`mix phx.server`)"
    expected: "All 10 tests pass: the 2 pre-existing D-15 button tests + the 8 new Phase 177 tests (2 for dropdown, 2 for palette, 2 for drawer token, 1 structural no-travel test + the existing 1)"
    why_human: "Playwright tests require a live Phoenix server (`/__e2e__/login` helper + DOM inspection). Cannot run without starting the app. The spec file is structurally correct and all ExUnit CI gates pass — runtime execution is the remaining gate."
  - test: "Visually observe the 9 animated surfaces in a browser (drawer open/close, dropdown open, More ▾ toggle, nav group expand/collapse, palette Cmd-K open/close, tabs active change, toast push/dismiss, skeleton→content, badge state change)"
    expected: "Motion reads as functional and restrained — not janky or decorative. Enter is gentle (ease-out, longer), exit is snappy (ease-in, 140ms). No animation fires that was not in the motion contract."
    why_human: "Visual motion quality (does it look right, feel right, not janky?) cannot be verified by grep or computed-style assertions. This is Phase 179's explicit trace/video review responsibility; however, the first live-browser pass belongs here."
---

# Phase 177: D — Motion & Micro-interaction Design Verification Report

**Phase Goal:** Add restrained, purposeful, token-based motion to the now-stable admin layouts — functional feedback, never decoration — governed by a documented spec + a researched antipattern list (Emil Kowalski), fully honoring prefers-reduced-motion, verified by an automated check.
**Verified:** 2026-06-04T19:18:24Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A documented motion/interaction spec defines what animates, why, which token, and reduced-motion behavior, including an antipattern list grounded in Emil Kowalski principles | VERIFIED | `accrue_admin/guides/motion.md` exists (107 lines), contains 9-surface Motion Contract table, 8-row Antipattern List (A1–A8) citing Kowalski, Enforcement Guard section, Reduced-motion section |
| 2 | Drawers, dropdowns, command palette, tabs, flash/toasts, skeleton→content, badge/state changes animate via Phase-174 token bundles | VERIFIED | All 9 surfaces wired: drawer (phx-mounted/phx-remove JS.show/hide `ax-drawer-*`), flash (JS.show/hide `ax-flash-*`), dropdown (CSS `details[open]` + token opacity/transform), More ▾ (`.ax-tab-more-open` class toggle), nav reveal (JS `ax-collapsed` transitionend two-step), palette (`data-open` attr CSS), tabs (`.ax-transition-colors` on `.ax-tab`), skeleton (phx-mounted `ax-content-*`), badge (`.ax-transition-colors` on `.ax-badge`) |
| 3 | All motion uses `--ax-dur-*`/`--ax-ease-*` atoms — zero raw ms/cubic-bezier literals | VERIFIED | `grep -E "transition:.*[0-9]+(ms\|s)\b" app.css \| grep -v ax-skeleton-shimmer` returns 0 matches; no `cubic-bezier(` in app.css except inside the token variable declarations in theme.css |
| 4 | prefers-reduced-motion is honored — all new motion routes through bundles so the theme.css token override collapses it | VERIFIED | All CSS transitions use `var(--ax-dur-*)` / `var(--ax-ease-*)` atoms which the existing `@media (prefers-reduced-motion: reduce)` block in theme.css collapses; `--ax-rise-sm` / `--ax-rise-md` travel tokens set to `0px` under reduced-motion |
| 5 | Automated reduced-motion check exists for dropdown, palette, and drawer surfaces | VERIFIED | `e2e/reduced-motion.spec.js` extended to 267 lines with D-15-pattern describe blocks for `.ax-dropdown-panel` (≤1ms threshold), `.ax-command-palette` (≤1ms), `--ax-dur-3` drawer token check (`"0ms"`), and structural travel-token test asserting `--ax-rise-sm` and `--ax-rise-md` are `"0px"` under reduced-motion |
| 6 | CI antipattern guard bans transition:all, raw cubic-bezier, raw ms/s literals, and layout-thrash props | VERIFIED | `scripts/ci/verify_package_docs.sh` has 4 motion guards (MOT-01) + motion.md guide needle; `bash scripts/ci/verify_package_docs.sh` exits 0 from repo root |
| 7 | Guard paired with negative tests (verify_package_docs ↔ test coupling honored) | VERIFIED | `package_docs_verifier_test.exs` has 4 negative test blocks injecting `.ax-drift` violations; `seed_tmp_dir!/1` copies `accrue_admin/guides/motion.md`; 14 verifier tests, 0 failures |
| 8 | motion.md registered in accrue_admin/mix.exs ExDoc (extras, groups_for_extras, skip_undefined) | VERIFIED | `grep -c '"guides/motion.md"' accrue_admin/mix.exs` returns 3 |
| 9 | /dev/components has a Motion reference section listing all 9 animated surfaces | VERIFIED | `component_kitchen_live.ex` contains a Motion Reference section with an 11-row table (9 primary + 2 backdrops) referencing `motion.md` and annotated `MOT-01` |

**Score:** 9/9 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue_admin/guides/motion.md` | 9-surface catalog + antipattern list + guard + reduced-motion sections; min 80 lines | VERIFIED | 107 lines; all required sections present; all 9 surfaces + 8 antipatterns confirmed by grep |
| `accrue_admin/mix.exs` | `"guides/motion.md"` in extras, groups_for_extras, skip_undefined | VERIFIED | 3 occurrences confirmed |
| `accrue_admin/assets/css/app.css` | Dropdown, More ▾, tabs, badge, skeleton content, nav, drawer, flash, palette transition rules using tokens only | VERIFIED | All transition blocks present; 0 raw literal violations |
| `accrue_admin/assets/js/hooks/sidebar_collapse.js` | transitionend two-step setExpanded | VERIFIED | `ax-collapsed` + `transitionend` + `removeAttribute("hidden")` pattern confirmed |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | phx-mounted/phx-remove JS.show/hide with ax-drawer-* transition tuples | VERIFIED | Lines 28–37 confirm both drawer and backdrop transitions wired |
| `accrue_admin/lib/accrue_admin/components/flash_group.ex` | phx-mounted/phx-remove JS.show/hide with ax-flash-* tuples | VERIFIED | Lines 17–18 confirmed |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | ax-tab-more-open class toggle on wrapper | VERIFIED | Line 256: `class={["ax-tab-more-wrapper", @more_tabs_open && "ax-tab-more-open"]}` |
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | phx-mounted fade-in via ax-content-* | VERIFIED | Line 185 confirmed |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | data-open attr replacing class-swap hidden | VERIFIED | Line 112: `data-open={to_string(@is_open)}` |
| `accrue_admin/assets/js/hooks/command_palette.js` | dataset.open === "true" (2 occurrences) | VERIFIED | Lines 19 and 39 confirmed; no `classList.contains("hidden")` remaining |
| `accrue_admin/lib/accrue_admin/components/sidebar.ex` | ax-sidebar-group-links class on controlled div | VERIFIED | Line 74 confirmed |
| `scripts/ci/verify_package_docs.sh` | 4 motion guards + motion.md needle; exits 0 | VERIFIED | Guards at lines 328–346; `bash scripts/ci/verify_package_docs.sh` → exit 0 |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | 4 negative tests + motion.md in seed_tmp_dir! | VERIFIED | 4 negative test blocks; `copy_fixture!` at line 449; 14 tests, 0 failures |
| `accrue_admin/e2e/reduced-motion.spec.js` | D-15 pattern describe blocks for dropdown/palette/drawer + structural no-travel test | VERIFIED | 267-line file; 4 new blocks: dropdown, palette, drawer token check, structural ax-rise-sm/md |
| `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | Motion reference section with all 9 surfaces | VERIFIED | Section at line 269; 11-row table confirmed |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `accrue_admin/mix.exs` | `accrue_admin/guides/motion.md` | `extras:` list | WIRED | 3 occurrences confirmed |
| `accrue_admin/assets/css/app.css` | `accrue_admin/assets/css/theme.css` | `var(--ax-dur-*)` / `var(--ax-ease-*)` / `var(--ax-rise-*)` atoms | WIRED | 0 raw literals; all transitions use token vars |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | `accrue_admin/assets/css/app.css` | `JS.show(transition: {"ax-drawer-entering",...})` | WIRED | CSS class tuples defined; phx-mounted calls confirmed |
| `accrue_admin/lib/accrue_admin/components/flash_group.ex` | `accrue_admin/assets/css/app.css` | `JS.show/hide` with `ax-flash-*` tuples | WIRED | Confirmed |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | `accrue_admin/assets/css/app.css` | `data-open` attr → `[data-open="true"]` CSS rule | WIRED | Confirmed |
| `accrue_admin/assets/js/hooks/command_palette.js` | `accrue_admin/lib/accrue_admin/components/global_search.ex` | `dataset.open === "true"` | WIRED | 2 occurrences confirmed |
| `accrue_admin/assets/js/hooks/sidebar_collapse.js` | `accrue_admin/assets/css/app.css` | `ax-collapsed` CSS class toggled by JS | WIRED | transitionend two-step confirmed |
| `scripts/ci/verify_package_docs.sh` | `accrue_admin/assets/css/app.css` | grep antipattern guards | WIRED | 4 guards + guide needle; exits 0 on clean codebase |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `scripts/ci/verify_package_docs.sh` | `System.cmd bash @script_path` with injected violations | WIRED | 4 negative tests; 14 tests, 0 failures |
| `accrue_admin/e2e/reduced-motion.spec.js` | `accrue_admin/assets/css/app.css` | `getComputedStyle` computed transition-duration checks | WIRED | Spec reads `--ax-dur-*` token values and `--ax-rise-*` travel tokens from documentElement |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase delivers CSS/JS animations, a guide document, and CI enforcement. No dynamic data rendering; no fetch/DB query data paths to trace. All artifacts are presentational or documentation.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No raw transition literals in app.css | `grep -E "transition:.*[0-9]+(ms\|s)\b" app.css \| grep -v ax-skeleton-shimmer` | 0 matches | PASS |
| motion.md registered 3× in mix.exs | `grep -c '"guides/motion.md"' accrue_admin/mix.exs` | 3 | PASS |
| Guard script exits 0 on clean codebase | `bash scripts/ci/verify_package_docs.sh` from repo root | exit 0 | PASS |
| 14 verifier tests green | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0` | 14 tests, 0 failures | PASS |
| 252 accrue_admin tests green | `cd accrue_admin && mix test --seed 0` | 252 tests, 0 failures | PASS |
| dataset.open usage in command_palette.js | `grep "classList.contains.*hidden" command_palette.js` | 0 matches | PASS |
| data-open attr in global_search.ex | `grep "data-open" global_search.ex` | match on line 112 | PASS |
| ax-collapsed transitionend two-step in sidebar_collapse.js | `grep "ax-collapsed\|transitionend" sidebar_collapse.js` | 5 matches | PASS |

---

### Probe Execution

No conventional probe scripts discovered for this phase (`scripts/ci/verify_package_docs.sh` is the CI guard, run above as a behavioral spot-check).

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| MOT-01 | 177-01, 177-05, 177-06 | Documented motion/interaction spec + antipattern list grounded in researched best practice | SATISFIED | `guides/motion.md` exists with 9-surface table + A1–A8 antipatterns + Emil Kowalski citation; CI guard + negative tests; /dev/components motion reference |
| MOT-02 | 177-02, 177-03, 177-04 | 9 surfaces animate via Phase-174 design-token transition bundles — functional, not decorative | SATISFIED | All 9 surfaces wired via CSS token bundles / JS.transition tuples / data-open CSS; 0 raw literals; enter/exit asymmetry encoded |
| MOT-03 | 177-02, 177-04, 177-06 | All motion honors prefers-reduced-motion; verified by automated check | SATISFIED (automated structural) / NEEDS RUNTIME | Motion routes through `--ax-dur-*`/`--ax-ease-*` tokens; theme.css reduced-motion block collapses bundles; `--ax-rise-*` travel tokens set 0px; Playwright spec structurally correct and extended — runtime execution needs live server |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| No debt-marker (TBD/FIXME/XXX) anti-patterns found in phase-modified files | — | — | — | — |

No `transition: all`, raw `cubic-bezier(`, raw `ms`/`s` literals, or layout-thrash props detected in `app.css`. Guard exits clean.

---

### Human Verification Required

#### 1. Playwright Reduced-Motion Spec Runtime

**Test:** Start the dev server (`cd accrue_admin && mix phx.server`) then run `npx playwright test e2e/reduced-motion.spec.js` from the `accrue_admin` directory.
**Expected:** All 10 tests pass. The 4 Phase-177 blocks verify: dropdown panel transition collapses to ≤1ms under reduced-motion (and is >1ms without), command palette collapses to ≤1ms (and is >1ms without), `--ax-dur-3` reads `"0ms"` under reduced-motion (and `"240ms"` without), and `--ax-rise-sm` / `--ax-rise-md` are `"0px"` under reduced-motion.
**Why human:** Playwright requires a running Phoenix server (`/__e2e__/login` endpoint + full DOM). Cannot be executed in the static CI grep/compilation context. The spec is structurally correct (267 lines, confirmed by grep), but only runtime execution proves the computed CSS values match expectations.

#### 2. Live Motion Quality Pass

**Test:** Open the admin UI in a browser on a desktop browser without reduced-motion preference enabled. Exercise each of the 9 animated surfaces: open/close a detail drawer, open a dropdown menu, open the More ▾ tab overflow, expand/collapse a sidebar nav group, open the command palette with Cmd-K and dismiss with Esc, switch between tabs, trigger and dismiss a flash toast, observe a data table loading (skeleton→content), and observe a badge state change.
**Expected:** All 9 animations read as functional and restrained. Enter transitions feel gentle (ease-out, 180–240ms). Exit transitions feel snappy (140ms). The command palette scale-in is subtle (0.98→1 with `--ax-ease-emphasis`). No animation feels decorative or redundant. No jank. Nothing animates that is not in the motion contract.
**Why human:** Visual motion quality — "does it look right and feel restrained?" — cannot be verified by computed CSS assertions. Static PNGs cannot capture animation. This is Phase 179's explicit trace/video review scope, but a first live-browser pass is warranted at this phase boundary.

---

### Gaps Summary

No gaps found. All 9 truths are VERIFIED against the codebase. The `human_needed` status reflects the two items above that require a live browser to confirm — both are expected at this phase boundary per the VALIDATION.md contract (Phase 177 gates = ExUnit suite + guard + spec structural correctness; runtime Playwright execution and visual motion review are Phase 179's job).

---

_Verified: 2026-06-04T19:18:24Z_
_Verifier: Claude (gsd-verifier)_
