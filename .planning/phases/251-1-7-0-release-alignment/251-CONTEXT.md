# Phase 251: 1.7.0 Release Alignment - Context

**Gathered:** 2026-10-26
**Status:** Ready for planning
**Source:** Maintainer decisions in the 2026-10-24..26 session, plus the post-Phase-250 Release Please observations.

<domain>
## Phase Boundary

Ship 1.7.0 of `accrue`, `accrue_admin` and `accrue_portal` to Hex and GitHub Releases from an aligned, exact-SHA-green release-please PR. This includes repairing the release-please workflow defect that emptied the previous release PR. No new product behavior.
</domain>

<decisions>
## Implementation Decisions (locked)

### Publication authorization (RLS-02)
- On 2026-10-26 the maintainer said: "follow ur recs. i authorize release we want to release early and often at any natural stopping point that is release worthy".
- That is the recorded explicit yes for publishing 1.7.0 to Hex. It also establishes a standing policy: release at every release-worthy stopping point.
- Record this verbatim, with the date, in STATE.md and in the phase SUMMARY/VERIFICATION. It satisfies SC3 without leaving the PR open.
- Publish only from an aligned release PR whose exact head is green, with `main` green. Never weaken a release gate to get there.
- If any publish step fails partway (for example, one package published and another not), stop and report. Do not improvise a yank or retire.

### Current state (observed 2026-10-26, verify again; do not trust blindly)
- `main` = `db1b6d85` (after PRs #49 merge commit 3dd5f874, #51 close b4310a39, #52 CI efficiency f1024908, #53 timeouts db1b6d85). Push CI is green there, and Release Please run 40281358545 succeeded.
- `.release-please-manifest.json` shows 1.6.0 for all three packages. GitHub releases `accrue-v1.6.0`, `accrue_admin-v1.6.0` and `accrue_portal-v1.6.0` exist (2026-09-18). No 1.7.0 tag or release exists. `publish-hex.yml` last ran in August.
- **Release PR #50 ("chore: release main") is MERGED, with 0 changed files, and still carries the `autorelease: pending` label.** How it got that way:
  1. After main moved to b4310a39, the stale-base repair in `.github/workflows/release-please.yml` (around lines 177–193) force-pushed `release-please--branches--main` back to main's commit.
  2. release-please then reported "PR #50 remained the same", because the title and body were unchanged, so it never re-created its release commit.
  3. Release Please run 40257272990 failed (`verify_release_pr_scope: PR #50 is missing required release file: .release-please-manifest.json`).
  4. With head == a main commit, GitHub auto-marked #50 merged (mergeCommit b4310a39, 2026-10-26T05:48Z).
  5. No release PR is open now.
  6. The previous release-branch tip `963ad2cd` may still exist as an object.
- **Risk to handle:** release-please treats a merged PR labelled `autorelease: pending` as a release to tag. A stale pending label on an empty merged PR could make it try to create releases for 1.6.0 (which already exist; the workflow's `release_exists` guard skips duplicates), or block a new release PR from opening. Research must decide the correct recovery from release-please's own documented behavior (for example, relabel to `autorelease: tagged` or `autorelease: closed`, or remove the label) before any change is made.

### Workflow defect (fix at source, first)
- The stale-base repair must not leave the release PR without its release commit. Two acceptable routes: re-create the release commit after a reset, or not reset when release-please would leave the PR unchanged.
- The fix needs a fixture or self-test with a negative control that reproduces "main moved, notes unchanged → PR emptied".
- The fix lands through its own PR to `main`, squash-merged when green on its exact head.

### Release alignment (RLS-01) — precedent: memory "Release PRs open red by design"; v1.62 / 1.6.0 alignment
- release-please cannot write the README version pins, the companion notes, or the release-notes story that its own gates require. Align these on the release branch:
  - README pins at 1.7.0;
  - companion notes;
  - a curated, adopter-readable CHANGELOG for each package, replacing raw phase-scoped `feat(2xx-yy)` lines.
- SC1 grep: no raw `feat(2xx-yy)` lines in the release CHANGELOGs.
- The CHANGELOG covers v1.63–v1.66 (admin/portal UI refinement, usability, consistency), the owner-feedback fixes, and v1.67 integration fixes worth noting to adopters:
  - the seed boundary in CI;
  - the focus ring a11y fix;
  - the 320px reflow fixes;
  - the portal Braintree stub race (test-only; probably not adopter-facing).
- Be honest about the D2 deferral (the `accrue_events.inserted_at` timezone issue is known and tracked for v1.68), if a known-issues note is the convention.
- Expect linked-versions 1.7.0. Verify the bump release-please computes; if it differs, investigate rather than force it.
- The release PR's exact head must be green on every required check (`success`, not `skipped`).
- The release PR is merged the way release-please expects (its default squash/merge flow), so it tags and the publish workflow fires. Then verify:
  - GitHub releases and tags for all three packages at 1.7.0;
  - `publish-hex.yml` success;
  - hex.pm shows 1.7.0 for all three, with docs published.

### Rules
- Never push to main directly, never force-push, and never push GSD milestone tags (release-please creates its own package tags; that is expected).
- Pushing branches and opening PRs for this phase is authorized, and so is merging them when green on their exact head.
- No Docker on the maintainer's machine. Never weaken a gate. Every contract change carries positive/negative controls.
- Re-mint covered_digest only via scanArtifact/computeDigest. STATE `current_phase` must flip to 251 in the same step that mints Phase 251's own VERIFICATION/UAT (the SL-G/SL-E handoff, as in Phase 250).
- Use `.planning/phases/250-remote-integration/250-ci-head-status.mjs` (with `--pr-base` where path filters apply) as the exact-head verdict helper.

### Claude's Discretion
- Plan decomposition and ordering. Expected: workflow fix PR → recover release-please state → aligned release PR → publish → verify → phase/milestone close.
- Whether v1.67 milestone completion (`/gsd-complete-milestone`) happens in this phase or right after. If it happens, keep milestone tags local.
</decisions>

<canonical_refs>
- `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, `release-please-config.json`, `.release-please-manifest.json`
- `scripts/ci/verify_release_manifest_alignment.sh`, `scripts/ci/verify_release_contract.sh`, and the release-PR scope / release-notes verifiers the release workflow runs
- `.planning/milestones/v1.62-*` (1.6.0 release precedent, PR #45)
- `accrue/CHANGELOG.md`, `accrue_admin/CHANGELOG.md`, `accrue_portal/CHANGELOG.md`, `accrue/guides/release-notes.md`
- Memory: "Release PRs open red by design" (release-please needs manual alignment on the release branch)
</canonical_refs>

<deferred>
## Deferred Ideas
- v1.68 items in REQUIREMENTS.md "Future Requirements" (the inserted_at timezone fix is HIGH).
- Extending the `_build` cache to host-integration, browser-uat, the admin jobs and `_build/dev`.
</deferred>

---
*Phase: 251-1-7-0-release-alignment · Context gathered: 2026-10-26*

### Resolved research decisions (orchestrator, 2026-10-26, under the maintainer's "follow ur recs. i authorize release" authority)
- **A6, release-flow remote writes:** these are authorized as part of the release:
  - removing the stale `autorelease: pending` label from merged PR #50, done only after the workflow-fix PR has landed;
  - `gh workflow run release-please.yml`;
  - `gh release edit` for release-body corrections.
  Each write is logged with a timestamp in the SUMMARY. Freeze `main` from the relabel until the release PR merges: no other merges.
- **A1, SC1 scope:** the raw-line check is scoped to each package's new `## [1.7.0]` CHANGELOG section. It must catch release-please's real rendering: both `feat(2xx-yy)` and `**2xx-yy:**` bullet forms, plus raw commit-hash link lists if the curated style forbids them.
  - Positive control: the uncurated release-please candidate section must FAIL the check.
  - Negative control: the curated section must pass.
  - Historic sections stay untouched, because rewriting released history is out of scope.
- **D2 known-issue note:** INCLUDE a concise "Known issues" bullet in the core 1.7.0 entry for the `accrue_events.inserted_at` session-timezone dependence. Say that it is fixed in the next release and what non-UTC adopters can do now (run Postgres with UTC session timezone), if that is accurate. Verify the wording against the code.
- **CHANGELOG claims:** every curated bullet must be verified against the code or diff, not only commit subjects. Avoid `new ` in the admin/portal 1.7.0 sections, per `verify_release_notes_contract.sh`.
- **Root-cause fix route:** delete the stale-base reset/force-push/second-`release-pr` block. Add the merged-but-pending label detector and `verify_release_branch_repair_safety.sh --self-test`, with both negative controls, wired merge-blocking. Fix the `RELEASING.md` and `scripts/ci/README.md` remedies and the `verify_release_contract.sh:64` needle with controls. This lands as its own PR, squash-merged when green.
- **Release PR merge:** merge commit, using `gh pr merge N --merge --match-head-commit <sha>` per `RELEASING.md` and the #46 precedent. Never squash, rebase or `--auto`.
- **Do not delete** the remote branch `integration/v1.62-candidate-recut`; the readiness gate depends on it.
- **v1.67 milestone completion** comes after the phase closes, as a separate step. Milestone tags stay local. Run the archive-invariant sweep immediately after.
