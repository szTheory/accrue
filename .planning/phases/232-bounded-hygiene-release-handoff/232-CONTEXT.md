# Phase 232: Bounded Hygiene & Release Handoff - Context

**Gathered:** 2026-09-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce one release-ready integration handoff: re-cut a candidate that unions the two divergent v1.62 lines without losing the published 1.5.1 release state, re-gate it at its own SHA, classify every untracked file / worktree / debug session / ref before touching anything, make only command-backed cleanup, and open a reviewable integration PR with proof that Release Please is ready to produce a consistent release PR.

This phase DOES: re-cut `integration/v1.62-candidate`; prove the re-cut lossless by blob identity; re-run GATE-01/GATE-02/GATE-03 at the new SHA and drive the currently-failing jobs to fixed-or-waived; ship a `collect`/`render`/`verify` hygiene-disposition triad; commit the two missing Stripe fixture scripts; remove the degraded phase-200 shadow; open the integration PR; prove REL-05 by side-effect-free dry run.

This phase does NOT: delete any remote branch or tag; merge the integration PR; merge a Release Please PR; publish to Hex; rewrite published CHANGELOG sections; rewrite published history.

</domain>

<decisions>
## Implementation Decisions

### Measured ground truth (re-measure at plan time; never transcribe -- D-15 of Phase 230 still binds)

- **D-00:** Every fact below was measured live on 2026-09-16. Treat each as a binding to re-measure, not a value to copy. Phase 230 proved transcription rots.
- **D-01:** The two lines are content-disjoint. Merge base `8a3bdd60e3cddc603dce2562e90a78e61b841c3b`; candidate `f524f2a6b16d3576829632ab6fa77d24b718e6f7` touched only `accrue*/` + `examples/` + manifests, HEAD `8f58d91cd556c441dcfcbc03af3df4462d21196c` touched only `.planning/` + `scripts/ci/` + `ci.yml`. **Co-touched files: 0.** `git merge-tree --write-tree` exits 0 producing tree `2e4f621c2d38456990610cc44e1975f56acda944`, which carries `1.5.1` in the manifest and all three `mix.exs`. The re-cut is a clean union, not a risky reconciliation.
- **D-02:** `origin/main` (`d30fc25d`) IS an ancestor of the candidate and is NOT an ancestor of HEAD. HEAD's manifest reads **1.4.0**; the candidate's and main's read **1.5.1**. Re-cutting from HEAD alone would regress two published releases.

### The re-cut

- **D-03:** Re-cut by merging `origin/main` into the milestone tip (first parent = milestone line, second = `origin/main`), then re-applying the two declared 230-05 post-merge commits (`5ba9453e`, `f524f2a6`). This preserves the exact shape `231-ROLLBACK-POINT.json` records and that `verify_recut_candidate.mjs --require-shape` already enforces. — **Reversibility:** reversible — `git revert -m 1 <merge>`, the recorded `restore_argv`.
- **D-04:** Never rebase either line. `origin/integration/v1.62-candidate` is already published; rebasing rewrites public history, which Phase 230's goal statement forbids.
- **D-05:** Do NOT advance by merging HEAD onto the candidate branch — `verify_recut_candidate.mjs --require-shape` scenario 4 explicitly rejects a second merge point. Avoid the self-inflicted gate failure.
- **D-06:** Create local rollback refs BEFORE any ref write: `rollback/232-pre-recut-milestone` at `8f58d91c`, `rollback/232-pre-recut-candidate` at `f524f2a6`. Local only, never pushed.
- **D-07:** Prove losslessness by **blob identity, not diffstat**. For every path changed by either side against the merge base, assert the blob in the new candidate is identical to the side that changed it. Measured against the merge-tree result: **85 files, 0 drifted.** Must still print 0 after the re-cut. Diffstats, file counts and green tests all miss a silent revert; blob identity does not.
- **D-08:** Three corroborating fail-closed assertions: (a) `git merge-base --is-ancestor d30fc25d <new>`; (b) manifest + three `@version` all read `1.5.1`; (c) `git rev-list --count <new> ^8f58d91c ^d30fc25d` equals 3 (one merge + two cherry-picks), catching duplicate commits from an accidental rebase.

### Re-gating

- **D-09:** Re-run every gate at the NEW merge SHA. A green run on either parent proves nothing: the merged tree is the first tree in which Phase 231's CI wiring and Phase 231's scripts coexist. No prior run anywhere exercises that combination.
- **D-10:** The prior GATE-02 dispatch at the old candidate (run 35100620086) concluded `failure`. Those failing jobs are the real work of this phase, not the cleanup. A merge that only reduces the red count is not a pass; the stopping condition is every required job green or waived on the record.
- **D-11:** HEAD's `ci.yml` delta is +28 lines of steps inside an existing job with zero new job names, so the 231-04 required-job-set drift check stays valid unchanged.
- **D-12:** D-34 landmine: `verify_repository_inventory.mjs` pins `worktree dirty = true`. Cleanup flips it to `false` and fails strict verification unless the pinned authority is recaptured **in the same commit** as the cleanup. Sequence them together.

### Gate-signal honesty (CR-01 follow-through)

- **D-13:** Bucket the window-disposition renderer on the `(disposition, state)` **pair** via a total map, not an if-chain with fall-through. Six legal pairs, all reachable, `fail()` on an unmapped pair. The CR-01 dead-branch incident was caused by unreachability being recorded in a comment; comments do not fail CI.
- **D-14:** Add a cartesian-product test that derives legality by calling `validateWindowRow`, asserts every legal pair renders under exactly one declared bucket, and asserts no declared bucket is unreachable by any legal pair. This is the anti-dead-code assertion in both directions. Export `ROW_STATES` from the collector so the renderer can enumerate what it buckets on.
- **D-15:** Sub-split waived rows by their own state into three sections — `Waived — the gate ran and failed`, `Waived — the gate never proved anything`, `Waived — the gate passed anyway` — plus `Fixed — proved at the candidate SHA`. Headings name what happened, not a status word. **Maintainer decision, 2026-09-16.** Note `waived/proved` is legal today and is a real third case (a ledger/reality mismatch to reconcile), not a hypothetical.
- **D-16:** **The committed window-disposition artifact is currently verified by nothing.** `verify_window_dispositions.mjs:296` returns on `--fixtures` before reading `--records`/`--rendered`, and `--fixtures` is exactly what `ci.yml:226` passes. The documented committed-artifact invocation exists only as a README row. Wire a real CI step that runs the verifier against the committed pair. This is the highest-value fix in the area.
- **D-17:** That README command binds `--candidate integration/v1.62-candidate`, a mutable ref — the repo's own comment at `ci.yml:~207` says a CI step must not do this. Drop it or pin the literal SHA.
- **D-18:** `--require-row-join` applies only to the current phase's record (the join is against live `WINDOWS.md`). Historical records verify schema + determinism only. Document this next to both records or the next person "fixes" a false red by editing frozen evidence.
- **D-19:** Phase 232 mints its own `232-WINDOW-DISPOSITIONS.{json,md}` at the new SHA. It does NOT append new rows to 231's record — that would insert a fact discovered in 232 into 231's evidence at 231's SHA.
- **D-20:** Re-render `231-WINDOW-DISPOSITIONS.md` in place under the new renderer, in a presentation-only commit touching no `.json` byte, with a before/after tuple-equality proof quoted in the SUMMARY. Rationale: the `.json` is the evidence of record and the `.md` is a projection; freezing the `.md` while the renderer changes destroys `render(json) == md`, which is the artifact's only source of authority. Forward-only versioning would institutionalize permanent dead code. — **Reversibility:** reversible — presentation-only, and the JSON is untouched.

### The parked Admin UI ratchet

- **D-21:** The ratchet is failing **on the merits**, not un-run: `ledger.baseline.json` has `frozen: false`. Its honest state is `failed`, not `non_run`/`skipped`/`advisory`. Reserve `advisory` for lanes advisory by design.
- **D-22:** Record the disposition as one `waived` row in the EXISTING window-disposition machinery + one `WINDOWS.md` row. Do not invent a second waiver channel — `assertWaiverCompleteness` and the row-join already enforce owner/rationale/release-impact and prevent drift.
- **D-23:** `admin-ui-ratchet-guardrails` sets `continue-on-error: true` at **job** level, bundling three genuinely-passing self-test steps with the two parked ones. Split into a blocking `admin-ui-ratchet-selftests` job and a non-blocking `... [parked]` job. The machinery must stay gated even while its subject is parked.
- **D-24:** Delete the "Ratchet status summary" step at `ci.yml:~976-991`. It echoes nine hardcoded `| ... | PASS | PASS - ... |` lines into `$GITHUB_STEP_SUMMARY` unconditionally. It is currently unreachable (the failing step precedes it with no `if: always()`), which makes it exactly the dead-branch-that-lies pattern — it would start printing fabricated PASS lines the moment the gate ahead of it goes green. Replace with an `if: always()` step printing the real numbers read from the ledger.
- **D-25:** Key the annotation sweep exclusion on the disposition, not the subject: `ANNOTATION_SWEEP_EXCLUDE: advisory,ratchet` → `advisory,parked`, with `[parked]` carried in the job name. The sweep matches job-name fragments, so both edits must land in one commit. Un-parking then becomes a rename and the annotations re-arm automatically.
- **D-26:** Expiry is trigger-primary: the parked job fails **blockingly** if `ledger.baseline.json` flips to `frozen: true` while the waiver row still exists. An unexpected pass is a failure. That makes the existing `ci.yml` removal comment executable instead of aspirational.

### Node CI verifier hygiene

- **D-27:** Measured across all 42 `scripts/ci/*.mjs`: **18 fail** `node --test`, **7 pass vacuously** (zero real tests — the only TAP line is the file-level entry), 17 genuinely test. Two of the 18 are explainable (`verify_ui_ratchet_signoff.mjs` fails on the merits; `phase229_gap_closure.test.mjs` spawns children and exceeds a 60s timeout). The other 16 fail exactly as `verify_ci_baseline.mjs` does. This is a class, not an isolated INFO finding.
- **D-28:** The dominant guard idioms are **silently wrong**. `argv[1] === new URL(import.meta.url).pathname` (~14 files) and ``import.meta.url === `file://${argv[1]}` `` (5 files) both return **false** when the repo path contains a space — verified empirically. `main()` never runs, the script prints nothing and exits **0**. A merge-blocking gate becomes a silent no-op. This is the vacuous-gate class wired into the house style.
- **D-29:** Standardize on a shared `scripts/ci/main_module.mjs` exporting `isMainModule(import.meta.url)` that compares **realpath-resolved file URLs** and **throws** on empty `argv[1]` rather than returning a silent false. Correct under spaces, symlinks, relative argv and Windows paths on every Node >= 20.
- **D-30:** Do NOT use bare `import.meta.main`: it is `undefined` on Node 20.18 and 22.14 (this machine has 22.14 via asdf) and only landed in 24.2/22.18, so it would silently degrade to a falsy guard on a maintainer's machine. It is also unfactorable — inside a helper it describes the helper, not the caller.
- **D-31:** For the 7 vacuous files, register at least one real named test **in the same commit** as the guard. Several currently run their full CLI verification under `node --test` by accident; adding a guard alone would trade a loud accident for a quiet nothing. — **Reversibility:** reversible, but the ordering is load-bearing.
- **D-32:** Add `scripts/ci/verify_ci_script_contract.mjs` — a meta-verifier asserting, for every `scripts/ci/*.mjs`: exit 0 under `node --test --test-reporter=tap`, AND at least one TAP line whose name is not the file path itself (the non-vacuity assertion), AND that the file imports `isMainModule` or is a `*.test.mjs`. It must carry a committed non-empty expected file count so it cannot pass on a zero-match glob. Exit-code-only would rubber-stamp all 7 vacuous files today and every future one.
- **D-33:** Pass `--test-reporter=tap` explicitly wherever child `node --test` output is asserted. Node 22+ defaults to `spec`. This footgun already bit `phase229_gap_closure.test.mjs` once.
- **D-34:** The `ci_baseline` triad is a dated landmine: it is not yet wired into `ci.yml`, and two of its three files fail `node --test`. Anyone wiring it by pattern-matching a neighbouring triad turns CI red. Fix the guards before or with the wiring.

### Release Please (REL-05)

- **D-35:** The changelog-noise premise was wrong. `docs`/`style`/`chore`/`refactor`/`test`/`build`/`ci` are `hidden: true` by default and already filtered, and path-scoping filters more. A live `release-pr --dry-run` shows the next release is **14 bullets across three packages, 1.6.0 in lockstep** — not 153. The 153 is historical accumulation across 33 released sections. No emergency here.
- **D-36:** The `commit-search-depth` framing was also wrong. The bound is commits **since the last release** over GitHub's merge history, not total commits, because the walk breaks once every tracked package's release SHA is seen. Measured walk: **310**, against a default of 500 — 62% headroom, no truncation warning. Still pin `"commit-search-depth": 2000` top-level as a pure safety ceiling (the early break means raising it costs nothing in steady state). Leave `commit-batch-size` at its default — raising it is the known GraphQL-timeout trigger.
- **D-37:** Do NOT use `last-release-sha` or `bootstrap-sha`. The schema calls both uncommon and to be avoided; `bootstrap-sha` is inert once every package has a release, and `last-release-sha` is a static string needing a hand-edit after every release, which rots into the exact silent-wrong-changelog bug it was meant to prevent.
- **D-38:** Exceeding the depth fails **silently and wrongly in two ways**: `commitsAfterSha` returns every commit it saw when the release SHA is past the window, so the changelog balloons AND the version bump goes wrong (a pre-release `feat:`/`BREAKING CHANGE:` gets re-counted). Add a grep for `Expected N commits, only found M` to the readiness script — release-please only `logger.warn`s.
- **D-39:** Prove REL-05 with `release-please release-pr --dry-run` — it executes every read path, skips every write, and exits 0. Ship it as `scripts/ci/verify_release_pr_readiness.sh` asserting: exit 0; no truncation warning; `updates: 7`; all three packages present with the SAME version; that version > current manifest and stable semver; exactly three `updating module attribute version` lines. Archive the log as the REL-05 artifact. Satisfies the Executable Acceptance Policy (`human_judgment: false`). Note it still needs a token and a pushed branch — it reads config from the branch, not the working tree.
- **D-40:** `capture_linked_release_proof.sh` CANNOT satisfy REL-05: it asserts `hex.pm` already serves the version, so it is a post-publish proof by construction.
- **D-41:** CLAUDE.md's release-please v4 output-naming gotcha (`accrue--release_created`) is factually correct but **inapplicable** — this repo uses the CLI (`npx --yes release-please@17.6.0`) with hand-written `$GITHUB_OUTPUT`, not `release-please-action`. Do not "fix" output names.
- **D-42:** **CLAUDE.md contradicts the code.** It requires `:accrue` to be pinned `== <same version>`; `accrue_portal/mix.exs:79` uses `==` but `accrue_admin/mix.exs:117` uses `~>`, and nothing asserts either. Resolve which was meant and make `verify_release_manifest_alignment.sh` assert it. — **Reversibility:** costly — tightening to `==` changes the published dependency constraint for adopters.
- **D-43:** Add `"group-pull-request-title-pattern": "chore: release accrue-monorepo ${version}"`. A grouped PR title that cannot yield a version silently skips GitHub Release and tag creation (open upstream issues #2306/#2712); current titles carry no `${version}`. Latent, not yet biting.
- **D-44:** Keep `repair_linked_release_pr.sh` and every existing release guard. They mitigate open upstream silent-skip issues (#2558/#2707) where a member package is dropped with no error. Never flip `include-component-in-tag` to `false`; never set `changelog-type: "github"` (it ignores `hidden`).

### HYG-01 classification

- **D-45:** Ship the classification as a `collect`/`render`/`verify` triad matching the four existing precedents, not prose: `{collect,render,verify}_hygiene_dispositions.mjs` + `232-HYGIENE-DISPOSITIONS.{json,md}`, wired into `docs-and-bash-contracts-shift-left`.
- **D-46:** Fail closed in BOTH directions: **completeness** (re-enumerate the live repo at verify time; fail if any live item has no row) and **soundness** (fail if a row names something that no longer exists without a terminal disposition). Otherwise the artifact rots into fiction the moment cleanup runs.
- **D-47:** Encode the maintainer's no-deletion decision structurally: every `remote_branch` row must carry `disposition in {retained, superseded}` and `authorization_required: false`, so **the verifier cannot express "delete a remote branch."** Converts an intention into a machine-enforced invariant. **Maintainer decision, 2026-09-16: classify only, delete nothing.**
- **D-48:** There are **11** untracked paths under `-uall`, not 6. Reading `git status --porcelain` without `-uall` collapses a directory into one entry and hid five files.
- **D-49:** `scripts/ci/stripe_test_fixtures.mjs` and `scripts/ci/verify_stripe_test_fixtures.mjs` are **not orphaned work** — tracked `provider_proof_automation.mjs:13` names both in its scope allowlist and `ci.yml` invokes that script. The repo ships CI code referencing two files present in no tree. Disposition: **committed**, not removed.
- **D-50:** `.tool-versions` is **already tracked on the candidate** (committed by 230-05) and becomes tracked by the re-cut. This reverses the prior "never git-tracked" intent. Record the reversal explicitly rather than letting it flip silently. **Needs maintainer confirmation.**
- **D-51:** The five untracked files under `.planning/phases/200-idempotent-verification-sign-off/` are a **degraded shadow** of the committed `.planning/milestones/v1.54-phases/` archive — 2 byte-identical, 3 strictly worse (`passed` → `pending-after-report-generation`; artifacts `present` → `missing`). `phase_evidence_path.mjs:29` resolves the active path FIRST, so every local phase-200 verifier run reads the degraded copy while CI reads the good one. A live local-vs-CI truth divergence inside the release path. Disposition: `authorized_for_removal`, with SHA-256s recorded first.
- **D-52:** `.planning/v1.61-v1.61-MILESTONE-AUDIT.md` is **not a typo** — the `vX.Y-vX.Y-` double prefix is an established repo convention (v1.33..v1.46, v1.59 all exist that way). It is superseded on recency: the committed `.planning/v1.61-MILESTONE-AUDIT.md` (Sep 12) postdates this untracked copy (Aug 12).
- **D-53:** HYG-01's worktree clause is **vacuous** — there is exactly one worktree and it is the repo itself, clean. Say so in the artifact rather than leaving it blank.
- **D-54:** Flag `tampered-review` and `tampered-review-2` explicitly in the local-branch rows. They are negative-control test artifacts (`tamper: same file count, different content`), local-only and must stay local. "Same file count, different content" is precisely the silent-revert class D-07 defends against; someone will eventually wonder why they exist.

### HYG-03 scope discipline

- **D-55:** Operational test for objective-vs-subjective: **a finding is objective if and only if it can be stated as "`<named command>` currently exits non-zero; after this change it exits 0."** If you cannot name the command before making the change, it is a nit.
- **D-56:** Bound `comprehension` hard — it is the category that swallows cleanup passes and it has no command. It qualifies only when it is the direct cause of a failing doc-truth or contract check. "This would read better" never qualifies.
- **D-57:** Stopping rule, encoded in the plan: enumerate the command set up front (release path only); record every non-zero exit as a numbered finding; one commit per finding naming its command; on re-run, append new findings ONLY if caused by the fixes — newly-noticed pre-existing issues go to the backlog, not the PR; STOP when a full pass yields zero new command-backed findings; **hard cap 2 passes**, a third needs written maintainer authorization. Step 4 and the cap are the load-bearing clauses — "I noticed X while fixing Y" is the mechanism by which bounded passes become unbounded.
- **D-58:** Make it machine-checkable: commit `232-CLEANUP-FINDINGS.json` (command, before-exit, after-exit, commit SHA per finding) and have the hygiene verifier fail if any commit in the cleanup range has no finding row. Converts HYG-03 from a judgment rule into a fail-closed contract.

### REL-04 integration PR

- **D-59:** Target 50-80 lines, density over length. Lead with what a reviewer would reject the PR for, not with what went well. The failure mode to avoid is the wall-of-green-checkmarks body, which reviewers correctly learn to skim because it is unfalsifiable. Every claim carries a runnable command or a permalinked run.
- **D-60:** State the provenance/behavior split explicitly — `integration/v1.62-candidate` answers "how did this get here" (link it, do not diff it); `review/v1.62-candidate-code-only` answers "what source behavior changed" (diff it). Highest-leverage sentence in the body for reviewer time.
- **D-61:** Rollback is one command and it lives in the PR body, not in a linked runbook.

### Claude's Discretion

- Exact section ordering, microcopy, and table shapes within the rendered artifacts, provided the vocabulary stays `disposition` x `state` with no new words and "parked" remains a CI-lane presentation label, never a schema value.
- Whether the hygiene triad and the window-disposition triad share helper modules.
- Plan/wave decomposition.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone contracts
- `.planning/ROADMAP.md` — Phase 232 goal, success criteria, requirement mapping
- `.planning/REQUIREMENTS.md` — HYG-01/02/03, REL-04/05 text (lines 28-30, 34-35)
- `.planning/phases/231-exact-sha-release-gate-proof/231-CONTEXT.md` — D-15 no-transcription rule, D-22 fixed-or-waived discipline, the deferred list this phase inherits
- `.planning/phases/231-exact-sha-release-gate-proof/231-REVIEW.md` — open WARNING/INFO findings
- `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md` — sanctioned post-merge-commit pattern
- `.planning/WINDOWS.md` — ship-window ledger the disposition record joins against

### Release path
- `prompts/GSD-REPO-HYGIENE.md` — standing hygiene policy and default deny-list (no Hex publish, no Release Please merge, no tag push, delete stale release-please branches only when no open PR)
- `RELEASING.md` — release procedure; its "Last verified against ... 2026-06-01" line is stale and must be refreshed with any config change
- `release-please-config.json`, `.release-please-manifest.json` — all release-please config changes land here
- `.github/workflows/release-please.yml` — CLI-based, hand-written `$GITHUB_OUTPUT`; no action-naming risk
- `scripts/ci/verify_release_manifest_alignment.sh` — where the sibling dep-operator assertion belongs
- `scripts/ci/repair_linked_release_pr.sh` — keep; mitigates open upstream #2558/#2707

### Verifier machinery
- `scripts/ci/README.md` — documents no guard convention today; must document the `isMainModule` convention
- `scripts/ci/verify_recut_candidate.mjs` — line ~630 is the guard template to generalize; `--require-shape` constrains the re-cut
- `scripts/ci/phase_evidence_path.mjs` — line 29, active-path-first resolution (the phase-200 shadow bug)
- `scripts/ci/provider_proof_automation.mjs` — line 13, the allowlist naming the two missing Stripe fixture files
- `.github/workflows/ci.yml` — lines ~205-230 (triad wiring), ~930-1000 (ratchet job), ~1346 (annotation sweep exclusion)

### Project standing constraints
- `CLAUDE.md` — Executable Acceptance Policy, GSD Workflow Enforcement, security constraints; note D-41 and D-42 record where it is inapplicable or contradicts the code

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Four `collect`/`render`/`verify` triads (`repository_inventory`, `integration_disposition`, `gate01_cohort`, `window_dispositions`) — the hygiene triad copies this shape exactly.
- `assertWaiverCompleteness` + row-join in `verify_window_dispositions.mjs` — already enforces owner/rationale/release-impact; the parked ratchet reuses it rather than adding a mechanism.
- `verify_recut_candidate.mjs` strict flags (`--require-shape/-ancestry/-revert-proof/-toolchain/-supersession`) — re-run unchanged against the new candidate.
- `review/v1.62-candidate-code-only` byte-identity proof — the natural ancestor of D-07's blob sweep.

### Established Patterns
- Fail-closed evidence over prose; machine-checkable artifacts; JSON is authority, Markdown is a deterministic projection.
- `<name>: FAIL: <reason>` prefix discipline in verifier output — consistent and good, keep it.
- The newest verifiers print a suffix naming which strict flags actually ran (`PASS (verified: ...)` vs `PASS (schema-only: ...)`). This is the repo's best anti-vacuity affordance; generalize it.
- Convention drift to note: 11 files use `--fixtures`, 10 use `--self-test` for roughly the same thing, 21 have neither; `--help` exists essentially nowhere; argv parsing is split between hand-rolled scanning and `node:util parseArgs`.

### Integration Points
- `docs-and-bash-contracts-shift-left` — where the hygiene verifier and the committed-artifact determinism step get wired.
- `admin-ui-ratchet-guardrails` — split into blocking self-tests + non-blocking `[parked]`; changing job names may require updating branch-protection required-check names in the same change.

</code_context>

<specifics>
## Specific Ideas

- Section headings in the disposition report name what happened, not a status word: `Waived — the gate ran and failed` beats `Waived (maintainer must accept)`. A reader who has never seen the schema should understand every heading without a legend.
- Always render bucket headings even at zero rows. `## Waived — the gate ran and failed` / `0 row(s).` is a positive claim; an absent heading is ambiguous between "none" and "the renderer forgot".
- Put the standing answer in the artifact itself: `Projection of <file>.json (schema v1). The JSON is the evidence of record; this file is a deterministic re-render of it.` That pre-answers "did you edit evidence?" for every future reader.
- Render `evidence_command` — it is in the JSON and shown nowhere today. It is how a maintainer disbelieves the report, so it earns its place.

</specifics>

<deferred>
## Deferred Ideas

- Commitlint with a billing-domain `scope-enum` banning numeric/phase-ID scopes (`feat(231-06)` → `feat(webhooks)`), wired into the GSD commit contract. The real long-term changelog fix, but it is a new capability affecting every future commit — its own phase.
- A curated per-minor Highlights slot above the generated changelog ledger (the two-layer pattern every peer library uses). Per `RELEASING.md`, editorial polish lands on the open release PR, which is after this integration PR.
- Standardizing `--fixtures` vs `--self-test` onto one name, adding `--help` everywhere, and migrating hand-rolled argv to `parseArgs` with `strict: true`. Real DX debt and a live vacuity vector (a typo'd flag is silently ignored today), but broader than this phase.
- Renaming the two adopter-named refs (`fix/getfluent-1.5.1` and its origin peer) — maintainer-decided as fail-forward; free only at a capsule mint.
- Deleting local `main` and the remote branch deletions themselves — classification only this phase, per the maintainer decision.
- The orphaned `CapabilityReportTests.swift`, out of the SPM build graph since Phase 223-04.
- Remaining 231-REVIEW WARNING/INFO items not in scope: fail-open `--require-event-class`/`--require-exit-codes` on zero run-kind records; hand-maintained `OUT_OF_COHORT_LANES`; sanitization-regex inconsistency between two D-31 implementations.
- Package publication — outside v1.62 entirely.

</deferred>

---

*Phase: 232-Bounded Hygiene & Release Handoff*
*Context gathered: 2026-09-16*
