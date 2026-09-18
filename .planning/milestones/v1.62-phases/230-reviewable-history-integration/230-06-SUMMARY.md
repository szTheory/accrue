---
phase: 230-reviewable-history-integration
plan: 06
subsystem: infra
tags: [git, integration, evidence, ci, archive-invariant, review-branch, ref-exceptions]

requires:
  - phase: 230-reviewable-history-integration
    plan: 04
    provides: 230-DISPOSITIONS.{json,md} excluded-commit ledger, linked in this plan's README evidence row
  - phase: 230-reviewable-history-integration
    plan: 05
    provides: the two post-merge commits on integration/v1.62-candidate whose file/commit deltas this plan's live-tip scope recomputation now covers
provides:
  - "scripts/ci/verify_phase230_archive_invariants.mjs: a standing, merge-blocking sweep over scripts/ci/** and .github/workflows/** asserting every .planning/phases/<slug> literal resolves on disk or is provably archive-aware repo-wide; registered in ci.yml's docs-contracts-shift-left job."
  - "refs/heads/review/v1.62-candidate-code-only: a code-only sibling review branch (never pushed), proved byte-identical to integration/v1.62-candidate on every non-.planning path, declared in 230-REF-EXCEPTIONS.json."
  - "230-REF-EXCEPTIONS.json wrapped as { row_count, refs } with a verifier-asserted literal row-count integer (scripts/ci/verify_repository_inventory.mjs)."
  - "scripts/ci/verify_integration_disposition.mjs --require-scope now measures scope against the candidate branch's live tip (not the pinned merge-commit candidate.object) and, given --review-ref, asserts the recorded source_changed_files count against a live review-branch diff."
  - "230-INTEGRATION-DISPOSITION.{json,md}: recomputed scope (337/223/114 files, 527/265 commits) and a new handoffs/handoff_count field recording six Phase-232 items."
  - "A Phase 230 row in scripts/ci/README.md's evidence table linking the full disposition + excluded-commit-ledger artifact set."
affects: [231-exact-sha-release-gate-proof, 232-bounded-hygiene-release-handoff]

actuals:
  tokens: 15135
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Repo-wide 'proven safe slug' detection: a slug is archive-aware if ANY scanned file contains a literal .planning/milestones/*-phases/<slug> reference OR calls resolvePhaseEvidencePath with that slug (directly or via a same-file variable) -- lets a sweep tool recognize the established firstExistingPath/dual-directory-constant convention without requiring every call site to literally invoke the canonical resolver."
    - "Predicate-method exemption (.startsWith/.endsWith/.includes): a .planning/phases/<slug> string used as a string-prefix filter against a foreign ref's git ls-tree output is not a filesystem path resolution and is exempt from the archive-path sweep, distinguishing it from a bare path constant."
    - "Scope decoupled from candidate identity: candidate.object/parents/tree stay pinned to the single --no-ff merge commit for D-05/D-06 ancestry identity; scope.* now tracks the candidate ref's live tip so post_merge_commits (declared, evidence-backed additions on the same branch) are reflected in the reviewer's file/commit counts without requiring candidate.object itself to move."
  patterns_removed: []

key-files:
  created:
    - scripts/ci/verify_phase230_archive_invariants.mjs
  modified:
    - .github/workflows/ci.yml
    - scripts/ci/verify_admin_ui_ratchet_ci_contract.sh
    - scripts/ci/verify_crosswake_host_commands.sh
    - scripts/ci/verify_ui_ratchet_signoff.mjs
    - scripts/ci/verify_repository_inventory.mjs
    - scripts/ci/verify_integration_disposition.mjs
    - scripts/ci/render_integration_disposition.mjs
    - scripts/ci/collect_integration_disposition.mjs
    - scripts/ci/README.md
    - .planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json
    - .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json
    - .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md

key-decisions:
  - "The real archive-path sweep, run against this tree, surfaced three genuine pre-existing F-01-class regressions (Phase 208/224 evidence paths with no archive-aware fallback anywhere in the corpus) that the plan's own acceptance criteria required to pass clean -- repaired in scripts/ci/verify_crosswake_host_commands.sh, scripts/ci/verify_ui_ratchet_signoff.mjs, .github/workflows/ci.yml, and scripts/ci/verify_admin_ui_ratchet_ci_contract.sh (mirroring the already-fixed Phase 192 precedent) rather than narrowing the sweep's scope to dodge them."
  - "published_elsewhere for the new review-branch ref-exceptions row is the literal boolean false, not the plan prose's string \"none\" -- the existing schema in verify_repository_inventory.mjs requires published_elsewhere to be typeof boolean, and false is the same semantic fact (never published anywhere) expressed in the type the verifier actually enforces."
  - "scope.* is measured against the candidate branch's live tip (git rev-parse refs/heads/integration/v1.62-candidate), not the pinned candidate.object -- re-measuring against the pinned merge commit alone reproduced the pre-Plan-230-05 values (334/223/111), which would make --require-scope --review-ref permanently unsatisfiable (the code-only review branch is built from the live tip per the plan's own git-diff-quiet acceptance criterion, and post_merge_commits are real source changes a reviewer needs counted). candidate.object/parents/tree/ancestry stay pinned to the merge commit for D-05/D-06 identity; only scope decouples from that pin."
  - "230-REF-EXCEPTIONS.json is wrapped as { row_count, refs } (was a bare array) so the ledger's row count is a verifier-asserted literal integer per D-37, mirroring the excluded_commit_count/hazard_count/post_merge_commit_count pattern already used elsewhere in this triad; readRefExceptions still accepts a bare array for backward compatibility but skips the row_count assertion in that shape."
  - "Fixed a pre-existing bug in scripts/ci/render_integration_disposition.mjs's main(), found while re-rendering after this plan's own JSON edits: when --ledger-input/--ledger-out were both absent, args[args.indexOf(flag) + 1] resolved to args[0] (the node executable path) for both -- truthy, so the renderer tried to JSON.parse the node binary itself. Gated on explicit args.includes(flag) presence instead."

requirements-completed: []

coverage:
  - id: D1
    description: "Standing fail-closed archive-path invariant sweep (scripts/ci/verify_phase230_archive_invariants.mjs) scans scripts/ci/** and .github/workflows/**, distinguishes archive-aware literals (repo-wide) from raw archived-slug literals, and is registered merge-blocking in ci.yml's docs-contracts-shift-left job."
    requirement: "INTG-01"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_phase230_archive_invariants.mjs (2/2 pass: fixtures self-test covering both passing shapes and both failing shapes, non-zero corpus scan)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_phase230_archive_invariants.mjs --fixtures && node scripts/ci/verify_phase230_archive_invariants.mjs -- fixtures: PASS; real sweep: PASS (scanned_files=97, literals=46, 0 failures)"
        status: pass
      - kind: unit
        ref: "grep -n 'Phase-evidence archive-path sweep' .github/workflows/ci.yml -- present under docs-contracts-shift-left"
        status: pass
    human_judgment: false
  - id: D2
    description: "Code-only review branch refs/heads/review/v1.62-candidate-code-only built via git plumbing, proved byte-identical to the candidate on every non-.planning path, exactly one commit ahead of origin/main, zero .planning/ paths, never pushed, declared in 230-REF-EXCEPTIONS.json."
    requirement: "INTG-01"
    verification:
      - kind: other
        ref: "git diff --quiet integration/v1.62-candidate review/v1.62-candidate-code-only -- . ':!.planning' -- exit 0"
        status: pass
      - kind: other
        ref: "git rev-list --count review/v1.62-candidate-code-only ^origin/main -- prints 1"
        status: pass
      - kind: other
        ref: "git ls-tree -r --name-only review/v1.62-candidate-code-only | grep -c '^\\.planning/' -- 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "230-REF-EXCEPTIONS.json row-count asserted as a literal integer (row_count field) recomputed against refs.length; --require-typed-ref-continuity passes against the real committed 229-REPOSITORY-INVENTORY.json and the updated ledger (8 rows, including the refreshed integration/v1.62-candidate object and the new review-branch row)."
    requirement: "INTG-01"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_repository_inventory.mjs (5/5 pass, incl. typed ref continuity)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_repository_inventory.mjs --records .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json --rendered .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md --expected-repository szTheory/accrue --require-typed-ref-continuity --ref-exceptions .planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json -- PASS"
        status: pass
    human_judgment: false
  - id: D4
    description: "--require-scope, given --review-ref, asserts the recorded source_changed_files count equals a live git diff --name-only <merge-base> <review-ref> -- . ':!.planning' count, counted inside the verifier (never a shell pipeline); a fixture proves a wrong count fails."
    requirement: "INTG-02"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_integration_disposition.mjs (18/18 pass, incl. Scenario 1.5's clean review-ref pass and wrong-review-ref rejection)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs --records ... --rendered ... --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-scope --review-ref refs/heads/review/v1.62-candidate-code-only -- PASS"
        status: pass
    human_judgment: false
  - id: D5
    description: "230-INTEGRATION-DISPOSITION.md carries a Phase-232 handoffs section naming all six items with reasons; none was acted on (release-please files byte-identical merge-commit..candidate, no untracked file besides .tool-versions tracked/deleted, .planning/v1.61-v1.61-MILESTONE-AUDIT.md unchanged); README.md's Phase 230 row links all four disposition/ledger artifacts with a runnable command verified to exit 0 verbatim."
    requirement: "INTG-02"
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs --records ... --rendered ... --dispositions ... --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-ancestry --require-scope --require-hazard-universe --require-excluded-ledger --require-post-merge-scope --require-determinism -- PASS"
        status: pass
      - kind: other
        ref: "git diff --quiet 4d45002cafb3846810b84ff1afd84e7418476c50..integration/v1.62-candidate -- release-please-config.json .github/workflows/release-please.yml -- exit 0"
        status: pass
      - kind: other
        ref: "cmp against a fresh render of the committed JSON -- byte-identical"
        status: pass
    human_judgment: false

duration: ~4h (includes extensive real-repo archive-path debt investigation before writing the sweep)
completed: 2026-09-15
status: complete
commits: 3
plan_head_before: 615da4c2d01599be92682462d791a44f768e3f89
---

# Phase 230 Plan 6: Standing Archive Invariant, Code-Only Review Branch, and Phase-232 Handoffs Summary

**A merge-blocking archive-path sweep that found and fixed three real pre-existing Phase 208/224 evidence-path regressions, a never-pushed code-only review branch proved byte-identical to the candidate on 114 source files, and six recorded (not acted on) Phase-232 handoffs.**

## Performance

- **Duration:** ~4h (dominated by determining which of ~15 pre-existing hardcoded `.planning/phases/<slug>` literals across the repository were genuine archive-path bugs versus intentional scratch-working-directory or reproduce-command patterns, before the sweep's own design could be finalized)
- **Started:** 2026-09-15T~16:30:00Z (approx, first file read)
- **Completed:** 2026-09-15T20:38:02Z
- **Tasks:** 3
- **Files modified:** 13 (1 created, 12 modified)

## Accomplishments

- **`scripts/ci/verify_phase230_archive_invariants.mjs`** scans every file under `scripts/ci/**` and `.github/workflows/**` for `.planning/phases/<slug>` literals, classifies each as active-resolving, archive-aware-repo-wide (either a literal `.planning/milestones/*-phases/<slug>` reference or a `resolvePhaseEvidencePath` call with that slug, anywhere in the scanned corpus), or a hard failure, and exempts `.startsWith`/`.endsWith`/`.includes` string-predicate usage (foreign-ref tree-listing filters, not filesystem reads) and reproduce-command hint text (a quoted string containing more than the bare path). Registered as a merge-blocking `docs-contracts-shift-left` step in `.github/workflows/ci.yml`.
- Running the real sweep against this tree (not just fixtures) surfaced three genuine, previously-unrepaired F-01-class regressions — archived-slug literals with **no** archive-aware fallback anywhere in the corpus — and each was repaired by routing it through the archived location rather than deleting or weakening the check: `scripts/ci/verify_crosswake_host_commands.sh`'s three Phase 224 evidence paths now resolve active-then-archived; `scripts/ci/verify_ui_ratchet_signoff.mjs`'s `PHASE208_DIR` now points directly at the archived v1.56 milestone location; `.github/workflows/ci.yml`'s Phase 208 ratchet-evidence upload and `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh`'s required-literal check were updated together, mirroring the already-fixed Phase 192 precedent (including a `require_source_absent_regex` guard against the stale literal regressing).
- **`refs/heads/review/v1.62-candidate-code-only`** was built entirely via git plumbing (`read-tree` from the candidate's live tip, `rm --cached -r .planning`, `write-tree`, `commit-tree` parented on `origin/main`) — never pushed, never checked out. `git diff --quiet integration/v1.62-candidate review/v1.62-candidate-code-only -- . ':!.planning'` exits 0, `git rev-list --count review/v1.62-candidate-code-only ^origin/main` prints `1`, and the tree contains zero `.planning/` paths. Declared in `230-REF-EXCEPTIONS.json` with `published_elsewhere: false` (the plan prose's "none," expressed as the literal boolean the existing schema requires) and a Phase-232-integration-PR-merge retirement trigger.
- `230-REF-EXCEPTIONS.json` is now wrapped as `{ row_count, refs }` — the row count is a verifier-asserted literal integer (`scripts/ci/verify_repository_inventory.mjs`), never a non-empty check — and grew from 6 to 8 rows (the new review-branch row, plus a refresh of the pre-existing `integration/v1.62-candidate` row's `object` to the live tip, since `--require-typed-ref-continuity` was silently failing on that stale value the moment this plan actually ran it).
- `scripts/ci/verify_integration_disposition.mjs`'s `--require-scope` now measures scope against the candidate branch's **live tip**, not the pinned merge-commit `candidate.object` — `candidate.object`/`parents`/`tree`/ancestry stay pinned for D-05/D-06 identity, but scope tracks the reviewer's actual current read surface, which legitimately grew when Plan 230-05 landed two declared `post_merge_commits`. Given `--review-ref`, it additionally asserts the recorded `source_changed_files` count equals a live `git diff --name-only <merge-base> <review-ref> -- . ':!.planning'` count, with a fixture proving a wrong count fails. Re-measured scope: 337 files changed (223 `.planning/`-only, 114 source), 527 commits (265 `.planning/`-only) — superseding transcribed values that had gone stale after Plan 230-05.
- `230-INTEGRATION-DISPOSITION.{json,md}` gained a validated `handoffs`/`handoff_count` field recording six Phase-232 items (the excluded `origin/phase-226-baseline-5da8e6b88735` branch, untracked artifacts other than `.tool-versions`, the suspected `.planning/v1.61-v1.61-MILESTONE-AUDIT.md` duplicate, the unset `release-please` `commit-search-depth`, the 153-entry editorially-wrong public CHANGELOG, and the worktree `dirty=true` pin Phase 232 will invert) — none acted on, verified by an exact `git diff --quiet` between the merge commit and the candidate tip over `release-please-config.json`/`.github/workflows/release-please.yml`.
- `scripts/ci/README.md` gained a Phase 230 evidence-table row linking `230-INTEGRATION-DISPOSITION.{json,md}` and `230-DISPOSITIONS.{json,md}` with a single runnable `verify_integration_disposition.mjs` invocation carrying the full `--require-*` flag set, verified to exit 0 run verbatim from the repository root.
- Fixed a real, previously-latent bug in `scripts/ci/render_integration_disposition.mjs`'s `main()`, found while re-rendering after this plan's own JSON edits: with `--ledger-input`/`--ledger-out` both absent, `args[args.indexOf(flag) + 1]` resolved to `args[0]` (the node executable path) for both — truthy, so the renderer attempted to `JSON.parse` the node binary itself. Gated on explicit `args.includes(flag)` presence.

## Task Commits

1. **Task 1: Standing fail-closed archive-path invariant sweep** - `a775b725` (feat)
2. **Task 2: Code-only review branch and recomputed changed-file scope** - `e311e48f` (feat)
3. **Task 3: Contributor evidence map row and recorded Phase-232 handoffs** - `d059a0e4` (feat)

**Plan metadata:** (this commit) - `docs(230-06): complete plan`

## Files Created/Modified

- `scripts/ci/verify_phase230_archive_invariants.mjs` — new; the standing sweep, exports `verifyArchiveInvariants`, `--fixtures` self-test
- `.github/workflows/ci.yml` — new `docs-contracts-shift-left` sweep step; Phase 208 ratchet-evidence upload now points at the archived milestone path
- `scripts/ci/verify_crosswake_host_commands.sh` — Phase 224 evidence paths now active-then-archived
- `scripts/ci/verify_ui_ratchet_signoff.mjs` — `PHASE208_DIR` now points at the archived v1.56 milestone location
- `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` — required literal updated + stale-literal absent-check added
- `scripts/ci/verify_repository_inventory.mjs` — `readRefExceptions` asserts a literal `row_count` when the ledger is wrapped
- `scripts/ci/verify_integration_disposition.mjs` — `--require-scope` measures against the live tip; `--review-ref` cross-check; Scenario 1.5 fixture
- `scripts/ci/render_integration_disposition.mjs` — Phase-232 handoffs section; review-branch link text in the scope section; ledger-args bug fix
- `scripts/ci/collect_integration_disposition.mjs` — `handoffs`/`handoff_count` schema + validator
- `scripts/ci/README.md` — Phase 230 evidence-table row
- `.planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json` — wrapped `{ row_count, refs }`; new review-branch row; refreshed candidate object
- `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json` — recomputed scope; new `handoffs` field
- `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md` — re-rendered (byte-identical to a fresh render of the committed JSON)

## Decisions Made

See `key-decisions` in frontmatter. Summarized: (1) the real sweep surfaced and required fixing three genuine pre-existing archive-path regressions (Phase 208/224) rather than being narrowed to avoid them; (2) `published_elsewhere: false` (literal boolean) supersedes the plan prose's string `"none"` since the existing schema enforces a boolean type; (3) scope is deliberately decoupled from the pinned `candidate.object` and measured against the live tip so it can ever agree with a review branch built from that same live tip, while ancestry/identity checks stay pinned to the merge commit; (4) `230-REF-EXCEPTIONS.json`'s row count became a verifier-asserted literal integer via a `{ row_count, refs }` wrapper, matching the `excluded_commit_count`/`hazard_count`/`post_merge_commit_count` pattern already used elsewhere in this triad; (5) a real bug in the renderer's optional-flag handling was fixed in place rather than worked around.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Three genuine archive-path regressions (Phase 208/224) had no archive-aware fallback anywhere in the corpus**
- **Found during:** Task 1, running the real sweep against this tree (not just fixtures)
- **Issue:** `scripts/ci/verify_crosswake_host_commands.sh` (Phase 224 evidence paths), `scripts/ci/verify_ui_ratchet_signoff.mjs` (`PHASE208_DIR`), and `.github/workflows/ci.yml`'s Phase 208 ratchet-evidence upload plus its `verify_admin_ui_ratchet_ci_contract.sh` contract all hardcoded now-archived `.planning/phases/<slug>` literals with zero fallback — exactly the F-01..F-03 class D-22 exists to prevent recurring.
- **Fix:** Made each active-then-archived (crosswake) or pointed directly at the archived milestone location (the parked Phase 208 ratchet, which has no live regeneration pipeline left), mirroring the already-fixed Phase 192 precedent for the ci.yml/contract pair.
- **Files modified:** scripts/ci/verify_crosswake_host_commands.sh, scripts/ci/verify_ui_ratchet_signoff.mjs, .github/workflows/ci.yml, scripts/ci/verify_admin_ui_ratchet_ci_contract.sh
- **Verification:** `bash scripts/ci/test_verify_crosswake_host_commands.sh` and `node scripts/ci/verify_ui_ratchet_signoff.mjs --self-test` still pass; `bash scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` passes; the real sweep exits 0.
- **Committed in:** `a775b725` (Task 1 commit)

**2. [Rule 1 - Bug] Stale `230-REF-EXCEPTIONS.json` `integration/v1.62-candidate` row object**
- **Found during:** Task 2, running `--require-typed-ref-continuity` for real
- **Issue:** The row's `object` still named the original 230-02 merge commit (`4d45002c...`); the branch had legitimately advanced via Plan 230-05's two declared `post_merge_commits` to `bab50d92...`, and owned-ref rows require exact live equality.
- **Fix:** Refreshed the `object` field to the live tip and extended the `reason` to note the two post-merge commits.
- **Files modified:** .planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json
- **Verification:** `node scripts/ci/verify_repository_inventory.mjs --require-typed-ref-continuity ...` PASS against the real committed inventory.
- **Committed in:** `e311e48f` (Task 2 commit)

**3. [Rule 1 - Bug] `render_integration_disposition.mjs`'s ledger-args handling read the node binary as JSON when `--ledger-input`/`--ledger-out` were absent**
- **Found during:** Task 2, re-rendering after the scope update without passing the optional ledger flags
- **Issue:** `args[args.indexOf(flag) + 1]` resolved to `args[0]` (truthy) for both flags when neither was present, so `main()` unconditionally attempted `JSON.parse(fs.readFileSync(args[0]))` — the node executable itself.
- **Fix:** Gated on `args.includes(flag)` before indexing.
- **Files modified:** scripts/ci/render_integration_disposition.mjs
- **Verification:** `node scripts/ci/render_integration_disposition.mjs --input ... --out ... --expected-repository szTheory/accrue` (no ledger flags) exits 0; `node --test scripts/ci/render_integration_disposition.mjs` still 12/12.
- **Committed in:** `e311e48f` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 1 bugs, all necessary for the plan's own acceptance criteria to pass against the real repository state rather than a synthetic fixture).
**Impact on plan:** All three fixes were pre-existing repository debt or a pre-existing script bug uncovered strictly by running this plan's own real (non-fixture) verification commands, not scope creep. No file outside `scripts/ci/**`, `.github/workflows/**`, and this phase's own evidence artifacts was touched.

## Issues Encountered

- **Scope semantics ambiguity between the pinned `candidate.object` and the live branch tip.** The plan's own acceptance criteria require both (a) the review branch to satisfy `git diff --quiet integration/v1.62-candidate <review-branch>` (forcing the review branch to reflect the live tip, since `integration/v1.62-candidate` resolves to whatever it currently points at) and (b) `scope.source_changed_files` to equal a count derived from that same review branch. The pre-existing `assertScopeLive` compared against the pinned `candidate.object`, which — after Plan 230-05's two legitimate post-merge commits — no longer equals the live tip. Resolved by decoupling scope from `candidate.object` (see key-decisions); `candidate.object`/ancestry/parents remain pinned for D-05/D-06 identity purposes, unaffected by this change.
- **Distinguishing genuine archive-path bugs from intentional patterns took the bulk of this plan's time.** Several files (`generate_phase200_closeout_reports.mjs`, `verify_phase190_automation_contract.sh`, `verify_phase191_ax187_coverage.mjs`, `verify_phase225_required_lane_evidence.sh`, `collect_integration_disposition.mjs`'s own ls-tree prefix filter, `render_ci_baseline.mjs`'s reproduce-command text, `verify_ci_critical_path.mjs`'s "next command" hints) already implement archive-aware dual-path fallback or are provably not filesystem-read literals; the sweep's design (repo-wide proven-safe-slug detection + predicate-method exemption) was shaped specifically so these pass without modification, while the three genuinely broken files (above) do not.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 230-07 remains to execute; no blockers identified for it from this plan's work.
- INTG-01 and INTG-02 remain declared by multiple plans in this phase (230-01/230-02/230-03/230-04/230-05/230-06/230-07); the shared-ID gate correctly keeps them `In Progress` in `REQUIREMENTS.md` until every declaring plan finishes.
- The standing archive-path sweep is now merge-blocking, so a literal a future merge introduces will be caught at merge time rather than after the next archival — directly closing D-22's stated purpose.
- The code-only review branch and its `230-REF-EXCEPTIONS.json` row carry a retirement trigger naming the Phase 232 integration-PR merge; Phase 232 should delete the branch and retire the row at that point.

---
*Phase: 230-reviewable-history-integration*
*Completed: 2026-09-15*

## Self-Check: PASSED

- FOUND: scripts/ci/verify_phase230_archive_invariants.mjs (new)
- FOUND: scripts/ci/verify_crosswake_host_commands.sh (modified)
- FOUND: scripts/ci/verify_ui_ratchet_signoff.mjs (modified)
- FOUND: scripts/ci/verify_admin_ui_ratchet_ci_contract.sh (modified)
- FOUND: scripts/ci/verify_repository_inventory.mjs (modified)
- FOUND: scripts/ci/verify_integration_disposition.mjs (modified)
- FOUND: scripts/ci/render_integration_disposition.mjs (modified)
- FOUND: scripts/ci/collect_integration_disposition.mjs (modified)
- FOUND: scripts/ci/README.md (modified)
- FOUND: .planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json (modified)
- FOUND: .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json (modified)
- FOUND: .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md (modified)
- FOUND: .github/workflows/ci.yml (modified)
- FOUND commit: a775b725 (Task 1)
- FOUND commit: e311e48f (Task 2)
- FOUND commit: d059a0e4 (Task 3)
- Re-ran the plan-level `<verification>` items 1-5: all PASS. `node --test scripts/ci/verify_phase230_archive_invariants.mjs` reports 2/2 pass, 0 fail. The real sweep exits 0 with scanned_files=97, literals=46. `git diff --quiet integration/v1.62-candidate review/v1.62-candidate-code-only -- . ':!.planning'` exits 0; the review branch is exactly 1 commit beyond origin/main with 0 `.planning/` paths. The full `--require-*` flag set (ancestry/scope/hazard-universe/excluded-ledger/post-merge-scope/determinism) plus `--review-ref` passes against the committed evidence artifacts. No Phase-232-owned file (release-please-config.json, .github/workflows/release-please.yml, the five other untracked artifacts, .planning/v1.61-v1.61-MILESTONE-AUDIT.md) was modified by this plan.
