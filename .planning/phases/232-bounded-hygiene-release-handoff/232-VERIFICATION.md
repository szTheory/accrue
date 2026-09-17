---
phase: 232-bounded-hygiene-release-handoff
verified: 2026-09-17T18:00:00Z
status: gaps_found
score: 4/5 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-01-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-01-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-02-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-02-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-03-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-03-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-04-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-04-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-05-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-05-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-06-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-06-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-07-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-07-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-08-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-08-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-09-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-09-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-10-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-10-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-11-PLAN.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-11-SUMMARY.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-CLEANUP-FINDINGS.json"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-CONTEXT.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-HYGIENE-DISPOSITIONS.json"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-HYGIENE-DISPOSITIONS.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-RESEARCH.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-REVIEW.md"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-ROLLBACK-POINT.json"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-WINDOW-DISPOSITIONS.json"
  - ".planning/phases/232-bounded-hygiene-release-handoff/232-WINDOW-DISPOSITIONS.md"
  - "scripts/ci/collect_hygiene_dispositions.mjs"
  - "scripts/ci/collect_integration_disposition.mjs"
  - "scripts/ci/collect_repository_inventory.mjs"
  - "scripts/ci/main_module.mjs"
  - "scripts/ci/render_gate01_cohort.mjs"
  - "scripts/ci/render_integration_disposition.mjs"
  - "scripts/ci/render_repository_inventory.mjs"
  - "scripts/ci/verify_ci_script_contract.mjs"
  - "scripts/ci/verify_phase230_archive_invariants.mjs"
  - "scripts/ci/verify_pr_body_contract.mjs"
  - "scripts/ci/verify_release_pr_readiness.sh"
covered_digest: "v1:sha256:a020ba740f8ddb94c0a6d0527d64ccbd99cbc2518de2bd93e57345a3dd3ac195"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A reviewer can assess an integration pull request with a concise risk summary, exact verification evidence, rollback instructions, and no unrelated feature scope (Success Criterion 4 / REL-04)."
    status: failed
    reason: "No pull request exists. `gh pr list --repo szTheory/accrue` returns zero results for the integration candidate at every state (open/closed/merged). Plan 232-11's Task 3 checkpoint (the step that actually opens the PR) was deliberately not run, by design, pending maintainer authorization. The committed 232-INTEGRATION-PR.md body is a necessary but not sufficient artifact: it is reviewable text on disk, not a reviewable pull request. REQUIREMENTS.md nonetheless marks REL-04 'Complete' (set by commit 32e4c1cf, plan 232-10's completion commit, before 232-11 even ran) — this is premature. The acceptance text is literally 'Maintainers can review an integration pull request'; there is no pull request to review."
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "REL-04 marked [x] Complete (line 34) while its own acceptance text requires a reviewable pull request that does not exist yet."
    missing:
      - "A fresh re-cut of the integration candidate incorporating this phase's own post-review fix commits (CR-01, CR-02, WR-01, WR-02, WR-03 — none of which are present on origin/integration/v1.62-candidate-recut today)."
      - "Re-pointing 232-INTEGRATION-PR.md's Head SHA / rollback-command lines to the fresh re-cut tip and re-running the body contract."
      - "Running plan 232-11's Task 3 checkpoint to obtain explicit maintainer authorization and actually open (or update) the pull request."
      - "REQUIREMENTS.md's REL-04 row reverted to Pending/In Progress until a real, open pull request exists (or an explicit override recorded by the maintainer accepting the committed-body-as-deliverable interpretation)."
deferred: []
---

# Phase 232: Bounded Hygiene & Release Handoff Verification Report

**Phase Goal:** Maintainers can review a release-ready integration handoff whose repository and
release-facing artifacts are truthful, recoverable, and free of demonstrated release-path drift.

**Verified:** 2026-09-17T18:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Before cleanup, a maintainer can inspect a classification of every untracked file, stale worktree, debug session, and remote maintenance/release branch (retained/committed/archived/superseded/removal-authorized). | ✓ VERIFIED | `scripts/ci/verify_hygiene_dispositions.mjs --records 232-HYGIENE-DISPOSITIONS.json --rendered 232-HYGIENE-DISPOSITIONS.md --require-completeness --require-soundness --require-determinism` → `PASS (verified: require-completeness, require-determinism, require-soundness)`, re-run live. The record was re-minted in commit `7c3a2d3a` to add the one branch (`remote_branch/origin/integration/v1.62-candidate-recut`) 232-11 itself discovered was missing before phase close — a genuine, closed gap, not a residual one. |
| 2 | A maintainer can verify GSD health, planning mirrors, generated artifacts, package metadata, changelogs, and release documentation agree with the integration candidate with no release-blocking drift. | ✓ VERIFIED | `verify_ci_script_contract.mjs --repo . --require-guard-coverage --require-non-vacuity --require-cohort-floor` → `PASS` (live). `verify_window_dispositions.mjs --repo . --records 232-WINDOW-DISPOSITIONS.json --rendered 232-WINDOW-DISPOSITIONS.md --candidate c1397fe9... --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism` → `PASS` (live, against the real pinned candidate SHA, not `--fixtures`). Both code-review Criticals (CR-01: six bare `isMainModule` call sites that crashed under a bare dynamic import; CR-02: `verify_release_pr_readiness.sh` defaulting to the superseded, pre-re-cut branch) are fixed and independently re-verified live in this session (see below) — not merely claimed fixed. |
| 3 | Any release-path cleanup is backed by an objective finding, and additional passes stop once only subjective nits remain. | ✓ VERIFIED | `232-CLEANUP-FINDINGS.json`: 8 command-backed findings (`before_exit_code`/`after_exit_code`/`commit` triples), `passes_taken: 2`. Categories are test/dead-code/lint/documentation-truth, matching the objective-finding constraint; no subjective-nit rows present. |
| 4 | A reviewer can assess an integration pull request with a concise risk summary, exact verification evidence, rollback instructions, and no unrelated feature scope. | ✗ FAILED | **No pull request exists.** `gh pr list --repo szTheory/accrue --state all` shows nothing for the integration candidate at any state. The committed `232-INTEGRATION-PR.md` body passes its own contract live (`pr body contract: PASS (verified: require-density, require-falsifiability, require-sections; 50 lines)`) and is a genuinely well-built artifact, but it is text on disk, not an open pull request a reviewer can assess. Plan 232-11's Task 3 (the checkpoint that opens the PR) was deliberately not run — by design, per its own dispatch scope — pending maintainer authorization and a fresh re-cut. See Gaps Summary. |
| 5 | A reviewer can confirm Release Please is producing, or is ready to produce, a version-and-changelog-consistent release pull request without merging it or publishing packages. | ✓ VERIFIED | `bash scripts/ci/verify_release_pr_readiness.sh` re-run live in this session, with real `gh` auth, against the correct branch (post-CR-02 fix, default now `integration/v1.62-candidate-recut`): `PASS -- all 6 assertions ran (target: integration/v1.62-candidate-recut, plan: 1.5.1 -> 1.6.0, updates: 7)`. This is a genuine, non-`--fixtures` proof against the live GitHub API and the real candidate branch. |

**Score:** 4/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/ci/main_module.mjs` | shared, correct entrypoint guard | ✓ VERIFIED | 5 self-tests, live-reproduced negative control (space-in-path) |
| `scripts/ci/verify_ci_script_contract.mjs` | meta-verifier enforcing guard/non-vacuity/cohort floor, and (post-review) guard *shape* | ✓ VERIFIED | Live run passes; `assertGuardCoverage` now regexes for the `try{...isMainModule...}catch` shape, not just import presence (WR-01 fix confirmed in source) |
| `scripts/ci/verify_release_pr_readiness.sh` | proves release-readiness of the branch that actually matters | ✓ VERIFIED | Default target now `integration/v1.62-candidate-recut`; fail-closed assertion 0 rejects the superseded SHA; live run passes |
| `scripts/ci/verify_pr_body_contract.mjs` | machine-checkable contract over the PR body | ✓ VERIFIED | 14/14 tests pass; wired into `docs-contracts-shift-left` (WR-03 fix confirmed present in `ci.yml`) |
| `.planning/phases/.../232-INTEGRATION-PR.md` | reviewable PR body | ⚠️ ORPHANED (relative to its purpose) | Exists, passes its contract, but is not yet attached to any pull request — see gap |
| `.planning/phases/.../232-HYGIENE-DISPOSITIONS.json/.md` | classification triad | ✓ VERIFIED | Live verify passes with all three strict flags after the 232-11 re-mint |
| `.planning/phases/.../232-WINDOW-DISPOSITIONS.json/.md` (phase 232's own) | pinned-SHA gate window record | ✓ VERIFIED | Live verify passes against the real candidate SHA `c1397fe9...`, wired merge-blocking in `ci.yml` (D-16) |
| `.planning/phases/.../232-CLEANUP-FINDINGS.json` | bounded, command-backed cleanup ledger | ✓ VERIFIED | 8 findings, 2 passes, all command-backed |
| `.planning/phases/.../232-ROLLBACK-POINT.json` | recoverable restore point | ⚠️ see Data-Flow Trace note below | `candidate_object`/`restore_argv` are correct and match 231's own schema precedent (merge commit, not tip); `candidate_ref` is only resolvable to the correct SHA inside this specific local sandbox (see below) |

### Code Review Follow-through (232-REVIEW.md → this session)

The phase's own code review (`232-REVIEW.md`, `status: issues_found`, 2 critical / 3 warning / 2 info)
was addressed by five follow-up commits (`6f3b67b5`, `db08a2f9`, `931f49db`, `529fd883`, `f2a13304`),
all present on `HEAD`. Each was independently re-verified live in this session, not merely trusted from
commit messages:

| Finding | Fix commit | Live re-verification | Status |
|---|---|---|---|
| CR-01 (six bare `isMainModule` calls crash under empty `argv[1]`) | `6f3b67b5` | `node --input-type=module -e "import('./scripts/ci/<file>.mjs')"` for all six files → all now resolve `OK import`, zero crashes | ✓ FIXED, confirmed |
| CR-02 (`verify_release_pr_readiness.sh` targets the superseded branch by default) | `931f49db` | `grep TARGET_BRANCH=` now defaults to `integration/v1.62-candidate-recut`; live run against the real branch passes | ✓ FIXED, confirmed |
| WR-01 (meta-verifier can't distinguish bare from wrapped guard usage) | `db08a2f9` | `assertGuardCoverage` source now contains a try/catch-shape regex (`/try\s*\{[^{}]*\bisMainModule\b[^{}]*\}\s*catch/`) with dedicated positive/negative test scenarios | ✓ FIXED, confirmed |
| WR-02 (stale provenance comment in `collect_hygiene_dispositions.mjs`) | `529fd883` | `grep -n "sanitizeLeakCheck\|NOT re-exported"` returns nothing | ✓ FIXED, confirmed |
| WR-03 (`verify_pr_body_contract.mjs` unwired in CI) | `f2a13304` | `ci.yml` now contains `Integration PR body contract (REL-04)` step, no `continue-on-error`; `yaml.safe_load` parses | ✓ FIXED, confirmed |

None of the review's findings remain open. This is a genuine strength of the phase — the review loop closed for real, verified independently rather than trusted from the fix commit messages.

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| HYG-01 | ✓ SATISFIED | Hygiene-dispositions triad live-verified (all strict flags) |
| HYG-02 | ✓ SATISFIED | CI script contract + window dispositions (D-16) live-verified against the real candidate SHA; both review Criticals independently confirmed fixed |
| HYG-03 | ✓ SATISFIED | `232-CLEANUP-FINDINGS.json`: 8 command-backed findings, 2 bounded passes |
| REL-04 | ✗ NOT YET SATISFIED (see gap) | Marked `[x] Complete` in REQUIREMENTS.md, but its own acceptance text requires a reviewable pull request, and none exists |
| REL-05 | ✓ SATISFIED | `verify_release_pr_readiness.sh` live-verified against the real, correctly-targeted branch with real `gh` API access |

No orphaned requirements found — HYG-01/02/03, REL-04, REL-05 are the complete declared set for this phase and all five are accounted for above.

### Anti-Patterns Found

None of blocker severity. No unresolved `TBD`/`FIXME`/`XXX` markers found in the covered file set. `232-VALIDATION.md` remains `status: draft` / `nyquist_compliant: false` (seeded, never validated) — consistent with phases 230/231 shipping the same way; noted, not blocking, per the task's own framing.

### Behavioral Spot-Checks / Probe Execution

All load-bearing claims for this phase are themselves executable CI verifier scripts; the "probes" and
"spot-checks" for this phase are the live verifier invocations reproduced above (not a separate probe
harness). Every command quoted in this report was re-run fresh in this session, not copied from a
SUMMARY.

Full `mix test` suites for `accrue` (2060 tests) and `accrue_admin` (519 tests) were not re-run in this
session (multi-minute, resource-heavy, and independently reported clean by the orchestrator's
pre-verification pass moments before this dispatch started, on the same `HEAD`). This is a scope
narrowing for time, not a finding — flagged here for transparency rather than silently assumed.

### Gaps Summary

**One must-have is genuinely unmet: Success Criterion 4 / REL-04.** No integration pull request exists
— `gh pr list` returns nothing for the candidate at any state, matching the task's own pre-stated
expectation. This is not a bug: plan 232-11's Task 3 (`checkpoint:decision`, the step that actually opens
the PR) was deliberately withheld pending maintainer authorization, which is the correct application of
CLAUDE.md's Executable Acceptance Policy carve-out for "genuine product decisions... irreversible external
operations." The committed `232-INTEGRATION-PR.md` and its passing contract are real, substantial progress
toward the goal — but they are not the goal. A reviewer cannot "assess an integration pull request" that
does not exist.

Compounding this: the currently published `origin/integration/v1.62-candidate-recut` (SHA `c1397fe9...`)
predates this phase's own code-review fix commits (`6f3b67b5` through `f2a13304`). Opening a PR from that
branch today would not include the CR-01/CR-02/WR-01/WR-02/WR-03 fixes verified above. 232-11's own
SUMMARY anticipated this ("the maintainer decides when to cut the fresh... re-cut... after phase 232's own
closing plan lands") — that re-cut has not yet happened. A real re-cut, a three-line re-point of
`232-INTEGRATION-PR.md`, a contract re-run, and the Task 3 checkpoint all remain before Success Criterion
4 can be called true.

**Verdict on `REL-04` marked `Complete` in REQUIREMENTS.md (commit `32e4c1cf`):** not defensible as
written. `32e4c1cf` is plan 232-10's completion commit, landed *before* plan 232-11 (the plan that
produces the PR body and the checkpoint) even ran. REL-04's acceptance text is "Maintainers can review an
integration pull request with a concise risk summary, exact verification evidence, preserved rollback
instructions, and no unrelated feature scope" — a pull request is the explicit subject of the sentence.
The committed body is necessary infrastructure, not the deliverable itself. Recommend reverting REL-04 to
Pending/In Progress in REQUIREMENTS.md until an open pull request exists, or — if the maintainer
deliberately wants to treat "a committed, contract-verified PR body" as satisfying REL-04 independent of
actually opening it — recording that as an explicit accepted override with a named rationale, rather than
leaving it silently marked Complete by an earlier plan's bookkeeping commit.

**Verdict on `232-ROLLBACK-POINT.json`'s `candidate_ref` (question 2):** the field's *value*
(`refs/heads/integration/v1.62-candidate`) is not misleading in isolation — it matches 231's own schema
precedent (`candidate_ref` names the branch used to resolve a live tip for the toolchain-pin check;
`candidate_object` is deliberately the merge commit, not the branch tip, because the shape gate requires
a 2-parent commit — this is documented and correct, confirmed against 232-09-SUMMARY.md's own Rule-1 fix
history). What **is** misleading as committed evidence: in this local sandbox, the local branch
`integration/v1.62-candidate` happens to point at the re-cut tip (`c1397fe9...`, a leftover of 232-09's
local scratch-clone construction that was never pushed under this name), while
**`origin/integration/v1.62-candidate` — the branch a fresh clone or CI would actually see under this
exact ref — still resolves to the superseded pre-re-cut SHA (`f524f2a6...`)**. Any command that resolves
`candidate_ref` against a fresh checkout (rather than this specific, already-scratch-touched local
repository) would silently validate the wrong, superseded state. This is mitigated in practice: CI's own
wiring of `verify_recut_candidate.mjs` only ever runs `--fixtures` (schema-only, never resolves the real
ref), so the ambiguous field is not currently exploitable through a merge-blocking gate. It is a real,
narrow documentation/portability defect (WARNING, not BLOCKER) — worth a follow-up note in the record or
a rename of the local leftover branch so it cannot be mistaken for reproducible evidence by a future
maintainer running the real (non-`--fixtures`) gates by hand.

**Verdict on `232-VALIDATION.md` (question 3):** confirmed `status: draft`, `nyquist_compliant: false`,
consistent with phases 230 and 231 shipping the same way — not a regression introduced by this phase, not
blocking.

## Human Verification Required

None — the remaining gap (Success Criterion 4 / REL-04) is not a human-judgment ambiguity; it is a
plainly observable, machine-checkable fact (no PR exists) with a clear, already-documented remediation
path (232-11's own "What remains before Task 3 can run" section). This routes to `gaps_found`, not
`human_needed`, because the missing artifact is unambiguous rather than requiring a subjective call.

---

*Verified: 2026-09-17T18:00:00Z*
*Verifier: Claude (gsd-verifier)*
