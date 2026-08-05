# Phase 222: Close gap: OFF-05 — schedule offline reconnect recovery - Research

**Researched:** 2026-08-05
**Domain:** Phoenix reference-host Oban recovery scheduling for durable offline reconnect attempts
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| OFF-05 | Reconnect authenticates account and device, refreshes due rails under an explicit schedule, compares account revision and device state, and atomically replaces cached proof with a newer allow proof or signed deny tombstone; client proof is never provider truth. | The core reconnect path already has durable attempt/wakeup state, recovery claiming, provider/due-source coordination, locked issuance, and signed replacement. This phase supplies the missing reference-host Cron link and host-level proof for recovery after job loss/retry exhaustion. [VERIFIED: codebase `accrue/lib/accrue/entitlements/offline/reconnect.ex`, `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`] |
</phase_requirements>

## Summary

Phase 222 is a narrow reference-host integration closure, not a new reconnect protocol, migration, source coordinator, or client-cache implementation. `Reconnect.schedule_attempt/5` durably writes an admitted reconnect attempt and a unique wakeup row before provider work; `Reconnect.enqueue_due/2` can reclaim admitted/retrying attempts and running attempts whose lease has expired; `ReconnectSweeper` exposes that recovery routine as an Oban worker. The host’s `config/config.exs` already provisions the `:accrue_entitlements` queue and schedules Apple reconciliation every 15 minutes, but it never schedules `Accrue.Entitlements.Offline.ReconnectSweeper`. [VERIFIED: codebase `reconnect.ex`, `reconnect_sweeper.ex`, `examples/accrue_host/config/config.exs`]

The milestone audit identifies this exact missing link: a stranded or retry-exhausted reconnect remains unclaimed in the deployed reference host. It requires one host Cron entry, a host-level recovery proof that exercises scheduler reclamation through signed replacement, and inclusion of that proof in the release-contract gate. The existing `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` already reads the base Oban configuration with `Config.Reader`, validates it with `Oban.Config.validate/1`, asserts the Apple sweeper entry/queue, and is included in the bounded `mix verify` script; extend it rather than inventing another configuration-test pattern. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`, `recovery_wiring_test.exs`, `scripts/ci/accrue_host_verify_test_bounded.sh`]

**Primary recommendation:** Add exactly one `{"*/15 * * * *", Accrue.Entitlements.Offline.ReconnectSweeper}` entry to the existing reference-host Cron list, extend the existing recovery wiring proof, and add a deterministic host integration test that leaves an attempt durable-but-unexecuted, invokes the sweeper/worker path, and verifies one signed replacement without weakening PoP, locks, or source authority. [VERIFIED: codebase `config/config.exs`, `reconnect.ex`, `offline_reconnect_test.exs`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Recurring recovery trigger | API / Backend | Database / Storage | The host’s Oban Cron plugin inserts the package worker; the durable reconnect-attempt table determines what is eligible to reclaim. [VERIFIED: codebase `examples/accrue_host/config/config.exs`, `reconnect.ex`] |
| Claim stranded/retryable work | Database / Storage | API / Backend | `enqueue_due/2` selects admitted/retrying or lease-expired running rows under `FOR UPDATE SKIP LOCKED`, then resets/requeues them. [VERIFIED: codebase `reconnect.ex`] |
| Execute an authenticated reconnect | API / Backend | Database / Storage | `ReconnectWorker` calls `execute_attempt/2`; it validates host config, claims one attempt, refreshes due sources, and finishes through the locked issuer path. [VERIFIED: codebase `reconnect_worker.ex`, `reconnect.ex`] |
| Provider truth and due-source repair | API / Backend | External provider | `SourceCoordinator` owns due/refresh/repair callbacks; a client proof is never accepted as provider truth. [VERIFIED: codebase `source_coordinator.ex`, `reconnect.ex`] |
| Atomic local proof replacement | Client | API / Backend | The server returns a signed terminal proof only after durable convergence; the Crosswake cache verifies and atomically replaces its local candidate. This phase does not modify that client boundary. [VERIFIED: codebase `reconnect.ex`, `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| Oban | existing `~> 2.21` package dependency | Cron-triggered worker execution and existing `:accrue_entitlements` queue | The reference host already uses `Oban.Plugins.Cron` for recovery workers; no dependency change is needed. [VERIFIED: codebase `accrue/mix.exs`, `examples/accrue_host/config/config.exs`] |
| Ecto/PostgreSQL | existing host stack | Durable attempt state, wakeups, locks, and transactional terminal outcomes | Core recovery correctness relies on constraints and row locking, not scheduler uniqueness. [VERIFIED: codebase `reconnect.ex`, `reconnect_attempt.ex`] |
| Accrue offline reconnect workers | local package code | Wakeup drain, reconnect execution, and periodic stranded-attempt recovery | `ReconnectSweeper`, `ReconnectWakeupWorker`, and `ReconnectWorker` already implement the required bounded recovery roles. [VERIFIED: codebase `accrue/lib/accrue/entitlements/offline/`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| ExUnit + Oban test helpers | existing host test stack | Config and real-repository recovery proof | Extend the current host `RecoveryWiringTest`; tests run with Oban manual mode so the test explicitly controls recovery. [VERIFIED: codebase `recovery_wiring_test.exs`, `examples/accrue_host/config/test.exs`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Host Oban Cron entry | A new in-process timer/supervised poller | The host already has Cron and a queue. A second scheduler would bypass the accepted operational/configuration pattern and add duplicate-trigger behavior without improving lock-backed correctness. [VERIFIED: codebase `examples/accrue_host/config/config.exs`, `reconnect_sweeper.ex`] |
| Reusing `RecoveryWiringTest` | A new static configuration-test file | A new file duplicates its `Config.Reader`/Oban validation helper and weakens the existing single recovery-wiring authority. [VERIFIED: codebase `recovery_wiring_test.exs`] |

**Installation:** None — this phase must not add dependencies. [VERIFIED: codebase `accrue/mix.exs`, `examples/accrue_host/mix.exs`]

## Architecture Patterns

### System Architecture Diagram

```text
authenticated reconnect + PoP
        |
        v
Reconnect.reconnect/3
        |
        +--> transaction: Challenge consumed + ReconnectAttempt(admitted) + ReconnectWakeup
        |                                      |
        |                                      +--> immediate ReconnectWakeupWorker -> ReconnectWorker
        |
        '--> worker lost / retries exhausted / lease abandoned
                                                |
                                                v
host Oban.Plugins.Cron (every 15 min)
        |
        v
Offline.ReconnectSweeper
        |
        v
Reconnect.enqueue_due/2 -- FOR UPDATE SKIP LOCKED --> ReconnectWorker job
                                                        |
                                                        v
                         host SourceCoordinator refreshes due provider sources
                                                        |
                                      unresolved --> durable pending/needs_repair, no proof
                                      resolved   --> locked issuer -> signed allow/deny proof
                                                        |
                                                        v
                                     verified client cache atomically replaces newer proof
```

The scheduler may create duplicate wakeups across failures, but it must never become the ownership or authorization primitive: only the row claim and execution token determine who can advance an attempt. [VERIFIED: codebase `reconnect.ex`, `offline_reconnect_test.exs`]

### Recommended Project Structure

```text
examples/accrue_host/
├── config/config.exs                              # append the reconnect recovery Cron entry
└── test/accrue_host/recovery_wiring_test.exs       # config + deterministic recovery proof

scripts/ci/
└── accrue_host_verify_test_bounded.sh              # unchanged if the existing test file is extended
```

### Pattern 1: Append to the one existing Cron list

**What:** Preserve every existing queue, plugin, and Cron tuple; append the recovery sweeper beside Apple reconciliation. [VERIFIED: codebase `examples/accrue_host/config/config.exs`]

**When to use:** When enabling the package’s already-implemented durable reconnect recovery in the reference host. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`]

**Example:**

```elixir
# Source: existing `examples/accrue_host/config/config.exs` Cron shape
crontab: [
  {"*/15 * * * *", Accrue.Entitlements.Apple.ReconciliationSweeper},
  {"*/15 * * * *", Accrue.Entitlements.Offline.ReconnectSweeper}
]
```

Use the explicit `:accrue_entitlements` worker declaration already encoded by `ReconnectSweeper`; do not add a redundant queue override to the Cron tuple. [VERIFIED: codebase `reconnect_sweeper.ex`]

### Pattern 2: Test the host’s actual recovery chain, not just worker presence

**What:** Use host test configuration to create a real durable reconnect attempt that has not completed, run `ReconnectSweeper.perform/1`, run the enqueued `ReconnectWorker`, then verify exactly one durable issuance and a valid signed replacement. [VERIFIED: codebase `reconnect.ex`, `offline_reconnect_test.exs`]

**When to use:** To close the audit’s broken flow after job loss or retry exhaustion. A configuration-only assertion prevents omission but cannot prove recovery reaches the issuer. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`]

### Anti-Patterns to Avoid

- **Only adding a Cron tuple:** Static wiring alone does not establish that a stranded attempt can be reclaimed, executed with valid host options, and finish in one proof issuance. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`, `reconnect.ex`]
- **Testing by calling `Reconnect.execute_attempt/2` directly:** That repeats package-level coverage but skips the missing host scheduler-to-worker link. [VERIFIED: codebase `offline_reconnect_test.exs`, `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`]
- **Replacing the Cron list:** Replacing it can silently drop dunning, card-expiry, meter, and Apple repair schedules. [VERIFIED: codebase `examples/accrue_host/config/config.exs`, `recovery_wiring_test.exs`]
- **Treating Oban uniqueness/Cron leadership as the lock:** Reclaim and terminal completion must remain protected by PostgreSQL locks and the execution token. [VERIFIED: codebase `reconnect.ex`, `offline_reconnect_test.exs`]
- **Using the client’s old proof as recovery input:** Source status must come from the configured coordinator/provider path; no cached proof may become provider truth. [VERIFIED: codebase `source_coordinator.ex`, `reconnect.ex`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Periodic recovery loop | A GenServer timer or custom polling process | Existing `Oban.Plugins.Cron` + `ReconnectSweeper` | The host already owns a validated Cron configuration; the package worker already handles bounded sweeping. [VERIFIED: codebase `examples/accrue_host/config/config.exs`, `reconnect_sweeper.ex`] |
| Stranded-attempt query/claim | A new host query over reconnect tables | `Reconnect.enqueue_due/2` via `ReconnectSweeper` | It already encodes eligible states, lease cutoff, lock semantics, state reset, and worker enqueue. [VERIFIED: codebase `reconnect.ex`] |
| Proof minting/replacement | Test-only/manual signed token construction | Existing `ReconnectWorker` → `Issuer` chain and verifier | The chain enforces source convergence, locked account/device/snapshot reads, self-verification, and durable issuance state. [VERIFIED: codebase `reconnect.ex`, `issuer.ex`] |

**Key insight:** This closure is a missing host trigger, not missing domain logic. Keep all retry, lock, PoP, provider-refresh, signing, and proof-replacement semantics in the established core flow. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`, `reconnect.ex`]

## Common Pitfalls

### Pitfall 1: A cron entry is present but the test does not prove recovery

**What goes wrong:** The reference host appears configured, while an admitted/retrying/expired-running attempt still cannot be shown to reach signed replacement. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`]

**Why it happens:** The existing core suite proves `enqueue_due/2` with injected jobs, whereas the host suite currently proves only Apple recovery wiring. [VERIFIED: codebase `offline_reconnect_test.exs`, `recovery_wiring_test.exs`]

**How to avoid:** Add deterministic host recovery coverage in `RecoveryWiringTest` that creates a durable interrupted reconnect, runs the sweeper, executes the produced `ReconnectWorker`, and checks a single signed issuance/replacement outcome. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`, `reconnect.ex`]

**Warning signs:** The test asserts `ReconnectSweeper in workers` but never persists `ReconnectAttempt`, observes an enqueued `ReconnectWorker`, or checks `Issuance`. [VERIFIED: codebase `recovery_wiring_test.exs`, `reconnect.ex`]

### Pitfall 2: Recovery runs with incomplete host configuration

**What goes wrong:** `Reconnect.execute_attempt/2` marks a nonterminal attempt `:needs_repair` with `failure_reason: "config_invalid"` if `:accrue, :offline_reconnect` lacks a valid source coordinator or signing key provider. [VERIFIED: codebase `reconnect.ex`, `offline_reconnect_test.exs`]

**Why it happens:** The worker intentionally cannot reuse request-scoped authentication options; it reads a host-owned worker configuration. [VERIFIED: codebase `reconnect.ex`]

**How to avoid:** The host-level test must install a real test-only `:offline_reconnect` configuration with a behaviour-conformant coordinator and signing provider, restore it on exit, and assert successful issuance. Do not use the test-only core providers as production configuration. [VERIFIED: codebase `key_provider.ex`, `source_coordinator.ex`, `offline_reconnect_test.exs`]

**Warning signs:** A test reaches only `ReconnectSweeper.perform/1`, or the attempt finishes as `:needs_repair`/`config_invalid` rather than `:completed` with an issuance. [VERIFIED: codebase `reconnect.ex`, `offline_reconnect_test.exs`]

### Pitfall 3: The release gate does not cover the new proof

**What goes wrong:** Local coverage exists but `mix verify` does not run it, so a future Cron edit can reopen OFF-05. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`]

**How to avoid:** Extend the already-listed `test/accrue_host/recovery_wiring_test.exs`; then the existing bounded host test script and `install_boundary_test.exs` coverage continue to include it without adding a second test-runner registration. If a new file is chosen instead, update both artifacts deliberately. [VERIFIED: codebase `scripts/ci/accrue_host_verify_test_bounded.sh`, `examples/accrue_host/test/install_boundary_test.exs`]

## Code Examples

### Existing package recovery entry point

```elixir
# Source: `accrue/lib/accrue/entitlements/offline/reconnect_sweeper.ex`
def perform(%Oban.Job{}) do
  case Reconnect.enqueue_due(Accrue.Repo.repo()) do
    {:ok, _} -> :ok
    {:error, reason} -> {:error, reason}
  end
end
```

### Existing reference-host configuration verification pattern

```elixir
# Source: `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs`
oban_config = base_oban_config()
assert :ok = Oban.Config.validate(oban_config)
workers = oban_config |> cron_entries() |> Enum.map(&elem(&1, 1))
assert Accrue.Entitlements.Offline.ReconnectSweeper in workers
```

Oban documents static Cron worker tuples and supports validating Cron/Oban configuration in tests; the host’s current `Config.Reader`/`Oban.Config.validate/1` pattern aligns with that guidance. [CITED: https://hexdocs.pm/oban/testing_config.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Immediate reconnect job only | Durable wakeup plus periodic reclaim of admitted/retrying/lease-expired attempts | Existing Phase 219 reconnect implementation | Recovery survives wakeup/job loss only when a host schedules `ReconnectSweeper`. [VERIFIED: codebase `reconnect.ex`, `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`] |

**Deprecated/outdated:**

- A one-shot in-request reconnect is insufficient as a recovery guarantee after process/job loss; retain the durable sweep path. [VERIFIED: codebase `reconnect.ex`, `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A 15-minute reconnect sweep is the intended cadence because it matches the already-deployed Apple reconciliation sweep. The audit requires an explicit cadence but does not prescribe a number. | Summary / Architecture Patterns | A different operational SLO may require a shorter or longer cadence; planner should confirm only if altering the established cadence is material. |

## Open Questions

1. **Does Phase 222 need to complete production `:offline_reconnect` host configuration, or only close the audited scheduler integration?**
   - What we know: `ReconnectWorker` requires a host-owned source coordinator and key provider. The current reference-host runtime configuration contains Apple reconciliation configuration but no `:offline_reconnect` configuration, and no production host implementation of `Accrue.Entitlements.Offline.KeyProvider` or `SourceCoordinator` was found. [VERIFIED: codebase `reconnect.ex`, `examples/accrue_host/config/runtime.exs`, `key_provider.ex`, `source_coordinator.ex`]
   - What's unclear: The milestone audit frames the required closure as Cron wiring plus a signed host recovery proof, but adding only Cron would cause a real production worker to terminate with `config_invalid` if a reconnect attempt reaches it. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`, `reconnect.ex`]
   - Recommendation: Keep production signing custody/provider-specific refresh implementation out of this narrow schedule phase unless the planner confirms it is already supplied externally. Make the host test use a test-only configured coordinator/provider and add an explicit planner checkpoint: do not claim the reference host’s production reconnect endpoint is operational until production `:offline_reconnect` configuration exists. [VERIFIED: codebase `key_provider.ex`, `source_coordinator.ex`, `reconnect.ex`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/Erlang | Host configuration and ExUnit proof | ✓ | Erlang/OTP 28 reported | — |
| Mix | Focused host test | ✓ | available in both `accrue` and `examples/accrue_host` | — |
| PostgreSQL client | Ecto/Oban-backed host test environment | ✓ | `psql 14.17` | — |
| Oban | Existing scheduler and manual test mode | ✓ | existing lockfile/dependency; host focused test passes | — |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit + Oban manual test mode [VERIFIED: codebase `examples/accrue_host/config/test.exs`] |
| Config file | `examples/accrue_host/config/test.exs` [VERIFIED: codebase] |
| Quick run command | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` [VERIFIED: executed 2026-08-05; 6 tests, 0 failures] |
| Full suite command | `cd examples/accrue_host && mix verify` [VERIFIED: codebase `examples/accrue_host/mix.exs`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| OFF-05 | Cron list includes exactly one reconnect sweeper without losing existing recovery workers/queue | configuration integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` | ✅ extend existing |
| OFF-05 | Durable admitted/retrying or expired-running reconnect is swept, enqueued, executed once, and reaches signed issuance/replacement through configured test workers | Ecto + Oban integration | same focused command | ❌ Wave 0 extension required |
| PROOF-02 (affected) | The host release gate executes the recovery proof | release-contract regression | `cd examples/accrue_host && mix verify` | ✅ when extending existing listed file |

### Sampling Rate

- **Per task commit:** Run the focused `RecoveryWiringTest` command. [VERIFIED: codebase test structure]
- **Per wave merge:** Run `cd examples/accrue_host && mix verify`. [VERIFIED: codebase `examples/accrue_host/mix.exs`]
- **Phase gate:** Run the focused core reconnect suite as a regression companion: `cd accrue && mix test test/accrue/entitlements/offline_reconnect_test.exs`. [VERIFIED: codebase `offline_reconnect_test.exs`]

### Wave 0 Gaps

- [ ] Extend `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` with the reconnect-sweeper Cron assertion and a real durable-attempt recovery test.
- [ ] Add isolated test-only host implementations/configuration for `Accrue.Entitlements.Offline.KeyProvider` and `SourceCoordinator`, restoring application configuration on exit.
- [ ] Verify exactly-once issuance and a valid signed proof; include a preexisting wakeup/job-loss condition so the sweeper, not the immediate path, is what causes recovery.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | Yes | Preserve one-time authenticated device proof-of-possession before reconnect admission. [VERIFIED: codebase `reconnect.ex`] |
| V3 Session Management | Yes | Worker recovery is for an already-admitted durable attempt; it must not recreate a client session or accept an unbound request. [VERIFIED: codebase `reconnect.ex`] |
| V4 Access Control | Yes | Keep the host authorization boundary for initial challenge/reconnect; do not expose the sweeper as a public endpoint. [VERIFIED: codebase `offline.ex`, `reconnect.ex`] |
| V5 Input Validation | Yes | Worker accepts only a binary attempt ID and cancels malformed jobs; worker config is explicitly validated. [VERIFIED: codebase `reconnect_worker.ex`, `reconnect.ex`] |
| V6 Cryptography | Yes | Reuse the configured key-provider signing and post-sign verification path; never introduce a scheduler-owned secret or test key in production config. [VERIFIED: codebase `key_provider.ex`, `issuer.ex`] |

### Known Threat Patterns for the stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Duplicate scheduler/worker execution | Tampering / Denial of Service | `FOR UPDATE SKIP LOCKED`, attempt states, and execution tokens make durable claim/terminalization authoritative. [VERIFIED: codebase `reconnect.ex`] |
| A stale running worker completes after lease recovery | Tampering | Terminal writes require the current execution token. [VERIFIED: codebase `reconnect.ex`, `offline_reconnect_test.exs`] |
| Scheduler mints a proof without provider refresh | Elevation of Privilege | Keep `SourceCoordinator.due_sources/3` and `refresh/4` before issuer settlement; unresolved work returns no proof. [VERIFIED: codebase `source_coordinator.ex`, `reconnect.ex`] |
| Test key or raw proof leaks into host runtime/docs | Information Disclosure | Keep signing providers test-only; retain the host-owned key-custody boundary and bounded telemetry. [VERIFIED: codebase `key_provider.ex`, `reconnect.ex`] |

## Sources

### Primary (HIGH confidence)

- [Milestone audit](../../v1.59-v1.59-MILESTONE-AUDIT.md) - exact OFF-05/PROOF-02 scheduler gap and required closure.
- [Reconnect implementation](../../../../accrue/lib/accrue/entitlements/offline/reconnect.ex) - durable admission, wakeup drain, stranded-attempt claim, worker config, and locked issuance path.
- [Reference-host Oban configuration](../../../../examples/accrue_host/config/config.exs) - existing queue and Cron entries missing the reconnect sweeper.
- [Recovery wiring test](../../../../examples/accrue_host/test/accrue_host/recovery_wiring_test.exs) - configuration-validation and release-gated host-test precedent.
- [Core reconnect tests](../../../../accrue/test/accrue/entitlements/offline_reconnect_test.exs) - expired-lease reclaim and configuration-failure behavior.

### Secondary (MEDIUM confidence)

- [Oban testing configuration](https://hexdocs.pm/oban/testing_config.html) - documented Oban/Cron validation approach used by the host pattern.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — existing dependencies and host scheduler are directly inspectable. [VERIFIED: codebase]
- Architecture: HIGH — the missing connection and exact recovery chain are identified by audit plus executable core code. [VERIFIED: codebase]
- Pitfalls: HIGH — core integration tests exercise lease reclaim/config-invalid behavior; the audit records the production-facing omission. [VERIFIED: codebase]

**Research date:** 2026-08-05
**Valid until:** 2026-09-04 — stable internal scheduling/wiring domain; recheck if Oban or reconnect code changes. [ASSUMED]

## Recommended Phase Goal and Success Criteria

**Recommended goal:** The reference host schedules durable offline reconnect recovery and proves that an interrupted reconnect is reclaimed through the existing locked, provider-authoritative worker path to one signed proof replacement.

1. `examples/accrue_host` retains all existing Oban queues/Cron entries and adds exactly one explicit `Accrue.Entitlements.Offline.ReconnectSweeper` Cron entry on the existing entitlement queue cadence. [VERIFIED: codebase `config/config.exs`, `recovery_wiring_test.exs`]
2. A host-level deterministic test persists a stranded reconnect attempt, invokes the actual sweeper and resulting worker, and proves one completed issuance with a cryptographically valid proof/replacement outcome. [VERIFIED: codebase `.planning/v1.59-v1.59-MILESTONE-AUDIT.md`, `reconnect.ex`]
3. The proof demonstrates recovery after the immediate wakeup path is unavailable; it must not bypass durable state, source coordination, PoP admission, locks, or terminal issuance. [VERIFIED: codebase `reconnect.ex`, `offline_reconnect_test.exs`]
4. The existing bounded host verification command runs the regression, and focused core reconnect tests remain green. [VERIFIED: codebase `scripts/ci/accrue_host_verify_test_bounded.sh`, `offline_reconnect_test.exs`]
5. Phase documentation reports the production `:offline_reconnect` configuration boundary accurately; do not claim a production reconnect endpoint is ready merely from Cron wiring if its host-owned source/key adapters are absent. [VERIFIED: codebase `reconnect.ex`, `examples/accrue_host/config/runtime.exs`]
