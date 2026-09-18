---
phase: 231-exact-sha-release-gate-proof
plan: 03
subsystem: infra
tags: [ci, node, dialyzer, docker, playwright, release-gate]

requires:
  - phase: 231-exact-sha-release-gate-proof
    provides: refs/heads/integration/v1.62-candidate (231-01), 231-ROLLBACK-POINT.json (231-01)
provides:
  - scripts/ci/collect_gate01_cohort.mjs (declaredMergeBlockingJobs/annotationSweepNeeds ci.yml parsers, closed COHORT_STATES/LANE_CLASSES lexicon, validateCohortRow/validateGate01Evidence, collectGate01Cohort, assertExactSet)
  - scripts/ci/render_gate01_cohort.mjs (pure renderGate01Cohort, failed-first bucketing, phase231-gate01-cohort splice markers)
  - scripts/ci/verify_gate01_cohort.mjs (--require-cohort-completeness/--require-declaration-drift/--require-exit-codes/--require-clean-checkout/--require-determinism, --fixtures)
  - .planning/phases/231-exact-sha-release-gate-proof/231-GATE-01-EVIDENCE.json and .md (GATE-01 evidence: 11 proved, 1 failed, 1 advisory, 6 non_run/skipped)
affects: [231-05, 231-06, 232]

actuals:
  tokens: 16030
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "declaredMergeBlockingJobs/annotationSweepNeeds parse ci.yml's header comment and the annotation-sweep job's live needs: array respectively -- the declared merge-blocking cohort is never a hand-maintained array literal, always derived and cross-checked (D-09/D-18)"
    - "assertExactSet is one shared missing/extra diff primitive used for both the declaration-drift check and the row-completeness check, so both report the identical missing=[]/extra=[] shape"
    - "Multi-step CI jobs are recorded as a single row whose argv is a `bash -c \"step1 && step2 && ...\"` invocation -- honest about what actually ran sequentially, without needing a per-step sub-schema"

key-files:
  created:
    - scripts/ci/collect_gate01_cohort.mjs
    - scripts/ci/render_gate01_cohort.mjs
    - scripts/ci/verify_gate01_cohort.mjs
    - .planning/phases/231-exact-sha-release-gate-proof/231-GATE-01-EVIDENCE.json
    - .planning/phases/231-exact-sha-release-gate-proof/231-GATE-01-EVIDENCE.md
  modified: []

key-decisions:
  - "The scratch clone checked out the candidate REF's live tip (f524f2a6, resolved via `git rev-parse integration/v1.62-candidate^{commit}`), not the bare merge-commit SHA recorded as candidate_object in 231-ROLLBACK-POINT.json (85aed062) -- the ref's tip is what plan 231-04 actually pushed and dispatched for GATE-02, so GATE-01 and GATE-02 prove the identical SHA."
  - "release-gate is recorded as one row covering 3 of 4 matrix cells (Floor elixir 1.19.0-otp-28, Primary elixir 1.19.5-otp-28, Primary+OpenTelemetry, all required) plus accrue_admin/accrue_portal under Primary -- all exercised clean. The Primary+sigra advisory cell was not exercised (non-blocking, no local proof value)."
  - "Recorded an honest, un-papered-over discrepancy on the release-gate row: this local proof passed every required cell it exercised, while the real GATE-02 GitHub Actions dispatch (plan 231-04, same candidate SHA) reported failures in non-advisory release-gate matrix cells on GitHub-hosted runners. Neither result overrides the other; both are independent evidence. Plausible non-candidate-code causes (local Postgres 14.17 vs ci.yml's postgres:15 service container; macOS/aarch64 vs ubuntu-24.04; a freshly asdf-installed Floor toolchain vs erlef/setup-beam) are named but not eliminated."
  - "docs-contracts-shift-left is recorded failed on its real first-failing step (verify_v1_17_friction_research_contract.sh), matching the fail-fast step order CI itself would have stopped at -- this genuinely reproduces GATE-02's real failure, not a local-only artifact."

patterns-established:
  - "Fifth-generation collect/render/verify triad (gate01 cohort), following the same fail()/fields()/fullSha()/run() primitives and --fixtures/--require-* CLI convention as verify_integration_disposition.mjs / verify_window_dispositions.mjs."

requirements-completed: [GATE-01]

coverage:
  - id: D1
    description: "collect_gate01_cohort.mjs and render_gate01_cohort.mjs: cohort derivation from ci.yml, closed-lexicon validation, and a pure deterministic renderer, each with negative controls for every rejected shape"
    requirement: GATE-01
    verification:
      - kind: unit
        ref: "node --test scripts/ci/collect_gate01_cohort.mjs scripts/ci/render_gate01_cohort.mjs (26 tests)"
        status: pass
      - kind: other
        ref: "node --input-type=module -e \"...\" against the live .github/workflows/ci.yml (13 declared jobs, 12 needs entries)"
        status: pass
    human_judgment: false
  - id: D2
    description: "verify_gate01_cohort.mjs: strict-flag verifier re-deriving completeness/drift live from ci.yml, with a hermetic fixture suite covering every negative control"
    requirement: GATE-01
    verification:
      - kind: other
        ref: "node scripts/ci/verify_gate01_cohort.mjs --fixtures --expected-repository szTheory/accrue --require-cohort-completeness --require-declaration-drift --require-exit-codes --require-clean-checkout --require-determinism"
        status: pass
    human_judgment: false
  - id: D3
    description: "GATE-01 evidence: the declared merge-blocking cohort executed in a fresh cache-free scratch clone at the candidate's live tip, every declared job and out-of-cohort lane recorded with an honest state and evidence"
    requirement: GATE-01
    verification:
      - kind: other
        ref: "node scripts/ci/verify_gate01_cohort.mjs --repo . --records .../231-GATE-01-EVIDENCE.json --rendered .../231-GATE-01-EVIDENCE.md --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-cohort-completeness --require-declaration-drift --require-clean-checkout --require-determinism"
        status: pass
      - kind: other
        ref: "grep -nE '/Users/|/home/|\\$HOME' on both committed evidence files (exit 1, no matches)"
        status: pass
    human_judgment: false

duration: 3h05min
completed: 2026-09-16
status: complete
---

# Phase 231 Plan 3: Exact-SHA Release Gate Proof — GATE-01 Cohort Summary

Authored the fifth collect/render/verify triad (gate01 cohort) and executed the repository's own declared 13-job merge-blocking cohort in a fresh, cache-free scratch clone at the candidate's live tip (`f524f2a6`), producing GATE-01 evidence with 11 proved, 1 failed, 1 advisory, and 6 non_run/skipped rows — honestly including a real docs-contracts-shift-left regression and a documented discrepancy against GATE-02's GitHub-runner findings on `release-gate`.

## Performance

- **Duration:** 3h 05min (paused mid-plan awaiting the Docker daemon; ~2h active compute after resume)
- **Tasks:** 3
- **Files created:** 5

## Accomplishments

- `scripts/ci/collect_gate01_cohort.mjs`: `declaredMergeBlockingJobs`/`annotationSweepNeeds` parse the live `ci.yml` header comment and the `annotation-sweep` job's `needs:` array (never a hand-maintained list); `COHORT_STATES`/`LANE_CLASSES`/`COHORT_ROW_FIELDS`/`GATE01_FIELDS` closed enumerations; `validateCohortRow`/`validateGate01Evidence` enforce D-29's exit-code/argv requirements and D-31's absolute-path/home-directory sanitization; `collectGate01Cohort` assembles evidence from caller-supplied per-job results, stamping `observed_at` from the candidate's committer date.
- `scripts/ci/render_gate01_cohort.mjs`: pure `renderGate01Cohort`, buckets `failed` first then `skipped`/`non_run`/`advisory` then collapses `proved` last, every bucket heading renders even at zero rows, fenced by `<!-- phase231-gate01-cohort:start/end -->`.
- `scripts/ci/verify_gate01_cohort.mjs`: five strict flags (`--require-cohort-completeness`, `--require-declaration-drift`, `--require-exit-codes`, `--require-clean-checkout`, `--require-determinism`) re-derive authority live from `ci.yml`, never trusting the record; hermetic `--fixtures` suite covers every negative control named in the plan's acceptance criteria.
- Executed the cohort for real: cloned the local repo (`git clone`, never `git worktree add`) into a scratch directory at `integration/v1.62-candidate`'s live tip; ran every executable merge-blocking job's local-equivalent command from cold — cold Dialyzer PLTs for `accrue`/`accrue_admin` across 3 matrix cells, Playwright/Chromium across 4 browser-gated jobs, a full Docker Compose boot-poll for `host-docker-smoke` (ready at 145s of a 900s budget) — recording argv, exit code, and duration for each.
- Committed `.planning/phases/231-exact-sha-release-gate-proof/231-GATE-01-EVIDENCE.json` (mode 0600) and `.md`: 11 `proved`, 1 `failed` (`docs-contracts-shift-left`, reproducing GATE-02's real finding), 1 `advisory` (`admin-ui-ratchet-guardrails`, its own `continue-on-error: true`), 6 `non_run`/`skipped` (the declared out-of-cohort lanes plus `annotation-sweep`, deferred to GATE-02).

## Task Commits

Each task was committed atomically (TDD gate: RED then GREEN for Tasks 1 and 2):

1. **Task 1 RED:** `daa307a8` (test) — failing tests for collector/renderer, `declaredMergeBlockingJobs` stubbed to throw; `RED_EVIDENCE_OK` confirmed via `gsd_run check tdd-red-evidence`.
2. **Task 1 GREEN:** `0a6da1ae` (feat) — full `collect_gate01_cohort.mjs`/`render_gate01_cohort.mjs` implementation; 25 tests pass.
3. **Task 2 RED:** `29589c82` (test) — failing fixture suite for the verifier, `assertCohortCompleteness` stubbed to throw; `RED_EVIDENCE_OK` confirmed.
4. **Task 2 GREEN:** `9a3d7579` (feat) — full `verify_gate01_cohort.mjs` implementation; hermetic fixture suite passes with all five strict flags.
5. **Task 3:** `b7ab9fd0` (feat) — GATE-01 evidence executed and committed.

## Files Created/Modified

- `scripts/ci/collect_gate01_cohort.mjs` — GATE-01 cohort collector, fifth-generation `scripts/ci/` evidence module.
- `scripts/ci/render_gate01_cohort.mjs` — pure deterministic Markdown renderer.
- `scripts/ci/verify_gate01_cohort.mjs` — strict-flag verifier with hermetic fixtures.
- `.planning/phases/231-exact-sha-release-gate-proof/231-GATE-01-EVIDENCE.json` (mode 0600) — committed evidence.
- `.planning/phases/231-exact-sha-release-gate-proof/231-GATE-01-EVIDENCE.md` — rendered evidence.

## Decisions Made

- Checked out the candidate **ref's live tip** (`f524f2a6`) in the scratch clone, not the bare `candidate_object` merge commit (`85aed062`) recorded in `231-ROLLBACK-POINT.json` — the live tip is what plan 231-04 actually pushed and dispatched to GitHub for GATE-02, so GATE-01 proves the exact same SHA GATE-02 tested.
- `release-gate` is one row covering 3 of 4 matrix cells (Floor, Primary, Primary+OpenTelemetry — all required) plus `accrue_admin`/`accrue_portal` under Primary, all exercised clean; the advisory `sigra` cell was skipped as non-blocking with no local proof value.
- Recorded, rather than suppressed, a real discrepancy: this local GATE-01 proof passed every required `release-gate` cell it exercised, while the real GATE-02 GitHub dispatch (same candidate SHA) reported failures on GitHub-hosted runners. The evidence names plausible non-candidate-code explanations (local Postgres 14.17 vs `postgres:15`, macOS/aarch64 vs `ubuntu-24.04`, a freshly asdf-installed Floor toolchain vs `erlef/setup-beam`) without claiming to have resolved which is the true cause — both results stand as independent evidence per D-22.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Local Postgres databases carried stale schema state from unrelated prior local sessions**
- **Found during:** Task 3, `host-integration`'s `mix verify.full` gate.
- **Issue:** `mix ecto.migrate` failed with `schema "billing" does not exist` against the pre-existing `accrue_host_test` and `accrue_host_dev` databases (both present in `psql -l` from unrelated prior local development on this shared machine, alongside dozens of other unrelated project databases). The migration that creates the `billing` schema was recorded as already-applied in a stale `schema_migrations` table from an earlier, differently-versioned local run.
- **Fix:** `mix ecto.drop --quiet && mix ecto.create --quiet && mix ecto.migrate --quiet` for both `MIX_ENV=test` and `MIX_ENV=dev` before re-running the gate — genuinely fresh state, matching what a real ephemeral `postgres:15` CI service container provides by construction. Not a fix to any candidate code; a fix to this local proof's own environment fidelity (D-13's "no cache" spirit extends to DB state, not just `deps/`/`_build/`).
- **Files modified:** none (database state only, outside the git tree).
- **Verification:** Re-ran `bash scripts/ci/accrue_host_uat.sh`; 219 ExUnit tests + 21 Playwright tests passed.
- **Committed in:** n/a (environment-only fix, no file change; captured in the committed evidence's `proved` `host-integration` row).

**2. [Rule 3 - Blocking] `mix credo --strict` silently ran 0 checks under an implicit MIX_ENV**
- **Found during:** Task 3, the Floor release-gate matrix cell.
- **Issue:** Running `mix credo --strict` in a fresh shell without explicitly exporting `MIX_ENV=test` picked up the default `:dev` env for that invocation and printed `Ignoring an undefined check: Accrue.Credo.NoRawStatusAccess` / `running 0 checks on 573 files` — `credo_checks/` is still on `:dev`'s `elixirc_paths`, but the custom check module hadn't been (re)compiled into that env's `_build` yet in that fresh shell.
- **Fix:** Re-ran `mix compile --warnings-as-errors` then `mix credo --strict` with `MIX_ENV=test` explicitly exported; confirmed `running 1 check on 573 files`, matching every other cell.
- **Files modified:** none.
- **Verification:** Re-run output shows the custom check active and `found no issues`, identical to the Primary and Primary+OpenTelemetry cells.
- **Committed in:** n/a (a shell/environment mistake in this executor's own commands, not a repository change).

---

**Total deviations:** 2 auto-fixed (both Rule 3 — local execution-environment blockers, neither touching candidate code). **Impact:** Both were necessary corrections to make this local proof genuinely equivalent to a fresh CI runner; neither represents a candidate regression or scope creep.

## Issues Encountered

- **Docker daemon precondition (resolved via checkpoint):** Task 3's precondition (`docker info` exit 0) was unmet at first attempt — the daemon was stopped. Per the executor's precondition protocol this halted with a `checkpoint:human-verify` (`gate="blocking-human"`) rather than proceeding; Tasks 1 and 2 were completed and committed before the halt. The maintainer started Docker Desktop and the coordinator re-verified (`docker info` exit 0, `pg_isready` exit 0) before authorizing resume. Re-verified independently at resume time before any Task 3 work began.
- **Real `docs-contracts-shift-left` regression, recorded not fixed:** `verify_v1_17_friction_research_contract.sh` fails with "STATE.md must reference canonical inventory path" — the same job the real GATE-02 GitHub dispatch (plan 231-04) reported as failed. Per plan instruction this is recorded honestly as a `failed` GATE-01 row, not investigated or patched by this plan (D-22: a gate that runs and fails on its merits is a GATE-01 blocker, not a still-open ship window). Disposing this failure is Plan 05's job, not this plan's.
- **`admin-ui-ratchet-guardrails` advisory failure, pre-existing and expected:** `ratchet:ledger:verify-frozen` fails on the known-parked v1.56 ratchet ledger (`frozen:false`); the job's own `continue-on-error: true` (confirmed read live at the candidate SHA) means this is recorded `advisory`, never conflated with a required lane.

## User Setup Required

None — no external service configuration required. (The Docker-daemon precondition was a one-time local environment step the maintainer resolved directly, not an ongoing setup task.)

## Next Phase Readiness

`.planning/phases/231-exact-sha-release-gate-proof/231-GATE-01-EVIDENCE.json`/`.md` are committed and strictly verified (`--require-cohort-completeness`, `--require-declaration-drift`, `--require-clean-checkout`, `--require-determinism` all PASS). `git worktree list` in the subject repository is unchanged (1 row) before and after. The evidence records exactly one real failure (`docs-contracts-shift-left`) and one recorded discrepancy (`release-gate` vs GATE-02's GitHub-runner finding) for Plan 05 to consume when disposing the ship window's `unrun-verify`/blocker rows. `annotation-sweep`'s `non_run` row points explicitly at GATE-02 (already produced by plan 231-04) as its proof.

## Self-Check: PASSED

- `scripts/ci/collect_gate01_cohort.mjs`, `render_gate01_cohort.mjs`, `verify_gate01_cohort.mjs` exist on disk.
- `.planning/phases/231-exact-sha-release-gate-proof/231-GATE-01-EVIDENCE.json` and `.md` exist on disk.
- Commits `daa307a8`, `0a6da1ae`, `29589c82`, `9a3d7579`, `b7ab9fd0` found in `git log --oneline --all`.
- Re-ran all task-level `<acceptance_criteria>` and the plan-level `<verification>` block: all pass (see Accomplishments/Task Commits above for the exact commands and results).

---
*Phase: 231-exact-sha-release-gate-proof*
*Completed: 2026-09-16*
