---
gsd_state_version: 1.0
milestone: v1.62
milestone_name: Release Integration & Repository Hygiene
status: Awaiting next milestone
stopped_at: Phase 232 complete — all phases complete
last_updated: "2026-09-18T15:14:54.513Z"
last_activity: 2026-09-18
last_activity_desc: Milestone v1.62 completed and archived
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 44
  completed_plans: 44
  percent: 100
current_phase: 232
state_head: 4e7715f772d763d7fe6c31f426ee6fafcc66becd
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-09-18)

**Core value:** A Phoenix developer can install Accrue and its companion admin UI and launch a real SaaS with subscription billing on day one, without avoidable integration or release risk.

**Current focus:** Planning next milestone. v1.62 shipped a *reviewable, per-lane-proved* release candidate, not a green one — the candidate SHA is red on `docs-contracts-shift-left`, `release-gate`, and `phase18-tax-gate`, with fixes already on the milestone line. Written path forward: push the phase-close commits, re-run CI at the new head, confirm the gates, merge PR #45, then run Release Please.

## Current Position

Phase: Milestone v1.62 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-09-18 — Milestone v1.62 completed and archived

## Performance Metrics

**Velocity:**

- Total plans completed: 38
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
| 232 | 11 | - | - |
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
| Phase 231 P02 | 70min | 3 tasks | 3 files |
| Phase 231 P04 | 70min | 3 tasks | 5 files |
| Phase 231 P03 | 3h05min | 3 tasks | 5 files |
| Phase 231 P05 | 70min | 2 tasks | 3 files |
| Phase 231 P06 | ~90min | 3 tasks | 3 files |
| Phase 232 P02 | 95min | 3 tasks | 24 files |
| Phase 232 P03 | ~80min | 3 tasks | 22 files |
| Phase 232 P04 | ~40min | 3 tasks | 4 files |
| Phase 232 P05 | ~45min | 3 tasks | 5 files |
| Phase 232 P06 | ~35min | 3 tasks | 3 files |
| Phase 232 P08 | ~140min | 3 tasks | 8 files |
| Phase 232-bounded-hygiene-release-handoff P09 | ~25min | 3 tasks | 2 files |
| Phase 232 P10 | 3h20min | 3 tasks | 7 files |

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
- [Phase 231]: 231-02: Fourth collect/render/verify triad (window dispositions) joins 1:1 by row id to WINDOWS.md via a single assertSameMap call since ledger status and record disposition share the same fixed/waived vocabulary. — D-26/D-30: the missing/extra/changed triple falls out of one exact-map comparison rather than a separate mapping layer.
- [Phase 231]: GATE-02 dispatch of ci.yml at the exact candidate SHA proved a genuine CI failure (docs-contracts-shift-left, the release-gate matrix, Phase 18 Stripe Tax gate, Admin UI ratchet guardrails); the evidence is recorded honestly (workflow_dispatch event class, closed provider_state enum), and Phase 232 is blocked on real fixes, not on a fabricated pass.
- [Phase 231]: [Phase 231]: 231-03 GATE-01 cohort proof executed the declared 13-job merge-blocking cohort in a fresh cache-free scratch clone at the candidate ref's live tip (f524f2a6), never the bare merge-commit SHA -- so GATE-01 and GATE-02 prove the identical SHA.
- [Phase 231]: [Phase 231]: 231-03 recorded an honest discrepancy on the release-gate row rather than suppressing it: this local GATE-01 proof passed every required matrix cell it exercised (Floor/Primary/Primary+OpenTelemetry), while GATE-02's real GitHub dispatch reported failures in non-advisory release-gate cells on GitHub-hosted runners -- both results stand as independent evidence, neither overrides the other.
- [Phase 231]: Row 3 (deviation, phase 215) waived rather than fixed: the Swift capability-report reducer it named was deleted by Phase 223-04's package-facade redesign, not merely edited; the equivalent safety property is independently verified enforced today by scripts/ci/verify_ios_offline_client.sh's jq assertion against the checked-in capability-report.json. — D-22 requires escalation, not a silent fixed close, when a deviation's original change is absent at the candidate SHA rather than present-and-intact; waiving with a verified-equivalent-mechanism rationale is the honest disposition.
- [Phase 231]: Row 10 (unrun-verify, phase 227) waived rather than fixed: GATE-02 recorded exactly one real workflow_dispatch observation and it concluded failure, not a qualifying success, so Phase 227's three-success bounded critical-path comparison still cannot run -- the original data-gap blocker reproduces in substance even though a dispatch now executes. — Per D-22, a gate that now executes but does not produce the specific outcome the row required (a qualifying success, not merely any real outcome) closes as waived, never silently rolled forward as fixed.
- [Phase 231]: Re-cut integration/v1.62-candidate verifiers permanently merge-blocking; every Phase 231 evidence artifact discoverable and reproducible from scripts/ci/README.md; fresh 231-REPOSITORY-INVENTORY.json capsule minted last, after all window-status and STATE.md/ROADMAP.md edits settled. — D-32/D-28: new verifiers must be merge-blocking and documented before the phase closes; D-28 requires the capsule to be minted only after planning docs settle or it invalidates itself on the next GSD step.
- [Phase 232]: Re-derived the 232-02 guard-migration census live; found 4 IN-01 no-guard files (not 1) and all 8 idiom-2 files vacuous (not 3); expanded Task 2's same-commit guard+test work within declared scope accordingly. — D-15 no-transcription rule: plan-authored file lists rot between planning and execution.
- [Phase 232]: Task 1's own real-repository acceptance criterion (--require-guard-coverage --require-non-vacuity --require-cohort-floor exits 0 against the real cohort) forced migrating 12 more guard-less scripts/ci/*.mjs files within Task 1 -- the ones 232-02 explicitly deferred as out of its own scope -- rather than leaving Task 1's own gate unsatisfied until a later plan. — D-15 no-transcription / Rule 3 blocking-issue: the plan's own acceptance criteria are the authority, and the real-repo invocation genuinely could not pass with 15 files still ungated.
- [Phase 232]: Spawning or dynamically importing a now-guard-migrated scripts/ci/*.mjs file must delete (not blank with an empty string) any inherited NODE_TEST_CONTEXT from the child's env -- node:test's recursion guard treats mere key presence as "already inside a test run" and silently skips the nested invocation, turning a deliberately-bad CLI negative control's expected non-zero exit into a false 0. — Found via Task 1 fixture failures and confirmed via a full 382-file cohort node --test sweep; documented in scripts/ci/README.md's Module-boundary guard convention section for future guard migrations.
- [Phase 232]: [Phase 232]: 232-04: bucketOf() is a total (disposition, state) pair map keyed by a NUL-separated pairKey(), failing closed by row id and both values on any unmapped pair -- replacing the fall-through if-chain whose unreachability was previously recorded only in a comment (D-13).
- [Phase 232]: [Phase 232]: 232-04: a cartesian-product reachability test derives legal (disposition, state) pairs by calling validateWindowRow directly (never a hand-listed table), asserting the derived set non-empty and that reached buckets exactly equal declared buckets, proving both directions of the mapping in one assertion (D-14).
- [Phase 232]: [Phase 232]: 232-04: [Gotcha] a literal null-escape written into an Edit-tool old_string/new_string parameter decodes to the actual NUL codepoint, not the six-character source text -- silently turning a text file into a git-perceived binary file; fix with a byte-level direct file replacement instead of retrying the Edit tool.
- [Phase 232]: [Phase 232]: 232-05: Targeted the readiness dry run at integration/v1.62-candidate, not main -- main is already fully released at 1.5.1 with zero pending commits today, so testing against it would produce a vacuous empty plan and make every count-based REL-05 assertion unsatisfiable; the candidate carries the real unreleased commits and reproduced 232-CONTEXT.md's D-35/D-36 measurements exactly (14 bullets, 1.6.0 lockstep, updates: 7).
- [Phase 232]: [Phase 232]: 232-06: Placed the Parked-lane expiry trigger (D-26) in the BLOCKING admin-ui-ratchet-selftests job, not the parked job, because GitHub Actions job-level continue-on-error absorbs the whole job's conclusion regardless of any step's own setting -- there is no per-step override, matching the plan's own documented fallback.
- [Phase 232]: [Phase 232]: 232-06: Ship-window row 11 uses kind unmet-truth (not unrun-verify/deviation) -- the ratchet lane's truth (a frozen, zero-open-findings ledger) is currently false, matching D-21's mandate that this lane's honest state is failed, never non_run/skipped/advisory.
- [Phase 232]: Maintainer decision at 232-08's checkpoint: rewrite .tool-versions to match integration/v1.62-candidate byte-for-byte (nodejs 22.14.0 / elixir 1.19.5-otp-28 / erlang 28.5), joined into the cleanup findings range as finding 8. — Local .tool-versions diverged from the candidate branch in two dimensions (erlang patch version AND a missing nodejs pin entirely); every scripts/ci/*.mjs gate is a Node script and ci.yml pins Node 22, while the local shell runs Node 24 -- local and CI gate runs were on different Node majors.
- [Phase 232-bounded-hygiene-release-handoff]: Re-cut integration/v1.62-candidate at a new SHA (c1397fe9, merge 3f42158d), proved lossless by a newly generalized --require-union-hunks check (447 inspected, 7 co-touched, 0 drifted). Maintainer checkpoint decision: since updating the published branch required a non-fast-forward (force-push, prohibited), pushed the re-cut to a NEW branch integration/v1.62-candidate-recut instead, leaving integration/v1.62-candidate untouched. — Option A (move the published branch) required a force-push the plan itself prohibits -- an internal plan contradiction for a fresh-supersession re-cut where the old tip is not an ancestor of the new tip. Option B resolves it without relaxing any prohibition; 232-10/232-11 must target integration/v1.62-candidate-recut, not integration/v1.62-candidate.
- [Phase 232]: Both real regressions found (docs-contracts-shift-left human_judgment violations, release-gate stale test fixture) fixed and verified on the milestone line but NOT pushed to the frozen candidate-recut ref -- recorded waived at the frozen SHA with the fix commit cited as evidence

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

- **Resolved by v1.62:** the `main`/v1.61 divergence, the stale local `main` ref, the four unpublished audit-closure commits, and the unavailable live-CI monitor. All are reconciled into the integration candidate with committed evidence.
- **Open:** the frozen candidate SHA is red on `docs-contracts-shift-left`, `release-gate` (Floor, Primary, Primary+OpenTelemetry), and `phase18-tax-gate`. Fixes exist on the milestone line but were deliberately not force-pushed into the frozen ref. Release requires re-gating at the new head.
- **Open (maintainer decision):** the adopter name `getfluent` appears in 34 places across 16 files on the published candidate branch, as public branch `refs/heads/fix/getfluent-1.5.1`, and as head of merged public PR #41. No credential, token, PII, or vulnerability — a business-relationship disclosure, classified *retained / maintainer-decided*.
- **Open (coverage):** Nyquist validation is partial — 229 genuine PARTIAL, 230 MISSING, 231/232 `draft`.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260915-dpd | Fix eager Mix.env/0 evaluation in Accrue auth modules that crashes OTP releases at boot | 2026-09-15 | 5653216c | [260915-dpd-fix-eager-mix-env-0-evaluation-in-accrue](./quick/260915-dpd-fix-eager-mix-env-0-evaluation-in-accrue/) |
| 260916-gda | Close phase-231 loose ends: STATE.md standing sections, gap-closure TAP harness, 229-UAT regen, CR-01 window-disposition invariant, WR-01 expected-repository validation, REQUIREMENTS.md gate wording | 2026-09-16 | f5b6d390 | [260916-gda-close-phase-231-loose-ends-state-md-stan](./quick/260916-gda-close-phase-231-loose-ends-state-md-stan/) |
| 260916-hl9 | Resolve the sibling dependency-operator contradiction between CLAUDE.md and the code, and make it machine-enforced | 2026-09-16 | 9f309871 | [260916-hl9-resolve-the-sibling-dependency-operator-](./quick/260916-hl9-resolve-the-sibling-dependency-operator-/) |
| 260917-l7v | Shift left seven phase-232 session failure modes into merge-blocking CI guards (SL-A through SL-G) | 2026-09-17 | b42c64a5 | [260917-l7v-shift-left-phase-232-session-lessons-int](./quick/260917-l7v-shift-left-phase-232-session-lessons-int/) |
| 260918-rpt | Fix release-PR title generation (grouped ${version} with no root package) that made release 1.6.0 tag nothing while reporting success; add a merge-blocking round-trip guard | 2026-09-18 | 11cf1e02 | [260918-rpt-fix-release-pr-title-generation](./quick/260918-rpt-fix-release-pr-title-generation/) |
| 260918-e8m | Correct v1.62 ROADMAP doc-truth drift before archive: two Phase 231 success criteria claimed green gates the candidate SHA never earned, plus a stale 16/20 plan count | 2026-09-18 | 62c5c6a0 | [260918-e8m-correct-v1-62-roadmap-doc-truth-drift-be](./quick/260918-e8m-correct-v1-62-roadmap-doc-truth-drift-be/) |

## Deferred Items

| Category | Item | Status |
|---|---|---|
| requirement | HOST-01..03 | Deferred at v1.60 override closeout |
| requirement | READY-01..02 | Deferred at v1.60 override closeout |
| seed | SEED-008-mailglass-downstream-major-cap | dormant — acknowledged and deferred at v1.62 override closeout (2026-09-18) |

## Post-v1.48 Pause Rule

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

v1.55 OSS Quality Evaluation & Hardening Roadmap shipped on 2026-07-03 as maintenance / release-readiness / support-contract hardening under stable core. It was audit-only and produced evidence-backed software quality, CI/CD, and DB schema-contract artifacts plus a ranked implementation roadmap; it did not change product behavior, public APIs, DB defaults, CI required-check topology, release automation, or runtime UI.

v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync opened 2026-07-30 as **maintenance / dependency currency plus closing a prior explicitly-deferred capability** (SEED-005's trigger fired 2026-07-29 when lattice_stripe `2.0.0` published with entitlements support, unblocking Phase 127's deferred optional Stripe-native sync). Not broad feature scope: stays inside the already-shipped entitlements feature, keeps the local plan→feature map canonical as the sole grant gate (D-01/D-11), and keeps `scripts/ci/verify_entitlement_sync_isolation.sh` green throughout.

Active v1.59 clears the reopen rule through a concrete adopter requirement and explicit strategy change. B2C Alpha needs coherent Stripe/Apple account access plus extended offline use; the reusable signal is recorded without adopter identity or PII in `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md`.

### Historical Research Assets

- **v1.17 Friction Inventory (FRG-01):** `.planning/research/v1.17-FRICTION-INVENTORY.md`
- **v1.17 North Star:** `.planning/research/v1.17-north-star.md` — stop rules S1–S5.
- **v1.47 Research:** `.planning/research/SUMMARY.md`
- **v1.51 Admin UI Depth Design:** `.planning/research/v1.51-admin-ui-depth-design.md` (prior design source carried forward for v1.53/v1.54)
- **v1.52 Brand System Design:** `.planning/research/v1.52-brand-system-design.md`
- **v1.54 Research (archived source):** `.planning/research/SUMMARY.md` (page-level streamlining + Storybook synthesis of FEATURES.md, ARCHITECTURE.md, PITFALLS.md, v1.54-storybook-and-forward-only-qa.md)

## Session Continuity

Last session: 2026-09-17T14:59:41.861Z
Stopped at: Phase 232 complete — all phases complete

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

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
