---
phase: 207-orchestration-digest-one-command-round-fix-loop
plan: 06
subsystem: testing
tags: [ui-ratchet, ledger, guard-mint, mix-task, playwright, node, elixir]

# Dependency graph
requires:
  - phase: 207-03
    provides: ratchet-guard-mint.mjs (mintGuardRow/appendMintedRow) + guard-home spec bootstrap
  - phase: 207-04
    provides: digest decisions.json checkpoint contract (D-42) consumed by --apply-decisions
  - phase: 207-05
    provides: ui.round.ex Runner/ShellRunner idiom + .fix-context marker-file handoff pattern
  - phase: 206
    provides: ratchet-ledger.js lifecycle helpers (appendResolved/appendSuppressed/appendVerifiedClosed/isValidSuppressedReason/fold)
provides:
  - "ratchet-fix.mjs — the mutation-half node module (--apply-decisions + --finalize-fixes)"
  - "mix accrue_admin.ui.fix — thin orchestrator: apply -> assets.build -> commit priv/static -> recapture -> probe -> finalize"
  - "ratchet-fix-probe.spec.js — scoped per-resolved-finding DOM probe writing probe-results.json"
  - "isValidSuppressedReason now exported from ratchet-ledger.js for up-front batch validation"
affects: [207-08, 208-convergence, ui-ratchet-round-fix-loop]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "abort-whole-batch validation: validate every decision row before applying ANY (zero partial-apply)"
    - "injected probe map: finalizeFixes takes probeResults as a parameter so the self-test needs no live browser"
    - "D-50 structural guarantee via grep: mutation command provably contains no fan-out / net-new-open writer"
    - "committed-CSS-bundle discipline: git add priv/static + --allow-empty commit BEFORE re-capture"

key-files:
  created:
    - accrue_admin/e2e/ratchet/ratchet-fix.mjs
    - accrue_admin/e2e/ratchet-fix-probe.spec.js
    - accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex
    - accrue_admin/test/mix/tasks/accrue_admin_ui_fix_test.exs
  modified:
    - accrue_admin/e2e/ratchet/ratchet-ledger.js
    - accrue_admin/package.json

key-decisions:
  - "Exported isValidSuppressedReason from ratchet-ledger.js (defined but not in module.exports) so --apply-decisions can validate the whole reject batch up-front without appending — the abort-before-any-apply invariant requires validation decoupled from appendSuppressed."
  - "For rubric dimensions with no single objective DOM invariant (design-token/spacing/microcopy/focus-ring + subjective ledger-count dims), the probe trusts the maintainer's already-approved resolution (present=false); objective kinds (contrast dim 6, motion dim 9) are genuinely re-measured and can override to present=true."
  - "ui.fix runs the exact 7-command sequence apply-decisions -> assets.build -> git-add -> git-commit -> recapture -> probe -> finalize-fixes (the plan's inline step-count prose was loose; the twice-stated command list is the contract)."

patterns-established:
  - "Guard-ordering discipline: --self-test checked FIRST in main(), before any real-path file access."
  - "Superset probed object: the probe emits a union of kind-fields; mintGuardRow.buildRow picks per kind."

requirements-completed: [ORCH-03, ORCH-04]

coverage:
  - id: D1
    description: "--apply-decisions applies an all-approve batch (D-42 zero-edit happy path) and writes .fix-context.json"
    requirement: "ORCH-03"
    verification:
      - kind: unit
        ref: "node e2e/ratchet/ratchet-fix.mjs --self-test (scenario a)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A reject row with missing/invalid suppressed_reason aborts the ENTIRE batch before any ledger/CSS mutation (D-43)"
    requirement: "ORCH-03"
    verification:
      - kind: unit
        ref: "node e2e/ratchet/ratchet-fix.mjs --self-test (scenario b)"
        status: pass
    human_judgment: false
  - id: D3
    description: "--dry-run mutates nothing (no appendResolved/appendSuppressed, no .fix-context.json)"
    requirement: "ORCH-03"
    verification:
      - kind: unit
        ref: "node e2e/ratchet/ratchet-fix.mjs --self-test (scenario c)"
        status: pass
    human_judgment: false
  - id: D4
    description: "--finalize-fixes mints a guard + promotes to verified-closed ONLY for a resolved-this-round finding the probe confirms fixed (present:false); leaves present:true/no-entry/other-round untouched (D-44/D-50)"
    requirement: "ORCH-04"
    verification:
      - kind: unit
        ref: "node e2e/ratchet/ratchet-fix.mjs --self-test (scenario d)"
        status: pass
    human_judgment: false
  - id: D5
    description: "mix accrue_admin.ui.fix sequences the 7-command loop, commits ONLY priv/static, runs zero evaluator fan-out (D-50), threads scope into recapture, and --dry-run stops after step 1"
    requirement: "ORCH-03"
    verification:
      - kind: unit
        ref: "test/mix/tasks/accrue_admin_ui_fix_test.exs (6 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "ratchet-fix.mjs and ratchet-fix-probe.spec.js are structurally incapable of a net-new open row / evaluator fan-out"
    requirement: "ORCH-04"
    verification:
      - kind: other
        ref: "grep -E 'appendOpen|ratchet-propose|ratchet-verify' over both files returns nothing"
        status: pass
    human_judgment: false
  - id: D7
    description: "The scoped probe spec correctly reaches each resolved finding's surface and writes a well-formed probe-results.json when run live against the admin app"
    verification: []
    human_judgment: true
    rationale: "Live per-kind DOM probing (routes, seeded ids, computed styles) is only exercised during a real ui.fix round against a booted admin server; the self-tests inject a fake probe map and never launch a browser."

# Metrics
duration: 20min
completed: 2026-07-05
status: complete
---

# Phase 207 Plan 06: Orchestration one-command round/fix loop (mutation half) Summary

**The ORCH-03/04 mutation half: `ratchet-fix.mjs` (validated batch apply + scoped-probe-gated guard-mint/verify-close) plus a thin `mix accrue_admin.ui.fix` that rebuilds+commits the CSS bundle, re-captures, probes, and finalizes — structurally incapable of creating a net-new open row (D-50).**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-05
- **Tasks:** 2
- **Files modified:** 6 (4 created, 2 modified)

## Accomplishments
- `ratchet-fix.mjs`: `--apply-decisions` validates the whole decision batch up-front (abort-on-any-invalid-reject, zero partial-apply), prints the loud D-43 banner, applies approves via `appendResolved` / rejects via `appendSuppressed`, and writes `.fix-context.json`; `--finalize-fixes` mints a guard + promotes to `verified-closed` ONLY for findings the injected scoped-probe map confirms fixed. Reuses ratchet-ledger.js + 207-03 guard-mint verbatim; `--self-test` proves all four D-42/D-43/D-44 scenarios with no browser/key.
- `mix accrue_admin.ui.fix`: Runner-swappable orchestrator running the 7-command loop, committing ONLY `priv/static` before re-capture, threading round/scope from `.fix-context.json`, and running NO evaluator fan-out.
- `ratchet-fix-probe.spec.js`: scoped per-resolved-finding DOM probe (this round only) writing `probe-results.json`; observes only enumerated resolved findings, imports nothing from the fan-out.
- D-50 enforced structurally: `grep -E "appendOpen|ratchet-propose|ratchet-verify"` over both new JS files returns nothing.

## Task Commits

Each task was committed atomically:

1. **Task 1: ratchet-fix.mjs (--apply-decisions + --finalize-fixes)** - `1d648887` (feat)
2. **Task 2: scoped probe spec + ui.fix.ex mix task + FakeRunner test** - `73473627` (feat)

_TDD note: this directory's convention co-locates a rich `--self-test` harness with each node module (RED/GREEN is exercised by the embedded assertion scenarios rather than a separate spec file); the Elixir task is proven by a FakeRunner ExUnit suite._

## Files Created/Modified
- `accrue_admin/e2e/ratchet/ratchet-fix.mjs` - Mutation-half module: apply-decisions + finalize-fixes + self-test.
- `accrue_admin/e2e/ratchet-fix-probe.spec.js` - Scoped per-resolved-finding DOM probe → probe-results.json.
- `accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex` - Thin orchestrator for the round/fix loop mutation half.
- `accrue_admin/test/mix/tasks/accrue_admin_ui_fix_test.exs` - FakeRunner suite (6 tests: order, no-fan-out, priv/static-only commit, dry-run, --round, unscoped).
- `accrue_admin/e2e/ratchet/ratchet-ledger.js` - Added `isValidSuppressedReason` to `module.exports` (was defined, not exported).
- `accrue_admin/package.json` - Added `ui:fix` script.

## Decisions Made
- **Exported `isValidSuppressedReason`** — the plan's key-link mandates reusing it, but it was defined-and-not-exported in ratchet-ledger.js. The abort-before-any-apply invariant requires validating the whole reject batch up-front (decoupled from `appendSuppressed`, which validates only at append time), so the pure function must be importable. Additive, safe, no reimplementation. ratchet-ledger.js's own self-test stays green.
- **Probe verdict policy** — objective kinds (contrast dim 6, motion dim 9) are genuinely re-measured against their AA/reduced-motion invariant; all other kinds trust the maintainer's already-approved resolution (`present=false`) since there is no single objective DOM invariant to re-derive without richer per-finding target metadata. Documented inline in the probe's `default` branch.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Exported `isValidSuppressedReason` from ratchet-ledger.js**
- **Found during:** Task 1 (ratchet-fix.mjs)
- **Issue:** The plan mandates `import { ... isValidSuppressedReason ... } from "./ratchet-ledger.js"`, but the function — though defined and self-tested in ratchet-ledger.js — was absent from its `module.exports`, so the ESM named import threw `SyntaxError: Named export not found`.
- **Fix:** Added `isValidSuppressedReason` to the `module.exports` object literal (cjs-module-lexer then surfaces it as a named ESM export). Reimplemented nothing.
- **Files modified:** accrue_admin/e2e/ratchet/ratchet-ledger.js
- **Verification:** `ratchet-fix.mjs --self-test` green; `node e2e/ratchet/ratchet-ledger.js` self-test still green (no regression).
- **Committed in:** `1d648887` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to satisfy the plan's own reuse key-link. No scope creep — a single additive export line.

## Issues Encountered
None beyond the export deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The mutation half of the one-command round/fix loop is complete and self-proven. Wave 4 of Phase 207 (this plan) closes the last of the 6 plans.
- Live end-to-end exercise of `ratchet-fix-probe.spec.js` against a booted admin (real routes, seeded ids, computed-style probing) is deferred to an actual `ui.fix` round / Phase 208 convergence proof — the self-tests deliberately inject a fake probe map (no browser).

---
*Phase: 207-orchestration-digest-one-command-round-fix-loop*
*Completed: 2026-07-05*

## Self-Check: PASSED
- All 4 created files present on disk; SUMMARY present.
- Both task commits (`1d648887`, `73473627`) found in git history.
