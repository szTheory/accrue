# Phase 231: Exact-SHA Release Gate Proof - Context

**Gathered:** 2026-09-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish one exact integration-candidate SHA and prove it releasable from complete, honest evidence: the repository's declared merge-blocking gates pass in a fresh clean checkout (GATE-01), the required GitHub Actions checks are green for that exact SHA with provider lanes keeping explicit proof-state semantics (GATE-02), and every open ship window is fixed or explicitly waived with current evidence, owner, rationale, and release impact (GATE-03).

This phase DOES: re-cut the integration candidate so the gated SHA contains Phase 230's own verifiers; push that one branch to `origin` and dispatch `ci.yml` against it; run the repo-declared merge-blocking cohort from a scratch clone; re-derive each ship window's condition at the candidate SHA and drive all ten to fixed-or-waived; emit fail-closed evidence artifacts.

This phase does NOT: open the integration pull request, write the reviewer risk summary or rollback instructions, prove Release Please readiness (all Phase 232 / REL-04, REL-05); merge anything to `main`; push `main`; move, re-annotate, or delete tags; force-push; classify or remove untracked files, stale worktrees, or remote maintenance branches (Phase 232 / HYG-01); publish packages.

</domain>

<decisions>
## Implementation Decisions

### Measured Ground Truth (re-measure at plan time; never transcribe — D-15 of Phase 230 still binds)

- **D-00:** Every fact below was measured live in this repository on 2026-09-15. Treat each as a binding to re-measure, not a value to copy forward. Phase 230 proved transcription rots (`origin/main` moved mid-discussion; a sixth co-touched file appeared).
  - `integration/v1.62-candidate` = `bab50d92`; milestone branch `gsd/milestone-v1.62-release-integration-hygiene` HEAD = `030a3c6e`; `origin/main` = `d30fc25d` (unmoved since Phase 230 closed); `review/v1.62-candidate-code-only` = `0595d1dd`.
  - `git merge-base --is-ancestor integration/v1.62-candidate HEAD` → **NO**. `git rev-list --left-right --count candidate...HEAD` → **27 / 37**.
  - The candidate's two unique non-merge commits are `31d19449` (toolchain pin + sibling lockfile re-resolution for Decimal 3) and `bab50d92` (config.ex disjoint-hunk coverage).
  - 37 milestone-only commits include **all** Phase 230 evidence artifacts, the CR-01/CR-02/WR-01/WR-02 fix commits, and WR-01's wiring of `verify_integration_disposition.mjs` and `verify_phase230_archive_invariants.mjs` into merge-blocking CI.
  - `.tool-versions` exists on the candidate, is **untracked** on milestone HEAD. `git diff --stat candidate HEAD -- . ':!.planning'` → **61 files**.
  - `origin/main` is an ancestor of the candidate but **not** of milestone HEAD.
  - `gh auth status` → authenticated as `szTheory`; remote is `https://github.com/szTheory/accrue.git` (public).
  - `gh api repos/szTheory/accrue/branches/main/protection` → **404 Branch not protected**; `gh api repos/szTheory/accrue/rulesets` → **`[]`**.
  - `.planning/WINDOWS.md`: `open_count: 10`, `waived_count: 0`, `fixed_count: 0`; every row's `reason`/`resolved_at` cell empty.

### Candidate SHA Identity

- **D-01:** **Re-cut the candidate from current milestone HEAD.** *(User decision.)* Repoint `refs/heads/integration/v1.62-candidate` to a fresh `--no-ff` merge of `origin/main` cut from `030a3c6e`, re-applying the toolchain pin and the `config.ex` disjoint-hunk test. Freezing `bab50d92` is rejected: it would prove releasable a SHA that lacks the very verifiers GATE-01/GATE-02 must check, and that Phase 230's own later code review already found needed fixing (CR-01, CR-02). — **Reversibility:** costly — every downstream artifact (GATE-01 run evidence, GATE-02 check-run proof, Phase 232's PR body) binds to the resulting SHA; changing it again invalidates all of them.
- **D-02:** **Record the re-cut in Phase 231's own evidence, not as a Phase 230 addendum.** *(User decision.)* Phase 230 is closed and verified; 231's evidence must state plainly why the candidate object changed after 230's closure, so an outside reader is never left comparing a live ref against a closed phase's record.
- **D-03:** **The re-cut is a precondition task at the very start of the phase**, not scope creep and not a mid-phase correction. Nothing else in Phase 231 may bind to a SHA until this task completes and its ancestry gates pass.
- **D-04:** **All of Phase 230's locked shape constraints carry forward unchanged** and must be re-asserted against the new candidate `C`: a single first-parent `--no-ff` merge; `git revert -m 1 C` reproduces the milestone parent's tree byte-identically; `v1.61` still resolves to tag object `fdb41672` → commit `e3b06794` and is an ancestor of `C`; `origin/main` is an ancestor of `C`; each of the four closure SHAs `8a95fbe8`, `9e090eb5`, `7cc501a3`, `57c61a9a` is an ancestor of `C`; and `git rev-list --count C ^030a3c6e ^origin/main == 1`. Rebase and squash remain disqualified (Phase 230 D-02, D-03).
- **D-05:** **Advance-by-merging and merge-back-then-recut are structurally disqualified**, not merely dispreferred. Merging milestone HEAD into the existing candidate creates a second merge point, pushes the `rev-list --count` assertion far above 1, and breaks the `revert -m 1` exact-undo property. Merging the candidate into the milestone branch first adds a merge commit Phase 230's D-31 ref budget does not account for, to reach a state the direct re-cut already reaches.
- **D-06:** **Recompute the hazard universe fresh against the new candidate** rather than assuming Phase 230's findings recur. `origin/main` has not moved, so the same three real hazards (`accrue/lib/accrue/config.ex`, `accrue/mix.exs`, `accrue/guides/entitlements.md`) and three convergent-identical files are *expected* — but expectation is not proof, and a `STALE_BINDING` refusal is the correct outcome if the verifier is handed a stale binding.
- **D-07:** **Re-mint the rollback-point record for the new candidate**, with the revert proof executed — not asserted — in a scratch `git clone` in the scratchpad (never `git worktree add`; the inventory verifier pins an exact worktree-row multiset). `restore_argv` stays an argv array, never a shell string. The existing `230-ROLLBACK-POINT.json` is a frozen point-in-time artifact bound to the superseded candidate: leave it untouched and supersede it by reference, do not edit it in place.
- **D-08:** Re-capture `.tool-versions` (`elixir 1.19.5-otp-28`) on the new candidate. It is enablement, not hygiene: GATE-01 demands a fresh clean checkout that runs local gates, and a clone lacking it cannot satisfy that without out-of-band operator knowledge.

### GATE-01 — Local Gate Scope and Environment Purity

- **D-09:** **Scope GATE-01 to the repository's own declared merge-blocking cohort**, as enumerated in the `ci.yml` header comment: `release-manifest-ssot`, `docs-contracts-shift-left`, `release-gate`, `phase18-tax-gate`, `admin-drift-docs`, `admin-group-contracts`, `admin-hardening-guardrails`, `admin-phase200-guardrails`, `admin-ui-ratchet-guardrails`, `host-integration`, `playwright-e2e`, `host-docker-smoke`, `annotation-sweep`. "Complete" means complete with respect to what this repository's CI treats as required — not complete with respect to every lane Phase 230 happened to enumerate.
- **D-10:** **The Phase-230 thirteen-lane table is a disposition record, not a scope proposal.** It recorded what Phase 230 correctly declined to run under the D-20 mechanical corollary. Three of its entries are not repository-declared gates at all: `mix hex.publish --dry-run` and `gh workflow run ci.yml` exist as no CI job, and `gh workflow run` is definitionally non-local. Record these `non_run` with reason "not a repository-declared local-CI-equivalent gate" — do not invent a gate the repo never enforced.
- **D-11:** **A credential-gated lane recorded `skipped` with a reason satisfies GATE-01; it does not violate it.** `live-stripe` needs `STRIPE_TEST_SECRET_KEY` and `ci.yml` states outright that it never runs on pull requests — it is periodic/dispatch-only and outside the merge-blocking cohort. `provider-proof-trigger` and `provider-proof-incident` are scheduler-only. `ios-offline-client` runs on PRs but is deliberately absent from `annotation-sweep`'s `needs:` list, so it is outside the declared merge-blocking contract. Each gets an explicit row with its reason.
- **D-12:** **Run from a scratch `git clone` of the local repository at the exact candidate SHA** — not from `origin` (the candidate branch is local-only until D-14's push, and the code-only review branch never leaves the machine), and never via `git worktree add` (Phase 230 D-30: the inventory verifier pins an exact multiset of `{branch, sha, dirty}` worktree rows, so any added worktree fails it). — **Reversibility:** reversible — a scratch clone creates zero refs and zero worktree rows in the subject repo.
- **D-13:** **"Without ignored caches" is satisfied by construction, not by assertion:** `deps/`, `_build/`, `priv/plts`, and built assets are all rebuilt fresh inside the scratch clone, never restored from a cache. Expect real local cost — a cold Dialyzer PLT build and a Chromium download — and a running Docker daemon for `host-docker-smoke`, whose setup creates a `proxy` network. Budget for this in the plan rather than discovering it mid-run.

### GATE-02 — Exact-SHA GitHub Proof

- **D-14:** **Push `integration/v1.62-candidate` to `origin`, then trigger with `gh workflow run ci.yml --ref integration/v1.62-candidate`.** *(User decision — this is the separate explicit authorization the project's remote-mutation posture requires.)* Push exactly this one branch; do not push `main`, do not open a PR. — **Reversibility:** one-way in practice — the SHA becomes public on `szTheory/accrue` and may be fetched, referenced, or indexed; deleting the branch later does not unpublish the commit.
- **D-15:** **Pushing alone proves nothing — `ci.yml`'s `push:` trigger is filtered to `branches: [main]`, so pushing the candidate branch fires zero checks.** The dispatch is what produces check runs. A plan that pushes and waits for checks will wait forever.
- **D-16:** `workflow_dispatch` is the right trigger because every merge-blocking job gates on `if: github.event_name != 'schedule'` — a dispatch runs the identical job set a pull request would, while creating no PR object, leaving REL-04 wholly to Phase 232.
- **D-17:** **The evidence must state its event class explicitly.** The proof obtained here is `workflow_dispatch`-class; Phase 232's PR will produce a second, distinct check-run set for the same SHA. Record the class as a first-class field so nobody later reads a dispatch proof as a pull-request proof.
- **D-18:** **Do not ask GitHub what is required — it declares nothing.** `branches/main/protection` returns 404 and `rulesets` returns `[]`. A checker that enumerates required checks from branch protection finds an empty set and passes vacuously, which is silently wrong rather than merely unavailable. Enumerate the required set from the in-repo declaration (the `ci.yml` header comment's merge-blocking list), and **assert that declaration has not drifted from the live job graph** — a required job silently renamed or removed must fail the gate.
- **D-19:** **Extend `scripts/ci/collect_ci_baseline.mjs` rather than writing a parallel mechanism.** It already normalizes runs and jobs keyed by `head_sha`, derives `required_job_set` from the actual job graph via `cohortFingerprint`, and carries a closed `provider_state` enum (`proved|failed|misconfigured|blocked|skipped|non_run`) with no `success`/`green` alias reachable.
- **D-20:** **Poll to completion; never dispatch-and-trust.** Account for dispatch propagation delay, and fail closed on a run that is queued, cancelled, or still in progress rather than treating absence of failure as success.
- **D-21:** **`live-stripe` only runs on `workflow_dispatch` when the `run_live_stripe` input is true.** A dispatch that leaves it unset yields `skipped`/`non_run` — which is honest and acceptable — but the checker must fail closed on any record claiming `proved` without a recorded exit code (Phase 230 D-24).

### GATE-03 — Ship-Window Resolution

- **D-22:** **Disposition is decided by the row's `kind`, by an evidence-backed test, not by judgment.**
  - `unrun-verify` (rows 1, 4, 5, 7, 8, 10): the window records "the gate could not run". It is **fixed** when the gate now executes at the candidate SHA and reports a real outcome — GATE-01's clean-checkout run is that evidence. A gate that runs and *fails on its merits* is a new GATE-01 blocker, not a still-open window. If the original blocker still reproduces, the row is **waived**, and waiving requires owner, rationale, and release impact — it may not silently roll forward.
  - `deviation` (rows 2, 3, 6, 9): an intentional, already-merged, already-reviewed change is **not a defect by default**. It closes as **fixed** by confirming the change is still present and intact at the candidate SHA plus a recorded rationale and release-impact statement. Inspection showing the change stale, absent, or newly risky escalates it.
- **D-23:** **"Current evidence" means re-derived at the candidate SHA — never the original description copied forward.** Row 1 is the proof this matters: it records that the checked-in Playwright config has no `chromium-mobile` project, but `examples/accrue_host/playwright.config.js` already defines one. Reusing a recorded description as evidence would have closed that row on a false premise.
- **D-24:** **Row 5 is handled conservatively and never auto-waived.** It records a real failing test (`examples/accrue_host/test/accrue_host/billing_facade_test.exs:160`, fake subscription uniqueness), not merely a gate that could not start. It is investigate-then-fix-or-block.
- **D-25:** **`.planning/WINDOWS.md` keeps its terse schema.** Flip statuses only through the ledger's own writer (`gsd-tools windows waive <id> "<reason>"` / `windows fixed <id>`), which rewrites the table deterministically and recomputes the counts. Extending the schema is rejected: `directShipWindows` in `verify_repository_inventory.mjs` hardcodes a 10-column parse, and widening it cascades into Phase 229/230 fixture golden files and re-litigates a schema D-28 already settled.
- **D-26:** **Richer GATE-03 fields live in a sibling artifact** — `231-WINDOW-DISPOSITIONS.{json,md}` as a `collect → render → verify` triad carrying owner, rationale, release impact, and current evidence per id, joined **1:1 by row id** to every non-`open` WINDOWS.md row with exact set equality. This is the same terse-ledger-plus-rich-sibling shape Phase 230 D-28 chose for `230-REF-EXCEPTIONS.json`. WINDOWS.md's single `reason` cell holds the short summary, sourced from the rich artifact.
- **D-27:** **Flipping window statuses is safe in routine CI, and here is exactly why** — so the plan does not paper it over with a waiver. `collect_repository_inventory.mjs::readShipWindows` recomputes `ship_windows` fresh from live WINDOWS.md at collection time, so a collect+verify pair is self-consistent by construction, and `ci.yml` only runs the `--fixtures` self-tests. The real hazard is narrow: re-diffing a **frozen, already-published** capsule (`229-REPOSITORY-INVENTORY.json`, or Phase 230's) against a changed WINDOWS.md.
- **D-28:** **Do not touch or re-diff the frozen 229/230 capsules.** If Phase 231 needs its own capsule proof, mint a fresh `231-REPOSITORY-INVENTORY.json` **after** all window-status edits land, following the one-capsule-per-phase pattern. Mint it last, after `.planning/STATE.md` and the roadmap settle, or it invalidates itself on the next GSD step; `git bundle create` resets mode to 0644, so `chmod 600` before publish.

### Evidence Conventions (inherited, non-negotiable)

- **D-29:** **Phase 226's proof-state lexicon binds every record:** `proved` (a named command ran at the candidate SHA with real assertions and exit 0, argv and exit code recorded), `failed`, `skipped` (with reason), `advisory`, `non_run`. `deferred`, `n/a`, and `green` are forbidden. No aggregate boolean. Reject any `state: proved` lacking a recorded exit code. A green Actions conclusion is not provider proof.
- **D-30:** Completeness assertions are **exact sorted set/multiset equality recomputed inside the verifier** — never non-empty checks, never asserted booleans. Reuse the existing `exactMap`/`assertSameMultiset` helpers, which already emit `missing`/`extra`/`changed` triples. Counts are asserted as literal integers.
- **D-31:** Render determinism: re-rendering the JSON must byte-equal the committed Markdown. Timestamps come from `git show -s --format=%cI` of the candidate, never `Date.now()`. Sanitize via allow-listed fields — no absolute paths, no `$HOME`, no actor names, no adopter identifiers, no secrets.
- **D-32:** New artifacts resolve through `scripts/ci/phase_evidence_path.mjs` so they survive milestone archiving, and each gets a row in the `scripts/ci/README.md` evidence table.
- **D-33:** Acceptance is fully executable with zero human checkpoints; `behavior_unverified: 0` is required to close the phase. No `type="tracer"`, no `checkpoint:human-verify`, no `<human-check>` where an executable assertion can decide the outcome.

### Claude's Discretion

- Exact JSON schema field names, artifact filenames, script module decomposition, and renderer layout, provided output is deterministic, sanitized, independently verifiable, and consistent with the 226/229/230 precedent.
- Whether GATE-01, GATE-02, and GATE-03 evidence are three artifacts or fewer, provided each completeness assertion holds independently and each gate's proof is separately readable.
- Task decomposition and ordering within the phase, subject to D-03 (re-cut first) and D-28 (capsule last).
- Whether the required-job drift check (D-18) lives in the new checker or extends an existing `scripts/ci` verifier.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Contract
- `.planning/PROJECT.md` — v1.62 goal, stable-core posture, immutable-history guardrails.
- `.planning/REQUIREMENTS.md` — GATE-01, GATE-02, GATE-03 (this phase); HYG-01..03 / REL-04..05 (Phase 232).
- `.planning/ROADMAP.md` — Phase 231 boundary, dependency order, success criteria.
- `.planning/STATE.md` — accumulated decisions and current position.
- `prompts/GSD-REPO-HYGIENE.md` — repository-hygiene posture, no-force-push / immutable-history rules.
- `CLAUDE.md` — the post-218 executable-acceptance policy that forbids human-judgment gates.

### Immediate Predecessor (binding — read first)
- `.planning/phases/230-reviewable-history-integration/230-CONTEXT.md` — D-01..D-39. Especially **D-01..D-06** (candidate shape, disqualified alternatives), **D-15** (never transcribe a hazard universe), **D-20** (the 230/231 scope line), **D-24** (proof-state lexicon), **D-28** (why WINDOWS.md stays terse), **D-29/D-30** (rollback point, scratch clone not worktree), **D-31** (ref budget and the Phase-230-scoped no-push rule), **D-37..D-39** (evidence conventions).
- `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md` — the "Phase-231 lanes" table (13 `non_run` rows) and the Phase-232 handoffs. Read as a **disposition record**, per D-10 above, not as GATE-01's scope.
- `.planning/phases/230-reviewable-history-integration/230-ROLLBACK-POINT.json` — frozen, bound to the superseded candidate `bab50d92`. Supersede by reference; do not edit.
- `.planning/phases/230-reviewable-history-integration/230-VERIFICATION.md` — passed-state precedent.
- `.planning/phases/229-repository-truth-recovery-safety/229-CONTEXT.md` — locked evidence conventions.
- `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json` — **frozen capsule; do not re-diff against a changed WINDOWS.md** (D-27, D-28).

### CI Contract
- `.github/workflows/ci.yml` — **the header comment is the authoritative merge-blocking job list** (D-09, D-18); `on:` triggers (`push` filtered to `main`, `pull_request`, `workflow_dispatch` with the `run_live_stripe` input); the `if: github.event_name != 'schedule'` job guards; `annotation-sweep`'s `needs:` list; the `live-stripe` "never runs on pull requests" comment; and the ~line 140-158 note that strict capsule verification is deliberately not run routinely.
- `.planning/milestones/v1.61-phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` — repository-bound CI evidence conventions and the proof-state lexicon.

### Implementation Surfaces to Reuse
- `scripts/ci/collect_ci_baseline.mjs` — `normalizeRun`/`normalizeJob` keyed by `head_sha`, `cohortFingerprint`'s `required_job_set` derivation, the closed `PROVIDER_STATES` enum. **The file D-19 extends.**
- `scripts/ci/render_ci_baseline.mjs`, `scripts/ci/verify_ci_baseline.mjs` — the triad pattern, `allowedFields()` sanitization, `--fixtures` self-test convention.
- `scripts/ci/verify_repository_inventory.mjs` — `directShipWindows` (the hardcoded 10-column WINDOWS.md parse, ~line 523-547) and `assertCompleteCategories` (~line 583-602). **The parser D-25 refuses to widen.**
- `scripts/ci/collect_repository_inventory.mjs` — `readShipWindows` (~line 402, used ~line 451): recomputes ship windows fresh at collection time, which is *why* D-27 holds.
- `scripts/ci/verify_integration_disposition.mjs`, `scripts/ci/verify_phase230_archive_invariants.mjs` — wired merge-blocking by WR-01; present on milestone HEAD, **absent from the superseded candidate**. Their presence is part of what the re-cut buys.
- `scripts/ci/phase_evidence_path.mjs` — archive-aware evidence resolution.
- `scripts/ci/preserve_repository_state.sh` — capsule/bundle minting; the 0644-vs-0600 bug from 229-19.
- `scripts/ci/README.md` — contributor-facing evidence map; add the new rows here.

### Ship Windows
- `.planning/WINDOWS.md` — the ten open rows; terse schema preserved (D-25).
- `~/.claude/gsd-core/bin/lib/broken-windows.cjs` — `markWaived` / `cmdWindowsMarkFixed`, the ledger's canonical writer; confirms no owner/release-impact columns exist.
- `examples/accrue_host/playwright.config.js` — line ~50 defines `chromium-mobile`, contradicting row 1's recorded description (D-23).
- `accrue_admin/mix.lock` — line 41, confirms row 9's `jose` lock still holds.

### Release Contract
- `RELEASING.md` — Release Please as the single writer of `@version` and numbered CHANGELOG sections.
- `release-please-config.json`, `.release-please-manifest.json` — the 1.5.1 baseline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `collect_ci_baseline.mjs` already reads GitHub run/job data keyed by `head_sha` and derives the required job set from the live job graph — GATE-02 extends it rather than inventing a checker.
- The `collect → render → verify` triad exists three times (`*_ci_baseline.mjs`, `*_repository_inventory.mjs`, `*_integration_disposition.mjs`); GATE-03's window-disposition artifact is a fourth instance by cloning, not by new design.
- `exactMap` / `assertSameMultiset` emit `missing`/`extra`/`changed` triples — reuse verbatim for the row-id join and the required-job set.
- `resolvePhaseEvidencePath` makes new artifacts survive milestone archiving for free.
- `gsd-tools windows waive/fixed` already rewrites WINDOWS.md deterministically and recomputes all four counts — no bespoke ledger writer needed.

### Established Patterns
- Evidence is sanitized machine-readable JSON plus deterministically rendered Markdown, bound to repository identity, observation time, exact object IDs, and the producing command as an argv array.
- Proof states stay distinct and no aggregate boolean is emitted; a green Actions conclusion is never provider proof.
- Completeness is exact set/multiset equality recomputed inside the verifier, never a non-empty check.
- A terse pinned ledger plus a rich sibling artifact joined by id is the settled shape for anything needing more fields than the ledger's schema allows.
- Remote mutation and destructive operations require separate explicit authorization — obtained here for exactly one branch push (D-14).

### Integration Points
- `gh` is authenticated as `szTheory` against the public `szTheory/accrue`, so both the push and the dispatch are mechanically available.
- `git ls-remote` reads live remote truth without mutating local refs — preferred over `git fetch` during evidence capture.
- `docs-contracts-shift-left` is where new merge-blocking verifiers land.
- Scratch clones in the scratchpad give a fresh checkout that creates zero refs and zero worktree rows in the subject repo.

</code_context>

<specifics>
## Specific Ideas

- The maintainer's actual question at the end of this phase is "can I ship this SHA, and what is still unproven?" — the rendered evidence should answer it in under a minute, leading with anything `failed` or `waived`, then what was `skipped` and why, and collapsing the `proved` rows last.
- Make the GATE-02 artifact state its event class in the first screenful. The single most likely misreading six months out is treating a `workflow_dispatch` proof as a `pull_request` proof.
- The re-cut should read, in the evidence, as a deliberate correction with a stated cause — "the prior candidate predated its own gating verifiers" — not as an unexplained ref move.
- Row 1 of WINDOWS.md is a small, quotable lesson worth preserving in the disposition artifact: the recorded blocker had already been fixed, so a copied-forward description would have closed it on a false premise.

</specifics>

<deferred>
## Deferred Ideas

- Opening the integration pull request, the reviewer risk summary, rollback instructions, and Release Please readiness — Phase 232 (REL-04 / REL-05).
- Classifying and removing untracked files, stale worktrees, debug sessions, and remote maintenance branches (including `origin/phase-226-baseline-5da8e6b88735`) — Phase 232 (HYG-01). Note `.tool-versions` leaves this set in Phase 231 via D-08.
- Deleting local `main` — Phase 232 (HYG-01).
- Pinning `commit-search-depth` in the release-please workflow (~492 commits against a default of 500, almost no headroom) — Phase 232.
- Editorial polish of the 153-entry public CHANGELOG dominated by internal GSD/CI tooling commits — Phase 232, via `RELEASING.md`'s "human polish on the open release PR" clause.
- `.planning/v1.61-v1.61-MILESTONE-AUDIT.md`, an apparent double-prefixed duplicate — recorded by Phase 230, acted on in Phase 232.
- Renaming the two adopter-named refs (`fix/adopter-app-1.5.1` and its origin peer) — maintainer-decided as fail-forward; free only at a capsule mint.
- Package publication — outside v1.62 entirely.

</deferred>

---

*Phase: 231-exact-sha-release-gate-proof*
*Context gathered: 2026-09-15*
