---
phase: 207-orchestration-digest-one-command-round-fix-loop
plan: 08
subsystem: testing
tags: [ui-ratchet, guard-mint, ledger, playwright, mix-task, git]

# Dependency graph
requires:
  - phase: 207-03
    provides: ratchet-guard-mint.mjs and guard-home spec marker regions
  - phase: 207-06
    provides: ratchet-fix.mjs finalize path, ratchet-fix-probe.spec.js, and mix accrue_admin.ui.fix
provides:
  - "Per-kind required-field validation before concrete guard rows can be minted or appended"
  - "Incomplete concrete probe data degrades to guard_ref: ledger-count without guard-home spec mutation"
  - "mix accrue_admin.ui.fix commits only priv/static via a pathspec-scoped git commit"
affects: [208-convergence, ui-ratchet-fix-loop, admin-ui-ratchet-guardrails]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "closed required-fields-by-kind map for generated guard data"
    - "sentinel downgrade path for incomplete concrete guard mints"
    - "pathspec-scoped git commit argv for generated static bundles"

key-files:
  created: []
  modified:
    - accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs
    - accrue_admin/e2e/ratchet/ratchet-fix.mjs
    - accrue_admin/e2e/ratchet-fix-probe.spec.js
    - accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex
    - accrue_admin/test/mix/tasks/accrue_admin_ui_fix_test.exs

key-decisions:
  - "Incomplete concrete guard rows degrade to the existing ledger-count sentinel instead of throwing in finalizeFixes(), so resolved findings can still be promoted without corrupting guard-home specs."
  - "appendMintedRow() validates concrete rows itself before any file read/write to defend future direct callers that bypass mintGuardRow()."
  - "ui.fix keeps --allow-empty but now appends -- priv/static so unrelated pre-staged files cannot enter the bundle commit."

patterns-established:
  - "Guard row shape validation treats null, undefined, empty strings, and empty arrays as missing; numeric zero remains valid."
  - "Finalize self-tests verify both concrete guard minting and incomplete-probe sentinel promotion in one ledger fold."

requirements-completed: [ORCH-04, ORCH-05]

# Metrics
duration: 12 min
completed: 2026-07-07
status: complete
---

# Phase 207 Plan 08: Guard Mint Completeness and Scoped `ui.fix` Commit Summary

**Guard minting now refuses incomplete concrete rows before spec writes, incomplete probe data promotes via the ledger-count sentinel, and `ui.fix` commits only `priv/static`.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-07T12:09:00Z
- **Completed:** 2026-07-07T12:21:22Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added a closed required-field map for concrete guard kinds and validation helpers exported from `ratchet-guard-mint.mjs`.
- Changed `mintGuardRow()` to downgrade incomplete design-token, spacing-scale, microcopy, focus-ring, contrast, or motion rows to `guard_ref:"ledger-count"` instead of returning a malformed concrete row.
- Changed `appendMintedRow()` to validate row kind, target home, finding id, and kind-specific fields before reading or rewriting any guard-home spec.
- Extended `ratchet-fix.mjs --self-test` with the CR-02 finalize path: an incomplete microcopy probe promotes to `verified-closed` with `ledger-count` and leaves the copied guard-home spec byte-identical.
- Updated `mix accrue_admin.ui.fix` so the CSS-bundle commit runs as `git commit ... --allow-empty -- priv/static`, with FakeRunner assertions for the exact argv.

## Task Commits

Each task was committed atomically:

1. **Task 1: Require concrete guard row completeness before mint/write** - `457cf615` (fix)
2. **Task 2: Scope `ui.fix` git commit to `priv/static`** - `6e799de6` (fix)

## Files Created/Modified
- `accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs` - Required-field validation, sentinel downgrade, direct append guard, self-tests.
- `accrue_admin/e2e/ratchet/ratchet-fix.mjs` - Finalize self-test for incomplete probe data and sentinel promotion.
- `accrue_admin/e2e/ratchet-fix-probe.spec.js` - Comment contract clarifying probe observation versus mint validation responsibility.
- `accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex` - Pathspec-scoped bundle commit argv.
- `accrue_admin/test/mix/tasks/accrue_admin_ui_fix_test.exs` - FakeRunner assertions for the scoped commit command.

## Decisions Made
- Used `ledger-count` as the safe downgrade for incomplete concrete rows, matching the verifier's accepted fallback and avoiding guessed values from LLM prose.
- Kept scoped probe behavior intentionally narrow; it records route/selector/text observations, while mint validation owns whether a concrete guard is structurally safe.
- Scoped the commit at commit time, not just `git add`, because unrelated files may already be staged before `ui.fix` starts.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** CR-02 and WR-02 are closed without expanding evaluator fan-out or changing ledger lifecycle semantics.

## Issues Encountered
None.

## Verification
- `cd accrue_admin && node e2e/ratchet/ratchet-guard-mint.mjs --self-test && node e2e/ratchet/ratchet-fix.mjs --self-test` — passed.
- `cd accrue_admin && mix compile --warnings-as-errors && mix test test/mix/tasks/accrue_admin_ui_fix_test.exs` — passed, 6 tests.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
All Phase 207 gap-closure plans now have summaries. Phase-level verification can re-check that the digest path, guard minting, and `ui.fix` mutation command satisfy the original ORCH-01/02/04/05 requirements.

---
*Phase: 207-orchestration-digest-one-command-round-fix-loop*
*Completed: 2026-07-07*

## Self-Check: PASSED
- All five modified files exist on disk.
- Task commits `457cf615` and `6e799de6` found in git history.
- Node self-tests, Elixir compile, and focused ExUnit tests passed.
