# Phase 216: Additive rail and persistence foundation - Research

**Researched:** 2026-08-02
**Domain:** Elixir/Phoenix runtime configuration, Ecto/PostgreSQL durable entitlement records
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Rail Registration and Legacy Aliasing
- **D-01:** Keep `config :accrue, :processor` unchanged as the supported alias for the default controllable gateway rail. Add opt-in `rails` and `default_rail` configuration beside it; omitting both preserves legacy single-processor behavior.
- **D-02:** A configured `default_rail` must name a registered controllable gateway rail and must agree with the legacy `processor` alias. Reject contradictory or ambiguous configuration at boot rather than selecting a rail by list order.
- **D-03:** Stripe and Apple are the only production rails in v1.59; the existing deterministic host-fake source remains a test/proof facility, not a third production billing rail. Apple registration is an entitlement source/observer and must not be coerced into `Accrue.Processor`.

### Rail-Qualified Product Catalog
- **D-04:** Extend each existing logical plan with a nested rail/environment-qualified product mapping. Use the Phase-215 contract vocabulary (`:production`, `:sandbox`; `:offline` remains a decision-case/proof environment, not a provider product catalog environment).
- **D-05:** Preserve `price_ids` as shorthand for the configured default rail and that rail's configured default environment. Bare identifiers never apply to every rail or environment.
- **D-06:** Uniqueness is enforced on the qualified tuple `{rail, environment, product_id}`. The same raw identifier may exist on different rails or environments, but one qualified tuple cannot map to two logical plans. A bare alias and a qualified entry that resolve to conflicting plans fail boot validation; repeats within one plan may normalize to one value.

### Durable Record Identity and Uniqueness
- **D-07:** Add separate UUID-backed entitlement account, grant, observation, and device records using `Accrue.Migration`, the configured billing prefix, UTC microsecond timestamps, database constraints/indexes, and matching changeset validation. Database constraints—not application prechecks alone—are the concurrency authority.
- **D-08:** An entitlement account is stable and unique per `(owner_type, owner_id)`. Its UUID is the future Apple `appAccountToken`; it is never derived from email or another mutable identifier. Start revision at zero, but Phase 217 owns projector writes and revision advancement.
- **D-09:** Grants are rail-, environment-, account-, lineage-, and product-qualified. Preserve observation history separately; enforce one current logical grant with a partial unique index over the deterministic current-row key rather than globally uniquing a provider lineage. Every external transaction/event identity is scoped by rail and environment.
- **D-10:** Observations are the durable quarantine/retry and provenance boundary, separate from existing gateway webhook rows. Enforce provider-event identity when present and transaction-plus-kind identity otherwise; duplicates are idempotent and cannot create duplicate durable observations.
- **D-11:** Foundation migrations are additive and forward-only: do not rewrite existing customers/subscriptions, create legacy-account backfills, or switch entitlement reads. Phase 217 owns backfill, parity/shadow mode, projector transactions, and cutover.

### Observation Evidence Retention
- **D-12:** Observation rows store normalized/redacted fields, bounded metadata, and an evidence digest. They never store raw receipts, JWS bodies, notification bodies, adopter identity, or PII in row-visible `data`.
- **D-13:** When later Apple verification or replay requires retained signed material, the row may hold only a nullable opaque reference to separately encrypted material plus an explicit expiry. The reference is non-diagnostic and non-telemetry data; Phase 216 does not invent a universal retention duration.

### Account-Scoped Device Identity
- **D-14:** Scope installation and key registration uniqueness to the entitlement account so one physical installation/key can be registered to another authenticated account. Future proofs remain bound to both account UUID and recomputed key thumbprint; account scoping does not weaken proof verification.
- **D-15:** Preserve device revocation/history rather than deleting rows to permit re-registration. Use partial uniqueness for current registrations so key rotation or account switching creates an auditable state transition without erasing the prior identity.

### Fake-First Proof and Propagation
- **D-16:** Ship deterministic Fake observer/record fixtures that cover both rails, both provider environments, collision rejection, duplicate observation idempotency, current-grant uniqueness, device account switching, and durable revocation. No live Stripe, Apple sandbox, Crosswake runtime, or physical-device evidence is required in this phase.
- **D-17:** Propagate the additive configuration and migrations through the installer, generated host migration path, examples, configuration validation, and compatibility tests in the same phase. A legacy host with only `processor` and `price_ids` must remain valid without new required keys or behavior changes.

### the agent's Discretion
The planner may choose exact internal modules, schema module names, constraint names, and whether the qualified catalog is represented internally as validated keywords, maps, or structs. It may also choose the opaque evidence-store behaviour name. These choices must preserve the public semantics above, the Phase-215 closed rail/environment vocabulary, the no-inline-raw-evidence rule, deterministic error reporting, and host-owned Repo/runtime-resource boundaries.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within Phase 216. Projection/backfill/cutover remain Phase 217; Apple verification and repair remain Phase 218; offline proof issuance and device runtime remain Phase 219; adopter diagnostics and release proof remain Phase 220.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RAIL-01 | Concurrent Stripe and Apple registration while `processor` remains the default alias. | Additive config schema, cross-field boot guard, closed registry vocabulary, compatibility tests. |
| RAIL-02 | Rail/environment-qualified product mapping without collisions. | Nested plan catalog plus one qualified-tuple collision reducer and default-rail alias resolution. |
| RAIL-03 | Stable accounts, qualified observations/grants, devices, provenance, quarantine, ordering, transactional uniqueness. | Four Ecto schemas/migration and named database constraints/indexes; fixture-driven `RepoCase` proof. |
</phase_requirements>

## Summary

[VERIFIED: codebase grep] Implement Phase 216 as an additive configuration-and-persistence slice: extend `Accrue.Config` beside—not in place of—`:processor`, introduce rail-qualified plan-product normalization at boot, and add four independent Ecto schemas backed by forward-only `Accrue.Migration` migrations. Existing legacy `price_ids` must normalize to exactly one qualified default-rail/default-environment entry, while new `products` entries always remain explicitly rail and environment scoped.

[VERIFIED: codebase grep] The durable model must deliberately keep cross-rail access identity separate from money/gateway identity: `Accrue.Billing.Customer` remains processor-qualified, while one entitlement account is unique to a host owner. Observation history is a separate bounded, privacy-safe quarantine/provenance boundary; it must not reuse `accrue_webhook_events`, whose present purpose includes gateway-specific raw-body replay.

[CITED: https://ecto.hexdocs.pm/Ecto.Changeset.html] Database constraints must be the concurrency authority. Ecto changesets should expose named database violations as usable errors, but neither `unsafe_validate_unique/4` nor an application precheck can substitute for the unique/partial indexes under concurrent writes. [CITED: https://www.postgresql.org/docs/current/indexes-partial.html]

**Primary recommendation:** Extend `Accrue.Config` with a deterministic rail catalog normalizer and ship four `Accrue.Schema` modules plus schema-qualified, named PostgreSQL unique/partial indexes; prove both legacy compatibility and all durable identity collisions using the existing real-Postgres test lane.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Rail registration/default alias | API / Backend | — | `Accrue.Config` owns runtime validation; host config is its input. [VERIFIED: codebase grep] |
| Qualified plan-product catalog | API / Backend | — | Catalog normalization and collision detection are boot-time domain rules. [VERIFIED: codebase grep] |
| Entitlement account/grant/observation/device persistence | Database / Storage | API / Backend | PostgreSQL enforces identity; Ecto schemas expose it to later contexts. [VERIFIED: codebase grep] |
| Fake-first fixtures and compatibility proof | API / Backend | Database / Storage | ExUnit exercises configuration and real repository constraints without live providers. [VERIFIED: codebase grep] |
| Apple/Stripe live verification and projector writes | — | — | Explicitly deferred to Phases 217–219. [VERIFIED: 216-CONTEXT.md] |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists. Applicable repository directives from `CLAUDE.md`: Elixir 1.19+, OTP 27+, Ecto/Ecto SQL 3.13+, PostgreSQL 14+; hosts own Repo and runtime resources; `Accrue.Application` stays childless; use `Accrue.Migration` for configured billing-prefix migrations; use runtime reads for host-owned catalog data; mandatory webhook verification and sensitive-field/PII protections remain in force. [VERIFIED: CLAUDE.md; codebase grep]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | `~> 3.13` (project pin) | schemas, changesets, constraints | Existing schema and changeset convention. [VERIFIED: accrue/mix.exs] |
| Ecto SQL | `~> 3.13` (project pin) | migrations and PostgreSQL indexes | Existing `Accrue.Migration` helpers wrap it with the billing prefix. [VERIFIED: accrue/mix.exs; codebase grep] |
| PostgreSQL | 14+ (project floor) | UUID defaults, composite and partial unique indexes | Required database authority for concurrent uniqueness. [VERIFIED: CLAUDE.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NimbleOptions | `~> 1.1` (project pin) | structural config validation | Keep public config shape validation in `Accrue.Config`; use a separate cross-entry reducer for collision checks. [VERIFIED: accrue/mix.exs; codebase grep] |
| ExUnit + Ecto SQL Sandbox | project test stack | deterministic real-DB tests | Use `Accrue.RepoCase` for migration/index/idempotency tests. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Database unique/partial indexes | application uniqueness precheck | Rejected: races remain possible; Ecto documents DB constraints as the safe, data-race-free boundary. [CITED: https://ecto.hexdocs.pm/Ecto.Changeset.html] |
| Separate observations | extend `accrue_webhook_events` | Rejected: existing gateway rows intentionally retain raw body, violating the no-inline-evidence decision. [VERIFIED: codebase grep; 216-CONTEXT.md] |

**Installation:** No package installation. [VERIFIED: accrue/mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
Host config
  │ processor (legacy) + optional rails/default_rail + entitlement plans
  ▼
Accrue.Config boot validation ──invalid/ambiguous──► Accrue.ConfigError
  │ normalized default rail + qualified product tuples
  ├──────────────────────────────────────────────► existing LocalMap stays valid
  ▼
Accrue.Migration forward-only migrations
  ▼
PostgreSQL billing prefix
  ├── entitlement_accounts ──1:N──► grants (current-row partial uniqueness)
  ├── observations (event/transaction idempotency; quarantine/retry)
  └── devices (account-scoped current registration; durable revocation)
  ▼
Deterministic Fake fixtures / RepoCase
  └── compatibility, collision, idempotency and durable-history proof
```

### Recommended Project Structure

```text
accrue/
├── lib/accrue/config.ex                         # additive schema/accessors/cross-entry guards
├── lib/accrue/entitlements/{account,grant,observation,device}.ex
├── priv/repo/migrations/*_create_accrue_entitlement_*.exs
├── lib/mix/tasks/accrue.install.ex               # generated host migration/config propagation
└── test/accrue/{config_entitlements_test,entitlements/*_test}.exs
```

### Pattern 1: Structural validation, then cross-entry normalization

**What:** Define `rails`, `default_rail`, and nested plan `products` in the existing NimbleOptions schema; then run one deterministic boot validator over the whole raw config to resolve aliases and reject tuple collisions.

**When to use:** Always for RAIL-01/02. Existing `validate_entitlements_price_ids!/1` already uses this shape because a per-field validator cannot see collisions across plans. [VERIFIED: codebase grep]

**Example:**

```elixir
# Follow the existing `validate_entitlements_price_ids!/1` reducer pattern.
Enum.reduce(qualified_products, %{}, fn %{rail: rail, environment: env, product_id: id, plan: plan}, seen ->
  key = {rail, env, id}

  case Map.fetch(seen, key) do
    {:ok, ^plan} -> seen
    {:ok, other} -> raise Accrue.ConfigError, key: :entitlements,
      message: "product #{inspect(key)} mapped to both #{inspect(other)} and #{inspect(plan)}"
    :error -> Map.put(seen, key, plan)
  end
end)
```

Source: existing `Accrue.Config.validate_entitlements_price_ids!/1`. [VERIFIED: codebase grep]

### Pattern 2: Named database constraints mirrored in changesets

**What:** Give each migration index a stable explicit name, then attach `unique_constraint/3` / `foreign_key_constraint/3` to the appropriate schema changeset using that name.

**When to use:** For every owner, current-grant, observation identity, and active device identity invariant.

**Example:**

```elixir
create Accrue.Migration.unique_index(:accrue_entitlement_accounts, [:owner_type, :owner_id],
  name: :accrue_entitlement_accounts_owner_identity_index
)

def changeset(account, attrs) do
  account
  |> cast(attrs, [:owner_type, :owner_id, :revision])
  |> validate_required([:owner_type, :owner_id])
  |> unique_constraint(:owner_id, name: :accrue_entitlement_accounts_owner_identity_index)
end
```

[VERIFIED: codebase grep] This matches `Accrue.Billing.Customer`; [CITED: https://ecto.hexdocs.pm/Ecto.Changeset.html] Ecto returns a named constraint failure as an error changeset after `Repo.insert/2`.

### Pattern 3: Current-state uniqueness without destroying history

**What:** Preserve grant/device history using status/supersession or revocation columns; constrain only the active/current subset with a partial unique index.

**When to use:** Current grant logical key and current device installation/key registrations.

**Example:**

```elixir
create Accrue.Migration.unique_index(
  :accrue_entitlement_grants,
  [:account_id, :rail, :environment, :lineage_id, :product_scope],
  where: "superseded_at IS NULL",
  name: :accrue_entitlement_grants_current_logical_key_index
)
```

[CITED: https://www.postgresql.org/docs/current/indexes-partial.html] PostgreSQL partial indexes index only rows satisfying the predicate. [VERIFIED: codebase grep] Existing migrations already use partial indexes for state-specific operational queries.

### Anti-Patterns to Avoid

- **Replacing `:processor` with a rail map:** Breaks legacy hosts; retain it as the default controllable gateway alias. [VERIFIED: 216-CONTEXT.md]
- **Using bare IDs globally:** A bare `price_id` is only the default rail/default environment alias. [VERIFIED: 216-CONTEXT.md]
- **`unique(account_id, rail, environment, lineage_id)` grants:** One lineage may have multiple concurrent product items; include deterministic product scope and limit uniqueness to current rows. [VERIFIED: v1.59-ARCHITECTURE.md]
- **Using NULL product IDs inside a unique key:** PostgreSQL permits distinct NULLs; use a non-null product/scope surrogate for unknown products. [VERIFIED: v1.59-ARCHITECTURE.md]
- **Reusing gateway webhook rows:** They carry `raw_body`; observations must remain redacted and bounded. [VERIFIED: codebase grep; 216-CONTEXT.md]
- **Backfill/projector/cutover in this phase:** Those writes and revision advancement are Phase 217 scope. [VERIFIED: 216-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Concurrent uniqueness | pre-insert `Repo.exists?` checks | PostgreSQL unique/partial indexes + Ecto constraint mapping | DB enforcement survives races and produces actionable changeset errors. [CITED: https://ecto.hexdocs.pm/Ecto.Changeset.html] |
| Billing-prefix qualification | ad hoc schema strings in each migration | `Accrue.Migration.table/references/index/unique_index` | Preserves host-selected prefix consistently. [VERIFIED: codebase grep] |
| UUID identity | email-derived or application-composed IDs | `:binary_id` with `gen_random_uuid()` precedent | Stable opaque identifier matches existing tables and cannot change with owner attributes. [VERIFIED: codebase grep; 216-CONTEXT.md] |
| Rail/environment vocabulary | new open-ended atoms | `Accrue.Entitlements.DecisionCases` / source registry vocabulary | Phase 215 already has the Stripe/Apple and production/sandbox contract. [VERIFIED: codebase grep] |

**Key insight:** The difficult edge cases are collision scope and concurrent writes, not schema boilerplate; reuse the project’s migration/changeset conventions and let PostgreSQL decide uniqueness. [VERIFIED: codebase grep; CITED: https://ecto.hexdocs.pm/Ecto.Changeset.html]

## Common Pitfalls

### Pitfall 1: Default rail ambiguity

**What goes wrong:** A host registers several rails but `default_rail` is missing, non-gateway, unregistered, or disagrees with `:processor`; behavior then depends on configuration order.

**How to avoid:** Normalize the legacy-only mode to one default controllable rail; when `rails` is present, require an explicit, registered controllable `default_rail` whose adapter agrees with `:processor`, then fail boot deterministically. [VERIFIED: 216-CONTEXT.md]

### Pitfall 2: Identifier collisions hidden by legacy aliases

**What goes wrong:** An alias resolves to one plan while its qualified `{rail, environment, id}` entry resolves to another, or Apple sandbox/production IDs are treated as globally unique.

**How to avoid:** Expand all `price_ids` aliases to the configured default tuple before reducing the full catalog by `{rail, environment, product_id}`; report both plans and the complete tuple. [VERIFIED: 216-CONTEXT.md]

### Pitfall 3: Historical data destroyed by active-row enforcement

**What goes wrong:** Global uniqueness blocks legitimate lineage product changes, or deleting a device to re-register it removes audit/revocation history.

**How to avoid:** Use a deterministic current-row key with a partial index and record supersession/revocation. [VERIFIED: 216-CONTEXT.md; CITED: https://www.postgresql.org/docs/current/indexes-partial.html]

### Pitfall 4: Sensitive evidence enters queryable rows

**What goes wrong:** Raw receipt/JWS/notification bodies enter observation `data`, fixtures, logs, or telemetry.

**How to avoid:** Permit only normalized/redacted bounded metadata and digest; future replay material is an opaque encrypted-store reference plus expiry, never row-visible diagnostic data. [VERIFIED: 216-CONTEXT.md]

## Code Examples

### Idempotent observation identity migration

```elixir
create Accrue.Migration.unique_index(:accrue_entitlement_observations,
  [:rail, :environment, :provider_event_id],
  where: "provider_event_id IS NOT NULL",
  name: :accrue_entitlement_observations_provider_event_identity_index
)

create Accrue.Migration.unique_index(:accrue_entitlement_observations,
  [:rail, :environment, :provider_transaction_id, :kind],
  where: "provider_event_id IS NULL AND provider_transaction_id IS NOT NULL",
  name: :accrue_entitlement_observations_transaction_kind_identity_index
)
```

[VERIFIED: 216-CONTEXT.md] This is the required event-first, transaction-plus-kind fallback identity; it must be paired with matching named changeset constraints.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One gateway `processor` and unqualified `price_ids` | Additive rail registry and rail/environment-qualified catalog; old shape aliases the default only | Phase 216 contract | Allows Stripe + Apple evidence without legacy breakage. [VERIFIED: 216-CONTEXT.md] |
| `Billing.Customer` as processor money identity | Separate owner-stable entitlement account | Phase 216 contract | Avoids conflating gateway customer and cross-rail access identity. [VERIFIED: v1.59-ARCHITECTURE.md] |

**Deprecated/outdated:** Treating Stripe’s advisory entitlement-summary cache as canonical entitlement state is not permitted; it remains observational-only. [VERIFIED: 216-CONTEXT.md]

## Assumptions Log

All claims in this research were verified against the phase context, current codebase, or cited official Ecto/PostgreSQL documentation — no user confirmation needed.

## Open Questions (RESOLVED)

1. **Exact public `rails` / nested `products` syntax — RESOLVED**
   - Phase 216 uses keyword lists throughout so the public shape is directly expressible in the existing NimbleOptions schema. The canonical registration is `rails: [stripe: [source: :stripe, processor: Accrue.Processor.Stripe, environments: [:production, :sandbox], default_environment: :production], apple: [source: :apple, environments: [:production, :sandbox], default_environment: :production]]` beside `default_rail: :stripe` and the unchanged top-level `processor: Accrue.Processor.Stripe`. Apple has no `processor` entry. Omitting both `rails` and `default_rail` remains legacy mode per D-01 through D-03.
   - Each logical plan remains under `entitlements: [plans: ...]` and adds `products: [stripe: [production: ["price_pro"], sandbox: ["price_pro_test"]], apple: [production: ["com.example.pro"], sandbox: ["com.example.pro.sandbox"]]]`. Existing `price_ids: [...]` remains a sibling inside that logical plan and expands only to the configured default rail/default environment per D-04/D-05. The normalized public accessor returns a deterministic map keyed by `{rail, environment, product_id}` and valued by logical plan; D-06 governs equality and collisions.
2. **Opaque encrypted-evidence store behaviour name and implementation seam — RESOLVED**
   - Phase 216 defines no evidence-store behaviour, module name, adapter callback, encryption API, read/write/delete operation, or retention policy. Its complete seam is the observation schema's nullable opaque `evidence_ref` plus nullable UTC-microsecond `evidence_expires_at`; when retained material is referenced, both values are present, and otherwise both are null. The row continues to hold only normalized/redacted data and the fixed evidence digest per D-12/D-13.
   - Phase 218 may define separately encrypted storage and purpose-specific retention when Apple verification/replay requirements are implemented. No universal duration or implicit cleanup behavior is introduced by Phase 216.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | schemas/migrations/tests | ✓ | 1.19.5 | — |
| Erlang/OTP | Elixir runtime | ✓ | 28 | — |
| Mix | compile/test | ✓ | 1.19.5 | — |
| PostgreSQL client | inspect/debug DB behaviour | ✓ | 14.17 | existing test Repo/Sandbox |
| Docker | optional local service workflow | ✓ | 29.5.2 | existing PostgreSQL test setup |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Ecto SQL Sandbox [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test test/accrue/config_entitlements_test.exs` |
| Full suite command | `cd accrue && mix test.all` [VERIFIED: accrue/mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RAIL-01 | Legacy `processor`/`price_ids` remains valid; concurrent Stripe+Apple config resolves deterministically; contradictions fail at boot | unit/config | `cd accrue && mix test test/accrue/config_entitlements_test.exs` | ✅ extend |
| RAIL-02 | tuple collisions and alias-vs-qualified conflicts reject; cross-rail/environment same raw ID accepts | unit/config | `cd accrue && mix test test/accrue/config_entitlements_test.exs` | ✅ extend |
| RAIL-03 | migrations create prefix-qualified tables; unique/partial constraints reject races/duplicates and retain history | integration/DB | `cd accrue && mix test test/accrue/entitlements` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** targeted `mix test` for touched config/schema test file.
- **Per wave merge:** `cd accrue && mix test`.
- **Phase gate:** `cd accrue && mix test.all` green before verification.

### Wave 0 Gaps

- [ ] `accrue/test/accrue/entitlements/persistence_test.exs` — RAIL-03 migrations, constraints, idempotency, current grant/device history.
- [ ] `accrue/test/accrue/entitlements/fake_fixture_test.exs` — both rails/environments and deterministic record fixtures.
- [ ] Extend `accrue/test/accrue/config_entitlements_test.exs` — RAIL-01/02 compatibility and catalog collision matrix.
- [ ] Extend installer/generated-host migration tests — D-17 propagation path.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Account creation/linking remains host-authenticated; no owner-ID lookup API. [VERIFIED: v1.59-ARCHITECTURE.md] |
| V3 Session Management | no | No session state is introduced in this foundation. [VERIFIED: 216-CONTEXT.md] |
| V4 Access Control | yes | Do not expose opaque account/evidence references as public authorization bypasses. [VERIFIED: v1.59-ARCHITECTURE.md] |
| V5 Input Validation | yes | NimbleOptions closed vocabularies + changesets + DB constraints. [VERIFIED: codebase grep] |
| V6 Cryptography | limited | No proof/JWS verification implementation now; only opaque evidence references with explicit expiry. [VERIFIED: 216-CONTEXT.md] |

### Known Threat Patterns for Ecto/PostgreSQL persistence

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Concurrent duplicate account/grant/observation/device rows | Tampering | Named composite/partial unique indexes, matching changeset constraints, real-DB tests. [CITED: https://ecto.hexdocs.pm/Ecto.Changeset.html; https://www.postgresql.org/docs/current/indexes-partial.html] |
| Sandbox evidence accepted as production | Tampering | Include rail and environment in all provider identity keys and catalog lookups. [VERIFIED: 216-CONTEXT.md] |
| Raw evidence/PII leaked via data/logs | Information disclosure | Store digest + bounded redacted metadata; opaque encrypted-store ref only. [VERIFIED: 216-CONTEXT.md] |
| Account switching erases revoked device history | Repudiation | Durable revocation/supersession with current-only partial uniqueness. [VERIFIED: 216-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `216-CONTEXT.md` — locked Phase 216 semantics, exclusions, privacy, fixtures, compatibility.
- `accrue/lib/accrue/config.ex`, `billing/customer.ex`, `migration.ex`, `schema.ex` — existing config, schema, migration, and constraint patterns.
- `accrue/test/support/repo_case.ex`, `test_helper.exs`, `config_entitlements_test.exs`, installer tests — executable test and installation conventions.
- `accrue/lib/accrue/entitlements/{source/registry,decision_cases}.ex` — closed rail/environment vocabulary.

### Secondary (MEDIUM confidence)

- [Ecto Changeset documentation](https://ecto.hexdocs.pm/Ecto.Changeset.html) — DB constraints vs unsafe validations; named constraint handling.
- [PostgreSQL partial-index documentation](https://www.postgresql.org/docs/current/indexes-partial.html) — predicate-scoped indexes.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locked project dependencies and current code inspection.
- Architecture: HIGH — phase decisions align with direct repository precedents and v1.59 architecture.
- Pitfalls: HIGH — locked acceptance constraints plus official database semantics.

**Research date:** 2026-08-02
**Valid until:** 2026-09-01
