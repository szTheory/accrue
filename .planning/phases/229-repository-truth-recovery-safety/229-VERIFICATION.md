---
phase: 229-repository-truth-recovery-safety
verified: 2026-09-15T22:04:20Z
status: passed
behavior_unverified: 0
score: 7/7 must-haves verified
re_verification: "Yes — re-stamped 2026-09-15 after Phase 230 modified 4 shared covered files; supersedes the 2026-09-15T17:00:18Z report and the 2026-09-13 gaps_found report"
evidence_mode: executable
covered_digest: "v1:sha256:1ed64380d7cb0e98350b5d4a8badddb3cb6a6bac35e936fb39c849007fbe99fd"
covered_files:
  - .planning/phases/229-repository-truth-recovery-safety/229-01-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-01-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-02-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-02-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-03-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-03-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-04-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-04-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-05-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-05-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-06-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-06-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-07-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-07-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-08-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-08-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-09-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-09-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-10-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-10-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-11-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-11-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-12-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-12-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-13-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-13-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-14-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-14-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-15-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-15-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-16-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-16-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-17-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-17-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-18-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-18-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-19-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-19-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-20-PLAN.md
  - .planning/phases/229-repository-truth-recovery-safety/229-20-SUMMARY.md
  - .planning/phases/229-repository-truth-recovery-safety/229-CONTEXT.md
  - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json
  - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md
  - scripts/ci/README.md
  - scripts/ci/ci_monitor.cjs
  - scripts/ci/collect_repository_inventory.mjs
  - scripts/ci/phase229_gap_closure.test.mjs
  - scripts/ci/preserve_repository_state.sh
  - scripts/ci/render_repository_inventory.mjs
  - scripts/ci/verify_phase229_handoff_invariants.mjs
  - scripts/ci/verify_repository_inventory.mjs
  - scripts/ci/watch_ci.sh
gaps: []
advisory: []
---

# Phase 229: Repository Truth & Recovery Safety Verification Report

**Phase Goal:** Maintainers can safely establish reproducible repository and CI truth while preserving every pre-existing ref, tag, worktree, and user-owned artifact.
**Verified:** 2026-09-15
**Status:** passed
**Re-verification:** Yes — this report supersedes the 2026-09-13 `gaps_found` report (score 3/7). That report was accurate when written but predated plans 229-15 through 229-20, which exist precisely to close the findings it recorded.

## Verification Method

Every claim below is backed by a suite executed directly at this HEAD, not by narration in a
SUMMARY. Commands and results:

| Command | Result |
|---|---|
| `bash scripts/ci/preserve_repository_state.sh --self-test` | PASS (ten-boundary transaction matrix) |
| `node --test scripts/ci/phase229_gap_closure.test.mjs` | 21/21 pass |
| `node --test scripts/ci/collect_repository_inventory.mjs` | 10/10 pass |
| `node --test scripts/ci/verify_repository_inventory.mjs` | 4/4 pass |
| `node --test scripts/ci/render_repository_inventory.mjs` | 1/1 pass |
| `node scripts/ci/verify_phase229_handoff_invariants.mjs --self-test` | PASS (17 named invariants) |
| `node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md` | PASS |
| `node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-complete-categories --require-edge-cases --require-all-ref-recovery --require-typed-artifacts --require-privacy-controls --require-determinism` | PASS |

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | One committed inventory covers all roadmap categories. | ✓ VERIFIED | Strict fixture run passes every category/edge-case/all-ref/typed-artifact flag. Fabricated active refs and fabricated planning digests are rejected (gap-closure CR-04); malformed remote states fail closed at bounds (CR-03 plural evidence, CR-09). |
| 2 | Canonical JSON deterministically renders sanitized Markdown with honest provenance. | ✓ VERIFIED | `--require-determinism` passes; the committed `229-REPOSITORY-INVENTORY.md`/`.json` contain zero `undefined` cells (grep: 0/0). Plural request provenance is enforced by gap-closure CR-07. |
| 3 | Every pre-existing ref is safely preserved and restorable from collision-safe refs plus a verified bundle. | ✓ VERIFIED | 229-16 moved ref publication after fallible preparation and added a compare-and-delete rollback ledger; the self-test proves exact pre-invocation state at ten injected failure boundaries, retains pre-existing and concurrently changed refs, and leaks no ref. Bundle symlink/alias acceptance is closed by 229-19's `resolveCanonicalOutputs()` device-inode checks. |
| 4 | Supported user-owned artifacts are typed, non-dereferenced, and unchanged. | ✓ VERIFIED | 229-18 hashes raw `readlinkSync(..., {encoding:"buffer"})` bytes with a `Buffer.isBuffer` fail-closed guard (CR-02); workflow-metadata authorization is bound three ways (authorization↔attestation, authorization↔manifest/live) via `assertExactWorkflowMetadataAuthority()` (CR-05); the handoff self-test's `raw-non-utf8`, `link-digest`, `type-swap`, `mode`, `owner`, and `exclusive-attestation` invariants all pass. |
| 5 | One implementation lists, inspects, and watches an exact SHA within bounds. | ✓ VERIFIED | Monitor self-test plus wrapper and docs verification pass; gap-closure CR-09 proves the wall-clock deadline through the public process and WR-02 rejects selected-viewed run ID and workflow switching. |
| 6 | The compatibility/documentation path works and completed failures remain non-zero. | ✓ VERIFIED | `--verify-wrapper`/`--verify-docs` pass against the real `watch_ci.sh` and `README.md`; failure exits are asserted in the monitor self-test. |
| 7 | Phase 229 stops before integration, cleanup, CI/PR mutation, or publication. | ✓ VERIFIED | The monitor's injected-adapter self-test audits every GitHub argv as a repository-bound read and rejects forbidden commands — this is now an executable assertion, not the LLM judgment the prior report relied on. |

**Score:** 7/7 truths verified. **Behavior unverified: 0.**

### Prior-Report Finding Closure

All twelve findings from `229-REVIEW.md` (10 critical, 2 warning, reviewed 2026-09-13) are closed,
each by a named plan with a committed regression test:

| Finding | Closed by | Regression test |
|---|---|---|
| CR-01 arbitrary output overwrite | 229-19 | `WR-01 real final-chain subprocess…` / `CR-01 preservation rejects post-snapshot artifact mutation before PASS` |
| CR-02 raw symlink decode (NYQ-229-01) | 229-18 | `CR-02 preservation hashes raw symlink link-text bytes including newline edges`; handoff `raw-non-utf8` |
| CR-03 self-stale active authority (NYQ-229-02) | 229-20 | `CR-03 strict recovery accepts an active ref advanced past the manifest freeze and rejects a diverged one`; `CR-03 published canonical pair stays strictly verifiable after its own commit` |
| CR-04 plural provenance (T-229-12/14/G14-03) | 229-15, 229-17, 229-19 | `CR-07 strict provenance rejects unrelated missing duplicate skipped reordered foreign and over-bound requests`; 0 `undefined` in committed Markdown |
| CR-05 ignored workflow authorization | 229-18, 229-19 | `CR-05 strict recovery rejects missing extra duplicate and changed canonical preservation rows` |
| CR-06 tracked/index omission | 229-19 | `snapshotIndexAndStatus()` + real-chain unstaged/staged/add/delete/rename/mode cases |
| CR-07 arbitrary attestation | 229-17, 229-19 | schema-2 attestation binding, independently re-checked by `--require-handoff-attestation` |
| CR-08 fabricated planning digests | 229-17, 229-19 | `CR-04 strict recovery rejects a fabricated active ref and accepts the actual live object` |
| CR-09 malformed remote schema | 229-15 | `CR-03 plural GitHub evidence requires a terminal page and fails closed at bounds` |
| CR-10 failed preservation ref leak | 229-16 | preservation self-test ten-boundary failure matrix |
| WR-01 comparator-only tests | 229-17, 229-19 | real `--run-final-chain` subprocess with eleven real mutation boundaries |
| WR-02 bundle authority | 229-17 | `WR-02 CI inspection rejects selected-viewed run ID and workflow switching`; `resolveCanonicalOutputs()` alias/symlink/hardlink rejection |

Two defects were found only because 229-19 ran the real chain rather than its comparators
(`git bundle create` resetting bundle mode to 0644 in two independent call sites, and a missing
`--artifact-authorization` that meant `--run-final-chain` could never complete against a real
capsule). Both are fixed and covered.

### Required Artifacts

| Artifact | Expected | Status |
|---|---|---|
| `preserve_repository_state.sh` | Transactional all-ref/artifact preservation | ✓ VERIFIED |
| `collect_repository_inventory.mjs` | Complete recovery-gated inventory | ✓ VERIFIED |
| `render_repository_inventory.mjs` | Deterministic truthful projection | ✓ VERIFIED |
| `verify_repository_inventory.mjs` | Independent strict reconciliation | ✓ VERIFIED |
| `verify_phase229_handoff_invariants.mjs` | Transactional final safety gate | ✓ VERIFIED |
| `ci_monitor.cjs` | Exact-run bounded monitor | ✓ VERIFIED |
| `watch_ci.sh` | Thin compatibility wrapper | ✓ VERIFIED |
| `README.md` | Executable command contract | ✓ VERIFIED |
| `phase229_gap_closure.test.mjs` | Closure-boundary coverage | ✓ VERIFIED (21 tests, real-chain and real-repository fixtures) |
| `229-REPOSITORY-INVENTORY.json` | Completed-tree truth | ✓ VERIFIED |
| `229-REPOSITORY-INVENTORY.md` | Maintainer projection | ✓ VERIFIED |

### Key Links and Data Flow

| From | To | Status |
|---|---|---|
| preservation | private capsule | ✓ WIRED (late publication, compare-and-delete rollback) |
| capsule/authorization | collector | ✓ WIRED (mandatory `--artifact-authorization`, raw-Buffer link digests) |
| JSON requests[] | Markdown | ✓ WIRED (plural provenance rendered, determinism gated) |
| strict verifier | Git/planning/capsule authority | ✓ WIRED (captured-ref continuity, pinned planning digests) |
| final wrapper | outputs/capsule/workspace/attestation | ✓ WIRED (pinned canonical paths, atomic two-file publish, schema-2 attestation) |
| wrapper | CI monitor | ✓ WIRED |

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| REPO-01 | ✓ SATISFIED | Truths 1, 2; strict fixture flags; 229-19 D1/D2 |
| REPO-02 | ✓ SATISFIED | Truths 3, 4; preservation matrix; handoff self-test; 229-18 D1/D2 |
| REPO-03 | ✓ SATISFIED | Truths 5, 6; monitor self-test, deadline and run-binding tests |

**Requirements score:** 3/3 satisfied. No orphaned IDs.

### Executable Acceptance Coverage

58 coverage entries across 20 SUMMARY files; **58 automated, 0 requiring human judgment.**
`229-02` and `229-04` (authored before the `coverage:` convention) were given coverage blocks in
this verification pass, each ref executed and confirmed passing; `229-18` D2 was missing its
`human_judgment` flag and is corrected. `scripts/ci/verify_executable_uat_contract.mjs` — the
project-wide merge-blocking contract — passes for this phase.

### Test Quality Audit

No requirement-linked test is disabled. The three boundary clusters the prior report flagged as
absent (real-chain output/workspace/attestation mutation, invalid-UTF-8 final collection, and
completed-tree post-commit strict verification) all now exist as real-subprocess or
real-repository tests. The fixture blindness 229-20 identified — fixtures minting the capsule and
capturing the inventory at the same commit — is covered by a regression that advances the active
ref past the freeze first and whose negative control uses a same-tree root commit, so only the
ancestry check can reject it.

### Operating Constraint (not a gap)

Strict verification of the *published* real capsule is a point-in-time check, valid until the next
planning-document update. Two consequences, both verified directly and documented in
`.planning/STATE.md`:

1. Creating any new ref while this inventory is the active evidence fails strict verification with
   `extra=[<ref>]`; a recapture cannot rescue it because the frozen manifest also lacks the ref.
2. `.planning/STATE.md`, `MILESTONES.md`, and `WINDOWS.md` are pinned planning authorities. Only
   `.planning/milestone.lock` and `.planning/state.json` are permitted to move.

This is a property of a frozen recovery capsule, not unverified behavior: the *behavior* is
covered by fixture and real-chain tests that run without the private capsule.

### Deferred Items

None blocking. Two maintainer decisions remain recorded in `.planning/STATE.md` (pre-existing ref
names that embed a downstream adopter's product name — already public and predating this phase,
renaming them is remote mutation outside D-10; and the unpushed `fix/release-boot-env-resolver`
branch). Neither is Phase 229 scope.

### Gaps Summary

None. All twelve prior findings are closed with committed regression coverage, every suite is
green at this HEAD, and the deterministic suites are now wired into the merge-blocking
`docs-contracts-shift-left` CI job so this evidence re-runs on every push rather than existing
only as a local self-test.

---

_Verified: 2026-09-15_
_Method: direct execution of every referenced suite at HEAD_

---

## Re-verification — 2026-09-15T22:04:20Z (digest re-stamp)

**Why.** Phase 230 modified four files Phase 229 declared in `covered_files`, which invalidated the
prior `covered_digest` and routed Phase 229 to `stale`:

| File | Changed by |
|------|-----------|
| `scripts/ci/README.md` | `04e18145` (230-03), `d059a0e4` (230-06) |
| `scripts/ci/collect_repository_inventory.mjs` | `92f6eb12` (230-01) |
| `scripts/ci/preserve_repository_state.sh` | `92f6eb12` (230-01), `38dbe905` (230-01) |
| `scripts/ci/verify_repository_inventory.mjs` | `92f6eb12`, `939af6d3` (230-01), `e311e48f` (230-06) |

The staleness signal is drift in shared implementation files owned jointly with Phase 230 — not a
Phase 229 regression. Every current `*-PLAN.md` / `*-SUMMARY.md` in the phase directory (40 files)
is still represented in `covered_files`; no artifact was added after verification without coverage.

**Re-executed against current bytes — all PASS:**

| Gate | Result |
|------|--------|
| `node --test scripts/ci/ci_monitor.cjs` | 4/4 pass |
| `node --test scripts/ci/collect_repository_inventory.mjs` | 10/10 pass |
| `node --test scripts/ci/render_repository_inventory.mjs` | 1/1 pass |
| `node --test scripts/ci/verify_repository_inventory.mjs` | 5/5 pass |
| `node --test scripts/ci/phase229_gap_closure.test.mjs` | 21/21 pass |
| `bash scripts/ci/preserve_repository_state.sh --self-test` | PASS |
| `node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md` | PASS |
| `node scripts/ci/verify_phase229_handoff_invariants.mjs --self-test` | PASS (all 10 invariants) |
| `node scripts/ci/verify_repository_inventory.mjs --fixtures` + all eight strict flags | PASS |

Total: 41/41 unit tests, 4/4 self-test gates.

**Not re-executable in this session (recorded, not claimed).** UAT items 21 and 38 run the strict
verifier and `--run-final-chain` against the *real* private recovery capsule. Both require
maintainer-held values (`PHASE229_PRIVATE_MANIFEST`, `PHASE229_CAPSULE_DIR`) that are local-only by
design and absent from this environment; the command fails closed with
`--recovery-manifest requires a non-empty private manifest path`. Their original passing evidence
from the 2026-09-15T17:00:18Z run stands unchanged and is not re-asserted here. The 339
`refs/accrue-preserve/phase-229/*` preservation refs remain present in this checkout.

**Coverage note for follow-up.** `scripts/ci/collect_repository_inventory.mjs` and
`scripts/ci/preserve_repository_state.sh` now appear in Phase 229's `covered_files` but in *no*
Phase 230 verification report, despite Phase 230 having modified both. Phase 229's re-stamp covers
their current bytes; if Phase 230 is meant to own them going forward, its own coverage set should
be widened.
