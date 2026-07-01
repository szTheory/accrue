# Phase 199: Cross-cutting interaction/overlay correctness + fixture stress + microcopy - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-29
**Phase:** 199-cross-cutting interaction/overlay correctness + fixture stress + microcopy
**Areas discussed:** Overlay substrate, Geometry/motion/theme/affordances, Fixture stress, Microcopy sweep

---

## Overlay Substrate

| Option | Description | Selected |
|--------|-------------|----------|
| Extend the existing portal-backed Overlay stack | Reuse `Overlay.overlay/1`, `DetailDrawer`, `StepUpAuthModal`, `FocusTrap`, and `ScrollLock`; sweep every surface. | x |
| Rewrite around native `<dialog>` now | Could use top layer, but churns the shipped FocusTrap/Overlay stack without a failing portal test. | |
| Keep per-page hand-rolled overlays | Fast locally, but reintroduces modal-behind-scrim and scroll/focus drift. | |

**Choice:** Extend the existing portal-backed Overlay stack.
**Notes:** Code scout found `ScrollLock` already exists and is composed through `assets/js/hooks/overlay.js`; Phase 199 should prove it cross-page rather than invent a second path.

---

## Geometry, Motion, Theme, and Affordances

| Option | Description | Selected |
|--------|-------------|----------|
| Tighten existing tokens and hooks with rendered tests | Preserve <=240ms motion tokens, reduced-motion behavior, production theme key, and local dropdown/palette hooks; add viewport/focus/theme assertions. | x |
| Add a broad positioning/motion dependency | Potentially useful for edge popovers, but unnecessary unless local hooks cannot pass near-edge tests. | |
| Leave theme checks as helper-forced `data-theme` only | Useful for matrix visuals, but does not prove production no-FOUC/persistence. | |

**Choice:** Tighten existing tokens and hooks with rendered tests.
**Notes:** Production persistence uses `accrue_theme`; helper-forced theme attributes are not enough for no-FOUC coverage.

---

## Fixture Stress

| Option | Description | Selected |
|--------|-------------|----------|
| Seeded composed route stress | Extend `/__e2e__/seed/*` and Playwright flows for real list/detail/drill/back paths and edge data. | x |
| Component-only state specimens | Useful supplement, but misses page composition failures. | |
| Full Phase 200 scorecard now | Too broad for this phase; Phase 200 owns final all-cell re-score and sign-off. | |

**Choice:** Seeded composed route stress.
**Notes:** Representative flows should include customer, invoice, webhook, connect, recovery/campaign, and subscription/detail transitions.

---

## Microcopy Sweep

| Option | Description | Selected |
|--------|-------------|----------|
| Copy-module sweep with accessible context | Route touched page copy through `AccrueAdmin.Copy`, distinguish state copy, and give action/Change labels object context. | x |
| Inline strings during page fixes | Faster initially, but violates the current copy SSOT and makes verification harder. | |
| Broad brand rewrite | Out of scope; this is page-level admin microcopy, not a new brand phase. | |

**Choice:** Copy-module sweep with accessible context.
**Notes:** Use `brandbook/voice.md`: measured, exact, native, durable. Keep labels short and mechanism-led.

---

## Claude's Discretion

- Auto-selected all gray areas based on locked phase scope, recent contexts, and repo config favoring all-area/low-risk resolution.
- Exact test filenames, helper names, route-matrix depth, and final copy strings are planner discretion within the CONTEXT.md boundaries.

## Deferred Ideas

- Native `<dialog>` rewrite unless the portal audit fails.
- Floating UI dependency unless local positioning cannot satisfy near-edge tests.
- Full Storybook completeness/final zero-regression sign-off, which belongs to Phase 200.
- `accrue_portal` white-label billing portal design-system work.
