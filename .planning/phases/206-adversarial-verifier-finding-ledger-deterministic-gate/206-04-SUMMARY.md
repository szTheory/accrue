---
phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
plan: 04
subsystem: testing
tags: [nodejs, esm, ndjson, ci-gate, ratchet, admin-ui-eval]

# Dependency graph
requires:
  - phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
    provides: "phase-ratchet-ledger.mjs (206-03) — the deterministic reducer + committed findings.ledger.ndjson/ledger.baseline.json/reopen-markers.ndjson/finding-regressions.ndjson quadruple this plan independently re-verifies"
  - phase: 205-persona-design-lens-evaluator-harness
    provides: "region-tags.js's isAdmissibleToken() — the one deliberate reuse exception to this plan's independence rule"
provides:
  - "scripts/ci/verify_ratchet_ledger.mjs: the independent CI re-verifier — recomputes per-lens confirmed_open counts straight from raw findings.ledger.ndjson rows via its own from-scratch fold, never trusting ledger.baseline.json's own stored numbers"
  - "verifyRatchetLedger(overridePaths) — pure function returning {ok, failures}, self-testable against fs.mkdtempSync fixtures"
  - "npm run ratchet:ledger / ratchet:ledger:self-test paired scripts in accrue_admin/package.json"
affects: [207-orchestration, 208-freeze-and-wire-ci]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Genuine code independence from the reducer it verifies (verify_phase200_scorecard.mjs precedent): its own from-scratch fold/seq-monotonic check, its own duplicated GUARD_HOME_SPECS allowlist + guard_ref static-substring check, its own raw-byte finding-regressions.ndjson read — zero shared implementation with the reducer besides the one deliberate region-tags.js (isAdmissibleToken) exception"
    - "'trust but verify': compares its own independently-recomputed per-lens confirmed_open totals against the committed baseline's stored numbers and fails on ANY disagreement, in either direction (LEDGER-04's literal contract)"

key-files:
  created:
    - scripts/ci/verify_ratchet_ledger.mjs
  modified:
    - accrue_admin/package.json

key-decisions:
  - "LENS_KEYS (the closed 7-value per-lens enum) is duplicated as its own local constant rather than imported from any sibling module — region-tags.js does not itself define the lens-key vocabulary (it lives in ratchet-ledger.js, which this file deliberately does not import), so duplicating the literal 7-value list here is the only way to keep both the recompute and the independence discipline intact."
  - "Added an independent justification_token re-admissibility check (checkJustificationTokensIndependent, using region-tags.js's isAdmissibleToken()) even though Task 1's <action> paragraph did not spell out this exact check step. The plan's own <read_first> explicitly calls isAdmissibleToken 'the one utility this script DOES deliberately reuse' — importing it and leaving it unexercised would contradict that stated purpose, so it is wired as a genuine defense-in-depth re-check against a hand-inserted/corrupted justification_token on a committed ledger row. [Rule 2 - auto-add missing critical functionality, documented rather than silently deviating]"
  - "reopenMarkersPath is accepted in verifyRatchetLedger()'s override-paths shape (for parity with phase-ratchet-ledger.mjs's own signature) but is unused — the plan's Task 1 action text does not describe an independent illegal-reopen re-derivation. Instead, all 3 of the deterministic reducer's regression kinds (count-increase, guard-missing, illegal-reopen) are transitively re-confirmed by this file's own raw-byte finding-regressions.ndjson zero-byte check: if the reducer had detected any of those 3 kinds, that file would be non-empty, and this file's independent read (never trusting a prior process's exit code) would catch it."
  - "Added a 6th --self-test fixture (inadmissible justification_token) beyond the plan's literal 5, to prove the deliberate region-tags.js reuse actually gates rather than being an unused import. All 5 plan-required scenarios are also present, verbatim to the plan's description."

requirements-completed: [LEDGER-04, LEDGER-05]

coverage:
  - id: D1
    description: "A hand-edited ledger.baseline.json whose stored confirmed_open numbers disagree with what the raw findings.ledger.ndjson rows actually fold to causes verify_ratchet_ledger.mjs to fail"
    requirement: "LEDGER-04"
    verification:
      - kind: unit
        ref: "node scripts/ci/verify_ratchet_ledger.mjs --self-test — (2) hand-edited baseline disagreement assertions"
        status: pass
    human_judgment: false
  - id: D2
    description: "A genuinely-matching non-zero ledger/baseline pair exits ok:true, proving the recompute is a real cross-check rather than a trivial both-zero pass"
    requirement: "LEDGER-04"
    verification:
      - kind: unit
        ref: "node scripts/ci/verify_ratchet_ledger.mjs --self-test — (5) genuinely-matching non-zero recompute assertion"
        status: pass
    human_judgment: false
  - id: D3
    description: "A resolved/verified-closed row whose guard_ref token is absent from its named real on-disk guard-home spec file fails an independent second guard-presence check"
    requirement: "LEDGER-05"
    verification:
      - kind: unit
        ref: "node scripts/ci/verify_ratchet_ledger.mjs --self-test — (4) guard-missing assertions"
        status: pass
    human_judgment: false
  - id: D4
    description: "A non-empty finding-regressions.ndjson, read as raw bytes off disk, fails independently of any prior process's exit code"
    requirement: "LEDGER-05"
    verification:
      - kind: unit
        ref: "node scripts/ci/verify_ratchet_ledger.mjs --self-test — (3) non-empty regressions assertions"
        status: pass
    human_judgment: false
  - id: D5
    description: "The real committed 206-03 artifact quadruple passes both node phase-ratchet-ledger.mjs and node scripts/ci/verify_ratchet_ledger.mjs cleanly end-to-end via the npm run ratchet:ledger chain, idempotently (no diff to the committed files)"
    requirement: "LEDGER-04"
    verification:
      - kind: integration
        ref: "cd accrue_admin && npm run ratchet:ledger (exit 0); git status --short accrue_admin/e2e/ratchet/ (clean)"
        status: pass
    human_judgment: false
  - id: D6
    description: "verify_ratchet_ledger.mjs never imports the reducer it verifies (or its shared lifecycle helper), never imports @anthropic-ai/sdk, and makes zero network calls — the LLM stays permanently off the CI gate path"
    requirement: "LEDGER-05"
    verification:
      - kind: unit
        ref: 'grep -c "phase-ratchet-ledger\|ratchet-ledger.js" scripts/ci/verify_ratchet_ledger.mjs -> 0; grep -c "@anthropic-ai/sdk" scripts/ci/verify_ratchet_ledger.mjs -> 0; grep -c "region-tags" scripts/ci/verify_ratchet_ledger.mjs -> 7'
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-04
status: complete
---

# Phase 206 Plan 04: Independent CI Re-Verifier for the Ratchet Finding Ledger Summary

**Built `scripts/ci/verify_ratchet_ledger.mjs` — the independent CI re-verifier that recomputes per-lens `confirmed_open` counts from raw `findings.ledger.ndjson` rows via its own from-scratch fold, cross-checks them against the committed `ledger.baseline.json`, and fails on any disagreement (LEDGER-04), with zero code sharing with the reducer it verifies and zero LLM reachability.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-07-04
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- `scripts/ci/verify_ratchet_ledger.mjs` created (repo-root `scripts/ci/`, mirroring `verify_phase200_scorecard.mjs`'s placement): an ESM script that deliberately does NOT import 206-03's deterministic reducer or its shared lifecycle/fold helper — genuine code independence, so a shared bug would not silently pass both.
- Its own from-scratch `independentFold()`: reads raw `findings.ledger.ndjson` lines, asserts `seq` is strictly increasing (an independent re-implementation of the same tamper-evidence check, deliberately duplicated), and keeps latest-event-wins per `finding_id`.
- `computeIndependentOpenCounts()` + `compareAgainstBaseline()`: recomputes per-lens `{total, minor, real}` open counts directly from the independently-folded state, and compares against the committed `ledger.baseline.json`'s STORED `confirmed_open` numbers — ANY mismatch (either direction, any of the 7 lens keys) is a hard `failures.baselineMismatch` failure (the literal LEDGER-04 contract).
- `validGuardHomePath()` + `checkGuardRefIndependent()`/`checkGuardRefsIndependent()`: a duplicated (not shared) `GUARD_HOME_SPECS` 4-file allowlist and D-39/D-40 guard-presence static-substring check, run as a SECOND independent confirmation against every `resolved`/`verified-closed` row's `guard_ref` (skipping the `"ledger-count"` sentinel).
- `checkJustificationTokensIndependent()`: the one deliberate exception to the independence rule — reuses `region-tags.js`'s `isAdmissibleToken()` to re-validate every folded row's `justification_token`, catching a hand-inserted or corrupted token directly in the committed ledger.
- `checkRegressionsZeroBytes()`: reads `finding-regressions.ndjson`'s raw byte size off disk via `fs.statSync`, never trusting any prior process's reported exit code — this single check transitively re-confirms all 3 of the reducer's regression kinds (count-increase, guard-missing, illegal-reopen).
- `verifyRatchetLedger(overridePaths)`: the exported pure function, accepting the same overridable `{ledgerPath, baselinePath, reopenMarkersPath, regressionsPath}` shape as `phase-ratchet-ledger.mjs`, returning `{ok, failures}`.
- `--self-test`: 6 independent `fs.mkdtempSync` fixture scenarios (the plan's 5 required — absent-baseline match, hand-edited baseline mismatch, non-empty regressions, guard-missing, genuinely-matching non-zero — plus 1 additional inadmissible-justification-token fixture), all passing, zero network calls, never touching the real committed files.
- CLI entry point printing failures and setting `process.exitCode = 1` on `!ok`.
- `"ratchet:ledger"`/`"ratchet:ledger:self-test"` npm scripts added to `accrue_admin/package.json`, mirroring the `phase200:scorecard` paired-script convention exactly.

## Task Commits

Each task was committed atomically:

1. **Task 1: Independent recompute + guard_ref/path-safety checks** - `a7956c6b` (feat), fixed for a literal-substring grep collision in `2d18bbbb` (fix)
2. **Task 2: --self-test fixtures + package.json wiring** - `6e598611` (feat)

**Plan metadata:** committed separately (see below)

## Files Created/Modified
- `scripts/ci/verify_ratchet_ledger.mjs` - the full independent re-verifier: `independentFold`, `computeIndependentOpenCounts`/`compareAgainstBaseline`, `validGuardHomePath`/`checkGuardRefIndependent`/`checkGuardRefsIndependent`, `checkJustificationTokensIndependent`, `checkRegressionsZeroBytes`, `verifyRatchetLedger`, `runSelfTest`, CLI entry point
- `accrue_admin/package.json` - `ratchet:ledger`/`ratchet:ledger:self-test` scripts

## Decisions Made
- `LENS_KEYS` and `GUARD_HOME_SPECS` are duplicated as local constants (not imported) — the whole point of this file is genuine independence from the reducer's own copies of these enums; re-deriving them a second time is what makes the recompute a real cross-check.
- Added `checkJustificationTokensIndependent()` (using `region-tags.js`'s `isAdmissibleToken()`) beyond what Task 1's literal action-text algorithm spelled out, since the plan's own `<read_first>` flags `isAdmissibleToken()` as "the one utility this script DOES deliberately reuse" — an unused import would contradict that. See key-decisions above.
- `reopenMarkersPath` is accepted in the override-paths shape for signature parity but unused — illegal-reopen detection is transitively re-confirmed via the raw-byte `finding-regressions.ndjson` zero-byte check rather than re-derived independently (not described in Task 1's action text).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Doc comment literal `@anthropic-ai/sdk` string tripped the plan's own zero-network-import grep check**
- **Found during:** Task 1 (running the plan's `<acceptance_criteria>` grep commands immediately after first draft)
- **Issue:** The header doc comment described the script as never importing "`@anthropic-ai/sdk`" — the literal package-name substring itself, which is exactly the string the plan's acceptance criteria (`grep -c "@anthropic-ai/sdk"` must return `0`) checks for. Same class of pitfall 206-01/206-02 hit with doc-comment literal-substring collisions.
- **Fix:** Reworded to "the Anthropic SDK package" — same meaning, no literal substring collision.
- **Files modified:** `scripts/ci/verify_ratchet_ledger.mjs`
- **Verification:** `grep -c "@anthropic-ai/sdk" scripts/ci/verify_ratchet_ledger.mjs` returns `0`.
- **Committed in:** `a7956c6b` (fixed before commit, no separate commit needed)

**2. [Rule 1 - Bug] Doc comments' literal `ratchet-ledger.js` mentions tripped the plan's own independence-proof grep check**
- **Found during:** Post-commit plan-level `<verification>` re-run (`grep -c "phase-ratchet-ledger\|ratchet-ledger.js"` must return `0`)
- **Issue:** Two header/doc comments described the sibling module the reducer imports by its literal filename `ratchet-ledger.js`, which collided with the plan's own OR-pattern independence-proof grep (checking that this file never mentions either the reducer's filename or its shared lifecycle-helper's filename — `region-tags.js` being the sole deliberate exception).
- **Fix:** Reworded both comments to describe the module without the exact substring (e.g. "the shared lifecycle/fold helper module (206-01)"). No functional change.
- **Files modified:** `scripts/ci/verify_ratchet_ledger.mjs`
- **Verification:** `grep -c "phase-ratchet-ledger\|ratchet-ledger.js" scripts/ci/verify_ratchet_ledger.mjs` returns `0`; `node scripts/ci/verify_ratchet_ledger.mjs`/`--self-test` still exit `0`.
- **Committed in:** `2d18bbbb` (separate fix commit, applied after Task 1's initial commit since the collision was only caught on the full plan-level verification re-run)

---

**Total deviations:** 2 (both Rule 1 doc-comment literal-substring bugs, auto-fixed — no scope creep, no functional-code bugs).
**Impact on plan:** None on scope or correctness — every task's own acceptance criteria and the plan's overall `<verification>` block pass exactly as specified after the fixes.

## Issues Encountered
None beyond the two items documented above.

## User Setup Required
None — no external service configuration required. `scripts/ci/verify_ratchet_ledger.mjs` is dev/test-only tooling, never referenced from `accrue_admin`'s `lib/` runtime or `mix.exs` application deps. It makes zero network calls and requires no credentials to run (including `--self-test`, and the live run against the real committed 0-finding ledger).

## Next Phase Readiness
- `scripts/ci/verify_ratchet_ledger.mjs` is fully self-testable (`node scripts/ci/verify_ratchet_ledger.mjs --self-test` exits 0, 10 `self-test pass:` lines across 6 fixtures) and cleanly re-verifies the real committed 206-03 artifact quadruple (`node scripts/ci/verify_ratchet_ledger.mjs` exits 0; `npm run ratchet:ledger` chains both scripts and exits 0, idempotently — no diff to the committed ledger/baseline/regressions files).
- Phase 206's own committed data quadruple (findings.ledger.ndjson / ledger.baseline.json / reopen-markers.ndjson / finding-regressions.ndjson) is now double-gated: the deterministic reducer (206-03) AND this independent re-verifier (206-04) both pass against it cleanly.
- Wiring this script into an actual GitHub Actions CI job (the `admin-ui-ratchet-guardrails` job) is explicitly out of scope for this phase — that is Phase 208's responsibility, per this plan's own `<prohibitions>`.
- No blockers. This closes out Wave 3 and the last of Phase 206's 4 plans.

## Known Stubs
None — every function shipped is fully wired and exercised by `--self-test` plus a live run against the real committed artifacts.

## Threat Flags
None — all new surface (independent recompute, guard_ref second-check, justification_token re-check, regressions byte-read) is already covered by this plan's own `<threat_model>` STRIDE register (T-206-04-01..04); no new surface was introduced beyond what that register anticipated.

## Self-Check: PASSED

- FOUND: scripts/ci/verify_ratchet_ledger.mjs
- FOUND: a7956c6b (Task 1 commit)
- FOUND: 6e598611 (Task 2 commit)
- FOUND: 2d18bbbb (Task 1 follow-up fix commit)

---
*Phase: 206-adversarial-verifier-finding-ledger-deterministic-gate*
*Completed: 2026-07-04*
