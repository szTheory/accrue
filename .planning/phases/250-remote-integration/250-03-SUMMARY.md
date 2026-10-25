---
phase: 250-remote-integration
plan: "03"
subsystem: ci-verdict-and-push-loop
status: complete
completed: 2026-10-25
requirements-completed: []
tags: [ci, push-loop, exact-sha-verdict, pre-push-guard, playwright, negative-control]
key-files:
  created:
    - .planning/phases/250-remote-integration/250-ci-head-status.mjs
    - .planning/phases/250-remote-integration/250-prepush-guard.sh
    - .planning/phases/250-remote-integration/250-CI-LEDGER.md
  modified:
    - .github/workflows/ci.yml
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - examples/accrue_host/lib/accrue_host/ordinary_seed_boundary.ex
    - examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex
    - examples/accrue_host/priv/repo/seeds/ordinary.exs
    - examples/accrue_host/test/ordinary_preview_seed_test.exs
    - examples/accrue_host/e2e
    - .planning/phases/250-remote-integration/250-INTEGRATION-PR.md
key-decisions:
  - "A fix per cause, each with a recorded negative control or a local reproduction that matched CI exactly"
  - "Browser UAT failing only at the Phase 211 pixel gate is the sole permitted remaining red and is handed to 250-04"
  - "No gate weakened: lane-specific preview specs skip only when their own lane's environment is absent; a wrong ordinary base URL still throws"
plan_head_before: e9518246278cd68a67831cd67b887bd8980d3d92
plan_head_after: b9c98b20081841e976586339db47554e40da7179
commits: 19
actuals:
  tokens: 26000
  tasks: 2
  commits: 19
coverage:
  - id: H1
    description: Exact-SHA verdict helper decides LAND-02 mechanically (head_sha equality, latest attempt, pinned job set, D1 exclusions, push-mode baseline comparison)
    requirement: LAND-02
    verification:
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --self-test prints PASS (34 checks): required job failure, skipped, cancelled; missing Playwright shard 2/3; whole workflow run absent; run head_sha differs; unpinned job name; dispatch-only job ran on pull_request; stale attempt (attempt 1 green, latest attempt 2 red); in-progress, queued and missing-while-running exit 2; visual-pending only at the pixel gate; push-mode baseline success job failed, skipped, cancelled, absent, browser path match with absent run"
        status: pass
      - kind: command
        ref: "live negative control: helper --sha 23bee4949045b7ac9361d954b24497bb749e771b --event pull_request returns rc 1 and names Docs and bash contracts (shift-left), Release gate (Floor; elixir=1.19.0 otp=28.0 sigra=off opentelemetry=off) and Browser UAT"
        status: pass
    human_judgment: false
  - id: G1
    description: Pre-push guard with runtime-built positive controls (secret/e-mail/username patterns, large-blob scan, milestone tags) and the Phase 250 gate suite
    requirement: LAND-01
    verification:
      - kind: command
        ref: "bash .planning/phases/250-remote-integration/250-prepush-guard.sh passed before each of the 5 pushes (fast-forward ancestry, current_phase 250, SL-G, SL-E, executable UAT, archive sweep, D-32, Phase 249 artifacts byte-unchanged, covered_files, home paths, SL-C census, secret/PII scan, large blobs, no v1.63-v1.66 tag on origin)"
        status: pass
      - kind: command
        ref: "first guard run refused (its own synthetic e-mail samples matched the scan), proving the scanner finds hits; samples reworked and the allowlisted identities have their own negative control"
        status: pass
      - kind: command
        ref: "! grep -qF \"$(basename \"$HOME\")\" 250-prepush-guard.sh (no username literal)"
        status: pass
    human_judgment: false
  - id: SC1
    description: Publication hygiene holds over every commit pushed so far (23bee494..P)
    requirement: LAND-01
    verification:
      - kind: command
        ref: "bash .planning/phases/250-remote-integration/250-prepush-guard.sh --hygiene-only --range 23bee4949045b7ac9361d954b24497bb749e771b..b9c98b20081841e976586339db47554e40da7179 prints all checks passed (32 commits, 0 secret/e-mail/username hits, 0 home paths, census strict pass, 0 blobs over 1 MiB, 0 milestone tags on origin)"
        status: pass
    human_judgment: false
  - id: SLF
    description: Committed PR #49 body is byte-identical to the live body at every push
    requirement: LAND-01
    verification:
      - kind: command
        ref: "GITHUB_TOKEN=$(gh auth token) node scripts/ci/verify_pr_body_currency.mjs --repo . --expected-repository szTheory/accrue --require-currency --min-declared 1 printed PASS (2 body files, 2 declared, 2 compared) before each push"
        status: pass
    human_judgment: false
  - id: L2
    description: Every PR-path job is success at P, except the Phase 211 pixel gate handed to 250-04
    requirement: LAND-02
    verification:
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha b9c98b20081841e976586339db47554e40da7179 --event pull_request --visual-pending-ok prints GREEN (visual-pending), rc 0, 19 jobs success; without the flag rc 1 with one red, Browser UAT at Phase 211 visual regression gate"
        status: pass
    human_judgment: false
  - id: F4
    description: Source and contract fixes exposed by first-time CI runs of host-integration and the Playwright shards
    requirement: LAND-02
    verification:
      - kind: command
        ref: "OrdinarySeedBoundary: removing the GitHub Actions clause fails the new test (8 tests, 1 failure); restored 8 tests, 0 failures; both ordinary host test files 15/0"
        status: pass
      - kind: command
        ref: "local mirror of the CI host Browser lane (private Postgres, no docker on PATH): before fixes 24 failed, 25 skipped, 32 passed, identical to CI; after fixes 50 passed, 31 skipped, 0 failed; Braintree lane 14 passed"
        status: pass
      - kind: command
        ref: "phase247-time-tracer: pin absent under TZ=UTC fails with the CI string 'Oct 25, 2026, 07:08:49 PM UTC'; pinned passes under TZ=UTC, TZ=Asia/Tokyo and the default zone"
        status: pass
      - kind: command
        ref: "focus ring fix re-verified: accrue_admin e2e:group-contracts 16 passed, e2e:phase199 29 passed, storybook a11y 3 passed, page-flow 7 passed, storybook/theme mix tests 19 tests 0 failures"
        status: pass
      - kind: command
        ref: "local mirror of the playwright-e2e job per shard with the shared proof build path: shard 1 (including dark-theme 238, real-DB search, Braintree ExUnit and lane, Phase 236 x3), shards 2 and 3 (including Braintree): all exit 0"
        status: pass
    human_judgment: false
---

# Phase 250 Plan 03: Verdict Helper, Pre-push Guard and the Push/Measure/Fix Loop

PR #49's head `b9c98b20081841e976586339db47554e40da7179` has every PR-path job `success` on the exact SHA, with the Phase 211 pixel gate the only red (handed to 250-04), after five bounded pushes and eight root-cause fixes.

## What was built

- `250-ci-head-status.mjs`: reads the newest `ci.yml` and `accrue_admin_browser.yml` run whose `head_sha` equals the SHA, judges the latest attempt of each against a pinned job set with the D1 exclusions, and exits 0 / 1 / 2. Push mode compares job by job against a baseline run and applies the browser workflow's path rules. 34 fixture self-tests and a live negative control at `23bee494`.
- `250-prepush-guard.sh`: run before every push. Secret, e-mail and username patterns are assembled at runtime and each has a synthetic positive sample; the username comes from `$HOME`; the large-blob scan and the milestone-tag scan have their own controls.
- `250-CI-LEDGER.md`: per iteration, pushed SHA, run IDs, every non-success job with step, evidence, classification and fix commit.

## The loop (5 of 6 pushes)

| Push | SHA | Result | What it exposed |
|------|-----|--------|-----------------|
| 1 | `bde9ae6c` | RED | First run that reached host-integration: the 246 loopback rule refused the Actions Postgres service container (13 host tests) |
| 2 | `11ede7ff` | RED | First run of the host Playwright lane since the 2026-10-12..19 admin owner-feedback series: 24 failures |
| 3 | `ead4f497` | RED | One left (a UTC-runner timezone assumption); a transient runner loss on the advisory cell |
| 4 | `533d2ded` | RED | First run of the Playwright shards: server cold-compiled inside the 120 s webServer timeout |
| 5 | `b9c98b20` | GREEN (visual-pending) | none |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Guard's own synthetic samples tripped its e-mail scan**
- **Found during:** Task 1, first guard run
- **Fix:** samples assembled from fragments; allowlisted identities got a negative control
- **Commit:** `fix(250-03): guard synthetic samples no longer self-trigger the e-mail scan`

**2. [Rule 1 - Bug] Helper treated jobs blocked on `needs` as missing (red) while the run was still running**
- **Found during:** iteration 1 wait
- **Fix:** a missing required job in a run that is not completed is pending; fixture added
- **Commit:** `docs(250-03): CI ledger iteration 1` (helper change committed with it)

**3. [Rule 1 - Bug] `OrdinarySeedBoundary` refused the GitHub Actions Postgres service container**
- **Fix:** 172.16.0.0/12 accepted only when `GITHUB_ACTIONS=true`; name and role checks unchanged; the refusal message now prints the observed address
- **Commit:** `fix(250-03): accept the GitHub Actions Docker-bridge Postgres in the ordinary seed boundary`

**4. [Rule 1 - Bug] `.ax-link-quiet:focus-visible` removed the outline and added no ring**
- **Fix:** joined the shared `:focus-visible` ring list; committed bundle rebuilt
- **Commit:** `fix(250-03): give quiet admin links the shared keyboard focus ring`

**5. [Rule 1 - Stale contract] 21 host Playwright specs asserted superseded admin UI**
- **Commit:** `fix(250-03): host Playwright specs follow the 2026-10 admin redesign`

**6. [Rule 1 - Bug] Preview and held-out specs threw in the default lane; `test.skip()` ReferenceError in phase247-current-proof**
- **Commit:** `fix(250-03): preview/held-out lane specs skip outside their own lane`

**7. [Rule 1 - Bug] phase246 state fixture passed `__changed__: %{}` to `~H`**
- **Commit:** `fix(250-03): phase246 state fixture renders every dynamic part on update`

**8. [Rule 1 - Bug] phase247 time tracer inherited the host timezone**
- **Commit:** `fix(250-03): pin the phase247 time tracer browser timezone`

**9. [Rule 3 - Blocking] Playwright shard job cold-compiled inside the 120 s webServer timeout**
- **Commit:** `fix(250-03): share one proof build path across the Playwright shard job`

## Known limits

- The advisory sigra Release gate cell lost its runner in iteration 3 (transient, recorded with the check-run annotation); it was `success` in iterations 2, 4 and 5. No `gh run rerun` was spent.
- The shard-job cold-compile timeout could not be reproduced locally (a faster machine finishes inside 120 s); the CI log is the evidence and iteration 5 is the proof.
- `250-04` owns the visual baselines for P. The Browser UAT run `40229480489` holds the diff artifacts.

## Threat Flags

None. The only new trust-boundary surface is the CI-only clause in `OrdinarySeedBoundary`, which keeps the database-name and role checks and is bounded to `GITHUB_ACTIONS=true` and 172.16.0.0/12.

## Self-Check: PASSED

The helper, guard and ledger exist; the ledger names every pushed SHA; P equals the remote head; the verdict helper passes at P with `--visual-pending-ok`.
