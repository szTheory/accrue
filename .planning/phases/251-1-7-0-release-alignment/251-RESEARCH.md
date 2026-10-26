# Phase 251: 1.7.0 Release Alignment - Research

**Researched:** 2026-10-26
**Domain:** release-please 17.6.0 monorepo release flow (linked-versions), GitHub Actions release/publish pipeline, Hex publication, release-gate contracts
**Confidence:** HIGH (root cause, recovery semantics and bump are reproduced from release-please source, run logs and read-only dry runs); MEDIUM on curated-notes accuracy (drafts need per-claim verification by the executor)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
(Copied from `251-CONTEXT.md` `## Implementation Decisions (locked)`; the "Current state" bullet block is observed state, kept for the planner.)

**Publication authorization (RLS-02)**
- On 2026-10-26 the maintainer said: "follow ur recs. i authorize release we want to release early and often at any natural stopping point that is release worthy".
- That is the recorded explicit yes for publishing 1.7.0 to Hex. It also establishes a standing policy: release at every release-worthy stopping point.
- Record this verbatim, with the date, in STATE.md and in the phase SUMMARY/VERIFICATION. It satisfies SC3 without leaving the PR open.
- Publish only from an aligned release PR whose exact head is green, with `main` green. Never weaken a release gate to get there.
- If any publish step fails partway (for example, one package published and another not), stop and report. Do not improvise a yank or retire.

**Workflow defect (fix at source, first)**
- The stale-base repair must not leave the release PR without its release commit. Two acceptable routes: re-create the release commit after a reset, or not reset when release-please would leave the PR unchanged.
- The fix needs a fixture or self-test with a negative control that reproduces "main moved, notes unchanged -> PR emptied".
- The fix lands through its own PR to `main`, squash-merged when green on its exact head.

**Release alignment (RLS-01)**
- release-please cannot write the README version pins, the companion notes, or the release-notes story that its own gates require. Align these on the release branch: README pins at 1.7.0; companion notes; a curated, adopter-readable CHANGELOG for each package, replacing raw phase-scoped `feat(2xx-yy)` lines.
- SC1 grep: no raw `feat(2xx-yy)` lines in the release CHANGELOGs.
- The CHANGELOG covers v1.63-v1.66 (admin/portal UI refinement, usability, consistency), the owner-feedback fixes, and v1.67 integration fixes worth noting to adopters (seed boundary in CI; focus ring a11y fix; 320px reflow fixes; portal Braintree stub race - test-only, probably not adopter-facing).
- Be honest about the D2 deferral (the `accrue_events.inserted_at` timezone issue is known and tracked for v1.68), if a known-issues note is the convention.
- Expect linked-versions 1.7.0. Verify the bump release-please computes; if it differs, investigate rather than force it.
- The release PR's exact head must be green on every required check (`success`, not `skipped`).
- The release PR is merged the way release-please expects (its default squash/merge flow), so it tags and the publish workflow fires. Then verify: GitHub releases and tags for all three packages at 1.7.0; `publish-hex.yml` success; hex.pm shows 1.7.0 for all three, with docs published.

**Rules**
- Never push to main directly, never force-push, and never push GSD milestone tags (release-please creates its own package tags; that is expected).
- Pushing branches and opening PRs for this phase is authorized, and so is merging them when green on their exact head.
- No Docker on the maintainer's machine. Never weaken a gate. Every contract change carries positive/negative controls.
- Re-mint covered_digest only via scanArtifact/computeDigest. STATE `current_phase` must flip to 251 in the same step that mints Phase 251's own VERIFICATION/UAT (the SL-G/SL-E handoff, as in Phase 250).
- Use `.planning/phases/250-remote-integration/250-ci-head-status.mjs` (with `--pr-base` where path filters apply) as the exact-head verdict helper.

### Claude's Discretion
- Plan decomposition and ordering. Expected: workflow fix PR -> recover release-please state -> aligned release PR -> publish -> verify -> phase/milestone close.
- Whether v1.67 milestone completion (`/gsd-complete-milestone`) happens in this phase or right after. If it happens, keep milestone tags local.

### Deferred Ideas (OUT OF SCOPE)
- v1.68 items in REQUIREMENTS.md "Future Requirements" (the inserted_at timezone fix is HIGH).
- Extending the `_build` cache to host-integration, browser-uat, the admin jobs and `_build/dev`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RLS-01 | The release-please 1.7.0 PR is aligned on its branch (README pins, companion notes, curated adopter-readable CHANGELOG instead of raw phase-scoped lines) and green on its exact head. | Bump verified (Q3); gates and exact edits enumerated (Q4); 1.6.0 alignment precedent extracted (Q4); curated drafts proven against the contract script (Q5, Appendix A); root-cause fix so alignment survives (Q1). |
| RLS-02 | Hex publication happens only after an explicit maintainer yes, decision recorded. | Yes is recorded in CONTEXT (verbatim quote above); publish path, ordering, partial-failure detection and read-only verification (Q6). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- All repo edits go through a GSD workflow (`/gsd-execute-phase` for planned phase work); no direct edits outside it.
- **Executable Acceptance Policy:** no `type="tracer"`, no `checkpoint:human-verify`, no `<human-check>` where an executable assertion can decide. Human interaction only for genuine product decisions, credential/bootstrap actions, or irreversible external operations. Phase completion needs SUMMARY coverage with `human_judgment: false`, generated automated UAT, `VERIFICATION.md` `status: passed` / `behavior_unverified: 0`, and the executable-UAT CI contract.
- **Working discipline:** commit verified work the moment it passes; never `git reset --hard`/`checkout --`/`clean -fd` with uncommitted work (use `--soft`); never exercise git behavior in the live tree (use `mktemp -d` + `git init`). A check that finds nothing must be shown to find a known positive first; `git grep -c -- "<pat>"` is a known silent-zero footgun (use `-e`). A guard must not spell out what it guards against (no hard-coded usernames/tokens; redact in output). After any milestone archive run `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .`, and route phase-evidence path reads through `scripts/ci/phase_evidence_path.mjs`.
- Core stays LiveView-runtime-free; release model is "ship complete" (no v0.x cycle); MIT; CHANGELOG per package.

## Summary

PR #50 was emptied by this repo's own workflow, not by release-please. In `.github/workflows/release-please.yml` the "stale-base repair" (lines 177-195) force-resets `release-please--branches--main` to `origin/main` whenever `main` has moved since the release commit was authored, then calls `release-pr` again expecting release-please to re-create the release commit. release-please's `release-pr` only rewrites a PR when the **computed PR body differs from the existing PR body** (`maybeUpdateExistingPullRequest`, `manifest.js` ~L560). When `main` moves by commits that do not change the notes (docs/ci/planning merges), the body is identical ("PR #50 remained the same", logged at 02:21:58 in run 40257272990), nothing is re-created, the branch stays equal to `main` (0 files), and the next line (`verify_release_pr_scope.sh`) fails. GitHub then auto-marked the PR merged when #52 landed (head == an ancestor of main), leaving a merged PR labelled `autorelease: pending`. The same empty-merged signature occurred before (PRs #26, #27, #28, #33).

That stale `pending` label is now a live hazard in two ways, both proven read-only: (1) `release-pr` aborts with "There are untagged, merged release PRs outstanding - aborting" (run 40281358545 log), so no new 1.7.0 PR will ever open, silently, with a green job; (2) `github-release --dry-run` against the real repo shows it would create `accrue-v1.7.0`, `accrue_admin-v1.7.0`, `accrue_portal-v1.7.0` **at `b4310a39`** (PR #50's empty merge commit, manifest still 1.6.0). Today only the workflow's "all manifest releases already exist" guard prevents that; the moment the real 1.7.0 release PR merges (manifest -> 1.7.0, no 1.7.0 releases exist) that guard opens and #50 would race the real PR for the tags. The label must be removed **before** the real release PR is merged.

The bump is verified: a read-only `release-pr --dry-run` at `main`=`db1b6d85` plans one PR "chore: release main", `updates: 7`, all three packages `1.6.0 -> 1.7.0` (linked-versions), no commit-window truncation warning, and a body byte-identical (modulo blank lines) to PR #50's. The #49 merge commit is the only unparseable commit and is ignored; its ~993 constituent commits are parsed individually. 1.7.0's raw notes are 8+10 (core), 61+107 (admin), 18+23 (portal) feature+fix lines, nearly all `**2xx-yy:**`-scoped, and the raw candidate fails `verify_release_notes_contract.sh` ("accrue_admin/CHANGELOG.md must remain compatibility-only"). A curated draft (Appendix A) plus README pins plus `### 1.7.0` release-notes stories, applied to an exported tree in scratch, passes `verify_release_notes_contract.sh`, `verify_release_manifest_alignment.sh` and `verify_package_docs.sh`.

**Primary recommendation:** Fix the workflow first by **deleting** the reset/force-push/second-`release-pr` block (never write to the release branch from automation) and adding a loud "merged-but-untagged release PR outstanding" detector, guarded by a new hermetic verifier with a legacy-block negative control; merge that fix (squash, exact-head green) with Phase 251's bootstrap evidence; only then remove `autorelease: pending` from #50 (needs an explicit maintainer-authorized remote write), dispatch Release Please, freeze `main`, align the fresh PR's branch with plain fast-forward pushes, get the exact head green, merge with a **merge commit** pinned by `--match-head-commit`, and verify tags, publish jobs, hex.pm and hexdocs read-only.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release PR generation (versions, notes, 7 file updates) | release-please 17.6.0 (CI, remote) | GitHub API | Computed from conventional commits since last tag; repo only supplies config/manifest. |
| Release-branch alignment (pins, release-notes story, curated CHANGELOG) | Git branch of the release PR | Local verifiers | release-please cannot author these; humans push fast-forward commits to the release branch. |
| Release contract enforcement | `scripts/ci/*` + `ci.yml` jobs | `release-please.yml` canary | Merge-blocking gates run on the PR; `verify_release_pr_scope` runs only inside the release workflow. |
| Tagging + GitHub Releases | release-please `github-release` (push to main) | `release_exists` guard in workflow | Created from the merged PR's body + label state. |
| Hex publish (accrue -> admin -> portal) | `release-please.yml` jobs `publish-*` | `publish-hex.yml` (manual recovery only) | `needs:` chain enforces order; `HEX_API_KEY` secret. |
| Post-publish proof | `linked-release-proof` job + read-only curl | `capture_linked_release_proof.sh` | Hex API + hexdocs + host Hex smoke. |
| Phase evidence | `.planning/phases/251-*` | `scripts/ci` SL-G / exec-UAT | VERIFICATION covered_digest minted only via `computeDigest`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| release-please (npx) | 17.6.0 (pinned in `release-please.yml:55` and `verify_release_pr_readiness.sh`) | Release PR + tags + GitHub Releases | Already the repo's pinned release engine; do not bump in this phase. |
| `gh` CLI | local, authenticated (`gh auth token` works read-only) | PR/label/run inspection, merge | Used by every repo release script. |
| bash/jq/node | repo-standard | Verifiers and self-tests | `scripts/ci` convention (`--self-test`). |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `250-ci-head-status.mjs` | in `.planning/phases/250-remote-integration/` | Exact-head verdict (`--event pull_request --pr-base main`) | Before merging the fix PR and the release PR. Note: milestone archive moves this file; reference via `phase_evidence_path.mjs` after v1.67 close. |
| `scripts/ci/verify_release_pr_scope.sh` | repo | Release PR file/version contract (`--pr N --version 1.7.0`) | After alignment push; read-only (uses `gh api`). |
| `scripts/ci/capture_linked_release_proof.sh` | repo | Hex API + hexdocs + release proof | Run by `linked-release-proof`; reusable locally after publish. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Delete the reset block (recommended) | Replace with `git merge origin/main` into the release branch | Merge-update preserves "branch contains current main tree" but moves the PR head (invalidates exact-head greens) and a `GITHUB_TOKEN` push triggers no CI (see Pitfall 4). Only choose if the maintainer wants the branch kept current. |
| `always-update: true` in `release-please-config.json` (schema-valid, `manifest.js:886`) | - | Rebuilds the branch on every main push, wiping every alignment commit; incompatible with branch-side alignment. Reject. |
| Editing the release PR body to curated text | Leave raw body, curated CHANGELOG + release-notes carry the story | An edited body differs from the computed body, so the next release-pr run rewrites the branch and wipes alignment. Reject; optionally `gh release edit --notes-file` after tagging. |

**Installation:** none (no new packages). `release-please@17.6.0` runs via `npx --yes`.

**Version verification:** `npm view release-please@17.6.0 version` -> `17.6.0`, modified 2026-08-24 [VERIFIED: npm registry]. Source for this research was `npm pack release-please@17.6.0` extracted in scratch (`.../scratchpad/251-research/rp/package/build/src`).

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| release-please | npm | published 2026-08-24 (17.6.0); project long-established | 236,096/wk | github.com/googleapis/release-please | [OK] (`gsd-tools query package-legitimacy check --ecosystem npm release-please`, postinstall null) | Approved (already pinned by repo; no install) |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
No other external packages are introduced by this phase.

## Architecture Patterns

### System Architecture Diagram

```
push to main / workflow_dispatch
        |
        v
 release-please.yml :: job "release"
   |-- (guard) all 3 manifest releases exist? --yes--> skip github-release
   |                                           --no---> release-please github-release
   |                                                      reads MERGED PRs labelled "autorelease: pending"
   |                                                      (body -> notes; merge sha -> tag target)   <-- #50 hazard
   |-- release-pr  ---------------------------------------------------------------+
   |      |-- any MERGED+pending PR?  yes -> "outstanding - aborting" (green job)  | <-- silent wedge
   |      |-- open PR body == computed body?  yes -> "remained the same" (no write)| <-- why #50 stayed empty
   |      '-- else code-suggester force-rebuilds branch = main tip + 1 release commit
   |-- [DEFECT] stale-base block: merge-base != main tip -> reset branch to main + force push
   |-- portal lag repair (repair_linked_release_pr.sh) -> plain push
   '-- verify_release_pr_scope.sh --pr N   (fails on 0-file PR: the canary that fired)

release PR (branch release-please--branches--main) --pull_request--> ci.yml / accrue_admin_browser.yml
   gates: release-manifest-ssot, docs-contracts-shift-left (notes contract, package docs), release-gate x4 ...
merge (merge commit) -> push to main -> job "release": manifest=1.7.0, no releases -> github-release
   -> tags+releases (sha = merge commit) -> publish-accrue -> publish-accrue-admin -> publish-accrue-portal
   -> linked-release-proof (needs all three success)
```

### Recommended Project Structure
```
.github/workflows/release-please.yml        # delete lines 177-195 reset block; add outstanding-merged-PR detector
scripts/ci/verify_release_branch_repair_safety.sh  # NEW: static reject + --self-test (legacy negative control + git fixture)
scripts/ci/verify_release_contract.sh       # lines 64-66: stop requiring force-with-lease; require/reject new patterns
.github/workflows/ci.yml                    # wire new verifier in release-manifest-ssot (after ci.yml:552)
RELEASING.md (step 3, ~L77) + scripts/ci/README.md (~L536)  # manual remedy text has the same defect
.planning/phases/251-1-7-0-release-alignment/251-mint-close-artifacts.mjs  # mirror of 250 minter
```

### Pattern 1: Deterministic head during alignment ("freeze window")
**What:** Once release-please opens the fresh PR, no further push to `main` until the release PR merges. Alignment commits are plain fast-forward pushes by the maintainer's credentials (which trigger `pull_request` CI).
**When to use:** always for this repo's release PRs.
**Why:** any push-to-main run recomputes the body; if notes changed (new `feat`/`fix` touching a package path) release-please force-rebuilds the branch and discards alignment (code-suggester `force: true`, `github.js` ~L578-590). With the defect fixed, docs/ci/planning-only pushes are harmless ("remained the same").

### Pattern 2: Hermetic negative-control self-test (house style)
**What:** `--self-test` that runs the legacy behavior in a `mktemp -d` bare-origin fixture and asserts the defect (0 changed files), then asserts the fixed workflow passes and the legacy workflow text fails the static rule. Models: `scripts/ci/prune_first_party_build.sh` (`self_test`, positive + missing + negative control, wired at `ci.yml:191`) and `scripts/ci/verify_no_home_paths.sh --self-test` (`ci.yml:291`).
**Prototype (executed, passes):** `.../scratchpad/251-research/sync_release_branch_prototype.sh` output: `negative control OK: legacy repair leaves 0 changed files (reproduces PR #50)` / `positive OK` / `conflict OK`. (It still prints `tmp: unbound variable` from an EXIT trap on a `local` - fix when productionising.)

### Anti-Patterns to Avoid
- **Automation writing to the release branch to "repair" base:** destroys either the release commit (reset) or the exact-head CI (merge push with `GITHUB_TOKEN`).
- **Treating a green Release Please job as success:** `release-pr` logs "aborting" / "remained the same" and still exits 0 (1.6.0 and #50 both). Detect with `gh pr list --state merged --label "autorelease: pending"`.
- **Editing the PR body, or enabling `always-update`:** both make the next run rebuild the branch.
- **`gh pr merge --auto` / squash / rebase for the release PR:** see Q7.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version/bump computation | manual manifest/mix.exs edits | release-please linked-versions | Reproduced 1.7.0; `verify_release_pr_readiness.sh` asserts 7 updates / 3 module-attribute lines. |
| Exact-head CI verdict | reading the PR check rollup | `250-ci-head-status.mjs --sha <40hex> --event pull_request --pr-base main` | Judges latest attempt of newest run per workflow at that head; names failing step. |
| covered_digest | hand-typed hashes | `scanArtifact` + `computeDigest` via the minter | Repo rule; a hand digest is rejected by SL-G. |
| Hex/hexdocs verification | scraping HTML | `https://hex.pm/api/packages/<p>/releases/<v>` (`has_docs`) + `https://hexdocs.pm/<p>/<v>/readme.html` | Validated against 1.6.0 below. |
| Duplicate-release protection | ad-hoc tag deletion | remove the stale label before the manifest bump | Deleting tags/releases is destructive and out of authorization. |

**Key insight:** every failure mode here is a *silent success* (green job, no PR, empty PR, wrong-sha tags). Gate on positive facts (7 files, three `## [1.7.0]` headings, three tags at the merge SHA) and prove each detector against a known positive.

## Runtime State Inventory

(Phase involves recovering stale release-system state; not a rename, but the same discipline applies.)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | GitHub PR #50: MERGED, 0 files, label `autorelease: pending` [VERIFIED: `gh pr view 50`] | Remove the `pending` label (remote write; needs explicit go). |
| Live service config | Remote branch `release-please--branches--main` @ `b4310a39` (== old main, 0 diff); object `963ad2cd` (release-please's original 7-file commit, parent `3dd5f874`) still resolvable via API and in local object store [VERIFIED: `gh api commits/963ad2cd`, `git cat-file -t`] | Leave branch; release-please force-updates it. Do not delete. Patch saved at scratchpad `963ad2cd.patch` for reference. |
| OS-registered state | None - no tasks/services reference this | None |
| Secrets/env vars | `HEX_API_KEY`, `RELEASE_PLEASE_TOKEN` exist (created 2026-04-16) [VERIFIED: `gh secret list`] | None; no rename. |
| Build artifacts | None. Tags: only `accrue-v1.6.0`/`accrue_admin-v1.6.0`/`accrue_portal-v1.6.0` @ `ca8f6655`, no 1.7.0 tag/release; `hex.pm/api/packages/<p>/releases/1.7.0` -> 404 for all three [VERIFIED] | None. |

## Common Pitfalls

### Pitfall 1: Relabel order - stale `pending` label vs. the manifest bump
**What goes wrong:** If #50 is still `pending` when the real release PR merges, `github-release` iterates both merged-pending PRs (`manifest.js` `findMergedReleasePullRequests`) and may create `*-v1.7.0` tags at `b4310a39` (wrong commit). The publish jobs then check out that SHA, `grep '@version "1.7.0"'` fails (mix.exs there says 1.6.0), publish is blocked, and tags/releases exist that only destructive remote ops can undo.
**Why:** The workflow guard that currently skips `github-release` (`release-please.yml:120-123`) keys on the manifest version, which flips on merge. Precedent: #26's empty merge produced a "Created releases ... 1.3.0" comment.
**Avoid:** Remove `autorelease: pending` from #50 after the fix PR lands and before the new release PR is merged; verify with `gh pr list --state merged --label "autorelease: pending"` -> `[]` (positive control: returns #50 today; nonexistent label returns `[]`).
**Warning signs:** `Found pull request #50` in a `github-release` dry-run; run log line `There are untagged, merged release PRs outstanding - aborting`.

### Pitfall 2: Main pushes during the alignment window
**What goes wrong:** Any push to `main` re-runs Release Please. With the defect unfixed: reset + empty PR. With the fix: harmless unless notes change, then branch rebuilt and alignment lost.
**Avoid:** Land the fix PR and Phase 251 bootstrap evidence **before** relabel/dispatch; no other merges until the release PR merges; the close-evidence PR goes after publish.

### Pitfall 3: Contract text, not just contract presence
`verify_release_notes_contract.sh:112-124` requires the admin and portal `## [1.7.0]` CHANGELOG sections to contain `Compatibility only:`, `linked 1.7.0`, `core`, `package owns`, and forbids (case-insensitive, per line) `admin-owned|portal-owned|new .*workflow|new .*API|grant authority|authorization behavior`. `new .*API` matches any line with `new ` followed by `api` inside any word (e.g. "capability"). Avoid the token `new ` in those sections. The raw candidate fails this gate at `assert_companion_compatibility_only` (reproduced). It also needs `### 1.7.0` under `## accrue` and `## accrue_admin` in `release-notes.md` (lines 231-234). Run the script locally before every alignment push.

### Pitfall 4: `GITHUB_TOKEN` pushes do not trigger CI
Events created by `GITHUB_TOKEN` do not create new workflow runs [CITED: docs.github.com/en/actions/using-workflows/triggering-a-workflow]. The repair's `git push` (default checkout credentials) is such a push; PR #50's force-push was by `github-actions[bot]` [VERIFIED: PR #50 timeline 02:13:52]. Any automated write to the release branch leaves the new head without CI. Another reason to remove the repair and to have the maintainer's credentials push alignment commits.

### Pitfall 5: SC1 grep literal is vacuous; scope is ambiguous
Release-please renders `* **233-05:** ...`, never `feat(233-05)`; a literal `feat\(2` grep returns zero on the raw candidate. Historic sections already contain 243/46/22 phase-scoped lines (core/admin/portal) [VERIFIED: grep]. Define the check as: within the `## [1.7.0]` section only, no line matches `^\* \*\*([0-9]{3}|phase-[0-9]+|quick-[0-9]+)` or `feat\([0-9]{3}`; positive control on the raw candidate (`963ad2cd`) hits 17/155/41, curated drafts hit 0 (executed). Rewriting released sections is out of scope. Flagged as A1.

### Pitfall 6: Post-merge `main` push is red unless pins are aligned
`verify_package_docs.sh:503-509` enforces README/first_hour pins `~> $version` but is skipped on release-please PRs (`ci.yml:250` sets `RELEASE_PLEASE_PR`; script `:104`, `:503`). Reproduced: raw candidate passes with `RELEASE_PLEASE_PR=1`, fails without ("accrue/README.md is missing: {:accrue, "~> 1.7.0"}"). So pins must be aligned on the branch even though the PR gate does not require it, or the first post-merge main push goes red.

### Pitfall 7: Release-PR readiness gate depends on a remote branch
`verify_release_pr_readiness.sh:~63` defaults `TARGET_BRANCH` to `integration/v1.62-candidate-recut` (exists; manifest 1.5.1). Do not delete `integration/v1.62-*` branches during cleanup or the merge-blocking `release-manifest-ssot` job breaks.

### Pitfall 8: Post-merge push CI and Hex smoke ordering
On the release merge push, `ci.yml:1623-1627` runs the host Hex smoke which polls hex.pm up to `ACCRUE_HOST_HEX_SMOKE_WAIT_SECONDS`; it can be red/yellow while publish is in flight. Judge "main green" after publish completes.

## Code Examples

### Read-only dry runs (executed this session; no writes)
```bash
# Plan the PR (read-only, ~9-10 min: walks 1014 commits)
npx --yes release-please@17.6.0 release-pr --dry-run --repo-url szTheory/accrue --target-branch main \
  --config-file release-please-config.json --manifest-file .release-please-manifest.json --token "$(gh auth token)"
# What github-release WOULD tag right now (shows the #50 hazard)
npx --yes release-please@17.6.0 github-release --dry-run ... same flags ...
```
Observed: `Would open 1 pull requests`, `title: chore: release main`, `updates: 7`, three `updating module attribute version from 1.6.0 to 1.7.0`, no `Expected N commits, only found M`; github-release dry run: tags `accrue-v1.7.0`, `accrue_admin-v1.7.0`, `accrue_portal-v1.7.0`, `sha: 'b4310a39...'`, `pullNumber: 50`.

### Wedge detector (positive control verified)
```bash
# In release-please.yml after the release-pr step: fail loudly instead of reporting success
outstanding="$(gh pr list --repo "$repo" --state merged --label 'autorelease: pending' --json number --jq '.[].number')"
if [ -n "$outstanding" ]; then
  echo "::error::merged release PR(s) still labelled autorelease: pending (${outstanding//$'\n'/ }); release-please will not open a new release PR" >&2
  exit 1
fi
```
Placement matters: after any `github-release` call so a legitimately in-flight tagging run is not flagged. Today it returns `50`; `--label "autorelease: nonexistent-xyz"` returns `[]`.

### Read-only post-publish verification (validated against 1.6.0)
```bash
for p in accrue accrue_admin accrue_portal; do
  curl -fsS "https://hex.pm/api/packages/$p/releases/1.7.0" | jq -r '[.version,.has_docs,.inserted_at]|@tsv'
  curl -fsSIL -o /dev/null -w '%{http_code}\n' "https://hexdocs.pm/$p/1.7.0/readme.html"   # 200
done
git ls-remote --tags origin 'refs/tags/accrue*-v1.7.0'    # 3 tags, all == merge commit SHA
gh release view accrue-v1.7.0 --json tagName,targetCommitish,isDraft,isPrerelease
```
(`changelog.html` is 404 on hexdocs for 1.6.0; do not use it as a check.)

## Answers to the research questions

### Q1. Root cause, fix, and self-test

**Evidence chain** [VERIFIED: run logs 40257272990 / 40281358545, PR #50 timeline, `manifest.js`]
1. 00:14:56 release-please authored `963ad2cd` (7 files, parent `3dd5f874`); 00:14:58-59 PR #50 opened, labelled `autorelease: pending` by the PAT user.
2. #51 merged 02:04:17 -> run 40257272990. First `release-pr` (workflow L166): computed body identical to #50's body -> `PR .../pull/50 remained the same` (02:13:48). No update.
3. L177-184: `git merge-base HEAD origin/main` != `origin/main` (main had moved) -> `git checkout -B release-please--branches--main <main tip>` + `git push --force-with-lease` (log: `+ 963ad2cd...b4310a39 (forced update)`, pushed by `github-actions[bot]`, 02:13:52).
4. L186-191 second `release-pr`: body still identical -> `remained the same` again (02:21:58). The release commit is never re-created.
5. L213 `verify_release_pr_scope.sh`: `PR #50 is missing required release file: .release-please-manifest.json` -> run failed 02:22:00.
6. 05:48:07 #52 squash-merged to main; 05:48:08 #50 auto-marked MERGED (head `b4310a39` was already an ancestor of main; mergeCommit == head, 0 files). Label stays `pending`.
7. Run 40281358545 (06:42, success): "All manifest releases already exist; skipping" (L120-123) for `github-release`; `release-pr` logs `Found pull request #50` then `There are untagged, merged release PRs outstanding - aborting`; job green, no PR.

**Why the second call cannot work:** `Manifest.maybeUpdateExistingPullRequest` compares only `existing.body` (the PR description) to the freshly computed body; branch contents are never inspected. Whenever notes are unchanged the branch is not rebuilt, so a force-reset to `main` is unrecoverable by re-running `release-pr`. Conversely when notes *do* change, release-please already rebuilds the branch from the current main tip (`force: true`), so the repair is redundant in exactly the case where it would be safe.

**Recurrence:** PRs #26, #27, #28, #33 were also merged with `changedFiles: 0`; #26/#28/#33 timelines show a `head_ref_force_pushed` by `github-actions[bot]` [VERIFIED: gh timeline]; #27 cause inferred [ASSUMED].

**Minimal correct fix (recommended):** in `.github/workflows/release-please.yml` delete lines 179-195 (the `expected_base` / `actual_base` / reset / force push / second `release-pr` / re-fetch). Keep fetch + checkout (L173-177) and the portal-lag repair and scope canary. Rationale: GitHub merges a stale-but-conflict-free branch with a merge commit; `pull_request` CI runs on `refs/pull/N/merge` (includes current main); real conflicts surface loudly; RELEASING.md's stated purpose ("contains the current main tree") is satisfied by the merge commit. Add the wedge detector above. Update:
- `scripts/ci/verify_release_contract.sh:64` currently *requires* the literal `git push --force-with-lease origin HEAD:"$release_branch"`; replace by rejecting that literal and `git checkout -B "$release_branch" "$expected_base"` (keep `:65-66`).
- `RELEASING.md` step 3 (~L77) and `scripts/ci/README.md:~536` document the same broken manual remedy ("reset ... back to main, rerun Release Please"). Correct remedy for a stuck/stale PR: close the PR and delete the remote branch, then dispatch Release Please (no open PR -> it creates one).
- Route-2 alternative (merge-update) is acceptable only with the PAT-push and head-invalidation caveats (Alternatives table).

**Hermetic self-test (recommended shape):** new `scripts/ci/verify_release_branch_repair_safety.sh` (house style, `--self-test`, captured-then-filtered greps to satisfy `verify_pipefail_grep_idiom.mjs`), wired into `release-manifest-ssot` next to `ci.yml:551-552`:
1. Static: `release-please.yml` must not contain a force push to `$release_branch` or `checkout -B "$release_branch"` from `$expected_base`; must contain the outstanding-PR detector and the `verify_release_pr_scope.sh --pr` canary.
2. `--self-test` negative control A (text): feed the verbatim legacy block (db1b6d85 L177-195) as fixture -> the static rule must FAIL.
3. `--self-test` negative control B (behavioral): bare-origin fixture (prototype): release branch = main + release commit; advance main with a docs commit; run the legacy algorithm -> assert `diff main...release` is **empty** (reproduces #50). Run the (now no-op) fixed path -> assert release files still present.
4. Positive: current workflow passes.
Record in the SUMMARY the exact FAIL output of A and B on the legacy block and PASS on the fix (negative control proven able to fail).

### Q2. Recovering from #50

`autorelease: pending` semantics in 17.6.0 [VERIFIED: `manifest.js` L35-38, L478-482, L606-640, L720-752]:
- `DEFAULT_LABELS=['autorelease: pending']`, `DEFAULT_RELEASE_LABELS=['autorelease: tagged']`; the only labels read are pending (open + merged PR discovery), snapshot, and `autorelease: snooze` (closed PRs only). `autorelease: closed` is **not** a release-please label.
- `github-release`: every MERGED PR carrying all of `labels` whose body parses is a release to create (tag target = PR merge SHA). Dry-run proves it would create the three 1.7.0 releases at `b4310a39`.
- `release-pr`: `createPullRequests` returns early with `untagged, merged release PRs outstanding - aborting` if any such PR exists, *before* touching open/snoozed PRs.
- After creating (or detecting duplicate) releases release-please itself swaps `pending` -> `tagged` (`createReleasesForPullRequest`).

Recovery options:
| Option | Effect on next runs | Verdict |
|---|---|---|
| Remove `pending` (precedent: #33 unlabeled 2026-08-19) | Both commands ignore #50; new PR opens; nothing tagged | **Recommended.** Truthful: nothing was tagged. |
| Relabel `autorelease: tagged` (precedent #26/#28; release-please does this itself on duplicate-detection) | Same effect | Works, but asserts a false "tagged" state; use only if the maintainer wants parity with #28. |
| `autorelease: closed` | Equivalent to removal (unknown label) | Pointless extra label. |
| Run `github-release` to let it self-heal | Creates wrong-sha 1.7.0 releases | **Never.** |

Command (needs explicit maintainer go; not run here): `gh pr edit 50 --repo szTheory/accrue --remove-label "autorelease: pending"` (optionally a PR comment explaining). Verify: `gh pr list --state merged --label "autorelease: pending"` -> `[]`. Then dispatch `gh workflow run release-please.yml --ref main` (workflow_dispatch exempt from the GITHUB_TOKEN trigger rule; release-please then sees no outstanding PR, no open PR, and creates a fresh PR on the existing branch name, which it force-updates; precedent #26->#28 reused the name).

Branch tip `963ad2cd`: **not reusable** (base `3dd5f874` predates #51-#53; raw notes; not release-please-owned state). Useful only as a reference oracle: it is the exact 7-file release commit shape (`.release-please-manifest.json`, 3x `mix.exs`, 3x `CHANGELOG.md`), and today's dry-run body equals the body recorded in #50, so a regenerated PR will be equivalent. Patch is saved in scratchpad; object may be GC'd by GitHub eventually, so do not depend on it.

### Q3. The bump

Read-only `release-pr --dry-run` (run against live `main`=`db1b6d85`, token from `gh auth token`, no writes):
- `Replacing strategy for path accrue|accrue_admin|accrue_portal with forced version: 1.7.0` - this is the LinkedVersions plugin picking the max of the three component bumps (`plugins/linked-versions.js` L45-62); the "release-as configuration" warning is that plugin, not a `Release-As:` footer (none exists after `ca8f6655`).
- Per-component commits considered: accrue 24, accrue_admin 268, accrue_portal 62; `commit-search-depth: 2000` covers 1014 commits since `ca8f6655`; no truncation warning (this is what `verify_release_pr_readiness.sh` assertion 2 greps).
- No breaking commits (`!:` / `BREAKING CHANGE`) in `ca8f6655..HEAD` [VERIFIED: git grep], so no major.
- `3dd5f874 Merge pull request #49 ...` fails conventional parsing ("unexpected token ' ' at 1:6") and is ignored; its constituent commits are parsed individually. So the merge commit does not alter the bump or notes. Body == PR #50's body (diff empty modulo blank lines).
- Raw sections: core 8 features + 10 fixes; admin 61 + 107; portal 18 + 23; hidden types (docs/chore/ci/test/refactor) excluded. Date stamped = generation date. Commits touching only `.github/` / `scripts/` (like #52/#53 and the planned fix PR) belong to no package (no root package), so they do not change the notes - keep the fix PR out of `accrue*/` paths.
- Runtime: each release-pr/dry-run takes ~9-10 min (commit file backfill); the workflow job has no timeout override.

### Q4. Gates on the release PR (file:line), and the 1.6.0 alignment precedent

| Gate | Where | Release-PR behavior |
|---|---|---|
| Scope: 7 required files, manifest versions, `@version`, `## [` heading, `## [$TARGET]` | `scripts/ci/verify_release_pr_scope.sh:111-148`; invoked at `release-please.yml:213` (not in PR CI) | Passes on release-please's output; run manually after alignment: `bash scripts/ci/verify_release_pr_scope.sh --pr N --version 1.7.0`. Extra files (README etc.) are allowed (#46 had 12 files). |
| Manifest/@version lockstep + same-minor `{:accrue, "~> #{@version}"}` | `scripts/ci/verify_release_manifest_alignment.sh:1-91`; `ci.yml:543` | Green on raw candidate (reproduced). |
| Linked release contract (config, RELEASING.md, workflow needles) | `scripts/ci/verify_release_contract.sh:44-77` (needles), `:64` force-with-lease needle, `:123-196` v1.59 contract; `ci.yml:546` | Green, but `:64` must change with the workflow fix. |
| Title round-trip | `scripts/ci/verify_release_pr_title_roundtrip.sh`; `ci.yml:551-552` | Green (no group pattern -> "chore: release main"). |
| Release PR readiness dry-run | `scripts/ci/verify_release_pr_readiness.sh` (7 updates, 3 attr lines, >current); `ci.yml:569` | Reads remote `integration/v1.62-candidate-recut`; independent of PR content (Pitfall 7). |
| Release-notes freshness | `scripts/ci/verify_release_notes_contract.sh:149-165` (numbered `## [1.7.0]` in all three), `:112-124,192-193` (companion compat-only), `:231-234` (`### 1.7.0` under `## accrue` and `## accrue_admin`); `ci.yml:297-298` | **Red on raw candidate** (reproduced); fixed by Appendix A. Also exercised by `accrue/test/accrue/docs/release_notes_contract_test.exs` (version-agnostic seeder, fine). |
| Package docs | `scripts/ci/verify_package_docs.sh:503-509` pins; skipped when `RELEASE_PLEASE_PR` (`ci.yml:249-251`) | Skipped on PR, enforced on post-merge main (Pitfall 6). |
| Sensitive-token census / no home paths | `ci.yml:233-237`, `:290-292`; `verify_sensitive_token_census.mjs:77` marks `CHANGELOG.md`/`README.md` always-forbidden for tokens | Keep curated text free of names, emails, absolute paths. |
| Everything else in `ci.yml` / browser workflow | Required set in `250-ci-head-status.mjs` `CI_REQUIRED` | Same exact-head bar as Phase 250 (`success`, not `skipped`); parked/PR-must-skip lists per helper. Release PR touches `accrue/` + `accrue_admin/` so the browser workflow runs; use `--pr-base main`. |

**1.6.0 alignment precedent (PR #46, branch commits after release-please's `fa66ce8c`)** [VERIFIED: `git show`]: `88d77207` edited `accrue/README.md` (pin `~> 1.5.1`->`1.6.0`), `accrue/guides/first_hour.md` (two pins), `accrue_admin/README.md` (pin + "resolve `accrue ~> ...`" sentence), `accrue/guides/release-notes.md` (`### 1.6.0` under `## accrue` and `## accrue_admin`), and a `### Notes` block ("Compatibility only: the linked 1.6.0 release accepts ... The core `accrue` package owns those capabilities; this package owns only its existing UI surface.") in `accrue_admin/CHANGELOG.md` and `accrue_portal/CHANGELOG.md`; `3b286b22` fixed the release-notes test seeder; `5ede0dbc` reworded. 12 files total. For 1.7.0 the equivalent set is: 4 README/first_hour pin occurrences (`accrue/README.md:38`, `accrue/guides/first_hour.md:95-96`, `accrue_admin/README.md:24` and `:84`), release-notes (2 stories), and 3 curated CHANGELOG sections. **Difference this time:** 1.6.0's CHANGELOGs kept the raw bullets under the Notes block; 1.7.0 must replace the raw `## [1.7.0]` body (SC1) with curated house-style text (`### Release highlights` + `### Notes`, as the curated 1.5.0/1.5.1 core entries).

### Q5. CHANGELOG curation

Adopter-facing inventory (from raw sections + commit diffs under `accrue/`):
- **v1.63-v1.66 (admin/portal):** Portal context resolution/authorization pinned per action (host-owned policy), scoped hosted invoices, Braintree Hosted Fields checkout and POST guards, expired-checkout recovery; Admin scoped return journeys, action revalidation/step-up, labeled filters/search, Local/UTC timestamps with exact-value copy, event labels/replay evidence, 320px/touch fixes.
- **Core-owned (verified in diffs):** checkout/`LocalSession` retry, reconcile and eligibility changes (`lib/accrue/checkout*.ex`), Braintree decline outcomes, processor action gating (`fake.ex`/`stripe.ex`/`braintree.ex`), atomic webhook replay claim + bulk owner-scope revalidation (`webhooks/dlq.ex`), dispatch-time manual-invoice-item validation (`billing/invoice_actions.ex`), dunning/recovery evidence amounts (`analytics/dunning.ex`), `:admin_branding` `theme` config key (`config.ex`, `guides/branding.md`), install template `portal_organization_for/2` + `authorize_portal_action/5` default hooks (`priv/accrue/templates/install/billing.ex.eex`), `brand.css` status/accent colors.
- **Owner-feedback range `3d7d949d..b4a7eeac` (11 `fix(admin)` commits, 2026-10-12..19):** quieter header controls, Home/event/timeline clarity, list controls and billing evidence, unified gutters, record labels, infinite lists keep all rows + end-of-list, default payment-method wording. Receipts: `.planning/notes/2026-10-1[1-4,8]-admin-owner-feedback.md`. No plan/verification is claimed; describe as fixes only.
- **v1.67 fixes:** 249-08/249-09 320px reflow (admin), 250-03 shared keyboard focus ring (admin; `priv/static/accrue_admin.css` rebuilt in the same commit `6fc488cd`, so it ships), 249-01..02 compile/credo/test hygiene (not adopter-facing), 250-04 portal Braintree stub (test-only), 250-03 CI seed-boundary (CI-only). Mention only 320px reflow and focus ring.
- **Known issue (D2):** `accrue_events.inserted_at` follows DB session timezone; fix deferred to v1.68. No prior "Known issues" convention exists in the CHANGELOGs/release-notes (grep empty) - so including it is a maintainer call (Open Question 2); draft includes it in core.

House style for curated entries: `accrue/CHANGELOG.md` 1.5.0 (`### Release highlights`, prose bullets, no hashes) and 1.5.1 (`### Bug Fixes` prose bullets); companion packages use a `### Notes` "Compatibility only:" bullet (1.5.1, 1.6.0). Curated drafts (Appendix A) were applied to an exported copy of `main` + the raw candidate patch and **passed** `verify_release_notes_contract.sh` ("OK (1.7.0)"), `verify_release_manifest_alignment.sh`, and `verify_package_docs.sh` (no `RELEASE_PLEASE_PR`), and the SC1/forbidden-phrase lints were clean. Claims in the drafts are derived from commit subjects/diff stats; the executor must verify each against the code before pushing (A2). Note the contract's "compatibility-only" framing is stale for 1.7.0 (admin/portal are the substance): satisfy it honestly (compatibility with core + "this package owns only its existing UI surface, refined as listed") rather than weakening the gate; if the maintainer prefers to evolve the gate, that is a separate controlled change.

### Q6. Publish path

- **Trigger/order:** publishing is in `release-please.yml`, not `publish-hex.yml`. On the merge push: job `release` runs `github-release` (guard `:120-131`), computes `*_release_created` (`:61-93`; lockstep fallback `:140-164`), then `publish-accrue` (`:216`) -> `publish-accrue-admin` (`:245`, `needs: [release, publish-accrue]`, `ACCRUE_ADMIN_HEX_RELEASE=1` switches its dep to Hex `{:accrue, "~> 1.7.0"}`, `accrue_admin/mix.exs:116-119`) -> `publish-accrue-portal` (`:278`, needs both) -> `linked-release-proof` (`:311`, runs only if all three succeeded). Each publish job: checkout tag SHA, `grep '@version "1.7.0"'`, `mix hex.publish --dry-run`, then `mix hex.publish --yes`. `publish-hex.yml` is `workflow_dispatch` only (inputs `package`, `tag`, `release_version`): the **manual recovery** path (CONTEXT: "last ran in August" matches).
- **Secrets:** `HEX_API_KEY` (publish), `RELEASE_PLEASE_TOKEN` (release-please + label/PR writes); both present. Main is unprotected and there are no rulesets [VERIFIED: API 404], so "required checks" is policy enforced by the head-status helper, not by GitHub.
- **Partial-failure detection:** (1) `gh run view <run> --json jobs -q '.jobs[]|[.name,.conclusion]'`; (2) per-package `hex.pm/api/packages/<p>/releases/1.7.0` (404 = not published); (3) `linked-release-proof` skipped/failed means not all three succeeded. Typical partial: accrue on Hex, admin missing. Per CONTEXT: **stop and report**; do not yank/retire/re-dispatch without the maintainer. Hex allows replacement only briefly after publish; a re-publish after that is rejected (do not rely on it). [ASSUMED: Hex replace window]
- **Verification:** commands in Code Examples; accrue publishes ~3 min before admin and portal (1.6.0: 13:22, 13:25, 13:28).

### Q7. Merge method

Use a **merge commit**: `gh pr merge <N> --repo szTheory/accrue --merge --match-head-commit <40-hex exact head>` (no `--auto`, no squash, no rebase). Reasons: `RELEASING.md` / `release-pr-automation.yml` / `gh_merge_release_pr.sh` all specify `--merge`; 1.6.0's PR #46 merged this way (merge commit `ca8f6655`, parents `34866b07` + `5ede0dbc`) and release-please tagged that SHA; release-please takes the tag target from the PR's `mergeCommit`, so squash would also tag correctly, but squash/rebase break the "release commit reachable" and per-commit changelog traceability the milestone calls out (REQUIREMENTS Out of Scope: "Squash or rebase merge"). `--match-head-commit` pins the SHA the verdict judged (Phase 250 did the same). CONTEXT's "default squash/merge flow" is satisfied by merge. (The *fix* PR is squash per CONTEXT; maintainer prefers squash for follow-ups, merge for the release PR.)

### Q8. Phase close

- **Bootstrap (first Phase 251 PR):** mirror `250-01`: set `current_phase: 251` / `current_phase_name`, add `251-mint-close-artifacts.mjs` (copy of `250-mint-close-artifacts.mjs`: `PHASE_SLUG="251-1-7-0-release-alignment"`, `BASE_COMMIT=` `db1b6d85b8ecb94d1d4d781591a6bf0ad88a2401`; `EXCLUDED` adds any SHA-recording file such as a `251-RELEASE-PR.md` ledger), mint `251-VERIFICATION.md` (`status: passed`, `behavior_unverified: 0`, scoped to completed-plan claims only) and generated UAT via `generateAutomatedUat`. SL-G reads `current_phase` (`verify_artifact_fixed_point.mjs:348-352`), exec-UAT too (`verify_executable_uat_contract.mjs:495-499`); an empty phase dir is refused (`zero artifacts discovered`), so the flip and mint must be one step. Re-mint rule: any commit changing a covered file or adding a SUMMARY is followed by the minter before the next push.
- **Record the authorization verbatim** (quote above, dated 2026-10-26) in STATE.md and the SUMMARY/VERIFICATION.
- **Release-PR content is not in covered_files at bootstrap**, so aligning the branch does not invalidate the digest; after the release merges, re-mint (covered set then includes the CHANGELOGs/mix.exs/READMEs changed since BASE).
- **Close:** after publish verification, a docs-only close PR (squash, like `docs/250-close`) with SUMMARYs (`human_judgment: false`), re-minted VERIFICATION/UAT, REQUIREMENTS RLS-01/RLS-02 -> Complete, STATE/ROADMAP. RLS-02 is satisfied by the recorded yes plus the executed publish.
- **v1.67 milestone completion:** do it as a separate step right after Phase 251 verifies (3/3 phases). Keep the milestone tag local; run `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .` immediately after the archive; the Phase 250 helper path moves to `milestones/v1.67-phases/`, so reference it through `scripts/ci/phase_evidence_path.mjs`. Untracked `.planning/milestone.lock` exists in the tree (not part of this work).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Reset release branch to main on staleness (a0805390, 2026-05-07) | Never write to the release branch from automation | This phase | Eliminates the empty-PR class (5 occurrences). |
| Raw release-please notes shipped as CHANGELOG | Curated per-package 1.7.0 sections | 1.5.0/1.5.1 precedent; now required by SC1 | Adopter-readable; GitHub Release notes remain the raw technical view. |

**Deprecated/outdated:** the manual remedy in `RELEASING.md`/`scripts/ci/README.md` ("reset ... rerun Release Please"); the `compatibility-only` framing for admin/portal as applied to 1.7.0 (honoured textually, not semantically).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SC1 means "no raw phase-scoped lines in the new `## [1.7.0]` section of each CHANGELOG" (not the whole file; historic sections have 243/46/22 raw lines) and the literal `feat(2xx-yy)` pattern is shorthand for `**2xx-yy:**` bullets | Pitfall 5, Q5 | If the whole file is meant, historic released sections must be rewritten (out of stated scope). Confirm with maintainer or in discuss. |
| A2 | Curated-draft claims (processor action gating, atomic replay claim, install-hook defaults, "neither package changes how core decides entitlements") are accurate; derived from commit subjects/diff stats, not full code review | Q5, Appendix A | Public notes over-claim. Executor must verify each bullet against code/tests before pushing. |
| A3 | Hex permits replacing a just-published version only within a short window | Q6 | Recovery guidance only; CONTEXT already forbids improvising. |
| A4 | #27's empty merge had the same cause as #26/#28/#33 | Q1 | Documentation precision only. |
| A5 | The maintainer wants the D2 known issue stated in the 1.7.0 core CHANGELOG/release notes (no convention exists) | Q5, Open Questions | Either omission (less honest) or unwanted public disclosure. |
| A6 | Removing the `pending` label is within the standing publish authorization (label edits are not listed in CONTEXT rules) | Q2 | A remote write outside explicit authorization; ask once, record the answer. |

## Open Questions

1. **Label edit authorization (A6).** (RESOLVED: see 251-CONTEXT.md "Resolved research decisions", A6. Removing the label after the fix PR lands, `gh workflow run release-please.yml`, and `gh release edit` are authorized and logged with timestamps, and main is frozen from the relabel to the release merge. No confirmation step.)
   - Known: removing `autorelease: pending` from #50 is required and is a remote write; CONTEXT authorizes branch pushes, PRs and merges, and the release yes, but does not name label edits or `workflow_dispatch`.
   - Recommendation: planner includes one explicit confirmation step (genuine external-operation decision, not UAT) covering: label removal, `gh workflow run release-please.yml`, the release-branch pushes, merge, and optional `gh release edit`.
2. **Known-issues note for D2 (A5).** (RESOLVED: see 251-CONTEXT.md "Resolved research decisions", D2 known-issue note. INCLUDE one Known issues bullet in core 1.7.0, with the wording verified against the code.) Recommendation: include one bullet under `### Known issues` in core 1.7.0 (draft provided) and one sentence in `release-notes.md`; drop if the maintainer prefers to fix D2 first (would delay 1.7.0 and needs a migration).
3. **SC1 scope (A1).** (RESOLVED: see 251-CONTEXT.md "Resolved research decisions", A1 SC1 scope. The check is scoped to each package's new `## [1.7.0]` section, catches the `feat(2xx-yy)`, `**2xx-yy:**` and raw-hash forms, uses the uncurated candidate as its positive control, and leaves historic sections untouched.) Recommendation: scope to the 1.7.0 section; make the check a committed script/assert with the positive control, so it is executable per policy.
4. **GitHub Release notes.** (RESOLVED: see 251-CONTEXT.md "Resolved research decisions", A6 and Release PR merge. The PR body is never edited. `gh release edit` is authorized only for corrections, and none is planned; raw technical release notes are accepted.) They will carry the raw PR-body text. Recommendation: accept (release-notes.md calls GitHub releases "more technical"); optionally `gh release edit <tag> --notes-file` after tagging. Do not edit the PR body (Alternatives table).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| node / npx | release-please dry runs, minter, helper | yes | repo toolchain (npx fetched 17.6.0) | - |
| gh (authenticated, repo scope) | PR/label/run inspection, merge | yes | `gh auth token` works; read-only calls verified | - |
| jq, curl, git, bash | verifiers, Hex checks | yes | system | - |
| Elixir/mix | `verify_package_docs.sh` full run needs deps; contract subset ran without | partial in scratch export | - | Run full set in CI; locally replay the hermetic bash gates |
| Docker | n/a (maintainer machine has none) | no | - | CI only (matches CONTEXT) |
| hex.pm / hexdocs.pm | post-publish checks | yes (reachable; 1.6.0 present, 1.7.0 absent) | - | - |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash `--self-test` verifiers + node:test minter/gates; ExUnit `release_notes_contract_test.exs` (runs in `release-gate`) |
| Config file | none (scripts self-contained); `ci.yml` wires them |
| Quick run command | `bash scripts/ci/verify_release_branch_repair_safety.sh --self-test` |
| Full suite command | the `ci.yml` jobs on the exact head via `node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha <head> --event pull_request --pr-base main` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RLS-01 | Workflow cannot empty the release PR (legacy block FAILS static rule; legacy algorithm yields 0 files; fixed workflow passes) | hermetic self-test | `bash scripts/ci/verify_release_branch_repair_safety.sh --self-test` | Wave 0 (new) |
| RLS-01 | No outstanding merged `pending` PR before release merge | read-only gh | `test -z "$(gh pr list --state merged --label 'autorelease: pending' --json number --jq '.[].number')"` (positive control: returns 50 today) | n/a |
| RLS-01 | Release PR shape: 7 files, 3x 1.7.0 | read-only gh | `bash scripts/ci/verify_release_pr_scope.sh --pr N --version 1.7.0` | yes |
| RLS-01 | Notes/pins/story aligned | bash | `bash scripts/ci/verify_release_notes_contract.sh && bash scripts/ci/verify_release_manifest_alignment.sh` and `bash scripts/ci/verify_package_docs.sh` (without `RELEASE_PLEASE_PR`) | yes |
| RLS-01 | SC1: no raw phase-scoped lines in 1.7.0 sections | bash/awk | section-scoped `grep -E` (Pitfall 5) with positive control against `963ad2cd` | Wave 0 (add as committed check) |
| RLS-01 | Exact head green (`success`, not `skipped`) | helper | `250-ci-head-status.mjs ... --pr-base main` exit 0 | yes |
| RLS-02 | Tags + releases + publish + Hex + docs for 3 packages | read-only | Code Examples block; `gh run view` jobs all `success` | n/a |
| Close | SL-G / SL-E / exec-UAT | node | `node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match`; `verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement`; `verify_executable_uat_contract.mjs --all-since 229` | yes |

### Sampling Rate
- **Per task commit:** the self-test above plus the touched gate script.
- **Per wave merge:** exact-head helper on the PR head.
- **Phase gate:** helper green on fix PR and release PR heads; post-publish read-only block green; SL-G/SL-E/exec-UAT green.

### Wave 0 Gaps
- [ ] `scripts/ci/verify_release_branch_repair_safety.sh` (+ `ci.yml` wiring, `scripts/ci/README.md` row) covers RLS-01 root-cause fix.
- [ ] `251-mint-close-artifacts.mjs`, `251-VERIFICATION.md`, `251-UAT.md`, `current_phase: 251` covers the SL-G/exec-UAT handoff.
- [ ] Committed SC1 section-scoped check with positive control.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | - |
| V3 Session Management | no | - |
| V4 Access Control | yes | Least-privilege release credentials: `HEX_API_KEY` and `RELEASE_PLEASE_TOKEN` only as Actions secrets; workflow `permissions:` already scoped; irreversible Hex publish gated on the recorded maintainer authorization. |
| V5 Input Validation | yes | Workflow `${{ inputs.* }}` interpolated into `grep` in `publish-hex.yml` (maintainer-only `workflow_dispatch`); keep inputs maintainer-controlled. |
| V6 Cryptography | no | - |
| V14 Config / supply chain | yes | `release-please` pinned `@17.6.0`; SHA-pinned actions; no new packages; Hex publish is effectively irreversible. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong-commit tag/release publishing unreleased or mismatched code | Tampering | Remove stale `pending` label first; `grep @version` check at tag SHA already in publish jobs; `--match-head-commit` on merge. |
| Secret leakage in logs/notes | Info disclosure | `--token "$(gh auth token)"` never echoed; curated notes free of names/emails/paths (census + home-path guard are merge-blocking). |
| Partial publish (supply-chain inconsistency across the three packages) | Tampering/DoS | `needs:` order; stop-and-report on partial; no improvised yank. |
| CI silently skipped | Repudiation | Exact-head helper requires `success`, not `skipped`; wedge detector turns silent success into a red job. |

## Sources

### Primary (HIGH confidence)
- `release-please@17.6.0` package source (`npm pack`, extracted in scratchpad): `build/src/manifest.js` (labels L35-38; `createPullRequests` L478-482; `findMergedReleasePullRequests` L606-640; `maybeUpdateExistingPullRequest` ~L560; `createReleasesForPullRequest` L700-752; config `always-update` L886), `plugins/linked-versions.js` L45-62, `strategies/base.js` `buildRelease`, `github.js` `updatePullRequest` L566-595, `util/pull-request-body.js`, `schemas/config.json`.
- Repo files read this session: `.github/workflows/release-please.yml`, `publish-hex.yml`, `release-pr-automation.yml`, `ci.yml` (cited lines), `scripts/ci/verify_release_pr_scope.sh`, `verify_release_manifest_alignment.sh`, `verify_release_contract.sh`, `verify_release_notes_contract.sh`, `verify_release_pr_readiness.sh`, `verify_release_pr_title_roundtrip.sh`, `repair_linked_release_pr.sh`, `verify_package_docs.sh`, `RELEASING.md`, `.planning/*` as listed.
- GitHub runs 40257272990 (failure) and 40281358545 (success) logs; PR #50/#26/#28/#33/#46 metadata and timelines; commit `963ad2cd`; `gh pr list` / `gh secret list` / branch-protection API.
- Read-only release-please dry runs (`release-pr --dry-run`, `github-release --dry-run`) against the live repo; outputs in scratchpad `dry/`.

### Secondary (MEDIUM confidence)
- docs.github.com "Triggering a workflow" (GITHUB_TOKEN events do not create workflow runs).
- hex.pm API / hexdocs behavior checked on 1.6.0.

### Tertiary (LOW confidence)
- Hex replace-window behavior (A3); #27 cause (A4).

## Appendix A: Curated 1.7.0 drafts (validated against the contract script in scratch; verify claims before use)

Scratch copies: `.../scratchpad/251-research/draft/{core,admin,portal}.md`, `rn_core.txt`, `rn_admin.txt`. Replace the whole body of each package's release-please-generated `## [1.7.0]` section (keep its heading line, compare URL and date) with:

**accrue/CHANGELOG.md** - `### Release highlights` (7 bullets: checkout retries/returns/eligibility/declines; atomic webhook replay claim + bulk owner-scope revalidation; processor-gated payment-method/subscription actions; dispatch-time manual-invoice-item validation; evidence-based recovery amounts; `:admin_branding` `theme: :system | :light | :dark`; self-only default Portal policy hooks `portal_organization_for/2` / `authorize_portal_action/5` in the generated billing context) and `### Known issues` (the `accrue_events.inserted_at` session-timezone bullet, fix planned next release).

**accrue_admin/CHANGELOG.md** and **accrue_portal/CHANGELOG.md** - `### Notes` with a bullet starting `Compatibility only: the linked 1.7.0 release asks nothing further of the core \`accrue\` billing contracts beyond the entries in its own changelog. The core \`accrue\` package owns billing capability; this package owns only its existing UI surface (portal: self-service surface), refined as listed below.` then `### Release highlights` (admin: journeys keep place/owner scope; actions recheck before running; list/search/ID/count/infinite-list changes; Local/UTC timestamp convention with exact-value copy; event/webhook clarity; 320px reflow + keyboard focus ring + touch targets; theme lock via core config. portal: host-resolved billing contexts rechecked per action; per-action authorization for payment methods/subscriptions/checkout with safe denial; dependable checkout; scoped hosted invoices; host branding/Hosted Fields colors).

Constraints enforced by the contract (keep when editing): the admin/portal sections must contain `Compatibility only:`, `linked 1.7.0`, `core`, `package owns`, and must not contain `admin-owned`, `portal-owned`, `grant authority`, `authorization behavior`, or `new ` followed by `workflow`/`api` on one line (avoid the token `new ` entirely).

**accrue/guides/release-notes.md** - insert `### 1.7.0` above `### 1.6.0` in both `## accrue` (story: Admin/Portal refinement, steadier checkout, safer webhook replay, the D2 known issue) and `## accrue_admin` (admin story + one portal sentence). **Pins:** `accrue/README.md:38`, `accrue/guides/first_hour.md:95-96`, `accrue_admin/README.md:24` and `:84` -> `1.7.0`.

## Recommended plan decomposition (risks and controls)

| # | Plan | Output | Key risk | Control |
|---|------|--------|----------|---------|
| 01 | Bootstrap + workflow fix (one PR from a branch, squash on exact-head green) | Phase 251 current_phase flip + minter + VERIFICATION/UAT; delete reset block; wedge detector; `verify_release_branch_repair_safety.sh --self-test`; `verify_release_contract.sh:64` update; RELEASING.md / scripts/ci/README.md remedy text; ci.yml wiring | Touching `accrue*/` paths would change notes; breaking a contract needle; vacuous test | Keep to `.github/`, `scripts/`, `.planning/`, docs; run the self-test with legacy-block negative control (record FAIL output); helper verdict with `--pr-base main` |
| 02 | Recover release-please state (explicit go) | Label removed from #50; `gh workflow run release-please.yml`; fresh PR verified | Wrong-sha tags if label stays; main moves meanwhile | Verify merged-pending list empty (positive control first); `gh run view` shows no `github-release` tags; confirm 0 `*-v1.7.0` tags/releases; freeze main; compare new PR body to `dry/dry.body` |
| 03 | Align release branch | Curated 3 CHANGELOG sections, 2 release-notes stories, 4 pin edits; pushed as fast-forward commits | Contract wording traps; rebuild by release-please wipes work | Replay hermetic gates locally on an exported tree first (as done in scratch); SC1 section check; `verify_release_pr_scope.sh --pr N --version 1.7.0`; no PR-body edits; no main pushes |
| 04 | Exact-head green | `250-ci-head-status.mjs --sha <head> --event pull_request --pr-base main` exit 0 | A required job `skipped`; head moved | Re-run helper on the exact SHA right before merge |
| 05 | Merge + publish + verify | Merge commit with `--match-head-commit`; 3 tags at merge SHA; 3 publish jobs + proof job success; hex.pm/hexdocs read-only checks; optional curated `gh release edit` | Partial publish; wrong-sha tag | Stop and report on any partial; read-only verification block; do not improvise yank |
| 06 | Close | SUMMARYs (`human_judgment: false`), re-minted VERIFICATION/UAT, REQUIREMENTS RLS-01/02 Complete, STATE/ROADMAP, authorization quote recorded; docs-only close PR (squash) | Digest drift after the release merge changes covered files | Re-mint via minter only; SL-G/SL-E/exec-UAT green |
| 07 (after) | v1.67 milestone completion (`/gsd-complete-milestone`), local tag only | Archive | Archive breaks path-bound verifiers | `verify_phase230_archive_invariants.mjs --repo .` immediately after; `phase_evidence_path.mjs` |

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - pinned, unchanged, source read.
- Architecture / root cause: HIGH - logs, timeline and source agree; defect reproduced in a hermetic fixture.
- Recovery semantics: HIGH - source plus read-only dry run showing the hazard.
- Curated notes: MEDIUM - contract-validated, claim accuracy pending (A2).
- Pitfalls: HIGH - each reproduced or log-evidenced.

**Research date:** 2026-10-26
**Valid until:** 2026-11-09 (release tooling pinned; re-run the dry runs if `main` gains `feat`/`fix` commits touching package paths)
