# Phase 203: Database Schema Contract ADR - Pattern Map

**Mapped:** 2026-07-02
**Files analyzed:** 1 phase implementation artifact
**Analogs found:** 1 / 1

Phase 203 is documentation/planning only. The only implementation artifact identified from `203-CONTEXT.md` and `203-RESEARCH.md` is `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`. Runtime code, installer code, public guides, tests, CI, package metadata, and example host files are evidence surfaces only and should not be edited in this phase.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | documentation/ADR | transform | `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | exact existing artifact |

## Pattern Assignments

### `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` (documentation/ADR, transform)

**Primary analog:** `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`
**Supporting analogs:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md`, `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md`

**Header/status/decision pattern** (`203-DB-SCHEMA-CONTRACT-ADR.md:1-5`):

```markdown
# ADR: Accrue-Owned Postgres Schema Contract

**Date:** 2026-07-01
**Status:** Accepted for v1.55
**Decision:** Keep `billing` as the default Accrue-owned Postgres schema. Keep `public` as an explicit opt-out. Do not rename the default to `accrue` in this milestone.
```

Copy this direct ADR header shape, but update content so the decision uses the locked hybrid contract from `203-CONTEXT.md`: current contract is normative, future hardening is advisory.

**Evidence-led context pattern** (`203-DB-SCHEMA-CONTRACT-ADR.md:11-20`):

```markdown
Repo evidence shows the dedicated-schema posture already exists:

- `Accrue.Schema` reads `config :accrue, :billing_schema` at compile time and sets `@schema_prefix`.
- `Accrue.Config` defaults `:billing_schema` to `"billing"` and validates PostgreSQL identifiers.
- `Accrue.Migration` creates the configured schema when needed and wraps `table`, `references`, `index`, `unique_index`, and raw SQL table qualification.
- Core migrations use `Accrue.Migration.*`.
- `mix accrue.install` defaults generated host config to `config :accrue, :billing_schema, "billing"`.
- Docs already explain default `billing` and explicit `public`.

External Ecto docs align with this shape: schemas support `@schema_prefix`; migrations support `prefix:` on tables/indexes/references; non-public prefixes need explicit schema creation.
```

Preserve the repo-evidence-first structure. Expand it to distinguish authoritative executable surfaces from mirror surfaces:

- Authoritative: `Accrue.Config`, `Accrue.Schema`, `Accrue.Migration`, installer generation.
- Mirrors: guides, example host config, installer tests.

**Current decision pattern** (`203-DB-SCHEMA-CONTRACT-ADR.md:22-46`):

````markdown
## Decision

Keep:

```elixir
config :accrue, :billing_schema, "billing"
```

as the default for fresh installs.

Allow:

```elixir
config :accrue, :billing_schema, "public"
```

only when a host intentionally wants Accrue tables in the default schema.
````

Keep concrete config examples. Add BCP-14-style words sparingly: `MUST` for default `billing`, explicit `public`, no default rename, and no `search_path` primary contract; `SHOULD` or plain advisory language for future Phase 204 candidates.

**Rejected alternative / tradeoff pattern** (`203-DB-SCHEMA-CONTRACT-ADR.md:48-76`):

```markdown
## Why Not Rename Default to `accrue`

Cons:

- `accrue.accrue_customers` is redundant and less readable than `billing.accrue_customers`.
- Existing installs compiled/migrated against `billing` could query the wrong schema after a default change unless pinned.
- A default rename is upgrade-sensitive and would require broad docs, tests, installer, example-host, and compatibility work.
- The real goal was avoiding `public` pollution, and `billing` already does that.
```

Use this as the "why not `accrue`" section shape. Avoid turning it into a migration guide.

**Future work and non-goals pattern** (`203-DB-SCHEMA-CONTRACT-ADR.md:77-95`):

```markdown
## Future Hardening Work

Add an implementation milestone for:

1. Centralize the default billing schema constant so `Config`, `Schema`, installer options/templates, docs tests, and example host cannot drift.
2. Add tests that representative Accrue schemas expose `__schema__(:prefix) == "billing"` under default config.
3. Add explicit test lanes for default `billing`, explicit `public`, and explicit `billing` compatibility.
4. Add a static guard for unqualified raw SQL references to `accrue_*` tables outside approved migration helpers.

## Non-Goals

- Do not rename tables.
- Do not move existing data automatically.
- Do not change the default schema from `billing` to `accrue`.
- Do not use Postgres `search_path` as the primary Accrue contract.
- Do not put host-owned users, organizations, Oban jobs, or app tables under Accrue's schema.
```

Replace the plain numbered future-work list with a structured Phase 204 handoff table, but keep the same non-goal discipline.

**Structured Phase 204 handoff pattern** (`202-CI-CD-PERFORMANCE-AUDIT.md:296-312`):

```markdown
## Phase 204 Handoff

These rows are local CI/CD priorities for Phase 202. They are rankable inputs for Phase 204, not final cross-audit ordering and not issue-ready implementation cards.

| Area | Evidence path | Current risk | Priority local to Phase 202 | Expected impact | Tradeoff | Implementation approach | Verification | Rollback | Metric-needed status | Suggested milestone-slice fit |
|---|---|---|---|---|---|---|---|---|---|---|
| CI baseline summaries | `.github/workflows/ci.yml`, `Baseline Metrics Needed`, partial run `28538686414` | Maintainer cannot see timings, cache-hit state, slowest tests, or provider proved-vs-skipped state in one run summary | P0 | Turns optimization from static inference into measured evidence | Adds small summary maintenance surface | Add `$GITHUB_STEP_SUMMARY` blocks for versions, cache-hit state, key step timings, slowest tests where cheap, and provider status | Two comparable CI runs show summary fields; no gate removed | Remove summary steps | Required before topology cleanup | Small measurement-first hardening slice |
```

For Phase 203, copy this table-section pattern but use the locked Phase 203 columns from `203-CONTEXT.md`: `Area`, `Evidence path`, `Current risk`, `Expected impact`, `Tradeoff`, `Implementation approach`, `Verification`, `Rollback`, `Metric/evidence-needed status`, and `Non-goals`. Do not pre-rank globally; label priorities as local DB-schema-contract inputs only if needed.

**Audit-only boundary pattern** (`202-CI-CD-PERFORMANCE-AUDIT.md:323-333`):

```markdown
## Phase Handoff and Boundary

Phase 202 is an **audit-only** gate. It produced the specialist CI/CD evidence that Phase 204 will rank alongside Phase 201 software-quality findings and Phase 203 database schema-contract findings. Phase 202 priorities are local CI/CD priorities; Phase 204 owns final cross-audit ordering and implementation slicing.

The Phase 202 gate did **not** change CI workflow topology, branch protection, package release automation, runtime behavior, public APIs, DB defaults, UI implementation, required-check semantics, source trees, workflow files, release workflows, script behavior, public docs, or package metadata. Static recommendations in this file are not implementation changes.
```

Copy this explicit no-code-change posture and adapt it for Phase 203: no runtime behavior, migration, installer default, docs default, CI topology, package metadata, or product surface change.

**Schema risk framing pattern** (`201-SOFTWARE-QUALITY-AUDIT.md:128-142`):

```markdown
### 5. DB Schema Contract Hardening

**What I observed:** The dedicated-schema posture already exists and defaults to `billing`. That is good. The risk is contract drift across compile-time Ecto schema prefix, runtime migration helper prefix, docs, installer, and existing installs.

**Why it matters:** A billing library that loses track of which schema owns its tables can create scary data-migration failures.

**Fix first:** Keep `billing`. Add guards that schema prefix, migration helper prefix, installer docs, explicit `public`, and old `billing` compatibility stay aligned.

**Do not over-fix:** Do not rename default schema to `accrue`; `billing.accrue_customers` is cleaner than `accrue.accrue_customers` and avoids upgrade risk.
```

Use this wording as the risk spine, but rewrite into ADR voice rather than audit voice.

## Shared Patterns

### Voice And Claim Posture

**Source:** `brandbook/voice.md:11-17`, `brandbook/voice.md:23-33`, `brandbook/voice.md:123-128`
**Apply to:** Entire ADR.

```markdown
**Measured.** Accrue doesn't oversell. Every claim is sized to what the library actually does — no superlatives, no adjective-led marketing copy. A measured sentence names a mechanism.

**Exact.** Accrue names things precisely: context functions, append-only ledgers, merge-blocking CI, Fake-backed proof paths.

**Native.** Accrue speaks in Phoenix-developer idioms — Ecto schemas, OTP supervision, mix tasks, plugs, contexts.
```

Planner instruction: use measured, mechanism-led, Phoenix/Ecto-native wording. Avoid claiming future guards already exist.

### Config Default And Validation

**Source:** `accrue/lib/accrue/config.ex:41-45`, `accrue/lib/accrue/config.ex:596-615`, `accrue/lib/accrue/config.ex:1484-1516`
**Apply to:** ADR authoritative-surface section, current contract section, validation/future hardening rows.

```elixir
billing_schema: [
  type: {:custom, __MODULE__, :validate_billing_schema, []},
  default: "billing",
  doc:
    "PostgreSQL schema where Accrue-owned billing tables are stored. Defaults to `billing`; set to `public` explicitly to keep Accrue tables in the default schema. This is compile-time configuration for Ecto schemas and migration generation."
]
```

```elixir
@doc """
Compile-time billing schema prefix used by Accrue Ecto schemas.
"""
@spec compile_time_billing_schema() :: String.t()
def compile_time_billing_schema do
  :accrue
  |> Application.get_env(:billing_schema, "billing")
  |> validate_billing_schema!()
end

@doc """
Runtime billing schema prefix used by migration and raw SQL helpers.
"""
@spec billing_schema() :: String.t()
def billing_schema do
  :accrue
  |> Application.get_env(:billing_schema, "billing")
  |> validate_billing_schema!()
end
```

```elixir
def validate_billing_schema!(schema) when is_binary(schema) do
  if Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_]*$/, schema) do
    schema
  else
    raise Accrue.ConfigError,
      key: :billing_schema,
      message:
        "invalid accrue config key: :billing_schema " <>
          "(expected a PostgreSQL identifier such as \"billing\" or \"public\")"
  end
end
```

### Compile-Time Ecto Schema Prefix

**Source:** `accrue/lib/accrue/schema.ex:1-21`
**Apply to:** ADR current contract and compile-time warning.

```elixir
@billing_schema Application.compile_env(:accrue, :billing_schema, "billing")

defmacro __using__(_opts) do
  billing_schema = Accrue.Config.validate_billing_schema!(@billing_schema)

  quote bind_quoted: [billing_schema: billing_schema] do
    use Ecto.Schema

    @schema_prefix billing_schema
  end
end
```

Planner instruction: explicitly say `:billing_schema` belongs in `config/config.exs`, not `config/runtime.exs`, because Ecto schemas compile the prefix.

### Migration Prefix And Raw SQL Qualification

**Source:** `accrue/lib/accrue/migration.ex:1-54`
**Apply to:** ADR authoritative-surface section, `search_path` non-goal, future raw-SQL guard row.

```elixir
def billing_prefix, do: Accrue.Config.billing_schema()

def create_billing_schema do
  prefix = billing_prefix()

  if prefix != "public" do
    Ecto.Migration.execute("CREATE SCHEMA IF NOT EXISTS #{quote_identifier(prefix)}")
  end
end

def table(name, opts \\ []) do
  Ecto.Migration.table(name, Keyword.put_new(opts, :prefix, billing_prefix()))
end

def references(name, opts \\ []) do
  Ecto.Migration.references(name, Keyword.put_new(opts, :prefix, billing_prefix()))
end

def index(table, columns, opts \\ []) do
  Ecto.Migration.index(table, columns, Keyword.put_new(opts, :prefix, billing_prefix()))
end

def unique_index(table, columns, opts \\ []) do
  Ecto.Migration.unique_index(table, columns, Keyword.put_new(opts, :prefix, billing_prefix()))
end

def qualified_table(name), do: qualified_name(billing_prefix(), name)
```

**Representative migration callsite** (`accrue/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs:11-47`):

```elixir
def change do
  # --- Payment Methods ---

  create Accrue.Migration.table(:accrue_payment_methods, primary_key: false) do
    add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

    add(
      :customer_id,
      Accrue.Migration.references(:accrue_customers, type: :binary_id, on_delete: :delete_all),
      null: false
    )
  end

  create(Accrue.Migration.index(:accrue_payment_methods, [:customer_id]))
  create(Accrue.Migration.index(:accrue_payment_methods, [:processor_id]))

  create(
    Accrue.Migration.unique_index(:accrue_payment_methods, [:processor, :processor_id],
      where: "processor_id IS NOT NULL",
      name: :accrue_payment_methods_processor_processor_id_index
    )
  )
end
```

**Representative raw SQL-like callsites** (`accrue/lib/accrue/analytics/dunning.ex:23-25`, `scripts/ci/accrue_host_seed_e2e.exs:45-46`, `scripts/ci/accrue_host_seed_e2e.exs:181-192`):

```elixir
@events_table Accrue.Migration.qualified_table(:accrue_events)
@invoices_table Accrue.Migration.qualified_table(:accrue_invoices)
@terminal_exists_sql "NOT EXISTS (SELECT 1 FROM #{@events_table} WHERE type IN ('dunning.recovered','dunning.exhausted') AND subject_id = ?::text AND inserted_at >= ?)"
```

```elixir
@events_table Accrue.Migration.qualified_table(:accrue_events)
@discount_mappings_table Accrue.Migration.qualified_table(:accrue_discount_mappings)
```

```elixir
Repo.query!("ALTER TABLE #{@events_table} DISABLE TRIGGER accrue_events_immutable_trigger")

try do
  Repo.delete_all(
    from(event in Event,
      where:
        event.subject_type == "Subscription" and
          event.subject_id in ^fake_browser_subscription_ids
    )
  )
after
  Repo.query!("ALTER TABLE #{@events_table} ENABLE TRIGGER accrue_events_immutable_trigger")
end
```

Planner instruction: future raw-SQL hardening row should target unqualified `accrue_*` table names outside approved helper usage.

### Installer Default And Explicit Public Opt-Out

**Source:** `accrue/lib/accrue/install/options.ex:27-44`, `accrue/lib/accrue/install/options.ex:76-101`, `accrue/lib/accrue/install/patches.ex:131-135`, `accrue/lib/mix/tasks/accrue.install.ex:3-10`
**Apply to:** ADR binding surfaces, compatibility story, future installer-test rows.

```elixir
defstruct billable: nil,
          billing_schema: "billing",
          billing_context: "MyApp.Billing",
          webhook_path: "/webhooks/stripe",
          admin_mount: "/billing",
          admin: :auto,
          sigra: :auto,
          check: false,
          dry_run: false,
          manual: false,
          force: false,
          write_conflicts: false,
          accept?: false

@switches [
  billable: :string,
  billing_schema: :string,
```

```elixir
%__MODULE__{
  billable: opts[:billable],
  billing_schema: validate_billing_schema!(Keyword.get(opts, :billing_schema, "billing")),
  billing_context: Keyword.get(opts, :billing_context, "MyApp.Billing"),
```

```elixir
def billing_schema_snippet(opts) do
  """
  # Compile-time: Accrue Ecto schemas and generated migrations use this prefix.
  # Use "public" only when you intentionally want Accrue tables in the default schema.
  config :accrue, :billing_schema, "#{opts.billing_schema}"
  """
end
```

```elixir
@moduledoc """
Generates host-owned Accrue wiring.

## Flags

  * `--billable MyApp.Accounts.User`
  * `--billing-schema billing`
```

### Installer Tests As Mirror Evidence

**Source:** `accrue/test/mix/tasks/accrue_install_test.exs:24-30`, `accrue/test/mix/tasks/accrue_install_test.exs:67-70`, `accrue/test/mix/tasks/accrue_install_test.exs:177-195`
**Apply to:** ADR verification section and future hardening table.

```elixir
assert output =~ "--billing-schema"
```

```elixir
assert InstallFixture.assert_contains!(
         app,
         "config/config.exs",
         "config :accrue, :billing_schema, \"billing\""
       )
```

```elixir
test "supports explicit public billing schema opt-out" do
  app = InstallFixture.tmp_app!(:public_billing_schema)

  run_install(app, ["--yes", "--billing-schema", "public"])

  assert InstallFixture.assert_contains!(
           app,
           "config/config.exs",
           "config :accrue, :billing_schema, \"public\""
         )
end
```

Planner instruction: call these tests current evidence, not complete future compatibility lanes.

### Public Docs And Example Host Mirrors

**Source:** `accrue/guides/configuration.md:17-34`, `accrue/guides/upgrade.md:53-65`, `examples/accrue_host/config/config.exs:13-15`
**Apply to:** ADR mirror-surface section and compatibility story.

````markdown
## Billing schema

By default, `mix accrue.install` configures Accrue-owned billing tables under a
Postgres schema named `billing` instead of placing them in `public`.

Keep this setting in `config/config.exs`, not `config/runtime.exs`: Ecto schema
prefixes are compile-time configuration.

```elixir
config :accrue, :billing_schema, "billing"
```

Set `"public"` explicitly only when you intentionally want Accrue tables in the
default schema:
````

````markdown
If you are upgrading an app that already has Accrue tables in `public`, decide
the billing schema before recompiling the dependency:

```elixir
config :accrue, :billing_schema, "public"
```

Keep that explicit `public` setting when you want existing table placement to
stay unchanged. New installer runs default to `billing`, and Accrue migrations
schema-qualify Accrue-owned tables there. Moving an existing production install
from `public` to `billing` is host-owned data migration work: schedule it like
any other table move, verify foreign keys/triggers/backups, then recompile with
`config :accrue, :billing_schema, "billing"`.
````

```elixir
config :accrue,
  repo: AccrueHost.Repo,
  billing_schema: "billing",
```

Planner instruction: use these as mirror evidence. Do not edit guides or example host config in Phase 203.

### Validation Pattern

**Source:** `203-RESEARCH.md:445-455`, `203-RESEARCH.md:459-461`
**Apply to:** planner verification loop for the ADR.

```markdown
| DB-01 | ADR explains `billing`, explicit `public`, compile-time schema prefix, migration helpers, and host-owned data migration. | markdown/content smoke | `rg -n "billing|public|compile-time|Accrue\\.Schema|Accrue\\.Migration|host-owned" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes, current draft exists. |
| DB-02 | ADR explains why default does not switch to `accrue`. | markdown/content smoke | `rg -n "accrue\\.accrue_|Why Not|out of scope|upgrade risk|rename" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes, current draft exists. |
| DB-03 | ADR lists concrete future hardening checks. | markdown/content smoke | `rg -n "Phase 204|prefix-agreement|raw SQL|installer|docs|test|compatibility|qualified" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes, current draft exists. |
| DB-04 | ADR separates future implementation work from work not worth doing now. | markdown/content smoke | `rg -n "Future Hardening|Non-Goals|not part|out of scope|implementation milestone" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes, current draft exists. |
```

Use markdown smoke checks only unless a later plan changes code or public docs.

## No Analog Found

No files lacked an analog. The phase has one modified implementation artifact, and it already exists as a seeded ADR. The closest supporting structural analog is Phase 202's audit handoff table.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| n/a | n/a | n/a | All phase-scope files have a close analog. |

## Metadata

**Analog search scope:** `.planning/phases`, `accrue/lib/accrue`, `accrue/priv/repo/migrations`, `accrue/test/mix/tasks`, `accrue/guides`, `examples/accrue_host/config`, `scripts/ci`, `brandbook`.

**Files scanned:** 22 focused files plus repo-local instruction/skill checks.

**Selected analogs:**

- `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` - exact current artifact to refine.
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` - closest structured Phase 204 handoff pattern.
- `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` - schema-prefix risk framing.

**Pattern extraction date:** 2026-07-02

**Implementation boundary:** `203-PATTERNS.md` is the only file written during pattern mapping. Planner should edit only `203-DB-SCHEMA-CONTRACT-ADR.md` during Phase 203 unless the phase scope changes explicitly.
