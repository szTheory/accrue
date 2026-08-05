# Phase 222: Close gap: OFF-05 — schedule offline reconnect recovery - Pattern Map

**Mapped:** 2026-08-05  
**Files analyzed:** 2  
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/accrue_host/config/config.exs` | config | event-driven | Existing Oban Cron block in the same file | exact |
| `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` | test | event-driven | Existing recovery wiring assertions plus `accrue/test/accrue/entitlements/offline_reconnect_test.exs` | exact / flow-match |

## Pattern Assignments

### `examples/accrue_host/config/config.exs` (config, event-driven)

**Analog:** its existing `Oban.Plugins.Cron` list at lines 46–71.

**Configuration shape** (lines 46–71):

```elixir
config :accrue_host, Oban,
  repo: AccrueHost.Repo,
  queues: [
    # existing host queues retained
    accrue_entitlements: 10
  ],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24},
    {
      Oban.Plugins.Cron,
      # append-merge: if your host already has cron jobs, append Accrue entries instead of replacing:
      # crontab: existing_cron_jobs() ++ [ ...Accrue entries... ]
      crontab: [
        {"*/15 * * * *", Accrue.Jobs.DunningSweeper},
        {"@daily", Accrue.Jobs.DetectExpiringCards},
        {"* * * * *", Accrue.Jobs.MeterEventsReconciler},
        {"*/5 * * * *", Accrue.Jobs.MeteredRenewalReconciler},
        {"*/15 * * * *", Accrue.Entitlements.Apple.ReconciliationSweeper}
      ]
    }
  ]
```

**Apply:** append exactly one tuple after the Apple entry, retaining the queues, Pruner, all current Cron entries, and cadence:

```elixir
{"*/15 * * * *", Accrue.Entitlements.Offline.ReconnectSweeper}
```

Do not put a queue override in the Cron tuple: `ReconnectSweeper` already declares `queue: :accrue_entitlements` (source `accrue/lib/accrue/entitlements/offline/reconnect_sweeper.ex:1-10`).

### `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` (test, event-driven)

**Primary analog:** the same test module at lines 1–119. It is already a real-host-Repo, non-async recovery proof and is included by the bounded verification script.

**Imports and host test base** (lines 1–13):

```elixir
defmodule AccrueHost.RecoveryWiringTest do
  use AccrueHost.AccrueCase, async: false

  alias Accrue.Jobs.DunningSweeper
  alias Accrue.Jobs.DetectExpiringCards
  alias Accrue.Jobs.MeteredRenewalReconciler
  alias Accrue.Jobs.MeterEventsReconciler
  alias Accrue.Entitlements.Apple.ReconciliationSweeper
```

Add aliases for `Offline`, `Reconnect`, `ReconnectAttempt`, `ReconnectWakeup`, `ReconnectWorker`, `ReconnectSweeper`, `Issuance`, the offline behaviour modules, and any existing account/device/projector helpers actually used. Keep `async: false`: the test changes application configuration and needs a shared Ecto sandbox.

**Static configuration assertion pattern** (lines 15–30):

```elixir
oban_config = base_oban_config()
assert :ok = Oban.Config.validate(oban_config)

crontab = cron_entries(oban_config)
workers = Enum.map(crontab, &elem(&1, 1))

assert ReconciliationSweeper in workers
assert Enum.count(crontab, &(&1 == {"*/15 * * * *", ReconciliationSweeper})) == 1
```

**Apply:** add `ReconnectSweeper` to `workers` and assert exactly one `{"*/15 * * * *", ReconnectSweeper}`. Preserve the existing assertions for every recovery worker and the entitlement queue—this test is deliberately an additive wiring contract.

**Test-mode scheduling boundary** (lines 83–90):

```elixir
runtime_oban_config = Application.fetch_env!(:accrue_host, Oban)

assert false == Keyword.get(runtime_oban_config, :plugins)
assert false == Keyword.get(runtime_oban_config, :queues)
assert :manual == Keyword.get(runtime_oban_config, :testing)
```

Tests must call `ReconnectSweeper.perform/1` and then explicitly execute the persisted/enqueued `ReconnectWorker`; do not expect Cron/plugins to run in test mode. This mirrors `examples/accrue_host/config/test.exs:44-48`.

**Base-config reader helper** (lines 93–112):

```elixir
defp base_oban_config do
  config_path = Path.expand("../../config/config.exs", __DIR__)

  config_path
  |> Config.Reader.read!(env: :dev)
  |> get_in([:accrue_host, Oban])
end

defp cron_entries(oban_config) do
  oban_config
  |> Keyword.fetch!(:plugins)
  |> Enum.find_value(fn
    {Oban.Plugins.Cron, cron_opts} -> Keyword.get(cron_opts, :crontab, [])
    _ -> nil
  end)
  |> case do
    nil -> []
    crontab -> crontab
  end
end
```

Reuse these helpers; do not add a competing configuration parser/test file.

**Recovery-flow analog:** `accrue/test/accrue/entitlements/offline_reconnect_test.exs:445-492` provides the closest durable lease-recovery setup. Copy its sequence, but substitute the actual `ReconnectSweeper.perform/1` plus actual Oban job execution for injected `insert_job`.

```elixir
assert {:error, :admission_interrupted} =
         Offline.reconnect(account, request, Keyword.put(opts, :after_admission, fn -> :interrupted end))

attempt = Repo.one!(ReconnectAttempt)

{:ok, _} =
  Repo.update(
    ReconnectAttempt.changeset(attempt, %{
      state: :running,
      started_at: DateTime.add(now, -301, :second)
    })
  )

# Phase test: invoke ReconnectSweeper.perform(%Oban.Job{}) here, load the
# produced ReconnectWorker job, and invoke that worker's perform/1.

assert %{state: :completed, attempt_count: 1} = Repo.get!(ReconnectAttempt, attempt.id)
assert 1 == Repo.aggregate(Issuance, :count)
```

The PoP admission must use the established challenge/request helper shape from `offline_reconnect_test.exs:887-910`; do not fabricate a worker-side request. The worker intentionally constructs its own internal request only after it claims an already admitted attempt.

**Test-only adapter/configuration pattern:** retain/restores are required for `:offline_reconnect`, just like this existing application-env fixture pattern (`offline_reconnect_test.exs:121-154`):

```elixir
original = Application.get_env(:accrue, :entitlements)
Application.put_env(:accrue, :entitlements, plans: [...])

on_exit(fn ->
  if original,
    do: Application.put_env(:accrue, :entitlements, original),
    else: Application.delete_env(:accrue, :entitlements)
end)
```

For this phase, capture/restore `Application.get_env(:accrue, :offline_reconnect)` instead. Define nested `InstrumentedDueSourceCoordinator` and `SigningProvider` test modules. The coordinator receives a controlled `%SourceCoordinator.SourceStatus{source: :stripe, environment: :production, due: true, state: :pending, next_action: :reconnect_required}` through host configuration, reports the account/time/config inputs observed by `due_sources/3`, reports the exact handed-off status received by `refresh/4`, and returns that status as resolved. Configure the worker with both modules, `test_pid: self()`, the controlled provider fixture, and valid signing/public-key options. Assert both callback reports against the persisted account and configured fixture, including the absence of any client-proof field. Keep these modules in the test file only; do not write a production key or source adapter merely to make the proof run.

**Worker execution/error semantics:** `accrue/lib/accrue/entitlements/offline/reconnect_worker.ex:6-16`:

```elixir
def perform(%Oban.Job{args: %{"attempt_id" => id}} = job) when is_binary(id) do
  Accrue.Oban.Middleware.put(job)

  case Reconnect.execute_attempt(id) do
    :ok -> :ok
    {:error, :config_invalid} -> {:cancel, :config_invalid}
    {:error, reason} -> {:error, reason}
  end
end
```

Assert `:ok` from the worker and completed/one-issuance persistence, rather than bypassing the worker with `Reconnect.execute_attempt/2`.

## Shared Patterns

### Durable recovery is lock-backed, not scheduler-backed

**Source:** `accrue/lib/accrue/entitlements/offline/reconnect.ex:435-469`.

```elixir
from(a in ReconnectAttempt,
  where:
    (a.state in [:admitted, :retrying] and
       (is_nil(a.next_attempt_at) or a.next_attempt_at <= ^now)) or
      (a.state == :running and not is_nil(a.started_at) and a.started_at <= ^lease_cutoff),
  limit: 100,
  lock: "FOR UPDATE SKIP LOCKED"
)
```

**Apply to:** the recovery proof and any explanatory assertions. Cron only triggers the sweep. Eligible rows, PostgreSQL locks, execution token reset, and the `ReconnectWorker` job make recovery safe under duplicate execution.

### Host-owned worker configuration

**Source:** `accrue/lib/accrue/entitlements/offline/reconnect.ex:473-525`.

```elixir
config =
  Keyword.get(opts, :offline_reconnect, Application.get_env(:accrue, :offline_reconnect))

case validate_worker_config(config) do
  {:ok, config} -> # claim, source refresh, locked issuance
  {:error, :config_invalid} -> mark_configuration_failure(repo, attempt_id, now)
end
```

**Apply to:** host recovery test setup. The sweeper calls `Reconnect.enqueue_due/1`, while `ReconnectWorker` later reads `:accrue, :offline_reconnect`; request-scoped opts are unavailable. The test must temporarily configure a behaviour-conformant source coordinator and key provider.

### Release-contract inclusion

**Source:** `scripts/ci/accrue_host_verify_test_bounded.sh:13-31`.

```bash
test_files=(
  # ...
  test/accrue_host/recovery_wiring_test.exs
  # ...
)
MIX_ENV=test mix test --warnings-as-errors "${test_files[@]}"
```

**Apply to:** the existing test file only. No script or release-gate edit is needed when this file is extended.

## No Analog Found

None. This phase extends existing host configuration and recovery-wiring-test patterns. It should not introduce a new scheduler, a new production `:offline_reconnect` adapter, or a second release-gate test registration.

## Metadata

**Analog search scope:** `examples/accrue_host/config`, `examples/accrue_host/test`, `accrue/lib/accrue/entitlements/offline`, `accrue/test/accrue/entitlements`, `scripts/ci`  
**Files scanned:** 10 focused files  
**Pattern extraction date:** 2026-08-05
