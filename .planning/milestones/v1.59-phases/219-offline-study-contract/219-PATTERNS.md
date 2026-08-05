# Phase 219: Offline study contract - Pattern Map

**Mapped:** 2026-08-03  
**Files analyzed:** 14 planned new/modified files  
**Analogs found:** 13 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/mix.exs` | config | transform | `accrue/mix.exs` | exact |
| `accrue/lib/accrue/entitlements/offline.ex` | context | request-response | `accrue/lib/accrue/entitlements.ex` | role-match |
| `accrue/lib/accrue/entitlements/offline/proof.ex` | model | transform | `accrue/lib/accrue/entitlements/snapshot.ex` | role-match |
| `accrue/lib/accrue/entitlements/offline/verifier.ex` | service | transform | `accrue/test/support/entitlements/offline_golden_vector_verifier.ex` | same-flow test seed |
| `accrue/lib/accrue/entitlements/offline/key_provider.ex` | service/behaviour | request-response | `accrue/lib/accrue/entitlements/apple/verifier.ex` | role-match |
| `accrue/lib/accrue/entitlements/offline/issuer.ex` | service | transform | `accrue/lib/accrue/entitlements/projector.ex` | partial: canonical snapshot transaction |
| `accrue/lib/accrue/entitlements/offline/reconnect.ex` | service | request-response | `accrue/lib/accrue/entitlements/apple/reconciliation.ex` | role-match |
| `accrue/lib/accrue/entitlements/offline/issuance.ex` | model/service | CRUD | `accrue/lib/accrue/entitlements/apple/reconciliation.ex` | role-match |
| `accrue/lib/accrue/entitlements/device.ex` | model | CRUD | `accrue/lib/accrue/entitlements/device.ex` | exact |
| `accrue/priv/repo/migrations/*_offline_entitlement_issuance.exs` | migration | batch | `accrue/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs` | role-match |
| `accrue/priv/entitlements/v1.59-offline-golden-vectors.json` | config/fixture | transform | existing same path + `v1.59-decision-cases.json` | exact evolution |
| `accrue/test/accrue/entitlements/offline_protocol_test.exs` | test | transform | `accrue/test/accrue/entitlements/offline_golden_vectors_test.exs` | role-match |
| `accrue/test/accrue/entitlements/offline_test.exs` | test | request-response | `accrue/test/accrue/entitlements/projector_test.exs` | role-match |
| `accrue/test/accrue/entitlements/offline_reconnect_test.exs` | test | CRUD/request-response | `accrue/test/accrue/entitlements/apple_reconciliation_test.exs` | role-match |

## Pattern Assignments

### `accrue/lib/accrue/entitlements/offline.ex` (context, request-response)

**Analog:** `accrue/lib/accrue/entitlements.ex`

Keep the new public API additive in its own small Phoenix-style context. Accept typed account/device values and keyword options, return tagged domain outcomes, wrap public operations in private telemetry, and do not broaden the existing boolean/scalar gate API.

**Imports/context boundary** (`accrue/lib/accrue/entitlements.ex:50-52`):

```elixir
alias Accrue.Entitlements.{Account, PurchaseDecision, Resolver, Snapshot}
alias Accrue.Entitlements.Apple.{Admission, Intake, Lineage, Reconciliation}
alias Accrue.Entitlements.Source.Registry, as: SourceRegistry
```

**Public tagged-result + telemetry pattern** (`accrue/lib/accrue/entitlements.ex:249-262`):

```elixir
@spec snapshot(Account.t() | term(), keyword()) :: {:ok, Snapshot.t()} | {:error, :not_found}
def snapshot(account_or_billable, opts \\ []) do
  Accrue.Telemetry.span_private(
    [:accrue, :entitlements, :snapshot],
    snapshot_metadata(account_or_billable, opts),
    fn ->
      case snapshot_account(account_or_billable) do
        nil -> {:error, :not_found}
        account -> {:ok, Snapshot.fetch(Accrue.Repo.repo(), account)}
      end
    end
  )
end
```

Use the Apple-facing public functions at `accrue/lib/accrue/entitlements.ex:137-164` as the authorization shape: host-supplied `authorize` callback, account ownership check, then narrow `{:ok, typed_outcome}` or bounded `{:error, reason}`.

### `accrue/lib/accrue/entitlements/offline/proof.ex` (typed model, transform)

**Analog:** `accrue/lib/accrue/entitlements/snapshot.ex`

Make the claims/decision/action-policy values explicit structs with enforced public fields; normalize plans/features deterministically and keep provider evidence out of values. The proof must consume the already canonical snapshot rather than fold grants independently.

**Value-object pattern** (`accrue/lib/accrue/entitlements/snapshot.ex:9-37`):

```elixir
alias Accrue.Entitlements.Grant

@enforce_keys [:account_id, :revision, :plans, :features, :quantities, :sources]
defstruct [:account_id, :revision, :plans, :features, :quantities, :sources, :authorization_bounds]

@type t :: %__MODULE__{
        account_id: Ecto.UUID.t() | String.t(),
        revision: non_neg_integer(),
        plans: [atom()],
        features: [atom()],
        quantities: %{optional(atom()) => pos_integer()}
      }
```

**Deterministic normalization pattern** (`accrue/lib/accrue/entitlements/snapshot.ex:44-65`):

```elixir
%__MODULE__{
  account_id: Keyword.fetch!(opts, :account_id),
  revision: Keyword.get(opts, :revision, 0),
  plans: plans |> MapSet.to_list() |> Enum.sort(),
  features: features |> MapSet.to_list() |> Enum.sort(),
  quantities: quantities,
  authorization_bounds: authorization_bounds
}
```

Implement the four-state classifier only after complete cryptographic/binding/order validation; `fresh_until` is a revalidation boundary, never an inferred hard expiry.

### `accrue/lib/accrue/entitlements/offline/verifier.ex` (service, transform)

**Analog:** `accrue/test/support/entitlements/offline_golden_vector_verifier.ex`

Promote its staged, fail-closed architecture into production code while replacing its fixed test key/legacy claims and handwritten ECDSA mechanics with JOSE strict ES256 verification. Retain Accrue-owned header, duplicate-member, claims, binding, classification, and high-water policy.

**Two-stage validation ordering** (`accrue/test/support/entitlements/offline_golden_vector_verifier.ex:95-106`):

```elixir
def verify(compact, key, context \\ %{}) do
  with {:ok, header, payload, signing_input, signature} <- parse_compact(compact),
       :ok <- fixed_header(header),
       :ok <- verify_signature(key, signing_input, signature),
       :ok <- verify_claims(payload, context),
       :ok <- verify_disposition(payload),
       :ok <- verify_high_water(payload, context) do
    {:ok, payload}
  end
end
```

**Compact parsing/duplicate-sensitive-member gate** (`accrue/test/support/entitlements/offline_golden_vector_verifier.ex:131-156`): split into exactly three base64url segments, decode header/payload/signature, require a 64-byte ES256 signature, decode JSON, and reject duplicate security fields before accepting the parsed compact input.

**High-water is verified before replacement** (`accrue/test/support/entitlements/offline_golden_vector_verifier.ex:205-230`): preserve the ordering gate as a separate stage; never use fixture labels or a candidate cache disposition as authority.

### `accrue/lib/accrue/entitlements/offline/key_provider.ex` (behaviour/service, request-response)

**Analog:** `accrue/lib/accrue/entitlements/apple/verifier.ex` (existing host-implemented cryptographic boundary; no production offline-key provider exists yet).

Copy the project behaviour pattern: declare callbacks and result types in the boundary module; have production/test implementations opt in with `@behaviour`; resolve host configuration at call time. The provider returns signing capability internally and public verification keys/JWKS externally—never Ecto rows or private JWKs.

**Related configured-host boundary:** `accrue/lib/accrue/repo.ex:1-27` documents the project convention: a library facade resolves a host-owned dependency at call time and exposes only the callbacks it needs.

### `accrue/lib/accrue/entitlements/offline/issuer.ex` and `offline/issuance.ex` (service + persistence, transform/CRUD)

**Analogs:** `accrue/lib/accrue/entitlements/projector.ex`; `accrue/lib/accrue/entitlements/apple/reconciliation.ex`

Provider reconciliation runs outside final issuance. Once all due sources are converged, issue only inside a transaction that locks/rereads account and device, reads `Snapshot.fetch/2`, rechecks lifecycle, persists privacy-safe issuance/high-water metadata, and signs allow or deny from that committed state.

**Transaction and row-lock pattern** (`accrue/lib/accrue/entitlements/projector.ex:45-84`):

```elixir
Accrue.Repo.transact(fn repo -> {:ok, project_in_transaction(repo, observation, opts)} end)

account =
  repo.one!(
    from(account in Account,
      where: account.id == ^observation.account_id,
      lock: "FOR UPDATE"
    )
  )

before = Snapshot.fetch(repo, account)
```

**Create-or-lock durable state pattern** (`accrue/lib/accrue/entitlements/apple/reconciliation.ex:504-523`):

```elixir
repo.insert!(Checkpoint.changeset(%Checkpoint{}, attrs),
  on_conflict: :nothing,
  conflict_target: [:lineage_id, :environment]
)

repo.one!(
  from(c in Checkpoint,
    where: c.lineage_id == ^lineage_id and c.environment == ^environment,
    lock: "FOR UPDATE"
  )
)
```

The issuance table must record only redacted/orderable metadata (for example `kid`, revision/high-water, issue/fresh/exp horizons, disposition, bounded correlation); do not archive compact JWS, receipts, provider payload, key material, email, or other identity data.

### `accrue/lib/accrue/entitlements/offline/reconnect.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex`

Use the existing due/retry/wakeup coordinator as the control-flow template. It has explicit due checks, bounded retries, durable repair outcomes, locks, and host-owned worker enqueueing. Keep idempotency/Oban as coalescing—not authorization locking.

**Due/retry classification** (`accrue/lib/accrue/entitlements/apple/reconciliation.ex:281-301`):

```elixir
def due(%{next_due_at: nil}, _now), do: true
def due(%{next_due_at: %DateTime{} = due}, now), do: DateTime.compare(due, now) != :gt
def due(_, _), do: false

def retry_after({:error, {:rate_limited, seconds}}, _attempt, now)
    when is_integer(seconds) and seconds >= 0,
    do: DateTime.add(now, seconds, :second)
```

**Pending/terminal repair pattern** (`accrue/lib/accrue/entitlements/apple/reconciliation.ex:460-499`): increment bounded attempts; save retrying state and `retry_after_at`; schedule durable retry; when exhausted or unrecoverable, persist `:needs_repair`. Phase 219 maps unresolved due sources to a typed `:pending` outcome and must not issue a partial allow.

### `accrue/lib/accrue/entitlements/device.ex` and migration (model + migration, CRUD/batch)

**Analogs:** same `device.ex`; `20260803031000_create_accrue_apple_reconciliation_checkpoints.exs`

Extend the existing account-scoped device identity rather than create a parallel registry. Schema fields and migration constraints should reflect durable lifecycle/ordering guarantees.

**Schema/changeset pattern** (`accrue/lib/accrue/entitlements/device.ex:14-59`):

```elixir
schema "accrue_entitlement_devices" do
  belongs_to(:account, Accrue.Entitlements.Account, type: :binary_id)
  field(:installation_id, :string)
  field(:key_thumbprint, :string)
  field(:state, Ecto.Enum, values: @states, default: :active)
  field(:last_accepted_revision, :integer, default: 0)
  timestamps(type: :utc_datetime_usec)
end

device_or_changeset
|> cast(attrs, @fields)
|> validate_required(@required)
|> check_constraint(:state, name: :accrue_entitlement_devices_state_domain_check)
|> unique_constraint(:installation_id, name: :accrue_entitlement_devices_current_installation_identity_index)
```

**Migration constraints/indexes** (`accrue/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs:5-52`): use `Accrue.Migration.table/2`, binary primary keys, explicit named foreign keys/unique indexes, then named SQL `CHECK` constraints with reversible `execute/2`.

### Golden fixture and tests (config/tests, transform/request-response/CRUD)

**Analogs:** `accrue/priv/entitlements/v1.59-offline-golden-vectors.json`; `accrue/test/accrue/entitlements/offline_golden_vectors_test.exs`; `accrue/test/accrue/entitlements/apple_reconciliation_test.exs`

Evolve—not duplicate—the checked-in corpus. Make vector IDs stable and synthetic; verify expected outcomes by executing verifier code against an explicit binding/high-water context, then assert cache disposition/fault behavior. Use direct public-context calls and the test repo for reconnect locking cases.

**Merge-blocking corpus assertion** (`accrue/test/accrue/entitlements/offline_golden_vectors_test.exs:7-39`):

```elixir
assert {:ok, vectors, observations} = OfflineGoldenVectorVerifier.verify_fixture!()
assert Enum.map(vectors, & &1["id"]) == Enum.map(observations, & &1.id)
assert Enum.any?(observations, &(&1.id == "valid_allow" and &1.result == :accept))
assert Enum.any?(observations, &(&1.id == "valid_signed_denial" and &1.cache == :deny))
assert expected_tuples(vectors) == observed_tuples(observations)
```

**Mutation-sensitive fixture validation** (`accrue/test/accrue/entitlements/offline_golden_vectors_test.exs:57-87`): mutate one canonical vector field at a time and assert the exact diagnostic, duplicate-ID rejection, and schema-version rejection.

For reconnect tests, follow `apple_reconciliation_test.exs` by setting up deterministic fakes/config, asserting tagged outcomes, checking durable row state, and covering retry/rate-limit/lock competition as integration cases.

### `accrue/mix.exs` (config, transform)

**Analog:** `accrue/mix.exs:56-117`

Add `{:jose, "~> 1.11"}` in the core required dependency section beside the existing cryptographic/runtime dependencies. Do not mark it optional: proof issuance and verification compile in library code.

## Shared Patterns

### Public API and privacy-safe telemetry

**Sources:** `accrue/lib/accrue/entitlements.ex:83-108`, `accrue/lib/accrue/entitlements/projector.ex:20-28`

Apply to public Offline calls: explicit specs, tagged bounded values, `Accrue.Telemetry.span_private/3`, and allowlisted metadata. The existing context refuses invalid host configuration with `{:error, :config_invalid}` instead of leaking adapter details.

### Transactional correctness

**Sources:** `accrue/lib/accrue/entitlements/projector.ex:45-84`; `accrue/lib/accrue/entitlements/apple/reconciliation.ex:504-531`

Use `Accrue.Repo.transact/1` and PostgreSQL `FOR UPDATE` for final authorization/issuance. Use unique conflict targets only to establish a single durable row before locking it; neither an Oban unique job nor idempotency key replaces the row lock.

### Host-owned runtime/resources

**Sources:** `accrue/mix.exs:40-54`; `accrue/lib/accrue/repo.ex:1-27`

Keep Repo, Oban, transport route, account authentication, secret/KMS wiring, and optional Plug mounting host-owned. The library exports a small facade/behaviour and pure JWKS rendering rather than starting children.

### Strict proof acceptance then cache order

**Source:** `accrue/test/support/entitlements/offline_golden_vector_verifier.ex:95-106, 205-244`

Verify all compact/header/key/signature/claims/binding/order conditions before candidate replacement. Maintain `{revision, deny precedence, iat, fresh_until}` ordering; rejected candidates leave the prior complete cache untouched, including the crash-before-replace fixture path.

## No Analog Found

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| Host/client durable compare-and-atomic-file-replace reference implementation | utility | file-I/O | The core repository has only the test corpus's logical `cache_after` model; actual secure storage and atomic filesystem/cache ownership belongs to the adopting host. Publish deterministic fixture cases and typed ordering contract instead. |

## Metadata

**Analog search scope:** `accrue/lib/accrue/entitlements`, `accrue/lib/accrue/repo.ex`, `accrue/mix.exs`, entitlement migrations, fixtures, tests, and test support  
**Files scanned:** 18  
**Pattern extraction date:** 2026-08-03
