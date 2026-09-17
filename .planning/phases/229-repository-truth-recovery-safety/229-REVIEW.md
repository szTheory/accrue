---
phase: 229-repository-truth-recovery-safety
reviewed: 2026-09-13T20:19:55Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - scripts/ci/README.md
  - scripts/ci/ci_monitor.cjs
  - scripts/ci/collect_repository_inventory.mjs
  - scripts/ci/phase229_gap_closure.test.mjs
  - scripts/ci/preserve_repository_state.sh
  - scripts/ci/render_repository_inventory.mjs
  - scripts/ci/verify_repository_inventory.mjs
  - scripts/ci/verify_phase229_handoff_invariants.mjs
  - scripts/ci/watch_ci.sh
findings:
  critical: 10
  warning: 2
  info: 0
  total: 12
status: issues_found
---

# Phase 229: Code Review Report

**Reviewed:** 2026-09-13T20:19:55Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

The second gap-closure cycle closes the prior pagination, provenance, privacy, CI deadline, and selected-run attribution findings in executable code. The complete advertised local suite is green: preservation self-test, collector 6/6, verifier 8/8, gap closure 24/24, monitor 4/4, wrapper/docs checks, and handoff self-test all passed.

That green suite is not sufficient to ship. The Nyquist failures are confirmed: raw symlink bytes are decoded during final collection, and the committed canonical active-ref evidence is stale after ordinary follow-up commits. The security audit's plural-provenance finding is also directly visible in the committed Markdown as three `undefined` request cells. Adversarial review found seven additional blocking boundaries, including an arbitrary-output overwrite primitive in the final safety wrapper, ignored workflow-metadata authorization, incomplete workspace protection, and permissive evidence schemas. Two test/authority weaknesses remain warnings.

## Narrative Findings (AI reviewer)

The committed inventory records active object `b48c7d8a...`, while live `HEAD` is `93ae7b98...`; strict recovery therefore deterministically rejects the completed tree. The committed Markdown renders `undefined` for Actions, pull-request, and release-branch request provenance. A direct schema probe deleted `remote_main.available`, set its state to `fabricated`, and still passed `validateInventory`, after which the renderer contradicted the retained SHA by printing `unavailable:undefined`. A full strict probe updated only the necessarily stale active SHA, replaced both planning digests with `fabricated`, and still exited 0. A real temporary-repository probe changed a tracked file between `snapshotWorkspace` calls and `assertExact` accepted it. Finally, a fresh injected post-manifest preservation failure exited 65 but left a new `refs/accrue-preserve/phase-229/*` ref behind, making a clean retry collide.

## Critical Issues

### CR-01: Final handoff output arguments can overwrite arbitrary files, including the recovery capsule

**Classification:** BLOCKER

**File:** `scripts/ci/verify_phase229_handoff_invariants.mjs:14-15,167-185`

**Issue:** `CANONICAL_RECORDS` and `CANONICAL_RENDERED` are declared but never enforced. Caller-controlled `--records` and `--rendered` are passed to two `writeFileSync`-based child commands. Supplying the private manifest, bundle, attestation destination, a capsule sibling, or any writable tracked/source path can truncate or replace it before the final comparison notices. Failure cleanup removes only an attestation created at the end, so the destructive write remains. This turns the purported safety gate into an arbitrary local-file overwrite primitive and can irreversibly corrupt the recovery authority it is supposed to protect.

**Fix:** Resolve both outputs without following a final symlink and require exact equality with `path.join(repo, CANONICAL_RECORDS)` and `path.join(repo, CANONICAL_RENDERED)`. Require distinct current-owner regular-file destinations under the verified repository, reject every capsule/authority/attestation alias or touching path before running children, and publish via validated temporary files plus atomic replacement. Add negative subprocess cases for manifest, bundle, capsule sibling, symlink, same-output, and non-canonical targets and prove zero mutation on every rejection.

### CR-02: Final collection hashes decoded symlink text instead of raw bytes

**Classification:** BLOCKER

**File:** `scripts/ci/collect_repository_inventory.mjs:161`

**Issue:** Preservation and the handoff attestation hash `fs.readlinkSync(..., { encoding: "buffer" })`, but `currentArtifact()` calls `fs.readlinkSync(full)` and hashes the decoded string. Invalid UTF-8 is replaced during decoding, so an unchanged link such as raw `ff fe 0a` disagrees with its frozen digest and final collection fails. This is NYQ-229-01 and breaks the promised byte-exact artifact identity.

**Fix:** Request `{ encoding: "buffer" }`, assert the result is a `Buffer`, hash it directly, and fail closed on an unsupported platform/read. Commit the generated-capsule end-to-end regression that preserves, attests, and collects one unchanged non-UTF-8 link.

### CR-03: Canonical active-ref evidence invalidates itself after normal commits

**Classification:** BLOCKER

**File:** `scripts/ci/verify_repository_inventory.mjs:146-157`

**Issue:** Strict verification requires `refs.milestone_branch` and the canonical active-ref row to equal the live active object. The wrapper captures and writes those values, but committing the canonical pair, plan summary, validation, security, or review necessarily advances the same branch. The current record contains `b48c7d8a...` while live `HEAD` is `93ae7b98...`, so the documented strict command cannot pass on the completed tree. This is NYQ-229-02, not incidental drift.

**Fix:** Define non-self-referential point-in-time authority: retain an explicit captured-at object that must exist and be an ancestor of the live active ref, bind the inventory bytes to a later attestation/commit, and continue requiring exact equality for every inactive frozen ref and preservation ref. Add a regression that commits the record and a later phase artifact before running strict verification.

### CR-04: Plural remote request provenance is discarded by the renderer

**Classification:** BLOCKER

**File:** `scripts/ci/render_repository_inventory.mjs:11-17`

**Issue:** Plural facts store `requests`, but every unavailable, empty, and populated row renders `value.request`. The committed Actions, PR, and release-branch rows consequently contain literal `undefined`, losing the ordered terminal-page evidence that produced the JSON. This confirms T-229-12, T-229-14, and T-229-G14-03.

**Fix:** Render the ordered `requests` array for plural categories in a deterministic escaped representation (and the singleton `request` only for `remote_main`). Add zero-, one-, many-, multi-page-, and unavailable-category assertions against both the rendered text and byte-reproduction verifier.

### CR-05: Supplemental workflow-metadata authorization is parsed but never applied

**Classification:** BLOCKER

**File:** `scripts/ci/collect_repository_inventory.mjs:132-180,378-382`

**Issue:** `artifactAuthorization` is independently parsed and structurally validated, then discarded. The actual permitted changes come solely from the unanchored final-capture attestation; the supplied authorization is never compared to the attestation or current hashes, and the final wrapper does not pass it at all. A valid authorization for unrelated before/after values therefore coexists with different accepted metadata changes, defeating the claimed separate authorization boundary.

**Fix:** Require the authorization for any workflow-metadata delta, open it with the same owner/mode/no-follow discipline as private authority, compare its exact path/type/before/after/state map to both the attestation and live snapshot, and reject omissions or extras. Make the wrapper accept and validate one fixed authorization input and cover mismatched, missing, symlinked, and broad-mode records.

### CR-06: The final workspace invariant omits tracked and index changes

**Classification:** BLOCKER

**File:** `scripts/ci/verify_phase229_handoff_invariants.mjs:64-103,167-188`

**Issue:** `snapshotWorkspace()` contains only untracked entries, refs, and worktree identities. It does not record tracked working-tree bytes, staged/index state, or Git status. A real probe modified a tracked file between snapshots and `assertExact("workspace", ...)` returned true. Any child test or malicious output argument can therefore rewrite tracked source/evidence while the final gate prints PASS; this also prevents enforcing the plan's rule that only the two canonical outputs may change.

**Fix:** Capture a NUL-safe tracked/index/worktree status authority and raw-byte identities for changed tracked paths before and after, permitting only the two exact canonical outputs and their expected content transition. Add real modifications for unstaged, staged, deleted, renamed, mode-changed, and newly tracked files around the actual wrapper chain.

### CR-07: The sole-attestation check accepts arbitrary content

**Classification:** BLOCKER

**File:** `scripts/ci/verify_phase229_handoff_invariants.mjs:116-133,186-188`

**Issue:** `assertOnlyAttestation()` verifies only path, type, mode, owner, and that the digest looks like 64 hex characters. It never checks the digest or parses the fixed record. The committed test demonstrates this by writing `{}` and accepting it as the sole attestation. A concurrent same-owner replacement after `createAttestation()` can therefore substitute arbitrary mode-0600 bytes while the gate passes, and the resulting record is not bound to the manifest, bundle, canonical JSON, Markdown, or snapshot.

**Fix:** Construct the exact canonical attestation bytes from anchored inputs, retain their expected SHA-256 from the exclusive descriptor write, and require exact digest/content/schema equality after publication. Include observed time plus manifest, bundle, records, rendered, and before-snapshot digests so the PASS is attributable; add post-create replacement and truncation probes.

### CR-08: Strict complete-category verification trusts fabricated planning digests

**Classification:** BLOCKER

**File:** `scripts/ci/verify_repository_inventory.mjs:255-263`

**Issue:** The verifier reconciles worktrees and ship windows but never hashes `.planning/MILESTONES.md` or `.planning/STATE.md`. After correcting only the stale active SHA in a temporary copy, replacing both planning fields with the literal `fabricated` still passed every documented strict flag. The collector computes these digests, but the independent verifier treats them as trusted caller input.

**Fix:** Independently compute the bounded file digest or exact `absent` marker for both paths and compare them to the inventory. Validate each field as either a lowercase SHA-256 or `absent`, and add missing, fabricated, swapped, stale, and changed-file probes.

### CR-09: Remote-fact validation accepts omitted availability and arbitrary states

**Classification:** BLOCKER

**File:** `scripts/ci/collect_repository_inventory.mjs:35-53,73-79`

**Issue:** `value.available !== false` treats a missing `available` field as available, and an available fact may carry any truthy `state`. `validateInventory()` discards the normalized return value, leaving the malformed original in place. A fact with no `available`, state `fabricated`, and a valid SHA passes validation; the renderer then treats it as unavailable and prints `unavailable:undefined`, contradicting the accepted SHA.

**Fix:** Require `available` to be exactly boolean. Require `state === "observed"` when true and `state === "unavailable"` when false, with the exact mutually exclusive SHA/reason fields. Either replace each fact with the normalized value or validate without coercive defaults. Add malformed missing/false/true/state cross-product fixtures through render and strict verification.

### CR-10: Failed preservation leaves new refs behind and its injected-failure test does not reach the injection

**Classification:** BLOCKER

**File:** `scripts/ci/preserve_repository_state.sh:104-113,196-234,386-390`

**Issue:** Preservation refs are created before bundle/artifact/manifest publication, but failure cleanup removes only files and scratch state. A fresh `PHASE229_TEST_FAIL_AFTER_MANIFEST=1` probe exited 65 with no outputs yet left a new preservation ref in the repository; a retry then collides. The self-test invokes the injected failure only after a successful run has already created the same refs, so it fails at the earlier collision and falsely claims to cover post-manifest cleanup.

**Fix:** Validate artifacts and build/verify all temporary authority before atomically creating preservation refs, or record exactly which refs this invocation created and roll them back transactionally only when their objects remain unchanged. Exercise each injected boundary on a fresh repository and assert outputs, refs, index, worktrees, and artifacts are identical after failure.

## Warnings

### WR-01: Final-invariant tests exercise comparators, not mutations around the real wrapper chain

**Classification:** WARNING

**File:** `scripts/ci/phase229_gap_closure.test.mjs:264-359`

**Issue:** The named "process-boundary" test launches only `--self-test`; that self-test mutates cloned row arrays. The real filesystem tests import snapshot helpers and compare them directly. None injects drift while `--run-final-chain` is executing, which is why arbitrary output destinations, tracked-file drift, and attestation substitution remain green.

**Fix:** Add controlled hooks available only to test-owned temporary repositories/capsules and launch the actual final-chain CLI for each mutation. Assert non-zero/no final PASS and exact post-failure state, rather than treating a comparator unit test as wrapper integration proof.

### WR-02: Standalone strict recovery follows bundle symlinks and ignores bundle ownership

**Classification:** WARNING

**File:** `scripts/ci/verify_repository_inventory.mjs:110-116`

**Issue:** `bundleMap()` uses `statSync`, so a symlink is accepted, and it does not require current-user ownership. The handoff wrapper applies stronger `lstat`/owner checks, but the README advertises the strict verifier independently. Digest equality protects object bytes, yet the standalone authority identity is weaker than documented and can change between reads.

**Fix:** Open the bundle with no-follow semantics where supported, require a current-owner regular file, hash through one descriptor, and use a stable descriptor-backed path or pre/post stat identity around Git verification. Add symlink, foreign-owner (where testable), and replacement-race fixtures.

---

_Reviewed: 2026-09-13T20:19:55Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
