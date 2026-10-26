# Phase 250: Remote Integration - Research

**Researched:** 2026-10-25
**Domain:** GitHub Actions CI reds on PR #49 (`integration/v1.63-v1.66` -> `main`), head `23bee4949045b7ac9361d954b24497bb749e771b`
**Confidence:** HIGH for the three measured root causes (each reproduced locally and then fixed in a scratch clone). MEDIUM for the not-yet-measured lanes, which can only be measured in CI.

<user_constraints>
## User Constraints (from 250-CONTEXT.md)

### Locked Decisions
- Fix every red at its source. Never weaken, skip or make a gate vacuous. Every contract change needs a positive or negative control (same gate-integrity rules as 249-CONTEXT.md).
- Iterate on the same PR branch: commit locally, re-run the relevant local check, push to `integration/v1.63-v1.66`. Pushes to this PR branch are authorized. Never force-push, never push to `main`, never push tags.
- Visual baselines: look at the CI diff artifacts first. Re-mint through the `accrue_admin_browser.yml` `workflow_dispatch` "Mint visual baselines" job and commit the downloaded artifact ONLY for intentional changes (249-01 CSS guard fixes and 249-09 topbar reflow). Any unintended visual change is a regression to fix in source. Record a classification for every surface that changed.
- SL-F / REL-04: commit the PR body file and keep it byte-identical to the live body (`gh pr edit 49 --body-file <committed file>`). Point the REL-04 step at the new file if the contract requires it. Record the exact 40-hex head SHA in the body when claiming green.
- STATE `current_phase` stays 249 until the same step that mints Phase 250's own VERIFICATION and UAT; then flip to 250.
- Merge (LAND-03) needs a separate explicit maintainer yes: `gh pr merge 49 --merge`, never squash or rebase. The first push run on `main` after merge must be fully green.
- No branch protection on `main` (404), so "required" means every job the PR runs, enforced by discipline.
- No Docker commands on the maintainer's machine. Docker lanes are proven only in CI.
- Shared local Postgres on 5432 is near its connection limit; do not stop the maintainer's apps; use a private scratch Postgres for suites.

### Claude's Discretion
- How to decompose the plans and order the fixes. Expect several push -> measure -> fix iterations. Plans should be loops with a hard success condition: all jobs `success` at the head SHA.

### Deferred Ideas (OUT OF SCOPE)
- Release-please alignment and Hex publishing (Phase 251).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAND-01 | Push to accurately named branch with hygiene check | Already done per CONTEXT (pushed 2026-10-25). Nothing further to research. |
| LAND-02 | Every PR-required `ci.yml` and `accrue_admin_browser.yml` job `success` on the exact head SHA; committed PR-body file matches live body | Sections 1-6 below: root cause and fix for every red, plus the by-design-skipped set and the PR-body file format |
| LAND-03 | Merge commit; first post-merge push run on `main` fully green | "Post-merge push run" section |
</phase_requirements>

## Summary

Three independent root causes explain every measured red. All three are "passes on the maintainer's laptop, fails on a clean Linux runner" environment dependencies in tests or workflow wiring, not product regressions.

1. **RecoveryLiveTest, 8 failures, all release-gate cells.** `accrue_events.inserted_at` is filled by the database default `now()` (transaction-start time) in a `timestamp without time zone` column, so the stored value follows the Postgres *session* TimeZone. The test aligns the fake clock to the second, floored, and the window's `until` is that floored clock. On the maintainer's Postgres (`America/New_York`) the stored timestamps land 4 hours *earlier* than real UTC, so they always fall inside the window. On CI (`postgres:15` image, UTC) the stored timestamp is real UTC time, a fraction of a second *after* the floored `until`, so the 8 events are filtered out and every KPI renders empty. It is a test artifact (clock alignment), not a render timeout. The sibling host test already uses the correct `+ 2` alignment (249-14); the admin copy was missed.
2. **Docs and bash contracts, D-32.** `scripts/ci/test_accrue_host_preview_custody.mjs` (2 subtests) and `test_accrue_host_proof_paths.mjs` (1 subtest) `require()` `examples/accrue_host/playwright.config.js`, which requires `@playwright/test`. The docs-contracts job never runs `npm ci` in `examples/accrue_host`, so the require throws `Cannot find module '@playwright/test'`. They pass locally only because `node_modules` exists. Reproduced in a clean clone of `23bee494`. This red also hid 7 later steps (tokens harness) and gates `host-integration`, `playwright-e2e` and `host-docker-smoke`, which `needs: docs-contracts-shift-left`.
3. **Browser UAT.** The functional suite (`npm run e2e`) PASSED. The only failure is the JS unit test `hook formats a mounted timestamp...` (`accrue_admin/test/js/time_display_test.mjs:89`), which asserts the zone label is not `UTC` but depends on the host timezone (the runner is UTC). Reproduced with `TZ=UTC`. The two later steps (baseline-set check, Phase 211 pixel-diff gate) were SKIPPED, so pixel diffs are unmeasured; they are very likely to fail afterwards (see section 3).

Annotation sweep and "Admin UI ratchet guardrails [parked]" are not independent reds. The sweep failed only on the release-gate annotations. The parked job is `continue-on-error: true` and excluded from the sweep by design.

**Primary recommendation:** fix the three causes in one commit set (admin test clock alignment, `npm ci` in the docs job, pin the timezone in the JS test), push, then iterate on whatever the previously-skipped lanes (pixel-diff gate, host-integration, playwright shards, docker smoke, tokens harness) reveal.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Event timestamp (`inserted_at`) | Database (column default) | App schema (`read_after_writes`) | `now()` default at `accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs:34` |
| Recovery window bounds | API/Backend (LiveView `handle_params`) | Clock abstraction (`Accrue.Clock`) | `window_bounds/1` at `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:263-267` |
| CI environment setup (deps for contract tests) | CI workflow | - | The workflow must install what the contract tests import |
| Pixel baselines | CI (Linux runner) | Repo (committed PNGs) | Baselines must be minted on Linux CI |

## Standard Stack

No new libraries. Tools used by the fixes are already in the repo: ExUnit, `node --test`, Playwright (`@playwright/test ^1.57.0` in `examples/accrue_host/package.json`), `actions/setup-node@v6`.

**Package Legitimacy Audit:** not applicable. No external package is added by any recommended fix (`npm ci` installs the already-locked `examples/accrue_host/package-lock.json`).

## Failure Analysis (one section per red)

### 1. Release gate x4 cells (Floor, Primary, Primary+OTel, Primary+sigra [advisory]), step "Accrue admin test"

**Exact error.** `746 tests, 8 failures`, every failure `Assertion with =~ failed` against a LiveView HTML whose KPI section is empty. Failing tests (file `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`, lines 73, 90, 106, 326, 374, 416, 846, 869). Examples:
- `code: assert html =~ "Recovered MRR (USD)"` (line 83)
- `code: assert html =~ "Monthly recurring revenue observed on recovered subscriptions."` (line 97)
- `code: assert html_30d =~ "$150.00"` (line 438)

The CI log truncates the HTML. The rendered page is the loaded dashboard shell with no KPI cards, i.e. `stats` empty, not a loading or timeout state.

**Root cause (file:line evidence, all opened this session).**
- `[VERIFIED: accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs:34]` `add(:inserted_at, :utc_datetime_usec, null: false, default: fragment("now()"))`. `[VERIFIED: accrue/lib/accrue/events/event.ex:48]` `field(:inserted_at, :utc_datetime_usec, read_after_writes: true)`. So `inserted_at` is set by Postgres, as `now()` = transaction start (the whole ExUnit sandbox transaction), converted to a naive timestamp in the **session TimeZone**.
- `[VERIFIED: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:263-267]` `defp window_bounds("30d") do now = Accrue.Clock.utc_now() ... {since, now}` and `[VERIFIED: accrue_admin/lib/accrue_admin/queries/dunning.ex:237-238]` `defp maybe_until(query, %DateTime{} = until), do: where(query, [event], event.inserted_at <= ^until)`.
- `[VERIFIED: accrue/lib/accrue/processor/fake/state.ex:61]` `@epoch ~U[2026-01-01 00:00:00Z]` (no sub-second part) and `[VERIFIED: accrue/lib/accrue/processor/fake.ex:856-857]` `clock: DateTime.add(clock, seconds, :second)`.
- `[VERIFIED: accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:34-37]`:
  ```elixir
  :ok =
    Accrue.Processor.Fake.advance(
      DateTime.diff(DateTime.utc_now(), Accrue.Clock.utc_now(), :second)
    )
  ```
  `:second` truncates, so the fake clock = `floor(now to the second)`, up to 1 s *behind* real time, while the events carry `inserted_at` = transaction start (earlier than the setup, but still after the floored second in ~99.9% of runs).
- Probe on the maintainer's Postgres (session `America/New_York`) printed `PROBE: {~U[2026-10-25 11:25:40.793826Z], ~U[2026-10-25 15:25:40Z], ...}`: the event's `inserted_at` was **11:25** while the clock was **15:25Z**. The stored value is local time labelled UTC, 4 hours early, always inside the window. That is why it passes locally, and why `TZ=UTC` on the *Node/BEAM process* changes nothing (the server session zone is what matters).

**Which artifact is wrong.** The test (clock alignment is too coarse and is silently TZ-dependent). Secondary, a latent product concern (see Open Question 1).

**Local reproduction (exact CI result).** A private Postgres 15 with `timezone=UTC` reproduces `746 tests, 8 failures` for the full admin suite, and `33 tests, 8 failures` for the file, on the unmodified code. The 8 failing test names match the CI list exactly.
- Private instance recipe: `initdb --auth=trust`, then `pg_ctl ... -o "-p 5432 -k <sockdir> -c listen_addresses=<non-loopback local IP> -c timezone=UTC"` and `PGHOST=<that IP> PGUSER=postgres mix test`. (Postgrex's `PGPORT` was not honoured by the Ecto pool in this setup, the repo kept reaching 5432; binding the scratch server to a different local interface address was the reliable way. Stop it afterwards.)
- Cheaper equivalent that does not need a second server: a scratch copy of the test with `AccrueAdmin.TestRepo.query!("SET TIME ZONE 'UTC'")` at the top of `setup` fails exactly the same 8 tests.
- Injecting a 250 ms delay reproduced only 1 of 8 because it exercises `render_async` timing, which is not the cause. Rule out: `render_async` timeout, locale/ICU/CLDR, ex_money rate retriever (a host log shows the harmless `LANG="C.UTF-8" is not a valid CLDR locale` warning), Postgres version (CI 15, local 14.17 on 5432; both fine once TZ matches).

**Fix.**
1. Test fix (primary), mirroring the existing precedent `[VERIFIED: examples/accrue_host/test/accrue_host_web/live/recovery_analytics_test.exs:14-16]`:
   ```elixir
   clock_shift = DateTime.diff(DateTime.utc_now(), Accrue.Clock.utc_now(), :second) + 2
   :ok = Accrue.Processor.Fake.advance(clock_shift)
   on_exit(fn -> Accrue.Processor.Fake.advance(-clock_shift) end)
   ```
   Replace the existing block at `recovery_live_test.exs:34-37` (keep the comment accurate: it must say "ceil, not floor" and name the session-timezone reason). `Fake.reset/0` in `LiveCase` already resets the clock, so `on_exit` is belt-and-braces; keep it for parity with the host test.
2. Parity pin (so this class cannot hide locally again): add `parameters: [timezone: "UTC"]` to `config :accrue_admin, AccrueAdmin.TestRepo` in `accrue_admin/config/test.exs`. `[VERIFIED in scratch clone]` With only this pin, the unmodified file fails 8/33 on the maintainer's New York server, i.e. local now matches CI. With pin plus the `+ 2` fix: `746 tests, 0 failures` on the same New York server. Consider the same one-line pin for `accrue`, `accrue_portal` and `examples/accrue_host` test configs; I ran portal (111/0) and the full host suite (237/0, scratch DB with `timezone=UTC`) under UTC and both are already green, so those are optional hardening, not required for this phase.

**Proof of fix with a control that can fail.**
- Negative control (must fail): `accrue_admin/config/test.exs` with the pin, test file unmodified -> `33 tests, 8 failures`.
- Positive: pin + `+ 2` -> `746 tests, 0 failures`; also green without the pin (shared server) and under `SET TIME ZONE 'UTC'`.
- Both `+ 1` and `+ 2` pass; use `+ 2` (host precedent, margin against the sub-second tail).

### 2. Docs and bash contracts (shift-left), step "CI script contract (D-32)"

**Exact error.** `ci script contract: FAIL: vacuous or failing under node --test: scripts/ci/test_accrue_host_preview_custody.mjs (exit 1), scripts/ci/test_accrue_host_proof_paths.mjs (exit 1)`. The verifier spawns each cohort file with `node --test` and records `exit` only (`scripts/ci/verify_ci_script_contract.mjs:204-215`), which hides the underlying message.

**Root cause.** `[VERIFIED: scripts/ci/test_accrue_host_proof_paths.mjs:17,26]` the test does `spawnSync("node", ["-e", "require(<examples/accrue_host/playwright.config.js>)"])`, and `[VERIFIED: examples/accrue_host/playwright.config.js:6]` that file does `const { defineConfig, devices } = require("@playwright/test");`. In a clean checkout the failing assertion is `Error: Cannot find module '@playwright/test'` (full text captured from my clean-clone run). The preview-custody test fails in subtests 15 and 17 for the same reason ("direct Playwright config and setup execute the same failing collision preflight", "preview URL fails closed unless the exclusive preservation spec is explicitly selected"). The docs job installs Node (`.github/workflows/ci.yml:98-104`, cache keyed only on `brandbook/tokens/harness/package-lock.json`) but runs `npm ci` only for `brandbook/tokens/harness`, at line 454, AFTER D-32 (lines 447-451).

My earlier hypotheses were wrong: `GITHUB_ACTIONS=true CI=true` does not change the result (28/28 and 6/6 pass with those set), and docker/psql presence is irrelevant because the tests stub docker via a temp `binDir`.

**Which artifact is wrong.** The workflow (environment): the job does not install what its contract tests import.

**Reproduction.** Clean clone at `23bee494`: `node --test scripts/ci/test_accrue_host_preview_custody.mjs` -> 26 pass, 2 fail; `test_accrue_host_proof_paths.mjs` -> 5 pass, 1 fail. After `cd examples/accrue_host && npm ci`: 28/0 and 6/0 and `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` -> `PASS (verified: require-cohort-floor, require-guard-coverage, require-non-vacuity)`. Removing `node_modules` again -> the exact CI FAIL line. (Needs `git remote set-url origin https://github.com/szTheory/accrue.git` in the clone, since the verifier checks the origin repository.)

**Fix.** Add a step before "CI script contract (D-32)" in the `docs-contracts-shift-left` job: `cd examples/accrue_host && npm ci`, and add `examples/accrue_host/package-lock.json` to the `cache-dependency-path` of the "Set up Node" step (it accepts a multi-line list). `npm ci` is lockfile-pinned and does not download browsers. Do NOT stub `@playwright/test` and do not exempt the two files: the tests exist to exercise the real config.

**Unmeasured downstream steps (all skipped by the failure).** `Install tokens harness`, `Regenerate tokens + specimens`, determinism diff, `Verify tokens completeness`, `Verify specimen content coverage`, `Brand<->admin token parity`, `Parity drift detection proof`. I ran the same commands in the clean clone: generate/specimens produce no diff, and verify, verify-specimens, parity and parity-test all print OK. Predicted green.

**Other docs-job steps.** Steps 4-44 passed in CI, including `Committed PR body matches the live PR body (SL-F)` and `Integration PR body contract (REL-04)`. SL-F passes today because `scripts/ci/verify_pr_body_currency.mjs` takes its corpus from `git ls-files "*-INTEGRATION-PR.md"` and `--min-declared 1` is satisfied by the archived v1.62 file (declares PR #45). See section 5.

### 3. Browser UAT (`accrue_admin_browser.yml`)

**Step results.** `Run browser UAT` (`npm run e2e`) = success. `Test Admin hooks and visual baseline set guard` (`node --test test/js/*.mjs`) = failure. `Require complete committed visual baseline set` and `Phase 211 visual regression gate` = skipped. `Mint visual baselines` = skipped by design (`if: github.event_name == 'workflow_dispatch'`).

**Failure A (functional/unit, not visual).** `not ok 50 - hook formats a mounted timestamp and removes status listeners on destroy`, `Expected "actual" to be strictly unequal to: 'UTC'` at `accrue_admin/test/js/time_display_test.mjs:89`. The assertion is `assert.notEqual(zone.textContent, "UTC")`. `[VERIFIED: accrue_admin/assets/js/hooks/time_display.js:20]` `const zone = timeZone || (mode === "utc" ? "UTC" : null) || Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";` so in default (local) mode the label is the host zone, which is `UTC` on the runner. Reproduced: `TZ=UTC node --test test/js/time_display_test.mjs` -> `# fail 1`; `TZ=America/Los_Angeles` -> 8/0. Whole suite under `TZ=UTC`: `68 pass, 1 fail`, only that test.

Fix (test is wrong; hook behaviour is correct): pin the zone in the test file so it cannot depend on the host, e.g. directly after the imports: `process.env.TZ = "America/Los_Angeles";`. `[VERIFIED in scratch copy]` this passes 8/0 under `TZ=UTC`, `America/New_York` and `Asia/Tokyo` (node:test runs each file in its own process, so it does not leak). Control: run the file under `TZ=UTC` with the pin removed (must fail) and with the pin present (must pass).

**Failure B (unmeasured): pixel-diff gate.** I cannot run it (baselines are Linux-specific and Docker is off-limits). Evidence it will fail once reached: baselines were last minted `0197f4ba` (2026-10-10, 243-01) and `git diff --stat 0197f4ba..HEAD -- accrue_admin/lib accrue_admin/assets/css accrue_admin/priv/static` shows 59 files changed, 3422 insertions, 1779 deletions, including `subscriptions_live.ex`, `subscription_live.ex`, `nav.ex`, and `priv/static/accrue_admin.css` changed by ten commits, among them `b396fc16` "quiet shared header utility controls", `c5b25640` "unify page gutters", `66d5b3ce` "unify list controls", `b4a7eeac`, plus 249-01 (`1a755b2d`) and 249-09 (`8b9dc258`). Not all of these are the "intentional" 249-01/249-09 changes named in CONTEXT; the 2026-10-12..10-19 `fix(admin)` series is a larger, earlier set of intentional-looking visual changes.
`[VERIFIED]` `node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop` prints `Found all 12 required visual baselines` (so "Require complete committed visual baseline set" will pass). The gate is `npm run e2e:visual-regression` = `playwright test --project=visual-desktop --workers=1`, 12 PNGs (dashboard, invoices, invoice-detail, subscriptions, subscription-detail, component-kitchen; each light and dark). On failure the workflow uploads `accrue-admin-playwright-report` and `accrue-admin-playwright-traces` (`if: failure()`), which hold the expected/actual/diff PNGs.

Plan for B: fix A and push; the gate then runs. Download the failure artifacts, Read every diff PNG, classify each surface (intentional per 249-01/249-09 or the 10-12..10-19 `fix(admin)` series vs. regression), fix regressions in source, then run the `workflow_dispatch` mint job and commit the `phase211-visual-baselines` artifact only for classified-intentional surfaces.

### 4. Skipped jobs: what gates them

`[VERIFIED: .github/workflows/ci.yml]` corrects the CONTEXT note: only `admin-drift-docs` depends on `release-gate` (line 805).
| Job | `needs` (ci.yml line) | Becomes runnable when |
|-----|----------------------|----------------------|
| Admin drift and docs | `[release-gate]` (805) | all required release-gate cells green |
| Host integration | `[docs-contracts-shift-left]` (1346) | D-32 fix |
| Playwright E2E shards 1-3 | `[host-integration]` (1500) | host-integration green |
| Host Docker boot smoke | `[docs-contracts-shift-left]` (1713) | D-32 fix |
| Annotation sweep | `if: always()`, needs all of the above (1748-1764) | runs always; passes when no un-excluded annotations |
| Mint visual baselines | `workflow_dispatch` only | never on a PR |
| Stripe provider-proof trigger classifier / incident reconciliation / test-mode parity | `if` is `schedule`, `workflow_dispatch` or `push` (lines 56, 1821, 1922) | never on a `pull_request` run |

**Consequence for LAND-02 (maintainer decision D1).** Five skipped jobs can never be `success` on a PR: Mint visual baselines and the three Stripe provider-proof jobs, plus the parked ratchet job which is `continue-on-error` and red by design. The success criterion must be stated as "every job that has a PR-event run path" (list below). Otherwise the phase is unsatisfiable.

PR-required set to drive to `success` at the head SHA: Docs and bash contracts; Release manifest SSOT; iOS offline client; Release gate Floor, Primary, Primary+OTel (and the advisory sigra cell should be made green too, it is the same test); Phase 18 Stripe Tax gate; Admin drift and docs; Admin group contracts (190); Admin hardening guardrails (192); Admin Phase 200 guardrails; Admin UI ratchet self-tests; Host integration; Playwright E2E 1/3, 2/3, 3/3; Host Docker boot smoke; Annotation sweep; Browser UAT.

**Checks I made on skipped lanes (all green):**
- Admin drift and docs: in the clean clone `mix deps.get && mix accrue_admin.assets.build` leaves `git diff` empty for `priv/static/accrue_admin.{css,js}`, so "Ensure committed bundle is fresh" passes. The guide greps are simple string checks.
- Release-gate steps after the admin test that were skipped: locally `mix credo --strict` -> no issues; `MIX_ENV=dev mix docs --warnings-as-errors` OK; `mix dialyzer --format github` -> `Total errors: 0` ("Unnecessary Skips: 1" is a note, not a failure); `mix hex.audit` OK for admin and portal; portal format, compile, `mix test --warnings-as-errors` -> 111/0 (also under a UTC server). The Floor (Elixir 1.19.0) cell cannot be run locally.
- Host: full `examples/accrue_host` `mix test` under a UTC-timezone database on loopback -> `237 tests, 0 failures` (scratch database `accrue_host_test77`, dropped afterwards). `e2e/generated/copy_strings.json` regenerated from the admin copy equals the committed file (no drift; this is the known silent-staleness trap from earlier phases).

**Unmeasurable locally, predicted risk:**
- Host integration runs `scripts/ci/accrue_host_uat.sh` -> `mix verify.full` (`verify.install` mutates files via `accrue.install`, dev-boot, browser lanes). Not run locally. `ACCRUE_HOST_CUSTODY_CI_ABSENT: "1"` is set at job level (ci.yml ~1355, same on playwright-e2e). The absent-mode code path (`scripts/ci/accrue_host_preview_custody.sh:74-103`) runs `docker volume ls` / `docker ps` filters; the runner has Docker with an empty daemon, so "absent" is provable. The 28 custody unit tests (once D-32 is fixed) cover missing-binary and daemon-error paths with stubs. Residual risk: LOW-MEDIUM; first CI measurement is the proof.
- Playwright shards read committed `copy_strings.json` (in sync, above). Residual risk: MEDIUM (never run on these 91 commits).
- Host Docker boot smoke: `docker compose up --build` cold boot with a 900 s wait. Cannot be tested here. Residual risk: MEDIUM.

### 5. SL-F / REL-04 PR-body contract for PR #49

- **SL-F** (`scripts/ci/verify_pr_body_currency.mjs`): corpus = `git ls-files "*-INTEGRATION-PR.md"` (line ~96). A file opts in with front matter `pr: <n>` or one comment `<!-- pr: https://github.com/szTheory/accrue/pull/49 -->` (v1.62 precedent first line: `<!-- pr: https://github.com/szTheory/accrue/pull/45 -->`). The declaration is stripped, and the rest is compared byte-for-byte with the live PR body fetched from the API (needs `secrets.GITHUB_TOKEN`, already wired). A file with no declaration is "unopened" and passes. So a committed `250-INTEGRATION-PR.md` declaring PR 49 is what makes the check cover this PR. The step is invoked with `--require-currency --min-declared 1`.
- Suggested path: `.planning/phases/250-remote-integration/250-INTEGRATION-PR.md` (matches the `*-INTEGRATION-PR.md` glob). Publish with `gh pr edit 49 --body-file <path>`, with the declaration comment included in the file only if `gh` is given the stripped body: the verifier strips the marker from the committed side, so the live body must equal the committed text minus the marker line and following blank lines (`parseDeclaration` removes `COMMENT_PATTERN` and leading newlines). Create the stripped body file for `gh pr edit` and keep the committed file byte-identical to it plus the one marker line. Verify with the same command CI runs.
- **REL-04** (`scripts/ci/verify_pr_body_contract.mjs`): the CI step is hard-wired to `232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md` via `phase_evidence_path.mjs` (ci.yml 417-423). It does not require retargeting to stay green. If the new body should also be shape-checked, add a second invocation (do not replace the v1.62 one, which would drop a standing check). The body shape it enforces: first heading matches `RISK_HEADING_PATTERN` (`/^#{1,3}\s*(risk|what (a )?reviewer would reject|reject this (pr|change|integration) for)/i`); headings `Rollback` and `Scope` exist; one line naming `link` and `diff` plus at least two inline code spans (the provenance-versus-behavior sentence); an inline code span containing `git` inside the Rollback section; line count within 50-80 (`DENSITY_BAND`); no local path (`UNSAFE_PATH_PATTERN`); every `github.com/OWNER/REPO` equals `szTheory/accrue`.
- **SL-A** (`PR claims contract`, ci.yml 138-148) is also hard-wired to the v1.62 `.md` + `.json` pair. A typed JSON claims sidecar for PR #49 is only needed if the maintainer wants SL-A to cover the new body; the body is a deterministic projection of the sidecar via `render_pr_claims.mjs`. Not required for green. Decision D3.
- SL-G (fixed-point/digest) and SL-E (completion evidence) interplay with `current_phase`: unchanged from CONTEXT. Add the new body file and any `covered_files` edits, then recompute digests with the module's own `scanArtifact` + `computeDigest` (AGENTS rule).

### 6. Ratchet [parked] and Annotation sweep

- `Admin UI ratchet guardrails [parked]`: `[VERIFIED: ci.yml:1270]` `continue-on-error: true` at job level. It fails at step "Verify frozen ratchet evidence" (`npm run ratchet:ledger:verify-frozen`) because `ledger.baseline.json` is `frozen:false` by design (waiver row 11 in `.planning/WINDOWS.md`). The jobs API reports it as `failure`, `gh pr checks` shows `fail`, but it does not fail the workflow. Its sibling `Admin UI ratchet self-tests` is blocking and green. Decision D1 covers how to word LAND-02 around this red X.
- `Annotation sweep`: `if: always()`; its output lists only release-gate annotations (the 8 RecoveryLiveTest failures plus `Process completed with exit code 2`) for the three required cells. `ANNOTATION_SWEEP_EXCLUDE: advisory,parked` already excludes the advisory sigra cell and the parked job. It will pass once the release-gate annotations clear, provided no other lane emits a new non-excluded annotation when it first runs. Expect to re-check after the first full run.

## Architecture Patterns

### Fix-loop shape for the plans
```
push fix set -> CI runs
  release-gate (4 cells) --green--> admin-drift-docs
  docs-contracts (D-32 + tokens) --green--> host-integration --> playwright-e2e x3
                                      \--> host-docker-smoke
  Browser UAT: js tests --> baseline-set --> pixel-diff gate --fail--> download diff PNGs
        --> classify per surface --> fix regressions / dispatch mint --> commit PNGs --> push
  Annotation sweep (always) <- needs everything
  gate: every PR-event job == success at head SHA; then SL-F body with the 40-hex SHA
```

### Pattern: deterministic clock alignment with DB-default timestamps
**What:** when events get `inserted_at` from `now()`, align the fake clock by ceiling plus margin and restore it.
**Source:** `examples/accrue_host/test/accrue_host_web/live/recovery_analytics_test.exs:14-16`. Better still for new tests: insert with an explicit `inserted_at` (the `insert_raw_recovery_event/4` helper at `recovery_live_test.exs:961-975` already does this) so the test never depends on the database clock or session zone.

### Anti-Patterns to Avoid
- Judging "passes locally" on a database whose session timezone is not UTC. CI Postgres is UTC.
- Reading `exit 1` from the D-32 verifier as a verdict: it prints no child stderr. Reproduce each cohort file directly in a clean clone.
- Retrying or `retry`-wrapping the 8 tests; they are deterministic, not flaky.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Linux pixel baselines | Mac-minted PNGs | `workflow_dispatch` mint job artifact `phase211-visual-baselines` | Mac baselines fail on Linux 100% |
| PR body currency | A new sync script | `gh pr edit 49 --body-file` + SL-F | Gate already compares bytes |
| Timezone-proof timestamps in tests | Per-test sleeps/delays | explicit `inserted_at` or `+ 2` alignment | A delay only hid 1 of 8 |
| Digest recompute for covered files | Hand-edited digest | `scanArtifact` + `computeDigest` | Repo rule |

## Runtime State Inventory

Not a rename/refactor phase. Omitted.

## Common Pitfalls

### Pitfall 1: Postgres session TimeZone masks the clock bug
**What goes wrong:** the maintainer's server is `America/New_York`; naive timestamps from `now()` land hours in the past, always inside the window.
**How to avoid:** pin `parameters: [timezone: "UTC"]` in the admin test repo config; verify with the unmodified test failing 8/33 first.
**Warning signs:** a test that aligns `Accrue.Clock` to `DateTime.utc_now()` with `:second` truncation.

### Pitfall 2: A cohort verifier that hides the child error
**What goes wrong:** D-32 reports only `(exit 1)`.
**How to avoid:** reproduce in a fresh `git clone` + checkout of the exact SHA; never in the working tree (ignored `node_modules`, `_build`, `deps` mask environment gaps).

### Pitfall 3: Fix-then-find-more
**What goes wrong:** the D-32 red skipped 7 docs steps, and the admin-test red skipped 12 release-gate steps and the portal suite; the Browser UAT JS failure skipped the pixel gate. Each fix exposes the next lane for the first time.
**How to avoid:** budget for at least two more push/measure iterations (pixel gate, host-integration, shards, docker smoke).

### Pitfall 4: Counting by-design skips as failures
See D1. A PR run can never have `success` for dispatch- or push-only jobs.

## Code Examples

### Admin test setup (replace `recovery_live_test.exs:34-37`)
```elixir
# Source: examples/accrue_host/test/accrue_host_web/live/recovery_analytics_test.exs:14-16
clock_shift = DateTime.diff(DateTime.utc_now(), Accrue.Clock.utc_now(), :second) + 2
:ok = Accrue.Processor.Fake.advance(clock_shift)
on_exit(fn -> Accrue.Processor.Fake.advance(-clock_shift) end)
```

### Admin test repo config (parity pin, `accrue_admin/config/test.exs`)
```elixir
config :accrue_admin, AccrueAdmin.TestRepo,
  database: "accrue_admin_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  parameters: [timezone: "UTC"],
  ...
```

### Docs job step (ci.yml, before "CI script contract (D-32)")
```yaml
- name: Install host Playwright config dependencies (D-32 cohort)
  run: cd examples/accrue_host && npm ci
```
and in "Set up Node": `cache-dependency-path` listing both `brandbook/tokens/harness/package-lock.json` and `examples/accrue_host/package-lock.json`.

### JS test pin (`accrue_admin/test/js/time_display_test.mjs`, after imports)
```js
process.env.TZ = "America/Los_Angeles"; // hook default mode reads the host zone; pin it
```

## State of the Art

Not applicable beyond: `actions/setup-node@v6` multi-line `cache-dependency-path` is supported. `[ASSUMED]` (used already in this repo with a single path; multi-line list is documented behaviour, not re-checked this session).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `actions/setup-node@v6` accepts a multi-line `cache-dependency-path` | Fix 2 | Cache key step errors; fall back to a single glob such as `**/package-lock.json` or drop the cache for the extra path |
| A2 | The CI `postgres:15` service image runs with session TimeZone UTC | Fix 1 | The CI numbers (8 failures) match a UTC server exactly when reproduced, so very likely true; if not, the pin still makes behaviour deterministic |
| A3 | Pixel-diff gate will fail on first run | Section 3B | If it passes, no re-mint needed; low cost |
| A4 | host-integration, playwright shards and docker smoke have no further reds | Section 4 | Cannot be measured locally; handled by the iterate loop |

## Open Questions

1. **Product concern: `accrue_events.inserted_at` follows the Postgres session TimeZone.**
   - What we know: the column is `timestamp(6) without time zone` with `DEFAULT now()`; on a server whose session zone is not UTC, the audit ledger stores local time as if UTC (my probe: stored 11:25, real 15:25Z). Any consumer window using `Accrue.Clock`/UTC mis-selects events.
   - What's unclear: whether adopters' servers are UTC (most managed PG are) and whether that justifies a new migration (`DEFAULT (now() AT TIME ZONE 'utc')`) or an app-side timestamp.
   - Recommendation: do NOT fix inside this phase (it is a published-migration change and belongs to a separate decision); record it as a candidate seed/quick task and keep this phase to the test-side fix. Needs the maintainer (D2).
2. **Which of the 2026-10-12..10-19 `fix(admin)` visual changes does the maintainer bless when the pixel gate fails?** Resolve from the diff PNGs at execution time (D4).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Postgres 15 binaries | UTC reproduction | yes | 15.17 (Homebrew), shared server 14.17 | n/a |
| Node | JS/contract tests | yes | v22 line (matches CI) | n/a |
| `gh` CLI | logs/artifacts | yes | - | n/a |
| Docker | host custody, docker smoke, host-integration | not used (policy) | - | CI only |
| Linux Chromium + fonts | pixel gate | no (macOS) | - | CI mint job only |

Scratch resources I created and removed: private Postgres 15 instance (stopped), socket dir, scratch database `accrue_host_test77` (dropped). Scratch artifacts remain under `/private/tmp/claude-501/-Users-jon-projects-accrue/48422f75-2b7f-40b8-aba9-40871881caab/scratchpad/` (`250-research/` logs, `clone/`, `dbg/`). No tracked file in the working tree was modified (`git status` shows only the pre-existing untracked `.planning/milestone.lock`).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (admin/portal/host), `node --test` (JS + CI contracts), Playwright (e2e, pixel gate) |
| Config file | `accrue_admin/config/test.exs`, `accrue_admin/package.json` |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| Full suite command | `cd accrue_admin && mix test --warnings-as-errors` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LAND-02 | Recovery KPI window includes DB-default timestamps under UTC | unit/integration | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` (run against `timezone=UTC`) | yes |
| LAND-02 | D-32 cohort executes with host Node deps | contract | clean clone: `cd examples/accrue_host && npm ci && cd ../.. && node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` | yes |
| LAND-02 | Time-display hook is zone-independent | unit | `for tz in UTC America/New_York Asia/Tokyo; do TZ=$tz node --test accrue_admin/test/js/time_display_test.mjs; done` | yes |
| LAND-02 | Every PR-event job success at head SHA | remote | `gh run view <run> --json jobs` + `gh pr checks 49` | n/a |
| LAND-02 | Committed PR body equals live body | contract | `node scripts/ci/verify_pr_body_currency.mjs --repo . --expected-repository szTheory/accrue --require-currency --min-declared 1` (needs token) | gate exists |

### Sampling Rate
- Per task commit: the relevant quick command above.
- Per wave: admin full suite under a UTC session, JS suite under three TZs, D-32 in a clean clone.
- Phase gate: all PR-event jobs `success` on the recorded 40-hex SHA.

### Wave 0 Gaps
- [ ] Add the UTC parity pin to `accrue_admin/config/test.exs` (also catches this class locally).
- [ ] A recorded negative control for each fix (pin without fix = 8 failures; JS test unpinned under `TZ=UTC` = 1 failure; clean clone without `npm ci` = the D-32 FAIL line).

## Security Domain

`security_enforcement` not disabled. This phase adds no new dependency, endpoint or data path. Relevant controls: publication hygiene already passed (CONTEXT, LAND-01); the PR body must pass `assertLeak` (no local paths) and the sensitive-token census before `gh pr edit`. ASVS V5/V6/V2-V4: not applicable to the changes recommended. Sensitive Stripe fields are untouched.

## Sources

### Primary (HIGH confidence, opened or executed this session)
- CI logs: `gh run view 40204835226 --log-failed`, `gh run view 40204835309 --log-failed`, job/step lists via `gh run view --json jobs`.
- `.github/workflows/ci.yml` (lines 76-104, 138-148, 192-198, 417-423, 447-454, 531-750, 802-832, 1180-1275, 1335-1500, 1497-1600, 1710-1812, 1815-1925), `.github/workflows/accrue_admin_browser.yml` (lines 60-140).
- `scripts/ci/verify_ci_script_contract.mjs:190-222`, `scripts/ci/test_accrue_host_proof_paths.mjs`, `scripts/ci/test_accrue_host_preview_custody.mjs`, `scripts/ci/accrue_host_preview_custody.sh:74-103`, `scripts/ci/verify_pr_body_currency.mjs`, `scripts/ci/verify_pr_body_contract.mjs:56-150`.
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`, `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`, `accrue_admin/lib/accrue_admin/queries/dunning.ex`, `accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs`, `accrue/lib/accrue/events/event.ex`, `accrue/lib/accrue/processor/fake.ex`, `accrue/lib/accrue/processor/fake/state.ex`, `examples/accrue_host/test/accrue_host_web/live/recovery_analytics_test.exs`, `accrue_admin/test/js/time_display_test.mjs`, `accrue_admin/assets/js/hooks/time_display.js`.
- Local experiments: UTC Postgres 15 reproduction (746/8), scratch-clone fixes (746/0), clean-clone D-32 reproduction and fix, `TZ=` matrix for the JS test, admin credo/docs/dialyzer/hex.audit, portal suite, host suite under UTC (237/0), assets rebuild diff-clean, tokens harness commands, copy_strings regeneration diff-clean.

### Secondary / Tertiary
- None. No web sources were needed.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH (no change).
- Root causes 1-3: HIGH (each reproduced, fixed and re-verified in isolation).
- Skipped-lane predictions: MEDIUM/LOW (only CI can measure; Docker prohibited locally).
- Pixel diffs: LOW as to exact surfaces, HIGH that a diff will occur.

**Research date:** 2026-10-25
**Valid until:** until the next push to `integration/v1.63-v1.66` (SHA-bound)

## Maintainer decisions needed

- **D1: Definition of "every PR-required job success".** Mint visual baselines (dispatch-only), the three Stripe provider-proof jobs (push/schedule/dispatch-only) can never be `success` on a PR run, and `Admin UI ratchet guardrails [parked]` is `continue-on-error` and red by design (waiver row 11). Recommend wording LAND-02 over "every job with a `pull_request` run path, excluding the parked lane", and recording the exclusions in the PR body. After merge, the push run on `main` will execute the provider-proof jobs; `live-stripe` needs `STRIPE_TEST_SECRET_KEY` and its tests skip when absent, so confirm what "fully green" means for LAND-03.
- **D2: The session-TimeZone dependence of `accrue_events.inserted_at`** (Open Question 1): defer to a separate seed/quick task, or fix now with a new migration? Recommend defer.
- **D3: Should SL-A (typed claims sidecar) and REL-04 also be extended to the new PR body**, or only SL-F (currency)? Recommend SL-F plus a second REL-04 invocation; SL-A only if cheap.
- **D4: Blessing the 2026-10-12..10-19 `fix(admin)` visual changes** when re-minting, beyond the 249-01 and 249-09 changes named in CONTEXT; resolve per surface from the diff PNGs.
