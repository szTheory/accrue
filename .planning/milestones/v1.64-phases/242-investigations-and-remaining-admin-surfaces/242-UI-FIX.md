---
phase: 242-investigations-and-remaining-admin-surfaces
closed_at: 2026-10-10T14:20:01Z
source_review: .planning/phases/242-investigations-and-remaining-admin-surfaces/242-UI-REVIEW.md
corrective_batches: 1
confirming_inspections: 0
status: fixed_with_automated_acceptance
human_judgment: false
---

# Phase 242 UI Review Corrections

## Applied corrections

1. `.ax-body` now uses `--ax-type-body-font` and `--ax-type-body-tracking`, the approved 16px/400/1.4 role. Relaxed leading remains available for prose-specific roles.
2. Home's three shortcut actions receive `min-block-size: 44px` for coarse pointers. The existing Phase 199 owner now measures each mounted shortcut's bounding-box height at 768 CSS px under coarse-pointer emulation.
3. Filtered Events empty state now routes its heading and body through the canonical `Copy.events_list_filtered_empty_title/0` and `Copy.events_list_filtered_empty_body/0` helpers. The list-contract fixture and host browser assertion use the exact approved `No ledger rows match these filters.` text.
4. Dark and System-dark table surface/link overrides now reference `--ax-elevated` and `--ax-primary`; the duplicate dark literal colors were removed from the targeted selectors.

**Source/test commit:** `157ef37d` (`fix(242): align Phase 242 presentation audit contracts`).  
**Generated package CSS commit:** `16bbcdfe` (`build(242): refresh Admin CSS after audit corrections`).

## Acceptance evidence

- Focused Admin ExUnit for global search and Events passed: 29 tests, 0 failures. Both changed Playwright files passed `node -c`.
- Package build passed with a task-scoped npm cache. The final Phase 191 owner passed 29 tests with 1 incumbent skip; Phase 199 passed 27 tests with 15 incumbent skips. The new Home geometry assertion ran as part of Phase 199's mobile coarse-pointer project.
- Host Phase 238/234 passed 2 tests. Its asset identity assertions compared package, host-compiled, served HTTP, and browser resource bytes.
- The combined warnings-as-errors compile and regression gate passed: Admin ExUnit 679/0, Node 44/44, host ExUnit 223/0. See `242-EXECUTION-GATES.md` for commands, hashes, and the initially failing then passing Phase 191 runs.

## Bounded visual and logo evidence

The phase's shared visual budget already contained one inspected screenshot. This corrective batch used one CSS/source correction batch and no new capture. A confirming inspection was attempted using the recorded screenshot path, but that file was unavailable; therefore confirming inspections used: 0. No capture scan or budget reset was performed.

The historic broken-logo observation is bounded to the disposable package E2E fixture by available source evidence: `accrue_admin/test/support/e2e_server.ex` configures `logo_url` as `https://example.test/logo.svg`, whereas `logo_url: nil` renders a self-contained inline SVG in `Sidebar`. The recorded capture was unavailable, so this diagnosis is not asserted as a fresh visual confirmation. No production logo code was changed.

Viewport, theme and pointer checks are browser emulation. Physical devices, native browser zoom, screen-reader speech, live-provider outcomes, remote CI and Linux goldens remain unobserved. Phase 243 retains final Linux golden and stable preview ownership. All acceptance claims here are machine-verified; no manual UAT checkpoint is introduced.
