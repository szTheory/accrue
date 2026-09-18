---
phase: 229-repository-truth-recovery-safety
plan: 18
subsystem: infra
tags: [ci, repository-inventory, symlink, sha256, no-follow, workflow-metadata]
requires:
  - phase: 229-15
    provides: "Base repository inventory collector with manifest/attestation scaffolding"
provides:
  - "Raw-Buffer symlink hashing in the final artifact collector (no decode/dereference)"
  - "Mandatory workflow-metadata authorization bound exactly to attestation and to freshly derived manifest-to-live values"
  - "Hardened no-follow, current-owner, mode-0600, stable-identity reader shared by authorization and attestation inputs"
affects: [229-19, 229-20, repository-inventory-verification]
actuals:
  tokens: 6516
  tasks: 2
  commits: 4
plan_head_before: da1f8f9c41822f9ebf8619d99937ce356c0f53dd
commits: 4
tech-stack:
  added: []
  patterns: [raw-Buffer-only symlink digesting, three-authority exact-map reconciliation, bounded no-follow private JSON reader]
key-files:
  created: []
  modified:
    - scripts/ci/collect_repository_inventory.mjs
key-decisions:
  - "currentArtifact() requires fs.readlinkSync(..., { encoding: 'buffer' }) to return a real Buffer and hashes it directly; any non-Buffer result or read failure fails closed instead of falling back to string decoding."
  - "Workflow metadata authorization is required whenever the fixed two workflow paths (.planning/milestone.lock, .planning/state.json) change, and must be an exact sorted path/type/before/after/state map equal to both the final-capture attestation and an independently re-derived manifest-before/live-after transition."
  - "Authorization and attestation share one bounded private-JSON reader that opens with O_NOFOLLOW, requires current-effective-user ownership, requires mode 0600 or stricter, and re-verifies path/descriptor identity is unchanged before and after the read."
requirements-completed: [REPO-02]
coverage:
  - id: D1
    description: "Final artifact collection hashes raw symlink Buffer bytes (including invalid UTF-8 and trailing newline) without decoding, normalizing, or dereferencing; a one-byte drift or non-Buffer/failed read is rejected."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/ci/collect_repository_inventory.mjs#repository truth exposes sanitized worktree and ship-window collectors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Workflow-metadata changes are accepted only when authorization, final-capture attestation, and an independently derived manifest-to-live transition are exactly equal; stale, mismatched, missing, malformed, symlinked, foreign-owner, broad-mode, or replaced authorization/attestation inputs are rejected before any remote observation."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/ci/collect_repository_inventory.mjs#repository truth exposes sanitized worktree and ship-window collectors"
        status: pass
      - kind: integration
        ref: "scripts/ci/verify_repository_inventory.mjs#strict repository inventory flags enforce independent negative controls"
        status: pass
    human_judgment: false
duration: unknown (session continuation — see Issues Encountered)
completed: 2026-09-15
status: complete
---

# Phase 229 Plan 18: Byte-Exact Symlink Digests and Bound Workflow-Metadata Authorization Summary

**Symlink artifact collection now hashes only raw non-dereferenced Buffer bytes, and workflow-metadata changes are accepted only when a mandatory authorization file, the final-capture attestation, and an independently re-derived manifest-to-live transition are all byte-exact matches.**

## Performance

- **Duration:** unknown — implementation landed in a prior session that ran out of budget before writing this SUMMARY; this session verified and sealed the work rather than authoring it (see Issues Encountered).
- **Tasks:** 2
- **Files modified:** 1 (`scripts/ci/collect_repository_inventory.mjs`)

## Accomplishments

- `currentArtifact()` now calls `fs.readlinkSync(full, { encoding: "buffer" })`, asserts `Buffer.isBuffer(bytes)`, and hashes the raw bytes directly with no string conversion path — a non-Buffer return or read failure fails closed (`raw symlink read did not return a Buffer`).
- Added `readStablePrivateJson()`: a shared, bounded, no-follow (`O_NOFOLLOW`), current-owner, mode-0600-or-stricter, before/after stable-identity JSON reader used by both `readWorkflowMetadataAuthorization()` and `readFinalCaptureAttestation()`.
- `collectRepositoryInventory()` now requires `artifactAuthorization`, reads it, reads the final-capture attestation, and calls `assertExactWorkflowMetadataAuthority()` twice: once to bind attestation's workflow-metadata invariants to the authorization, and once to bind the authorization to freshly derived manifest-before/live-after values from `validateFinalArtifactSnapshot()`.
- `WORKFLOW_METADATA_PATHS` (`.planning/milestone.lock`, `.planning/state.json`) is the single fixed allow-list; `validateWorkflowMetadataChanges()` rejects any other path, duplicates, or a count other than exactly two everywhere it is invoked (authorization record, attestation record, and the live-derived transition).

## Task Commits

Both tasks landed in a prior session with intentional RED→GREEN TDD cycles; this session re-verified them rather than re-authoring:

1. **Task 1 RED: Reproduce decoded symlink drift** - `11c7a580`
2. **Task 1 GREEN: Hash raw symlink metadata bytes** - `7dcf5e0f`
3. **Task 2 RED: Expose unbound workflow authorization** - `79154278`
4. **Task 2 GREEN: Bind workflow authorization to attestation and live bytes** - `20f6695f`

## Files Created/Modified

- `scripts/ci/collect_repository_inventory.mjs` - Raw-Buffer symlink digesting plus the shared bounded no-follow private-JSON reader and three-authority workflow-metadata reconciliation.

## Decisions Made

- Confirmed (did not re-derive) the prior session's design: symlink hashing must never touch the string overload, decode, normalize, trim, or dereference — the `Buffer.isBuffer()` guard is the single enforcement point.
- Confirmed the exact-map reconciliation is genuinely two independent bindings (authorization↔attestation, authorization↔manifest/live), not one check reused twice — read `assertExactWorkflowMetadataAuthority()` call sites in `collectRepositoryInventory()` to verify this directly against the code rather than trusting the commit message alone.
- During this verification pass, re-confirmed (per the orchestrator's briefing) that commit `20f6695f` also tightened the attestation fixture in `verify_repository_inventory.mjs` to mode 0600 — this was necessary fixture-compliance so the older 0644 fixture would not be rejected by the newly hardened no-follow/owner/mode private-input reader, not an unplanned scope change.

## Deviations from Plan

None — plan executed exactly as written (by the prior session; this session found no genuine gap against the plan's acceptance criteria and made no code changes).

## Issues Encountered

**Session discontinuity:** A prior execution session implemented both tasks (commits `11c7a580`, `7dcf5e0f`, `79154278`, `20f6695f`) but exhausted its budget before writing this SUMMARY.md. This session was spawned specifically to verify the prior work independently rather than re-implement it:

- Re-ran `node --check scripts/ci/collect_repository_inventory.mjs && node --test scripts/ci/collect_repository_inventory.mjs` directly: **10/10 pass**, including `CR-02` (raw symlink) and `CR-05` (workflow-metadata authorization) coverage embedded in the `repository truth exposes sanitized worktree and ship-window collectors` test suite.
- Re-ran `node --test scripts/ci/verify_repository_inventory.mjs` directly: **4/4 pass**.
- Read `scripts/ci/collect_repository_inventory.mjs` at HEAD and confirmed line-by-line that every acceptance criterion in both tasks is genuinely implemented: the Buffer-only symlink guard, the bounded no-follow/owner/mode-0600/stable-identity private reader, the fixed two-path workflow-metadata allow-list, and the two independent `assertExactWorkflowMetadataAuthority()` bindings (attestation↔authorization, authorization↔manifest-and-live).
- Found no genuine gap between the plan's `must_haves` and the code at HEAD. No new commits were made in this session.

## User Setup Required

None.

## Next Phase Readiness

- CR-02 and CR-05 are closed; REPO-02's artifact-identity and workflow-metadata-authorization requirements for this collector are now byte-exact end to end.
- Plans 229-19 and 229-20 can build on a collector that fails closed on any decoded/dereferenced symlink read and on any unbound or stale workflow-metadata authorization.

## Self-Check: PASSED

- `scripts/ci/collect_repository_inventory.mjs` exists and contains the `readlinkSync(..., { encoding: "buffer" })` Buffer guard and the `readStablePrivateJson`/`assertExactWorkflowMetadataAuthority` implementations (confirmed via `grep` at HEAD).
- Commits `11c7a580`, `7dcf5e0f`, `79154278`, `20f6695f` are present in `git log` at HEAD.
- `node --test scripts/ci/collect_repository_inventory.mjs` → 10/10 pass (verified this session).
- `node --test scripts/ci/verify_repository_inventory.mjs` → 4/4 pass (verified this session).

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-15*
