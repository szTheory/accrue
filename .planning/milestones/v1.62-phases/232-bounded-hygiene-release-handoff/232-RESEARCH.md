# Phase 232: Bounded Hygiene & Release Handoff - Research

**Researched:** 2026-09-16
**Domain:** Repository hygiene classification, release-gate CI verifier hygiene, Release Please dry-run proof, integration PR handoff
**Confidence:** HIGH (all load-bearing claims re-measured live against this repository on 2026-09-16, after CONTEXT.md was gathered)

## Summary

This is not a domain-discovery research task — 232-CONTEXT.md's 61 decisions already fully specify the approach (triad shape, disposition schema, isMainModule design, REL-05 assertions, cleanup stopping rule). This document's job is to re-measure every D-00-bound fact per D-15's no-transcription rule, and it found **one load-bearing piece of decision drift**: the branch has moved 6 commits past the SHA CONTEXT.md recorded as HEAD, and one of those commits (`afff2018`/`9f309871`, quick-task `260916-hl9`) **already resolved D-42** — the exact sibling-dependency-operator question D-42 flagged as an open question. This is good news structurally (one less unknown) but it also **invalidates D-01's "zero co-touched files" framing**: because the D-42 fix touched `accrue_portal/mix.exs` on the milestone side, and the candidate branch also touches that same file (its own version bump), the re-cut now has exactly one genuinely co-touched file. Empirically, `git merge-tree --write-tree` still resolves it cleanly (exit 0, no conflict markers) because the two edits land on different lines — but D-07's blob-identity assertion ("identical to the side that changed it") cannot literally hold for this one path, since the correct merged result is byte-different from *both* parents (it must carry the candidate's `@version "1.5.1"` *and* the milestone's `~> ` operator). The planner must special-case exactly one file in the D-07 verification, not zero.

Every other measured fact was re-confirmed unchanged or found to differ only in ways requiring re-measurement at execution time (never a substantive contradiction of a locked decision): the 11 untracked `-uall` paths (D-48), the `.tool-versions` tracked-on-candidate/untracked-on-HEAD split (D-50), the 42 `scripts/ci/*.mjs` file count (D-27), the exact `ci.yml:226` `--fixtures` early-return bug (D-16), the job-level `continue-on-error: true` and unreachable "Ratchet status summary" step (D-23/D-24), and the `ANNOTATION_SWEEP_EXCLUDE` line (D-25) all reconfirmed exactly as CONTEXT.md describes. The `isMainModule`/`import.meta.main` portability claim (D-29/D-30) reconfirmed its *behavior* (both dominant guard idioms silently return `false` under a space-containing path) but its supporting evidence about *this machine's* Node version is stale — the machine now runs Node v24.19.0, not 22.14, and `import.meta.main` is defined and `true` here. This does not overturn D-29/D-30 (CI still pins a floating `'22'` tag, and other contributors' machines are unknown), but the planner should not cite "this machine has 22.14" as current fact.

**Primary recommendation:** Plan the re-cut task to (1) re-measure D-01/D-02/D-07/D-08 fresh at execution time rather than trusting CONTEXT.md's SHAs, (2) special-case `accrue_portal/mix.exs` in the blob-identity check as a legitimate content-union (not identical to either parent), (3) treat D-42 as CLOSED — do not re-litigate, just fold the already-shipped fix into the re-cut's file-scope accounting and verify `verify_release_manifest_alignment.sh`'s new `check_sibling_accrue_dep` assertion survives the re-cut, and (4) build the hygiene triad, isMainModule migration, and REL-05 dry-run proof exactly as D-45–D-61 specify — no further research is needed there, only execution-time re-measurement.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Candidate re-cut (merge origin/main + re-apply 2 commits) | Git/VCS layer | — | Pure ref/commit graph operation; no application code involved. |
| Blob-identity / losslessness proof | CI verifier script (`scripts/ci/verify_recut_candidate.mjs`) | Git/VCS layer | Verifier reads git objects directly; no runtime app tier involved. |
| Gate re-run (GATE-01/02/03) | CI / GitHub Actions | Local scratch-clone shell | Re-execution of Phase 231's own machinery, unchanged in shape. |
| Hygiene classification (HYG-01) | CI verifier script (new `hygiene_dispositions` triad) | Filesystem / git status | Enumerates repo state; verifier owns completeness/soundness invariants. |
| isMainModule guard migration | Node.js script layer (`scripts/ci/*.mjs`) | — | Pure Node module-boundary concern; no framework tier. |
| REL-05 dry-run proof | Release Please CLI (external tool) wrapped in a shell script | GitHub Actions (token-gated) | Reads config from the pushed branch, not the working tree — a process-boundary concern, not an app-tier one. |
| Integration PR body (REL-04) | GitHub (PR object) | — | Presentation/handoff artifact, not code. |

## Package Legitimacy Audit

Not applicable — this phase introduces no new external package dependencies. All work is either shell/Node scripting against the existing `scripts/ci/` toolchain or `release-please@17.6.0` (already pinned and in use per `.github/workflows/release-please.yml`).

## Decision Drift (re-measured 2026-09-16, after CONTEXT.md was gathered)

These are re-measurement findings, not proposals to relitigate any locked decision. Per the research-focus instructions, they are reported for the maintainer/planner's awareness; nothing here licenses a different approach than D-00–D-61 already specify.

### DRIFT-1 (load-bearing): D-01's "zero co-touched files" is now false — 1 co-touched file

- **Then (CONTEXT.md, 2026-09-16 morning):** merge base `8a3bdd60`, candidate `f524f2a6`, HEAD `8f58d91c`. Co-touched files: **0**. Merge-tree `2e4f621c`.
- **Now (re-measured):** HEAD has advanced 6 commits past `8f58d91c` to `d449d78335c467d509ab85490cba3c07cfe4cca9` (`git merge-base --is-ancestor 8f58d91c HEAD` → yes; `git rev-list --count 8f58d91c..HEAD` → 6). Those 6 commits are the quick-task `260916-hl9` (D-42's own resolution, see DRIFT-2) plus the phase-232 context-gathering commits themselves.
- **Effect:** `accrue_portal/mix.exs` is now touched by **both** sides vs merge-base `8a3bdd60`:
  - Candidate `f524f2a6` changed line 4 only (`@version "1.4.0"` → `"1.5.1"`), leaving `{:accrue, "== #{@version}"}` (line 79) untouched.
  - HEAD (via `afff2018`) changed line 79 only (`==` → `~>`), leaving `@version "1.4.0"` untouched (the candidate's version bump was never on HEAD's line, so HEAD's copy of the file is still the pre-bump `1.4.0`).
  - `comm -12` on the two file-diff lists (`8a3bdd60..f524f2a6` vs `8a3bdd60..HEAD`) confirms exactly one shared path: `accrue_portal/mix.exs`.
- **Verified non-blocking:** `git merge-tree --write-tree HEAD f524f2a6` still exits 0 (tree `907e319af6e0cf2acc0e9fcfec936515df403a82`, superseding the stale `2e4f621c`), because the two edits are on non-overlapping lines and git's 3-way merge auto-resolves them. Read the resulting blob directly: it correctly carries **both** `@version "1.5.1"` (from candidate) **and** `{:accrue, "~> #{@version}"}` (from HEAD) — a correct textual union, not a silent drop of either side.
- **Planning consequence:** D-07's per-path assertion ("blob in the new candidate is identical to the side that changed it") is **structurally unsatisfiable for this one path** by construction — the correct/expected content is identical to *neither* parent, it's a genuine union of both. The re-cut task must special-case `accrue_portal/mix.exs` (or generalize the check to: "for a co-touched path, the result must textually contain every hunk each side introduced, verified by line-level union rather than whole-blob identity") rather than trip a false-positive `DRIFTED` verdict. Re-measure the full changed-file set (candidate + HEAD, both now larger than the recorded 85-file boundary — candidate touches 46 paths, HEAD touches 47 paths vs the merge base, union 92, intersection 1) at plan/execution time; do not reuse the 85/0 figures.
- Also note: D-01's boundary claim ("HEAD touched only `.planning/` + `scripts/ci/` + `ci.yml`") is now stale too — HEAD also touches `CLAUDE.md` and `accrue_portal/mix.exs`, both outside that stated boundary, via the same D-42 fix commits.

### DRIFT-2 (informational, resolves D-42): the D-42 open question is now closed by an already-shipped commit

D-42 asked "which operator was meant — `==` (CLAUDE.md/accrue_portal) or `~>` (accrue_admin)?" and flagged it costly to resolve. **It is already resolved**, same day, by quick-task `260916-hl9` (commits `afff2018`, `2e55670a`, `9f309871`, `d449d783` — all already on the current branch HEAD, ancestors of any future re-cut that merges HEAD):

- `accrue_portal/mix.exs:79` now reads `{:accrue, "~> #{@version}"}` (was `==`).
- `accrue_admin/mix.exs:117` already read `{:accrue, "~> #{@version}"}` (unchanged).
- `CLAUDE.md`'s own tech-stack table now documents `~> <same version>` (was `== <same version>`) with an updated rationale citing `release-please`'s `linked-versions` lockstep.
- `scripts/ci/verify_release_manifest_alignment.sh` gained a new `check_sibling_accrue_dep()` function (45 new lines) asserting **exactly one** `{:accrue, "~> #{@version}"}` declaration in each of `accrue_admin/mix.exs` and `accrue_portal/mix.exs`, rejecting zero-match, multi-match, exact-pin, and hardcoded-literal-version shapes. The commit message documents two required negative controls that were run and passed (restoring the old exact-pin form; hardcoding a version literal) — this satisfies the Executable Acceptance Policy for that specific check.

**Planning consequence:** the Phase 232 plan must NOT re-open D-42 as a decision to make. Treat it as: (a) already shipped on the branch the re-cut will build from, (b) verify the new `check_sibling_accrue_dep` assertion survives the re-cut unchanged (it lives in `scripts/ci/verify_release_manifest_alignment.sh`, a HEAD-side-only file per DRIFT-1's file-scope, so it is not the co-touched path), and (c) note that the **`/Users/dev/projects/accrue/CLAUDE.md` shown to any agent via the system-prompt CLAUDE.md injection is itself now stale** relative to the repository's own `CLAUDE.md` on this branch — the injected copy still shows `== <same version>`. This is a meta-note for anyone planning/executing downstream, not a phase task.

### DRIFT-3 (informational, non-blocking): D-30's "this machine has 22.14" is stale; underlying decision unaffected

- **Then:** "this machine has 22.14 via asdf" — used as evidence that `import.meta.main` is `undefined` locally.
- **Now:** `node --version` → `v24.19.0` (`which node` → `/Users/dev/.asdf/shims/node`; the repo's own `.tool-versions` — tracked on the candidate branch, untracked on HEAD per D-50 — does not pin a `nodejs` entry, only `erlang`/`elixir`). Empirically probed via a script at a space-containing path:
  - `import.meta.main` → `true` (boolean), confirming Node 24.19 has the feature (matches D-30's own stated 24.2+ threshold).
  - Both dominant guard idioms **still fail exactly as D-28 describes**: `process.argv[1] === new URL(import.meta.url).pathname` → `false`, and `` import.meta.url === `file://${process.argv[1]}` `` → `false`, under `/tmp/space test dir/probe.mjs`. **D-28's core empirical claim is reconfirmed on this machine's current Node**, independent of the stale version number.
- **Planning consequence:** none for the decision itself (D-29/D-30 stand: build `scripts/ci/main_module.mjs`, do not use bare `import.meta.main`) — CI pins a floating `node-version: '22'` tag (7 occurrences in `.github/workflows/ci.yml`, lines 133/664/758/862/951/1062/1213) whose exact patch is not verified here, and other contributors' local Node versions are unknown, so the portability argument for a realpath-based helper over the built-in still holds. Just don't cite the specific stale "22.14 on this machine" fact in the plan.

### DRIFT-4 (informational): guard-idiom counts differ from D-28's rough figures; total-42 and 11-untracked hold exactly

Re-measured against the current 42-file `scripts/ci/*.mjs` set (file count **confirmed unchanged at 42**, matching D-27):

| Idiom | D-28's estimate | Re-measured now |
|---|---|---|
| `argv[1] === new URL(import.meta.url).pathname` | ~14 files | **11 files** |
| `` import.meta.url === `file://${argv[1]}` `` | ~5 files | **9 files** |
| String `isMainModule` already present | (not counted) | **1 file** |
| Neither idiom present (guard-less, or `NODE_TEST_CONTEXT`-only per 231-REVIEW.md IN-01) | (not counted) | **22 files** |

D-27's headline census (18 fail / 7 vacuous / 17 pass under `node --test`) was **not re-run in full this session** — a full 42-file `node --test` sweep is an execution-time verification step, not a research step, and several of these scripts have real side effects (git object writes, GitHub API calls) that make a blind re-run outside the planned task sequencing inadvisable. The planner should treat D-27's 18/7/17 split as the design target to re-verify at Wave/Task execution time via `scripts/ci/verify_ci_script_contract.mjs` (D-32) itself, not as a number to trust unmeasured. The 22-file "neither idiom" count is larger than a naive reading of "18 fail" might suggest a guard-migration scope to be — it includes `*.test.mjs` files (which correctly have no guard by design, per D-32's own carve-out: "imports `isMainModule` OR is a `*.test.mjs` file") and files already using `NODE_TEST_CONTEXT`-branching without any `isMainModule` call (231-REVIEW.md IN-01's exact finding, for `verify_window_dispositions.mjs` and `verify_gate01_cohort.mjs`). Size the D-29 migration plan to cover the **20 files using one of the two broken idioms** as the primary target, with the 22 "neither" files needing individual triage (some need the new guard, some are legitimately guard-free `*.test.mjs`).

### Reconfirmed unchanged (no drift — safe to plan against directly)

- **D-48 (11 untracked `-uall` paths):** re-measured via `git status --porcelain -uall`, exact same 11 paths: `.planning/milestone.lock`, 5 files under `.planning/phases/200-idempotent-verification-sign-off/`, `.planning/state.json`, `.planning/v1.61-v1.61-MILESTONE-AUDIT.md`, `.tool-versions`, `scripts/ci/stripe_test_fixtures.mjs`, `scripts/ci/verify_stripe_test_fixtures.mjs`.
- **D-50 (`.tool-versions` tracked-on-candidate / untracked-on-HEAD):** `git ls-tree f524f2a6 -- .tool-versions` → present (`100644 blob 89a1cd64...`); `git ls-tree HEAD -- .tool-versions` → empty. Exact match.
- **D-16 (`ci.yml:226` `--fixtures` early-return bug):** confirmed exact line — `.github/workflows/ci.yml:226` is `node scripts/ci/verify_window_dispositions.mjs --fixtures --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism`; no separate step anywhere in the file passes `--records`/`--rendered` against the committed `.planning/WINDOWS.md` pair.
- **D-23/D-24 (ratchet job structure):** `admin-ui-ratchet-guardrails` job starts at `ci.yml:931`; `continue-on-error: true` at job level is `ci.yml:945` (7 steps below the job header, above `steps:`); "Ratchet status summary" step spans `ci.yml:975-991`, unconditional (no `if: always()`), hardcodes 8 literal `| ... | PASS | PASS - ... |` table rows into `$GITHUB_STEP_SUMMARY`, and is preceded by 4 steps (`ratchet:ledger:verify-frozen`, `ratchet:signoff:self-test`, `ratchet:signoff`, `ratchet:ci-contract`) any of which can fail without `if: always()`, confirming it is currently unreachable dead code that will start emitting fabricated PASS lines the moment the gate ahead of it goes green.
- **D-25 (`ANNOTATION_SWEEP_EXCLUDE`):** exact line `ci.yml:1346`, current value `advisory,ratchet`.
- **D-27 (42-file count):** exact match, `ls scripts/ci/*.mjs | wc -l` → 42.
- **D-53 (single, clean worktree):** `git worktree list` → exactly one row (the repo itself at `d449d783`); confirms HYG-01's worktree clause stays vacuous.
- **D-49 (two Stripe fixture scripts present-but-untracked):** both `scripts/ci/stripe_test_fixtures.mjs` and `scripts/ci/verify_stripe_test_fixtures.mjs` exist on disk (appear in the 42-file `scripts/ci/*.mjs` glob) and are simultaneously untracked (appear in the `git status -uall` list) — confirms D-49's framing exactly.

## Standard Stack

No new external dependencies. This phase is exclusively:
- Node.js `.mjs` scripts (ESM, `node:test`, `node:util`'s `parseArgs` where used) under `scripts/ci/` — same runtime already used by all four existing triads.
- Bash (`verify_release_manifest_alignment.sh` and siblings) — POSIX-ish, already the house style.
- `release-please@17.6.0` CLI, invoked via `npx --yes` per `.github/workflows/release-please.yml` (D-41 confirms this is CLI-based, not `release-please-action`, so v4's output-naming gotcha does not apply).
- `gh` CLI for PR creation/inspection (already authenticated in this environment per Phase 231's `gh auth status` check).

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────┐
                         │  git graph: origin/main +    │
                         │  milestone HEAD (6 commits    │
                         │  past CONTEXT.md's recorded   │
                         │  8f58d91c, now d449d783)      │
                         └──────────────┬───────────────┘
                                        │ re-cut (merge + 2 cherry-picks,
                                        │ D-03; now 1 co-touched path,
                                        │ auto-resolved, DRIFT-1)
                                        ▼
                         ┌─────────────────────────────┐
                         │  new integration candidate    │
                         │  SHA (blob-identity proof,     │
                         │  D-07, with 1 union-path       │
                         │  carve-out)                    │
                         └──────────────┬───────────────┘
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
          ┌─────────────────┐ ┌─────────────────┐ ┌──────────────────┐
          │ Re-gate GATE-01/ │ │ HYG-01/02/03     │ │ REL-05 dry-run    │
          │ 02/03 at new SHA │ │ classify+cleanup │ │ proof (no write)  │
          │ (D-09..D-34)     │ │ (D-45..D-58)     │ │ (D-35..D-44)      │
          └────────┬─────────┘ └────────┬─────────┘ └─────────┬────────┘
                    └───────────────────┼───────────────────┘
                                        ▼
                         ┌─────────────────────────────┐
                         │  REL-04 integration PR        │
                         │  (risk summary + evidence +    │
                         │  rollback, D-59..D-61)         │
                         └─────────────────────────────┘
```

### Recommended Project Structure

No new directories. New files land in the existing flat `scripts/ci/` layout:

```
scripts/ci/
├── main_module.mjs                      # NEW — D-29's shared isMainModule() helper
├── collect_hygiene_dispositions.mjs     # NEW — D-45 triad
├── render_hygiene_dispositions.mjs      # NEW
├── verify_hygiene_dispositions.mjs      # NEW
├── verify_ci_script_contract.mjs        # NEW — D-32 meta-verifier
├── verify_release_pr_readiness.sh       # NEW — D-39, REL-05 proof
└── (42 existing files, ~20 gain an isMainModule import per DRIFT-4)
.planning/phases/232-bounded-hygiene-release-handoff/
├── 232-HYGIENE-DISPOSITIONS.json / .md   # NEW artifact (D-45)
├── 232-WINDOW-DISPOSITIONS.json / .md    # NEW artifact, own SHA (D-19)
├── 232-CLEANUP-FINDINGS.json             # NEW — D-58, one row per cleanup commit
└── 232-ROLLBACK-POINT.json               # re-cut rollback point (mirrors 231's shape)
```

### Pattern 1: `collect`/`render`/`verify` triad (D-45 — generalize from 4 existing precedents)

**What:** Three files per artifact family. `collect_*.mjs` gathers live facts into a sanitized JSON record (with an `evidence_command` field per repo convention). `render_*.mjs` deterministically projects the JSON into a Markdown file (`render(json) == committed .md`, byte-for-byte). `verify_*.mjs` re-collects, re-renders, and asserts (a) the committed JSON matches a fresh re-collect where the underlying facts are supposed to be stable, (b) the committed Markdown byte-equals a fresh render of the committed JSON, and (c) domain-specific completeness/soundness invariants.

**When to use:** Any new evidence artifact needing the same fail-closed, no-aggregate-boolean shape as GATE-01/02/03.

**Shared contract, extracted from all four existing precedents (`repository_inventory`, `integration_disposition`, `gate01_cohort`, `window_dispositions`):**

- **File naming:** `collect_<name>.mjs`, `render_<name>.mjs`, `verify_<name>.mjs` — always this order, always this prefix triple, one exported `main()`-equivalent function each plus a CLI entry guard.
- **Argv convention:** hand-rolled scanning is the dominant pattern (11 files use `--fixtures`, 10 use `--self-test` for the same self-test concept — a known, documented inconsistency; D-32's new meta-verifier and this phase's own triads should pick `--fixtures` to match the majority and the `ci.yml` calling convention already in use for GATE-01/02/03's triads). `--expected-repository <owner/repo>` is the sanitization/scope-check flag every verifier accepts (though `verify_recut_candidate.mjs`'s own copy is currently vacuous — WR-01 in 231-REVIEW.md — do not copy that specific bug). Strict-mode flags are individually named booleans (`--require-row-join`, `--require-waiver-completeness`, etc.), not a single `--strict`.
- **JSON schema shape:** top-level `{ schema_version, repository, captured_at (git commit %cI, never Date.now()), evidence_command (argv array), rows: [...] }`. Rows carry a closed enum field (here: `disposition` × `state`, matching the vocabulary D-45's discretion note locks: no new words, "parked" stays a CI-lane label never a schema value).
- **Output discipline:** every failure line is prefixed `<name>: FAIL: <reason>` (e.g. `verify_window_dispositions: FAIL: ...`) — keep this verbatim; it is the repo's one universal grep-able failure marker.
- **The `PASS (verified: ...)` / `PASS (schema-only: ...)` suffix:** the newest verifiers (introduced in Phase 231) print which strict flags actually ran, e.g. `PASS (verified: row-join, evidence-freshness, waiver-completeness, determinism)` vs a bare `PASS` when no strict flag was passed. This is the anti-vacuity affordance called out in 232-CONTEXT.md's `<code_context>` section — generalize it into the new hygiene triad and the `verify_ci_script_contract.mjs` meta-verifier so a reader can immediately see which invariants were actually checked versus schema-only.
- **CI wiring:** every triad's `--fixtures` self-test call is wired inside `docs-contracts-shift-left` as consecutive `node --test` + `node scripts/ci/verify_X.mjs --fixtures ...` lines in a single multi-line `run:` block (see `ci.yml:150-226` for the existing five-triad sequence). The committed-artifact (non-`--fixtures`) invocation is, per 231-REVIEW.md IN-03, **deliberately not** run recurringly for already-shipped triads (it would fail on any later planning-doc edit) — except D-16 explicitly calls for wiring exactly one real (non-`--fixtures`) run for the *window-dispositions* triad against the live `.planning/WINDOWS.md`, which is new work this phase must add, not an existing pattern to copy uncritically.
- **Self-tests:** `--fixtures` mode runs a battery of synthetic positive and negative-control records entirely in-memory (no repo I/O), asserting both that valid records pass and that specific malformed shapes are rejected with a specific message. This is what makes the CI step hermetic and fast.

### Pattern 2: Cross-field invariant enforcement (231-REVIEW.md CR-01 precedent — apply proactively in the new hygiene triad)

**What:** A `disposition`/`state`-shaped (or here, `disposition`/`authorization_required`-shaped) schema needs an explicit cross-field rule, not just per-field validation, or a row can claim an outcome its own recorded state contradicts.

**Why this matters for HYG-01 specifically:** D-47 already encodes exactly this discipline structurally for `remote_branch` rows (`disposition in {retained, superseded}` and `authorization_required: false` — the verifier literally cannot express "delete a remote branch"). Extend the same cross-field-invariant discipline to every other row `kind` the hygiene triad introduces (untracked file, stale worktree, debug session): e.g., a row with `disposition: authorized_for_removal` should require a recorded SHA-256 (per D-51's own practice for the phase-200 shadow) and a `superseded_by` or `duplicate_of` pointer, so `authorized_for_removal` cannot be asserted without evidence, mirroring 231-REVIEW.md CR-01's fix pattern (`fail()` on an unmapped/incomplete cross-field combination) rather than trusting per-field validation alone.

### Anti-Patterns to Avoid

- **Trusting a green Actions conclusion as provider proof** — forbidden repo-wide since Phase 226/D-29 (231-CONTEXT.md); does not change in 232.
- **A required CLI flag that is parsed but never compared against anything** — the exact WR-01 defect (`verify_recut_candidate.mjs --expected-repository`). Any new verifier this phase adds must wire every required flag into a real assertion, or drop the flag.
- **A vacuous completeness loop** — WR-02's pattern (looping over zero matching records and returning a silent pass). Every new completeness check must assert a non-zero count of items actually inspected before declaring pass.
- **Hardcoded PASS tables printed unconditionally** — the exact "Ratchet status summary" defect (D-24). Any new CI summary step must read real numbers from the artifact it is summarizing and use `if: always()` if it is meant to report on a possibly-failed prior step.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| isMainModule guard | A fifth bespoke idiom | `scripts/ci/main_module.mjs` (D-29), realpath-resolved file URL comparison | Both dominant existing idioms are empirically broken under a space in the path (reconfirmed this session); a sixth broken variant is strictly worse than consolidating to one correct, shared helper. |
| Ledger waiver machinery for the parked ratchet | A second waiver channel/schema | The existing `assertWaiverCompleteness` + row-join in `verify_window_dispositions.mjs` (D-22) | Already enforces owner/rationale/release-impact and drift; a parallel mechanism would fork the "what counts as waived" definition. |
| Release-readiness proof | A custom Release Please config parser | `release-please release-pr --dry-run` (D-39) | It already executes every real read path (commit walk, version-bump computation, changelog assembly) using the actual tool; a hand-rolled parser would re-implement release-please's own bump logic and drift from it. |
| WINDOWS.md status flips | Direct file edits | `gsd-tools windows waive <id> "<reason>"` / `windows fixed <id>` (231-CONTEXT.md D-25, still binding) | The ledger's canonical writer recomputes all four counts deterministically; hand-edits risk a stale/inconsistent count. |

**Key insight:** every "don't hand-roll" item in this phase is really the same insight restated: this repository already has four working instances of the triad pattern and a closed proof-state lexicon — the discipline is to extend, not reinvent, and to let existing verifiers (`assertWaiverCompleteness`, `exactMap`/`assertSameMultiset`) do the enforcement work rather than writing new bespoke logic that could diverge from the established invariants.

## Common Pitfalls

### Pitfall 1: Treating D-01's file-scope numbers as current

**What goes wrong:** A plan that hardcodes "85 files, 0 drifted" or "candidate touches only `accrue*/`+`examples/`+manifests" into a task's acceptance check will fail the moment it re-measures, because HEAD has already moved 6 commits and one of those commits crosses the stated boundary (touches `accrue_portal/mix.exs`, a source manifest, and `CLAUDE.md`).
**Why it happens:** CONTEXT.md's numbers were true when gathered, hours before this research; D-00 explicitly warns this rots, and it did.
**How to avoid:** Every task referencing a file count, co-touched-file count, or blob-identity assertion must re-derive the number from a live `git diff --name-only <merge-base> <side>` at execution time, per D-15. Do not copy DRIFT-1's numbers into the plan as new fixed constants either — re-measure again at plan/execution time, since the branch will keep moving.
**Warning signs:** A verifier assertion that hardcodes an integer (`85`, `0`) instead of comparing two live-computed sets.

### Pitfall 2: D-07's blob-identity check rejecting the one legitimately co-touched file

**What goes wrong:** If `verify_recut_candidate.mjs`'s blob-identity sweep is implemented as a blanket "for every changed path, blob must equal the side that changed it" with no carve-out, it will now **always** fail on `accrue_portal/mix.exs`, because the correct merged content is (by design) different from both parents.
**Why it happens:** D-07 was written when the union was genuinely disjoint (0 co-touched files); the underlying invariant it protects (no silent revert) still matters, but the mechanical check needs generalizing.
**How to avoid:** For the co-touched path, assert instead that every line-level hunk each side introduced (relative to the merge base) is present in the result — i.e., the specific two facts (`@version` bumped to `1.5.1`, operator is `~>`) both hold in the merged file — rather than requiring whole-blob equality to either parent. Treat this as a targeted, named exception (documented inline, with the specific path and reason), not a loosening of the check for every path.
**Warning signs:** `verify_recut_candidate.mjs --require-shape` failing with a `DRIFTED` verdict specifically and only for `accrue_portal/mix.exs` after an otherwise-correct re-cut.

### Pitfall 3: Re-litigating D-42

**What goes wrong:** A plan task titled something like "resolve the accrue sibling-dependency operator contradiction" duplicates work already shipped and verified (with two negative controls) in commits `afff2018`/`9f309871`/`2e55670a`/`d449d783`.
**Why it happens:** D-42 as written in CONTEXT.md still frames it as an open question ("needs maintainer confirmation... Resolve which was meant").
**How to avoid:** Confirm at plan time (as this research did) that the fix is already an ancestor of the branch the re-cut will build from; the only remaining task is verifying `check_sibling_accrue_dep` in `scripts/ci/verify_release_manifest_alignment.sh` survives the re-cut (it is HEAD-side-only, not on the co-touched path, so it should carry through the merge unchanged — verify this rather than assume it).
**Warning signs:** A plan task that proposes editing `accrue_portal/mix.exs:79` or `accrue_admin/mix.exs:117`'s operator, or CLAUDE.md's dependency table — all three are already correct.

### Pitfall 4: Sizing the isMainModule migration off D-27/D-28's rough estimates

**What goes wrong:** Estimating "14 + 5 = 19 files to migrate" (D-28's rough figures) undercounts; the actual current split is 11 + 9 = 20 files on the two broken idioms, plus a separate 22-file "neither idiom" bucket that needs individual triage (some are `*.test.mjs` files correctly exempt per D-32, some are the 231-REVIEW.md IN-01 `NODE_TEST_CONTEXT`-without-guard pattern that also needs a fix, just a different one).
**Why it happens:** D-27/D-28's counts were approximate ("~14", "5 files") at the time CONTEXT.md was written; exact counts drift as files are added/edited.
**How to avoid:** Re-run the grep census (`grep -l "new URL(import.meta.url).pathname" scripts/ci/*.mjs`, the `file://\${` variant, and a `comm` diff against the full file list) at plan time to size the migration task, and treat the two `NODE_TEST_CONTEXT`-without-`isMainModule` files (231-REVIEW.md IN-01) as a related but distinct fix within the same migration wave.
**Warning signs:** A plan that budgets exactly "19 file edits" for D-29's migration.

## Code Examples

### D-45's triad file-naming and argv template, generalized from `verify_window_dispositions.mjs`

```js
// Source: scripts/ci/verify_window_dispositions.mjs (existing, read this session)
// scripts/ci/verify_hygiene_dispositions.mjs should follow this exact shape:

import { isMainModule } from "./main_module.mjs"; // NEW shared helper, D-29

function main(argv) {
  const opts = parseArgs(argv); // hand-rolled or node:util parseArgs — pick one, document it
  if (opts.fixtures) {
    verifyFixtures(); // hermetic, in-memory positive + negative controls
    return;
  }
  const records = loadRecords(opts.records);
  const rendered = readFileSync(opts.rendered, "utf8");
  assertRenderDeterminism(records, rendered); // render(json) === committed .md, byte-equal
  if (opts.requireCompleteness) assertCompleteness(records); // D-46: re-enumerate live repo
  if (opts.requireSoundness) assertSoundness(records);       // D-46: no dangling row
  // ... print PASS (verified: completeness, soundness) or PASS (schema-only: ...)
}

if (isMainModule(import.meta.url)) {
  main(process.argv.slice(2));
}
```

### D-47's structural no-deletion invariant for remote branches

```js
// Source: 232-CONTEXT.md D-47 (already a locked decision; shown here as the concrete
// validation shape the collector must enforce, matching CR-01's cross-field-invariant fix)
function validateRemoteBranchRow(row) {
  if (!["retained", "superseded"].includes(row.disposition)) {
    fail(`remote_branch row ${row.name}: disposition must be "retained" or "superseded", got "${row.disposition}" — this verifier cannot express branch deletion`);
  }
  if (row.authorization_required !== false) {
    fail(`remote_branch row ${row.name}: authorization_required must be false — remote branch deletion is out of scope for this phase`);
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `argv[1] === new URL(import.meta.url).pathname` / `` import.meta.url === `file://${argv[1]}` `` guards | `isMainModule()` via `scripts/ci/main_module.mjs`, realpath-resolved | This phase (D-29) | Fixes a silent-no-op-under-spaces bug affecting a merge-blocking gate; empirically reconfirmed broken on Node v24.19.0 this session. |
| `{:accrue, "== #{@version}"}` in `accrue_portal/mix.exs` | `{:accrue, "~> #{@version}"}`, same as `accrue_admin`, asserted by `verify_release_manifest_alignment.sh` | Already shipped, same-day, quick-task `260916-hl9` (commits `afff2018`/`9f309871`) | D-42 closed before this phase's execution begins. |
| `.planning/phases/231-.../231-WINDOW-DISPOSITIONS.md` rendered by the pre-CR-01 renderer | Same JSON, re-rendered under the fixed bucketing renderer (D-13/D-14/D-20) | This phase | Presentation-only; the `.json` byte content is untouched (D-20). |

**Deprecated/outdated:** the two broken isMainModule idioms (11 + 9 = 20 current call sites) are being retired in favor of one shared helper; do not add a 21st or 10th instance of either broken idiom while this migration is in flight.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CI's floating `node-version: '22'` tag resolves to a patch ≥ 22.18 (where `import.meta.main` landed per D-30) is **not verified this session** — only this local machine's Node (24.19.0) was probed. | Decision Drift / DRIFT-3 | Low — does not change any task; D-29/D-30's `isMainModule` helper is used regardless of whether `import.meta.main` would also work in CI. |
| A2 | The full D-27 census (18 fail / 7 vacuous / 17 pass under `node --test`) was not re-run in full this session — only guard-idiom grep counts were re-measured (DRIFT-4). | Decision Drift / DRIFT-4 | Medium — if the actual pass/fail split has shifted materially since D-27 was measured, the planner's task sizing for D-31/D-32 could be off; mitigated by having the plan itself run `scripts/ci/verify_ci_script_contract.mjs`'s own census as an execution-time step rather than trusting a stale number. |
| A3 | The 22 "neither idiom" files were not individually triaged (`*.test.mjs` exemption vs `NODE_TEST_CONTEXT`-without-guard defect vs some other shape) — only the two `verify_window_dispositions.mjs`/`verify_gate01_cohort.mjs` instances were confirmed via 231-REVIEW.md IN-01. | Decision Drift / DRIFT-4 | Medium — undercounting the "neither idiom" triage work could under-budget D-31's per-vacuous-file real-test-registration task. |

## Open Questions

1. **Does the re-cut's blob-identity carve-out (Pitfall 2) need a new CLI flag, or a hardcoded single-path exception?**
   - What we know: exactly one path (`accrue_portal/mix.exs`) is currently co-touched; the correct content is a verifiable two-hunk union.
   - What's unclear: whether a future re-cut (if HEAD moves again before execution) could introduce additional co-touched paths, in which case a hardcoded single-path exception in `verify_recut_candidate.mjs` would be wrong.
   - Recommendation: implement the carve-out generically (assert every hunk from both sides is present, for any path found co-touched at execution time) rather than hardcoding `accrue_portal/mix.exs` by name — cheaper to build correctly once than to special-case now and re-litigate when HEAD moves again.

## Validation Architecture

`.planning/config.json`'s `workflow.nyquist_validation` was not found to be explicitly `false` (not checked directly this session, but no override was found in the repo's config, and CLAUDE.md's Executable Acceptance Policy binds regardless) — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node.js built-in `node:test` (`node --test`, `--test-reporter=tap` where child output is asserted per D-33) for JS/`.mjs` verifiers; Bash `set -e` scripts with explicit `fail()` calls for shell verifiers (`verify_release_manifest_alignment.sh` and siblings). |
| Config file | none — `node --test` auto-discovers `*.test.mjs` / files registering `test()` when `NODE_TEST_CONTEXT` is set; no `package.json` test runner config found for `scripts/ci/`. |
| Quick run command | `node --test --test-reporter=tap scripts/ci/verify_hygiene_dispositions.mjs` (per-file, ~1-5s) |
| Full suite command | The `docs-contracts-shift-left` job's full `run:` block in `.github/workflows/ci.yml` (all triads' `node --test` + `--fixtures` self-test invocations, currently lines ~150-226, growing with this phase's additions) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HYG-01 | Every untracked file / stale worktree / debug session / remote branch is classified with a completeness+soundness proof | unit + integration | `node scripts/ci/verify_hygiene_dispositions.mjs --require-completeness --require-soundness` | ❌ Wave 0 — new triad (D-45) |
| HYG-02 | GSD health, planning mirrors, generated artifacts, package metadata, changelogs, release docs agree with candidate; no release-blocking drift | integration | `scripts/ci/verify_release_manifest_alignment.sh` (existing, extended by D-42's fix already) + a new release-docs-truth check for `RELEASING.md`'s stale "Last verified" line | ⚠️ partial — manifest alignment exists; a "release docs are current" check does not yet exist, Wave 0 |
| HYG-03 | Cleanup limited to objective, command-backed findings; stops when only nits remain | integration | `node scripts/ci/verify_hygiene_dispositions.mjs --require-cleanup-findings-join` against `232-CLEANUP-FINDINGS.json` (D-58) | ❌ Wave 0 — new artifact + verifier assertion |
| REL-04 | Integration PR has risk summary, verification evidence, rollback instructions, no unrelated scope | manual-structural (PR body content) with an automated length/section-presence lint | `scripts/ci/verify_pr_body_contract.mjs` (new, optional — or a manual review-time check per D-59's density-over-length framing; PR body content itself is not unit-testable, but its presence of required sections can be) | ❌ new, optional |
| REL-05 | Release Please ready to produce a version-and-changelog-consistent PR, no merge/publish | integration (external CLI dry-run) | `scripts/ci/verify_release_pr_readiness.sh` (D-39) | ❌ Wave 0 — new script |

### Sampling Rate

- **Per task commit:** run the specific new/changed verifier(s) in `--fixtures` mode (hermetic, fast).
- **Per wave merge:** full `docs-contracts-shift-left` job locally via a scratch clone (mirrors GATE-01's own posture from Phase 231), plus a `workflow_dispatch` re-run once the re-cut SHA is pushed.
- **Phase gate:** `--fixtures` + one real (non-`--fixtures`) invocation of `verify_window_dispositions.mjs` against the committed `.planning/WINDOWS.md` (D-16's new wiring) before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `scripts/ci/main_module.mjs` + its own `node:test` self-test — foundational, everything else in this phase that touches an `.mjs` file depends on it existing first (D-29).
- [ ] `scripts/ci/collect_hygiene_dispositions.mjs` / `render_hygiene_dispositions.mjs` / `verify_hygiene_dispositions.mjs` — HYG-01/02/03's core artifact triad (D-45).
- [ ] `scripts/ci/verify_ci_script_contract.mjs` — D-32's meta-verifier, needed before the isMainModule migration can be proven complete (its own committed non-empty expected-file-count must be set correctly, currently 42 per this session's re-measurement, but re-verify at execution time).
- [ ] `scripts/ci/verify_release_pr_readiness.sh` — REL-05's entire proof surface (D-39); needs a `GITHUB_TOKEN`/PAT with repo scope and a pushed branch, confirm token availability before this task starts.
- [ ] `232-CLEANUP-FINDINGS.json` schema + its join-completeness assertion inside the hygiene verifier — HYG-03's fail-closed contract (D-58).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | This phase touches no auth code. |
| V3 Session Management | No | N/A |
| V4 Access Control | No | N/A |
| V5 Input Validation | Yes (narrow) | New verifier scripts parsing CLI argv and JSON records must reject malformed input the same way existing triads do (`fail()` with a specific message, never a silent default) — same discipline as D-46's fail-closed-both-directions requirement. |
| V6 Cryptography | No | N/A |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Secret/token leakage into a public PR body or committed artifact | Information Disclosure | Same sanitization discipline as D-31 (repo, this session confirmed 231-REVIEW.md IN-02's pattern-inconsistency between two existing sanitizers — do not introduce a third divergent pattern; reuse one of the two existing `UNSAFE_PATH_PATTERN`/`LEAK_RE` regexes verbatim, do not invent a new one). |
| A CI job silently downgrading a real failure to a fabricated pass (the "Ratchet status summary" class) | Tampering (of evidence) | D-24's fix — read real numbers, gate on `if: always()` only when intentionally summarizing a possibly-failed step, never hardcode outcome strings. |
| A required verifier flag that performs no check (WR-01 class) | Spoofing (of a safety property) | Every new required CLI flag in this phase's new scripts must be wired into a real comparison before being marked required; if nothing exists to compare it against, do not add the flag. |

## Sources

### Primary (HIGH confidence — read/executed this session)

- `git` object inspection (`cat-file`, `diff`, `merge-tree`, `rev-list`, `ls-tree`, `show`) against the live repository at HEAD `d449d78335c467d509ab85490cba3c07cfe4cca9` — DRIFT-1, DRIFT-2, D-48, D-50 reconfirmations.
- `.github/workflows/ci.yml` (1503 lines, read directly, grep'd for line anchors) — CI wiring reconfirmations (D-16, D-23, D-24, D-25).
- `scripts/ci/*.mjs` (42 files, `grep -l` census) — DRIFT-4 guard-idiom counts.
- Local Node.js runtime probe (`node --input-type=module -e ...`, a standalone `.mjs` file at a space-containing path) — DRIFT-3, D-28 reconfirmation.
- `.planning/phases/231-exact-sha-release-gate-proof/231-REVIEW.md` (read in full) — CR-01/WR-01/WR-02/WR-03/IN-01/IN-02/IN-03, informing Pattern 2 and the security-domain table.
- `.planning/phases/232-bounded-hygiene-release-handoff/232-CONTEXT.md` (read in full, D-00 through D-61) — the binding decision set this research verifies against, not re-litigates.
- `.planning/phases/231-exact-sha-release-gate-proof/231-CONTEXT.md` (read in full) — inherited D-15 no-transcription rule, D-22 fixed-or-waived discipline, deferred-list inheritance.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` (grep'd), `.planning/STATE.md` (tail read) — requirement text and session-continuity confirmation.
- `prompts/GSD-REPO-HYGIENE.md` (read in full) — standing hygiene policy, default deny-list.

### Secondary (MEDIUM confidence)

- CI's `node-version: '22'` pin (`grep -n` in `ci.yml`) — the exact resolved patch version was not queried against the live GitHub Actions runner image; treated as "floating, unverified exact patch" per Assumption A1.

### Tertiary (LOW confidence)

- None — every claim above is either directly read/executed this session or explicitly logged in the Assumptions table.

## Metadata

**Confidence breakdown:**
- Decision-drift findings (DRIFT-1..4): HIGH — every claim re-derived from a live git/CI/Node command executed this session.
- Reconfirmed-unchanged findings: HIGH — same standard.
- Triad/pattern generalization (Patterns 1-2, Code Examples): HIGH — derived from reading the actual existing triad source files this session (via the 231-REVIEW.md file list, which names and was cross-referenced against the same files) and CONTEXT.md's own already-locked decisions; no invention.
- D-27's full pass/fail census, and the 22-file "neither idiom" triage: MEDIUM — not fully re-run this session (Assumption A2/A3); flagged for execution-time re-verification via the phase's own new `verify_ci_script_contract.mjs`.

**Research date:** 2026-09-16
**Valid until:** This phase's own D-00 rule applies to this document too — every SHA and count above must be re-measured again at plan time and again at each task's execution time; treat "valid until" as **immediately**, not a 7/30-day window. The branch moved 6 commits during this research session alone.
