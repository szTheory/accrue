# Phase 218: Apple observation and repair - Pattern Map

**Mapped:** 2026-08-03  
**Files analyzed:** 18 planned new/modified files  
**Analogs found:** 18 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/entitlements/apple/verifier.ex` | service/behaviour | transform | `entitlements/observation.ex` | partial (bounded validation) |
| `accrue/lib/accrue/entitlements/apple/client.ex` | service/behaviour | request-response | `entitlements/stripe_sync.ex` | role-match |
| `accrue/lib/accrue/entitlements/apple/lineage.ex` | model/service | CRUD | `entitlements/observation.ex` | exact persistence style |
| `accrue/lib/accrue/entitlements/apple/intake.ex` | service | request-response | `entitlements/projector.ex` | data-flow match |
| `accrue/lib/accrue/entitlements/apple/reconciliation.ex` | service | batch | `entitlements/reconcile.ex` | data-flow match |
| `accrue/lib/accrue/entitlements/apple/reconcile_worker.ex` | worker | batch | `entitlements/stripe_sync/refresh_worker.ex` | exact |
| `accrue/lib/accrue/entitlements.ex` | context | request-response | itself / `purchase_decision.ex` | exact |
| `accrue/lib/accrue/entitlements/observation.ex` | model | CRUD | itself | exact extension |
| `accrue/lib/accrue/entitlements/projector.ex` | service | transform | itself | exact extension |
| `accrue/lib/accrue/entitlements/decision_cases.ex` | utility/fixture contract | transform | `test/support/entitlements/fixtures.ex` | role-match |
| `accrue/priv/repo/migrations/*apple*.exs` | migration | CRUD | `20260802150000_create_accrue_entitlement_persistence.exs` | exact |
| `accrue/test/support/entitlements/fixtures.ex` | test utility | transform | itself | exact extension |
| `accrue/test/accrue/entitlements/apple_verifier_test.exs` | test | transform | `entitlements/projector_test.exs` | role-match |
| `accrue/test/accrue/entitlements/apple_lineage_test.exs` | test | CRUD | `entitlements/projector_test.exs` | data-flow match |
| `accrue/test/property/apple_lineage_property_test.exs` | test | event-driven | `test/property/entitlements_fail_closed_property_test.exs` | role-match |
| `accrue/test/accrue/entitlements/apple_intake_test.exs` | test | request-response | `entitlements/projector_test.exs` | data-flow match |
| `accrue/test/property/apple_convergence_property_test.exs` | test | batch | `test/property/entitlements_fail_closed_property_test.exs` | role-match |
| `accrue/test/accrue/entitlements/apple_reconciliation_test.exs` and `apple_source_isolation_test.exs` | test | batch / request-response | `stripe_sync_refresh_worker_test.exs`, `source_test.exs` | role-match |

## Pattern Assignments

### Apple verifier, client, and closed outcome values

**Analog:** `accrue/lib/accrue/entitlements/observation.ex`

Use a private typed seam with allowlisted values and explicit specs; raw JWS never becomes an Ecto field or generic metadata. Preserve only normalized, bounded facts before returning to intake.

**Privacy and schema boundary** ([`observation.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/observation.ex:1), lines 1-31):

```elixir
@moduledoc """Privacy-bounded, rail-qualified entitlement evidence received from a provider."""
@rails [:stripe, :apple]
@environments [:production, :sandbox]
@metadata_sources ["apple_server", "fake_observer"]
```

**Closed validation / database-error mapping** (lines 70-125):

```elixir
%__MODULE__{}
|> cast(normalize_optional_identities(attrs), @ingest_fields)
|> validate_required(@required_fields)
|> validate_identity()
|> validate_number(:provider_order, greater_than_or_equal_to: 0)
|> unique_constraint(:provider_event_id, name: :accrue_entitlement_observations_provider_event_identity_index)
|> check_constraint(:rail, name: :accrue_entitlement_observations_rail_domain_check)
```

Implement `Apple.Verifier` and `Apple.Client` as behaviours with deterministic Fake implementations. Production adapters remain private and return typed verified facts or closed error/disposition values; never expose JOSE or dependency structs through `Accrue.Entitlements`.

### `apple/lineage.ex` and `apple/intake.ex`

**Analogs:** `observation.ex` and `projector.ex`

**Idempotent identity ownership** ([`observation.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/observation.ex:128), lines 128-153):

```elixir
case repo.insert(changeset, on_conflict: :nothing, conflict_target: conflict_target(changeset)) do
  {:ok, _observation} -> resolve_identity_owner(repo, changeset)
  {:error, error_changeset} -> {:error, error_changeset}
end

if observation.account_id == get_field(changeset, :account_id) do
  {:ok, observation}
else
  {:error, add_error(changeset, :account_id, "provider identity is already owned")}
end
```

**Lock and sole-writer handoff** ([`projector.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/projector.ex:43), lines 43-78):

```elixir
Accrue.Repo.transact(fn repo ->
  account = repo.one!(from(account in Account,
    where: account.id == ^observation.account_id, lock: "FOR UPDATE"))

  case apply_observation(repo, observation, opts) do
    :noop -> {:ok, {:noop, :stale}}
    :changed -> # refresh snapshot, revision, audit, enqueue inside transaction
  end
end)
|> unwrap_transaction()
```

`Lineage` must use the same transaction style but lock by `(rail, environment, original_transaction_id)`, re-read binding under the lock, then bind exactly once. `Intake` is the only Apple caller allowed to create a qualified `Observation` and immediately call `Projector.project/2`; unbound/conflict/invalid results stay outside `Observation`.

### `apple/reconciliation.ex` and `apple/reconcile_worker.ex`

**Analogs:** `entitlements/reconcile.ex`; `entitlements/stripe_sync/refresh_worker.ex`

**Stale/idempotent result convention** ([`reconcile.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/reconcile.ex:36), lines 36-88):

```elixir
Repo.transact(fn ->
  case Repo.get_by(Customer, processor_id: cus_id, processor: to_string(processor)) do
    %Customer{} = customer ->
      case check_stale(row, synced_at, evt_id) do
        :stale_same -> {:ok, :stale}
        :stale -> {:ok, :stale}
        :ok -> write_summary(%{...})
      end
    _ -> {:ok, :deferred}
  end
end)
```

**Thin host-owned worker** ([`refresh_worker.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex:1), lines 1-35):

```elixir
use Oban.Worker, queue: :accrue_webhooks, max_attempts: 25

def perform(%Oban.Job{args: %{"customer_id" => customer_id}} = job) do
  Accrue.Oban.Middleware.put(job)
  # load scalar id, delegate once, map domain result to Oban result
end
```

Keep job args scalar and privacy-safe (never JWS/token). The worker delegates to `Reconciliation`; the checkpoint service owns immutable filter fingerprint, pending revision, attempts, bounded pages, and final-page-only completion. Return explicit retry/cancel/domain results rather than letting retry exhaustion erase `needs_repair`.

### `entitlements.ex`, `projector.ex`, and `source/registry.ex`

**Analog:** `entitlements.ex` public context and `source/registry.ex` Apple capability declaration.

**Public context telemetry and typed result shape** ([`entitlements.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/entitlements.ex:52), lines 52-70):

```elixir
def purchase_decision(account, rail, product_id, opts \\ []) do
  metadata = purchase_decision_metadata(account, rail, opts)

  Accrue.Telemetry.span_private([:accrue, :entitlements, :purchase_decision], metadata, fn ->
    case decision_snapshot(account, opts) do
      {:ok, snapshot} -> PurchaseDecision.evaluate(snapshot, rail, product_id, ...)
      {:error, reason} -> {:error, reason}
    end
  end)
end
```

**Apple external-management contract** ([`registry.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/entitlements/source/registry.ex:69), lines 69-98):

```elixir
{:ok, :externally_managed,
 guidance(:manage_apple_subscription,
   "Manage this subscription in Apple.", "Manage subscription", @apple_url)}
```

Add the small public Apple facade (`purchase context/token`, observation, repair, explicit reconciliation) with `span_private`, allowlisted metadata, and tagged value objects. Reuse Registry guidance unchanged; Apple modules must have no `Billing.SubscriptionActions` / Stripe lifecycle dependency.

### Migrations and schema extensions

**Analog:** `20260802150000_create_accrue_entitlement_persistence.exs`

**Qualified table + partial unique identity** ([migration](/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs:20), lines 20-68):

```elixir
create Accrue.Migration.table(:accrue_entitlement_observations, primary_key: false) do
  add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))
  add(:rail, :string, null: false)
  add(:environment, :string, null: false)
  timestamps(type: :utc_datetime_usec)
end

create Accrue.Migration.unique_index(:accrue_entitlement_observations,
  [:rail, :environment, :provider_event_id],
  where: "provider_event_id IS NOT NULL", name: :accrue_entitlement_observations_provider_event_identity_index)
```

Create separate lineage, durable quarantine/intake, and reconciliation-checkpoint tables. Use `Accrue.Migration.table/unique_index/references`, named constraints mirrored by changesets, environment in every provider identity, and partial uniqueness for the one immutable account binding.

### Fixtures and tests

**Analogs:** `test/support/entitlements/fixtures.ex`; `projector_test.exs`; `stripe_sync_refresh_worker_test.exs`; `test/property/entitlements_fail_closed_property_test.exs`.

**Deterministic privacy-safe fixture idiom** ([`fixtures.ex`](/Users/jon/projects/accrue/accrue/test/support/entitlements/fixtures.ex:1), lines 1-15 and 70-91):

```elixir
@timestamp ~U[2026-08-02 15:00:00.000000Z]
@pairs for(rail <- [:stripe, :apple], environment <- [:production, :sandbox], do: {rail, environment})

%{rail: rail, environment: environment, provider_event_id: "evt_fake_#{suffix}",
  metadata: %{"source" => "fake_observer"}, evidence_digest: digest(rail, environment)}
```

**Repo + Oban integration test setup** ([`projector_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/entitlements/projector_test.exs:1), lines 1-7 and 87-96):

```elixir
use Accrue.RepoCase, async: false
use Oban.Testing, repo: Accrue.TestRepo

assert {:noop, :stale} = Projector.project(observation)
assert {:noop, :not_qualified} = Projector.project(%{observation | state: :quarantined})
```

Use Fake-first verifier/client fixtures, concurrency tasks only around real database locking, and property tests for permutation/order and bind-once invariants. Tests must assert raw JWS/tokens/PII do not appear in rows, job args, telemetry, or inspect output.

## Shared Patterns

### Database authority and idempotency

**Sources:** `observation.ex:128-153`, `projector.ex:43-78`  
**Apply to:** lineage binding, qualified observation admission, checkpoint completion.

PostgreSQL partial unique indexes plus `FOR UPDATE` transactions are the authority; Oban uniqueness is only enqueue deduplication. Re-select the identity after `on_conflict: :nothing` rather than assuming an Elixir pre-check is safe.

### Projection and ordering

**Source:** `projector.ex:81-112`  
**Apply to:** normalized Apple facts only.

```elixir
current != [] and Enum.all?(current, &(&1.provider_order >= observation.provider_order)) -> :noop
current != [] and retraction?(observation) -> supersede!(repo, current); :changed
```

Extend the ordering comparison to a complete Apple tuple without giving any Apple module direct `Grant` writes.

### Telemetry and privacy

**Source:** `projector.ex:220-232`  
**Apply to:** every public Apple entry point and outcome.

```elixir
%{revision: ..., action: :project, rail: observation.rail,
  environment: observation.environment, disposition: observation.state,
  reason: nil, account_id: observation.account_id, actor_id: hashed_actor_id(...)}
|> Map.take(@metadata_keys)
```

Use allowlisted metadata only and hash actor correlation. Never add raw provider evidence, tokens, notification bodies, or Apple IDs to telemetry/audit/Oban args.

## No Analog Found

| File/concern | Role | Data Flow | Direction |
|---|---|---|---|
| Strict Apple x5c + nested JWS verifier | service | transform | No crypto analogue exists; apply the private behaviour/Fake pattern and RESEARCH.md’s locked checks. |
| Final-page Apple History cursor protocol | service | batch | No Apple pagination analogue; adapt `Reconcile` idempotency but implement the research contract directly. |

## Metadata

**Analog search scope:** `accrue/lib/accrue/entitlements`, `accrue/lib/accrue/telemetry`, `accrue/priv/repo/migrations`, entitlement/property tests  
**Files scanned:** 18 primary analogs and supporting files  
**Pattern extraction date:** 2026-08-03
