# Phase 177: D — Motion & Micro-interaction Design - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Add restrained, purposeful, token-based motion to the now-stable admin layouts (174 tokens + 175 IA spine + 176 rubric uplift) — functional feedback, never decoration — governed by a documented motion/interaction spec and a researched antipattern list (Emil Kowalski principles), fully honoring `prefers-reduced-motion`. Apply motion to drawers, dropdowns (incl. the new More ▾ + collapsible nav), the command palette, tabs, flash/toasts, skeleton→content, and badge/state changes, all via the Phase 174 `--ax-transition-*` bundles. **No new screens/components, no IA changes, no per-screen rubric work, no seed work.** This phase is applied ONCE on stable layouts so motion isn't re-thrashed. Satisfies MOT-01, MOT-02, MOT-03.

</domain>

<decisions>
## Implementation Decisions

Three areas proposed as a synthesized package grounded in the locked design source (`v1.51-admin-ui-depth-design.md` §4 Phase D) + a codebase scout, accepted as-is by the user (calibration: `minimal_decisive`). Scout findings that shaped it: Phase 174 already shipped the `--ax-transition-colors/-transform/-shadow/-base` bundles (theme.css) AND a token-level reduced-motion override (app.css:2409, bundles→`--ax-dur-instant`); JS hooks exist (command_palette.js, sidebar_collapse.js, accrue_shell_nav.js, accrue_theme.js, clipboard.js); `Phoenix.LiveView.JS` is currently used only in step_up_auth_modal; motion-relevant components are detail_drawer, dropdown_menu, global_search, tabs, flash_group, data_table (skeleton); no motion doc exists yet.

### Motion spec doc & antipattern list (MOT-01)
- **Spec location:** a committed guide `accrue_admin/guides/motion.md` (authoritative catalog) + a live reference section in `/dev/components`.
- **Per-element documentation:** element · trigger · animated property + which token (`--ax-transition-*` / `--ax-dur-*` / `--ax-ease-*`) · enter/exit behavior · reduced-motion fallback · the **functional justification** (continuity / feedback / affordance — never decorative).
- **Antipattern list = Emil Kowalski principles** (https://emilkowal.ski/ui/great-animations): no `transition: all`; don't animate layout-thrashing properties; durations 150–300ms; ease-out for enter; no decorative spinners / infinite loops (except genuine loading); always honor reduced-motion.
- **Enforcement:** a grep/lint guard (extend the existing token-bypass guard pattern) banning `transition: all` and raw `ms`/`cubic-bezier()` literals in app.css (motion must compose from `--ax-dur-*`/`--ax-ease-*` atoms), wired into the test guard. ⚠️ Per the known coupling, a new guard needle must be added to BOTH the guard script AND its negative-test seed fixture.

### Per-component motion application (MOT-02)
- **Surfaces that animate:** detail_drawer (slide+fade in / fade out), dropdown_menu + the More ▾ overflow + the collapsible-nav reveal (height/opacity), global_search command palette (overlay fade + subtle scale-in), tabs (active-indicator slide or crossfade), flash/toasts (enter slide+fade, dismiss fade), skeleton→content (crossfade), badge/state changes (color/transform). ALL via the 174 `--ax-transition-*` bundles — never hardcoded ms/curves.
- **Mechanism:** prefer **CSS transitions** on `data-state`/`hidden` toggles (cheapest, declarative, matches how collapse/dropdown already work) + `Phoenix.LiveView.JS` show/hide with token durations for genuine mount/remove transitions where no hook exists (mirror `step_up_auth_modal`).
- **Enter/exit asymmetry** (Phase 174 D-16 deferred this to D): enter = `--ax-ease-out` (gentle), exit = `--ax-dur-exit` + ease-in (snappy dismiss) per Kowalski. Encode the exit variant now.
- **Badge/state changes** transition via `--ax-transition-colors` + a subtle transform on first-appear (includes the nav attention badges from Phase 175).

### Reduced-motion & verification (MOT-03)
- **Reduced-motion behavior:** honor the existing token-level override (bundles collapse to `--ax-dur-instant`): travel/overshoot/scale removed, opacity crossfades retained; no parallax/auto-animation. Route ALL new motion through the bundles so reduced-motion correctness is free.
- **Automated check:** extend the Phase 174 reduced-motion bundle-collapse test (D-15) to assert the newly-animated components collapse under `prefers-reduced-motion`; add a Playwright check emulating `prefers-reduced-motion: reduce` asserting no transform travel on a drawer/dropdown (structural).
- **Phase 179 handoff:** motion needs trace/video review (static PNGs can't see it) — Phase 179 runs a Playwright trace/video pass; THIS phase ships the automated reduced-motion check + the documented spec as its proof.
- **Restraint / anti-churn:** every animation cites a functional purpose (feedback / continuity / affordance); decorative motion is inadmissible; 150–300ms; nothing animates that wasn't flagged in the spec.

### Claude's Discretion
- Exact per-component durations within 150–300ms and the precise enter/exit easing pairing, provided they compose from existing `--ax-dur-*`/`--ax-ease-*` atoms (no literals).
- Whether tabs use an indicator-slide vs a crossfade — pick per what reads as functional, not decorative.
- The exact shape of the `motion.md` table and the `/dev/components` motion reference section.
- Whether to introduce an `--ax-dur-exit` consumption pattern or reuse the existing exit atom from 174.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- **174 transition bundles** — `--ax-transition-colors/-transform/-shadow/-base` (theme.css ~85) composed from `--ax-dur-*` + `--ax-ease-*` atoms; the reduced-motion override at app.css:2409 already collapses them to `--ax-dur-instant`. All new motion rides these.
- **JS hooks** — `command_palette.js`, `sidebar_collapse.js`, `accrue_shell_nav.js`, `accrue_theme.js`, `clipboard.js`. `Phoenix.LiveView.JS` used in `step_up_auth_modal.ex` (the show/hide-with-transition template to mirror).
- **Motion-relevant components** — `detail_drawer.ex`, `dropdown_menu.ex`, `global_search.ex`, `tabs.ex`, `flash_group.ex`, `data_table.ex` (skeleton/poll banner), plus the Phase 175 collapsible nav (`sidebar.ex` + sidebar_collapse.js) and Customer-360 More ▾ (`customer_live.ex`).

### Established Patterns
- Custom `ax-*` CSS + tokens (Tailwind inert, NO migration). Committed asset bundle — run `cd accrue_admin && mix accrue_admin.assets.build` + commit `priv/static` after CSS/JS edits.
- `verify_package_docs ↔ test` coupling: a new guard needle (e.g. the `transition: all` ban) must be added to BOTH the guard script AND its negative-test seed fixture.
- 252 tests currently green — do not regress.

### Integration Points
- `theme.css`/`app.css` transition bundles consumed by component classes; the reduced-motion `@media` block is the single override point.
- `/dev/components` (`component_kitchen_live.ex`) gets the motion reference section.
- `accrue_admin/e2e/` (Playwright) for the reduced-motion structural check; full motion trace review is Phase 179.

</code_context>

<specifics>
## Specific Ideas

- **Authoritative design source:** `.planning/research/v1.51-admin-ui-depth-design.md` — §4 Phase D scope (lines 105–108), §6 rubric dim ⑨ (motion: token-based, reduced-motion, functional not decorative), §7 guardrails. The Emil Kowalski reference: https://emilkowal.ski/ui/great-animations.
- **Anti-churn justification token** per change: motion is added only where it serves feedback/continuity/affordance; "looks nicer" is inadmissible. The motion.md entry IS the justification record.
- **Verification:** `cd accrue_admin && mix accrue_admin.assets.build`; `cd accrue_admin && mix test --seed 0`; the reduced-motion automated check; Playwright trace review deferred to Phase 179.

</specifics>

<deferred>
## Deferred Ideas

- **Motion trace/video QA sign-off** (the visual proof motion reads correctly + is restrained) → Phase 179 (F) Playwright trace pass.
- **Seed/state coverage** so every animated state (skeleton→content, toast, dead-letter badge appearance) is reachable for the trace pass → Phase 178 (E).
- Any net-new motion-only tokens beyond the 174 atoms — avoid; compose from existing atoms. Escalate only if a genuine gap appears.

*Discussion stayed within phase scope — no new screens/IA/seed work, applied once on stable layouts.*

</deferred>

---

*Phase: 177-d-motion-micro-interaction-design*
*Context gathered: 2026-06-04*
