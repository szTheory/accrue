# Phase 250 CI ledger (plan 250-03)

Verdict instrument: `250-ci-head-status.mjs --repo szTheory/accrue --sha <sha> --event pull_request` (exact head_sha, latest attempt, pinned job set; parked lane and dispatch-only/Stripe-trio exclusions per D1). Classifications: source bug / workflow env / stale contract / visual-pending / transient.

## Iteration 1 - pushed `bde9ae6cb64734c144706895641e46dbf5cedcb2`

Runs: ci.yml `40213687124`, accrue_admin_browser.yml `40213687112`. Pushed with guard PASS (all 17 checks) and SL-F PASS. First run in which host-integration, playwright shards, host-docker-smoke and admin-drift-docs were reachable.

Verdict: RED (rc 1). 14 jobs `success`, including all four Release gate cells (RecoveryLiveTest fix confirmed), Docs and bash contracts (D-32 fix confirmed), Admin drift and docs, Host Docker boot smoke.

| Job | Conclusion | Failing step | Evidence | Classification | Fix |
|-----|-----------|--------------|----------|----------------|-----|
| Host integration (required deterministic gate) | failure | Run host integration gate (`mix verify.full`) | job 121231467740 log: `237 tests, 13 failures`, all in `OrdinaryPreviewSeedTest` / `OrdinaryPreviewStoryContractTest`, `RuntimeError ordinary preview seed refused: connected Repo is not the isolated ordinary preview database` (`priv/repo/seeds/ordinary.exs:23`) | stale contract: the 246 CR-01 loopback rule in `OrdinarySeedBoundary` refuses a GitHub Actions Postgres service container, whose own address is on the Docker bridge, never loopback. Never exercised in CI before this run. The observed address is inferred, not logged; the next run's refusal message now prints it if the inference is wrong. | `fix(250-03): accept the GitHub Actions Docker-bridge Postgres in the ordinary seed boundary`. 172.16.0.0/12 accepted only when `GITHUB_ACTIONS=true`; name and role checks unchanged. Negative control: clause removed -> `8 tests, 1 failure`; restored -> `8 tests, 0 failures`; both host test files 15/0 locally. Proof for the CI half is the next run. |
| Playwright E2E shards 1/3, 2/3, 3/3 | skipped (job `121232299553`, unexpanded matrix name) | none ran | `needs: host-integration` | downstream of host-integration | none; re-measure |
| Annotation sweep | failure | Sweep release-facing annotations | job 121236407889: all 10 annotations are the host-integration failures above | downstream of host-integration | none |
| Browser UAT (browser workflow) | failure | Phase 211 visual regression gate | `Test Admin hooks and visual baseline set guard` is now success (time_display TZ pin confirmed); only the pixel gate fails. Artifacts downloaded to `$GSD_SCRATCH/ci/40213687112/artifacts/` | visual-pending, owned by 250-04 | none here (no re-mint in 250-03) |
| Admin UI ratchet guardrails [parked] | failure | Verify frozen ratchet evidence | by design, D1 | parked, any conclusion allowed | none |

## Iteration 2 - pushed `11ede7ffab5ee4fbd0862982575b1dcbd52b6206`

Runs: ci.yml `40216216053`, accrue_admin_browser.yml `40216216059`. Guard PASS, SL-F PASS.

Verdict (helper, `--visual-pending-ok`): RED (rc 1). 14 jobs `success` (all four Release gate cells, Docs and bash contracts, Admin drift and docs, Admin group/hardening/phase200 guardrails, ratchet self-tests, Host Docker boot smoke, Phase 18, REL-02, iOS). Browser UAT is visual-pending only (`Phase 211 visual regression gate`; `Test Admin hooks and visual baseline set guard` and `npm run e2e` are success).

| Job | Conclusion | Failing step | Evidence | Classification | Fix |
|-----|-----------|--------------|----------|----------------|-----|
| Host integration | failure | Run host integration gate, phase `browser_playwright` | job 121238966067 log: `64 tests, 0 failures`, `238 tests, 0 failures` (iteration-1 fix confirmed), dev-boot smoke passed, then Playwright `24 failed, 25 skipped, 32 passed` | stale contract (21 specs), source bug (focus ring, 1 spec), test-lane bug (5 specs; two groups overlap in the 24) | see below |
| Playwright E2E shards | skipped | none | needs host-integration | downstream | none |
| Annotation sweep | failure | Sweep release-facing annotations | downstream of host-integration annotations | downstream | none |
| Browser UAT | failure | Phase 211 visual regression gate | only the pixel gate | visual-pending, 250-04 | none here |

The host Playwright lane had never run in CI after the 2026-10-12..19 owner-feedback series, so 24 specs were measured at once. The lane was reproduced locally (private Postgres on 5439, no docker binary on PATH so custody ran in CI-absent mode, no `npm ci` / `playwright install`) and matched CI exactly (`24 failed, 25 skipped, 32 passed`). Each failure was classified from the local DOM:

| Spec(s) | Cause | Class | Fix commit |
|---------|-------|-------|-----------|
| phase233-semantic (focus) | first Tab stop on Home is `.ax-link-quiet` (View events) with `outline: none` and no ring, a keyboard-focus indicator regression | source bug | `fix(250-03): give quiet admin links the shared keyboard focus ring` (app.css + rebuilt bundle; phase199 29 passed, group-contracts 16 passed locally) |
| phase13, 233, 234-admin, 234-post-layout, 237, 238, 239, 244 (x5), 247-time-tracer, verify01-a11y, -mounted, -mobile | assertions on superseded admin UI (Home h1 Recent activity, webhook title, event labels, Reset filters, Invoices h1, window labels, 28px header, elided labels, single event-payload disclosure, ISO in copy control, column and nav labels, webhook-summary-received id) | stale contract | `fix(250-03): host Playwright specs follow the 2026-10 admin redesign` |
| phase245 (route identity), phase246 collection/invoice/current-proof ordinary, phase247-current-proof | specs owned by dedicated preview/held-out configs threw in the default lane (missing preview password / ordinary base URL, env-dependent pure test, `test.skip()` ReferenceError) | test-lane bug | `fix(250-03): preview/held-out lane specs skip outside their own lane` |
| phase246-global-search held-out | fixture `identity_cell/1` used `__changed__: %{}`, so `send_update` kept the first row | source bug (fixture) | `fix(250-03): phase246 state fixture renders every dynamic part on update` |

Post-fix local mirror of the host browser lane: `50 passed, 31 skipped, 0 failed`; Braintree checkout lane `14 passed`; admin group-contracts 16 passed, phase199 29 passed (15 by-design skips), storybook a11y 3 passed, page-flow 7 passed, storybook/theme mix tests 19/0. Lanes not reproducible locally: the post-gate step `Run host Hex smoke` and the CI-only runner environment; their proof is the next run.

## Iteration 3 - pushed `ead4f497c124d4e1bbca2ff313dff76f310231e2`

Runs: ci.yml `40221570264`, accrue_admin_browser.yml `40221570185`. Guard PASS, SL-F PASS.

Verdict (helper, `--visual-pending-ok`): RED (rc 1). 13 jobs `success`. Browser UAT visual-pending only.

| Job | Conclusion | Failing step | Evidence | Classification | Fix |
|-----|-----------|--------------|----------|----------------|-----|
| Host integration | failure | Run host integration gate, phase `browser_playwright` | job 121255538386 log: `64 tests, 0 failures`, `238 tests, 0 failures`, dev boot passed, Playwright `1 failed, 31 skipped, 49 passed` (was 24 failed): only `phase247-time-tracer.spec.js:5`, `expect(time.textContent()).not.toContain("UTC")` received `Oct 25, 2026, 06:47:01 PM UTC` | workflow env: the spec asserts a non-UTC local display but inherited the UTC runner's zone (same class as time_display_test.mjs in 250-02). It passed locally only because the maintainer machine is not UTC; my local mirror ran in the same America/New_York zone and could not see it. | `fix(250-03): pin the phase247 time tracer browser timezone` (`test.use({ timezoneId })`). Negative control reproduces the CI string under `TZ=UTC` with the pin absent; pinned passes under TZ=UTC, Asia/Tokyo and the default zone. |
| Release gate (Primary ... sigra=on ...) [advisory] | failure | steps after setup show no result; job ran 46 minutes | check-run annotation on job 121254067760: "The hosted runner lost communication with the server." Log blob is `BlobNotFound`. The same cell was `success` in iteration 2 and the three non-advisory cells were `success` in this run. | transient (runner infrastructure) | none; no `gh run rerun` spent because the next iteration pushes a new head that re-runs the cell. If it recurs on the next head it is re-examined. |
| Playwright E2E shards | skipped | none | needs host-integration | downstream | none |
| Annotation sweep | failure | Sweep release-facing annotations | downstream (host-integration and the sigra annotation) | downstream | none |

## Iteration 4 - pushed `533d2ded4208d32c982d2e4bb78c8f6dff150eb8`

Runs: ci.yml `40226070833`, accrue_admin_browser.yml `40226070837`. Guard PASS, SL-F PASS.

Verdict (helper, `--visual-pending-ok`): RED (rc 1). 15 jobs `success`, including Host integration (required deterministic gate) for the first time (Playwright lane green, Hex smoke green), all four Release gate cells (the iteration-3 advisory-cell runner loss did not recur), Admin drift and docs, Host Docker boot smoke. Browser UAT visual-pending only.

| Job | Conclusion | Failing step | Evidence | Classification | Fix |
|-----|-----------|--------------|----------|----------------|-----|
| Playwright E2E shard 1/3, 2/3, 3/3 | failure | Run Playwright shard | jobs 121272413476 / 121272412975 / 121272412902: `[WebServer]` output compiles Faker, Oban and the rest of the dependency tree, then `Error: Timed out waiting 120000ms from config.webServer.` No test ran. | workflow env: `playwright.config.js` forces `MIX_BUILD_PATH` into `examples/accrue_host/tmp/accrue-host-proof-<id>` for its server; the job's compile/seed steps filled the default `_build`, so the server cold-compiled everything inside the 120 s timeout. First time this job ever ran (it needs host-integration). | `fix(250-03): share one proof build path across the Playwright shard job` (job env `ACCRUE_HOST_PROOF_RUN_ID` + `MIX_BUILD_PATH`). Local mirror of the whole job: shard 1 incl. dark-theme 238, real-DB search, Braintree ExUnit/lane and the three Phase 236 steps all `0`; shards 2 and 3 incl. Braintree `0`. The timeout itself could not be reproduced locally (a faster machine cold-compiles inside 120 s); the CI log is the evidence and the next run is the proof. |
| Annotation sweep | failure | Sweep release-facing annotations | downstream of the shard failures | downstream | none |
| Browser UAT | failure | Phase 211 visual regression gate | only the pixel gate | visual-pending, 250-04 | none here |

## Iteration 5 - pushed `b9c98b20081841e976586339db47554e40da7179` (P)

Runs: ci.yml `40229480564`, accrue_admin_browser.yml `40229480489`. Guard PASS, SL-F PASS.

Verdict: `250-ci-head-status.mjs --repo szTheory/accrue --sha b9c98b20081841e976586339db47554e40da7179 --event pull_request --visual-pending-ok` prints `GREEN (visual-pending)`, rc 0, 19 jobs `success`. Without `--visual-pending-ok` it is rc 1 with exactly one red, `Browser UAT` at `Phase 211 visual regression gate`.

Every PR-path job is `success` (all four Release gate cells, Docs and bash contracts, Release manifest SSOT, iOS offline client, Phase 18 Stripe Tax gate, Admin drift and docs, Admin group/hardening/phase200 guardrails, ratchet self-tests, Host integration, Playwright E2E shards 1/3 2/3 3/3, Host Docker boot smoke, Annotation sweep). The parked lane `Admin UI ratchet guardrails [parked]` is `failure` by design (D1). The Stripe trio and `Mint visual baselines` are `skipped` as required.

| Job | Conclusion | Failing step | Classification | Fix |
|-----|-----------|--------------|----------------|-----|
| Browser UAT | failure | Phase 211 visual regression gate (every earlier step `success`) | visual-pending, handed to 250-04 | none in 250-03; baselines are minted only after each changed surface is classified (D4) |

Bound: 5 of 6 push iterations used. Hand-off: 250-04 owns the visual baselines for P.

## Iteration 6 (plan 250-04) - pushed `133fafc2b0c4487522eaa40801985518e4d986ec`

Runs: ci.yml `40232857493`, accrue_admin_browser.yml `40232857489`; mint dispatch `40232864961` (headSha equal, `Mint visual baselines` success). Guard PASS, SL-F PASS.

Carried the D4 checker and the Phase 211 anchor fix. At P (`b9c98b20`) the gate had failed before any pixel comparison (`dashboard: rendered timestamp anchor`, 0 found), because 247-03 moved timeline instants into the shared `Timestamp` control.

| Job | Conclusion | Failing step | Evidence | Classification | Fix |
|-----|-----------|--------------|----------|----------------|-----|
| Browser UAT | failure | Phase 211 visual regression gate | now a real pixel comparison: `toHaveScreenshot(dashboard.png)` 71723 px (0.07) different. The anchor and mask assertions pass in CI | visual: baselines from `0197f4ba` predate v1.63-v1.66 and the owner-feedback series | classified per D4 in `250-VISUAL-CLASSIFICATION.md` (10 intentional, 2 unchanged, 0 regressions); intentional PNGs copied from mint run `40232864961` |
| Admin UI ratchet guardrails [parked] | failure | Verify frozen ratchet evidence | by design, D1 | parked | none |

All other PR-path jobs were `success`, or still running when superseded.

## Iteration 7 (plan 250-04) - pushed `74cdd43a48a57ee2ee047293d387093c138da5d8`

Runs: ci.yml `40234321143`, accrue_admin_browser.yml `40234321194`. Guard PASS, SL-F PASS. Carried the 10 re-minted baselines; `250-visual-ledger-check.mjs --base 133fafc2...` PASS.

Verdict: RED (rc 1), 17 jobs `success`. **Browser UAT `success`**: the Phase 211 pixel gate passes on the re-minted baselines.

| Job | Conclusion | Failing step | Evidence | Classification | Fix |
|-----|-----------|--------------|----------|----------------|-----|
| Release gate (Primary dev target; elixir=1.19.5 otp=28.0 sigra=off opentelemetry=off) | failure | Accrue portal test | job 121292519931: `111 tests, 1 failure`, `AddPaymentMethodLiveTest:73` setup `GenServer.call(AccruePortal.BraintreeMox, ...)` `no process`. Same portal code passed at `b9c98b20` | source bug (test support, timing-dependent): `BraintreeMox.ensure_started/0` linked the named Agent to the first test that reset it. ExUnit (`runner.ex` `receive_test_reply`) does not await a finished test's `exit(:shutdown)`, so the next setup can see the dying Agent | `fix(250-04): start the portal Braintree client-token stub unlinked`. Mechanism model: linked 964/2000 next-caller crashes, unlinked 0/2000. accrue_portal 111/0 under seeds 0-4 |
| Admin drift and docs | skipped | none ran | `needs: [release-gate]` | downstream | none |
| Annotation sweep | failure | Sweep release-facing annotations | both annotations are the portal failure above | downstream | none |
| Admin UI ratchet guardrails [parked] | failure | Verify frozen ratchet evidence | by design, D1 | parked | none |

## Iteration 8 (plan 250-04) - pushed `5ad01dee2c70087aa89fafdfb154f6e9d8068277` (P)

Runs: ci.yml `40236926623`, accrue_admin_browser.yml `40236926603`. Guard PASS, SL-F PASS.

Verdict: `250-ci-head-status.mjs --repo szTheory/accrue --sha 5ad01dee2c70087aa89fafdfb154f6e9d8068277 --event pull_request` (no `--visual-pending-ok`) prints `GREEN`, rc 0, 20 jobs `success`.

Every PR-path job is `success`: Browser UAT, including the `Phase 211 visual regression gate`; all four Release gate cells, including the portal suite; Docs and bash contracts; Release manifest SSOT; iOS offline client; Phase 18 Stripe Tax gate; Admin drift and docs; Admin group, hardening and Phase 200 guardrails; ratchet self-tests; Host integration; Playwright E2E shards 1/3, 2/3 and 3/3; Host Docker boot smoke; Annotation sweep. The parked lane `Admin UI ratchet guardrails [parked]` is `failure` by design (D1). The Stripe trio and `Mint visual baselines` are `skipped` as required. No `gh run rerun` was used.

Bound: 3 of 3 plan-250-04 pushes used.

## Iteration 9 (plan 250-05) - pushed `7b1b58624fed4c1cbbd96f45f0d568d86f1bad5f` (first close commit, superseded)

Runs: ci.yml `40241001658`, accrue_admin_browser.yml `40241001662`. Guard `--close` PASS, SL-F PASS. Browser UAT run `success`.

| Job | Conclusion | Failing step | Evidence | Classification | Fix |
|-----|-----------|--------------|----------|----------------|-----|
| Release gate (Primary dev target; elixir=1.19.5 otp=28.0 sigra=off opentelemetry=on) | failure | accrue suite | job 121312543518: `2081 tests, 1 failure`, `Accrue.Docs.V159ReleaseContractTest` "rejects backend-first wording" (`v159_release_contract_test.exs:49`): `verify_release_contract.sh: line 188: printf: write error: Broken pipe`, then the wrong failure "missing job/next-action structure". The same code passed at `5ad01dee` | source bug (CI script, timing-dependent): `printf "$v159_section" \| grep -Fq` under `pipefail`; `grep -q` exits on its first match, and a printf still writing the 7551-byte section gets EPIPE, so a present needle reads as missing | `fix(250-05): feed the v1.59 runbook greps from here-strings, not a pipe` (`5561a9a9`). Controls in `250-05-SUMMARY.md` F5: mechanism 20/20 vs 0/20; 30 rounds of the test file 6/0; each of the three checks still fails on a bad fixture |
| Admin drift and docs | skipped | none ran | `needs: [release-gate]` | downstream | none |
| Admin UI ratchet guardrails [parked] | failure | Verify frozen ratchet evidence | by design, D1 | parked | none |

No `gh run rerun` was used. The close was re-made as a new E on top of the fix; `7b1b5862` is not the evidence head.

## Pushed SHA record

| Iteration | SHA | ci.yml run | browser run | Verdict |
|-----------|-----|-----------|-------------|---------|
| 1 | `bde9ae6cb64734c144706895641e46dbf5cedcb2` | 40213687124 | 40213687112 | RED |
| 2 | `11ede7ffab5ee4fbd0862982575b1dcbd52b6206` | 40216216053 | 40216216059 | RED |
| 3 | `ead4f497c124d4e1bbca2ff313dff76f310231e2` | 40221570264 | 40221570185 | RED |
| 4 | `533d2ded4208d32c982d2e4bb78c8f6dff150eb8` | 40226070833 | 40226070837 | RED |
| 5 (P) | `b9c98b20081841e976586339db47554e40da7179` | 40229480564 | 40229480489 | GREEN (visual-pending) |
| 6 (250-04) | `133fafc2b0c4487522eaa40801985518e4d986ec` | 40232857493 | 40232857489 | RED (visual, classified) |
| 7 (250-04) | `74cdd43a48a57ee2ee047293d387093c138da5d8` | 40234321143 | 40234321194 | RED (portal flake; Browser UAT success) |
| 8 (250-04, P) | `5ad01dee2c70087aa89fafdfb154f6e9d8068277` | 40236926623 | 40236926603 | GREEN |
| 9 (250-05, first close) | `7b1b58624fed4c1cbbd96f45f0d568d86f1bad5f` | 40241001658 | 40241001662 | RED (SIGPIPE race in verify_release_contract.sh; fixed in 5561a9a9) |

The evidence head E and the body-only head H are recorded in `250-INTEGRATION-PR.md` Provenance; this ledger cannot hold E's own runs without moving E.
