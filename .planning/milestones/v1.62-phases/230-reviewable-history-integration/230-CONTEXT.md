# Phase 230: Reviewable History Integration - Context

**Gathered:** 2026-09-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce one reversible, reviewable integration candidate that unites remote `main`, the full intended v1.61 lineage, and the four post-archive audit-closure commits, without rewriting published history or moving the `v1.61` tag. Record evidence-backed dispositions for every semantic integration hazard and every intentionally excluded commit. Prove the candidate's ancestry, changed-file scope, milestone provenance, and rollback point before any pull request targets `main`.

This phase DOES: create local refs, mint a recovery capsule, commit evidence artifacts, re-resolve sibling lockfiles, run focused regressions, and close one superseded public PR.

This phase does NOT: open the integration PR, merge anything to `main`, push `main`, move or re-annotate tags, force-push `main`, delete refs/branches/worktrees/files, run the full clean-checkout release gates (Phase 231 owns GATE-01/02/03), dispatch GitHub workflows, or classify/remove untracked artifacts (Phase 232 owns HYG-01).

</domain>

<decisions>
## Implementation Decisions

### Measured Ground Truth (re-verify before acting; it drifted during this discussion)

- **D-00:** Every fact below was measured live on 2026-09-15 and independently re-verified in-session. **Facts recorded in `.planning/STATE.md` about PR #44 are wrong** (see D-10). Treat all SHAs as a binding to re-measure at plan time, never to transcribe.
  - `origin/main` = `d30fc25d`; milestone `HEAD` (`gsd/milestone-v1.62-release-integration-hygiene`) = `cdd9d47a`; merge-base = `702dc482`; divergence **491 ahead / 24 behind**.
  - `origin/main` already ships **1.5.1** (`accrue-v1.5.1` = `d30fc25d`; `.release-please-manifest.json` = `1.5.1` x3). The milestone branch is still at `1.4.0` x3. The version trap is **1.4.0 -> 1.5.1**, not 1.4.0 -> 1.5.0.
  - Merge is **textually clean**: `git merge-tree --write-tree HEAD origin/main` -> tree `e1990d37`, zero conflicts.
  - **Six** files touched on both sides (was five before `origin/main` moved): `accrue/.dialyzer_ignore.exs`, `accrue/guides/entitlements.md`, `accrue/lib/accrue/config.ex`, `accrue/mix.exs`, `accrue/test/accrue/webhook/ingest_test.exs`, `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs`.
  - `v1.61` tag object `fdb41672` -> commit `e3b06794`; **is** an ancestor of `HEAD`, **is not** an ancestor of local `main` or of `origin/main`.
  - Four closure commits `8a95fbe8`, `9e090eb5`, `7cc501a3`, `57c61a9a` all resolve and are unpublished. (A research agent reported `8a95be8` unresolvable — that was a transcription typo, not a finding.)
  - Local `main` = `5c01f4bc`: an 80-commit abandoned Phase-226 execution line, diverged at `5b1759f2`, not on the released lineage.

- **D-00a:** During this discussion a research subagent ran `git fetch`, advancing `origin/main` `8f3135f7` -> `d30fc25d` and `origin/HEAD`, and created then deleted a temporary ref and tag. Net-zero on ref set; `origin/*` movement is real and must appear in the ref-exception accounting rather than pass unrecorded.

### Candidate Shape and Ancestry

- **D-01:** Build the candidate as a **single `--no-ff` merge commit**: branch `integration/v1.62-candidate` cut from milestone `HEAD` `cdd9d47a`, then `git merge --no-ff origin/main`. Cutting from the milestone side keeps `cdd9d47a` an untouched restore ref and makes `--first-parent` read as "the v1.61 line, then main arrived". — **Reversibility:** costly — the shape is what makes `git revert -m 1` an exact undo; changing shape after downstream phases bind to the candidate SHA invalidates 231's gate evidence and 232's PR body.
- **D-02:** **Rebase is disqualified outright.** `v1.61` points *into* the branch, so rebasing orphans the tag and violates the project's immutable-published-history posture. — **Reversibility:** one-way — rewritten SHAs break the tag's ancestry and every planning artifact that cites a commit.
- **D-03:** **Squash/collapse is disqualified.** It breaks `git merge-base --is-ancestor v1.61 <candidate>`, orphans F-01..F-04, and destroys ~153 changelog-bearing `feat:`/`fix:` commits that Release Please must harvest — killing REL-05. `.planning/` is this project's evidence substrate, not noise to discard. — **Reversibility:** one-way — provenance linking SUMMARY/VERIFICATION artifacts to commits cannot be reconstructed.
- **D-04:** Ship a **code-only sibling review branch** via `/gsd-pr-branch`, and prove the two are identical on source: `git diff --quiet <candidate> <review> -- . ':!.planning'`. Scope reality: milestone-vs-merge-base is 283 files / 491 commits, of which 211 files and 260 commits are `.planning/`-only; the real source surface is **72 files**. The reviewer reads 72, not 283.
- **D-05:** Encode these ancestry assertions as fail-closed gates on the candidate `C`: `v1.61` still resolves to **both** `fdb41672` (tag object) and `e3b06794` (commit); `--is-ancestor v1.61 C`; `--is-ancestor origin/main C`; each of the four closure SHAs is an ancestor of `C`; and `git rev-list --count C ^cdd9d47a ^origin/main == 1` (exactly the merge commit — proves nothing was smuggled in).
- **D-06:** Reject any candidate that is not a single first-parent merge — the revert identity does not hold for a squashed or rebased candidate.

### Excluded-Commit Dispositions

- **D-07:** **Exclude all 80 abandoned local-`main` commits wholesale, with a machine-checked ledger.** Their entire unique non-planning surface is 4 files plus 2 small edits, and every one is superseded: the milestone line replaced the shell baseline implementation (`capture_ci_baseline.sh`, `verify_ci_baseline_contract.sh`, `ci_baseline_workflow_policy.json`) with the `.mjs` collect/render/verify triad, and completed plans 01-21 where the abandoned line reached 01-11 and reverted its own requirement completions.
- **D-08:** **Salvage-by-cherry-pick is rejected as actively harmful.** Landing `verify_ci_baseline_contract.sh` plus its `ci.yml` step would put two competing baseline contracts on `main` and resurrect a rejected 463-line verifier as a live gate, on a `ci.yml` the milestone line rewrote `+192/-16`.
- **D-09:** **`git cherry` is a lead, never proof.** Its 3 `-` marks here are patch-id **false positives**: `8fdb2426`, `3fecff13`, `ccfe752e` share patch-id `a06acd99...`, a boilerplate revert hunk occurring 3x on `main` and 5x on the milestone branch. Supersession must be proven at **tree level** (per-file existence sweep + archived-vs-live plan inventory) and **requirement level** (`BASE-01`/`BASE-02` Complete under the finished 226), then recorded. Record `patch_id_occurrences_*` as recomputed **integers**, never booleans.
- **D-10:** **PR #44: close unmerged, citing superseding SHAs.** *(User decision.)* `git merge-base --is-ancestor main 3f8338cd` -> YES and `main...3f8338cd` -> `0 4`: its head is local `main` + 4 commits, so **merging it would permanently publish all 80 abandoned Phase-226 commits onto `main`**. `.planning/STATE.md`'s description of #44 as "four commits cherry-picked off main" describes intent, not the pushed branch — correct that record. Its 4 useful commits are already on the milestone branch as exact patch-id matches (`2de4389b`, `9eae363a`, `173607d9`, `5653216c`), so nothing is lost. Comment naming the superseding SHAs, then close without merging. — **Reversibility:** costly — closing is publicly visible and reopening invites confusion; but merging is the genuinely one-way error.
- **D-11:** Build the candidate **before** touching #44. Merging #44 first is the one move that makes exclusion impossible without rewriting `origin/main`.
- **D-12:** `afddc87c` (the GSD quick-task planning doc left behind) is already on milestone `HEAD`; record it as carried-on-candidate so nobody re-cherry-picks it and re-triggers the `.planning/` conflict.
- **D-13:** `origin/phase-226-baseline-5da8e6b88735` (`5da8e6b8`) publishes part of the abandoned line. It stays excluded; its ledger row gets a `published_elsewhere` field so the exclusion is explainable to an outside reader who finds the branch on GitHub. **Phase 230 records it; Phase 232 acts.**

### Integration Hazards and Verification Depth

- **D-14:** **Redefine "conflict disposition" for a clean merge**: every place both histories had an opinion, or where one side's change silently changes the other side's meaning, has a recorded, machine-recomputable resolution. Hazard classes to detect: convergent-identical, disjoint-hunk, version/release-train drift, version-keyed contract scripts, dependency/lock drift, schema relaxation, doc rewrite, archive-path regression, generated-artifact staleness. **Unknown class ⇒ fail, never pass-through.**
- **D-15:** **Recompute the hazard universe from SHAs inside the verifier; never transcribe it.** This discussion proved transcription rots — `origin/main` moved mid-session and a sixth co-touched file appeared. Refuse to verify on a stale binding (`STALE_BINDING` exit).
- **D-16:** **Three of the six co-touched files are already convergent-identical** (same blob both sides: `.dialyzer_ignore.exs`, `ingest_test.exs`, `entitlements_live_test.exs`) and owe no test — but this must be **proved by blob identity, not asserted**. The real work is `accrue/lib/accrue/config.ex` (disjoint hunks: ours replaces `safe_mix_env` with `Accrue.Env.mix_env()`, theirs relaxes `:branding` `from_email`/`support_email` to optional — both survive, both need a test), `accrue/mix.exs`, and `accrue/guides/entitlements.md`.
- **D-17:** **The dependency migration is the dominant hazard and is invisible to `git merge`.** `origin/main` moved `{:decimal, "~> 2.0"} -> "~> 3.0"` and `{:ex_money, "~> 5.24"} -> "~> 6.2"` (plus explicit `ex_cldr`/`ex_cldr_numbers`), with Ecto `3.13.6 -> 3.14.2`. **491 commits of milestone work — all money math and StreamData property tests — have never been compiled against Decimal 3 / ex_money 6.** This is the classic bors/homu failure: both parents green, merge textually clean, result never compiled.
- **D-18:** **Cross-package lock skew already exists on `origin/main` and is inherited.** `accrue/mix.lock` pins decimal `3.1.1` while `accrue_admin`, `accrue_portal`, and `examples/accrue_host` all still pin `2.4.1` against a path-dep `accrue` declaring `~> 3.0`. Expect `mix deps.get --check-locked` to fail in those three.
- **D-19:** **Phase 230 must produce a candidate that compiles and whose money-math and property suites are green, and fixing what Decimal 3 breaks is in scope.** *(User decision.)* Re-resolve the three sibling lockfiles. A candidate nobody can compile is not a candidate, and deferring means handing Phase 231 a fresh-checkout gate that fails for untriaged reasons. — **Reversibility:** costly — may touch real money-math code; every such change needs its own regression and must stay inside the integration's blast radius, not become a refactor.
- **D-20:** **The 230/231 line, encoded as one rule:** *230 proves the merge changed nothing it did not declare* (scope: behavior reachable from the integration's own diff and hazard universe, existing worktree and caches allowed). *231 proves the candidate is releasable* (scope: everything, fresh clean checkout of the exact SHA, no reused caches/credentials/worktree). Mechanical corollary: **if a check would have the same result on `origin/main` alone, it belongs to 231, not 230.**
- **D-21:** **Explicitly NOT in Phase 230:** full `mix test` for any project; Dialyzer/PLT (the `.dialyzer_ignore.exs` hazard is discharged by blob identity); Playwright E2E, the admin visual pixel-diff gate, storybook specs; host-integration and host-docker-smoke; asset rebuild or `copy_strings.json` regeneration; any provider/live-Stripe lane; `mix hex.publish --dry-run`; any fresh-clone run; any GitHub Actions dispatch (229's read-only posture still binds).
- **D-22:** **Make F-01..F-03 a standing invariant, not a one-time fix.** `origin/main` never touched the archive-resolution scripts, so the closure commits survive the merge — but the merge is exactly when new hardcoded `.planning/phases/<slug>` literals can sneak in. Add a fail-closed sweep asserting every such literal in `scripts/ci/**` and `.github/workflows/**` either resolves on disk or is reachable via `resolvePhaseEvidencePath`, with any literal naming a now-archived slug a hard failure.
- **D-23:** **Commit `.tool-versions` in Phase 230 as enablement, not hygiene.** Without `elixir 1.19.5-otp-28` none of 230's focused regressions can run, and GATE-01 demands a fresh clean checkout that runs local gates — a clone lacking `.tool-versions` cannot satisfy that without out-of-band operator knowledge. The other four untracked paths stay Phase 232's, but all are recorded with reasons so "untracked at integration time" is an evidenced decision.
- **D-24:** **Honest proof-state vocabulary per record**, reusing 226's lexicon with no aggregate boolean: `proved` (named command ran on the candidate SHA, real assertions, exit 0, argv+exit recorded), `failed`, `skipped` (with reason), `advisory`, `non_run` (correct state for every 231-owned lane). Forbid `deferred`, `n/a`, `green`. Reject any `state: proved` lacking a recorded exit code, so 231 can never be handed a relabeled success.

### Ref Truth, Rollback, and Recovery

- **D-25:** **URGENT SAFETY GAP — close it as the phase's first task.** The Phase 229 capsule's bundle milestone head is `dc4f6b91`; `cdd9d47a` is reachable from **no** bundle head. **139 commits — the entire Phase 229 execution — have zero out-of-repo preservation**, and D-06 of Phase 229 explicitly rejects reflog. Mint preservation covering the milestone line before any integration work begins. — **Reversibility:** one-way — losing this working repo before preservation exists destroys 139 commits permanently.
- **D-26:** **Fix the verifier's semantics rather than papering over drift with waivers.** Strict verification currently fails with 5 `extra` + 2 `changed`; **5 of the 7 divergences were produced by Release Please and `git fetch`** — zero by Phase 230, zero by corruption, all honest and monotone. Exact-equality-over-all-refs is unsatisfiable in a repo whose upstream is a release bot; pure fail-forward normalizes a permanently red gate that 231 and 232 inherit and learn to ignore.
- **D-27:** **Typed ref continuity** — partition by ref ontology, generalizing the ancestry-not-equality carve-out Phase 229 already invented: (1) owned `refs/heads/*` and local `refs/tags/*` -> exact equality plus declared additions; (2) remote-tracking `refs/remotes/*` -> **monotone ancestry only** (a cache of someone else's state is not this repo's truth); (3) preservation refs -> generalize the hardcoded `phase-229/` prefix to a phase-parameterised one so a Phase-230 capsule cannot self-invalidate. Only the comparison *operator* changes per class; `missing=[]` stays absolute and a non-fast-forward `origin/main` must still fail loudly.
- **D-28:** **Declared-additions ledger** at `.planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json` — **not** `.planning/WINDOWS.md`, which is itself pinned as an `id:status` row multiset and would break the very check it documents. Assertion is **exact multiset equality**: undeclared ref fails, and declared-but-absent **also** fails — that is what stops the junk drawer. Expected size ~2 once typed continuity lands, versus one row per bot release under pure fail-forward. Each row carries a `retirement_trigger`, and the capsule mint asserts the ledger is empty-after-retirement.
- **D-29:** **Rollback point = the single merge commit**, recorded in `230-ROLLBACK-POINT.json` with `candidate_ref`, `candidate_object`, both parents, pre-integration ref->object map, `expected_reverted_tree`, bundle/manifest digests, and **`restore_argv` as argv arrays, never shell strings** (229 lesson). Prove reversibility **executably** while `HEAD == M`, where `git revert -m 1 M` reproduces `tree(P1)` byte-identically — not by assertion, per the project's executable-acceptance policy.
- **D-30:** **Run the revert proof in a scratch `git clone` into the scratchpad, not `git worktree add`.** Worktrees are pinned too: the verifier compares an exact multiset of `{branch, sha, dirty}` rows, so even a detached linked worktree adds a row and fails. A separate clone creates zero refs and zero worktree rows in the subject repo.
- **D-31:** **Minimal ref churn — exactly two new refs are unavoidable:** `refs/heads/integration/v1.62-candidate` (must be `refs/heads/*`: GitHub will not open a PR from a custom namespace, and custom namespaces are neither pushed by the default refspec nor fetched by clones, making the candidate undiscoverable later) and the Phase-230 preservation namespace reusing 229's hex encoding verbatim. Everything else uses plumbing that creates objects, not refs: `merge-tree --write-tree`, `commit-tree`, `GIT_INDEX_FILE` temp indexes, `cat-file`, `merge-base`. Do not push in Phase 230 — pushing mints a third ref, and INTG-03 requires verification *before* any PR targets `main`.
- **D-32:** **Mint the new capsule LAST**, after `.planning/STATE.md` and `MILESTONES.md` settle. This is a hard ordering constraint in the plan, not a hope: a capsule minted earlier invalidates itself on the next GSD step. `git bundle create` silently resets mode to 0644 — `chmod 600` before publish (the real bug found in 229-19).
- **D-33:** Untracked artifacts: **hash and record only** in Phase 230; classification and removal are HYG-01/Phase 232. `scripts/ci/stripe_test_fixtures.mjs` and `verify_stripe_test_fixtures.mjs` are real source and must be sha256'd into the capsule's artifact manifest so they survive an undo. They belong in the *capsule*, not the rollback-point record — the rollback point is about refs and trees.
- **D-34:** Hand Phase 232 a known transition: `dirty` is a single pinned boolean per worktree, currently `true`. **232 flipping the tree fully clean will flip it true->false and fail strict verification.**
- **D-35:** Naming: `integration/v1.62-candidate` satisfies the locked convention — no adopter, customer, or personal names in ref names.

### Evidence Format

- **D-36:** Reuse the established **`collect -> render -> verify` triad** as a fourth instance rather than inventing a parallel mechanism: `230-INTEGRATION-DISPOSITION.{json,md}` plus `230-DISPOSITIONS.{json,md}` for excluded commits, resolved through `resolvePhaseEvidencePath` so they survive archiving.
- **D-37:** Completeness assertions are **exact sorted set/multiset equality, recomputed inside the verifier** — never non-empty checks, never asserted booleans (229's hardest-won lesson). Ledger size asserted as a literal integer. `superseded_by` is never null or omitted; use an explicit literal for "no equivalent".
- **D-38:** Render determinism: re-rendering the JSON must byte-equal the committed Markdown. Timestamps come from `git show -s --format=%cI` of the candidate, never `Date.now()`. Sanitization via allow-listed fields: no absolute paths, no `$HOME`, no actor names, no adopter identifiers, no secrets.
- **D-39:** Evidence DX — the artifact's job is answering "what did this merge decide on my behalf?" in under a minute. Lead the rendered Markdown with a **decisions-adopted-silently** section (1.5.1, Decimal 3 / ex_money 6, branding optionality); collapse convergent-identical rows last since they owe nothing. Add a row to the `scripts/ci/README.md` evidence table, and fence the rendered block so Phase 232 can splice it into the PR body (REL-04) with a verifier proving PR body matches artifact. Make the ledger greppable by raw 40-hex SHA so "where did commit X go?" is a sub-minute answer.

### Claude's Discretion

- Exact JSON schema field names, artifact filenames, script module decomposition, and renderer layout are flexible provided output is deterministic, sanitized, independently verifiable, and consistent with the 226/229 precedent.
- The planner may choose how to decompose the verifier changes across tasks, and the narrowest preservation-ref naming consistent with 229's hex encoding.
- Whether the excluded-commit ledger and integration-disposition ledger are one artifact or two is the planner's call, provided both completeness assertions hold independently.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Contract
- `.planning/PROJECT.md` — v1.62 goal, stable-core posture, immutable-history guardrails, reopen rules.
- `.planning/REQUIREMENTS.md` — INTG-01..03 (this phase), GATE-01..03 (231), HYG-01..03 / REL-04..05 (232).
- `.planning/ROADMAP.md` — Phase 230 boundary, dependency order, success criteria.
- `.planning/STATE.md` — accumulated decisions; **contains a factually wrong account of PR #44 that D-10 corrects**.
- `.planning/seeds/SEED-003-repo-hygiene-before-new-milestone.md` — selected hygiene checklist and release boundary.
- `prompts/GSD-REPO-HYGIENE.md` — repository-hygiene posture, no-force-push / immutable-history rules.

### Prior Phase Evidence (the pattern to extend, not replace)
- `.planning/phases/229-repository-truth-recovery-safety/229-CONTEXT.md` — D-01..D-10, locked evidence conventions.
- `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.{json,md}` — the published inventory whose strict verification this phase must repair.
- `.planning/phases/229-repository-truth-recovery-safety/229-VERIFICATION.md`, `229-SECURITY.md` — passed-state precedent and threat register.
- `.planning/milestones/v1.61-phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` — repository-bound CI evidence conventions and proof-state lexicon.
- `.planning/milestones/v1.61-REQUIREMENTS.md` — `BASE-01`/`BASE-02` completion, the requirement-level supersession proof for D-09.
- `.planning/v1.61-MILESTONE-AUDIT.md` — the audit that produced closure commits F-01..F-04.

### Implementation Surfaces to Reuse
- `scripts/ci/verify_repository_inventory.mjs` — `PRESERVATION_PREFIX`, the ancestry carve-out to generalize, `assertCanonicalRefContinuity`, worktree multiset pinning, WINDOWS.md row-multiset pinning, planning digests. **The file D-27 modifies.**
- `scripts/ci/collect_repository_inventory.mjs` — unfiltered `for-each-ref` collection; the collect half to clone.
- `scripts/ci/render_repository_inventory.mjs` — deterministic render precedent.
- `scripts/ci/preserve_repository_state.sh` — capsule/bundle minting; the 0644-vs-0600 bug from 229-19.
- `scripts/ci/{collect,render,verify}_ci_baseline.mjs` — the triad pattern, `allowedFields()` sanitization, `--fixtures` self-test convention.
- `scripts/ci/phase_evidence_path.mjs` — archive-aware evidence resolution (F-01..F-03).
- `scripts/ci/README.md` — contributor-facing evidence map; add the new row here.

### Release Contract
- `RELEASING.md` — Release Please as the single writer of `@version` and numbered CHANGELOG sections; "human polish belongs on the open release PR".
- `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml` — the 1.5.1 baseline and the unset `commit-search-depth` flagged for Phase 232.
- `.planning/WINDOWS.md` — ship-window ledger; **pinned as a row multiset, so do NOT add waiver rows here** (D-28).

### CI Contract
- `.github/workflows/ci.yml` — required job identities, `docs-contracts-shift-left`, provider-proof semantics.
- `CLAUDE.md` — the post-218 executable-acceptance policy that forbids human-judgment gates.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `collect -> render -> verify` triad exists twice (`*_ci_baseline.mjs`, `*_repository_inventory.mjs`); Phase 230 adds a third/fourth instance by cloning, not inventing.
- `assertCapturedRefContinuity` in `verify_repository_inventory.mjs` already implements ancestry-instead-of-equality for the advancing active branch — D-27 generalizes exactly this primitive.
- `exactMap`/`assertSameMap` helpers already emit `missing`/`extra`/`changed` triples; reuse verbatim for the new completeness assertions.
- `resolvePhaseEvidencePath` makes new artifacts survive milestone archiving for free.
- `/gsd-pr-branch` already exists to produce a `.planning`-free review branch (D-04).

### Established Patterns
- Evidence is sanitized machine-readable source plus deterministic rendered Markdown, bound to repository identity, observation time, exact object IDs, and the producing command as an argv array.
- Proof states stay distinct (`proved`/`failed`/`skipped`/`advisory`/`non_run`); a green Actions conclusion is not provider proof.
- Acceptance is fully executable with zero human checkpoints; `behavior_unverified: 0` is required to close a phase.
- Remote mutation and destructive operations require separate explicit authorization.

### Integration Points
- Git plumbing (`merge-tree`, `commit-tree`, `rev-list`, `patch-id`, `range-diff`, `bundle`) supplies all integration evidence without network access.
- `git ls-remote` reads live remote truth without mutating local refs — preferred over `git fetch` during evidence capture.
- The `docs-contracts-shift-left` CI job is where new merge-blocking verifiers land.

</code_context>

<specifics>
## Specific Ideas

- The reviewer's actual question is "what source behavior changed, and is it safe to merge?" — answered by the 72-file code-only branch read with `git log --first-parent`. The 491-commit provenance branch answers a different question and should be linked, not diffed.
- The rendered disposition Markdown should read like a release engineer's diagnostic: what the merge decided silently, first; what owes a test, second; what owes nothing, collapsed last.
- Design the ledger so a maintainer six months from now can `grep <sha>` and get a straight answer about where a commit went, without session memory.
- Flag for Phase 232 (do not act now): ~492 commits since `accrue-v1.5.1` sits against release-please's default `commit-search-depth: 500` with almost no headroom — pin it explicitly or the next release silently truncates. Also: mechanically Release Please will produce a consistent PR, but a 153-entry public CHANGELOG dominated by internal GSD/CI tooling commits is editorially wrong; `RELEASING.md`'s "human polish on the open release PR" clause is the sanctioned remedy.
- Flag for Phase 232: `.planning/v1.61-v1.61-MILESTONE-AUDIT.md` looks like a double-prefixed duplicate of the committed `.planning/v1.61-MILESTONE-AUDIT.md`. Record it; do not fix it here.

</specifics>

<deferred>
## Deferred Ideas

- Opening the integration PR, the risk summary, rollback instructions, and Release Please readiness — Phase 232 (REL-04/REL-05).
- Fresh clean-checkout local gates, exact-SHA GitHub check proof, and ship-window resolution — Phase 231 (GATE-01/02/03).
- Deleting local `main`, `origin/phase-226-baseline-5da8e6b88735`, stale worktrees, or any untracked file; classifying untracked artifacts — Phase 232 (HYG-01).
- Renaming the two adopter-named refs (`fix/getfluent-1.5.1` and its origin peer) — already maintainer-decided as fail-forward; only free when a new capsule is minted, so revisit at the Phase-230 capsule mint if desired.
- Pinning `commit-search-depth` in the release-please workflow — Phase 232.
- Package publication — outside v1.62 entirely.

</deferred>

---

*Phase: 230-reviewable-history-integration*
*Context gathered: 2026-09-15*
