---
gsd_state_version: "1.0"
milestone: v1.62
milestone_name: Release Integration & Repository Hygiene
current_phase: 229
current_phase_name: Repository Truth & Recovery Safety
status: executing
stopped_at: Completed 229-16-PLAN.md
last_updated: "2026-09-15T14:05:21.205Z"
last_activity: 2026-09-13
last_activity_desc: Phase 229 execution started
state_head: 5653216c6f5d012eaef71f48a8ffb746c1aee8c3
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 20
  completed_plans: 16
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-09-12)

**Core value:** A Phoenix developer can install Accrue and its companion admin UI and launch a real SaaS with subscription billing on day one, without avoidable integration or release risk.

**Current focus:** Phase 229 — Repository Truth & Recovery Safety

## Current Position

Phase: 229 (Repository Truth & Recovery Safety) — IN PROGRESS
Plan: 19 of 20
Status: Gap closure execution complete through 229-19; 229-20 BLOCKED on maintainer-held private capsule values
Last activity: 2026-09-15 — Sealed 229-18 and 229-19 (CR-01/02/05/06/07 and WR-01 closed; all four CI gates green)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 0
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 229. Repository Truth & Recovery Safety | 0 | — | — |
| 230. Reviewable History Integration | 0 | — | — |
| 231. Exact-SHA Release Gate Proof | 0 | — | — |
| 232. Bounded Hygiene & Release Handoff | 0 | — | — |
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

### Pending Todos

None yet.

### Blockers/Concerns

- Remote `main` and the v1.61 lineage have diverged; the local `main` ref is stale and independently divergent.
- Four audit-closure commits are not published, and the required live-CI monitor is unavailable; both need honest evidence or an explicit waiver before release handoff.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260915-dpd | Fix eager Mix.env/0 evaluation in Accrue auth modules that crashes OTP releases at boot | 2026-09-15 | 5653216c | [260915-dpd-fix-eager-mix-env-0-evaluation-in-accrue](./quick/260915-dpd-fix-eager-mix-env-0-evaluation-in-accrue/) |

## Session Continuity

Last session: 2026-09-15T16:30:00Z
Stopped at: Phase 229 is COMPLETE at 20/20 plans. 229-20 shipped both tasks; the final recovery-backed canonical inventory pair is published, committed and independently strict-verified against the real capsule.

229-20 outcome (commits 024eaeca, ddd9a137, c6677152):
- Strict verification PASSES at all three points: capture commit A, after committing the canonical pair (B), and after committing the summary (C). The A-to-B-to-C ancestry property holds on the real repository, not just in fixtures.
- The recovery capsule is byte, type, owner and digest immutable across the run. Exactly one addition: phase229-final-capture-attestation-round3.json, mode 0600, uid 501, schema v2.
- The published inventory is live_remote (remote facts obtained under terminal proof), captured at 024eaeca. Committed recovery digests still match their anchors.
- All seven gates green; phase229_gap_closure is now 21/21.

Two blockers surfaced ONLY against the real capsule; both are fixed and covered:
1. assertStrictRecovery required the frozen manifest refs to EQUAL the freshly captured refs. A real capsule is minted once and then immutable, so at capture time the manifest had frozen the active ref 127 commits in the past -- meaning no real capsule could ever verify, contradicting 229-20's own must-have. Replaced with assertCapturedRefContinuity: exact for every frozen ref except the active one, which must instead prove the frozen object is still reachable from the captured commit. NOTE the class of blindness here: the generated fixtures mint the capsule and capture the inventory at the SAME commit, so no fixture-only test could see this. The new regression advances the active ref past the freeze first, and its negative uses a same-tree root commit so only the ancestry check can reject it.
2. The recovery bundle was mode 0644 against a verifier requiring 0600 or stricter -- the capsule predated its own access-control rule. Tightened to 0600 with maintainer approval; bytes, digest, type and owner unchanged. Recorded as a deliberate exception to the mode-immutability criterion.

Still open for a maintainer decision:
- 229-VERIFICATION.md is STALE. It is dated 2026-09-13, scores 3/7 and reads gaps_found, but it predates plans 229-15 through 229-20 and names exactly the gaps those plans closed. Re-run /gsd-verify-work 229 to clear it; do not read the current status as real debt.
- The canonical inventory faithfully records two pre-existing refs whose names embed a downstream adopter's product name. They exist locally AND on the public origin, predate this plan, and the same names are already in the previously committed inventory, so the recapture added no new exposure. Renaming them is remote mutation (outside D-10) and would invalidate the frozen manifest.
- Branch fix/release-boot-env-resolver now carries the adopter boot fix as four commits off main (env resolver, auth boot path, format, docs), cherry-picked out of the 453-commit milestone branch and verified there: env 5/5, auth 6/6, mix format clean. Not pushed. The GSD quick-task planning doc was deliberately left behind on the milestone branch.
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

### Adopter boot fix: SHIPPED as PR #44

Branch `fix/release-boot-env-resolver` is pushed and PR #44 is OPEN against main
(mergeable). Four commits cherry-picked from the milestone branch
(2de4389b, 9eae363a, 173607d9, 5653216c): canonical `Accrue.Env` seam, the six
auth call sites, format, and release docs. Verified on the branch off
main @ 5c01f4bc -- env 5/5, auth 6/6, `mix format --check-formatted` clean,
zero adopter PII in the diff or PR body (it says "a downstream host app").

The fifth commit (afddc87c, the GSD quick-task planning doc) conflicts on
`.planning/` and is deliberately left on the milestone branch. Running the
Elixir suites needs `elixir 1.19.5-otp-28` in `.tool-versions`; no Elixir
version is set globally, so `mix` fails in the main checkout too.

KNOWN AND ACCEPTED: this branch plus its remote-tracking ref are two refs that
did not exist at capture, so strict verification of the published inventory now
reports `extra=[...]` for both. Maintainer-authorized fail-forward. It was
already a point-in-time check (see constraint 2 above) and the next recapture
must happen after these settle.

### Adopter-named refs: fail forward (maintainer decision)

`fix/getfluent-1.5.1` and its origin counterpart embed a downstream adopter's
product name. They predate this work, are already on the public origin, are not
merged to main, and the same names are already in the previously committed
inventory, so nothing here added exposure. Maintainer decision: FAIL FORWARD --
leave them. Renaming would invalidate the frozen manifest (the old names are
baked into an immutable capsule pinned by the committed inventory's
manifest_sha256), so it is only free when a NEW capsule is minted. Revisit then.
Convention going forward: no adopter, customer or personal names in ref names.
