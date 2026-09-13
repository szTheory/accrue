---
phase: 229-repository-truth-recovery-safety
reviewed: 2026-09-13T13:56:23Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - scripts/ci/README.md
  - scripts/ci/ci_monitor.cjs
  - scripts/ci/collect_repository_inventory.mjs
  - scripts/ci/preserve_repository_state.sh
  - scripts/ci/render_repository_inventory.mjs
  - scripts/ci/verify_repository_inventory.mjs
  - scripts/ci/watch_ci.sh
findings:
  critical: 10
  warning: 3
  info: 0
  total: 13
status: issues_found
---

# Phase 229: Code Review Report

**Reviewed:** 2026-09-13T13:56:23Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The recovery and observation implementation has multiple correctness and safety failures despite its green embedded fixtures. The most serious defects can destroy the just-created recovery bundle while still printing `PASS`, bypass the outside-repository capsule boundary through symlinked directories, produce shell-injectable restore commands, and certify an inventory that omits the live remote, worktree, and ship-window facts it claims to collect. The compatibility watcher's documented no-argument invocation also fails immediately.

## Narrative Findings (AI reviewer)

Targeted probes reproduced four failures: identical bundle/manifest paths return success but leave a non-bundle JSON file; a symlinked output directory places both supposedly external artifacts inside the repository; `--public-record-out` exits on an unbound variable after writing the bundle and private manifest; and `watch_ci.sh` with no arguments exits 64 before contacting GitHub. A generated bundle also does not contain the encoded preservation refs used by the rendered restore instruction. The shipped self-tests still report PASS for both the monitor and repository-inventory fixture suites.

## Critical Issues

### CR-01: Aliased output paths overwrite the verified recovery bundle while reporting success

**Classification:** BLOCKER

**File:** `scripts/ci/preserve_repository_state.sh:34-35,75-84`

**Issue:** The collision checks only test whether each path already exists; they never require `bundle_out`, `private_manifest_out`, and `public_record_out` to be distinct. Passing the same initially absent path for `--bundle-out` and `--private-manifest-out` creates and verifies the bundle, then overwrites it with JSON and prints `preserve repository state: PASS`. The same problem lets the optional public record overwrite either private artifact. This is a direct recovery-data-loss risk.

**Fix:** Canonicalize all three targets first, reject any pair that identifies the same path (and preferably the same inode after exclusive creation), and create outputs with exclusive-open semantics. Re-verify the final bundle only after every other output has been written.

### CR-02: Symlinked parent directories bypass the outside-repository recovery boundary

**Classification:** BLOCKER

**File:** `scripts/ci/preserve_repository_state.sh:29-36`

**Issue:** `within_repo` compares lexical paths only. An outside path whose parent is a symlink to the repository passes the check and writes the bundle and private manifest into the worktree. This violates the recovery barrier and allows later repository cleanup or mutation to destroy the only capsule.

**Fix:** Resolve the repository and each existing target parent to physical paths (`realpath`/`pwd -P`), reject parents inside the physical worktree, reject symlink path components where practical, and perform the final check against an opened parent directory before creating each file.

### CR-03: The documented public-record mode always crashes after partially succeeding

**Classification:** BLOCKER

**File:** `scripts/ci/preserve_repository_state.sh:75-83`

**Issue:** `BUNDLE_SHA256=... node ...` creates an environment assignment for that one process; it does not leave a shell variable for line 83. Under `set -u`, every invocation with `--public-record-out` terminates with `BUNDLE_SHA256: unbound variable` after the bundle and private manifest have already been created. The self-test omits this supported mode.

**Fix:** Assign a shell-local first, for example `local bundle_sha256; bundle_sha256="$(sha256 "$bundle_out")"`, pass that value to Node, and use the same local when writing the public record. Add a self-test that requests and validates the public record.

### CR-04: Private restore commands allow shell command substitution from valid Git ref names

**Classification:** BLOCKER

**File:** `scripts/ci/preserve_repository_state.sh:79`

**Issue:** Git permits ref names containing shell metacharacters such as `$()` and `;`, but `restore_command` interpolates the ref without quoting. A valid ref named `refs/custom/x$(touch_pwned)` produces `git update-ref refs/custom/x$(touch_pwned) <sha>`; executing the promised exact restore command runs attacker-controlled shell syntax.

**Fix:** Store restore operations as an argv array rather than an executable shell string, e.g. `{"argv":["git","update-ref",ref,object]}`. If a human-readable shell command is mandatory, apply a real POSIX shell-quoting routine to every argument and cover metacharacter-bearing valid refs in fixtures.

### CR-05: The compatibility watcher fails for its documented default invocation and no longer selects CI

**Classification:** BLOCKER

**File:** `scripts/ci/watch_ci.sh:6-12,23-34`

**Issue:** `branch` defaults to an empty string, so `bash scripts/ci/watch_ci.sh` passes neither `--branch` nor `--sha`; `ci_monitor.cjs` immediately exits 64 with `--sha must be a full lowercase 40-hex SHA`. Even with a positional branch, the wrapper no longer supplies `--workflow CI`, so it can resolve an unrelated workflow and then become ambiguous when `inspectSha` sees multiple runs for that SHA. It also dropped the old `gh run watch --exit-status` failure-exit behavior, so a completed failed run is reported with exit 0.

**Fix:** Default to `main`, add `--workflow CI` unless explicitly overridden, and preserve compatibility by returning non-zero when the selected completed run has a non-success conclusion. Exercise the no-argument, failed-run, and multi-workflow cases through an injected adapter instead of only regex-checking the wrapper.

### CR-06: `--observe-remote` performs no live observation and plural categories lose all but one SHA

**Classification:** BLOCKER

**File:** `scripts/ci/collect_repository_inventory.mjs:162-173`

**Issue:** The CLI calls `collectRepositoryInventory` without an adapter, so `--observe-remote` always emits four synthetic `unavailable` facts and never runs the required repository-bound GETs. If an adapter is injected programmatically, `remoteRead` extracts only the first PR, release branch, or Actions run SHA. Confirmed empty lists are misclassified as `data_shape` unavailable because the schema requires one primary `sha`. The resulting inventory cannot cover open PR heads, all release branches, or recent Actions runs as required.

**Fix:** Build a bounded, read-only `gh api` adapter in the CLI using `spawnSync` with `shell:false`, fixed `szTheory/accrue` endpoints, timeouts, buffers, and item/page limits. Normalize collection categories to `shas` arrays (including valid empty arrays), retain a single SHA only for singleton facts such as remote main, and render every normalized object ID.

### CR-07: The canonical inventory fabricates empty ship windows and records only the current worktree

**Classification:** BLOCKER

**File:** `scripts/ci/collect_repository_inventory.mjs:164-169`

**Issue:** `collectPlanningFacts` hard-codes `ship_windows: []`, and `collectRepositoryInventory` constructs exactly one worktree row from the current checkout. It never reads `.planning/WINDOWS.md`/the GSD window status and never runs `git worktree list --porcelain`. A repository with additional clean or dirty worktrees is therefore certified as complete while those worktrees are absent.

**Fix:** Collect bounded ship-window facts from the declared planning authority and parse every worktree from `git worktree list --porcelain`, omitting only absolute paths from public output. Determine each worktree's dirty state in that worktree and add multi-worktree/non-empty-window fixtures.

### CR-08: A recovery manifest from another repository is relabeled as `szTheory/accrue`

**Classification:** BLOCKER

**File:** `scripts/ci/collect_repository_inventory.mjs:63-81,165-169`

**Issue:** `readTrustedRecoveryManifest` validates the manifest digest, schema, refs, and bundle digest but never compares `manifest.repository` with `expectedRepository`. If the objects happen to exist locally, a capsule created for another repository can pass and the returned canonical inventory is labeled with the caller-supplied repository. This breaks provenance at the recovery boundary.

**Fix:** Pass the validated context into `readTrustedRecoveryManifest`, require an allowlisted `repository` field, and reject unless it exactly equals `context.expectedRepository` before bundle, artifact, or remote work begins.

### CR-09: The all-ref verification flag accepts any single claimed recovery row

**Classification:** BLOCKER

**File:** `scripts/ci/verify_repository_inventory.mjs:135-150`

**Issue:** `--require-all-ref-recovery` checks only `inventory.recovery.refs.length !== 0`; it neither compares original refs against the complete ref inventory nor verifies the external bundle or encoded refs. `--require-recovery` similarly trusts the already-required boolean, and several advertised strict flags add no flag-specific checks. A one-row fabricated recovery section with arbitrary well-formed digests can pass the command marketed as all-ref recovery verification.

**Fix:** Require the private manifest, independently anchored digest, and bundle for strict recovery verification; run bundle verification/list-heads and encoded-ref resolution, then compare the frozen original set against the expected non-preservation ref set. At minimum, make `--require-all-ref-recovery` prove set equality rather than non-emptiness and add a missing-one-of-many negative fixture.

### CR-10: Both rendered recovery commands are non-executable

**Classification:** BLOCKER

**File:** `scripts/ci/render_repository_inventory.mjs:23-24`

**Issue:** The bundle created by `preserve_repository_state.sh` contains original ref names, not `refs/accrue-preserve/phase-229/<encoded>` names, so the documented `git fetch "$PHASE229_BUNDLE" <encoded>:<original>` restore command fails with `couldn't find remote ref`. The preceding verification command also sets `PHASE229_BUNDLE` only as a command-prefix assignment while expanding `$PHASE229_BUNDLE` before that assignment takes effect, normally yielding an empty path.

**Fix:** Render commands that first assign/export the bundle variable, then verify it. Restore from the actual original bundle head (`<original-ref>:<original-ref>`) or fetch the object and use a safely represented `git update-ref` argv. Add an integration fixture that restores a deleted ref into a fresh repository using the exact rendered procedure.

## Warnings

### WR-01: Valid repository-relative filenames containing `..` are rejected

**Classification:** WARNING

**File:** `scripts/ci/preserve_repository_state.sh:66-68`

**Issue:** The path guard rejects any filename containing the substring `..`, including harmless names such as `release..notes`. This is stricter than the promised parent-traversal rejection and can prevent a recovery barrier on a valid repository.

**Fix:** Split on `/` and reject only path components exactly equal to `.` or `..`, matching the validator's normalized-relative-path logic.

### WR-02: The preservation self-test does not exercise the behaviors it claims to prove

**Classification:** WARNING

**File:** `scripts/ci/preserve_repository_state.sh:86-95`

**Issue:** The self-test never creates `refs/stash`, never requests a public record, never tests distinct/aliased output paths, and never tests a symlinked output parent. Consequently it reports PASS while CR-01 through CR-03 remain reproducible and while the phase acceptance text says stash recovery is proven.

**Fix:** Create an actual stash, assert every expected original name/object and bundle head, cover all supported output modes, and add negative cases for aliased targets and physical in-repository destinations.

### WR-03: Scratch directories containing private ref and artifact inventories are never cleaned up

**Classification:** WARNING

**File:** `scripts/ci/preserve_repository_state.sh:37-39,84-97`

**Issue:** Both production and self-test paths create private scratch directories and install no `EXIT` trap. Successful and failed runs leave ref names and untracked artifact paths in temporary storage indefinitely, and repeated runs accumulate stale data.

**Fix:** Install a trap immediately after `mktemp -d` that removes that exact validated scratch directory on every exit path; clear or scope the trap after explicit cleanup.

---

_Reviewed: 2026-09-13T13:56:23Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
