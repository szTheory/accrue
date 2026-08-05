---
phase: 222-close-gap-off-05-schedule-offline-reconnect-recovery
verified: 2026-08-05T20:11:24Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 222: Close gap: OFF-05 — schedule offline reconnect recovery Verification Report

**Phase Goal:** The reference host schedules durable offline reconnect recovery and proves that an interrupted reconnect is reclaimed through the existing locked, provider-authoritative worker path to one signed proof replacement.

**Verified:** 2026-08-05T19:55:05Z

**Status:** passed

**Re-verification:** Yes — after the post-review fixture hardening

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The reference host schedules exactly one offline reconnect recovery sweep every 15 minutes while preserving every existing Oban queue, plugin, and Cron entry. | ✓ VERIFIED | `config/config.exs` has exactly one `{"*/15 * * * *", Accrue.Entitlements.Offline.ReconnectSweeper}` tuple alongside all five prior entries. `RecoveryWiringTest` reads the real config, validates it through `Oban.Config.validate/1`, and checks workers, both relevant Cron cardinalities, and the entitlement queue. The focused test passed. |
| 2 | A PoP-authenticated stranded reconnect is reclaimed by the real sweeper and worker, then terminalizes once with one cryptographically fresh signed replacement. | ✓ VERIFIED | The focused host test executes real challenge/signature admission, interrupts after durable admission, removes the queued immediate `ReconnectWakeupWorker` job while retaining the durable wakeup record, then invokes `ReconnectSweeper.perform/1`, loads the persisted `ReconnectWorker` job, and calls `ReconnectWorker.perform/1`. It asserts `:completed`, `attempt_count: 1`, one `Issuance`, and `Offline.verify/3 == {:ok, %{state: :fresh}}`; 7/7 focused tests passed. |
| 3 | Recovery gets provider status only from the host-configured coordinator; `due_sources/3` hands its configured status to `refresh/4` and neither receives client proof authority. | ✓ VERIFIED | The integration test asserts one callback of each kind for the persisted account and identical worker clock/status fixture, with observed authority keys exactly `[:provider_fixture]`. Production `Reconnect.execute_attempt/2` merges only validated host `:offline_reconnect` configuration before running the coordinator. |
| 4 | Production reconnect adapters remain host-owned and out of scope; Cron presence is not treated as a configured production endpoint. | ✓ VERIFIED | `examples/accrue_host/config/` contains no `:offline_reconnect` adapter configuration. The source/key implementations exist only as nested test modules and setup restores every mutated application key. `Reconnect.execute_attempt/2` validates runtime host configuration and terminalizes invalid configuration rather than inventing an adapter. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/accrue_host/config/config.exs` | One additive 15-minute `ReconnectSweeper` Cron tuple on the established entitlement queue. | ✓ VERIFIED | Exists, substantive, parsed by `Config.Reader`, and consumed by the static Oban wiring test. `verify.artifacts` passed 2/2 artifacts. |
| `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` | Static Oban validation and durable stranded-reconnect-to-signed-issuance proof. | ✓ VERIFIED | Exists (358 lines), contains executable crypto/DB/Oban assertions rather than a stub, and is included in the reference-host `mix verify` lane. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Host Cron config | `ReconnectSweeper` | `Oban.Plugins.Cron` tuple at `*/15 * * * *`. | ✓ WIRED | Exact tuple is in the real host config and its parsed Cron list is checked by the focused passing test. |
| `ReconnectSweeper` | `ReconnectWorker` | `Reconnect.enqueue_due/2` selects eligible durable attempts with `FOR UPDATE SKIP LOCKED` and inserts `ReconnectWorker` jobs. | ✓ WIRED | `reconnect_sweeper.ex` calls `Reconnect.enqueue_due(Accrue.Repo.repo())`; `reconnect.ex` constructs the real worker job. The host test proves the persisted job carries the admitted attempt ID. |
| `ReconnectWorker` | `Issuance` | `execute_attempt/2` uses validated host configuration, provider refresh, and the locked issuer path. | ✓ WIRED | `reconnect_worker.ex` calls `Reconnect.execute_attempt/1`; `reconnect.ex` reaches `Issuer.issue_after_admission/4` with a transactional issued-outcome callback. The host test proves the resulting single issuance and verified proof. |

The generic `verify.key-links` query reported the module-name links unparseable because its `from` values are not file paths (and the first pattern includes literal quoting). Manual source-and-behavior tracing above verifies all three actual links.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `recovery_wiring_test.exs` | durable reconnect attempt, queued job, terminal proof | Real `AccrueHost.Repo` records created by authenticated admission; host-owned test fixture becomes worker configuration; `Issuer` persists the issuance. | Yes — no static API return or empty prop is involved. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Host configuration and full stranded-reconnect recovery | `cd examples/accrue_host && mix format --check-formatted config/config.exs test/accrue_host/recovery_wiring_test.exs && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` | 7 tests, 0 failures | ✓ PASS |
| Reference-host release contract, including recovery wiring | `cd examples/accrue_host && mix verify` | 64 tests, 0 failures | ✓ PASS |
| Core reconnect lifecycle regression | `cd accrue && mix test test/accrue/entitlements/offline_reconnect_test.exs` | 19 tests, 0 failures | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 222 declares no probe and has no phase-referenced `probe-*.sh` script.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| OFF-05 | `222-01-PLAN.md` | Authenticate account/device, schedule due-rail refresh, and atomically replace proof from provider-authoritative state without accepting client proof as provider truth. | ✓ SATISFIED | The real host integration test exercises PoP admission, scheduled durable retry, configured coordinator discovery/refresh, single issuance, and cryptographic fresh-proof verification. Core reconnect regression also passes. |

### Anti-Patterns Found

No blocker or warning anti-patterns in the two phase-owned files. The scan found no unreferenced `TBD`/`FIXME`/`XXX`, placeholder output, empty user-visible data path, or hardcoded empty rendered data. The test’s fixture setup is populated by real DB/worker execution and is not a stub.

### Gaps Summary

No gaps found. There are no later roadmap phases to which a missing Phase 222 obligation could be deferred.

---

_Verified: 2026-08-05T20:11:24Z_

_Verifier: the agent (gsd-verifier)_
