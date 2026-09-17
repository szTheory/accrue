---
phase: 229-repository-truth-recovery-safety
plan: 19
subsystem: infra
tags: [ci, repository-inventory, handoff, transactional-publish, workflow-metadata-authorization, attestation]

requires:
  - phase: 229-16
    provides: "Base final-handoff wrapper (verify_phase229_handoff_invariants.mjs), capsule/workspace snapshot comparators"
  - phase: 229-17
    provides: "Later-commit capture authority; the `capture` field validateInventory now requires"
  - phase: 229-18
    provides: "readStablePrivateJson()/assertExactWorkflowMetadataAuthority() and the fixed WORKFLOW_METADATA_PATHS authorization input"
provides:
  - "CR-01: pre-write canonical-output authority pinning + exclusive-temp/atomic-rename/rollback transactional publish for the two canonical evidence files"
  - "CR-06: snapshotWorkspace() now captures raw git status/index bytes (snapshotIndexAndStatus), not just untracked/ref/worktree state"
  - "CR-07: the wrapper's collector call was missing the required --artifact-authorization option (a real, previously-untested bug); it's now derived internally and passed to both collector and strict verifier, and the handoff attestation is schema v2 with full digest bindings"
  - "WR-01: real `--run-final-chain` subprocess mutation tests (test-owned, token-gated hooks) replacing comparator-only confidence"
  - "verify_repository_inventory.mjs: --artifact-authorization cross-check + --handoff-attestation/--require-handoff-attestation independent binding verification"
affects: [229-20, repository-inventory-verification, phase229-final-handoff]

actuals:
  tokens: 46000
  tasks: 2
  commits: 5

plan_head_before: cd58a48d

tech-stack:
  added: []
  patterns:
    - "exclusive same-directory temp + atomic dual-rename publish with pre-existing-bytes backup and exact rollback on any downstream failure"
    - "git status/ls-files pathspec exclusion (:(exclude,glob)) to let an operation's own expected canonical-output writes pass an otherwise byte-exact workspace invariant"
    - "test-owned marker file (.phase229-test-owned in both repo and capsule roots) + matching env-var token gates a mutation hook that is otherwise unreachable from a real invocation"

key-files:
  created: []
  modified:
    - scripts/ci/verify_phase229_handoff_invariants.mjs
    - scripts/ci/verify_repository_inventory.mjs
    - scripts/ci/phase229_gap_closure.test.mjs
    - scripts/ci/README.md
    - scripts/ci/preserve_repository_state.sh

key-decisions:
  - "Task 1's canonical-output pinning is enforced by requiring the CLI --records/--rendered arguments to equal the CANONICAL_RECORDS/CANONICAL_RENDERED string constants exactly (not merely resolve to the same path), then independently lstat/device/inode-checking the resolved absolute paths against the capsule directory, recovery manifest, recovery bundle, and attestation destination before any write."
  - "The collector/renderer now write into `<canonical>.phase229-tmp-<pid>` same-directory temporaries; strict verification runs against those temporaries BEFORE publish (matching the plan's 'prepublication checks' requirement), and publish is a genuine two-file transaction with byte-exact rollback of the prior pair (or removal, if absent) on any later failure."
  - "Chose git pathspec exclusion (`:(exclude,glob)`) over manual NUL-record parsing to keep the two canonical output paths (and their temp/backup name variants) out of the workspace status/index snapshot. This lets the byte-exact workspace invariant stay genuinely exact for everything else while not self-triggering on the operation's own expected writes - simpler and more robust than diffing parsed status lines."
  - "Dropped the `stat.gid !== process.getegid()` pin in createAttestation/assertOnlyAttestation. BSD/macOS assigns a newly created file's group from its parent directory, not the creating process's primary egid, so this pin made `--run-final-chain` fail on every macOS run - including a fully valid one - the very first time it was actually exercised end-to-end (see Issues Encountered). Mode 0600 + UID ownership is the real access-control boundary; GID is still captured in snapshots for drift detection, just no longer required to equal a specific value."
  - "A `--run-final-chain` invocation whose repository AND capsule roots both contain a `.phase229-test-owned` marker file skips re-running this file's own meta self-tests (preservation/collector/gap-closure/inventory-verifier/monitor self-tests). Without this, the new WR-01 real-chain test - which lives inside phase229_gap_closure.test.mjs and spawns `--run-final-chain` - would cause that same process to re-spawn `node --test phase229_gap_closure.test.mjs` as one of its own self-test steps, recursively re-running (and re-spawning) itself. Real invocations (no marker files) are unaffected and always run every self-test; the marker is a no-op for production capsules."
  - "The mutation-hook gate requires BOTH a `PHASE229_TEST_MUTATION_TOKEN` env var match AND a `.phase229-test-owned` file (containing that same token) present in both the repository and capsule roots - not just the env var alone. Verified experimentally: a mismatched token against a real fixture produces a normal, unmutated PASS run (see Issues Encountered)."

requirements-completed: [REPO-01, REPO-02]

coverage:
  - id: D1
    description: "The final handoff wrapper rejects a manifest/bundle/capsule/attestation alias, symlink, hardlink, or non-canonical --records/--rendered argument before any output, temp, snapshot, or attestation write, and publishes the real canonical pair only via an exclusive-temp + atomic-rename transaction with exact rollback on any failure."
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/ci/phase229_gap_closure.test.mjs#WR-01 real final-chain subprocess proves canonical publication, attestation binding, and exact rollback around the actual mutation boundaries"
        status: pass
    human_judgment: false
  - id: D2
    description: "snapshotWorkspace captures complete NUL-safe git status/index bytes in addition to untracked/ref/worktree/tracked-symlink identity, and only the two canonical output paths are permitted to change across the real final-chain process; every other tracked/untracked/index/status byte, ref, tag, or worktree drift fails the process and leaves no partial attestation or canonical bytes."
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/ci/verify_phase229_handoff_invariants.mjs --self-test (index/status invariants)"
        status: pass
      - kind: unit
        ref: "scripts/ci/phase229_gap_closure.test.mjs#WR-01 real final-chain subprocess proves canonical publication, attestation binding, and exact rollback around the actual mutation boundaries (unstaged/staged/add/delete/rename/mode/ref/worktree/untracked cases)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The wrapper derives and passes the fixed workflow-metadata authorization to both the collector and the strict verifier (previously missing entirely, so --run-final-chain could never complete against a real capsule); the schema-2 handoff attestation binds exact capture/manifest/bundle/authorization/collection-attestation/records/rendered/before-snapshot digests, independently reverifiable via verify_repository_inventory.mjs --require-handoff-attestation."
    requirement: REPO-02
    verification:
      - kind: unit
        ref: "scripts/ci/phase229_gap_closure.test.mjs#WR-01 real final-chain subprocess proves canonical publication, attestation binding, and exact rollback around the actual mutation boundaries"
        status: pass
      - kind: unit
        ref: "scripts/ci/verify_repository_inventory.mjs#strict repository inventory flags enforce independent negative controls"
        status: pass
    human_judgment: false
  - id: D4
    description: "Two pre-existing shared adversarial fixtures (strictVerifierFixture, documentedStrictFixture) were missing the `capture` field 229-17 made required, and strictVerifierFixture never chmod'd its bundle to 0600, both silently masking CR-04/CR-05/CR-06/CR-07/CR-08. Both are fixed."
    requirement: REPO-02
    verification:
      - kind: unit
        ref: "scripts/ci/phase229_gap_closure.test.mjs (CR-04, CR-05, CR-06, CR-07, CR-08)"
        status: pass
    human_judgment: false

duration: unknown (single continuous session)
completed: 2026-09-15
status: complete
---

# Phase 229 Plan 19: Transactional Final Handoff + Real-Chain Mutation Proof Summary

**The Phase 229 final-handoff wrapper now pins canonical output paths before any write, publishes the committed inventory pair as a true exclusive-temp/atomic-rename transaction with exact rollback, captures raw git status/index bytes in its workspace invariant, and is proven — via a real `--run-final-chain` subprocess, not comparator-only assertions — to fail closed and leave zero partial state across eleven distinct real mutation boundaries.**

## Performance

- **Tasks:** 2
- **Files modified:** 5 (4 planned + `preserve_repository_state.sh`, a documented deviation — see below)
- **Commits:** 5 (measured: `git rev-list --count cd58a48d..HEAD`)

## Accomplishments

- **CR-01 (pre-write pinning + transactional publish):** `resolveCanonicalOutputs()` requires the caller's `--records`/`--rendered` to equal the fixed `CANONICAL_RECORDS`/`CANONICAL_RENDERED` constants, then independently lstat/device-inode checks the resolved absolute paths against the capsule directory, recovery manifest, recovery bundle, and attestation destination — rejecting any symlink, hardlink, same-file, or authority alias before any write. The collector and renderer now write into exclusive same-directory `*.phase229-tmp-<pid>` temporaries, are strictly verified there, then `publishCanonicalPair()` performs a genuine two-file atomic-rename transaction: prior bytes are backed up first, and any failure (including a failure of only the second rename) restores the exact prior pair (or absence) and removes only invocation-owned temps/backups.
- **CR-06 (complete workspace invariants):** Added `snapshotIndexAndStatus()`, capturing raw NUL-safe `git status --porcelain=v2` and `git ls-files -s` output into the workspace snapshot alongside the existing untracked/ref/worktree identities — so unstaged, staged, add, delete, rename, mode, and index-only drift are now caught byte-exact. The two canonical output paths (and their temp/backup name variants) are excluded from these snapshots via `git`'s `:(exclude,glob)` pathspec so the operation's own expected writes don't self-trigger the invariant while everything else stays exact.
- **CR-07 (mandatory workflow authorization + attestation v2):** Discovered and fixed a real, previously-untested bug: the wrapper's collector call never passed `--artifact-authorization`, which `collect_repository_inventory.mjs`'s `main()` has required since Plan 229-18 — meaning `--run-final-chain` could never actually complete against a real capsule before this plan. `writeWorkflowMetadataAuthorization()` now derives the authorization record from the same final-capture attestation the wrapper already builds and passes it to both the collector and the strict verifier. The handoff attestation is now schema v2, binding exact `capture` (ref/commit), `manifest_sha256`, `bundle_sha256`, `authorization_sha256`, `collection_attestation_sha256`, `records_sha256`, `rendered_sha256`, `before_capsule_digest`, and `before_workspace_digest`.
- **WR-01 (real-chain mutation proof):** `verify_repository_inventory.mjs` gained `assertHandoffAttestation()` (`--handoff-attestation`/`--require-handoff-attestation`) and an authorization cross-check (`--artifact-authorization`) that independently recompute every one of those bindings. `phase229_gap_closure.test.mjs` gained `finalChainFixture()`/`runFinalChainCli()`, which build a disposable repo+capsule via the actual `preserve_repository_state.sh` and spawn the actual `verify_phase229_handoff_invariants.mjs --run-final-chain` process. The new test proves: a clean run publishes both canonical outputs and a valid schema-2 attestation; a mismatched mutation token never fires (normal PASS); and eleven real mutations (unstaged, staged, add, delete, rename, mode, ref, worktree, untracked, before-publish capsule tamper, before-attestation capsule tamper) each fail the real subprocess with no `PASS` output and leave no newly published canonical records, rendered Markdown, or attestation.
- **Fixed pre-existing fixture debt (flagged in dependency_state):** Two shared adversarial fixtures (`strictVerifierFixture`, `documentedStrictFixture`) were missing the `capture` field 229-17 made required — this was silently masking CR-04, CR-07, and CR-08 (outright failures) and CR-05/CR-06 (passing for the wrong reason, since their "must fail" assertions were trivially satisfied by the unrelated missing-field error). Added the required `capture` block to both. `strictVerifierFixture` also never `chmod`'d its `git bundle create` output to 0600 (a second, previously-undiscovered bug in the same fixture) — fixed.

## Task Commits

1. **Fixture-debt / blocking-issue fix:** `011ec3bd` — `fix(229-19): mode-0600 the recovery bundle temp before publish` (`preserve_repository_state.sh` — see Deviations)
2. **Task 1 (CR-01) + Task 2 (CR-06, CR-07, WR-01) wrapper implementation:** `165f5c57` — `feat(229-19): pin canonical handoff outputs and bind the real final chain`
3. **Task 2 (strict-verifier independent binding checks):** `c72c380c` — `feat(229-19): independently verify workflow authorization and handoff attestation bindings`
4. **Task 1+2 fixture repair + WR-01 real-chain test:** `bbc3212a` — `test(229-19): repair fixture debt and add a real-chain WR-01 mutation matrix`
5. **README:** `d95ef20d` — `docs(229-19): document canonical pinning, transactional publish, and attestation v2`

## Files Created/Modified

- `scripts/ci/verify_phase229_handoff_invariants.mjs` — pre-write canonical-output pinning, transactional publish, extended workspace invariants (index/status), internal workflow-authorization derivation, schema-2 attestation, test-owned mutation hooks.
- `scripts/ci/verify_repository_inventory.mjs` — `readStableJson()`, authorization cross-check, `assertHandoffAttestation()` + new CLI flags.
- `scripts/ci/phase229_gap_closure.test.mjs` — fixture `capture`/bundle-permission fixes, self-test invariant-name update, new WR-01 real-chain mutation test.
- `scripts/ci/README.md` — documents the new pinning/publish/attestation-v2 behavior and the new independent strict-verifier flags.
- `scripts/ci/preserve_repository_state.sh` — bundle-temp mode-0600 fix (deviation, see below).

## Decisions Made

See `key-decisions` in frontmatter for the six substantive design decisions (canonical-path equality pinning, temp+publish transaction shape, pathspec exclusion over manual status parsing, dropping the GID pin, the test-owned self-test recursion guard, and the two-factor mutation-hook gate).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `git bundle create` silently resets its output to mode 0644, breaking every downstream mode-0600 private-authority check**
- **Found during:** Task 2, while proving WR-01's `--run-final-chain` end-to-end for the first time
- **Issue:** `preserve_repository_state.sh` creates its bundle temp via `mktemp` (mode 0600 by default), then runs `git -C "$repo_root" bundle create "$bundle_tmp" ...` — but `git bundle create` opens its output with the process umask, silently widening the file back to 0644 before `publish_exclusive` moves it to the final bundle path. Every private-authority reader in this phase (`bundleMap` in `verify_repository_inventory.mjs`, the wrapper's `validateAuthority`) requires bundle mode 0600-or-stricter, so this bug meant the actual maintainer-facing preservation script has never produced a bundle that its own downstream tooling would accept.
- **Fix:** `chmod 600 "$bundle_tmp"` immediately after `git bundle create`, before `refresh_temporary_output_identity` snapshots the temp's stable identity for the rest of the script's integrity checks.
- **Files modified:** `scripts/ci/preserve_repository_state.sh`
- **Verification:** `bash scripts/ci/preserve_repository_state.sh --self-test` passes; manually confirmed the bundle is 0600 after a real (non-self-test) preservation run.
- **Committed in:** `011ec3bd`

**2. [Rule 1 - Bug] `git bundle create` also reset mode on the same fixture inside `phase229_gap_closure.test.mjs`'s `strictVerifierFixture()`**
- **Found during:** Task 2, chasing CR-04/CR-07/CR-08 failures after fixing the missing `capture` field
- **Issue:** Same root cause as #1, in a second, independent call site (this test fixture builds its own bundle via `spawnSync("git", ["bundle", "create", ...])` without a chmod).
- **Fix:** Added `fs.chmodSync(bundle, 0o600)` immediately after bundle creation.
- **Files modified:** `scripts/ci/phase229_gap_closure.test.mjs`
- **Verification:** CR-04/CR-05/CR-06/CR-07/CR-08 all pass for their actually-intended reason (confirmed by reading each failure message before and after the fix, not just the exit code).
- **Committed in:** `bbc3212a`

**3. [Rule 1 - Bug] `stat.gid !== process.getegid()` pin made the wrapper non-functional on macOS for a fully valid run**
- **Found during:** Task 1/2, first successful `--run-final-chain` dry run
- **Issue:** BSD/macOS assigns a newly created regular file's group from its parent directory (not the creating process's primary egid). Every scratch directory created in this sandbox inherited group `wheel` (gid 0) regardless of the shell's primary group (`staff`, gid 20), so `createAttestation`'s `stat.gid !== process.getegid()` check failed on the very first genuinely valid, unmutated chain — a correctness bug, not a security gap (mode 0600 + UID ownership is the actual access-control boundary; the GID literal adds nothing once group/other bits are zero).
- **Fix:** Dropped the GID equality requirement from `createAttestation` and `assertOnlyAttestation`'s default-added-entry check; GID is still captured in snapshots for later drift comparison, just no longer pinned to a specific expected value.
- **Files modified:** `scripts/ci/verify_phase229_handoff_invariants.mjs`
- **Verification:** `--self-test` passes; a real `--run-final-chain` dry run against a hand-built fixture now reaches `phase229 final handoff invariants: PASS`.
- **Committed in:** `165f5c57`

**4. [Rule 1 - Bug, discovered via Rule 3 investigation] `--run-final-chain` was missing the required `--artifact-authorization` collector argument**
- **Found during:** Task 2, first attempted real dry run of `--run-final-chain`
- **Issue:** `collect_repository_inventory.mjs`'s `main()` has required `--artifact-authorization` since Plan 229-18, but the wrapper's collector `runStep` call never supplied it — meaning the documented `--run-final-chain` command has never actually succeeded against a real capsule since 229-18 landed. This is exactly the CR-07 gap this plan was scoped to close.
- **Fix:** `writeWorkflowMetadataAuthorization()` derives the authorization record from the wrapper's own final-capture attestation and the derived path is passed to the collector via `--artifact-authorization`.
- **Files modified:** `scripts/ci/verify_phase229_handoff_invariants.mjs`
- **Verification:** Real `--run-final-chain` dry run reaches PASS; `WR-01 real final-chain subprocess...` test in `phase229_gap_closure.test.mjs` exercises this path end-to-end.
- **Committed in:** `165f5c57`

---

**Total deviations:** 4 auto-fixed (1 Rule 3 blocking, 3 Rule 1 bugs — all discovered only because this plan required, for the first time, actually running `--run-final-chain` as a real subprocess rather than testing its exported comparators in isolation)
**Impact on plan:** All four were pre-existing defects in files this plan's implementation depends on (`preserve_repository_state.sh` bundle mode, the shared test fixture's bundle mode, GID portability, and the missing collector argument). None were speculative additions; each was a genuine blocker discovered while proving WR-01's real-chain requirement, and each was verified fixed before continuing. No scope creep beyond what was necessary to get `--run-final-chain` to actually run.

## Issues Encountered

- **`preserve_repository_state.sh --repo-root`/private-input recursion risk:** the new WR-01 test lives inside `phase229_gap_closure.test.mjs`, and `--run-final-chain` itself re-runs `phase229_gap_closure.test.mjs` as one of its own meta self-test steps. Without a guard, the real-chain test would cause its own host process to recursively re-spawn itself. Resolved by gating those meta self-test `runStep` calls behind a `testOwned` check (both the repository and capsule roots contain a `.phase229-test-owned` marker, present only in disposable test fixtures never in a real capsule) — real invocations are unaffected.
- **`ci_monitor.cjs --self-test --verify-wrapper ...` hangs in this sandbox:** independently reproduced (identical hang running the command directly, outside any of my changes, from the real repo root) that the `#!/usr/bin/env node` shebang on this self-test's fake-`gh` fixture script hangs indefinitely under this sandbox's asdf-shimmed `node`, timing out at the self-test's internal 30s GitHub-read bound. Confirmed pre-existing and unrelated to this plan's files (out of scope per the deviation rules' scope boundary); the `testOwned` skip above also avoids exercising this specific self-test from the new WR-01 test, so it does not block this plan's proof, but it remains a real environmental gap worth a maintainer's attention if `--run-final-chain` is ever run under a similarly asdf-shimmed `node` in CI.

## User Setup Required

None.

## Next Phase Readiness

- CR-01, CR-06, CR-07, and WR-01 are closed. `--run-final-chain` now actually completes end-to-end (verified via a real subprocess, not just self-test comparators) and is proven, via eleven distinct real mutation boundaries, to fail closed with zero partial canonical/attestation state.
- Plan 229-20 (if scoped against this wrapper) can rely on: canonical output paths being pinned and alias-rejected before any write; the two-file publish being a genuine atomic transaction; the workspace invariant covering raw git status/index bytes; and the schema-2 handoff attestation being independently re-verifiable via `verify_repository_inventory.mjs --require-handoff-attestation`.
- The `ci_monitor.cjs --verify-wrapper` sandbox hang (Issues Encountered) is a real, reproducible environmental gap unrelated to this plan's scope — flagging for whoever next touches `ci_monitor.cjs` self-tests or CI's own `node` toolchain configuration.

## Self-Check: PASSED

- `scripts/ci/verify_phase229_handoff_invariants.mjs`, `scripts/ci/verify_repository_inventory.mjs`, `scripts/ci/phase229_gap_closure.test.mjs`, `scripts/ci/README.md`, `scripts/ci/preserve_repository_state.sh` all exist and contain the described changes (confirmed via `git show` at each commit).
- Commits `011ec3bd`, `165f5c57`, `c72c380c`, `bbc3212a`, `d95ef20d` are present in `git log` at HEAD.
- `node --test scripts/ci/phase229_gap_closure.test.mjs` → 19/19 pass (includes the new WR-01 real-chain test).
- `node --test scripts/ci/verify_repository_inventory.mjs` → 4/4 pass.
- `node --test scripts/ci/collect_repository_inventory.mjs` → 10/10 pass (no regression).
- `node scripts/ci/verify_phase229_handoff_invariants.mjs --self-test` → PASS (including new index/status invariants).

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-15*
