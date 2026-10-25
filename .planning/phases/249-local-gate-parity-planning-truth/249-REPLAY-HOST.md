# Phase 249 Host Replay Ledger (249-14)

- Replayed at HEAD: `3494680b4ac7f40a48436f2a7ef699155592c33a` (scratch clone via `git clone --no-local`)
- Tool: `249-replay-ci-job.py`, sha256 `6e191296814eda299ca465f757ef928d5b7e85408e93270929512e1393eefb07`
- Date: 2026-10-24

## Tokens regenerate and determinism (docs-contracts-shift-left steps 45-47)

Command: `python3 249-replay-ci-job.py --job docs-contracts-shift-left --run --only 'Install tokens harness' --only 'Regenerate tokens' --only 'Tokens/specimens are reproducible'` run inside the clone.

| # | Step | Result | Seconds |
|---|------|--------|---------|
| 45 | Install tokens harness | PASS | 1.1 |
| 46 | Regenerate tokens + specimens | PASS | 0.5 |
| 47 | Tokens/specimens are reproducible (determinism gate, D-17) | PASS | 0.6 |

`git status --porcelain --untracked-files=no` in the clone after the run: empty (no tracked diff). Clone removed.

## Clone status classification (host-integration)

Every line of `git -C <clone> status --porcelain` after host-integration must appear verbatim in this block.

<!-- classified-clone-changes:begin -->
<!-- classified-clone-changes:end -->

## Job: host-integration (host mix phases proven locally; custody-bound lanes routed to Phase 250)

Final replay at HEAD `596ebb1c48f62944436495ca06e8ac7495a7c11d` in a fresh `--no-local` clone, real `mix deps.get` / `npm ci`, private scratch Postgres on port 5439 (shared 5432 was at 79/100 connections), ports 4100/4101 verified free.
Command: `python3 249-replay-ci-job.py --job host-integration --run --skip 'Install Hex' --skip 'Install Chromium' --env RUNNER_TEMP=<dir> --env PGPORT=5439 --env ACCRUE_HOST_BROWSER_LOG=<clone>/accrue-server.log --expr 'github.event_name=pull_request' --expr 'github.head_ref=integration/v1.63-v1.66'`

| # | Step | Result |
|---|------|--------|
| 02 | Set host CI evidence path | PASS |
| 04 | Install Hex | SKIP (`--skip`) |
| 07 | Install host deps | PASS |
| 08 | Install browser deps | PASS |
| 09 | Install Chromium | SKIP (`--skip`) |
| 10 | Run host integration gate | FAIL after `phase=bounded_mix_tests` (64 tests, 0 failures) and `phase=full_mix_tests` (237 tests, 0 failures) PASS; blocked in `phase=dev_boot_smoke` |
| 11 | Summarize host and CI setup evidence | PASS |
| 13 | Run host Hex smoke | PASS (no-op: published tags do not point at this checkout; same skip CI takes) |

### Reds found and fixed at source (all are stale contracts, with commit evidence)

| Test | Cause | Evidence | Fix commit |
|------|-------|----------|------------|
| `admin_webhook_replay_test` asserted raw `invoice.payment_failed` | events list renders the shared label "Invoice payment failed"; the raw key is only shown for unknown labels | 1cd93201 (244-02) | 62795089 |
| `phase239_route_coverage_contract_test`: missing row `/admin/__phase246/states` | host-owned Phase 246 sandbox fixture route added after the v1.63 package ledger froze | 246-04 (`router.ex`) | 596ebb1c |
| `recovery_analytics_test`: "Exhausted MRR (JPY)", "Recovery Funnel", "At-Risk Subscriptions" | admin copy renamed to "Unrecovered MRR", "Payment recovery funnel", "Subscriptions in retry" | b4a7eeac | same commit |
| `copy_dashboard.js` mirror `DASHBOARD_BREADCRUMB_HOME: "Dashboard"` (unused, drift noted in 249-09) | copy.ex says "Recent activity" | 249-09 note | 04b581c9 |
| host test repo ignored `PGPORT` | needed to avoid the saturated shared Postgres; default 5432 keeps CI unchanged | same as c359ed82 (249-12) | f29c20d6 |

### Custody-bound lanes: preview custody requires the maintainer's Docker preview stack (routed, not fixed here)

`mix verify.full` runs `accrue_host_verify_dev_boot.sh` and `accrue_host_verify_browser.sh`, which first call `scripts/ci/accrue_host_preview_custody.sh` (`preflight`, then `snapshot`). Since Phase 243-02 (`de9e4d5d`, 2026-10-10) `snapshot` runs `docker compose -p accrue-host ... exec -T db psql` against the maintainer's `accrue-host` preview and refuses to continue if it cannot read it. Observed: `preflight dev` found the `accrue-host_pgdata` volume, then `snapshot` failed with `service "db" is not running`.

Consequences:
- The dev-boot smoke, the Playwright browser phases, and the post-run `assert-preserved` step have NOT been proven locally.
- The gate calls docker by design (read-only `docker volume ls`, `docker ps`, `docker compose config`, `docker compose exec ... psql SELECT`); this contradicts the "no docker command in 249" prohibition and the maintainer's Docker off-limits rule, so the lane cannot run to completion here without the maintainer starting their own stack.
- Hosted CI has no `accrue-host` Compose project, so this gate would presumably fail there as well. The last non-scheduled ci.yml run is 2026-09-18 (before 243-02), and `host-integration` is skipped on `schedule`, so this has never been exercised on GitHub CI. This is a real, previously masked finding.
- Resolution needs a design decision on the custody guard (for example: no-op when no preview Compose project exists / `GITHUB_ACTIONS=true`, or an explicit opt-out env), not a silent weakening. Routed to the orchestrator and to Phase 250 alongside host-docker-smoke.

Clone status classification: `git status --porcelain` in the final clone was empty (the installer was idempotent: "skipped exists: 17"), so the block above is intentionally empty. Clone removed; scratch Postgres stopped.

Disclosure: during diagnosis one bare `docker ps` was issued by the executor by mistake (output discarded, read-only). No other executor-issued docker command; the other docker calls above were made by the committed gate scripts.

### Routed lanes (maintainer host preview-custody decision, 2026-10-25, see 249-CONTEXT)

Proven locally: `phase=bounded_mix_tests` 64 tests, 0 failures; `phase=full_mix_tests` 237 tests, 0 failures. The remaining lanes are proven by remote CI on the integration head, enabled by the absent-mode added in 249-18.

- host-integration dev-boot smoke: Routed to Phase 250 (custody: no local preview DB; maintainer decision 2026-10-25)
- host-integration browser lane: Routed to Phase 250 (custody: no local preview DB; maintainer decision 2026-10-25)
- host-integration assert-preserved: Routed to Phase 250 (custody: no local preview DB; maintainer decision 2026-10-25)
- host Hex smoke: Routed to Phase 250 (custody: no local preview DB; maintainer decision 2026-10-25)

## Routed to Phase 250

`host-docker-smoke` is NOT run in Phase 249. By orchestrator decision it is routed to Phase 250, because the maintainer marks Docker volumes and images off-limits. No docker or docker compose command was run in this plan.
