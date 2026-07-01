# ADR: Accrue-Owned Postgres Schema Contract

**Date:** 2026-07-01  
**Status:** Accepted for v1.55  
**Decision:** Keep `billing` as the default Accrue-owned Postgres schema. Keep `public` as an explicit opt-out. Do not rename the default to `accrue` in this milestone.

## Context

The maintainer asked whether Accrue should keep its tables out of `public` by default, potentially using a dedicated `<domain>` schema such as `accrue`.

Repo evidence shows the dedicated-schema posture already exists:

- `Accrue.Schema` reads `config :accrue, :billing_schema` at compile time and sets `@schema_prefix`.
- `Accrue.Config` defaults `:billing_schema` to `"billing"` and validates PostgreSQL identifiers.
- `Accrue.Migration` creates the configured schema when needed and wraps `table`, `references`, `index`, `unique_index`, and raw SQL table qualification.
- Core migrations use `Accrue.Migration.*`.
- `mix accrue.install` defaults generated host config to `config :accrue, :billing_schema, "billing"`.
- Docs already explain default `billing` and explicit `public`.

External Ecto docs align with this shape: schemas support `@schema_prefix`; migrations support `prefix:` on tables/indexes/references; non-public prefixes need explicit schema creation.

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

Also allow explicit old/current defaults:

```elixir
config :accrue, :billing_schema, "billing"
```

for existing installs and any future compatibility test lanes.

## Why Not Rename Default to `accrue`

Pros of `accrue`:

- Brand-obvious schema name.
- Makes ownership clear in database tooling.
- Matches the package name.

Cons:

- `accrue.accrue_customers` is redundant and less readable than `billing.accrue_customers`.
- Existing installs compiled/migrated against `billing` could query the wrong schema after a default change unless pinned.
- A default rename is upgrade-sensitive and would require broad docs, tests, installer, example-host, and compatibility work.
- The real goal was avoiding `public` pollution, and `billing` already does that.

## Consequences

Positive:

- Accrue remains a respectful guest in host apps by default.
- The database namespace is domain-oriented instead of brand-redundant.
- Existing installs avoid surprise data lookup failures.
- `public` remains available for hosts that explicitly choose it.

Tradeoffs:

- Users looking for an `accrue` schema may need docs to explain why `billing` is the default.
- Prefix consistency must be guarded because Ecto schemas compile prefixes while migration helpers read runtime config.

## Future Hardening Work

Add an implementation milestone for:

1. Centralize the default billing schema constant so `Config`, `Schema`, installer options/templates, docs tests, and example host cannot drift.
2. Add tests that representative Accrue schemas expose `__schema__(:prefix) == "billing"` under default config.
3. Add explicit test lanes for default `billing`, explicit `public`, and explicit `billing` compatibility.
4. Add a static guard for unqualified raw SQL references to `accrue_*` tables outside approved migration helpers.
5. Ensure installer `--billing-schema public` remains tested.
6. Add upgrade docs warning existing `public` or `billing` installs to pin `:billing_schema` before recompiling if defaults ever change.
7. Clarify that moving existing production data between schemas is host-owned data migration work.

## Non-Goals

- Do not rename tables.
- Do not move existing data automatically.
- Do not change the default schema from `billing` to `accrue`.
- Do not use Postgres `search_path` as the primary Accrue contract.
- Do not put host-owned users, organizations, Oban jobs, or app tables under Accrue's schema.

## Verification

Current evidence to preserve:

- `accrue/lib/accrue/schema.ex`
- `accrue/lib/accrue/migration.ex`
- `accrue/lib/accrue/config.ex`
- `accrue/lib/accrue/install/options.ex`
- `accrue/test/mix/tasks/accrue_install_test.exs`
- `accrue/guides/configuration.md`
- `accrue/guides/first_hour.md`
- `accrue/guides/upgrade.md`
- `examples/accrue_host/config/config.exs`

Future implementation should prove that schema prefix, migration prefix, docs, installer output, and example host all agree.
