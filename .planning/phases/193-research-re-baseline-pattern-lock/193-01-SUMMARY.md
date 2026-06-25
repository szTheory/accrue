---
phase: "193"
plan: "01"
subsystem: accrue_admin
status: complete
tags:
  - guides
  - design-contracts
  - storybook
  - mix-exs
dependency_graph:
  requires:
    - "193-RESEARCH.md (source material)"
    - "193-CONTEXT.md (D-06 through D-15 decisions)"
    - "accrue_admin/guides/motion.md (structural precedent)"
  provides:
    - "accrue_admin/guides/spec-overview.md — SPEC-OVERVIEW design contract"
    - "accrue_admin/guides/spec-list.md — SPEC-LIST design contract"
    - "accrue_admin/guides/spec-detail.md — SPEC-DETAIL design contract"
    - "accrue_admin/mix.exs — phoenix_storybook dep + extended elixirc_paths + ExDoc wiring"
  affects:
    - "Plans 193-02 through 193-05 (all read these guides as design contracts)"
    - "Phases 194–200 (all build/conform against these three specs)"
    - "Plan 05 verify_package_docs.sh needles (anchored to the guide content authored here)"
tech_stack:
  added:
    - "{:phoenix_storybook, \"~> 1.2\", only: [:dev, :test]}"
  patterns:
    - "GOV.UK-style two-column machine invariant table (Invariant / How verified)"
    - "motion.md structural precedent: H1 intro → stable anchor heading → invariant table → prose judge section"
    - "ExDoc extras + groups_for_extras co-registration (both lists required, one missing = guides appear under Pages not Guides)"
key_files:
  created:
    - accrue_admin/guides/spec-overview.md
    - accrue_admin/guides/spec-list.md
    - accrue_admin/guides/spec-detail.md
  modified:
    - accrue_admin/mix.exs
decisions:
  - "Anchor headings match require_fixed needle patterns exactly: '## SPEC-OVERVIEW — ', '## SPEC-LIST — ', '## SPEC-DETAIL — summary-then-drill'"
  - "Added spec guides to skip_undefined_reference_warnings_on (guides reference .planning/ paths outside the package tarball, same as motion.md)"
  - "elixirc_paths(:dev) extended to ['lib', 'storybook/_support'] — required for storybook/_support/registry_story.ex to compile in dev"
metrics:
  duration: "~12 minutes"
  completed: "2026-06-25"
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 1
---

# Phase 193 Plan 01: Archetype Spec Guides + mix.exs Wiring Summary

Three locked archetype pattern specs authored as ExDoc guides and wired into mix.exs like the shipped motion.md precedent; phoenix_storybook dep added and elixirc_paths extended as prerequisites for Plan 04.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author three archetype spec guides | 4c6fe25e | accrue_admin/guides/spec-overview.md, spec-list.md, spec-detail.md |
| 2 | Wire spec guides into mix.exs (extras, groups, dep, elixirc_paths) | 55de6b53 | accrue_admin/mix.exs |

## What Was Built

### Three archetype spec guides

Each guide follows the `motion.md` structural pattern — intro prose, stable anchor heading, GOV.UK-style two-column machine-invariant table ("Invariant" / "How verified"), prose judge-graded section — and is wired into ExDoc as a published guide under the Guides: group.

**`spec-overview.md` — SPEC-OVERVIEW** (anchor: `## SPEC-OVERVIEW — exceptions-first, tasks-as-doors`)

Four machine invariants:
1. Exactly one `<h1>` per page (Playwright count assertion + axe-core landmark check)
2. ⌘K trigger present and focusable (Playwright locator + `assertFocusWithin`)
3. KPI cluster is a DOM sibling *after* attention-rail and task-launcher zones (Playwright DOM-order assertion on `[data-ax-zone]` node list)
4. Healthy/empty attention-rail renders a non-interactive hero — no `cursor:pointer` / `role="button"` (`assertTopPointerTarget` + source guard on `.ax-attention-rail--empty`)

Prose section: three judge-graded rubric criteria on exceptions-as-higher-signal, KPIs-demoted-not-deleted, and Recovery analytics zone grammar.

**`spec-list.md` — SPEC-LIST** (anchor: `## SPEC-LIST — table-first, four-state, chips-count-clear`)

Four machine invariants:
1. Renders 4 distinct states with distinct copy strings (populated, first-run-empty, filtered-empty, loading skeleton) — Playwright fixture-seeded state assertions
2. Filter chips + result count + clear-all all present when a filter is active — Playwright triple-presence assertion
3. Every truncating cell pairs `text-overflow: ellipsis` with `min-width: 0` in the same CSS block — new source guard (require_regex) in verify_package_docs.sh
4. No pagination controls rendered when pages ≤ 1 — Playwright absence assertion

Prose section: column priority (identity·state·money·time), deliberate-dense padding rhythm, work-queue default.

**`spec-detail.md` — SPEC-DETAIL** (anchor: `## SPEC-DETAIL — summary-then-drill`)

Four machine invariants:
1. ≤2 primary action buttons + one overflow menu (`[data-ax-primary-action]` count assertion)
2. Action forms NOT pre-expanded on load (`[data-ax-action-band] form:visible` count === 0 on initial goto)
3. Exactly one related-resources strip per page (`[data-ax-related-resources]` count === 1)
4. Overlay/drawer hit-testable above scrim with body scroll locked (`assertTopPointerTarget` + body-scroll assertion, covering Pitfall-1 and Pitfall-2 ACs from PITFALLS.md)

Prose section: summary-list answers "what state, what's wrong" at a glance; no card-in-card double border; tabs only for peer record-sets.

### mix.exs changes

- All three spec guide paths added to `docs/0` `extras` (after `"guides/motion.md"`)
- All three spec guide paths added to `Guides:` in `groups_for_extras` (after `"guides/motion.md"`)
- All three spec guide paths added to `skip_undefined_reference_warnings_on` (guides reference `.planning/milestones/...` paths outside the package tarball)
- `{:phoenix_storybook, "~> 1.2", only: [:dev, :test]}` added to deps (STY-01 prerequisite, Plan 04 unblocked)
- `elixirc_paths(:dev)` added as explicit clause: `["lib", "storybook/_support"]`
- `elixirc_paths(:test)` extended: `["lib", "storybook/_support", "test/support"]`

## Verification Results

All plan verification checks pass:

```
grep -c "## SPEC-OVERVIEW — " accrue_admin/guides/spec-overview.md  → 1  ✓
grep -c "## SPEC-LIST — " accrue_admin/guides/spec-list.md           → 1  ✓
grep -c "## SPEC-DETAIL — summary-then-drill" accrue_admin/guides/spec-detail.md → 1  ✓
grep -c '"guides/spec-overview.md"' accrue_admin/mix.exs             → 2  ✓
grep -c '"guides/spec-list.md"' accrue_admin/mix.exs                 → 2  ✓
grep -c '"guides/spec-detail.md"' accrue_admin/mix.exs               → 2  ✓
grep -c ':phoenix_storybook' accrue_admin/mix.exs                    → 1  ✓
grep -c 'storybook/_support' accrue_admin/mix.exs                    → 2  ✓
bash scripts/ci/verify_package_docs.sh                               → PASS  ✓
```

## Deviations from Plan

### Auto-additions

**1. [Rule 2 - Missing critical functionality] Added spec guides to skip_undefined_reference_warnings_on**
- **Found during:** Task 2
- **Issue:** The spec guides reference `.planning/milestones/.../187-RUBRIC.md` paths that are outside the package tarball. Without `skip_undefined_reference_warnings_on`, ExDoc would emit undefined reference warnings that would fail CI with `--warnings-as-errors`. The `motion.md` guide has the same pattern.
- **Fix:** Added all three spec guide paths to `skip_undefined_reference_warnings_on` alongside `motion.md`.
- **Files modified:** `accrue_admin/mix.exs`
- **Commit:** 55de6b53

No other deviations — plan executed as written.

## Known Stubs

None. The spec guides are design contracts; no runtime data flows through them.

## Threat Flags

None. Static markdown guide files authored by the executor; no untrusted input crosses the author→ExDoc boundary. The `phoenix_storybook` dep legitimacy was pre-verified in the RESEARCH.md threat audit (T-193-01-SC: hex.pm verified, 2+ year history, 1.2.0 released 2026-06-11).

## Self-Check: PASSED

Files exist:
- FOUND: accrue_admin/guides/spec-overview.md
- FOUND: accrue_admin/guides/spec-list.md
- FOUND: accrue_admin/guides/spec-detail.md

Commits exist:
- FOUND: 4c6fe25e (task 1 — three guide files)
- FOUND: 55de6b53 (task 2 — mix.exs wiring)
