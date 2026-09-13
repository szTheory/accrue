---
phase: 229-repository-truth-recovery-safety
plan: 07
subsystem: repository-safety
tags: [git-bundle, recovery, deterministic-rendering, node-test, shell-quoting]
requires:
  - phase: 229-05
    provides: Atomic external recovery capsule and argv-safe restoration contract
  - phase: 229-06
    provides: Complete singleton/plural repository inventory schema
provides:
  - Independent exact-set recovery verification across private and public authorities
  - Executable runtime-only bundle verification and original-head restoration procedure
  - Flag-specific negative controls for every strict repository inventory check
affects: [229-09-final-capture, phase-230-history-integration]
tech-stack:
  added: []
  patterns: [independent authority reconciliation, exact map equality, POSIX single-quote rendering, fresh-repository recovery integration]
key-files:
  created: []
  modified:
    - scripts/ci/verify_repository_inventory.mjs
    - scripts/ci/render_repository_inventory.mjs
key-decisions:
  - "Treat private manifest assertions as untrusted inputs: independently verify owner, mode, digest, bundle heads, encoded refs, and exact set equality."
  - "Derive public recovery commands from validated original ref/object mappings and quote every shell argument; never execute legacy private restore strings."
patterns-established:
  - "Strict recovery proof: reconcile manifest, bundle, encoded preservation refs, committed recovery rows, and canonical non-preservation refs as exact maps."
  - "Recovery rendering: assign/export the runtime-only bundle path before use, fetch actual original heads, then update refs with POSIX-quoted arguments."
requirements-completed: [REPO-01, REPO-02]
coverage:
  - id: D1
    description: "Strict verification independently proves complete recovery and rejects every missing, extra, duplicate, wrong-object, wrong-encoded, absent-head, foreign, null, and empty case."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-recovery --require-all-ref-recovery --require-typed-artifacts --require-complete-categories --require-edge-cases --require-command-provenance --require-privacy-controls --require-determinism"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each advertised strict flag has a targeted negative control for its named property."
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/ci/verify_repository_inventory.mjs#strict repository inventory flags enforce independent negative controls"
        status: pass
    human_judgment: false
  - id: D3
    description: "The exact rendered procedure verifies a generated bundle and restores ordinary and metacharacter-bearing original refs in a fresh repository."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/ci/verify_repository_inventory.mjs#rendered recovery procedure restores original bundle heads safely"
        status: pass
    human_judgment: false
actuals:
  tokens: 14526
  tasks: 2
  commits: 4
plan_head_before: ab005276ee882d788681ce0cf6dccaca6724e725
commits: 4
metrics:
  duration: 20m
  completed: 2026-09-13
  tasks: 2
  files: 2
duration: 20m
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 07: Independent Recovery Proof and Executable Rendering Summary

**An independently anchored all-ref verifier plus deterministic recovery instructions that safely restore actual bundle heads in a fresh repository.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-09-13T15:01:00Z
- **Completed:** 2026-09-13T15:21:30Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced shallow recovery booleans and non-empty checks with independent private-manifest, bundle-digest, bundle-head, encoded-ref, committed-row, and canonical-ref exact equality proofs.
- Added explicit missing, extra, duplicate, wrong-object, wrong-encoded, absent-head, foreign-repository, null/empty, valid-singleton, and strict-flag negative controls.
- Rendered a runtime-only bundle setup and POSIX-quoted original-head restore procedure, then executed the exact block in a fresh repository against ordinary and hostile valid ref names.
- Preserved every SHA in plural remote categories, distinguishing observed-empty results from typed unavailable evidence with stable secondary ordering.

## Automated Evidence

- node --check scripts/ci/render_repository_inventory.mjs — passed.
- node --check scripts/ci/verify_repository_inventory.mjs — passed.
- node --test scripts/ci/collect_repository_inventory.mjs — passed (2 tests).
- node --test scripts/ci/verify_repository_inventory.mjs — passed (4 tests, including strict recovery and exact restore integration).
- Full strict fixture command from both plan tasks — passed.
- A non-fixture `--require-all-ref-recovery` invocation without private inputs exits non-zero and names the missing `--recovery-manifest` input.

## Task Commits

1. **Task 1: Prove all-ref recovery and every strict flag independently** — `53450baf` (RED), `aaa7f0d3` (GREEN)
2. **Task 2: Render and execute exact bundle verification and restoration instructions** — `fa9bf7c1` (RED), `1e8f0c11` (GREEN)

## Files Created/Modified

- `scripts/ci/verify_repository_inventory.mjs` — independent recovery authorities, exact-set comparisons, strict-flag controls, and fresh-repository restore integration.
- `scripts/ci/render_repository_inventory.mjs` — runtime bundle setup, POSIX-safe original-head commands, plural remote rows, and deterministic secondary ordering.

## Decisions Made

- The private manifest is an authority only after its restrictive ownership/mode and externally supplied digest anchor pass; its asserted booleans and legacy restore strings are never treated as proof.
- Public recovery instructions are reconstructed from validated original ref/object pairs and actual bundle membership, keeping the private bundle location solely in runtime state.

## TDD Gate Compliance

- RED `53450baf`: the exact one-of-many probe failed because shallow `recovery.refs.length` logic accepted an incomplete recovery set; `tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- GREEN `aaa7f0d3`: independent exact-map proof and strict negative fixtures passed.
- RED `fa9bf7c1`: the renderer test failed because the command-prefix assignment expanded `PHASE229_BUNDLE` before it existed; `tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- GREEN `1e8f0c11`: the exact rendered procedure verified and restored real bundle content in a fresh repository.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The immutable original private capsule uses the legacy `restore_command` field. The verifier intentionally ignores that untrusted string and supports it without mutation, while the public renderer derives safe commands from independently verified original ref/object mappings.

## User Setup Required

None - private recovery paths remain runtime-only inputs to the final capture plan.

## Next Phase Readiness

Plan 229-09 can recapture the canonical JSON/Markdown pair and invoke strict verification with the original private manifest digest and bundle supplied only at runtime.

## Self-Check: PASSED

- Both modified scripts exist and pass syntax and fixture verification.
- Task commits `53450baf`, `aaa7f0d3`, `fa9bf7c1`, and `1e8f0c11` exist in git history.
- No plan-owned stub, skipped test, unrun verification, or unmodeled threat surface remains.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
