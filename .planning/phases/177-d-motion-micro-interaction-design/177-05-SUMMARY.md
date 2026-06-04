---
phase: 177-d-motion-micro-interaction-design
plan: "05"
subsystem: ci-guard
tags: [motion, ci, testing, MOT-01, antipattern-guard, negative-tests]
dependency_graph:
  requires: [177-01, 177-04]
  provides: [motion-antipattern-ci-enforcement]
  affects: [scripts/ci/verify_package_docs.sh, accrue/test/accrue/docs/package_docs_verifier_test.exs]
tech_stack:
  added: []
  patterns: [verify_package_docs-guard-shape, seed_tmp_dir-negative-test-pattern]
key_files:
  modified:
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
decisions:
  - "Guard 3 (raw ms/s literals) uses two-pipe grep with -v allowlist for ax-skeleton-shimmer 1.4s — matches PATTERNS.md exactly"
  - "seed_tmp_dir!/1 adds mkdir_p for accrue_admin/guides before copying motion.md — guards against missing parent dir"
  - "Both changes shipped in separate commits (guard, then tests) per task structure; the critical coupling is within plan 177-05 as a unit"
metrics:
  duration: "2m"
  completed: "2026-06-04"
  tasks_completed: 2
  files_modified: 2
---

# Phase 177 Plan 05: Motion Antipattern Guard + Negative Tests Summary

CI antipattern enforcement for MOT-01: 4 motion guards + 1 guide needle in verify_package_docs.sh, paired with 4 negative tests and a seed update in package_docs_verifier_test.exs.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Add 4 motion antipattern guards + motion.md guide needle to verify_package_docs.sh | a84b0631 | scripts/ci/verify_package_docs.sh |
| 2 | Add 4 negative tests + copy motion.md in seed_tmp_dir! | bdbc2a7a | accrue/test/accrue/docs/package_docs_verifier_test.exs |

## What Was Built

**Task 1 — Guard script extensions:**

Five new blocks added to `scripts/ci/verify_package_docs.sh` immediately after the Phase 174 breakpoint guard (lines 322–328):

1. Ban `transition: all` (MOT-01/A1) — exact properties or `--ax-transition-*` bundles required
2. Ban raw `cubic-bezier(` literals (MOT-01/A3) — `--ax-ease-*` atoms required
3. Ban raw `ms`/`s` duration literals in transition/animation rules (MOT-01/A3) — `--ax-dur-*` tokens required; `ax-skeleton-shimmer` allowlisted
4. Ban layout-thrash properties (`height`, `width`, `margin`, `padding`, `top`, `left`, `right`, `bottom`) in transition lists (MOT-01/A2)
5. `require_fixed` needle for `"guides/motion.md"` in `accrue_admin/mix.exs`

All blocks annotated with `Phase 177, MOT-01`. Guard script exits 0 on clean codebase (Plans 01–04 CSS is fully token-safe; only existing raw literal is `ax-skeleton-shimmer 1.4s` which is allowlisted).

**Task 2 — Test pairings:**

- `seed_tmp_dir!/1` updated: added `File.mkdir_p!` for `accrue_admin/guides` and `copy_fixture!("accrue_admin/guides/motion.md", tmp_dir)` after the `app.css` fixture copy. This ensures all 10 seeded tests pass when the guard checks the `"guides/motion.md"` needle.
- 4 new negative test blocks added after the existing breakpoint test, each following the identical seed/inject/assert structure:
  1. Injects `.ax-drift { transition: all 180ms; }` — asserts `output =~ "transition: all"`
  2. Injects `.ax-drift { transition: opacity cubic-bezier(0.4,0,1,1); }` — asserts `output =~ "cubic-bezier"`
  3. Injects `.ax-drift { transition: opacity 200ms ease; }` — asserts `output =~ "ms"`
  4. Injects `.ax-drift { transition: height var(--ax-dur-2) ease; }` — asserts `output =~ "layout"`

## Verification Results

| Check | Result |
|-------|--------|
| `bash scripts/ci/verify_package_docs.sh` on clean codebase | exit 0 |
| `grep -c "MOT-01" scripts/ci/verify_package_docs.sh` | 6 |
| `grep -c "transition: all" package_docs_verifier_test.exs` | 3 |
| `mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0` | 14 tests, 0 failures |
| `cd accrue_admin && mix test --seed 0` | 252 tests, 0 failures |

## Deviations from Plan

None — plan executed exactly as written. Both changes committed individually per task structure. The guard shape, violation strings, and assertion strings all match PATTERNS.md and the plan's `<interfaces>` section verbatim.

## Known Stubs

None. Guard and tests are fully wired.

## Threat Flags

None. This plan modifies a CI guard script and ExUnit tests only — no new network endpoints, auth paths, or trust boundaries.

## Self-Check: PASSED

- `scripts/ci/verify_package_docs.sh` modified and verified: FOUND
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` modified and verified: FOUND
- Commit a84b0631: FOUND
- Commit bdbc2a7a: FOUND
- 14 verifier tests green, 252 admin tests green
