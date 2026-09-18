---
quick_id: 260917-l7v
title: Shift left seven phase-232 session failure modes into merge-blocking CI guards
type: execute
branch: gsd/milestone-v1.62-release-integration-hygiene
autonomous: true
human_judgment: false
revision: 2
requirements: [SL-A, SL-B, SL-C, SL-D, SL-E, SL-F, SL-G]
files_modified:
  - scripts/ci/verify_completion_evidence.mjs
  - scripts/ci/render_pr_claims.mjs
  - scripts/ci/verify_pr_claims.mjs
  - scripts/ci/verify_pr_body_contract.mjs
  - scripts/ci/verify_sensitive_token_census.mjs
  - scripts/ci/verify_pipefail_grep_idiom.mjs
  - scripts/ci/verify_pr_body_currency.mjs
  - scripts/ci/verify_artifact_fixed_point.mjs
  - scripts/ci/verify_ci_script_contract.mjs
  - .planning/hygiene/sensitive-token-census.json
  - .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json
  - .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md
  - .github/workflows/ci.yml
estimate:
  tokens: 245000
  raw_tokens: 122500
  tasks: 7
  confidence: low

must_haves:
  truths:
    - A requirement marked Complete with no passing verification and no UAT/SUMMARY citation of its ID fails the build, and the check is bidirectional (SL-E).
    - A committed PR claim is a typed record evaluated by a frozen evaluator table; no string from any committed file ever becomes a program name, a flag, or a shell word (SL-A).
    - A claim whose asserted value differs from the measured value fails the build; an unknown claim kind, a schema violation, an evaluator error, or a timeout fails the build and is never skipped (SL-A).
    - The committed markdown body is byte-exactly re-derivable from the typed claims sidecar; a bullet with no backing claim id, or a claim id absent from the body, fails the build (SL-A).
    - The gate asserts the repository declares no `pull_request_target` workflow, so the evaluator's blast radius cannot be widened silently (SL-A).
    - A claim ref field naming a bare local branch instead of an explicit `origin/` ref fails the build (SL-B).
    - The censused token may appear only under `.planning/`; any occurrence in shipped source, docs, workflows, changelogs, or anything reaching a package tarball fails the build, and the total count may only decrease (SL-C).
    - A newly written non-builtin-producer `grep -q` / `grep -v` pipeline under `set -euo pipefail` in scripts/ci fails the build with the capture-then-filter remediation (SL-D).
    - A committed PR-body file that declares a PR number and whose text differs from that PR's live body fails the build; an unavailable token fails the build rather than skipping it (SL-F).
    - A generated artifact that derives a field from an artifact which checksums it fails the build; regenerating a generated artifact is a no-op (SL-G).
    - Every new guard has at least one negative-control fixture that MUST fail, and prints a suffix naming exactly which checks ran and how many items were inspected.
  artifacts:
    - scripts/ci/verify_completion_evidence.mjs
    - scripts/ci/render_pr_claims.mjs
    - scripts/ci/verify_pr_claims.mjs
    - .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json
    - scripts/ci/verify_sensitive_token_census.mjs
    - .planning/hygiene/sensitive-token-census.json
    - scripts/ci/verify_pipefail_grep_idiom.mjs
    - scripts/ci/verify_pr_body_currency.mjs
    - scripts/ci/verify_artifact_fixed_point.mjs
  key_links:
    - Every new guard is a step in the merge-blocking `docs-contracts-shift-left` job in .github/workflows/ci.yml with no `continue-on-error`.
    - The hermetic Node guards run BEFORE the setup-beam and mix deps.get steps, so a cheap contract failure surfaces in seconds rather than after a toolchain install.
    - Every new scripts/ci/*.mjs file satisfies verify_ci_script_contract.mjs `--require-guard-coverage --require-non-vacuity` (which already runs `--repo .` against the live cohort).
    - The typed claims sidecar is the factual authority and the markdown body is its deterministic projection, restoring the convention stated at scripts/ci/README.md line 29.
---

<objective>
Seven failure modes observed for real during phase 232 become merge-blocking CI guards.

Purpose: the phase-232 session shipped three demonstrably false claims through a
falsifiability gate that measures SHAPE, not TRUTH; found a repo-wide name exposure by
accident rather than by its gate; hand-fixed the same pipefail/SIGPIPE idiom twice; marked
a requirement Complete eight hours before its deliverable existed; let a committed PR-body
file drift from the live PR twice; and burned real time on a UAT/VERIFICATION derivation
cycle whose only fixed point was a hand-written digest. Each is mechanically detectable.

Output: six new `scripts/ci/*.mjs` guards plus one renderer, one typed claims sidecar, one
census record, and seven new merge-blocking steps in `docs-contracts-shift-left`.
</objective>

<revision_note>

## What changed in revision 2, and why

Revision 1 proposed executing commands parsed out of markdown, inside a hardened sandbox.
**That decision is overturned.** Two independent reviews converged against it and the
repo-grounding was verified. The substance of the objection, recorded here so it is not
relitigated:

1. **The safety argument depended on a workflow property a maintainer can silently flip.**
   `.github/workflows/ci.yml` is `on: pull_request` (not `pull_request_target`) with
   `permissions: {actions: read, checks: read, contents: read}` on hosted runners. That
   makes today's exploitability moderate — checkout-persisted token, egress,
   Actions-cache poisoning as a fork→main pivot — not catastrophic. But it is one one-line
   edit from severe, and a design whose safety rests on a line someone else can change is
   the wrong design regardless of how well the sandbox is built.
2. **The prefix allowlist was not sound.** git accepts unambiguous long-option
   abbreviations; that is exactly how GHSA-2f96-g7mh-g2hx bypassed GitPython's hardened
   blocklist. Separately, a PR tree can ship `.gitattributes` / `.gitmodules` wiring
   `diff.external` or a textconv filter and obtain execution with no argument injection at
   all. Revision 1's `GIT_CONFIG_GLOBAL=/dev/null` did not close the in-tree vector.
3. **Decisive: this repo already has the right convention and one artifact broke it.**
   `scripts/ci/README.md` line 29 states it outright — the canonical JSON inventory is the
   factual authority; its Markdown is a deterministic projection. Six `collect_* →
   render_* → verify_*` triads follow it. `verify_pr_body_contract.mjs` is the single
   artifact that inverted it (markdown-first, no records file), and it is precisely the one
   that went vacuous. The fix is to restore the convention, not to harden the inversion.

**Rejected alternative, recorded so it is not re-proposed:** a purely static
`verified-by:` comment joined to CI step names. It is zero-execution and cheap, and it is
genuinely tempting. It is rejected because it fails the only test that matters here —
*would this design have caught the bug that motivated the work?* It would not. It proves a
covering CI step exists; it does not prove `-> 3` was false. The typed evaluator does.

Everything else from revision 1 survives. Ordering changed (SL-E promoted to first), SL-C's
invariant changed from per-path counts to a scope lock plus a monotonic ratchet, SL-D's
measurements were corrected, SL-F's token availability was corrected, and SL-G was added.

</revision_note>

<planner_judgment>

## Read this before executing: my judgment on all seven

**(E) Completion-mark evidence — SHIP FIRST.** Promoted to Task 1. Both reviews rated it
highest value-per-cost independently, and it is the guard addressing a failure that
demonstrably happened: `.planning/REQUIREMENTS.md` marked REL-04 `Complete` in commit
`32e4c1cf` roughly eight hours before PR #45 existed. Scoping stands: enforce the STATE
invariant checkable at branch tip, not a temporal one. Do NOT attempt a `git log -S`
timestamp check — CI only ever sees the tip, so a mark set early and backfilled in the same
PR legitimately passes, and pretending otherwise produces a gate that is wrong about its
own scope.

**(A) Typed claims sidecar — SHIP, reshaped.** The gate being replaced accepts any line
containing backticks; that is a punctuation check, not a falsifiability check. The
replacement makes the JSON sidecar the authority and the markdown a projection, so CI
evaluates *typed scalars through a frozen evaluator table* and never executes text. The
reviewer still sees a pasteable `` `git rev-list --count origin/main..X` -> `4` `` bullet,
because the renderer derives that string from the typed claim — humans keep the
expressiveness, CI never parses it back. The byte-exact re-render join is what makes the
two artifacts un-forgeable relative to each other, and it is the same `--require-row-join`
idiom `verify_window_dispositions.mjs` already uses.

**(B) Bare-local-ref ban — SHIP, now much cheaper.** Under the typed design this stops
being text analysis: `base`/`head` are typed ref fields, so the check is a validation rule
on a schema field. It is still the literal root cause of the `9`-vs-`4` error (a count
computed against local `main`, read by a reviewer against `origin/main`; a fresh clone
yields `4`), and it still gets its own flag, its own negative control, and its own commit.

**(C) Token census — SHIP, invariant corrected.** Revision 1's per-path count map was
wrong for this repo: `.planning/phases/NNN/` is archived into `.planning/milestones/` every
milestone, so per-path enforcement would fail on every archive move — a gate that goes red
on a routine, correct operation is a gate that gets deleted. The real shape of the
exposure, re-measured: **57 occurrences across 18 files**, all of them under `.planning/`,
**zero on `origin/main`**, **zero outside `.planning/`**. So the primary invariant is a
**scope lock** (shipped source, docs, workflows, changelogs, packaged files ⇒ hard FAIL)
with a **monotonic total ratchet** (may only decrease) as secondary. Maintainer decision
recorded: merge PR #45 as-is, do not scrub, mint the baseline at the merge commit.

**(D) pipefail/SIGPIPE idiom ban — SHIP, bespoke, and do NOT reach for shellcheck.**
Re-measured: **36** pipelines into `grep -q`/`-qv` under `scripts/ci`, of which **3** have
non-builtin producers. (Revision 1 said ~41/5; a parallel review said 0. Both were wrong;
36/3 is the measured figure and the plan states it.) Empirically confirmed on this machine:
**shellcheck 0.11.0 is installed and reports nothing on the exact pre-fix shape, even with
`--include=SC2337`** — the upstream rule is merged but unreleased. So a merge-blocking gate
here would require a digest-pinned master-build shellcheck container, which is a supply-
chain dependency taken on for a ~15-line check. Keep the bespoke guard. It remains a
*latent* hazard, not an active false PASS — both producers fixed this session emit far
under the 64 KiB pipe buffer (30 lines / 1527 bytes and 1 line / 69 bytes) — and the plan
must say so rather than overstate it.

**(F) PR-body drift — SHIP LAST, still the weakest of the seven, still droppable.**
Correction to revision 1: `secrets.GITHUB_TOKEN` **is** available on fork `pull_request`
runs — what forks lose is repository and organization secrets. So this needs only
`permissions: pull-requests: read`, no repo secret, and it blocks on forks like everyone
else. The remaining honest cost is unchanged and is the reason it is last: it will go
**transiently red for true reasons** (body committed, `gh pr edit` not yet run). That red
is correct but is the annoying kind that gets muted. Fail-closed on a missing token stays.
If the transient red is unacceptable, delete the task rather than soften it.

**(G) Artifact fixed-point — SHIP, new.** A real defect found while closing phase 232:
`232-UAT.md` derives its `started:`/`updated:` from the `verified:` field of
`232-VERIFICATION.md`, while `232-VERIFICATION.md`'s `covered_digest` covers `232-UAT.md`.
That is a derivation cycle — every verifier run bumps `verified:`, which rewrites the UAT,
which re-stales the digest, forever. The only fixed point today was a hand-written digest.
It cost real time and it is mechanically detectable.

**Cross-cutting, applies to EVERY task:**
- Use `git --no-optional-locks` in every guard shell-out. This repo has a known
  intermittent under concurrent git load, and porcelain commands that rewrite `.git/index`
  are the root cause.
- Prefer plumbing (`rev-list`, `rev-parse`, `cat-file`, `ls-files`, `grep -F`) over
  porcelain everywhere, not only in the SL-A evaluators.
- Retry ONLY on classified lock contention (`index.lock` / `Unable to create ... .lock`).
  Never blanket-retry: a blanket retry converts a real failure into a slow real failure.
- Place the cheap hermetic Node guards BEFORE the `setup-beam` and `mix deps.get` steps in
  `docs-contracts-shift-left`, so a stray bare `main..` fails in ~15s rather than ~90s.
- Every new `scripts/ci/*.mjs` MUST import `isMainModule` from `./main_module.mjs`, call it
  ONLY through a precomputed boolean assigned inside `try { ... } catch`, and register real
  `node:test` scenarios. `verify_ci_script_contract.mjs` already runs `--repo .
  --require-guard-coverage --require-non-vacuity` over the live cohort as a merge-blocking
  step; a file that skips any of those turns an existing gate red.

</planner_judgment>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@.planning/REQUIREMENTS.md
@scripts/ci/README.md
@scripts/ci/verify_pr_body_contract.mjs
@scripts/ci/verify_ci_script_contract.mjs
@scripts/ci/verify_window_dispositions.mjs
@scripts/ci/main_module.mjs
@.github/workflows/ci.yml
</context>

<interface_notes>
Read `scripts/ci/verify_pr_body_contract.mjs`, `scripts/ci/verify_ci_script_contract.mjs`,
and `scripts/ci/verify_window_dispositions.mjs` before writing any new file. Every new
guard copies their established shape exactly:

- `const fail = (m) => { throw new Error("<guard name>: FAIL: " + m); };`
- `export`ed assert functions, one per property, each independently testable.
- A single `verify*()` entrypoint that both the CLI and every scenario funnel through.
- `BOOLEAN_FLAGS` / `VALUE_OPTIONS` sets plus the `options(argv)` parser, which rejects
  unknown options, missing values, and duplicate values.
- A `--fixtures` mode running a `SCENARIOS` array of `[name, fn]` pairs; the SAME array is
  registered as named `node:test` cases when `NODE_TEST_CONTEXT` is set. `--fixtures` must
  return before any `--records` / `--body` value is read.
- The entrypoint tail: `let invokedAsEntrypoint = false; try { invokedAsEntrypoint =
  isMainModule(import.meta.url); } catch { invokedAsEntrypoint = false; }` then the
  `NODE_TEST_CONTEXT` branch, then `main()` in try/catch setting `process.exitCode = 1`.
- A PASS line naming exactly which strict checks ran and over how many items
  (`(verified: a, b; 34 items)`), and a distinct `(schema-only: ...)` suffix when no strict
  flag was supplied. Never print a bare `PASS`.

Every guard MUST fail when the inspected-item count is zero. That is the repo's anti-vacuity
convention and it is non-negotiable for gates whose whole purpose is to stop vacuous gates.

Shared git helper: every guard that shells out to git uses one local helper of the shape
`spawnSync("git", ["--no-optional-locks", "-C", repo, ...args], { shell: false, timeout,
maxBuffer, encoding: "utf8" })`, classifying an `index.lock` / `Unable to create ... .lock`
stderr as retryable (up to 3 attempts, short backoff) and treating every other non-zero
exit as a hard failure. Follow `verify_ci_script_contract.mjs`'s `git()` helper, adding
`--no-optional-locks` and the lock classification.
</interface_notes>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1 (SL-E): a requirement marked Complete must carry verification and coverage evidence</name>
  <files>scripts/ci/verify_completion_evidence.mjs, .github/workflows/ci.yml</files>
  <read_first>.planning/REQUIREMENTS.md (the `## v1.62 Requirements` checkbox list and the `| Requirement | Phase | Status |` traceability table), .planning/phases/232-bounded-hygiene-release-handoff/232-VERIFICATION.md (front-matter `status:` key), .planning/phases/232-bounded-hygiene-release-handoff/232-UAT.md, scripts/ci/verify_executable_uat_contract.mjs</read_first>
  <behavior>
    Negative controls (each MUST fail, each a named node:test scenario):
    - A fixture requirement marked Complete whose mapped phase has NO `*-VERIFICATION.md` fails, naming the requirement and the directory searched.
    - A fixture requirement marked Complete whose phase VERIFICATION.md carries any non-`passed` status fails, naming the observed status.
    - A fixture requirement marked Complete whose ID appears in NO UAT or SUMMARY artifact in its phase directory fails, naming the ID. This is the shape that would have caught the observed early mark: at that moment neither a passing verification nor a citing artifact existed.
    - BIDIRECTIONAL, direction 1: a `Complete` traceability row with NO corresponding requirement bullet fails, naming the orphaned row.
    - BIDIRECTIONAL, direction 2: a `- [x]` requirement bullet with NO `Complete` row fails, naming the orphaned bullet.
    - A `- [x]` bullet whose row says `Incomplete` fails, naming both sides.
    - NON-VACUITY: a requirements file whose traceability table header has been renamed or reshaped, so that ZERO Complete rows parse, fails loudly naming the parsed count — it does not pass silently.
    - A run over a requirements file with zero parsed requirements fails.
    Positive controls: a requirement marked Incomplete needs no evidence and passes; requirements under `## Future Requirements` are skipped with a printed count; the live `.planning/REQUIREMENTS.md` passes at its current state.
  </behavior>
  <action>
Create `scripts/ci/verify_completion_evidence.mjs`.

WHAT THIS CATCHES AND WHAT IT DOES NOT — write this into the header comment, because its
scope is easy to over-read. During phase 232, `.planning/REQUIREMENTS.md` marked REL-04
`Complete` in commit `32e4c1cf` (titled "docs(232-10): complete plan") roughly eight hours
BEFORE the deliverable it asserts (PR #45) existed. The tempting framing is "a completion
mark must not precede its deliverable" — but that is a TEMPORAL property and CI only
observes branch tip, so a mark set early and backfilled later in the same PR will
legitimately pass here. Do NOT attempt a `git log -S` archaeology check to recover it: it
would be slow, history-shape-dependent, and wrong after any rebase. What this gate enforces
is the STATE invariant ALSO violated at that moment and checkable at tip: a requirement
marked Complete must have passing verification and at least one artifact citing its ID.

PARSING. Read `--requirements` (default `.planning/REQUIREMENTS.md`). Extract two views:
  1. the checkbox list — `- [x] **REQ-ID**: ...` / `- [ ] **REQ-ID**: ...`;
  2. the traceability table — `| REQ-ID | Phase N | Status |`.
Cross-check them in BOTH directions and fail on any orphan or disagreement, naming which
side is missing. Skip requirements under `## Future Requirements` explicitly and print how
many were skipped, so the skip can never hide a whole-section opt-out.

EVIDENCE RESOLUTION. For each Complete requirement, resolve its phase directory by matching
the leading phase number against `.planning/phases/<number>-*`, falling back to
`.planning/milestones/*/` archives — an archived milestone's requirements must not become
unverifiable merely because the phase directory moved (this repo archives every milestone;
see SL-C for the same constraint). Then require BOTH:
  - a `*-VERIFICATION.md` in that directory whose front matter carries `status: passed`;
  - at least one occurrence of the requirement ID in a `*-UAT.md` or `*-SUMMARY.md` there.
Fail naming the requirement, which of the two is missing, and the directory searched.

ANTI-VACUITY. Fail when zero requirements parsed, when zero Complete rows parsed while the
table is non-empty, and when the phases directory is empty. PASS line names parsed,
complete, verified, and skipped-as-future counts.

FLAGS. `BOOLEAN_FLAGS`: `fixtures`, `require-completion-evidence`, `require-table-agreement`.
`VALUE_OPTIONS`: `repo`, `requirements`.

Build every fixture corpus in a temp directory (the established hermetic pattern); do NOT
mutate `.planning/` to produce a negative control.

WIRE IT: add a merge-blocking step "Completion-mark evidence (SL-E)" to
`docs-contracts-shift-left`, positioned BEFORE the `Set up BEAM` step (cross-cutting rule:
cheap hermetic Node guards run first). It runs the unit tests, then `--fixtures
--require-completion-evidence --require-table-agreement`, then `--repo .
--require-completion-evidence --require-table-agreement`. No `continue-on-error`.

Note that placing a Node step before `Set up BEAM` requires a `setup-node` action earlier in
the job than the existing "Set up BEAM for reference-scenario verification" step. Move the
existing `actions/setup-node@v6` step (currently near the tokens harness) to the top of the
job rather than adding a second one, and confirm the tokens-harness steps still resolve
their cache path afterward.

If the live run goes red on a requirement that is genuinely complete but whose evidence is
merely unindexed, FIX THE INDEX (cite the requirement ID in the phase's UAT or SUMMARY). Do
NOT add an allowlist — an allowlist here would recreate the exact "complete because we said
so" failure the gate exists to stop.
  </action>
  <verify>
    <automated>cd "$(git rev-parse --show-toplevel)" && node --test --test-reporter=tap scripts/ci/verify_completion_evidence.mjs && node scripts/ci/verify_completion_evidence.mjs --fixtures --require-completion-evidence --require-table-agreement</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" && node scripts/ci/verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; T=$(mktemp -d) &amp;&amp; mkdir -p "$T/.planning/phases/999-empty" &amp;&amp; printf '| Requirement | Phase | Status |\n|---|---|---|\n| ZZZ-01 | Phase 999 | Complete |\n' > "$T/.planning/REQUIREMENTS.md" &amp;&amp; ! node scripts/ci/verify_completion_evidence.mjs --repo "$T" --require-completion-evidence &amp;&amp; echo UNEVIDENCED_COMPLETE_FAILS_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; T=$(mktemp -d) &amp;&amp; mkdir -p "$T/.planning/phases/999-empty" &amp;&amp; printf '# R\n\n- [x] **ZZZ-01**: orphan bullet with no row\n\n| Requirement | Phase | Status |\n|---|---|---|\n' > "$T/.planning/REQUIREMENTS.md" &amp;&amp; ! node scripts/ci/verify_completion_evidence.mjs --repo "$T" --require-table-agreement &amp;&amp; echo ORPHAN_BULLET_FAILS_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; grep -v '^[[:space:]]*#' .github/workflows/ci.yml | grep -c 'verify_completion_evidence.mjs'</automated>
  </verify>
  <done>Complete-without-evidence fails; both orphan directions fail; a reshaped table that parses zero Complete rows fails loudly; future requirements are skipped with a printed count; the live requirements file passes; the step is merge-blocking and runs before setup-beam; no allowlist exists.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2 (SL-A): typed claims sidecar — JSON is the authority, markdown is a projection, CI never executes text</name>
  <files>scripts/ci/render_pr_claims.mjs, scripts/ci/verify_pr_claims.mjs, .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json, .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md, scripts/ci/verify_pr_body_contract.mjs, .github/workflows/ci.yml</files>
  <read_first>scripts/ci/README.md line 29 (the convention this restores), scripts/ci/verify_window_dispositions.mjs (the `--require-row-join` idiom and the render/verify join), scripts/ci/render_window_dispositions.mjs, scripts/ci/verify_pr_body_contract.mjs (its `hasEvidence`/`assertFalsifiability` pair at lines ~112-133 is the defect being retired)</read_first>
  <behavior>
    Negative controls (each MUST fail, each a named node:test scenario):
    - A claim with an unknown `kind` fails, naming the kind and listing the frozen table's keys. It is never skipped.
    - A claim violating its kind's argument schema fails before any evaluator runs.
    - A claim whose measured value differs from `expected` fails, printing both. Use a `merge_count` claim asserting `3` against a fixture repo that really yields `4`, reproducing the observed error exactly.
    - An argument value matching `/^-/` fails at validation, before any argv is built.
    - A ref value containing `..`, `@{`, a space, or a leading `-` fails validation.
    - A SHA value not matching `^[0-9a-f]{7,40}$` fails validation.
    - An evaluator exceeding its timeout fails; an evaluator whose output exceeds the bounded buffer fails. Neither is truncated into a pass.
    - RE-RENDER JOIN: a committed markdown body whose text differs by one byte from the renderer's output fails, naming the first differing line.
    - A markdown bullet carrying a claim id that is absent from the JSON fails.
    - A JSON claim id that is absent from the markdown fails.
    - A sidecar with zero claims fails the `--min-executed` floor, naming the floor.
    - An `attested` claim past its `expires_on` fails, naming the expiry date and owner.
    - A third `attested` claim fails the hard cap of 2; attested claims exceeding 20% of total claims fails.
    - A repository declaring a `pull_request_target` workflow fails `--require-no-pull-request-target`.
    Positive control: a conforming sidecar of several kinds, whose measured values all match and whose rendered markdown matches the committed body byte-for-byte, passes every strict flag at once and prints the evaluated claim count.
  </behavior>
  <action>
Create the pair `scripts/ci/render_pr_claims.mjs` and `scripts/ci/verify_pr_claims.mjs`,
plus the typed sidecar
`.planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json`.

WHY A PAIR, NOT A TRIAD — state this in both header comments so nobody later "completes"
the triad. The six existing `collect_* → render_* → verify_*` triads collect facts FROM the
repository into a records file. Here the records file is AUTHORED: the claims are what a
human asserts, and the measurement happens inside the verifier's evaluators. So there is no
`collect_` stage, and adding an empty one would be cargo-culting the shape without the
substance.

SIDECAR SCHEMA. `{ "schema": 1, "repository": "<owner/repo>", "claims": [ ... ] }`. Each
claim: `{ "id": "C1", "kind": "<frozen key>", "text": "<prose the reviewer reads>",
"expected": <typed scalar>, ...typed arguments }`. Example:
`{ "id": "C1", "kind": "merge_count", "base": "origin/main",
"head": "integration/v1.62-candidate-recut", "expected": 4,
"text": "The candidate reaches main through ..." }`.

FROZEN EVALUATOR TABLE. Export `EVALUATORS` as a frozen object keyed by `kind`. Each entry
carries `{ args: <schema>, evaluate(repo, claim), renderCommand(claim) }`. Seed with exactly
six kinds and no more: `merge_count`, `commit_reachable`, `path_exists`, `file_sha256`,
`fixed_string_count`, `tracked_path_count`. **No kind may perform network I/O** — a claim
about a CI run conclusion must be a LINK in the body, not an assertion; write that rule
into the header comment, because it is the boundary that keeps the evaluator table
auditable.

THE RULE THAT DEFINES THIS DESIGN: **no string from any committed file ever becomes a
program name, a flag, or a shell word.** Program name and flags come from the frozen table
only. Committed values are typed scalars, schema-validated before use, and passed as
positional operands after a literal `--`. Write that sentence into the header comment
verbatim; it is the invariant a future reviewer checks the file against.

ARGUMENT VALIDATION (before any argv is constructed):
  - reject any value matching `/^-/` outright;
  - SHA: `^[0-9a-f]{7,40}$`;
  - ref: `^[A-Za-z0-9._/-]{1,120}$`, additionally rejecting `..`, `@{`, and a leading `-`;
  - path: repo-relative, no leading `/`, no `..` segment;
  - integers: `Number.isSafeInteger` and non-negative.

EVALUATOR EXECUTION HARDENING (these still shell out to git, so keep revision 1's
hardening and add the in-tree-config closures the review identified):
  - `execFile` with an argv ARRAY; never a shell; values only after a literal `--`.
  - PLUMBING ONLY: `rev-list --count`, `rev-parse --verify`, `cat-file`, `ls-files`,
    `grep -F`. NEVER `diff`, `log -p`, or `show` — those are the commands that honor
    `diff.external` and textconv.
  - Force, on every invocation: `--no-optional-locks`, `-c core.attributesFile=/dev/null`,
    `-c core.hooksPath=/dev/null`, `-c protocol.ext.allow=never`. The first two close the
    in-tree `.gitattributes` / hooks vector that a scrubbed HOME did not.
  - Replaced (not inherited) env: `{ PATH, LANG: "C", LC_ALL: "C",
    GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_SYSTEM: "/dev/null",
    GIT_TERMINAL_PROMPT: "0", GIT_ASKPASS: "", GIT_ALLOW_PROTOCOL: "" }`.
  - `timeout` 10s (override via `--timeout-ms`, capped 60s); `maxBuffer` 1 MB. Exceeding
    either is a FAILURE, never a truncated comparison.
  - Non-zero exit is a claim FAILURE; print stderr truncated to 400 chars, matching the
    existing `git()` helper convention.

RENDERER. `render_pr_claims.mjs` reads the sidecar and emits the markdown body
deterministically. For each claim it emits the prose `text`, the claim id, AND a
human-runnable command string produced by that kind's `renderCommand(claim)` — so the
reviewer still sees and can paste `` `git rev-list --count origin/main..integration/…` ->
`4` ``. That string is OUTPUT ONLY. Nothing ever parses it back; say so in a comment
directly above `renderCommand`, because that is the line a future maintainer is most likely
to undo.

VERIFIER JOIN. `verify_pr_claims.mjs --require-render-join` re-renders from the JSON and
requires the committed markdown to match **byte-exactly**, failing with the first differing
line number. Additionally: every rendered bullet must carry a claim id present in the JSON,
and every JSON claim id must appear in the body. This mutual join is what makes the two
artifacts un-forgeable relative to each other; it is the same property
`verify_window_dispositions.mjs --require-row-join` already enforces.

FAIL-CLOSED SET (unchanged from revision 1, extended): unknown `kind`, schema violation,
argument-validation failure, evaluator error, evaluator timeout, measured-vs-expected
mismatch, re-render mismatch, a rendered bullet with no backing claim id, a claim id absent
from the body, or a sidecar below the `--min-executed` floor ⇒ FAIL. Never skip, never warn.

WAIVER PRESSURE-VALVE. Reuse this repo's expiring-waiver idiom rather than inventing one: a
`kind: "attested"` claim requiring `{ reason, owner, expires_on, approving_sha }`. FAIL when
past `expires_on`. Hard cap: at most 2 attested claims AND at most 20% of total claims,
whichever is stricter. Both caps get their own negative control.

KEEP `--require-no-pull-request-target`: read every file under `.github/workflows/` and fail
if any declares a `pull_request_target:` trigger. Under the typed design this is no longer
load-bearing for safety, but it is retained deliberately as an interlock — it goes red
BEFORE the blast radius changes rather than after. Say exactly that in the comment so it is
not later deleted as redundant. Fail if zero workflow files were inspected.

RETIRE THE DEFECT. In `scripts/ci/verify_pr_body_contract.mjs`, delete `hasEvidence` and
`assertFalsifiability` and its scenario, replacing them with a header note pointing at
`verify_pr_claims.mjs` and recording WHY: a regex for backticks measures punctuation, not
truth, and three false claims shipped through it. Leave that file's remaining SHAPE checks
(risk-first heading, required headings, provenance sentence, inline rollback command,
density band, leak sweep, expected-repository) exactly as they are — those are sound, and
they are a different concern from claim truth.

BACKFILL THE SIDECAR. Author `232-INTEGRATION-PR.json` from the existing committed body,
then regenerate the body from it. Expect real corrections: the body contains claims whose
asserted values are now false — that is the finding that motivated this work. Correct each
claim to its true measured value; if a claim was true only against a stale local ref,
restate it in `origin/`-explicit terms and re-measure. NEVER delete a claim to make the gate
green, and never edit the historical record to assert something the evaluator did not
measure.

WIRE IT: a merge-blocking step "PR claims contract (SL-A)" in `docs-contracts-shift-left`,
placed with the other cheap Node guards BEFORE `Set up BEAM`. It runs `node --test` on both
new files, then `verify_pr_claims.mjs --fixtures --require-claims --require-render-join
--require-no-pull-request-target`, then the real invocation with `--repo . --claims
<json> --body <md> --expected-repository szTheory/accrue --require-claims
--require-render-join --require-no-pull-request-target --min-executed 1`. No
`continue-on-error`.

The job's `actions/checkout@v6` uses the default shallow fetch. If any `merge_count` or
`commit_reachable` claim needs real history, add `fetch-depth: 0` to that job's checkout
rather than weakening the claim.
  </action>
  <verify>
    <automated>cd "$(git rev-parse --show-toplevel)" && node --test --test-reporter=tap scripts/ci/render_pr_claims.mjs && node --test --test-reporter=tap scripts/ci/verify_pr_claims.mjs && node scripts/ci/verify_pr_claims.mjs --fixtures --require-claims --require-render-join --require-no-pull-request-target</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" && node scripts/ci/verify_pr_claims.mjs --repo . --claims .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json --body .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md --expected-repository szTheory/accrue --require-claims --require-render-join --require-no-pull-request-target --min-executed 1</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; node scripts/ci/render_pr_claims.mjs --claims .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json > /tmp/rendered-claims.md &amp;&amp; diff -u .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md /tmp/rendered-claims.md &amp;&amp; echo BYTE_EXACT_RENDER_JOIN_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; T=$(mktemp -d) &amp;&amp; printf '{"schema":1,"repository":"szTheory/accrue","claims":[{"id":"C1","kind":"exec_shell","text":"x","expected":0}]}' > "$T/c.json" &amp;&amp; ! node scripts/ci/verify_pr_claims.mjs --repo . --claims "$T/c.json" --require-claims &amp;&amp; echo UNKNOWN_KIND_FAILS_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; T=$(mktemp -d) &amp;&amp; printf '{"schema":1,"repository":"szTheory/accrue","claims":[{"id":"C1","kind":"merge_count","base":"--upload-pack=touch /tmp/pwn","head":"HEAD","expected":0,"text":"x"}]}' > "$T/c.json" &amp;&amp; ! node scripts/ci/verify_pr_claims.mjs --repo . --claims "$T/c.json" --require-claims &amp;&amp; test ! -e /tmp/pwn &amp;&amp; echo FLAGLIKE_VALUE_REJECTED_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; grep -v '^[[:space:]]*#' scripts/ci/verify_pr_body_contract.mjs | grep -c 'assertFalsifiability'</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; node --test --test-reporter=tap scripts/ci/verify_pr_body_contract.mjs &amp;&amp; node scripts/ci/verify_pr_body_contract.mjs --body .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md --expected-repository szTheory/accrue --require-sections --require-density</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor</automated>
  </verify>
  <done>The JSON sidecar is the authority and the markdown re-renders from it byte-exactly; an unknown kind and a flag-like value both fail before any argv is built and nothing is executed from committed text; a false `expected` fails printing measured vs asserted; attested claims expire and are capped; the retired `assertFalsifiability` count is 0 and the remaining shape checks still pass; the step is merge-blocking and runs before setup-beam.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3 (SL-B): claim ref fields must name explicit remote refs, never bare local branches</name>
  <files>scripts/ci/verify_pr_claims.mjs, .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json, .github/workflows/ci.yml</files>
  <read_first>scripts/ci/verify_pr_claims.mjs (written in Task 2)</read_first>
  <behavior>
    Negative controls (each MUST fail, each a named node:test scenario):
    - A claim whose `base` is `main` fails, naming the field and instructing `origin/main`.
    - A claim whose `head` is `master`, `develop`, or `trunk` fails.
    - A claim whose ref field is a bare local branch fails EVEN WHEN its `expected` value is currently correct — ref hygiene and claim truth are separate properties and this test must prove they are separable.
    Positive controls (MUST pass):
    - `origin/main` passes.
    - `refs/remotes/origin/main` passes.
    - A 40-hex SHA passes — it is unambiguous and needs no remote qualification.
    - A ref naming a topic branch that has no `origin/` peer passes when the claim additionally carries `"local_ref_reason": "<why>"`; a bare well-known branch name never qualifies for this escape, and an empty reason fails.
  </behavior>
  <action>
Add `assertRemoteRefsExplicit(claims)` to `scripts/ci/verify_pr_claims.mjs`, gated behind a
new `--require-remote-refs` boolean flag. Under the typed design this is a validation rule
on schema fields, not text analysis — it inspects only values whose declared argument type
is `ref`, so a path, a prose mention, or a SHA can never trip it.

ROOT CAUSE to record in the header comment: a claim computed against local `main` is read
by a reviewer against `origin/main`. During phase 232 that produced a merge count asserted
as `3`, corrected to `9`, where `9` was right only against a 4-commit-stale local `main` —
a fresh clone yields `4`. An `origin/`-explicit claim is reproducible by the reviewer; a
bare one is not, and the reviewer has no way to tell which they are looking at.

RULE: a `ref`-typed value fails when it matches `/^(main|master|develop|trunk|release)$/`
and is not prefixed `origin/` or `refs/remotes/`. Exempt values that are 7-40 char hex.
For a genuine local-only topic ref, require an explicit sibling field
`"local_ref_reason": "<one line>"` on the same claim; an absent or empty reason fails. Fail
naming the claim id, the field, the offending value, and the `origin/`-prefixed form.

Add the flag to `BOOLEAN_FLAGS`, include it in the PASS-line strict-flag suffix, and append
`--require-remote-refs` to BOTH the `--fixtures` and the real invocation in the "PR claims
contract (SL-A)" step from Task 2.

Then audit `232-INTEGRATION-PR.json`: correct any bare ref to its `origin/`-explicit form
and RE-MEASURE the claim's `expected` against that form. A corrected ref may change the true
value — that is precisely the bug this catches, so treat a changed value as the expected
outcome and not as a regression.
  </action>
  <verify>
    <automated>cd "$(git rev-parse --show-toplevel)" && node --test --test-reporter=tap scripts/ci/verify_pr_claims.mjs && node scripts/ci/verify_pr_claims.mjs --fixtures --require-claims --require-render-join --require-remote-refs --require-no-pull-request-target</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; T=$(mktemp -d) &amp;&amp; printf '{"schema":1,"repository":"szTheory/accrue","claims":[{"id":"C1","kind":"merge_count","base":"main","head":"HEAD","expected":0,"text":"x"}]}' > "$T/c.json" &amp;&amp; ! node scripts/ci/verify_pr_claims.mjs --repo . --claims "$T/c.json" --require-remote-refs &amp;&amp; echo BARE_REF_FAILS_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; node scripts/ci/verify_pr_claims.mjs --repo . --claims .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json --body .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md --require-claims --require-render-join --require-remote-refs --min-executed 1</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; grep -v '^[[:space:]]*#' .github/workflows/ci.yml | grep -c -- '--require-remote-refs'</automated>
  </verify>
  <done>A bare `main` ref field fails with an `origin/`-prefixed remediation; a SHA and an `origin/`-qualified ref pass; a local-only topic ref passes only with a non-empty recorded reason; the committed sidecar carries no bare well-known ref and every corrected claim was re-measured; the flag is wired into the merge-blocking step in both invocations.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 4 (SL-C): sensitive-token scope lock plus a monotonic total ratchet</name>
  <files>scripts/ci/verify_sensitive_token_census.mjs, .planning/hygiene/sensitive-token-census.json, .github/workflows/ci.yml</files>
  <precondition>PR #45 has been merged by the maintainer and the merge commit is reachable from `origin/main`. The census baseline is minted at that merge commit; running earlier produces a baseline that is stale the moment the merge lands. Halt and report if it is not yet merged.</precondition>
  <read_first>scripts/ci/verify_ci_script_contract.mjs (`liveCohort` / `git ls-files` enumeration and the cohort-floor anti-vacuity pattern), .planning/phases/232-bounded-hygiene-release-handoff/232-VERIFICATION.md (the adjudication recording why the exposure is not remediable by editing files)</read_first>
  <behavior>
    Negative controls (each MUST fail, each a named node:test scenario):
    - SCOPE LOCK: a fixture occurrence under `accrue/`, `accrue_admin/`, `guides/`, `.github/`, or in a root `CHANGELOG.md` fails, naming the path with the token itself redacted.
    - SCOPE LOCK: a fixture occurrence in a file that would be included in a Hex package (a path matching the `files:` globs declared in either `mix.exs`) fails even if it also lives under an otherwise-allowed prefix.
    - RATCHET: a total count ABOVE the recorded baseline fails, naming both numbers.
    - A census entry whose reconstructed literal does not hash to its recorded `pattern_sha256` fails — the entry cannot be silently repointed.
    - A census pattern matching ZERO occurrences across a non-empty corpus fails as vacuous, naming the entry id.
    - A run over an empty corpus fails rather than reporting a completeness pass.
    - A census file containing the reconstructed literal in cleartext anywhere fails.
    - Gate output containing the literal token anywhere fails a self-check on its own stdout/stderr.
    Positive controls (MUST pass):
    - A total count BELOW the recorded baseline passes (the ratchet is one-directional) and prints that the baseline should be lowered.
    - A phase directory MOVED from `.planning/phases/NNN-x/` to `.planning/milestones/vN/NNN-x/`, with the same total count, passes unchanged. This is the archive operation this repo performs every milestone, and it is the reason per-path counts are recorded but not enforced.
  </behavior>
  <action>
Create `scripts/ci/verify_sensitive_token_census.mjs` and
`.planning/hygiene/sensitive-token-census.json`.

MAINTAINER DECISION, recorded: **merge PR #45 as-is, do not scrub.** Mint the baseline at
the merge commit. Do not edit any existing occurrence.

WHY THIS REPLACES THE OLD CHECK (header comment): the prior check was
`grep -c <token> <one file> -> 0` — per-file, so it under-measured, and the true footprint
was found by accident rather than by the gate.

RE-MEASURED REALITY (re-measure live during execution; these are the figures to expect):
**57 occurrences across 18 files**, up from 34/16 because the verification pass that
assessed the exposure itself wrote 12 new occurrences. Critically: **`origin/main` has
ZERO**, and **zero occurrences exist outside `.planning/`**. That shape is what determines
the invariant.

PRIMARY INVARIANT — SCOPE LOCK. The token may appear ONLY under `.planning/`. Any
occurrence in `accrue/`, `accrue_admin/`, `guides/`, `.github/`, a root `CHANGELOG.md`, or
any path matched by the `files:` globs of either package's `mix.exs` (i.e. anything that
would reach a published Hex tarball) is a HARD FAIL. This is the invariant that actually
protects the thing worth protecting: `.planning/` is internal record-keeping, a Hex tarball
is a permanent public artifact that cannot be unpublished.

SECONDARY INVARIANT — MONOTONIC RATCHET. Record the total count. A total ABOVE the baseline
fails. A total BELOW it passes and prints a note that the baseline should be lowered in the
same commit. Record per-path counts in the manifest for diagnostics but **do NOT enforce
them**: this repo archives `.planning/phases/NNN-*/` into `.planning/milestones/` at every
milestone close, and per-path enforcement would fail on every archive move — a gate that
reddens on a routine correct operation is a gate that gets deleted.

NO SECRETS. Use no CI secrets at all. A pepper or HMAC held in Actions secrets would force
a choice between passing vacuously on fork PRs (where repository secrets are unavailable)
and blocking all outside contributions. Both are unacceptable for a public repo, so the
manifest must be self-contained.

CLEARTEXT CONSTRAINT AND HOW `pattern` SATISFIES IT. Store the token as a regex source in
which at least one character is wrapped in a single-character class — the `x[y]z` shape.
That source compiles to a regex matching the literal while containing no contiguous
substring equal to it, so a plain search for the token does not hit the manifest.
Reconstruct the literal for hashing by collapsing every `[c]` to `c`, then assert
`sha256(literal.toLowerCase()) === pattern_sha256`.

Be honest in the rationale comment about what that buys. It is NOT secrecy — the name is
already public via a merged PR and a live remote branch ref, and no file edit retracts that.
It buys exactly two things: the new artifact does not mint another searchable occurrence,
and the hash makes the census target tamper-evident so an entry cannot be repointed at a
token matching nothing while the gate keeps reporting green.

REDACTION. Public CI logs are themselves a publication surface. Every path, count, and
diagnostic the gate prints must have the token replaced by the literal
`<REDACTED-ADOPTER-REF>`. Add a self-check that scans the gate's own assembled output for
the reconstructed literal and fails if present — a leak gate that leaks in its own failure
message is worse than no gate.

NEUTRAL NAMING. The script, the manifest, the CI step name, the commit message, and every
comment stay generic. Never name the file, the step, or the commit after the organization.

MANIFEST SHAPE. `.planning/hygiene/sensitive-token-census.json`:
```
{ "entries": [ {
    "id": "token-1",
    "kind": "third-party-organization-reference",
    "pattern": "<obfuscated regex source>",
    "pattern_sha256": "<hex sha256 of reconstructed lowercased literal>",
    "rationale": "Already public via a merged PR and a live remote ref; recorded, not scrubbed. The only effective remediation is ref renaming, which is maintainer-owned.",
    "allowed_prefixes": [".planning/"],
    "baseline_total": <n>,
    "baseline_files": <n>,
    "observed_paths": { "<path>": <count>, ... }
} ] }
```
`observed_paths` is diagnostic only — say so in the manifest itself with a comment field, so
a future reader does not assume it is enforced.

SCANNER. Enumerate from `git --no-optional-locks ls-files` (tracked files only, never a raw
directory read — same reason `liveCohort` does). Skip binary files by rejecting any whose
first 8 KiB contains a NUL byte. Count case-insensitive matches per file. Exclude the
manifest itself from the scan only if needed; note that the obfuscated pattern does not
match itself, so no exclusion should be necessary — assert that as a scenario rather than
assuming it.

ANTI-VACUITY. Fail when the corpus is empty, when the manifest has zero entries, and when
any entry matches zero occurrences corpus-wide.

FLAGS. `BOOLEAN_FLAGS`: `fixtures`, `require-scope-lock`, `require-ratchet`,
`require-no-cleartext`. `VALUE_OPTIONS`: `repo`, `census`. PASS line names entries, files,
total occurrences, and the baseline.

WIRE IT: a merge-blocking step "Sensitive token census (SL-C)" in
`docs-contracts-shift-left`, placed with the cheap Node guards BEFORE `Set up BEAM`, running
the unit tests, then `--fixtures --require-scope-lock --require-ratchet
--require-no-cleartext`, then `--repo . --census .planning/hygiene/sensitive-token-census.json
--require-scope-lock --require-ratchet --require-no-cleartext`. No `continue-on-error`.

Measure the baseline AFTER writing the script and BEFORE committing, and re-measure if a
later task adds an occurrence.
  </action>
  <verify>
    <automated>cd "$(git rev-parse --show-toplevel)" && node --test --test-reporter=tap scripts/ci/verify_sensitive_token_census.mjs && node scripts/ci/verify_sensitive_token_census.mjs --fixtures --require-scope-lock --require-ratchet --require-no-cleartext</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" && node scripts/ci/verify_sensitive_token_census.mjs --repo . --census .planning/hygiene/sensitive-token-census.json --require-scope-lock --require-ratchet --require-no-cleartext</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; node -e 'const c=require("./.planning/hygiene/sensitive-token-census.json");const cr=require("node:crypto");const raw=require("node:fs").readFileSync(".planning/hygiene/sensitive-token-census.json","utf8");let n=0;for(const e of c.entries){const lit=e.pattern.replace(/\[(.)\]/g,"$1");if(cr.createHash("sha256").update(lit.toLowerCase()).digest("hex")!==e.pattern_sha256)throw new Error("hash mismatch "+e.id);if(raw.toLowerCase().includes(lit.toLowerCase()))throw new Error("cleartext in manifest "+e.id);n++}if(n===0)throw new Error("empty census");console.log("MANIFEST_HASHED_AND_CLEAN",n)'</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; node -e 'const c=require("./.planning/hygiene/sensitive-token-census.json");const {execFileSync}=require("node:child_process");let bad=0;for(const e of c.entries){const lit=e.pattern.replace(/\[(.)\]/g,"$1");const out=execFileSync("git",["--no-optional-locks","grep","-il","-e",lit,"--","."],{encoding:"utf8"}).split("\n").filter(Boolean);for(const p of out){if(!e.allowed_prefixes.some(pre=>p.startsWith(pre))){console.error("OUT_OF_SCOPE",p);bad++}}}if(bad)process.exit(1);console.log("SCOPE_LOCK_HOLDS")'</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; grep -v '^[[:space:]]*#' .github/workflows/ci.yml | grep -c 'verify_sensitive_token_census.mjs'</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor</automated>
  </verify>
  <done>Scope lock holds (zero occurrences outside `.planning/`, none packageable); the ratchet fails upward and passes downward; a milestone archive move passes unchanged; per-path counts are recorded but not enforced; the manifest carries no cleartext and hashes correctly; all output is redacted and the script, step, and commit names are neutral; no CI secret is used; nothing was scrubbed.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 5 (SL-D): ban the pipefail/SIGPIPE `grep -q` idiom in scripts/ci — bespoke, not shellcheck</name>
  <files>scripts/ci/verify_pipefail_grep_idiom.mjs, scripts/ci/accrue_host_verify_dev_boot.sh, scripts/ci/accrue_host_verify_browser.sh, .github/workflows/ci.yml</files>
  <read_first>git show 3f6791c7 (the root-cause analysis and the capture-then-filter remediation), git show 7e9f45dc, scripts/ci/verify_ci_script_contract.mjs (cohort enumeration + floor)</read_first>
  <behavior>
    Negative controls (each MUST fail, each a named node:test scenario):
    - A fixture script with `set -euo pipefail` and `awk '...' "$f" | grep -Fq needle` fails, naming the file, the line, and the capture-then-filter remediation.
    - The same shape with `grep -qv` / `grep -v` as the consumer fails.
    - The same shape with a `git`, `sed`, `find`, or `cat` producer fails.
    - A shell-function producer (`describe_port_owner "$p" | grep -q .`) fails.
    - An allowlist entry whose recorded reason is an empty string fails — an entry without a committed reason is not an allowlist entry.
    - A run inspecting zero files fails rather than reporting a pass.
    Positive controls (MUST pass):
    - `printf '%s\n' "$var" | grep -Fq needle` passes: a builtin producer writes a sub-pipe-buffer string in one write and cannot lose the race.
    - A pipeline captured into `$( ... )` ending `|| true` passes: pipefail is absorbed and no early exit occurs.
    - A script without `set -o pipefail` passes.
    - The two remediated host scripts pass after conversion.
  </behavior>
  <action>
Create `scripts/ci/verify_pipefail_grep_idiom.mjs`.

MECHANISM, stated exactly and WITHOUT overstatement in the header comment. Under
`set -euo pipefail`, a `-q` consumer exits at its first match and closes the pipe; the
producer takes SIGPIPE and dies 141; pipefail promotes that to the pipeline status; an
enclosing `if !` inverts it and SKIPS the `fail` on precisely the input that should have
tripped it.

ACCURACY REQUIREMENT — re-measured live, and the plan must state these figures rather than
the revision-1 estimates: **36** pipelines into `grep -q`/`-qv` under `scripts/ci`, of which
**3** have non-builtin producers. None is currently producing a false PASS: both producers
fixed this session emit far under the 64 KiB pipe buffer (30 lines / 1527 bytes and 1 line /
69 bytes). So this is a **latent** hazard, not an active one. It is still worth banning
because the failure is silent and inverted, and because the same shape was hand-fixed twice
in one session with nothing preventing a third. Cite commits `3f6791c7` and `7e9f45dc`.

WHY BESPOKE AND NOT SHELLCHECK — record this, because "just use shellcheck" is the obvious
objection and it was tested. **shellcheck 0.11.0 is installed on this machine and reports
NOTHING on the exact pre-fix shape, even with `--include=SC2337`.** The upstream rule is
merged but unreleased. Making this merge-blocking via shellcheck would therefore require a
digest-pinned master-build container — a supply-chain dependency taken on for a ~15-line
check, on the merge-blocking path. Keep the bespoke guard.

DETECTION. Enumerate `git --no-optional-locks ls-files 'scripts/ci/*.sh'`. For each file
containing `set -` with `pipefail`, strip comment lines and scan for a pipeline whose
consumer is `grep` carrying `-q` or `-v` in its option cluster. Classify by PRODUCER — this
is what makes the guard precise rather than blunt:
  - producer is the shell builtin `printf` or `echo` → EXEMPT (single sub-buffer write,
    cannot lose the race). Record that reason in a named constant, not only in prose.
  - producer is anything else (external command or shell function) → OFFENDER.
Also exempt a pipeline captured in a command substitution ending `|| true`; prove that
exemption with a positive control so it is a tested property, not an assumption.

ALLOWLIST. Export `IDIOM_ALLOWLIST` as a `Map<relativePath#line, reason>` following
`LIBRARY_MODULE_ALLOWLIST`'s shape in `verify_ci_script_contract.mjs`: every entry carries a
one-line committed reason, and an empty reason FAILS. Prefer FIXING to allowlisting. The
measured live offender set is 3; convert the genuinely hazardous
`describe_port_owner "$port" | grep -q .` sites in `accrue_host_verify_dev_boot.sh` and
`accrue_host_verify_browser.sh` to capture-then-filter (`out=$(producer); case "$out" in
... esac`) rather than allowlisting them. Verify BOTH directions after each conversion, as
commit `3f6791c7` did: the fixed script still passes against real input AND still fails
closed against a fixture with the needle stripped.

ANTI-VACUITY. Fail when the enumerated `.sh` cohort is empty; print the inspected file count
and the pipeline count examined on the PASS line.

FLAGS. `BOOLEAN_FLAGS`: `fixtures`, `require-idiom-ban`. `VALUE_OPTIONS`: `repo`.

WIRE IT: a merge-blocking step "Pipefail/SIGPIPE grep idiom ban (SL-D)" in
`docs-contracts-shift-left`, with the cheap Node guards BEFORE `Set up BEAM`, running the
unit tests, `--fixtures --require-idiom-ban`, then `--repo . --require-idiom-ban`. No
`continue-on-error`.

FOLLOW-UP SEED (do not implement here; record it in the SUMMARY's deferred list):
**53 shell guards under `scripts/ci` are entirely unlinted**, and full shellcheck adoption is
a substantially larger win than this one rule. Record the warning that must travel with that
seed: **shellcheck's own SC2143 actively recommends this exact footgun**, so any adoption
must include `disable=SC2143` or it will push contributors back toward the shape this task
bans.
  </action>
  <verify>
    <automated>cd "$(git rev-parse --show-toplevel)" && node --test --test-reporter=tap scripts/ci/verify_pipefail_grep_idiom.mjs && node scripts/ci/verify_pipefail_grep_idiom.mjs --fixtures --require-idiom-ban && node scripts/ci/verify_pipefail_grep_idiom.mjs --repo . --require-idiom-ban</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; T=$(mktemp -d) &amp;&amp; mkdir -p "$T/scripts/ci" &amp;&amp; git -C "$T" init -q &amp;&amp; printf '#!/usr/bin/env bash\nset -euo pipefail\nif awk NR==1 "$1" | grep -Fq needle; then echo hi; fi\n' > "$T/scripts/ci/bad.sh" &amp;&amp; git -C "$T" add -A &amp;&amp; ! node scripts/ci/verify_pipefail_grep_idiom.mjs --repo "$T" --require-idiom-ban &amp;&amp; echo OFFENDER_FAILS_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; T=$(mktemp -d) &amp;&amp; mkdir -p "$T/scripts/ci" &amp;&amp; git -C "$T" init -q &amp;&amp; printf '#!/usr/bin/env bash\nset -euo pipefail\nif printf %%s "$1" | grep -Fq needle; then echo hi; fi\n' > "$T/scripts/ci/ok.sh" &amp;&amp; git -C "$T" add -A &amp;&amp; node scripts/ci/verify_pipefail_grep_idiom.mjs --repo "$T" --require-idiom-ban &amp;&amp; echo BUILTIN_PRODUCER_EXEMPT_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; bash -n scripts/ci/accrue_host_verify_dev_boot.sh &amp;&amp; bash -n scripts/ci/accrue_host_verify_browser.sh &amp;&amp; echo REMEDIATED_SCRIPTS_PARSE_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; grep -v '^[[:space:]]*#' .github/workflows/ci.yml | grep -c 'verify_pipefail_grep_idiom.mjs'</automated>
  </verify>
  <done>A non-builtin-producer `| grep -q` pipeline under pipefail fails naming file, line, and remediation; `printf`-producer and `|| true`-absorbed pipelines pass; the 3 measured live offenders are converted to capture-then-filter rather than allowlisted, each verified in both directions; an empty allowlist reason fails; no shellcheck dependency was added; the step is merge-blocking.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 6 (SL-G): no generated artifact may derive from a field of the artifact that checksums it</name>
  <files>scripts/ci/verify_artifact_fixed_point.mjs, .github/workflows/ci.yml</files>
  <read_first>.planning/phases/232-bounded-hygiene-release-handoff/232-UAT.md (its `started:` / `updated:` front-matter fields), .planning/phases/232-bounded-hygiene-release-handoff/232-VERIFICATION.md (its `verified:` field and `covered_digest`), scripts/ci/verify_executable_uat_contract.mjs (how the UAT artifact is generated and digested)</read_first>
  <behavior>
    Negative controls (each MUST fail, each a named node:test scenario):
    - A fixture pair where artifact A's front matter derives a field from artifact B, and B's `covered_digest` covers A, fails — naming both artifacts and the two edges that close the cycle.
    - A fixture pair at a NON-fixed point (regenerating A changes A's bytes, which would change B's digest) fails, naming the changed field.
    - A fixture whose `covered_digest` does not match a freshly computed digest of its covered set fails.
    - A run inspecting zero artifact pairs fails rather than reporting a pass.
    Positive controls (MUST pass):
    - A pair where A's derived fields come only from sources OUTSIDE B's covered set passes.
    - A pair at a fixed point — regenerating A is a byte-level no-op — passes.
    - The live `232-UAT.md` / `232-VERIFICATION.md` pair passes after the cycle is broken.
  </behavior>
  <action>
Create `scripts/ci/verify_artifact_fixed_point.mjs`.

THE DEFECT THIS ENCODES (header comment): `232-UAT.md` derives its `started:` and `updated:`
front-matter fields from the `verified:` field of `232-VERIFICATION.md`, while
`232-VERIFICATION.md`'s `covered_digest` covers `232-UAT.md`. That is a derivation CYCLE.
Every verifier run bumps `verified:`, which rewrites the UAT, which re-stales the digest,
which requires another verifier run — forever. The only fixed point reachable today was a
hand-written digest, and it cost real time during the phase-232 close.

CHECK 1 — CYCLE DETECTION (`--require-acyclic`). Build a directed graph over phase
artifacts with two kinds of edge: a DERIVES edge (artifact A's front matter takes a value
from artifact B, declared by a machine-readable `derived_from:` key that this task
introduces to the generating artifacts) and a COVERS edge (B's `covered_digest` includes A).
Fail on any cycle, printing the full edge list that closes it. A cycle is the structural
defect; naming the specific edges is what makes it fixable rather than merely reported.

CHECK 2 — FIXED POINT (`--require-fixed-point`). The weaker but always-available property,
and the one to rely on if declaring `derived_from:` everywhere proves too invasive:
regenerate each generated artifact into a temp directory and require the output to be
byte-identical to the committed file. Any diff is a FAIL naming the first changed field.
Normalize nothing — a normalization step here would hide exactly the timestamp churn this
exists to catch.

CHECK 3 — DIGEST TRUTH (`--require-digest-match`). Recompute each `covered_digest` from its
covered set and require equality. This is what makes a hand-written digest fail, closing the
escape hatch that was used to break the cycle by hand.

BREAK THE LIVE CYCLE. Fixing the cycle is part of this task, not a follow-up. Preferred fix,
in order: (1) stop deriving the UAT's `started:`/`updated:` from `verified:` — source them
from the phase's own plan/summary timestamps, which are outside the covered set; or, if that
is not available, (2) exclude the volatile front-matter block from `covered_digest`'s input
by digesting the artifact BODY only, and record that exclusion explicitly in the artifact so
it is a declared property rather than an implicit one. Do NOT break the cycle by
hand-writing a digest — Check 3 exists to make that fail.

ANTI-VACUITY. Fail when zero artifact pairs are discovered. PASS line names the number of
artifacts inspected, edges built, and regenerations compared.

FLAGS. `BOOLEAN_FLAGS`: `fixtures`, `require-acyclic`, `require-fixed-point`,
`require-digest-match`. `VALUE_OPTIONS`: `repo`, `phase`.

WIRE IT: a merge-blocking step "Artifact fixed-point and derivation-cycle guard (SL-G)" in
`docs-contracts-shift-left`, with the cheap Node guards BEFORE `Set up BEAM`, running the
unit tests, `--fixtures --require-acyclic --require-fixed-point --require-digest-match`,
then `--repo . --require-acyclic --require-fixed-point --require-digest-match`. No
`continue-on-error`.
  </action>
  <verify>
    <automated>cd "$(git rev-parse --show-toplevel)" && node --test --test-reporter=tap scripts/ci/verify_artifact_fixed_point.mjs && node scripts/ci/verify_artifact_fixed_point.mjs --fixtures --require-acyclic --require-fixed-point --require-digest-match</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" && node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" && node scripts/ci/verify_executable_uat_contract.mjs --all-since 229 && git --no-optional-locks diff --exit-code -- .planning/phases/232-bounded-hygiene-release-handoff/232-UAT.md && echo UAT_REGENERATION_IS_A_NO_OP</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; grep -v '^[[:space:]]*#' .github/workflows/ci.yml | grep -c 'verify_artifact_fixed_point.mjs'</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor</automated>
  </verify>
  <done>The UAT/VERIFICATION derivation cycle is broken at the source rather than by a hand-written digest; regenerating the UAT is a byte-level no-op; a fixture cycle, a non-fixed point, and a hand-written digest each fail with the offending edge or field named; the step is merge-blocking.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 7 (SL-F): committed PR-body file must match the live PR body — fail closed, never skip</name>
  <files>scripts/ci/verify_pr_body_currency.mjs, .github/workflows/ci.yml, scripts/ci/verify_ci_script_contract.mjs</files>
  <read_first>scripts/ci/verify_pr_body_contract.mjs (the sibling SHAPE contract; this must not duplicate its checks), scripts/ci/verify_pr_claims.mjs (Task 2), .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md, .github/workflows/ci.yml (the `permissions:` block at the top)</read_first>
  <behavior>
    Negative controls (each MUST fail, each a named node:test scenario):
    - A committed body declaring a PR number whose injected live body differs fails, printing the first differing line and the `gh pr edit` remediation.
    - A run with a declared PR number and NO token available fails, naming the missing credential. Assert the failure message explicitly rejects skipping.
    - A run where the fetch returns a non-retryable non-200 fails immediately, without retrying.
    - A run where the fetch times out on all 3 attempts fails, and the message classifies it as infrastructure and says "re-run the job".
    - A body declaring a malformed PR reference (non-numeric, or a URL whose owner/repo does not match `--expected-repository`) fails.
    - A run over zero body files, or one where fewer than `--min-declared` bodies carried a declaration, fails.
    Positive controls (MUST pass):
    - A declared PR whose injected live body matches after newline normalization passes.
    - A body file declaring NO PR number is reported `unopened` and passes; the PASS line names how many were unopened so the count cannot hide a whole-corpus opt-out.
    - A 5xx on attempt 1 followed by a 200 on attempt 2 passes, and the retry is recorded in the output.
  </behavior>
  <action>
Create `scripts/ci/verify_pr_body_currency.mjs`.

WHY, AND THE HONEST COST — both in the header comment. A committed PR-body file drifted
from the live PR body twice in one phase-232 session. This is the only guard here needing
network and a credential, and SL-A's lesson forbids the obvious escape hatch: "skip when
unavailable" is exactly how a gate goes vacuous. So it fails closed. The cost is real and
must be written where a future maintainer sees it BEFORE muting the gate: this check will
go transiently RED for a TRUE reason — you commit a body edit, CI runs, and the live body
is not updated until you run `gh pr edit <n> --body-file <path>`. That red is correct. The
remediation is one command and the gate prints it. Do not soften this into a warning; if the
transient red is unacceptable, delete the gate rather than make it lie.

TOKEN AVAILABILITY, corrected: `secrets.GITHUB_TOKEN` **is** available on fork
`pull_request` runs — what forks lose is repository and organization secrets. So this needs
only `permissions: pull-requests: read` on the workflow, no repository secret, and it blocks
on forks like everyone else. Record that correction in the comment so nobody later adds a
skip-on-fork branch believing forks have no token.

DECLARATION. A committed body opts in via YAML front matter `pr: <number>` or a single line
`<!-- pr: https://github.com/OWNER/REPO/pull/<number> -->`. Validate owner/repo against
`--expected-repository`, reusing `verify_pr_body_contract.mjs`'s `assertExpectedRepository`
by import rather than re-implementing the pattern (the repo's convention is reuse — see
`UNSAFE_PATH_PATTERN`). A file with no declaration is `unopened`: it passes and is counted.
A file with a declaration MUST be compared live.

FETCH. `fetch` against `https://api.github.com/repos/<owner>/<repo>/pulls/<number>` with
`Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`, and
`Authorization: Bearer <token>` from `--token-env` (default `GITHUB_TOKEN`). Enforce an
`AbortController` timeout (default 15s).

RETRY, CLASSIFIED. Retry at most 3 attempts with backoff, and ONLY on network error, 5xx, or
a rate-limit response (429, or 403 carrying `x-ratelimit-remaining: 0`). Never retry a 401,
404, or 422 — those are real and a retry only makes the failure slower. After exhausting
retries, fail with a message that names it as infrastructure and instructs "re-run the job",
so an infra blip is distinguishable from a drift finding at a glance. Missing token, a
non-retryable non-200, or a response without a `body` field is an immediate FAILURE. Never
catch-and-continue. Never log the token or any header value.

COMPARISON. Normalize both sides: strip the declaration line / front matter from the
committed file, CRLF → LF, strip trailing whitespace per line, drop trailing blank lines.
Then compare exactly. On mismatch print the first differing line number with both versions
truncated to 200 chars, plus `gh pr edit <number> --body-file <path>`. Route the live body
through `verify_pr_body_contract.mjs`'s `assertLeak` AND through SL-C's redaction before
printing any of it — a diff must never be the thing that publishes a local path or the
censused token into a public CI log.

ANTI-VACUITY. `--min-declared N` (CI passes `1`): fail when fewer than N bodies carried a
declaration. Without it, deleting every declaration silently turns the gate off. PASS line
names declared, compared, retried, and unopened counts.

FLAGS. `BOOLEAN_FLAGS`: `fixtures`, `require-currency`. `VALUE_OPTIONS`: `repo`, `bodies`,
`expected-repository`, `token-env`, `timeout-ms`, `min-declared`. In `--fixtures` mode
inject the live body through a seam (an optional `fetchBody` parameter on the exported
`verifyCurrency()`), so every scenario is hermetic and NO fixture touches the network.

PERMISSIONS. Add `pull-requests: read` to the `permissions:` block at the top of
`.github/workflows/ci.yml`. That is the only widening this plan makes; note it in the commit
message. Do NOT add `pull-requests: write`, and do NOT convert any trigger to
`pull_request_target` — SL-A's `--require-no-pull-request-target` will go red if anyone
later does, which is the intended interlock.

ADD THE DECLARATION to `232-INTEGRATION-PR.md` referencing PR #45, then reconcile: if the
committed file and the live body differ, update the LIVE body with
`gh pr edit 45 --body-file <path>`. That is a body edit, not a merge, and is permitted. Note
that by this point PR #45 may already be merged (SL-C's precondition) — a merged PR's body
is still fetchable and still comparable, so the check applies unchanged.

FINALLY (this task only): re-measure with `git --no-optional-locks ls-files 'scripts/ci/*.mjs'
| wc -l` and raise `COMMITTED_COHORT_FLOOR` in `scripts/ci/verify_ci_script_contract.mjs` to
the new live value, recording the re-measurement date in the comment above it exactly as the
existing comment instructs. The floor is a floor, not a ceiling — it exists only to stop a
short or empty glob being read as a completeness pass, and leaving it at 41 after adding six
files weakens it.
  </action>
  <verify>
    <automated>cd "$(git rev-parse --show-toplevel)" && node --test --test-reporter=tap scripts/ci/verify_pr_body_currency.mjs && node scripts/ci/verify_pr_body_currency.mjs --fixtures --require-currency</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; env -u GITHUB_TOKEN node scripts/ci/verify_pr_body_currency.mjs --repo . --expected-repository szTheory/accrue --require-currency --min-declared 1; test $? -ne 0 &amp;&amp; echo FAILS_CLOSED_WITHOUT_TOKEN_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; grep -v '^[[:space:]]*#' .github/workflows/ci.yml | grep -c 'verify_pr_body_currency.mjs'</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; grep -v '^[[:space:]]*#' .github/workflows/ci.yml | grep -c 'pull-requests: read'</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; test "$(git --no-optional-locks ls-files 'scripts/ci/*.mjs' | wc -l | tr -d ' ')" = "$(grep -oE 'COMMITTED_COHORT_FLOOR = [0-9]+' scripts/ci/verify_ci_script_contract.mjs | grep -oE '[0-9]+')" &amp;&amp; echo COHORT_FLOOR_REMEASURED_OK</automated>
    <automated>cd "$(git rev-parse --show-toplevel)" &amp;&amp; node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor</automated>
  </verify>
  <done>A declared PR whose live body differs fails with a one-command remediation; a missing token fails rather than skipping; retries are classified and only 5xx/network/rate-limit are retried; no fixture touches the network; `pull-requests: read` is the only permission widening; the cohort floor is re-measured.</done>
</task>

</tasks>

<sequencing>
Strictly sequential, waves 1 through 7, in the order above. Every task appends a step to
`.github/workflows/ci.yml`; that shared-file overlap is the reason for the ordering, since
parallel edits to one workflow file conflict. Each task remains an independently
committable unit — guard, tests, and CI wiring land together, so no commit leaves an
unwired guard in the tree.

Ordering rationale:
- **SL-E first** (promoted in revision 2): highest value-per-cost, addresses a failure that
  actually happened, and depends on nothing.
- **SL-A second**, unblocked by anything above it. SL-B extends SL-A's module and must
  follow it.
- **SL-C fourth**, carrying a hard `<precondition>`: PR #45 must be merged first, because
  the baseline is minted at the merge commit.
- **SL-D and SL-G** are independent of everything else; drop or defer either without
  disturbing the rest.
- **SL-F last**: it is the weakest of the seven (see `<planner_judgment>`), it is the only
  one changing workflow permissions, and it carries the cohort-floor re-measurement that
  must happen after every new `.mjs` file exists.

One commit per task, `feat(ci): ...` with the
`Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>` trailer. SL-C's commit
message must stay neutral and must not name the organization.
</sequencing>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| authored JSON sidecar -> typed evaluator (SL-A) | Committed values reach a `git` argv. Values are typed scalars validated against a schema; no committed string ever becomes a program name, a flag, or a shell word. |
| PR worktree -> git evaluator config (SL-A) | A PR tree can ship `.gitattributes` / `.gitmodules` / hooks that git would otherwise honor. |
| GitHub API -> public CI log (SL-F) | A live PR body, editable by anyone with comment access, is read into a public log. |
| censused token -> public CI log and package tarball (SL-C) | Both are publication surfaces that cannot be retracted. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-SLA-01 | Elevation of Privilege | claim evaluation | critical | mitigate | Typed sidecar + frozen evaluator table; program name and flags come only from the table; committed values are schema-validated typed scalars passed as operands after a literal `--`. No text from any committed file is executed. Replaces revision 1's prefix-allowlist design, which was unsound against git's long-option abbreviation matching (GHSA-2f96-g7mh-g2hx). |
| T-SLA-02 | Elevation of Privilege | in-tree git config from a PR worktree | critical | mitigate | Plumbing commands only (`rev-list`, `rev-parse`, `cat-file`, `ls-files`, `grep -F`); never `diff`/`log -p`/`show`; forced `-c core.attributesFile=/dev/null -c core.hooksPath=/dev/null -c protocol.ext.allow=never` closes the `diff.external`/textconv/hooks vector that a scrubbed HOME alone did not. |
| T-SLA-03 | Elevation of Privilege | workflow trigger surface | high | mitigate | `--require-no-pull-request-target` fails the build if any workflow declares that trigger. Retained as an interlock even though it is no longer load-bearing for safety under the typed design. |
| T-SLA-04 | Tampering | markdown/JSON divergence | high | mitigate | Byte-exact re-render join plus mutual claim-id coverage in both directions, the same property `verify_window_dispositions.mjs --require-row-join` enforces. |
| T-SLA-05 | Repudiation | waiver abuse | medium | mitigate | `attested` claims require reason, owner, `expires_on`, `approving_sha`; fail past expiry; hard cap of 2 and ≤20% of claims. |
| T-SLA-06 | Denial of Service | evaluator | medium | mitigate | Per-evaluator 10s timeout (capped 60s) and 1 MB buffer; exceeding either is a FAILURE, never a truncated pass. |
| T-SLC-01 | Information Disclosure | packaged tarball / shipped source | high | mitigate | Scope lock: any occurrence outside `.planning/`, or in any path matched by either `mix.exs` `files:` glob, is a hard FAIL. A Hex tarball cannot be unpublished. |
| T-SLC-02 | Information Disclosure | public CI log | medium | mitigate | All gate output redacted to `<REDACTED-ADOPTER-REF>`, plus a self-check over the gate's own assembled output. |
| T-SLC-03 | Information Disclosure | the census manifest itself | medium | mitigate | Obfuscated regex plus SHA-256 of the reconstructed literal; `--require-no-cleartext` fails if the manifest contains the literal. |
| T-SLC-04 | Tampering | census entry repointing | medium | mitigate | `pattern_sha256` tamper-evidence; a pattern matching zero occurrences fails as vacuous. |
| T-SLC-05 | Denial of Service | fork contributions | medium | mitigate | No CI secret used at all, so the gate runs non-vacuously on fork PRs without blocking outside contributors. |
| T-SLF-01 | Information Disclosure | live PR body into a public log | medium | mitigate | Fetched body passes through `assertLeak` and SL-C redaction before printing; diffed lines truncated to 200 chars; token and headers never logged. |
| T-SLF-02 | Elevation of Privilege | workflow permissions widening | low | mitigate | `pull-requests: read` only; no write; no trigger change; interlocked with T-SLA-03. |
| T-ALL-01 | Repudiation | a gate that passes without inspecting anything | high | mitigate | Every guard fails on zero inspected items and prints the count; SL-A carries `--min-executed`, SL-C a zero-match vacuity check, SL-E a zero-Complete-row check, SL-F `--min-declared`, SL-G a zero-pair check. |
| T-ALL-02 | Tampering | npm/pip/cargo installs | n/a | accept | No package-manager install task exists in this plan; every guard uses Node built-ins and `git` only. The shellcheck container dependency was considered and explicitly rejected in SL-D. |
</threat_model>

<verification>
After all seven tasks, the whole set must hold simultaneously:

1. `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` passes over the enlarged cohort, with the floor re-measured.
2. Every new guard's `node --test` run reports a non-zero number of passing assertions. A TAP `# pass 0` is a failure of this plan, not a pass.
3. Every new guard has at least one negative-control scenario proven to FAIL, exercised by the inline `! node ...` commands in each task.
4. No committed string is executed anywhere: `grep -rn "exec(" scripts/ci/render_pr_claims.mjs scripts/ci/verify_pr_claims.mjs` finds no shell-invoking form, and neither file passes `shell: true`.
5. `grep -v '^[[:space:]]*#' .github/workflows/ci.yml | grep -c continue-on-error` does not increase relative to the pre-task baseline. Measure before Task 1 and re-measure after Task 7.
6. The seven new steps all appear in `docs-contracts-shift-left`, and all cheap Node guards precede the `Set up BEAM` step.
7. No new committed artifact contains an adopter reference in cleartext, a credential, a token, or a local home-directory path prefix. Verify with `git --no-optional-locks diff --stat origin/main...HEAD` plus a leak sweep over the changed files using the `UNSAFE_PATH_PATTERN` the existing contract already applies (do not restate the prefixes here — a literal restatement would make this file trip the sweep it describes).
8. No release PR is merged, no package is published, no tag is moved, no remote branch is deleted, and no published history is rewritten. PR #45 IS merged, by the maintainer, as an explicit decision recorded in Task 4's precondition — that is the one exception and it is deliberate.
</verification>

<success_criteria>
- Seven merge-blocking steps exist in `docs-contracts-shift-left`, none `continue-on-error`, with the cheap hermetic guards ordered before the toolchain install.
- A requirement marked Complete without passing verification and a citing UAT/SUMMARY fails the build, in both orphan directions, and a reshaped table fails loudly.
- A claim asserting a false value fails the build; an unknown kind, a flag-like value, or a schema violation fails before any argv is built; and no committed text is ever executed.
- The markdown body re-renders byte-exactly from the typed sidecar, in both claim-id directions.
- A bare local ref in a typed claim field fails with an `origin/`-prefixed remediation.
- The censused token cannot appear outside `.planning/` or in anything packageable, the total may only decrease, a milestone archive move passes unchanged, and every emitted diagnostic is redacted.
- A newly written non-builtin-producer `| grep -q` pipeline under pipefail fails the build, with no shellcheck dependency added.
- A derivation cycle or a non-fixed-point regeneration fails the build, and the live UAT/VERIFICATION cycle is broken at the source.
- A committed PR-body file that drifts from its live PR fails the build; a missing token fails rather than skipping; retries are classified.
- `human_judgment: false` throughout: every acceptance decision is made by an executable assertion.
</success_criteria>

<output>
Write `.planning/quick/260917-l7v-shift-left-phase-232-session-lessons-int/SUMMARY.md` when
done, with `human_judgment: false`, the per-guard live measurements taken during execution
(the census total and file count at the PR #45 merge commit, the idiom offender count, the
re-measured cohort floor, the claim count in the sidecar), and an explicit statement of
which of the seven shipped and which — if any — were dropped and why.

Record in the SUMMARY's deferred list:
- **Full shellcheck adoption across the 53 unlinted shell guards under `scripts/ci`** — a
  substantially larger win than SL-D's single rule. Must travel with the warning that
  shellcheck's own SC2143 actively recommends the footgun SL-D bans, so `disable=SC2143`
  is mandatory in any adoption.
- **Ref renaming for the adopter-named branches** — maintainer-owned, free only at a
  capsule mint, and the only remediation that would actually reduce the SL-C exposure.
</output>

