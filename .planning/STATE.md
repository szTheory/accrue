---
gsd_state_version: "1.0"
milestone: v1.62
milestone_name: Release Integration & Repository Hygiene
current_phase: 231
current_phase_name: Exact-SHA Release Gate Proof
status: executing
stopped_at: Completed 231-01-PLAN.md
last_updated: "2026-09-16T02:59:03.072Z"
last_activity: 2026-09-15
last_activity_desc: Phase 231 execution started
state_head: ed55b9411aa6469dfc91e71f17df6d1d5ee6eeb9
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 33
  completed_plans: 28
  percent: 50
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-09-15)

**Core value:** A Phoenix developer can install Accrue and its companion admin UI and launch a real SaaS with subscription billing on day one, without avoidable integration or release risk.

**Current focus:** Phase 231 — Exact-SHA Release Gate Proof

## Current Position

Phase: 231 (Exact-SHA Release Gate Proof) — EXECUTING
Plan: 2 of 6
Status: Ready to execute
Last activity: 2026-09-15 — Phase 231 execution started

Progress: [█████░░░░░] 50% (2/4 phases complete; 27/27 plans in Phases 229-230)

## Performance Metrics

**Velocity:**

- Total plans completed: 27
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 229. Repository Truth & Recovery Safety | 0 | — | — |
| 230. Reviewable History Integration | 0 | — | — |
| 231. Exact-SHA Release Gate Proof | 0 | — | — |
| 232. Bounded Hygiene & Release Handoff | 0 | — | — |
| 229 | 20 | - | - |
| 230 | 7 | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 229 P01 | 10min | 2 tasks | 6 files |
| Phase 229 P02 | 15min | 2 tasks | 2 files |
| Phase 229-repository-truth-recovery-safety P03 | 16min | 2 tasks | 3 files |
| Phase 229 P04 | 35min | 2 tasks | 7 files |
| Phase 229 P05 | 20m | 2 tasks | 1 files |
| Phase 229 P06 | 13m | 2 tasks | 1 files |
| Phase 229 P08 | 9min | 2 tasks | 3 files |
| Phase 229 P07 | 20m | 2 tasks | 2 files |
| Phase 229 P09 | 40min | 2 tasks | 3 files |
| Phase 229 P10 | 10 min | 2 tasks | 1 files |
| Phase 229 P11 | 10 min | 2 tasks | 2 files |
| Phase 229 P12 | 7min | 2 tasks | 1 files |
| Phase 229 P13 | 11min | 2 tasks | 2 files |
| Phase 229 P14 | 15min | 2 tasks | 5 files |
| Phase 229 P15 | 11min | 2 tasks | 3 files |
| Phase 229 P16 | 10min | 2 tasks | 1 files |
| Phase 230 P01 | ~50min | 3 tasks | 4 files |
| Phase 230 P02 | ~2h | 2 tasks | 7 files |
| Phase 230 P03 | ~90 min | 3 tasks | 5 files |
| Phase 230 P05 | 40 min | 3 tasks | 7 files |
| Phase 230 P04 | ~110 min | 3 tasks | 5 files |
| Phase 230 P06 | ~4h | 3 tasks | 13 files |
| Phase 230 P07 | ~65 min | 3 tasks | 6 files |
| Phase 231 P01 | 55min | 2 tasks | 2 files |

## Accumulated Context

### Decisions

- v1.62 is release integration and repository hygiene only; no product capability is in scope.
- Published history and the v1.61 tag remain immutable: no force-push, tag movement, destructive cleanup, required-check weakening, merge to `main`, Release Please merge, or package publication.
- Phase order is repository truth/safety → integration candidate → exact-SHA gate proof → bounded hygiene and release handoff.
- Cleanup must be evidence-backed and stops when only subjective nits remain.
- [Phase 229]: Freeze every refs/** row before creating Phase 229 preservation refs, then verify both named refs and bundle membership.
- [Phase 229]: Persist only allowlisted, relative typed artifact evidence; external recovery locations and content remain private.
- [Phase 229]: Phase 229 monitor permits only repository-bound list, inspect, and bounded watch reads.
- [Phase 229]: Legacy branch selection is resolved to a full SHA before watch polling, while explicit SHA bypasses selection.
- [Phase 229]: Actions success remains provider_proof non_run absent independent provider evidence.
- [Phase 229]: Remote facts use repository-bound GET provenance and explicit unavailable records.
- [Phase 229]: Collection re-resolves preservation refs before live remote observation.
- [Phase 229]: Phase 229 inventory permits only exact-path before/after-hash evidence for the two GSD workflow metadata refreshes.
- [Phase 229]: Phase 229 commits explicit unavailable remote observations rather than cached or local substitutes.
- [Phase 229]: [Phase 229]: Recovery capsules use physical destination validation and exclusive atomic publication before final bundle revalidation.
- [Phase 229]: [Phase 229]: Recovery manifests store restore argv arrays, never shell command text.
- [Phase 229]: Remote main is singleton evidence while plural GitHub categories retain deterministic full-SHA arrays.
- [Phase 229]: Recovery manifest repository identity is checked before dependent collection.
- [Phase 229]: Compatibility watcher defaults are fixed to szTheory/accrue, main, CI, 900-second timeout, and 10-second polling.
- [Phase 229]: Explicit full SHA selection takes precedence over branch resolution.
- [Phase 229]: Phase 229 acceptance is fully executable — 58 automated UAT tests, zero human-verification checkpoints — and its seven hermetic suites are merge-blocking in the `docs-contracts-shift-left` CI job.
- [Phase 229]: Strict verification of the *published* capsule stays OUT of CI by design: it is point-in-time and fails on any planning-doc update, so it has no recurring value there. The behavior it guards is covered by fixture and real-chain tests that need no capsule.
- [Phase 229]: The executable-UAT contract gate is wired as `--all-since 229`, not `--all-since 218`, because phases 219-228 carry pre-existing missing-`coverage:` debt. The gate ratchets forward rather than widening and going red.
- [Phase 229]: Completed success exits 0 and completed non-success conclusions render repository/SHA evidence before exiting 69.
- [Phase 229]: Strict recovery reconciles the anchored private manifest, actual bundle heads, encoded preservation refs, committed recovery rows, and canonical non-preservation refs as exact maps. — No asserted boolean or non-empty array can substitute for independent authority checks.
- [Phase 229]: Rendered recovery derives POSIX-quoted fetch and update-ref commands from verified original ref/object pairs while the bundle path remains runtime-only. — The immutable legacy private restore string is untrusted and is never executed.
- [Phase 229]: Final capture keeps the original recovery capsule immutable and adds one restrictive private attestation. — Append-only evidence avoids weakening or replacing the anchored recovery authority.
- [Phase 229]: Strict recovery permits only the active execution branch to advance after freezing. — Phase task commits must advance that branch while every frozen original object remains recoverable and every non-active ref remains exact.
- [Phase 229]: Compare complete sorted NUL-delimited artifact triples immediately before PASS. — One exact map comparison detects add, remove, rename, type, and digest drift while new outputs remain cleanup-owned.
- [Phase 229]: Hash symlink link text only from a non-dereferenced Buffer. — Raw fs.readlinkSync buffer bytes preserve invalid UTF-8 and newline evidence without target access or decode/re-encode loss.
- [Phase 229]: Plural remote evidence is available only after an explicit short terminal page; full pages at page or item bounds fail as overflow. — This prevents silent truncation while keeping remote collection bounded.
- [Phase 229]: Plural facts retain their complete ordered producing GET sequence while remote main keeps its singleton request. — Category-specific provenance must remain independently verifiable without widening the read-only API surface.
- [Phase 229]: Use performance.now() for one monotonic watch deadline and pass a remaining-budget function through every read boundary.
- [Phase 229]: Validate viewed run ID, SHA, and requested workflow before reading jobs or returning a conclusion.
- [Phase 229]: The active branch is the only allowed frozen-ref continuity exception, and its canonical object must equal the independently resolved live symbolic ref object.
- [Phase 229]: Canonical worktrees and ship windows are exact multisets read independently by the verifier from Git porcelain and bounded WINDOWS.md parsing.
- [Phase 229]: Plural remote provenance is an exact contiguous page sequence whose SHA count proves a short terminal page when evidence is available.
- [Phase 229]: Privacy rejection covers POSIX, Windows, UNC, drive-relative, file-URI, C0, and DEL forms while dedicated normalized repository-relative artifact paths remain valid.
- [Phase 229]: The final handoff accepts only a fixed allowlisted child chain and never caller-supplied commands.
- [Phase 229]: Protected capsule, untracked-path, ref/tag, and worktree identities are encoded from raw bytes and exact-compared around the full final chain.
- [Phase 229]: The sole permitted external delta is the pre-named absent attestation created exclusively after pre-attestation invariant checks pass.
- [Phase 229]: Remote availability is a literal boolean discriminator; observed SHA values and unavailable reasons are mutually exclusive exact schemas.
- [Phase 229]: Plural remote provenance renders every producing request in order with one stable category-independent separator.
- [Phase 229]: Captured-at authority binds one active full symbolic ref and commit to the sanitized primary-worktree identity and captured active row.
- [Phase 229]: Preservation refs enter the rollback ledger only after atomic absent-old-value creation and are compare-deleted only while their expected objects remain exact.
- [Phase 229]: Bundle, artifact, manifest, and public-record preparation completes before preservation refs and capsule outputs are published.
- [Phase 229]: Concurrently changed preservation refs are retained and reported instead of being deleted during rollback.
- [Phase 230]: Phase-parameterized the preservation ref namespace and generalized the ancestry-carve-out into a typed owned/remote_tracking/preservation ref partition backed by a bounded declared-additions ledger (230-REF-EXCEPTIONS.json). — Closes D-25's out-of-repo preservation gap and makes strict ref verification satisfiable in a repo whose upstream is a release bot, without waiving the checks it documents.
- [Phase 230]: Built the reviewable v1.62 integration candidate (refs/heads/integration/v1.62-candidate) via pure git plumbing, proving all five D-05 ancestry gates live and a scratch-clone-executed rollback revert, without pushing or moving the v1.61 tag. — Plan 230-02 (tracer)
- [Phase 230]: [Phase 230]: Recomputed the hazard universe from live merge-parent SHAs inside the collector -- three co-touched files proved convergent-identical by blob equality, config.ex classified disjoint-hunk (proved by both survivor markers present), mix.exs classified dependency-lock-drift (non_run, owned by Plan 230-05), entitlements.md classified doc-rewrite; every D-21 lane recorded as an explicit non_run row owned by Phase 231. — D-14/D-15/D-20/D-21: never transcribe the hazard universe, unknown class is a hard failure, and a 231-owned check absent from Phase 230's scope must be an evidenced non_run row, not a silent omission.
- [Phase 230]: 230-05: Config's mix_env regression exercises validate_at_boot!/0, not validate!/1 (the latter never invokes maybe_validate_boot_setup!/1 where the seam is actually exercised). — A first draft using validate!/1 passed even when the Accrue.Env.mix_env/0 seam was reverted to current/0 -- a false negative caught before committing.
- [Phase 230]: 230-04: superseded_by is the no-equivalent sentinel for every wholesale-excluded row; excluded-rejected vs excluded-superseded classification is a live path-filter recomputation, never a hardcoded SHA list. — D-07's exclusion is proven at tree/requirement level, not commit-for-commit; D-15's never-transcribe discipline extends to disposition classification.
- [Phase 230]: 230-04: bulkPatchIdFrequency pipes git log -p | git patch-id through temp-file descriptors, not spawnSync string buffers, to avoid ENOBUFS on the candidate's ~350MB diff history. — Node spawnSync input/stdout string buffers hit an OS pipe limit well before any maxBuffer ceiling on a ~500-commit history.
- [Phase 230]: 230-06: The real archive-path sweep found and fixed three genuine pre-existing F-01-class regressions (Phase 208/224 evidence paths with no archive-aware fallback anywhere in the corpus). — The plan's own acceptance criteria required the sweep to pass clean against the real repository, not just fixtures; narrowing scope to dodge real findings would have defeated D-22's purpose.
- [Phase 230]: 230-06: scope.* in 230-INTEGRATION-DISPOSITION.json is measured against the candidate branch's live tip, not the pinned merge-commit candidate.object; candidate.object/parents/tree/ancestry stay pinned for D-05/D-06 identity. — The code-only review branch is built from the live tip per the plan's own git-diff-quiet acceptance criterion, and Plan 230-05's declared post_merge_commits are real source changes a reviewer needs counted; measuring scope against the stale pinned object made --require-scope --review-ref permanently unsatisfiable.
- [Phase 230]: 230-07: Closed PR #44 unmerged with NO public comment (maintainer-authorized privacy deviation from D-10's cite-superseding default); the disposition ledger's enumeration was extended with an honest close-unmerged-no-comment value rather than forcing the old cite-superseding literal onto an action that posted no citation.
- [Phase 230]: 230-07: Minted the final Phase-230 capsule under a distinct --preservation-phase 230.7 (not the bare 230 Plan 230-01's safety capsule already claimed) to avoid a preservation-ref collision on a second same-phase mint; rollback point re-proved by execution in a fresh scratch clone and its capsule field updated with the final digests.
- [Phase 231]: [Phase 231]: Re-cut integration/v1.62-candidate from current milestone HEAD (85aed062 merge / f524f2a6 tip), superseding bab50d92; collectRecutGates compares live git facts against RECORD-supplied expectations (never the same live value it just derived), which is what makes the D-05 "second merge point" and stale-revert-expectation failure modes detectable at all.

### Pending Todos

None yet.

### Deferred / Dormant

- **SEED-008 — `mailglass ~> 1.0` caps every downstream consumer at 1.x** (planted 2026-09-15, Phase 230).
  `accrue/mix.exs:68` pins `{:mailglass, "~> 1.0"}` while Hex has mailglass 2.5.0, so no host
  depending on Accrue can reach 2.x. NOT a one-line bump: 118 call sites across `accrue/lib` and
  `accrue_admin/lib` (`use Mailglass.Mailable`, `Mailglass.Message`, `Mailglass.Renderer`).
  "Stays capped, documented" is a legitimate outcome; the README half is cheap and standalone.
  See `.planning/seeds/SEED-008-mailglass-downstream-major-cap.md`.
- **Pre-existing, out of scope for Phase 230:** `.github/workflows/ci.yml:611` matches phase 190's
  PRE-ARCHIVE path (`.planning/phases/190-…`) inside a `grep -Eq` against a changed-files listing.
  Phase 190 is archived, so that alternation branch no longer matches anything and the relevance
  gate has quietly stopped firing for phase-190 evidence changes. Annotated
  `archive-sweep-exempt:` (it is a content match, not a path read) but the staleness itself is
  unfixed and belongs to whoever owns that gate. Recorded in `230-REVIEW.md` as an observation.

### Blockers/Concerns

- Remote `main` and the v1.61 lineage have diverged; the local `main` ref is stale and independently divergent.
- Four audit-closure commits are not published, and the required live-CI monitor is unavailable; both need honest evidence or an explicit waiver before release handoff.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260915-dpd | Fix eager Mix.env/0 evaluation in Accrue auth modules that crashes OTP releases at boot | 2026-09-15 | 5653216c | [260915-dpd-fix-eager-mix-env-0-evaluation-in-accrue](./quick/260915-dpd-fix-eager-mix-env-0-evaluation-in-accrue/) |

## Session Continuity

Last session: 2026-09-16T02:59:03.032Z
Stopped at: Completed 231-01-PLAN.md

229-20 outcome (commits 024eaeca, ddd9a137, c6677152):

- Strict verification PASSES at all three points: capture commit A, after committing the canonical pair (B), and after committing the summary (C). The A-to-B-to-C ancestry property holds on the real repository, not just in fixtures.
- The recovery capsule is byte, type, owner and digest immutable across the run. Exactly one addition: phase229-final-capture-attestation-round3.json, mode 0600, uid 501, schema v2.
- The published inventory is live_remote (remote facts obtained under terminal proof), captured at 024eaeca. Committed recovery digests still match their anchors.
- All seven gates green; phase229_gap_closure is now 21/21.

Two blockers surfaced ONLY against the real capsule; both are fixed and covered:

1. assertStrictRecovery required the frozen manifest refs to EQUAL the freshly captured refs. A real capsule is minted once and then immutable, so at capture time the manifest had frozen the active ref 127 commits in the past -- meaning no real capsule could ever verify, contradicting 229-20's own must-have. Replaced with assertCapturedRefContinuity: exact for every frozen ref except the active one, which must instead prove the frozen object is still reachable from the captured commit. NOTE the class of blindness here: the generated fixtures mint the capsule and capture the inventory at the SAME commit, so no fixture-only test could see this. The new regression advances the active ref past the freeze first, and its negative uses a same-tree root commit so only the ancestry check can reject it.
2. The recovery bundle was mode 0644 against a verifier requiring 0600 or stricter -- the capsule predated its own access-control rule. Tightened to 0600 with maintainer approval; bytes, digest, type and owner unchanged. Recorded as a deliberate exception to the mode-immutability criterion.

Still open for a maintainer decision:

- The canonical inventory faithfully records two pre-existing refs whose names embed a downstream adopter's product name. They exist locally AND on the public origin, predate this plan, and the same names are already in the previously committed inventory, so the recapture added no new exposure. Renaming them is remote mutation (outside D-10) and would invalidate the frozen manifest.
- Branch fix/release-boot-env-resolver now carries the adopter boot fix as four commits off main (env resolver, auth boot path, format, docs), cherry-picked out of the 453-commit milestone branch and verified there: env 5/5, auth 6/6, mix format clean. Not pushed. The GSD quick-task planning doc was deliberately left behind on the milestone branch.

RESOLVED 2026-09-15 (was "229-VERIFICATION.md is STALE"): re-verified via /gsd-verify-work 229.
The report now reads `status: passed`, `behavior_unverified: 0`, 7/7 must-haves, with a #4155
covered-input fingerprint over all 52 inputs. 229-UAT.md was generated from SUMMARY coverage:
58 tests, 58 automated, 0 human. 229-SECURITY.md's three remaining open threats (T-229-12,
T-229-14, T-229-G14-03) were one stale register entry — the audit doc commit is an ancestor of
the renderer fix — and were re-verified closed adversarially (61/61, threats_open: 0).

Resume file: None

### Phase 229 evidence: two ordering constraints learned the hard way

The published inventory asserts COMPLETE ref truth and pins planning-authority
digests. Two consequences, both hit and both verified after 229-20 sealed:

1. Creating ANY new ref (branch or tag) makes strict verification fail with
   `extra=[<ref>]`. A standalone branch created after capture broke it
   immediately; deleting the branch restored it. Do not create refs while this
   inventory is the active evidence -- recapture afterwards instead. Note a
   recapture CANNOT rescue this either: the new ref is absent from the frozen
   manifest, so the manifest comparison would fail with extra=[<ref>] too.

2. `.planning/STATE.md` is a pinned planning authority (planning.state is its
   sha256; MILESTONES.md and WINDOWS.md likewise). Editing it after capture
   fails with `planning.state differs from independent .planning/STATE.md
   authority`. Verified directly: restoring STATE.md to its c6677152 content
   makes strict verification PASS again. Only `.planning/milestone.lock` and
   `.planning/state.json` are permitted to move.

So strict re-verification of a published inventory is a point-in-time check,
valid until the next planning-doc update -- which is every GSD step, including
the `/gsd-verify-work 229` that should run next. That is inherent to pinning
planning digests, not a defect. The evidence's durable guarantee is that it
verified at publication (capture commit A, canonical commit B, summary commit C)
and stays bound by the round-3 attestation. Any future recapture must be the
LAST action after planning docs settle.

### Adopter boot fix: PR #44 closed unmerged (corrected 2026-09-15, Plan 230-07)

**Correction (D-10):** the prior text below described PR #44's four commits as
"cherry-picked from the milestone branch" -- that described *intent*, not the
pushed branch. Measured truth, re-verified live immediately before Plan
230-07 Task 2 acted: `git merge-base --is-ancestor main 3f8338cd` -> YES and
`main...3f8338cd` -> `0 4`. **The PR's pushed head was local `main` plus 4
commits** -- so merging it would have permanently published all 80 of the
abandoned, excluded Phase-226 commits onto `main` (see `230-DISPOSITIONS.json`
for the full excluded-commit ledger). It was never a clean 4-commit branch off
`main`.

The four useful commits (`2de4389b`, `9eae363a`, `173607d9`, `5653216c`:
canonical `Accrue.Env` seam, the six auth call sites, format, and release
docs) are already on `integration/v1.62-candidate` as exact patch-id matches,
re-verified live at close time -- nothing was lost by closing. `mix format
--check-formatted` was clean on the branch; zero adopter PII in the diff or
PR body (it says "a downstream host app").

The fifth commit (afddc87c, the GSD quick-task planning doc) conflicts on
`.planning/` and is deliberately left on the milestone branch (and is carried
unchanged on the candidate, recorded `carried-on-candidate` in the ledger).

**Outcome:** PR #44 is now **closed, unmerged** (state `closed`, `mergedAt`
null). Per the Plan 230-07 checkpoint resolution, the maintainer authorized
closing **without posting any PR comment** -- a deliberate deviation from the
D-10 default (which called for a public superseding-SHA comment) -- to avoid
any possibility of leaking identifiers in public GitHub content. Zero
comments exist on the PR (verified). The superseding-SHA evidence instead
lives only in the committed `230-DISPOSITIONS.json`/`.md` ledger, never in a
public PR comment. `origin/main` was re-measured unchanged at `d30fc25d`
both before and after the close. The remote branch `fix/release-boot-env-resolver`
still exists (its removal is Phase 232's HYG-01, not this plan's).

KNOWN AND ACCEPTED: this branch plus its remote-tracking ref are two refs that
did not exist at Phase 229's capture, so strict verification of the published
229 inventory still reports `extra=[...]` for both. Maintainer-authorized
fail-forward, carried over unchanged by this correction. It was already a
point-in-time check (see constraint 2 above) and the next recapture must
happen after these settle.

### Phase 230 outcome: reviewable integration candidate built, PR #44 closed

`integration/v1.62-candidate` (single `--no-ff` merge commit
`4d45002cafb3846810b84ff1afd84e7418476c50`, live tip
`bab50d92be2695b12d5853e7d578e600376e73d0` after two declared post-merge
commits) reconciles remote `main` (`d30fc25d`) with the full v1.61 lineage and
the four post-archive closure commits, without rewriting published history or
moving the `v1.61` tag. Recomputed scope: 337 files changed (223
`.planning/`-only, 114 source), 527 commits (265 `.planning/`-only). The
excluded-commit ledger records exactly 80 abandoned local-`main` commits (27
`excluded-rejected`, 53 `excluded-superseded`), each with a tree- and
requirement-level supersession proof, plus one `carried-on-candidate` row
(`afddc87c`) and one `published_elsewhere` row (`5da8e6b8`). The
declared-additions ref-exceptions ledger (`230-REF-EXCEPTIONS.json`) carries
`row_count: 8`. PR #44 is closed unmerged per the section above.

**D-34 handoff to Phase 232:** the canonical worktree inventory's `dirty`
boolean is currently pinned `true`. Phase 232 fully cleaning the tree will
flip that boolean `true` -> `false`, which **will fail strict re-verification**
of any capsule/inventory minted against the current `dirty: true` state. This
is an expected, known transition, not a defect -- Phase 232 must recapture
after the tree goes clean, not before.

### Adopter-named refs: fail forward (maintainer decision)

`fix/getfluent-1.5.1` and its origin counterpart embed a downstream adopter's
product name. They predate this work, are already on the public origin, are not
merged to main, and the same names are already in the previously committed
inventory, so nothing here added exposure. Maintainer decision: FAIL FORWARD --
leave them. Renaming would invalidate the frozen manifest (the old names are
baked into an immutable capsule pinned by the committed inventory's
manifest_sha256), so it is only free when a NEW capsule is minted. Revisit then.
Convention going forward: no adopter, customer or personal names in ref names.
