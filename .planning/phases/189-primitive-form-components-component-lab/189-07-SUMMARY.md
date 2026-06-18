---
phase: 189-primitive-form-components-component-lab
plan: "07"
subsystem: accrue / accrue_admin / scripts/ci
tags: [ci-guard, verifier, negative-fixture, cmp-05, phase-closeout]
dependency_graph:
  requires: [189-06]
  provides: [CMP-05 enforcement guard, phase 189 validation close-out]
  affects: [scripts/ci/verify_package_docs.sh, accrue/test/accrue/docs/package_docs_verifier_test.exs, .planning/phases/189-primitive-form-components-component-lab/189-VALIDATION.md]
tech_stack:
  added: []
  patterns: [shell verifier guard block (bash/perl/find), ExUnit negative-fixture test with seed_tmp_dir!]
key_files:
  created: []
  modified:
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - .planning/phases/189-primitive-form-components-component-lab/189-VALIDATION.md
decisions:
  - CMP-05 inline-style guard targets elements with BOTH an ax-primitive class AND style= in the same tag; ax-inline-id (used in inline_id.ex with style=max-width) is NOT in the guarded class list and will not be flagged
  - Phase 189 VALIDATION.md closed with nyquist_compliant: true and wave_0_complete: true on 2026-06-17
metrics:
  duration: "~20m total (3m 49s initial + post-checkpoint remediation)"
  completed_date: "2026-06-17"
  tasks_completed: 3
  files_modified: 3
---

# Phase 189 Plan 07: CMP-05 Verifier Guard + Phase Closeout Summary

CMP-05 enforcement guard added to the CI verifier with per-page CSS override detection and inline `style=` detection on primitive component wrappers, backed by two negative-fixture ExUnit tests; FND-05 fixture hardened to handle the 4-scope token count from Phase 189-01; Phase 189 VALIDATION.md closed out.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add CMP-05 guard blocks to verify_package_docs.sh | 156861c1 | scripts/ci/verify_package_docs.sh |
| 2 | Add negative-fixture tests for CMP-05; close out 189-VALIDATION.md | be882311 | accrue/test/accrue/docs/package_docs_verifier_test.exs, .planning/phases/189-primitive-form-components-component-lab/189-VALIDATION.md |
| 3 | Make FND-05 negative fixture robust to theme.css 4th-scope token (189-01) | 662dcf52 | accrue/test/accrue/docs/package_docs_verifier_test.exs |

## What Was Built

### Task 1: CMP-05 Guard Blocks in verify_package_docs.sh

Two new guard blocks added immediately before the final `echo "package docs verified..."` line:

**Guard 1 — Per-page CSS override detection:**
- Scans `accrue_admin/assets/css/*.css` excluding `app.css` and `theme.css`
- Flags any file containing selectors matching `.ax-(button|field|input|select|status-badge|icon|money|json|empty)[^{]*{`
- Uses `find ... -print0 | xargs -0 grep` pattern for space-safe filename handling
- Exits with `CMP-05` in the error message

**Guard 2 — Inline style= on primitives:**
- Scans `accrue_admin/lib/**/*.ex` and `*.heex` files
- Uses a Perl one-liner to parse `~H"""` heredoc blocks and find elements with both an ax-primitive class AND `style=` in the same tag
- Guarded class list: `ax-button|ax-field|ax-input|ax-select|ax-status-badge|ax-money|ax-json`
- `ax-inline-id` is NOT in the list (its `style={"max-width: ..."}` is a structural computed-prop constraint, not a design override)

**Verification:** `bash scripts/ci/verify_package_docs.sh` exits 0 on the clean codebase.

### Task 2: Negative-Fixture Tests + VALIDATION.md Closeout

**Test 1 — Per-page CSS override negative fixture:**
- Seeds tmp_dir, then writes `accrue_admin/assets/css/page-overrides.css` with `.ax-button { font-size: 1rem; }`
- Asserts verifier exits non-zero with `[verify_package_docs]` and `CMP-05` in output

**Test 2 — Inline style= on primitive negative fixture:**
- Seeds tmp_dir, replaces `<Button.button variant="primary" type="button">Primary action</Button.button>` in `component_kitchen_live.ex` with `<button class="ax-button ax-button-primary" style="color: red;" type="button">Primary action</button>`
- The element is inside a `~H"""` heredoc block (required for the Perl guard to find it)
- Asserts verifier exits non-zero with `[verify_package_docs]` and `CMP-05` in output

**VALIDATION.md closeout:**
- `nyquist_compliant: true` set in frontmatter
- `wave_0_complete: true` set in frontmatter
- `status: approved` set
- `approval_date: 2026-06-17` added
- All Wave 0 checklist items marked `[x]` with plan references
- All Validation Sign-Off checklist items marked `[x]`
- Phase 189 complete note added summarizing Plans 01–07 evidence

## Verification Results

Final verification after Task 3 remediation:

```
bash scripts/ci/verify_package_docs.sh  →  exits 0 (clean codebase)
cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs  →  25 tests, 0 failures
grep -c "CMP-05" scripts/ci/verify_package_docs.sh  →  4
grep -c "primitive_override_hit" scripts/ci/verify_package_docs.sh  →  2
grep -c "inline_style_hit" scripts/ci/verify_package_docs.sh  →  2
grep -c "CMP-05" accrue/test/accrue/docs/package_docs_verifier_test.exs  →  4
```

## Deviations from Plan

### Post-Checkpoint Remediation (maintainer-required)

**1. [Rule 1 - Bug] FND-05 negative fixture broken by 4th theme.css scope added in Phase 189-01**
- **Found during:** Maintainer sign-off at human-verify checkpoint
- **Issue:** `String.replace(..., global: false)` removed only the first of 4 occurrences of `--ax-focus-ring-offset: var(--ax-base);` in the seeded theme.css, leaving 3 — exactly meeting the verifier's "≥3 scopes" threshold so the "semantic role tokens" check silently passed. Execution fell through to `verify_foundation_contrast.mjs` which crashed with a TypeError instead of emitting the expected message, making the test's assertion `output =~ "semantic role tokens"` fail (or pass for the wrong reason).
- **Fix:** Removed `global: false` option; `String.replace(File.read!(theme_path), "--ax-focus-ring-offset: var(--ax-base);", "")` now removes all 4 occurrences, dropping the count to 0 so the check fires correctly.
- **Files modified:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`
- **Verification:** 25 tests, 0 failures; `bash scripts/ci/verify_package_docs.sh` exits 0
- **Committed in:** `662dcf52`

---

**Total deviations:** 1 post-checkpoint remediation (Rule 1 — existing negative fixture broken by 4th token scope added in Phase 189-01)
**Impact on plan:** Intent-preserving fix. No scope creep. Guard was always correct; only the test fixture needed hardening.

## Known Stubs

None.

## Threat Flags

None — this plan only adds CI shell guard blocks and ExUnit negative-fixture tests. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- `scripts/ci/verify_package_docs.sh` — FOUND (156861c1)
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — FOUND (be882311, 662dcf52)
- `.planning/phases/189-primitive-form-components-component-lab/189-VALIDATION.md` — FOUND (be882311)
- Commits 156861c1, be882311, and 662dcf52 verified in git log
- `mix test test/accrue/docs/package_docs_verifier_test.exs` — 25 tests, 0 failures (post-remediation)
- `bash scripts/ci/verify_package_docs.sh` — exit 0
