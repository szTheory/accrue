---
phase: 230-reviewable-history-integration
plan: 01
subsystem: infra
tags: [git, preservation, ref-continuity, evidence, ci]

requires:
  - phase: 229-repository-truth-recovery-safety
    provides: refs/accrue-preserve/phase-229/<hex> preservation namespace, verify_repository_inventory.mjs strict verification, collect_repository_inventory.mjs collect/validate pair, the published 229-REPOSITORY-INVENTORY.json frozen ref authority
provides:
  - Phase-parameterized preservation ref namespace across preserve_repository_state.sh, collect_repository_inventory.mjs, verify_repository_inventory.mjs (default "229", unchanged behavior)
  - An out-of-repo Phase-230 safety capsule whose bundle heads include the live milestone tip (closes D-25)
  - assertTypedRefContinuity: a three-way typed ref partition (owned/remote_tracking/preservation) gated by --require-typed-ref-continuity and --ref-exceptions
  - .planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json declared-additions ledger
affects: [230-later-plans, 231-exact-sha-release-gate-proof, 232-bounded-hygiene-release-handoff]

actuals:
  tokens: 17027
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Phase-parameterized preservation ref namespace: preservationPrefix(phase) exported once from collect_repository_inventory.mjs, imported by verify_repository_inventory.mjs, --preservation-phase threaded through preserve_repository_state.sh (default 229)."
    - "Typed ref continuity: partition every ref by ontology (owned/remote_tracking/preservation) before comparing; only the comparison operator changes per class, missing=[] stays absolute for all three."
    - "Declared-additions ledger: two-sided exact multiset equality (assertSameMultiset) against the live owned-class addition set only -- undeclared fails, declared-but-absent also fails."

key-files:
  created:
    - .planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json
  modified:
    - scripts/ci/preserve_repository_state.sh
    - scripts/ci/collect_repository_inventory.mjs
    - scripts/ci/verify_repository_inventory.mjs

key-decisions:
  - "Preservation refs under refs/accrue-preserve/phase-<N>/ are excluded from the set of refs a mint re-preserves (Rule 1/3 bug fix) -- a real repository with a prior phase's preservation refs already present would otherwise try to double-hex-encode a preservation ref name and blow the filesystem loose-ref path limit."
  - "The typed 'owned' class gives the active local branch the same ancestry-not-equality leniency assertCapturedRefContinuity already established for the single hardcoded active ref -- exact equality on a branch that advances every task commit would make the gate permanently red, which D-26 explicitly rejects."
  - "The 'preservation' class's extra (new) refs are unconditionally legitimate with no declared-addition row required -- new refs from a later phase's capsule are the entire point of the phase-parameterized prefix. missing=[] and changed=[] stay absolute for frozen preservation refs; only 'extra' is exempt."
  - "The declared-additions ledger's exact-multiset assertion is scoped to the 'owned' class only. remote_tracking movement is bounded by ancestry and documented in the ledger for audit trail (D-00a) but is never required by the gate -- a ledger row must never excuse a ref that changed value, only record one that is genuinely new (prohibitions clause)."

requirements-completed: [INTG-03]

coverage:
  - id: D1
    description: "Phase-parameterized preservation ref namespace across all three call sites, default 229, published Phase 229 evidence unaffected"
    requirement: "INTG-03"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/collect_repository_inventory.mjs"
        status: pass
      - kind: unit
        ref: "node --test scripts/ci/verify_repository_inventory.mjs"
        status: pass
      - kind: integration
        ref: "bash scripts/ci/preserve_repository_state.sh --self-test"
        status: pass
      - kind: integration
        ref: "bash scripts/ci/preserve_repository_state.sh --preservation-phase 'not a phase' ... (rejects invalid phase, exit 65, no ref created)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Out-of-repo Phase-230 safety capsule minted, bundle heads include the live milestone tip and all four closure commits, 0600 mode, stripe-fixture scripts recorded by sha256"
    requirement: "INTG-03"
    verification:
      - kind: integration
        ref: "git bundle verify $PHASE230_SAFETY_BUNDLE && git bundle list-heads | grep -qF $(git rev-parse HEAD-at-mint-time)"
        status: pass
      - kind: integration
        ref: "git merge-base --is-ancestor {8a95fbe8,9e090eb5,7cc501a3,57c61a9a} <bundle head>"
        status: pass
      - kind: integration
        ref: "stat -f '%OLp' on bundle and private manifest == 600"
        status: pass
    human_judgment: false
  - id: D3
    description: "Typed ref continuity (owned/remote_tracking/preservation) and the 230-REF-EXCEPTIONS.json declared-additions ledger, asserted by two-sided exact multiset equality"
    requirement: "INTG-03"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_repository_inventory.mjs (typed ref continuity partitions owned/remote-tracking/preservation refs correctly)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-typed-ref-continuity [+ all other --require-* flags]"
        status: pass
      - kind: integration
        ref: "node -e assertTypedRefContinuity(...) against the real committed 229-REPOSITORY-INVENTORY.json, live refs, and 230-REF-EXCEPTIONS.json -- returns true; empty ledger fails with extra=[...]"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-15
status: complete
---

# Phase 230 Plan 01: Phase-Parameterized Preservation + Typed Ref Continuity Summary

**Closed the Phase 229 out-of-repo preservation gap (D-25), phase-parameterized the preservation ref namespace so a Phase-230 capsule cannot collide with or invalidate Phase 229's evidence, and replaced the unsatisfiable exact-equality-over-all-refs gate with a typed ref-ontology partition plus a bounded, two-sided declared-additions ledger.**

## Performance

- **Duration:** ~50 min
- **Tasks:** 3
- **Files modified:** 4 (3 modified, 1 created)
- **Commits:** 3 task commits

## Accomplishments

- `preservationPrefix(phase)` and `isPreservationRef(name)` exported once from `scripts/ci/collect_repository_inventory.mjs`, imported by `scripts/ci/verify_repository_inventory.mjs`; `--preservation-phase` threaded through all three call sites (`preserve_repository_state.sh`, both `.mjs` scripts), defaulting to `"229"` everywhere so the published Phase 229 evidence keeps verifying unchanged.
- Minted an out-of-repo Phase-230 safety capsule (bundle + 0600 private/public manifests, in the session scratchpad, never committed) whose bundle heads include the live milestone tip and all four audit-closure commits (`8a95fbe8`, `9e090eb5`, `7cc501a3`, `57c61a9a`); the two untracked stripe-fixture scripts are recorded by sha256 in its artifact manifest.
- Added `assertTypedRefContinuity` to `verify_repository_inventory.mjs`, gated by `--require-typed-ref-continuity` / `--ref-exceptions`: partitions every ref into `owned` (exact equality + declared additions + active-branch ancestry leniency), `remote_tracking` (ancestry-only, non-fast-forward always fails), and `preservation` (missing/changed absolute, new-phase extras unconditionally legitimate).
- Created `.planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json` (6 rows) and verified end-to-end against the *real* committed `229-REPOSITORY-INVENTORY.json` and live repository state — `assertTypedRefContinuity` returns `true`.

## Task Commits

1. **Task 1: Phase-parameterize the preservation ref namespace across all three call sites** - `92f6eb12` (feat)
2. **Task 2: Mint the Phase-230 safety capsule (+ Rule 1/3 fix for re-preservation collision)** - `38dbe905` (fix)
3. **Task 3: Typed ref continuity and the declared-additions ledger** - `939af6d3` (feat)

_No separate plan-metadata commit was made yet; this SUMMARY and STATE/ROADMAP updates land in the final metadata commit per the executor protocol._

## Files Created/Modified

- `scripts/ci/preserve_repository_state.sh` - `--preservation-phase` option (validated, default 229), `preservation_prefix()` helper, excludes existing preservation refs from re-preservation
- `scripts/ci/collect_repository_inventory.mjs` - exports `preservationPrefix(phase)` and `isPreservationRef(name)`; `validateRecovery`/`readTrustedRecoveryManifest`/`collectRepositoryInventory` thread a `preservationPhase` parameter (default `"229"`)
- `scripts/ci/verify_repository_inventory.mjs` - imports the shared prefix helper; `assertTypedRefContinuity` (new), `readRefExceptions`/`readCommittedJson` (new), typed-partition fixtures; `--preservation-phase`, `--ref-exceptions`, `--require-typed-ref-continuity` CLI wiring
- `.planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json` - declared-additions ledger (6 rows: PR #44 branch, three Release Please 1.5.1 tags, two documentary `origin/*` fast-forward rows)

## Decisions Made

- **Active-branch ancestry leniency in the "owned" class.** The plan's text describes `owned` as pure "exact equality plus declared additions," but the active milestone branch advances on every task commit within this same plan. Applying strict exact equality would make the gate fail immediately after Task 1's own commit — exactly the "permanently red gate" D-26 explicitly rejects. Gave the active ref (from `inventory.capture.active_ref`) the same ancestry-not-equality treatment `assertCapturedRefContinuity` already established for the old single hardcoded active ref. Verified this does not weaken the gate for any other owned ref (every other branch and every tag stays exact).
- **Preservation-class extras need no ledger declaration.** D-31/D-27's stated purpose for phase-parameterizing the prefix is precisely so a later phase's capsule "cannot self-invalidate" earlier evidence — read literally, that means new preservation refs from any later phase are unconditionally legitimate, not merely ancestry-relaxed. Implemented `missing=[]`/`changed=[]` absolute for preservation (a frozen preservation ref must stay present and unchanged) but no `extra` check at all. This is why the ledger has 6 rows instead of the 114 individual phase-230 preservation refs minted in Task 2 — declaring each would be both impractical and contrary to the design's stated intent.
- **remote_tracking ledger rows are documentary, not load-bearing.** The gate's declared-additions multiset assertion (`assertSameMultiset`) is scoped to the `owned` class only, matching the prohibitions clause ("must not relax a failing continuity check by adding a waiver row instead of fixing the comparison semantics"). The two `remote_tracking` rows for the D-00a `git fetch` movement are recorded per D-00a's instruction ("must appear in the ref-exception accounting rather than pass unrecorded") but are not required for the gate to pass — `origin/main`/`origin/HEAD` already pass via the ancestry rule.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1/3 - Bug + Blocking] preserve_repository_state.sh tried to re-preserve existing preservation refs**
- **Found during:** Task 2 (minting the real Phase-230 safety capsule)
- **Issue:** `run()`'s `for-each-ref ... refs` walk enumerates everything under `refs/`, including the 109 `refs/accrue-preserve/phase-229/<hex>` refs already present in this real repository from the actual Phase 229 execution. Encoding one of those ref *names* again under `phase-230/<hex(hex(...))>` produces a name long enough to exceed the filesystem's loose-ref path limit, failing the mint with `preservation ref collision` / `File name too long`.
- **Fix:** Skip any ref already matching `^refs/accrue-preserve/phase-[0-9]+(\.[0-9]+)?/` when freezing refs to preserve — such a ref is already a frozen snapshot from a prior capsule (any phase), never an original ref that itself needs preserving.
- **Files modified:** `scripts/ci/preserve_repository_state.sh`
- **Verification:** `--self-test` still passes (fresh fixture repos have no pre-existing `accrue-preserve` refs, so behavior is unchanged there); the real Phase-230 mint succeeds after the fix, with `refs/accrue-preserve/phase-229` byte-identical before and after (109 refs, unchanged), and 114 new `refs/accrue-preserve/phase-230/*` refs created.
- **Committed in:** `38dbe905`

---

**Total deviations:** 1 auto-fixed (1 bug + blocking issue, same root cause).
**Impact on plan:** Necessary for Task 2 to complete at all against the real repository (a fixture-only repo would never surface this). No scope creep — the fix is scoped to the exact ref-enumeration bug.

## Issues Encountered

- The plan's `<verify>` block for Task 2 checks `git bundle list-heads` for the *live* milestone tip at verification time. Because Task 1's and Task 3's own commits land on the milestone branch after Task 2's mint, a **later** re-check of the capsule against the current `HEAD` would no longer find that later tip in the bundle heads (the capsule is a point-in-time snapshot, same lesson Phase 229 already learned). This does not violate the plan's acceptance criteria, which were checked immediately after minting and passed; it's recorded here so a future reader isn't surprised that `git bundle list-heads` on this capsule doesn't include `939af6d3` (Task 3's commit).
- Full real-repo re-verification via `assertStrictRecovery`'s `--require-all-ref-recovery` path (which needs Phase 229's out-of-repo private manifest and bundle) was not attempted — those artifacts are intentionally private and outside this repository/session. `assertTypedRefContinuity` does not need them and *was* run end-to-end against the real committed inventory (see coverage D3), which is the mechanism this task actually changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- D-25 (out-of-repo preservation gap) is closed: the milestone execution line up through this plan's Task 2 mint has out-of-repo preservation.
- The preservation namespace is phase-parameterized; later plans in this phase (or Phase 231/232) can mint further phase-230 evidence without colliding with Phase 229's.
- Typed ref continuity is available (`--require-typed-ref-continuity --ref-exceptions .planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json`) and passes against the real repository today.
- **D-34 flag for Phase 232 (record only, do not act):** the canonical worktree multiset pins `dirty` as a single boolean per worktree, currently `true` for the primary worktree (this repository has uncommitted planning-doc drift such as `.planning/STATE.md`, `.planning/milestone.lock`, `.planning/state.json`). When Phase 232 flips the tree fully clean, that boolean flips `true -> false` and any capsule/inventory frozen against the current `dirty: true` state will fail strict worktree-multiset verification. This is expected, not a defect — flagged here per the plan's instruction to record it in the SUMMARY rather than as a ledger waiver row.
- Ready for the next plan in Phase 230 (`230-02` or whichever plan builds the `integration/v1.62-candidate` merge commit per D-01), which will need to declare that new branch as an `owned`-class addition in `230-REF-EXCEPTIONS.json` if/when strict typed-continuity verification is re-run after it's created.

---
*Phase: 230-reviewable-history-integration*
*Completed: 2026-09-15*

## Self-Check: PASSED

- FOUND: .planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json
- FOUND commit: 92f6eb12 (Task 1)
- FOUND commit: 38dbe905 (Task 2 + Rule 1/3 fix)
- FOUND commit: 939af6d3 (Task 3)
- Re-ran plan `<verification>` commands 1-3 and 5: all PASS (see coverage block). Item 4 (bundle list-heads contains live tip) verified PASS at mint time; documented as a point-in-time capsule per "Issues Encountered."
