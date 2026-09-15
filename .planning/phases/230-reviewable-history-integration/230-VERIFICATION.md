---
phase: 230-reviewable-history-integration
verified: 2026-09-15T21:50:00Z
status: passed
score: 3/3 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/230-reviewable-history-integration/230-01-PLAN.md"
  - ".planning/phases/230-reviewable-history-integration/230-01-SUMMARY.md"
  - ".planning/phases/230-reviewable-history-integration/230-02-PLAN.md"
  - ".planning/phases/230-reviewable-history-integration/230-02-SUMMARY.md"
  - ".planning/phases/230-reviewable-history-integration/230-03-PLAN.md"
  - ".planning/phases/230-reviewable-history-integration/230-03-SUMMARY.md"
  - ".planning/phases/230-reviewable-history-integration/230-04-PLAN.md"
  - ".planning/phases/230-reviewable-history-integration/230-04-SUMMARY.md"
  - ".planning/phases/230-reviewable-history-integration/230-05-PLAN.md"
  - ".planning/phases/230-reviewable-history-integration/230-05-SUMMARY.md"
  - ".planning/phases/230-reviewable-history-integration/230-06-PLAN.md"
  - ".planning/phases/230-reviewable-history-integration/230-06-SUMMARY.md"
  - ".planning/phases/230-reviewable-history-integration/230-07-PLAN.md"
  - ".planning/phases/230-reviewable-history-integration/230-07-SUMMARY.md"
  - ".planning/phases/230-reviewable-history-integration/230-CONTEXT.md"
  - ".planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.json"
  - ".planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.md"
  - ".planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json"
  - ".planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md"
  - ".planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json"
  - ".planning/phases/230-reviewable-history-integration/230-REVIEW.md"
  - ".planning/phases/230-reviewable-history-integration/230-ROLLBACK-POINT.json"
  - "scripts/ci/README.md"
  - "scripts/ci/collect_integration_disposition.mjs"
  - "scripts/ci/render_integration_disposition.mjs"
  - "scripts/ci/verify_integration_disposition.mjs"
  - "scripts/ci/verify_phase230_archive_invariants.mjs"
  - "scripts/ci/verify_repository_inventory.mjs"
covered_digest: "v1:sha256:e71860e82f52267eb552014d3ce058e0ab4e7891df10402d0e718946d64c5ae6"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 230: Reviewable History Integration Verification Report

**Phase Goal:** Maintainers can review one reversible integration candidate that reconciles remote `main`, intended v1.61 work, and all four post-archive audit-closure commits without rewriting published history.
**Verified:** 2026-09-15T21:50:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A maintainer can inspect an integration candidate containing remote-`main` changes, intended v1.61 work, and all four post-archive audit-closure commits while the v1.61 tag remains unchanged | ✓ VERIFIED | `refs/heads/integration/v1.62-candidate` exists (tip `bab50d92`). The candidate's merge commit `4d45002c` has parents `8b248d9c` (milestone tip) and `d30fc25d` (`origin/main`, confirmed live via `git ls-remote`). Ran `git merge-base --is-ancestor` for `v1.61`, `origin/main`, and all four closure SHAs (`8a95fbe8`, `9e090eb5`, `7cc501a3`, `57c61a9a`) against the candidate tip — all return YES/exit 0. `git rev-parse v1.61` still resolves to `fdb41672` (tag object) exactly as recorded pre-integration; nothing was pushed (`git ls-remote origin` shows no `integration/*` or `review/*` ref). |
| 2 | A maintainer can inspect evidence-backed dispositions for every integration conflict and intentionally excluded commit, with focused regressions covering retained runtime, documentation, release, and CI behavior | ✓ VERIFIED | Ran the strict verifier with all six `--require-*` flags: `node scripts/ci/verify_integration_disposition.mjs --records 230-INTEGRATION-DISPOSITION.json --rendered 230-INTEGRATION-DISPOSITION.md --dispositions 230-DISPOSITIONS.json --dispositions-rendered 230-DISPOSITIONS.md --candidate integration/v1.62-candidate --review-ref review/v1.62-candidate-code-only --expected-repository szTheory/accrue --require-ancestry --require-scope --require-determinism --require-post-merge-scope --require-hazard-universe --require-excluded-ledger` → `PASS (verified: require-ancestry, require-determinism, require-excluded-ledger, require-hazard-universe, require-post-merge-scope, require-scope)`, exit 0. Four regression areas independently re-run against the live candidate branch, not transcribed from SUMMARY prose (see Behavioral Spot-Checks below): **runtime** (config.ex disjoint-hunk both surviving code paths present in `git show 4d45002c:accrue/lib/accrue/config.ex`; 184 money-math/billing/property tests + 65 config/money tests, 0 failures, run live against a fresh clone of the candidate compiled against Decimal 3 / ex_money 6), **documentation** (`bash scripts/ci/verify_package_docs.sh` exit 0 on the candidate), **release** (same run confirms `accrue`/`accrue_admin`/`accrue_portal` all at 1.5.1, matching `origin/main`'s Release Please state — no hand-edited version strings), **CI** (`node scripts/ci/verify_phase230_archive_invariants.mjs` exit 0, `scanned_files=97, literals=43`, registered merge-blocking in `.github/workflows/ci.yml`'s `docs-contracts-shift-left` job at "Phase-evidence archive-path sweep (D-22 standing invariant)"). Excluded-commit ledger records 80 abandoned local-`main` commits (`excluded_commit_count: 80`) plus PR #44's disposition (`close-unmerged-no-comment`), independently confirmed via `gh pr view 44` (state `CLOSED`, zero comments — matching the maintainer's explicit no-comment decision). |
| 3 | Before a pull request targets `main`, a maintainer can verify the candidate's ancestry, changed-file scope, milestone provenance, and rollback point | ✓ VERIFIED | Ancestry: see truth 1. Scope: `git diff --quiet integration/v1.62-candidate review/v1.62-candidate-code-only -- . ':!.planning'` → exit 0 (source-identical, code-only review branch never pushed). Rollback point: `230-ROLLBACK-POINT.json` records `candidate_object: 4d45002c`, both parents, `expected_reverted_tree: eb5c4eb3`, `restore_argv` as an argv array, and `bundle_sha256` for the out-of-repo safety capsule. Independently ran the revert proof in a scratch clone (never a worktree, per D-30): checked out `4d45002c`, ran `git revert -m 1 --no-edit 4d45002c`, resulting tree `eb5c4eb3` byte-identical to `git rev-parse 8b248d9c^{tree}` — reversibility proven executably, not asserted. The out-of-repo capsule (`phase230-final.bundle`, mode 600, outside the repo by design) sha256-matches the `bundle_sha256` recorded in the rollback point exactly (`45eca6bf...`). |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `refs/heads/integration/v1.62-candidate` | Reversible `--no-ff` merge candidate | ✓ VERIFIED | Exists locally, never pushed; tip carries 2 post-merge commits (230-05 toolchain/lockfile + regression work) on top of the pinned merge commit `4d45002c`, declared in `230-INTEGRATION-DISPOSITION.json.post_merge_commits` |
| `refs/heads/review/v1.62-candidate-code-only` | Code-only sibling review branch | ✓ VERIFIED | Exists, never pushed, byte-identical to candidate on every non-`.planning` path |
| `.planning/phases/230-.../230-INTEGRATION-DISPOSITION.{json,md}` | Hazard dispositions + scope | ✓ VERIFIED | Present, strict-verifier PASS, render determinism asserted by `--require-determinism` |
| `.planning/phases/230-.../230-DISPOSITIONS.{json,md}` | Excluded-commit ledger | ✓ VERIFIED | 80 rows + PR #44 disposition, strict-verifier PASS |
| `.planning/phases/230-.../230-ROLLBACK-POINT.json` | Rollback point | ✓ VERIFIED | Present; revert proof independently reproduced byte-identical tree |
| `.planning/phases/230-.../230-REF-EXCEPTIONS.json` | Declared-additions ledger | ✓ VERIFIED | `row_count: 8`, matches `refs.length`; verified against `verify_repository_inventory.mjs --require-typed-ref-continuity` per SUMMARY D3 (re-confirmed row_count field present and consistent) |
| `scripts/ci/verify_phase230_archive_invariants.mjs` | Standing archive-path invariant sweep | ✓ VERIFIED | Fixtures self-test + real corpus scan both exit 0; wired merge-blocking into `ci.yml` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| Candidate branch | v1.61 tag / origin-main / 4 closure SHAs | `git merge-base --is-ancestor` | WIRED | All five ancestry checks pass live |
| Candidate branch | Review branch | `git diff --quiet -- . ':!.planning'` | WIRED | Source-identical, confirmed live |
| `.github/workflows/ci.yml` | `verify_phase230_archive_invariants.mjs` | `docs-contracts-shift-left` job step | WIRED | Step present, runs `node --test`, `--fixtures`, and the real sweep, all no `continue-on-error` |
| Rollback point | Out-of-repo safety capsule | `bundle_sha256` | WIRED | Live sha256 of the capsule bundle matches the recorded value exactly |
| PR #44 | Milestone branch (patch-id matches) | `230-DISPOSITIONS.json.pr_44.matched_commits` | WIRED | All 4 PR-branch commits map to milestone commits by recorded patch-id; PR closed unmerged, 0 comments, confirmed via `gh pr view` |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Strict integration-disposition verifier, all 6 require flags | `node scripts/ci/verify_integration_disposition.mjs --records ... --require-ancestry --require-scope --require-determinism --require-post-merge-scope --require-hazard-universe --require-excluded-ledger` | `PASS (verified: require-ancestry, require-determinism, require-excluded-ledger, require-hazard-universe, require-post-merge-scope, require-scope)`, exit 0 | ✓ PASS |
| Candidate ancestry (v1.61, origin/main, 4 closure SHAs) | `git merge-base --is-ancestor <sha> integration/v1.62-candidate` × 6 | All exit 0 | ✓ PASS |
| Candidate vs review-branch source scope | `git diff --quiet integration/v1.62-candidate review/v1.62-candidate-code-only -- . ':!.planning'` | exit 0 (identical) | ✓ PASS |
| Reversibility proof (scratch clone, not worktree) | `git checkout 4d45002c && git revert -m 1 --no-edit 4d45002c` then compare `HEAD^{tree}` to `8b248d9c^{tree}` | Trees byte-identical (`eb5c4eb3...` == `eb5c4eb3...`) | ✓ PASS |
| Rollback-point capsule integrity | `shasum -a 256 phase230-final.bundle` vs recorded `bundle_sha256` | Exact match, file mode 600 | ✓ PASS |
| Runtime regression (dependency-lock-drift lane, fresh clone at candidate tip, Decimal 3 / ex_money 6) | `mix deps.get --check-locked && mix compile && mix test <29 billing/property files>` | Clean compile; `70 properties, 184 tests, 0 failures` | ✓ PASS |
| Runtime regression (config.ex disjoint-hunk hazard) | `mix test test/accrue/config_test.exs test/accrue/money_test.exs test/property/money_property_test.exs` | `14 properties, 65 tests, 0 failures` | ✓ PASS |
| Documentation/release regression | `bash scripts/ci/verify_package_docs.sh` (run at candidate tip) | `package docs verified for accrue 1.5.1, accrue_admin 1.5.1, and accrue_portal 1.5.1`, exit 0 | ✓ PASS |
| CI-behavior regression (archive-path invariant) | `node scripts/ci/verify_phase230_archive_invariants.mjs --fixtures && node scripts/ci/verify_phase230_archive_invariants.mjs` | Both exit 0; real sweep `scanned_files=97, literals=43` | ✓ PASS |
| PR #44 closure state | `gh pr view 44 --json state,comments` | `state: CLOSED`, `comments: []` | ✓ PASS |
| `origin/main` unmoved | `git rev-parse origin/main` vs `git ls-remote origin main` | Both `d30fc25dbf6ba551792c66ff451b4b93c0af4bf1` | ✓ PASS |
| Nothing pushed | `git ls-remote origin` grep for `integration/`/`review/` refs | Empty (not present remotely) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|--------------|--------|----------|
| INTG-01 | 230-02, 230-06, 230-07 | Integration candidate + code-only review branch + archive-path invariant | ✓ SATISFIED | Ancestry checks, scope-identity diff, CI wiring all live-verified |
| INTG-02 | 230-03, 230-05 | Hazard dispositions + focused regressions | ✓ SATISFIED | Strict verifier PASS with `--require-hazard-universe`/`--require-scope`; regression suites independently re-run, all green |
| INTG-03 | 230-01, 230-02, 230-07 | Ref continuity / rollback point / provenance before PR | ✓ SATISFIED | Rollback point revert proof independently reproduced; ref-exceptions ledger present and consistent |

No orphaned requirements found for Phase 230 in `.planning/ROADMAP.md`.

### Anti-Patterns Found

None. Scanned all four newly-authored/modified verifier scripts (`verify_integration_disposition.mjs`, `collect_integration_disposition.mjs`, `render_integration_disposition.mjs`, `verify_phase230_archive_invariants.mjs`) for `TBD|FIXME|XXX` — zero matches. Code review (`230-REVIEW.md`, round 3/final) records 0 Critical, 1 Warning (WR-03 — a renderer scoping edge case, non-blocking, explicitly deferred as low-risk since the current data shape makes it moot), 1 Info (IN-01 — an error-message specificity nit in an unrelated pre-existing script), status `passed_with_warnings`. Neither open item bears on any of the three success criteria.

### Human Verification Required

None. All three success criteria were proven by direct command execution against the live repository state (ancestry checks, diff identity, revert-proof tree comparison, sha256 capsule match, strict verifier exit codes, and independently re-run test suites in a fresh scratch clone) — not inferred from SUMMARY.md prose.

### Gaps Summary

No gaps. All three roadmap success criteria for Phase 230 hold true against the current repository state, independently re-verified by direct command execution rather than trusted from SUMMARY claims:

1. The integration candidate exists, is unpushed, and provably contains remote-`main`, the milestone lineage, and all four closure commits as ancestors, while `v1.61` and `origin/main` are unchanged.
2. Every hazard and every excluded commit has a machine-recomputed, evidence-backed disposition; the four claimed regression areas (runtime, documentation, release, CI) were each independently re-executed live and pass with zero failures — not merely asserted present in JSON.
3. The candidate's ancestry, changed-file scope, milestone provenance, and reversibility are all independently provable before any PR targets `main`, including a from-scratch revert-proof reproducing the exact pre-merge tree.

---

_Verified: 2026-09-15T21:50:00Z_
_Verifier: Claude (gsd-verifier)_
