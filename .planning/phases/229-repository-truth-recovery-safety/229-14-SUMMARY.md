---
phase: 229-repository-truth-recovery-safety
plan: 14
subsystem: repository-safety
tags: [git, recovery-capsule, invariant-gate, deterministic-evidence, tdd]
requires:
  - phase: 229-10
    provides: "Final artifact reconciliation and raw symlink-byte hashing"
  - phase: 229-11
    provides: "Bounded terminal-page GitHub evidence"
  - phase: 229-12
    provides: "Absolute CI deadline and exact run attribution"
  - phase: 229-13
    provides: "Independent repository authority, provenance, and privacy verification"
provides:
  - "Executable runtime-only strict verification documentation"
  - "Raw-path-safe capsule and workspace invariant gate around the complete final chain"
  - "Final schema-v2 canonical JSON and deterministic Markdown repository truth"
  - "Exclusive current-owner mode-0600 final handoff attestation"
affects: [phase-229-verification, phase-230-history-integration, repository-handoff]
actuals:
  tokens: 11011
  tasks: 2
  commits: 4
plan_head_before: 58259b7ade3f2ef23d54f28e16342e19f3702606
commits: 4
tech-stack:
  added: []
  patterns: [runtime-only-private-authority, recursive-raw-byte-snapshots, exact-before-after-comparison, allowlisted-final-chain]
key-files:
  created: [scripts/ci/verify_phase229_handoff_invariants.mjs]
  modified:
    - scripts/ci/README.md
    - scripts/ci/phase229_gap_closure.test.mjs
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md
key-decisions:
  - "The final handoff uses a fixed allowlisted chain and never accepts caller-supplied child commands."
  - "Capsule, untracked-path, ref/tag, and worktree identities are encoded from raw bytes and exact-compared around the entire chain."
  - "The sole external delta is a pre-named absent attestation created with exclusive open after all pre-attestation comparisons pass."
patterns-established:
  - "Final-success gate: capture protected identities, run the fixed chain, compare exact state, then create and validate one exclusive attestation."
  - "Private authority stays runtime-only: documentation names variables and flags but never persists capsule locations or contents."
requirements-completed: [REPO-01, REPO-02, REPO-03]
coverage:
  - id: D1
    description: "The exact documented strict command succeeds with generated private authority and fails for every absent, empty, mismatched, or unsafe input."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/ci/phase229_gap_closure.test.mjs#WR-01 documented strict command executes generated private authority and rejects invalid inputs"
        status: pass
    human_judgment: false
  - id: D2
    description: "One allowlisted wrapper exact-compares recursive capsule and protected workspace identities around the complete final chain."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/ci/verify_phase229_handoff_invariants.mjs --self-test"
        status: pass
      - kind: integration
        ref: "scripts/ci/phase229_gap_closure.test.mjs#final handoff gate rejects capsule workspace and attestation invariant drift"
        status: pass
    human_judgment: false
  - id: D3
    description: "The final canonical inventory records complete local and terminal-proven or honestly unavailable remote truth and reproduces its privacy-safe Markdown projection."
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "verify_phase229_handoff_invariants.mjs --run-final-chain"
        status: pass
    human_judgment: false
  - id: D4
    description: "Read-only monitor, provider-proof separation, and Phase 229 no-integration boundary remain enforced by the final chain."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 14: Final Repository Truth Handoff Summary

**A raw-byte-safe invariant gate now recaptures and strictly verifies canonical repository truth while proving the original recovery capsule and protected workspace remain exact before one exclusive attestation is added.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-13T19:37:59Z
- **Completed:** 2026-09-13T19:52:48Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Made the README's strict verifier block directly executable with the three runtime-only private authority variables and every strict flag.
- Added generated-capsule subprocess coverage for valid authority plus missing, empty, wrong-digest, wrong-bundle, and broad-permission failures.
- Added one fixed final-success wrapper that snapshots recursive capsule entries, complete untracked identities, refs/tags, and worktrees before running the entire allowlisted chain and exact-compares them afterward.
- Recaptured the final schema-v2 inventory with 218 refs, 109 recovery mappings, six typed artifacts, one worktree, ten ship windows, terminal-proven remote main/PR/release evidence, and honest unavailable Actions evidence.
- Created only `phase229-final-capture-attestation-round2.json` in the external capsule using exclusive creation, current ownership, and mode `0600`; all six pre-existing capsule digests remain unchanged.

## Task Commits

Each task was committed atomically through its TDD RED and GREEN stages:

1. **Task 1 RED: expose unrunnable strict inventory docs** - `5b853aa2` (test)
2. **Task 1 GREEN: make strict inventory verification executable** - `d38e2be6` (docs)
3. **Task 2 RED: require final handoff invariant gate** - `b48c7d8a` (test)
4. **Task 2 GREEN: gate final repository truth handoff** - `8ee1cf15` (feat)

## Files Created/Modified

- `scripts/ci/verify_phase229_handoff_invariants.mjs` - Captures raw-path-safe protected snapshots, runs only the fixed final chain, exact-compares identities, and creates the exclusive attestation.
- `scripts/ci/phase229_gap_closure.test.mjs` - Executes the documented strict command with generated authority and exercises the named final-invariant matrix through the wrapper process.
- `scripts/ci/README.md` - Documents the executable strict command and exact runtime-only final-wrapper invocation without private locations.
- `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json` - Final canonical repository and remote evidence.
- `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md` - Fresh deterministic privacy-safe projection.

## Decisions Made

- Used Buffer-returning filesystem and NUL-delimited Git interfaces for protected identities; platforms unable to reopen a raw filename fail closed rather than decoding and substituting it.
- Generated the current artifact attestation only in the process-local mode-`0600` scratch area, allowing the collector to verify current authorized workflow metadata while leaving every original capsule entry untouched.
- Kept attestation creation strictly after the full chain and first exact comparison; a failure after creation removes only the file created by that invocation.

## TDD Gate Compliance

- **Task 1 RED:** the named WR-01 test failed because no extractable runtime-authority README block existed; `check tdd-red-evidence` returned `RED_EVIDENCE_OK` with `target_test_failed`.
- **Task 1 GREEN:** the extracted block passed a generated public-preservation capsule and rejected all seven missing/empty variable cases plus wrong digest, wrong bundle, and unsafe permissions.
- **Task 2 RED:** the named final-handoff test failed because the supported invariant wrapper was absent; `check tdd-red-evidence` returned `RED_EVIDENCE_OK` with `target_test_failed`.
- **Task 2 GREEN:** the wrapper self-test and 22-test gap matrix passed, followed by the real final-chain invocation against the independently anchored capsule.

## Verification

- `node --test scripts/ci/phase229_gap_closure.test.mjs` — PASS, 22/22 tests.
- `node scripts/ci/verify_phase229_handoff_invariants.mjs --self-test` — PASS, all named capsule/workspace/attestation cases.
- Exact runtime-only `verify_phase229_handoff_invariants.mjs --run-final-chain ...` invocation — PASS.
- `node --test scripts/ci/verify_repository_inventory.mjs` — PASS, 8/8 tests.
- Monitor/wrapper/documentation self-test — PASS.
- Final attestation validation — PASS: regular file, current owner, mode `0600`, sanitized PASS record.
- Original capsule integrity — PASS: every pre-existing entry retains its pre-task SHA-256; exactly one named attestation was added.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- macOS exposes its temporary directory through a lexical `/var` symlink and does not reliably reopen invalid-UTF-8 filenames through Node filesystem APIs. Fixtures canonicalize the temporary root before public preservation; raw link bytes are exercised directly, while raw filename round-trip loss is detected and the production snapshot path fails closed when lossless reopening is unavailable.
- Tracked planning state was synchronized directly after the final capture instead of invoking state handlers that republish `.planning/state.json` and `.planning/milestone.lock`; this preserves the protected runtime artifacts frozen by the final attestation.

## Authentication Gates

None. The bounded GitHub collection completed with terminal-proven public categories and an explicit `network` unavailable Actions fact.

## Known Stubs

None. Empty arrays and nullable remote fields are validated evidence states, not placeholders.

## User Setup Required

None. Private authority remained supplied only through the runtime values provided for this execution.

## Next Phase Readiness

Phase 229 is complete and ready for a separate Phase 230 planning/execution step. The handoff contains facts and recovery mechanisms only; it performed no history integration, cleanup, remote mutation, window resolution, push, merge, or publication.

## Self-Check: PASSED

- All five plan-owned tracked artifacts exist; the executable wrapper is mode `100755`.
- Task commits `5b853aa2`, `d38e2be6`, `b48c7d8a`, and `8ee1cf15` exist in git history.
- The plan ledger measures four task commits from base `58259b7ade3f2ef23d54f28e16342e19f3702606`.
- The final external attestation exists at the pre-authorized path as mode `0600`; all pre-existing capsule entries and unrelated/untracked repository paths remain untouched.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
