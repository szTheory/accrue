---
phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
plan: 03
subsystem: testing
tags: [nodejs, esm, ndjson, ratchet, deterministic-gate, admin-ui-eval]

# Dependency graph
requires:
  - phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
    provides: "ratchet-ledger.js's fold()/LENS_KEYS (206-01) — imported directly, never reimplemented"
provides:
  - "phase-ratchet-ledger.mjs: the deterministic sibling gate — folds the committed ledger, computes per-lens confirmed_open counts, asymmetrically compares against ledger.baseline.json (count-increase), checks guard_ref presence (guard-missing), checks reopen-marker legitimacy (illegal-reopen), and enforces the --freeze refusal gate"
  - "Phase 206's own committed findings.ledger.ndjson / ledger.baseline.json / reopen-markers.ndjson / finding-regressions.ndjson quadruple — empty/all-zero/unfrozen, gate-green by construction"
affects: [206-04-verify-ratchet-ledger-ci, 207-orchestration, 208-freeze-and-wire-ci]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Static ESM import of a CJS sibling module (`import * as ratchetLedger from \"./ratchet-ledger.js\"`) rather than a dynamic `await import()` — no guard/deferred-import need exists here (unlike the SDK-guarded ratchet-verify.mjs), so the simpler static form (already proven working in 206-02) is used"
    - "Every reducer function accepts an overridable {ledgerPath, baselinePath, reopenMarkersPath, regressionsPath} parameter object, defaulting to the real committed paths — the same discipline ratchet-ledger.js's append helpers use, letting --self-test redirect every read/write to an fs.mkdtempSync scratch root"
    - "Asymmetric forward-only compare (count-increase fires only on increase) ported from phase200-scorecard.mjs's compareCells(), adapted from per-cell score/coverage to per-lens open-finding totals"

key-files:
  created:
    - accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs
    - accrue_admin/e2e/ratchet/findings.ledger.ndjson
    - accrue_admin/e2e/ratchet/ledger.baseline.json
    - accrue_admin/e2e/ratchet/reopen-markers.ndjson
    - accrue_admin/e2e/ratchet/finding-regressions.ndjson
  modified: []

key-decisions:
  - "Used a static `import * as ratchetLedger from \"./ratchet-ledger.js\"` at the top of the file rather than the plan's literal dynamic `const { fold, LENS_KEYS } = await import(...)` — this file has no SDK-guard ordering constraint (unlike ratchet-verify.mjs), and 206-02 already proved the static-import form works cleanly against a CJS sibling via cjs-module-lexer interop. Behavior-identical; simpler."
  - "Omitted importing region-tags.js — the plan's action text listed it alongside ratchet-ledger.js, but no function in this file's described algorithm (fold/count/compare, guard_ref check, reopen-marker check, --freeze gate) calls any region-tags.js export. This reducer trusts the folded ledger row's own claim_key/finding_id fields directly (identity re-validation against region-tags.js already happened upstream in ratchet-verify.mjs's appendOpen path, per D-35/D-38) rather than re-deriving it a second time here. Omitting an unused import avoids dead code; no functionality was lost."
  - "regressionRow()'s `lens` field is reused as a generic identifier slot across all 3 regression kinds per the plan's own wording: the lens key for count-increase, finding_id for guard-missing, claim_key for illegal-reopen — matching the plan's literal `finding.lens_or_id` / `finding.claim_key` call-site examples."
  - "regenerateBaseline() runs unconditionally on every non-self-test invocation (not gated on regressions being absent) — per D-37, an unfrozen baseline is meant to track current counts on every run (this is what lets Phase 207's ui.fix re-scoring recompute the baseline during iteration); only --freeze (Phase 208) makes the baseline sticky against future increases."
  - "Doc comments deliberately never spell out the literal Anthropic-SDK package-name substring (learned from 206-01's SUMMARY deviation, where a doc comment tripped its own `grep -c` verification check) — phrased as \"no Anthropic SDK import\" throughout."

requirements-completed: [LEDGER-02, LEDGER-03, LEDGER-05]

coverage:
  - id: D1
    description: "A synthetic ledger with 2 open findings for one lens against a committed baseline of 1 for that lens produces exactly one count-increase regression row naming that lens (SC-4 / LEDGER-03)"
    requirement: "LEDGER-03"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test — fixture (2) count-increase group (2 assertions)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A resolved finding whose guard_ref token is not a substring of its named GUARD_HOME_SPECS file produces a guard-missing regression (SC-4 / LEDGER-03)"
    requirement: "LEDGER-03"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test — fixture (3) guard-missing group (2 assertions)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A resolved_locked claim reappearing open without a matching current-epoch reopen marker produces an illegal-reopen regression (SC-4 / LEDGER-03)"
    requirement: "LEDGER-03"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test — fixture (4) illegal-reopen group (2 assertions)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The reducer refuses to write a frozen baseline without --freeze, leaving the on-disk file byte-identical"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test — fixture (5) --freeze refusal group (2 assertions)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The committed findings.ledger.ndjson / ledger.baseline.json / reopen-markers.ndjson / finding-regressions.ndjson quadruple is self-matching (open == baseline) and gate-green by construction, with zero live LLM calls (SC-3, D-37)"
    requirement: "LEDGER-02"
    verification:
      - kind: unit
        ref: "test ! -s finding-regressions.ndjson (0 bytes); re-running phase-ratchet-ledger.mjs against the unchanged committed files is byte-identical (idempotent)"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-07-04
status: complete
---

# Phase 206 Plan 03: Phase-Ratchet-Ledger Deterministic Gate Summary

**Built `phase-ratchet-ledger.mjs` — the deterministic sibling gate proving 3 regression kinds (count-increase, guard-missing, illegal-reopen) plus the `--freeze` refusal via `--self-test`, and committed Phase 206's own gate-green-by-construction ledger/baseline/reopen-marker/regressions quadruple.**

## Performance

- **Duration:** ~8 min
- **Completed:** 2026-07-04T20:59:43Z
- **Tasks:** 3 (2 code commits — see note below)
- **Files modified:** 5

## Accomplishments
- `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` created: imports `fold`/`LENS_KEYS` directly from 206-01's `ratchet-ledger.js` (never reimplemented), computes per-lens `confirmed_open` totals (D-24 7-value lens enum), and asymmetrically compares against `ledger.baseline.json` — fires `count-increase` only when a lens's open-finding total exceeds its baseline (D-25/D-26).
- `checkGuardRef()`: D-39/D-40 static-substring guard-presence contract. The `"ledger-count"` sentinel bypasses the file check entirely; otherwise splits on `"::"`, validates path-safety against the closed `GUARD_HOME_SPECS` 4-file allowlist, validates the `@ratchet:f-[0-9a-f]{16}` token grammar with a `finding_id` cross-wire check, and reads the spec file for a literal substring match — zero test execution.
- `checkReopenMarkers()`: D-41 illegal-reopen detection — a `resolved_locked` claim reappearing `open` without a matching current-epoch entry in `reopen-markers.ndjson` fires a regression.
- `regenerateBaseline()`: D-37 `--freeze` refusal gate — throws `"Refusing to modify a frozen baseline without --freeze (Phase 208 only)."` rather than silently overwriting an existing `frozen:true` baseline.
- `--self-test`: 5 independent `fs.mkdtempSync` fixture scenarios (clean/0-regressions, count-increase, guard-missing, illegal-reopen, `--freeze` refusal) — all pass, zero network calls, never touches the real committed files.
- Phase 206's own committed `findings.ledger.ndjson`/`ledger.baseline.json`/`reopen-markers.ndjson`/`finding-regressions.ndjson` quadruple: generated by running the reducer against an initially-empty ledger (all 7 lenses at `{total:0,minor:0,real:0}`, `frozen:false`, `epoch:1`, `resolved_locked:[]`); self-matching and gate-green by construction (D-37), with a proven idempotent re-run.

## Task Commits

Each task was committed atomically, with tasks 1 and 3 landing together in a single commit (see Deviations below):

1. **Task 1 + Task 3: fold/count/compare + guard_ref/reopen/--freeze logic + --self-test** - `b31564c4` (feat)
2. **Task 2: commit Phase 206's initial gate-green ledger quadruple** - `a2f6feca` (feat)

**Plan metadata:** committed separately (see below)

## Files Created/Modified
- `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` - the full deterministic reducer: `computeCurrentOpenCounts`, `compareOpenCounts`, `checkGuardRef`/`checkGuardRefs`, `checkReopenMarkers`, `regenerateBaseline`, `computeRegressions`/`runReducer`, `assertSelfTest`/`runSelfTest`, CLI entry point
- `accrue_admin/e2e/ratchet/findings.ledger.ndjson` - committed, 0 bytes (initial empty ledger)
- `accrue_admin/e2e/ratchet/ledger.baseline.json` - committed, all 7 lenses at `{total:0,minor:0,real:0}`, `frozen:false`, `epoch:1`, `resolved_locked:[]`
- `accrue_admin/e2e/ratchet/reopen-markers.ndjson` - committed, 0 bytes
- `accrue_admin/e2e/ratchet/finding-regressions.ndjson` - committed, 0 bytes (gate-green proof)

## Decisions Made
- Static `import * as ratchetLedger from "./ratchet-ledger.js"` instead of the plan's literal dynamic `await import(...)` — no SDK-guard ordering constraint exists in this file, and 206-02 already proved the static form works via cjs-module-lexer interop against the same CJS sibling.
- Omitted the plan-listed `region-tags.js` import — no function in this file's described algorithm calls any of its exports; identity re-validation against `region-tags.js` already happens upstream (in `ratchet-verify.mjs`'s `appendOpen` call path, per D-35/D-38), so this reducer trusts the folded row's own `claim_key`/`finding_id` fields directly rather than re-deriving them a second time.
- `regressionRow()`'s `lens` field is reused as a generic identifier slot (lens key / `finding_id` / `claim_key` depending on regression kind) per the plan's own literal wording.
- `regenerateBaseline()` runs unconditionally on every non-self-test invocation (not gated on the absence of regressions) — an unfrozen baseline is designed to track current counts on every run per D-37, so Phase 207's `ui.fix` re-scoring can recompute it during iteration; only `--freeze` (Phase 208) makes it sticky.

## Deviations from Plan

### Auto-fixed Issues

None — no bugs, missing critical functionality, or blocking issues were encountered.

### Task-boundary note (non-blocking, no scope impact)

**1. [Plan-authoring note] Tasks 1 and 3 landed in a single commit rather than separately**
- **Found during:** Task 1 (implementation)
- **Issue:** The plan's Task 1 (fold+count+compare) and Task 3 (self-test) both target the same single file, and Task 3's self-test fixtures must exercise Task 2's own guard_ref/reopen/`--freeze` logic to prove themselves meaningfully (a self-test that only covers count-increase would not satisfy the plan's stated must-have of proving guard-missing and illegal-reopen too). Writing the file in three separately-runnable increments would have meant either (a) a Task 1 commit whose own file could not yet pass a meaningful self-test, or (b) fabricating an artificial mid-file checkpoint with no functional boundary.
- **Resolution:** The full reducer (fold/count/compare, guard_ref check, reopen-marker check, `--freeze` gate, and the 5-fixture `--self-test`) was authored and verified holistically, then committed as one commit whose message explicitly attributes the work to "tasks 1+3," followed by a second, cleanly separated commit for Task 2's own remaining deliverable (the 4 committed data artifacts). All of Task 1's, Task 2's, and Task 3's `<acceptance_criteria>` and `<verify>` commands were independently run and passed against the final state.
- **Files modified:** `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` (commit `b31564c4`); the 4 committed data files (commit `a2f6feca`)
- **Verification:** All 3 tasks' `<verify>`/`<acceptance_criteria>` commands pass (see Self-Check below); plan-level `<verification>` block passes in full.

---

**Total deviations:** 0 auto-fixed bugs/missing-functionality; 1 non-blocking task-boundary/commit-structure note.
**Impact on plan:** None on scope or correctness — every task's own acceptance criteria and the plan's overall verification block pass exactly as specified.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. This module is dev/test-only tooling under `accrue_admin/e2e/ratchet/`, never referenced from `accrue_admin`'s `lib/` runtime or `mix.exs` application deps.

## Next Phase Readiness
- `phase-ratchet-ledger.mjs` is fully self-testable (`node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test` exits 0, 9 `self-test pass:` lines) and its real committed quadruple is gate-green (`finding-regressions.ndjson` is 0 bytes, idempotent re-run confirmed).
- 206-04's `scripts/ci/verify_ratchet_ledger.mjs` can now independently re-verify this reducer's per-lens `confirmed_open` counts from the raw committed ledger rows (per the plan's key-link: "phase-ratchet-ledger.mjs's per-lens confirmed_open counts are what scripts/ci/verify_ratchet_ledger.mjs (206-04) independently recomputes and cross-checks").
- No blockers. `--freeze` remains unexercised in this phase (reserved for Phase 208) — the committed baseline stays `frozen:false` as designed.

## Self-Check: PASSED

- FOUND: accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs
- FOUND: accrue_admin/e2e/ratchet/findings.ledger.ndjson
- FOUND: accrue_admin/e2e/ratchet/ledger.baseline.json
- FOUND: accrue_admin/e2e/ratchet/reopen-markers.ndjson
- FOUND: accrue_admin/e2e/ratchet/finding-regressions.ndjson
- FOUND: b31564c4 (Task 1+3 commit)
- FOUND: a2f6feca (Task 2 commit)

---
*Phase: 206-adversarial-verifier-finding-ledger-deterministic-gate*
*Completed: 2026-07-04*
