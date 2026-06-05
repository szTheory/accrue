---
phase: 177-d-motion-micro-interaction-design
plan: "01"
subsystem: accrue_admin/docs
tags: [motion, documentation, exdoc, guides]
dependency_graph:
  requires: []
  provides: [accrue_admin/guides/motion.md, exdoc-motion-registration]
  affects: [accrue_admin/mix.exs]
tech_stack:
  added: []
  patterns: [token-based motion catalog, ExDoc guide registration]
key_files:
  created:
    - accrue_admin/guides/motion.md
  modified:
    - accrue_admin/mix.exs
decisions:
  - "motion.md is the authoritative justification record — no motion.md entry means no animation permitted"
  - "All 9 surfaces catalogued with enter/exit asymmetry — --ax-ease-out enter, --ax-dur-exit + --ax-ease-in exit"
  - "Antipattern list A1–A8 grounded in Emil Kowalski 'Great Animations' as the normative 'do not'"
metrics:
  duration: 2m
  completed_date: "2026-06-04T18:51:29Z"
  tasks_completed: 2
  files_changed: 2
requirements:
  - MOT-01
---

# Phase 177 Plan 01: Motion & Micro-interaction Design Guide Summary

Token-based motion catalog for all 9 animated surfaces in accrue_admin, registered in ExDoc.

## What Was Built

**Task 1 — `accrue_admin/guides/motion.md`** (commit `2ee0a734`): Created the authoritative motion
spec for Phase 177. The guide contains:

- Motion Vocabulary section reproducing the locked Phase-174 token tables (duration atoms,
  easing atoms, travel/scale atoms, property bundles)
- The Motion Contract table — all 9 surfaces with trigger, animated property, enter token,
  exit token, reduced-motion fallback, and functional justification
- Enter/exit asymmetry note (gentle enter with `--ax-ease-out` and longer duration vs snappy
  exit with `--ax-ease-in` + `--ax-dur-exit`)
- Antipattern List A1–A8 citing Emil Kowalski "Great Animations" as the normative source
- Enforcement Guard section referencing the CI script and paired negative tests
- Reduced-motion section explaining the token-level override in `theme.css:187`

**Task 2 — `accrue_admin/mix.exs`** (commit `0a57dfa8`): Registered `guides/motion.md` in ExDoc
configuration at all three required locations: `extras:`, `groups_for_extras: Guides:`, and
`skip_undefined_reference_warnings_on:`.

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- `accrue_admin/guides/motion.md` exists: PASS
- `"guides/motion.md"` appears 3 times in `mix.exs` (extras, groups_for_extras, skip_undefined): PASS
- `mix test --seed 0`: 252 tests, 0 failures — no regression

## Known Stubs

None.

## Threat Flags

None. This plan creates a documentation file and modifies ExDoc configuration only — no HTTP
endpoints, authentication paths, file access patterns, or schema changes.

## Self-Check: PASSED

- `accrue_admin/guides/motion.md` exists: confirmed
- Commit `2ee0a734` exists: confirmed (Task 1)
- Commit `0a57dfa8` exists: confirmed (Task 2)
- All 9 surface rows present (detail_drawer, dropdown_menu, global_search, flash, skeleton,
  badge, tabs, collapsible nav, More overflow): confirmed
- Antipattern rows A1–A8 present: confirmed
- `"guides/motion.md"` needle in mix.exs (3 occurrences): confirmed
- Test suite 252 green: confirmed
