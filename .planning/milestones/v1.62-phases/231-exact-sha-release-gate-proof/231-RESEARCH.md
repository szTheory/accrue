# Phase 231: Exact-SHA Release Gate Proof - Research

**Researched:** 2026-09-15
**Domain:** Release-gate proof engineering (local CI-equivalent execution, GitHub Actions exact-SHA verification, ship-window disposition) in an existing Elixir/Node evidence-tooling codebase
**Confidence:** HIGH (all claims in this document were re-measured live on 2026-09-15 per D-00; a small number of items are `[ASSUMED]` and are called out explicitly)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Measured Ground Truth (re-measure at plan time — D-00):** every measured value in CONTEXT.md was taken 2026-09-15 and is a binding to re-measure, not a value to copy forward.

**Candidate SHA Identity:** D-01 re-cut the candidate from current milestone HEAD (repoint `integration/v1.62-candidate` to a fresh `--no-ff` merge of `origin/main` cut from milestone HEAD, re-applying the toolchain pin and `config.ex` disjoint-hunk test); D-02 record the re-cut in Phase 231's own evidence, not a Phase 230 addendum; D-03 the re-cut is a precondition task at the very start of the phase; D-04 all Phase 230 shape constraints (single first-parent `--no-ff` merge, `git revert -m 1 C` byte-identical, v1.61 tag/four closure SHAs/`origin/main` all ancestors, `rev-list --count C ^HEAD ^origin/main == 1`) carry forward against the new candidate; D-05 advance-by-merging and merge-back-then-recut are structurally disqualified; D-06 recompute the hazard universe fresh; D-07 re-mint the rollback-point record via scratch `git clone` (never `git worktree add`), `restore_argv` stays an argv array; D-08 re-capture `.tool-versions` on the new candidate as enablement for GATE-01.

**GATE-01 — Local Gate Scope and Environment Purity:** D-09 scope to the repository's own declared merge-blocking cohort per the `ci.yml` header comment; D-10 the Phase-230 thirteen-lane table is a disposition record, not a scope proposal — `mix hex.publish --dry-run` and `gh workflow run ci.yml` are not repository-declared gates, record `non_run`; D-11 credential-gated/scheduler-only/PR-but-not-merge-blocking lanes recorded `skipped`/`non_run` with reason satisfy GATE-01; D-12 run from a scratch `git clone` of the local repository at the exact candidate SHA, never `git worktree add`; D-13 "without ignored caches" is satisfied by construction — rebuild `deps/`, `_build/`, `priv/plts`, built assets fresh; budget cold Dialyzer PLT, Chromium download, running Docker daemon creating a `proxy` network.

**GATE-02 — Exact-SHA GitHub Proof:** D-14 push `integration/v1.62-candidate` to `origin`, then trigger with `gh workflow run ci.yml --ref integration/v1.62-candidate` (separate explicit authorization); push exactly this one branch, no PR; D-15 pushing alone proves nothing — `push:` is filtered to `branches: [main]`; D-16 `workflow_dispatch` is correct because every merge-blocking job gates on `if: github.event_name != 'schedule'`; D-17 the evidence must state its event class explicitly (`workflow_dispatch`-class, distinct from Phase 232's future PR-class proof); D-18 do not ask GitHub what is required — branch protection is 404, rulesets are `[]`; enumerate required set from the in-repo `ci.yml` header declaration and assert it has not drifted from the live job graph; D-19 extend `scripts/ci/collect_ci_baseline.mjs` rather than writing a parallel mechanism; D-20 poll to completion, never dispatch-and-trust, account for dispatch propagation delay, fail closed on queued/cancelled/in-progress; D-21 `live-stripe` only runs on `workflow_dispatch` when `run_live_stripe` is true — an unset dispatch yields honest `skipped`/`non_run`, but the checker must fail closed on any record claiming `proved` without a recorded exit code.

**GATE-03 — Ship-Window Resolution:** D-22 disposition decided by row `kind` (`unrun-verify` rows 1,4,5,7,8,10 vs `deviation` rows 2,3,6,9), not judgment; D-23 "current evidence" means re-derived at the candidate SHA, never the original description copied forward (row 1's chromium-mobile is the proof); D-24 row 5 (billing_facade_test.exs:160) is handled conservatively, never auto-waived — investigate-then-fix-or-block; D-25 WINDOWS.md keeps its terse schema, flip statuses only through `gsd-tools windows waive/fixed`; D-26 richer GATE-03 fields live in a sibling artifact `231-WINDOW-DISPOSITIONS.{json,md}` as a fourth `collect → render → verify` triad, joined 1:1 by row id; D-27 flipping window statuses is safe in routine CI (collect re-derives fresh); D-28 do not touch or re-diff the frozen 229/230 capsules — mint a fresh `231-REPOSITORY-INVENTORY.json` last, after STATE.md/roadmap settle, `chmod 600` before publish (git bundle resets to 0644).

**Evidence Conventions (inherited, non-negotiable):** D-29 Phase 226 proof-state lexicon (`proved`/`failed`/`skipped`/`advisory`/`non_run`; no `deferred`/`n/a`/`green`; no aggregate boolean; `proved` requires recorded exit code); D-30 completeness is exact sorted set/multiset equality recomputed inside the verifier, reuse `exactMap`/`assertSameMultiset`; D-31 render determinism — re-rendering JSON byte-equals committed Markdown, timestamps from `git show -s --format=%cI` of the candidate, allow-listed sanitized fields; D-32 new artifacts resolve through `scripts/ci/phase_evidence_path.mjs`, get a `scripts/ci/README.md` row; D-33 acceptance is fully executable, zero human checkpoints, `behavior_unverified: 0` required.

### Claude's Discretion

- Exact JSON schema field names, artifact filenames, script module decomposition, and renderer layout, provided output is deterministic, sanitized, independently verifiable, and consistent with the 226/229/230 precedent.
- Whether GATE-01, GATE-02, and GATE-03 evidence are three artifacts or fewer, provided each completeness assertion holds independently and each gate's proof is separately readable.
- Task decomposition and ordering within the phase, subject to D-03 (re-cut first) and D-28 (capsule last).
- Whether the required-job drift check (D-18) lives in the new checker or extends an existing `scripts/ci` verifier.

### Deferred Ideas (OUT OF SCOPE)

- Opening the integration pull request, the reviewer risk summary, rollback instructions, and Release Please readiness — Phase 232 (REL-04 / REL-05).
- Classifying and removing untracked files, stale worktrees, debug sessions, and remote maintenance branches (including `origin/phase-226-baseline-5da8e6b88735`) — Phase 232 (HYG-01). `.tool-versions` leaves this untracked set in Phase 231 via D-08.
- Deleting local `main` — Phase 232 (HYG-01).
- Pinning `commit-search-depth` in the release-please workflow — Phase 232.
- Editorial polish of the public CHANGELOG — Phase 232.
- `.planning/v1.61-v1.61-MILESTONE-AUDIT.md` apparent double-prefixed duplicate — recorded by Phase 230, acted on in Phase 232.
- Renaming the two adopter-named refs — maintainer fail-forward, free only at a capsule mint.
- Package publication — outside v1.62 entirely.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GATE-01 | A fresh clean checkout of the exact integration candidate passes the repository's complete local CI-equivalent gates without depending on ignored caches, credentials, or another worktree. | §"CI Cohort Enumeration" gives the exact declared job list and the exact local command per job. §"Local Cost and Environment Prerequisites" gives wall-clock/tooling budget. §"Runtime State Inventory §.tool-versions drift" flags a real blocker to fix before a scratch-clone run can succeed. |
| GATE-02 | Required GitHub Actions checks for the exact candidate SHA are green, and provider lanes retain explicit `proved`/`skipped`/`failed`/`advisory` semantics. | §"GitHub Surface for GATE-02" gives the dispatch/poll mechanics, branch-protection absence, and the `collect_ci_baseline.mjs` extension points (`normalizeRun`, `normalizeJob`, `cohortFingerprint`, `PROVIDER_STATES`). |
| GATE-03 | Every open ship window is fixed or explicitly waived with current evidence, owner, rationale, and release impact. | §"WINDOWS.md Surface" gives the live 10-row state, the exact parser contract, the writer CLI, and live re-derivation results for rows 1 and 5. §"Collect → Render → Verify Triad" gives the reusable helpers for the sibling artifact. |
</phase_requirements>

## Summary

This phase has almost no new-technology risk — every mechanism it needs (dispatch+poll, collect/render/verify triads, ship-window ledger, scratch-clone execution) already exists in this repository and is exercised by Phase 226/229/230. The work is (1) mechanically re-cutting the candidate ref per D-01–D-08, (2) running the *exact* declared merge-blocking cohort — no more, no less — from a scratch clone, (3) dispatching `ci.yml` against the pushed candidate branch and polling to completion with `ci_monitor.cjs watch` (a **read-only** tool; the dispatch itself must go through `gh workflow run`, which `ci_monitor.cjs` deliberately does not wrap), and (4) re-deriving all ten WINDOWS.md rows' current evidence and driving them to fixed/waived through the existing `gsd-tools windows` writer plus a new fourth collect/render/verify triad instance for the richer fields.

Live re-measurement surfaced two material findings the planner must account for. First, the CONTEXT.md `rev-list --left-right --count` figure (`27 / 37`) has already drifted to `27 / 39` and milestone-branch HEAD has moved from `030a3c6e` to `dc8df106` — both are two additional `docs:` commits from this very research/planning session, which is exactly the D-00 "transcription rots" hazard the context predicted. Second, the on-disk untracked root `.tool-versions` (`nodejs 22.14.0` only) is **missing** the `elixir 1.19.5-otp-28` / `erlang 28.5` lines that exist in the candidate's tracked `.tool-versions` (`bab50d92:.tool-versions`) — so the current working tree cannot itself run `mix` without an explicit `ASDF_ELIXIR_VERSION`/`ASDF_ERLANG_VERSION` override, and the re-cut task must make sure the *new* candidate's tracked `.tool-versions` (not the stale untracked root copy) is what actually lands in the scratch clone.

Ad hoc live runs (not a scratch clone, not the candidate SHA — informational only) suggest two of WINDOWS.md's ten rows may already be resolved on current milestone HEAD: row 5's previously-failing test (`billing_facade_test.exs:160`) now passes (1 test, 0 failures, against a live local Postgres), and `mix format --check-formatted` is clean in both `accrue/` and `examples/accrue_host/` — which is the blocker rows 4, 7, and 8 record. This is a *lead*, not proof: GATE-03's own evidence must come from re-derivation inside the actual scratch-clone run at the actual candidate SHA per D-23/D-12, not from a dirty local checkout.

**Primary recommendation:** Treat this phase as evidence-assembly, not build-work — reuse the collect/render/verify triad verbatim a fourth time, use `gh workflow run` (not `ci_monitor.cjs`, which is read-only by design) for the one authorized dispatch, and budget real wall-clock time (cold Dialyzer PLTs × 3 packages, Chromium installs × 2 jobs, a ~900s Docker boot-smoke poll, 3-shard Playwright) for the scratch-clone GATE-01 run.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Candidate ref re-cut (`--no-ff` merge, ancestry gates) | Local Git / CLI scripting | — | Pure git plumbing, no app-tier code; same pattern as Phase 230's `230-02` build. |
| GATE-01 local cohort execution | CI / Build tooling (scratch clone) | Elixir (`mix`)/Node (`npm`) toolchains inside the clone | The cohort is defined by `ci.yml`; execution is orchestration around existing `mix`/`npm`/`bash` commands, not new app logic. |
| GATE-02 dispatch + poll | GitHub Actions (remote) / Node CLI (`gh`, `ci_monitor.cjs`) | `scripts/ci/collect_ci_baseline.mjs` (Node, local) | Dispatch and remote observation are GitHub-tier; normalization and proof-state assignment happen in the existing local Node collector, which is the extension point (D-19). |
| GATE-03 ship-window resolution | `.planning/WINDOWS.md` ledger (data) | Node collect/render/verify triad (`scripts/ci/*.mjs`) | The ledger itself has a fixed 10-column schema (D-25); richer fields live in a new sibling Node-verified JSON/Markdown pair (D-26), following the established triad tier split. |
| Rollback-point re-mint, capsule mint | Node CLI (`scripts/ci/preserve_repository_state.sh`, `collect_repository_inventory.mjs`) | Scratch `git clone` (never worktree) | Same tier and tooling Phase 229/230 already used; D-28 requires the capsule to be minted *last*. |

## Standard Stack

No new libraries are introduced by this phase. All work extends existing `scripts/ci/*.mjs`/`*.sh` tooling, `gh` CLI, and `git` plumbing already present in the repository.

### Core (reused, not new)
| Tool | Version (verified live) | Purpose | Why Standard Here |
|------|--------------------------|---------|--------------------|
| `gh` CLI | authenticated as `szTheory`, token scopes `gist, read:org, read:packages, repo, workflow` [VERIFIED: `gh auth status` output, this session] | Dispatch `ci.yml` (`workflow run`), list/view runs, check-runs | Only tool with `workflow` scope needed to dispatch; `ci_monitor.cjs` is deliberately read-only and does not dispatch. |
| Node.js | required by all `scripts/ci/*.mjs` (no version pin found beyond CI's `node-version: '22'` in `actions/setup-node@v6`) [CITED: `.github/workflows/ci.yml` `docs-contracts-shift-left`/`host-integration` steps] | Run collect/render/verify triads and `ci_monitor.cjs` | Existing convention across Phase 226/229/230. |
| Elixir 1.19.5 / OTP 28.0 | `.tool-versions` on candidate `bab50d92` [VERIFIED: `git show bab50d92:.tool-versions`, this session — `nodejs 22.14.0`, `elixir 1.19.5-otp-28`, `erlang 28.5`] | Run `mix format`/`compile`/`test`/`credo`/`dialyzer`/`docs` for all three packages in the scratch clone | Matches `ci.yml`'s `erlef/setup-beam@v1` pins (`otp-version: '28.0'`, `elixir-version: '1.19.5'`) used in every Elixir-touching job. |

**No `Package Legitimacy Audit` is required** — this phase installs no new external packages; it only runs existing `mix deps.get`/`npm ci` against already-pinned lockfiles inside a scratch clone.

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────┐
                         │  Precondition: re-cut        │
                         │  integration/v1.62-candidate │
                         │  (D-01..D-08)                │
                         └───────────────┬──────────────┘
                                         │ candidate SHA C (frozen)
              ┌──────────────────────────┼───────────────────────────┐
              ▼                          ▼                           ▼
   ┌─────────────────────┐   ┌───────────────────────┐   ┌───────────────────────┐
   │ GATE-01              │   │ GATE-02                │   │ GATE-03                │
   │ scratch git clone    │   │ push C → origin        │   │ re-derive each         │
   │ at C, run declared   │   │ gh workflow run ci.yml │   │ WINDOWS.md row's       │
   │ merge-blocking cohort│   │  --ref C -f run_live_  │   │ current evidence at C  │
   │ (13 jobs; D-09..D-13)│   │  stripe=<bool>         │   │ (D-22..D-24)           │
   └──────────┬───────────┘   │ poll: ci_monitor.cjs   │   └──────────┬─────────────┘
              │                │  watch --sha C         │              │
              │                └───────────┬────────────┘              │
              │                            │ run/job data               │
              │                            ▼ keyed by head_sha           │
              │                ┌───────────────────────┐                │
              │                │ extend                 │                │
              │                │ collect_ci_baseline.mjs│                │
              │                │ normalizeRun/Job,       │                │
              │                │ cohortFingerprint,      │                │
              │                │ PROVIDER_STATES         │                │
              │                └───────────┬─────────────┘                │
              │                            │                              │
              ▼                            ▼                              ▼
   231-GATE-01-EVIDENCE.*      231-GATE-02-EVIDENCE.*         gsd-tools windows waive/fixed
   (new triad or sibling to    (extends 226-style baseline     rewrites WINDOWS.md (terse,
   the WINDOWS ledger; see     JSON+MD; event-class field      D-25); 231-WINDOW-DISPOSITIONS.
   Claude's Discretion)        is first-screenful per §specifics) {json,md} 4th triad instance,
                                                                 joined 1:1 by row id (D-26)
              │                            │                              │
              └────────────────────────────┴──────────────────────────────┘
                                         │
                                         ▼
                         231-REPOSITORY-INVENTORY.json (minted LAST,
                         after STATE.md/roadmap settle — D-28)
```

### Recommended Project Structure

No new top-level structure; new files land in `scripts/ci/` (Node modules following the collect/render/verify naming convention) and `.planning/phases/231-exact-sha-release-gate-proof/` (evidence artifacts), consistent with Phase 226/229/230.

```
scripts/ci/
├── collect_ci_baseline.mjs        # EXTEND (D-19) — do not fork
├── render_ci_baseline.mjs         # reuse triad pattern
├── verify_ci_baseline.mjs         # reuse triad pattern, --fixtures convention
├── collect_window_dispositions.mjs   # NEW — 4th triad instance (naming: discretion)
├── render_window_dispositions.mjs    # NEW
├── verify_window_dispositions.mjs    # NEW
└── phase_evidence_path.mjs        # reuse resolvePhaseEvidencePath for all new artifacts

.planning/phases/231-exact-sha-release-gate-proof/
├── 231-CONTEXT.md
├── 231-RESEARCH.md                (this file)
├── 231-ROLLBACK-POINT.json        # re-minted, supersedes 230's by reference (D-07)
├── 231-GATE-0{1,2}-EVIDENCE.{json,md}   # exact filenames: discretion
├── 231-WINDOW-DISPOSITIONS.{json,md}    # D-26, joined 1:1 by row id to WINDOWS.md
└── 231-REPOSITORY-INVENTORY.json  # minted LAST (D-28)
```

### Pattern 1: Collect → Render → Verify Triad (reuse, 4th instance)

**What:** Every evidence surface in this codebase (226 CI baseline, 229 repository inventory, 230 integration disposition) is built as three files: a `collect_*.mjs` that gathers raw facts (live or fixture) and normalizes them through strict schema validation (`allowedFields`, closed enums), a `render_*.mjs` that deterministically projects the normalized JSON to Markdown, and a `verify_*.mjs` that independently re-derives authority facts and asserts exact equality (`exactMap`/`assertSameMultiset`) against the committed record — plus a `--fixtures` self-test mode that requires no live repository state.

**When to use:** GATE-03's richer fields (D-26) are explicitly specified as a fourth instance of this pattern. GATE-01/GATE-02 evidence should follow the same shape for consistency even though the exact artifact count is discretionary.

**Example (verified signatures, this session):**
```javascript
// Source: scripts/ci/collect_ci_baseline.mjs (read this session)
export function cohortFingerprint(run, jobs = run.jobs || []) {
  const required = jobs.map((job) => normalizedIdentity(job.name, "job.name")).sort();
  const inputs = {
    workflow_revision: String(run.workflow_revision || run.workflow_path || "unknown").replace(/[^a-zA-Z0-9@._/-]/g, "_"),
    event_class: eventClass(run.event),
    branch_class: branchClass(run.event, run.head_branch),
    runner_images: [...new Set(jobs.map((job) => normalizedIdentity(job.runner_image || "unknown", "job.runner_image")))].sort(),
    required_job_set: required,
    provider_configuration_class: eventClass(run.event) === "schedule" ? "provider_only" : "full_ci"
  };
  return `cohort-v1-${hash(JSON.stringify(inputs))}`;
}

export function normalizeRun(run, validationContext) { /* ... returns { schema_version, kind: "run", run_id, run_url, sha, created_at, started_at, completed_at, event_class, branch_class, cohort_fingerprint, workflow_duration_ms, conclusion, run_attempt, original_run_id, provider_state } */ }
export function normalizeJob(job, run, validationContext, completedByName = new Map()) { /* ... returns { schema_version, kind: "job", run_id, job_id, job_url, job_name, stable_identity, matrix_identity, started_at, completed_at, conclusion, duration_ms, runner_queue_ms, dag_wait_ms, failure_signature, setup_costs, cache } */ }

const PROVIDER_STATES = new Set(["proved", "failed", "misconfigured", "blocked", "skipped", "non_run"]); // D-19's "closed provider_state enum with no success/green alias reachable"
```

```javascript
// Source: scripts/ci/verify_repository_inventory.mjs (read this session, lines ~50-73)
function exactMap(rows, label, keyOf, valueOf) {
  const result = new Map();
  for (const row of rows) {
    const key = keyOf(row);
    if (result.has(key)) fail(`${label} contains duplicate mapping: ${key}`);
    result.set(key, valueOf(row));
  }
  return result;
}
function assertSameMultiset(authorityName, authority, candidateName, candidate, keyOf) {
  const expected = authority.map(keyOf).sort();
  const actual = candidate.map(keyOf).sort();
  if (expected.length !== actual.length || expected.some((value, index) => value !== actual[index])) {
    fail(`${candidateName} differs from ${authorityName}: expected=[${expected.join(", ")}] actual=[${actual.join(", ")}]`);
  }
}
```

`resolvePhaseEvidencePath(phaseSlug, artifactPath, { root })` [VERIFIED: `scripts/ci/phase_evidence_path.mjs`, read this session] resolves first against `.planning/phases/<phaseSlug>/<artifactPath>`, then falls back to searching every `.planning/milestones/*-phases/<phaseSlug>/<artifactPath>` directory, throwing on zero or multiple matches — this is what makes new 231 artifacts archive-safe (D-32) for free.

### Pattern 2: Read-only monitor vs. mutating dispatch — two different tools

**What:** `scripts/ci/ci_monitor.cjs` exposes exactly three commands — `list`, `inspect`, `watch` [VERIFIED: `scripts/ci/ci_monitor.cjs:13`, read this session — `const COMMANDS = new Set(["list", "inspect", "watch"]);`]. `scripts/ci/README.md` states explicitly: "The monitor is the single supported read-only observation implementation... no command dispatches, reruns, cancels, or otherwise mutates Actions, refs, PRs, or providers." [VERIFIED: `scripts/ci/README.md`, read this session].

**When to use:** The one authorized mutation (D-14's push + dispatch) must go through `gh` directly (`gh workflow run ci.yml --ref integration/v1.62-candidate -f run_live_stripe=<bool>`); all subsequent observation — polling to completion, listing runs, inspecting job conclusions — should reuse `ci_monitor.cjs watch`/`inspect`, which already implements the fail-closed deadline semantics D-20 requires.

**Example (verified, this session):**
```javascript
// Source: scripts/ci/ci_monitor.cjs (read this session)
const UNSUCCESSFUL_COMPLETION_EXIT = 69;
// watch: exits 68 on deadline breach ("a response that completed after the deadline must not be reported as success")
// watchSha(adapter, options, { now = () => performance.now(), sleep = () => {} })
```
`watch`'s CLI options (from `parseArgs`, read this session): `--repo` (must equal the hardcoded `szTheory/accrue`), `--sha` (full lowercase 40-hex, `FULL_SHA` regex), `--workflow`, `--timeout-seconds` (max `MAX_TIMEOUT_SECONDS = 3600`), `--poll-seconds` (max `MAX_POLL_SECONDS = 300`), `--format json` default.

### Pattern 3: `directShipWindows` — the exact 10-column WINDOWS.md parser

**What:** `verify_repository_inventory.mjs::directShipWindows` reads `.planning/WINDOWS.md`, requires the exact header string `"| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |"`, requires every non-separator row to have exactly 10 pipe-delimited columns with `status` in `["open", "waived", "fixed"]`, and cross-checks the four frontmatter counts (`total_count`, `open_count`, `waived_count`, `fixed_count`) against the parsed rows [VERIFIED: `scripts/ci/verify_repository_inventory.mjs:523-547`, read this session; quoted below verbatim].

```javascript
// Source: scripts/ci/verify_repository_inventory.mjs:523-547 (read this session)
function directShipWindows(repositoryRoot) {
  const filename = path.join(repositoryRoot, ".planning/WINDOWS.md");
  const contents = fs.readFileSync(filename, "utf8");
  if (Buffer.byteLength(contents, "utf8") > 512 * 1024) fail("ship-window authority exceeds its bounded input size");
  const count = (name) => {
    const match = new RegExp(`^${name}:\\s*(\\d+)\\s*$`, "m").exec(contents);
    if (!match) fail(`ship-window authority is missing ${name}`);
    return Number(match[1]);
  };
  const header = "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |";
  const start = contents.indexOf(header);
  if (start < 0) fail("ship-window authority is malformed");
  const rows = [];
  for (const line of contents.slice(start + header.length).trimStart().split("\n")) {
    if (!line.startsWith("|")) break;
    const columns = line.split("|").slice(1, -1).map((item) => item.trim());
    if (columns.every((item) => /^-+$/.test(item))) continue;
    if (columns.length !== 10 || !/^\d+$/.test(columns[0]) || !["open", "waived", "fixed"].includes(columns[6])) fail("ship-window authority contains an invalid row");
    rows.push({ id: Number(columns[0]), status: columns[6] });
  }
  const ids = new Set();
  for (const row of rows) { if (ids.has(row.id)) fail("ship-window authority contains duplicate IDs"); ids.add(row.id); }
  if (count("total_count") !== rows.length || count("open_count") !== rows.filter((row) => row.status === "open").length || count("waived_count") !== rows.filter((row) => row.status === "waived").length || count("fixed_count") !== rows.filter((row) => row.status === "fixed").length) fail("ship-window authority counts are inconsistent");
  return rows.sort((left, right) => left.id - right.id).map((row) => `${row.id}:${row.status}`);
}
```

**When to use:** Confirms D-25 — this parser only extracts `id`+`status` from each row and cannot see `owner`/`rationale`/`release impact`. Widening it (adding columns) breaks the 10-column-exact check and cascades into Phase 229/230 fixture golden files, which is exactly why D-26 puts the rich fields in a sibling artifact instead.

### Pattern 4: `gsd-tools windows` ledger writer

**What:** `~/.claude/gsd-core/bin/lib/broken-windows.cjs` exports `markWaived(ledger, id, reason, opts)` and `markFixed`/`cmdWindowsMarkFixed`, invoked via the `gsd-tools windows waive <id> "<reason>"` / `gsd-tools windows fixed <id>` CLI [VERIFIED: `~/.claude/gsd-core/bin/lib/broken-windows.cjs`, grep confirmed this session at lines 58, 68, 277, 289, 1062, 1068]. It rewrites WINDOWS.md deterministically and recomputes all four frontmatter counts. It has no `owner` or `release-impact` column — confirming D-25's "no owner/release-impact columns exist."

**When to use:** This is the *only* supported writer for WINDOWS.md's `status`/`reason`/`resolved_at` columns; the plan must not hand-edit WINDOWS.md.

### Anti-Patterns to Avoid

- **Using `git worktree add` for the scratch clone or the rollback-point revert proof:** The repository inventory verifier (`assertCompleteCategories`) pins an exact `{branch, sha, dirty}` multiset of worktree rows via `assertSameMultiset("captured worktrees...", ..., directWorktreeRecords(repositoryRoot), ...)` [VERIFIED: `scripts/ci/verify_repository_inventory.mjs:583-598`, read this session]. Any added worktree row fails this check on the *next* recapture — D-12/D-07 correctly disqualify `git worktree add` for exactly this reason.
- **Treating `ci_monitor.cjs` as a dispatch tool:** it is read-only by explicit design (`COMMANDS = new Set(["list", "inspect", "watch"])`); the plan must invoke `gh workflow run` separately for D-14's dispatch.
- **Widening WINDOWS.md's column schema for owner/rationale/impact:** breaks `directShipWindows`'s hardcoded 10-column check (D-25).
- **Re-diffing the frozen 229/230 capsules against a changed WINDOWS.md:** D-27/D-28 — those capsules are point-in-time and will legitimately fail exact-equality re-verification once window statuses flip; that is expected, not a regression to chase.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Normalizing GitHub run/job data keyed by `head_sha` | A parallel GATE-02 collector | Extend `scripts/ci/collect_ci_baseline.mjs`'s `normalizeRun`/`normalizeJob`/`cohortFingerprint` (D-19) | Already handles immutable-URL validation, timestamp monotonicity, DAG-wait computation, and the closed `PROVIDER_STATES` enum. |
| Polling a dispatched run to completion with a deadline | A new sleep-loop | `scripts/ci/ci_monitor.cjs watch --sha <candidate-sha>` | Already implements `performance.now()`-based absolute deadlines, exits `68` on deadline breach and `69` on unsuccessful completion — exactly D-20's "fail closed on queued/cancelled/in-progress." |
| Comparing two sets/arrays for exact completeness | Ad hoc `.every`/`.includes` checks | `exactMap`/`assertSameMultiset` from `verify_repository_inventory.mjs`/`verify_integration_disposition.mjs` | Already emit `missing=[...] extra=[...] changed=[...]` triples per D-30. |
| Archive-safe path resolution for new phase evidence | Hardcoded `.planning/phases/231-.../foo.json` paths | `resolvePhaseEvidencePath("231-exact-sha-release-gate-proof", "foo.json")` | Falls back to `.planning/milestones/*-phases/` automatically once the phase archives (D-32). |

**Key insight:** every mechanism GATE-01/02/03 needs already has a working, tested implementation somewhere in `scripts/ci/`. The task is almost entirely "extend/reuse/instantiate a fourth time," not "design something new."

## Runtime State Inventory

> Rename/refactor-adjacent: the candidate ref itself is being re-cut (D-01), so this section audits what depends on the *specific object* being replaced.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no database, collection, or user-id references the candidate SHA by value. | None. |
| Live service config | GitHub Actions run/check-run records are keyed by `head_sha`. Once the candidate is re-cut, its SHA changes, so any prior GATE-02-style dispatch against the superseded `bab50d92` (if one was ever run — none was found: Phase 230's own disposition table records `gh workflow run ci.yml` as `non_run` for all 13 lanes) is void and must be re-run against the new SHA. | Re-dispatch against the re-cut candidate's new SHA; do not reuse any prior run keyed to `bab50d92`. |
| OS-registered state | None found — no Task Scheduler / launchd / pm2 entries reference candidate SHAs. | None. |
| Secrets/env vars | `STRIPE_TEST_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `ACCRUE_LIVE_BASIC_PRICE`, `ACCRUE_LIVE_PRO_PRICE` gate `live-stripe`; presence/absence is a repo secret, not tied to the candidate SHA. `[ASSUMED]` these secrets are configured on `szTheory/accrue` (not independently verified this session — verifying would require either triggering `live-stripe` or a permissions probe outside this phase's scope; D-21 already treats an unset `run_live_stripe` dispatch as an honest `skipped`/`non_run`, so this doesn't block GATE-02). | None required by this phase; `live-stripe` is outside the merge-blocking cohort per D-11 regardless. |
| Build artifacts | The **candidate object itself** (`bab50d92`) is a build artifact of Phase 230 that D-01 explicitly supersedes. `230-ROLLBACK-POINT.json` is a frozen artifact bound to `bab50d92` — D-07 says leave it untouched, supersede by reference, don't edit in place. `origin/phase-226-baseline-5da8e6b88735` remote branch — unrelated stale artifact, Phase 232 HYG-01 territory, not touched here. | Author a **new** `231-ROLLBACK-POINT.json` that references (does not overwrite) `230-ROLLBACK-POINT.json`. |

## Common Pitfalls

### Pitfall 1: Treating CONTEXT.md's measured numbers as still current at plan/execute time

**What goes wrong:** CONTEXT.md's `rev-list --left-right --count` figure (`27 / 37`) and milestone-branch HEAD (`030a3c6e`) are **already stale**, re-measured live this session as `27 / 39` and `dc8df106` respectively — a drift of exactly the two `docs:` commits produced by this research/planning session itself.
**Why it happens:** Every GSD step (including the one producing this RESEARCH.md) advances the active branch, and D-00/D-15(Phase 230) already predicted this — "Phase 230 proved transcription rots (`origin/main` moved mid-discussion; a sixth co-touched file appeared)."
**How to avoid:** Re-run every measurement command listed in CONTEXT.md's "Measured Ground Truth" section again immediately before the re-cut task executes, not at plan time. Do not copy this RESEARCH.md's numbers forward either — they were current at 2026-09-15's research pass, but will drift the moment the phase's own planning commits land.
**Warning signs:** Any plan step that hardcodes `030a3c6e` or `27/37` as a literal comparison target instead of re-invoking `git rev-parse`/`git rev-list` live.

### Pitfall 2: Root `.tool-versions` on disk does not match the candidate's tracked `.tool-versions`

**What goes wrong:** The current untracked working-tree `.tool-versions` contains only `nodejs 22.14.0` [VERIFIED: `Read /Users/dev/projects/accrue/.tool-versions`, this session — full file contents `nodejs 22.14.0`]. The candidate object `bab50d92`'s **tracked** `.tool-versions` contains three lines: `nodejs 22.14.0`, `elixir 1.19.5-otp-28`, `erlang 28.5` [VERIFIED: `git show bab50d92:.tool-versions`, this session]. Running `mix` anything from the bare working tree today fails with "No version is set for command mix" / "No version is set for command erl" until `ASDF_ELIXIR_VERSION`/`ASDF_ERLANG_VERSION` are exported manually — confirmed live this session.
**Why it happens:** `.tool-versions` is untracked on milestone HEAD (per D-00/CONTEXT.md) — it exists only on disk, not in any commit on the milestone branch, so it was never a stable input to the merge that produced `bab50d92`. It looks like it was hand-created at the repo root separately from the candidate's own commit.
**How to avoid:** D-08 already calls for re-capturing `.tool-versions` on the new candidate as "enablement, not hygiene." The plan must verify that whatever ends up in the re-cut candidate's `.tool-versions` (via the toolchain-pin commit D-01 says to re-apply) actually contains the Elixir/Erlang lines — not rely on the stale root file, and not assume `asdf` will silently pick the right version in the scratch clone without it.
**Warning signs:** A scratch-clone GATE-01 run failing at the very first `mix` invocation with "No version is set for command mix."

### Pitfall 3: `ci_monitor.cjs` cannot dispatch — a plan step that assumes it can will silently no-op or error

**What goes wrong:** A task written as "use `ci_monitor.cjs` to trigger and watch the candidate" will fail, because `COMMANDS = new Set(["list", "inspect", "watch"])` has no dispatch verb.
**Why it happens:** The tool was deliberately built read-only (per `scripts/ci/README.md`'s explicit statement) as part of REPO-03's "observable, non-mutating" contract from Phase 229 — dispatch is a *new* authorized capability this phase introduces (D-14), not something the existing monitor was ever meant to do.
**How to avoid:** Two distinct commands: `gh workflow run ci.yml --ref integration/v1.62-candidate -f run_live_stripe=<bool>` for the mutation, then `node scripts/ci/ci_monitor.cjs watch --repo szTheory/accrue --sha <candidate-sha> --workflow CI --timeout-seconds <N> --poll-seconds <N>` for the read-only poll.
**Warning signs:** Any plan step whose only tool reference is `ci_monitor.cjs` for the dispatch step itself.

### Pitfall 4: Dispatch propagation delay — a workflow_dispatch run may not appear immediately

**What goes wrong:** `gh workflow run` returns before the run object exists; querying immediately after can find nothing, and a plan that treats "no matching run found" as "not required" rather than "not yet propagated" will silently under-prove GATE-02.
**Why it happens:** GitHub's dispatch API is asynchronous relative to run-list visibility; D-20 explicitly calls this "dispatch propagation delay."
**How to avoid:** Use `ci_monitor.cjs watch`'s own deadline/retry semantics (it already exists for exactly this) rather than a single-shot `gh run list` check; give it a generous `--timeout-seconds` budget that accounts for both propagation delay and the full cohort's actual runtime (see cost budget below).
**Warning signs:** A GATE-02 evidence record with `provider_state: non_run` purely because the query ran too soon after dispatch, not because the run genuinely didn't happen.

## Code Examples

### Dispatch + poll for GATE-02 (mechanics only — exact flags/thresholds are plan discretion)

```bash
# Source: mechanics synthesized from gh CLI + scripts/ci/ci_monitor.cjs (read this session).
# D-14: push exactly one branch, then dispatch. Do not push main. Do not open a PR.
git push origin integration/v1.62-candidate

# D-16/D-21: workflow_dispatch carries run_live_stripe explicitly; an honest false/unset
# still satisfies GATE-01/02 per D-11/D-21 (live-stripe stays skipped/non_run).
gh workflow run ci.yml --ref integration/v1.62-candidate -f run_live_stripe=false

# D-20: poll to completion, fail closed. --sha must be the full 40-hex candidate SHA
# (ci_monitor.cjs's FULL_SHA regex requires this; a 12-char short SHA is rejected).
node scripts/ci/ci_monitor.cjs watch \
  --repo szTheory/accrue \
  --sha <full-40-hex-candidate-sha> \
  --workflow CI \
  --timeout-seconds 3600 \
  --poll-seconds 30
```

### Local cohort run — one representative job (release-gate's primary compatibility cell)

```bash
# Source: .github/workflows/ci.yml release-gate job steps, transcribed verbatim (read this session).
# Run inside the scratch clone, at the candidate SHA, with the candidate's own .tool-versions.
cd accrue && mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix credo --strict
mix dialyzer --format github
MIX_ENV=dev mix docs --warnings-as-errors
mix hex.audit
```
(Repeat the equivalent block for `accrue_admin/` and `accrue_portal/`, per the job's later steps — read `.github/workflows/ci.yml:255-474` for the full step list including PLT cache and the four `matrix.compatibility` cells, three `required` + one `advisory` sigra cell.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Freeze the Phase-230 candidate (`bab50d92`) as releasable | Re-cut the candidate from current milestone HEAD before proving anything (D-01) | This phase, per the user's explicit context decision | `bab50d92` predates the very verifiers (`verify_integration_disposition.mjs`, `verify_phase230_archive_invariants.mjs`) GATE-01/GATE-02 need to check — proving it releasable would be proving a stale, incomplete SHA. |
| Ask GitHub branch protection what checks are required | Enumerate required checks from the in-repo `ci.yml` header comment and assert no drift from the live job graph (D-18) | Confirmed live this session: `branches/main/protection` → 404, `rulesets` → `[]` | A protection-based checker would silently pass vacuously on this repo (empty required set), which is worse than unavailable — it looks like proof but proves nothing. |

**Deprecated/outdated:** N/A — no external library or API version changes are relevant to this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `STRIPE_TEST_SECRET_KEY`/`STRIPE_WEBHOOK_SECRET`/`ACCRUE_LIVE_BASIC_PRICE`/`ACCRUE_LIVE_PRO_PRICE` are configured as repository secrets on `szTheory/accrue` | Runtime State Inventory — Secrets/env vars | Low — D-21 already makes an unset/false `run_live_stripe` dispatch an honest `skipped`/`non_run`, and `live-stripe` is outside the merge-blocking cohort (D-11) regardless of secret presence. |
| A2 | The two ad hoc local test/format runs performed during this research session (row 5's test passing, both `mix format --check-formatted` clean) will reproduce identically inside a true scratch clone at the re-cut candidate SHA | Summary; Common Pitfalls | Medium — these runs were against the current dirty milestone-HEAD checkout, not a scratch clone at the (not-yet-re-cut) candidate SHA, so they are a *lead* for GATE-03 row 4/5/7/8 triage, not GATE-01/03 evidence. If the scratch-clone run at the actual candidate SHA reproduces a failure, the row(s) stay open per D-22/D-24's conservative handling. |

**If this table is empty:** N/A — see rows above.

## Open Questions

1. **Does the re-cut candidate's toolchain-pin commit actually carry the full three-line `.tool-versions`, or only a subset?**
   - What we know: the *current* candidate `bab50d92`'s tracked `.tool-versions` has all three lines; D-01 says to "re-apply the toolchain pin" when cutting the new merge.
   - What's unclear: whether "re-apply" means cherry-picking the exact same commit (safe) or re-authoring it (risk of dropping a line, as the stale root-level untracked copy already demonstrates is possible).
   - Recommendation: the re-cut task should diff the new candidate's `.tool-versions` against `bab50d92:.tool-versions` and assert byte-identity (or an intentional, justified difference) before any GATE-01 scratch-clone attempt.

2. **What is the actual runtime of a full scratch-clone GATE-01 pass?**
   - What we know: cold Dialyzer PLTs for 3 packages, 2 Chromium installs (`host-integration`, `playwright-e2e` ×3 shards, `admin-group-contracts`, `admin-hardening-guardrails`, `admin-phase200-guardrails` each independently install Chromium), a `host-docker-smoke` job that polls for up to 900 seconds for first boot, and a 4-cell `release-gate` matrix (3 required + 1 advisory) each running full `mix test`+`credo`+`dialyzer` across 3 packages.
   - What's unclear: total wall-clock on the actual execution machine (varies by hardware/network); this session did not attempt the full scratch-clone run (out of scope for research — that's GATE-01's own execution).
   - Recommendation: the plan should budget generously (likely 45–90+ minutes serial, less if jobs are parallelized across separate scratch clones) rather than pick an arbitrary number; see Local Cost and Environment Prerequisites below for the itemized list to parallelize against.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `git` | Re-cut, scratch clone, rollback proof | ✓ | — | — |
| `gh` CLI | GATE-02 dispatch + poll | ✓ | authenticated as `szTheory` [VERIFIED: `gh auth status`, this session] | — |
| Elixir 1.19.5 / OTP 28 via `asdf` | All `mix`-based cohort jobs | ✓ (via `asdf`, not default) | confirmed installable — `asdf` present [VERIFIED: `which asdf` this session] but not auto-selected without `.tool-versions` lines (see Pitfall 2) | Export `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` explicitly, or ensure the scratch clone's own `.tool-versions` is correct (preferred — matches GATE-01's "without ... another worktree / out-of-band operator knowledge" spirit per D-08). |
| Node 22 | `npm ci`/Playwright/token-harness jobs | ✓ | `nodejs 22.14.0` per root `.tool-versions` | — |
| Docker daemon + `proxy` network | `host-docker-smoke` | ✗ (not running at research time — `docker info` failed) [VERIFIED: `docker info` exit non-zero, this session] | — | Must be started before the scratch-clone GATE-01 run reaches `host-docker-smoke`; no fallback — it's a required merge-blocking job (D-09). |
| PostgreSQL (local, port 5432) | `release-gate`, `phase18-tax-gate`, `host-integration`, `playwright-e2e`, `live-stripe` (all use a `postgres:15` service container in CI) | ✓ (locally, via a process already listening on 5432) [VERIFIED: `pg_isready` → "accepting connections", this session] | — | In the scratch clone (matching CI), these jobs expect a `postgres:15` service; a local install works for ad hoc checks (as used in this research pass) but CI parity should use the same `postgres:15` service shape D-13 implies "rebuilt fresh." |

**Missing dependencies with no fallback:**
- Docker daemon must be started before `host-docker-smoke` runs in the scratch-clone GATE-01 pass.

**Missing dependencies with fallback:**
- `.tool-versions`-driven `asdf` auto-selection — falls back to explicit `ASDF_ELIXIR_VERSION`/`ASDF_ERLANG_VERSION` env exports, but see Pitfall 2 for why the *candidate's own* `.tool-versions` should be fixed instead of relying on this fallback for the actual scratch-clone run.

## CI Cohort Enumeration (GATE-01 scope, per D-09)

The `ci.yml` header comment declares this merge-blocking set on `pull_request` [VERIFIED: `.github/workflows/ci.yml:9-14`, read this session, quoted verbatim]:

> `release-manifest-ssot`, `docs-contracts-shift-left`, `release-gate`, `phase18-tax-gate`, `admin-drift-docs`, `admin-group-contracts`, `admin-hardening-guardrails`, `admin-phase200-guardrails`, `admin-ui-ratchet-guardrails`, `host-integration`, `playwright-e2e`, `host-docker-smoke`, `annotation-sweep`.

`annotation-sweep`'s own `needs:` list matches this set exactly (12 entries, `annotation-sweep` itself not self-listed) [VERIFIED: `.github/workflows/ci.yml:1282-1299`, read this session]:
```yaml
needs:
  [
    release-manifest-ssot,
    docs-contracts-shift-left,
    release-gate,
    phase18-tax-gate,
    admin-drift-docs,
    admin-group-contracts,
    admin-hardening-guardrails,
    admin-phase200-guardrails,
    admin-ui-ratchet-guardrails,
    host-integration,
    playwright-e2e,
    host-docker-smoke,
  ]
```
**No drift found** between the header comment's declared list and the live `needs:` graph — both enumerate the same 12 jobs (annotation-sweep is the 13th, itself). This is a positive finding worth recording as GATE-02's `--require-required-job-set-matches-declaration`-style assertion baseline (D-18).

`ios-offline-client` (macOS-15 runner) runs on `pull_request` (`if: github.event_name != 'schedule'`) but is **absent** from `annotation-sweep`'s `needs:` [VERIFIED: grep of the full needs array above + job presence at `.github/workflows/ci.yml:221`] — confirms D-11's claim verbatim.

| Job (YAML key) | Runs where GATE-01 substitute is executed | Exact local-equivalent command(s) |
|---|---|---|
| `release-manifest-ssot` | `accrue/` (needs BEAM 28.0/1.19.5) | `bash scripts/ci/verify_release_manifest_alignment.sh` (after `cd accrue && mix deps.get`) |
| `docs-contracts-shift-left` | repo root + `accrue/`, `brandbook/tokens/harness/` | ~20 `bash scripts/ci/verify_*.sh` + `node scripts/ci/*.mjs --self-test`/`--fixtures`/`--all-since 229` invocations, transcribed verbatim at `.github/workflows/ci.yml:65-220`; includes `node --test scripts/ci/collect_repository_inventory.mjs && ... render_repository_inventory.mjs && ... verify_repository_inventory.mjs`, `node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-complete-categories ...`, `node --test scripts/ci/phase229_gap_closure.test.mjs`, `node --test scripts/ci/verify_phase230_archive_invariants.mjs && ... --fixtures && ...` (bare), and the tokens-harness `npm run generate && npm run specimens && npm run verify && npm run verify-specimens && npm run parity && npm run parity-test`. |
| `release-gate` (4-cell matrix: Floor `required`, Primary `required`, Primary+sigra `advisory`, Primary+opentelemetry `required`) | `accrue/`, `accrue_admin/`, `accrue_portal/` each: format, compile, test, credo, dialyzer, docs, hex.audit | See "Code Examples" block above; repeat per package. |
| `phase18-tax-gate` | `accrue/` | `mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/billing/subscription_test.exs test/accrue/checkout_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/stripe_test.exs` |
| `admin-drift-docs` | `accrue_admin/` | `mix accrue_admin.assets.build` then `git diff --exit-code -- accrue_admin/priv/static/accrue_admin.css accrue_admin/priv/static/accrue_admin.js` |
| `admin-group-contracts` | `accrue_admin/` (Chromium) | `bash scripts/ci/verify_phase190_automation_contract.sh`; `mix compile --warnings-as-errors`; `npm ci`; `npx playwright install --with-deps chromium`; `npm run e2e:group-contracts` |
| `admin-hardening-guardrails` | `accrue_admin/` (Chromium) | `bash scripts/ci/verify_phase192_ci_contract.sh`; compile; `npm run e2e:phase2142`; `bash scripts/ci/verify_phase192_guardrail_contract.sh`; `bash scripts/ci/verify_phase192_admin_guardrails.sh` |
| `admin-phase200-guardrails` | `accrue_admin/` (Chromium) | `bash scripts/ci/verify_phase200_ci_contract.sh`; `bash scripts/ci/verify_phase200_guardrail_contract.sh`; `bash scripts/ci/verify_phase200_admin_guardrails.sh` |
| `admin-ui-ratchet-guardrails` | `accrue_admin/` | `npm run ratchet:ledger:self-test`; `npm run ratchet:ledger:verify-frozen`; `npm run ratchet:signoff:self-test`; `npm run ratchet:signoff`; `npm run ratchet:ci-contract` (**note:** per the `annotation-sweep`'s `ANNOTATION_SWEEP_EXCLUDE: advisory,ratchet` comment, this job is itself non-blocking via its own `continue-on-error` while v1.56 ratchet is PARKED — verify this job's own `continue-on-error:` flag when writing the GATE-01 evidence so it's classified correctly, not silently conflated with the 3 `required` release-gate cells). |
| `host-integration` (needs `docs-contracts-shift-left`) | `examples/accrue_host/` (Postgres service, Chromium) | `bash scripts/ci/accrue_host_uat.sh` (after deps/npm/Chromium install); conditionally `bash scripts/ci/accrue_host_hex_smoke.sh` unless a `release-please--` PR head ref. |
| `playwright-e2e` (needs `host-integration`; 3-shard matrix) | `examples/accrue_host/` (Postgres, Chromium) | `mix compile --warnings-as-errors`; `mix assets.build`; `mix ecto.create/migrate --quiet`; `mix run ../../scripts/ci/accrue_host_seed_e2e.exs`; `npx playwright test --shard=N/3` per shard. |
| `host-docker-smoke` (needs `docs-contracts-shift-left`) | `examples/accrue_host/` (Docker) | `docker network create proxy \|\| true`; `docker compose up --build -d`; poll `curl -fsS http://localhost:4000/` up to 900×1s; `docker compose down --volumes --remove-orphans`. |
| `annotation-sweep` (needs all 12 above) | repo root | `bash scripts/ci/annotation_sweep.sh release-manifest-ssot docs-contracts-shift-left release-gate phase18-tax-gate admin-drift-docs admin-group-contracts admin-hardening-guardrails admin-phase200-guardrails admin-ui-ratchet-guardrails host-integration playwright-e2e host-docker-smoke` with `ANNOTATION_SWEEP_EXCLUDE=advisory,ratchet` and `ANNOTATION_SWEEP_IGNORE_MESSAGE='first\.\.last inside match is deprecated'` — this reads recorded run annotations, so its local-equivalent form needs discretion (it may only be meaningfully runnable against the real GATE-02 dispatch's annotations, not a bare scratch-clone run; flag for planner). |

**Non-declared lanes present in `ci.yml` but outside the merge-blocking cohort (D-10/D-11), record as explicit `non_run`/`skipped` rows with reason:**
- `provider-proof-trigger` — scheduler/dispatch/push only (`if: github.event_name == 'schedule' || 'workflow_dispatch' || 'push'`), not `pull_request`.
- `ios-offline-client` — runs on PRs but absent from `annotation-sweep`'s `needs:` (confirmed above).
- `live-stripe` — gated on `provider-proof-trigger` output + explicit `run_live_stripe` dispatch input; "never runs on pull requests" per its own header comment.
- `provider-proof-incident` — `needs: [provider-proof-trigger, live-stripe]`.
- `mix hex.publish --dry-run` and a bare `gh workflow run ci.yml` — not repository-declared gates at all (D-10).

## GitHub Surface for GATE-02

- `gh auth status` → authenticated as `szTheory`, protocol `https`, token scopes `gist, read:org, read:packages, repo, workflow` [VERIFIED, this session]. The `workflow` scope is required for `gh workflow run`.
- `gh api repos/szTheory/accrue/branches/main/protection` → `404 {"message":"Branch not protected", ...}` [VERIFIED, this session — unchanged from CONTEXT.md].
- `gh api repos/szTheory/accrue/rulesets` → `[]` [VERIFIED, this session — unchanged from CONTEXT.md].
- `on:` triggers [VERIFIED: `.github/workflows/ci.yml:20-34`, read this session]: `push: branches: [main]`; `pull_request: branches: [main]`; `workflow_dispatch: inputs: run_live_stripe { type: boolean, required: true, default: true }`; `schedule: cron: '0 6 * * *'`.
- Every merge-blocking job carries `if: github.event_name != 'schedule'` (confirmed present on `docs-contracts-shift-left`, `release-gate`, `phase18-tax-gate`, `host-integration`, `playwright-e2e`, `host-docker-smoke`, `annotation-sweep`, `ios-offline-client`, `release-manifest-ssot` — all read this session) — a `workflow_dispatch` run therefore executes the identical merge-blocking job set a `pull_request` would (D-16).
- `live-stripe`'s own `if:` [VERIFIED: `.github/workflows/ci.yml:1349`]: `needs.provider-proof-trigger.outputs.should_run == 'true' && (event_name == 'schedule' || event_name == 'push' || (event_name == 'workflow_dispatch' && inputs.run_live_stripe))` — confirms D-21 exactly: an unset/false `run_live_stripe` on a manual dispatch means this job doesn't run at all (skipped, not merely non-`proved`).

## WINDOWS.md Surface (GATE-03)

Live state re-measured this session — **unchanged from CONTEXT.md**: `open_count: 10`, `waived_count: 0`, `fixed_count: 0`, `total_count: 10`, all `reason`/`resolved_at` cells empty [VERIFIED: `.planning/WINDOWS.md`, read this session, full contents reproduced below].

| id | phase | kind | file | description (abridged) |
|----|-------|------|------|------|
| 1 | 214.2 | unrun-verify | `examples/accrue_host/e2e/verify01-admin-mobile.spec.js` | "no chromium-mobile project" in checked-in Playwright config |
| 2 | 215 | deviation | `.../CapabilityReportTests.swift` | corrected stale capability case name |
| 3 | 215 | deviation | `.../AccrueOfflineClient.swift` | reducer requires every declared evidence lane |
| 4 | 217 | unrun-verify | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `mix test.all` blocked by unrelated dirty unformatted file |
| 5 | 220 | unrun-verify | `examples/accrue_host/test/accrue_host/billing_facade_test.exs:160` | pre-existing fake subscription uniqueness test failure |
| 6 | 220 | deviation | `accrue/lib/accrue/entitlements/snapshot.ex` | forwarded `:now` option to repository folding |
| 7 | 221 | unrun-verify | `examples/accrue_host` | `mix verify` blocked by unrelated formatting violations |
| 8 | 221 | unrun-verify | `.../layouts.ex` | `mix format --check-formatted` blocked by unrelated formatting |
| 9 | 225 | deviation | `accrue_admin/mix.lock:41` | locked `jose` dependency for clean-checkout Playwright web server |
| 10 | 227 | unrun-verify | `.../227-CI-CRITICAL-PATH.ndjson` | no qualifying successful workflow_dispatch observations |

**Live re-derivation performed this session (informational — NOT a scratch clone at the candidate SHA, see Pitfall/A2):**

- **Row 1** (D-23's own example): `examples/accrue_host/playwright.config.js` line 50 **does** define a `"chromium-mobile"` project [VERIFIED: `grep -n "chromium-mobile\|project" examples/accrue_host/playwright.config.js`, this session — `50:      name: "chromium-mobile",`]. This directly confirms D-23's claim that the recorded blocker no longer describes reality — but per D-22, the row is only `fixed` once the *gate itself* (the `verify01-admin-mobile.spec.js` contract) runs and reports a real outcome at the candidate SHA, not merely because the config now has the project.
- **Row 5**: at current (dirty) milestone HEAD, with a local Postgres already listening (`pg_isready` → accepting connections), `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs:160` → **1 test, 0 failures** [VERIFIED: command run this session, exit output reproduced]. The full file also passes: 18 tests, 0 failures. This is a strong lead that the test may already be fixed, but D-24 requires investigate-then-fix-or-block treatment and D-12/D-23 require the actual evidence to come from the scratch clone at the candidate SHA, not this ad hoc dirty-tree run.
- **Rows 4/7/8** (all "blocked by unrelated formatting violations"): `mix format --check-formatted` is currently clean in both `accrue/` and `examples/accrue_host/` [VERIFIED: both commands run this session, zero output/exit clean]. Same caveat as row 5 — a lead, not GATE-03 evidence.
- **Row 9**: `accrue_admin/mix.lock` line 41 was not independently re-read this session (already cited in CONTEXT.md canonical refs); planner should still re-derive per D-23 rather than trust the citation.
- **Rows 2, 3, 6** (`deviation` kind): per D-22, these close as `fixed` by confirming the change is *still present and intact* at the candidate SHA — this requires a file-content check at the candidate SHA, not a test run; not independently re-verified this session (out of scope for research — GATE-03 execution work).
- **Row 10**: concerns a Phase-227 NDJSON critical-path artifact with no qualifying live observations; this is a data-availability question about historical CI runs, likely resolved (or not) by whatever fresh `workflow_dispatch` history GATE-02 itself produces.

## Local Cost and Environment Prerequisites

- **Cold Dialyzer PLTs** — `release-gate`'s 4 matrix cells × 3 packages (`accrue`, `accrue_admin`, `accrue_portal`) each build a PLT from scratch in a true scratch clone (no cache restore per D-13); this is typically the single most expensive step per package/cell in Elixir CI.
- **Chromium downloads** — `host-integration`, `playwright-e2e` (×3 shards, though shards may share one `npm run e2e:install`), `admin-group-contracts`, `admin-hardening-guardrails`, `admin-phase200-guardrails` each run `npx playwright install --with-deps chromium` fresh (no cache per D-13).
- **Docker daemon + `proxy` network** — required for `host-docker-smoke`; **not running** in this research environment (`docker info` failed) — the scratch-clone GATE-01 run must start it first. The job itself polls up to 900×1s (~15 minutes worst case) for the container to answer `http://localhost:4000/`.
- **PostgreSQL** — every Postgres-dependent job uses a `postgres:15` service container in real CI; a scratch-clone local run needs an equivalent (a local Postgres was already listening on 5432 in this research environment and answered `pg_isready`).
- **Elixir/OTP toolchain** — `asdf` is present, but (per Pitfall 2) the scratch clone's own `.tool-versions` must carry `elixir 1.19.5-otp-28`/`erlang 28.5` or every `mix` invocation fails immediately with "No version is set."
- **Node 22** — required for `npm ci`/Playwright/tokens-harness steps; `asdf`-resolvable from the (currently node-only) root `.tool-versions`.

No further concrete wall-clock estimate is offered beyond the itemization above (Open Question 2) — this session did not execute the full cohort in a scratch clone, and a specific minute figure would be an unverified guess rather than a measured fact.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Node's built-in `node:test` (for `scripts/ci/*.mjs` unit/fixture suites) + ExUnit (`mix test`) for Elixir packages + Playwright for browser E2E |
| Config file | none centralized — each `scripts/ci/*.mjs` is directly executable and self-testing via `--fixtures`/`--self-test` flags; ExUnit config lives in each package's `mix.exs`/`test_helper.exs`; Playwright config at `examples/accrue_host/playwright.config.js` and `accrue_admin/playwright.config.js` |
| Quick run command | `node scripts/ci/<new_script>.mjs --fixtures` (hermetic, no live repo state) |
| Full suite command | The full GATE-01 cohort itself (see CI Cohort Enumeration table) plus the new verifiers' own `--fixtures` self-tests wired into `docs-contracts-shift-left`, following the exact precedent of `verify_phase230_archive_invariants.mjs`'s three-step CI wiring (`node --test ...; ... --fixtures; ...` bare) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GATE-01 | Scratch-clone run of the declared cohort completes and its evidence is captured/verified | integration (self-authored evidence triad) | `node scripts/ci/verify_<gate01-artifact>.mjs --fixtures` then `node scripts/ci/verify_<gate01-artifact>.mjs` (real) | ❌ Wave 0 — new artifact per Claude's Discretion |
| GATE-02 | Dispatch + poll produces `proved`/`skipped`/`failed`/`advisory` per-lane records with no `success`/`green` alias | unit + fixture contract | extend `node --test scripts/ci/collect_ci_baseline.mjs` / `node scripts/ci/verify_ci_baseline.mjs --fixtures` | ✅ (extend existing file, per D-19) |
| GATE-03 | Every WINDOWS.md row is `fixed`/`waived` with a joined 1:1 rich-artifact row (owner/rationale/impact) | unit + fixture contract, 4th triad | `node --test scripts/ci/collect_window_dispositions.mjs` (name: discretion) / `node scripts/ci/verify_window_dispositions.mjs --fixtures` | ❌ Wave 0 — new triad |

### Sampling Rate
- **Per task commit:** run the relevant new/extended verifier's `--fixtures` self-test (hermetic, seconds).
- **Per wave merge:** re-run the real (non-fixture) verifier against the actual committed evidence.
- **Phase gate:** all three gate artifacts pass their strict/real verification; `.planning/WINDOWS.md` shows `open_count: 0`; `231-REPOSITORY-INVENTORY.json` minted last and passes (D-28).

### Wave 0 Gaps
- [ ] GATE-01 evidence collect/render/verify triad (or equivalent) — does not exist yet.
- [ ] GATE-03 `collect_window_dispositions.mjs`/`render_window_dispositions.mjs`/`verify_window_dispositions.mjs` (D-26's 4th triad instance) — does not exist yet.
- [ ] GATE-02 extension to `collect_ci_baseline.mjs` for the required-job-set-drift assertion (D-18) — does not exist yet; Claude's Discretion whether it lives here or in a new checker.
- [ ] `231-ROLLBACK-POINT.json` re-mint script/invocation — reuse Phase 230's pattern (`git revert -m 1` proof in a scratch clone), no new framework needed.

## Security Domain

> `security_enforcement` not found explicitly disabled in `.planning/config.json`; treat as enabled per the reference's default.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | This phase touches no auth surface. |
| V3 Session Management | No | N/A. |
| V4 Access Control | Yes (narrow) | The one authorized remote mutation (D-14's push+dispatch) requires the existing `gh` authenticated session (`workflow` scope); no new access-control surface is introduced. |
| V5 Input Validation | Yes | New collector/verifier code must reuse `allowedFields`/closed-enum validation exactly as the existing triads do (`RUN_INPUT_FIELDS`, `JOB_INPUT_FIELDS`, `PROVIDER_STATES`) rather than accepting free-form JSON. |
| V6 Cryptography | No | N/A — no new secrets or crypto primitives are introduced (existing `sha256` hashing utilities in `scripts/ci/*.mjs` are reused, not hand-rolled). |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Publishing sensitive local paths/actor names in committed evidence | Information Disclosure | `allowedFields` sanitization + D-31's allow-listed fields (no absolute paths, `$HOME`, actor names, adopter identifiers, secrets) — reuse verbatim as the existing triads already do. |
| A checker that vacuously passes on missing GitHub declared-check metadata | Repudiation / false assurance | D-18: never derive the required set from `branches/.../protection` (404) or `rulesets` (`[]`); always derive from the in-repo `ci.yml` header and assert no drift from the live job graph. |
| Publishing the candidate SHA publicly via push (D-14) | (not a STRIDE defect, a deliberate accepted risk) | Explicitly called out as "one-way in practice" in CONTEXT.md D-14 — no mitigation needed beyond the informed, separate authorization already obtained; document as accepted in the phase evidence. |

## Sources

### Primary (HIGH confidence — read directly this session)
- `.github/workflows/ci.yml` (full file structure, all job `if:`/`needs:`/`run:` steps enumerated above)
- `scripts/ci/collect_ci_baseline.mjs`, `scripts/ci/verify_ci_baseline.mjs`, `scripts/ci/verify_repository_inventory.mjs`, `scripts/ci/verify_integration_disposition.mjs`, `scripts/ci/phase_evidence_path.mjs`, `scripts/ci/ci_monitor.cjs`, `scripts/ci/README.md`
- `.planning/WINDOWS.md`
- `~/.claude/gsd-core/bin/lib/broken-windows.cjs` (grep-confirmed exports)
- `examples/accrue_host/playwright.config.js`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs`
- Live `git`/`gh` command output (rev-parse, rev-list, merge-base, diff --stat, auth status, api branch-protection/rulesets) — all re-run this session
- `guides/testing-live-stripe.md`

### Secondary (MEDIUM confidence)
- N/A — no web search was needed; this phase is entirely in-repo evidence engineering with no external library research surface.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- CI cohort enumeration: HIGH — read directly from `ci.yml`, cross-checked header comment against live `needs:` graph, zero drift found.
- Collect/render/verify triad reuse points: HIGH — exact function signatures read from source this session.
- Ship-window current-state re-derivation (rows 1/4/5/7/8): MEDIUM — re-derived live, but against a dirty checkout, not the (not-yet-existing) re-cut candidate's scratch clone; must be re-confirmed at execution time per D-12/D-23.
- Local cost/runtime estimate: LOW-to-none by design — itemized rather than guessed; Docker was unavailable in this research environment so `host-docker-smoke` could not be timed.

**Research date:** 2026-09-15
**Valid until:** Effectively point-in-time — per D-00, every measured fact in this document should be re-verified live immediately before use, not trusted as still current. Treat as valid for guidance/mechanics (script APIs, job graph shape, tool capabilities) for ~30 days; treat all specific SHAs/counts/row-states as stale the moment any further commit lands on the milestone branch.
