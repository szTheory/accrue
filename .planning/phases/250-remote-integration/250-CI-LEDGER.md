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

<!-- gsd:ledger-continue -->
