# ADR: Accrue-Owned Postgres Schema Contract

**Date:** 2026-07-02
**Status:** Accepted for v1.55
**Decision:** Accrue keeps `billing` as the default Accrue-owned Postgres schema for v1.55 and v1.x, keeps `public` as an explicit host opt-out, does not rename the default to `accrue`, and does not make PostgreSQL `search_path` the primary schema contract.

## Context

Phase 203 locks the existing database schema support contract. It does not change runtime behavior, defaults, migrations, installer behavior, public docs defaults, CI topology, package metadata, or product surface.

The checked-in code already uses a dedicated-schema posture:

- `accrue/lib/accrue/config.ex` defines `:billing_schema` with default `"billing"`, validates PostgreSQL identifier-shaped values, and describes the setting as compile-time configuration for Ecto schemas and migration generation.
- `accrue/lib/accrue/schema.ex` reads `Application.compile_env(:accrue, :billing_schema, "billing")`, validates it through `Accrue.Config`, and applies `@schema_prefix` in `Accrue.Schema`.
- `accrue/lib/accrue/migration.ex` creates the configured schema when needed, wraps `table`, `references`, `index`, and `unique_index` with an Ecto migration `prefix`, and exposes `qualified_table/1` for raw SQL table qualification.
- Installer code in `accrue/lib/accrue/install/options.ex`, `accrue/lib/accrue/install/patches.ex`, `accrue/lib/accrue/install/templates.ex`, and `accrue/lib/mix/tasks/accrue.install.ex` generates host config with a default `billing` schema and supports `--billing-schema public`.
- Installer tests, public guides, and `examples/accrue_host/config/config.exs` mirror the contract by showing default `billing` and explicit `public`.

The Ecto-native shape is explicit prefixing, not implicit lookup. Ecto schemas support a schema prefix through `@schema_prefix`; Ecto migrations support `prefix:` on table/index/reference operations; PostgreSQL resolves unqualified names through `search_path`. Accrue's contract is therefore to name the configured schema at the Ecto and migration helper boundaries.

## Current Contract

Accrue's current contract is intentionally small:

- Accrue MUST keep `billing` as the default Accrue-owned Postgres schema for v1.55 and v1.x.
- Accrue MAY support explicit `public` when a host opts in because it intentionally wants Accrue tables in the default schema.
- Accrue MUST NOT rename the default schema to `accrue` in this milestone.
- Accrue MUST NOT rely on PostgreSQL `search_path` as its primary schema contract.
- Accrue-owned tables use the configured `:billing_schema`; host-owned users, organizations, Oban jobs, and app tables remain under host migration conventions.

Fresh installs keep:

```elixir
config :accrue, :billing_schema, "billing"
```

Hosts that intentionally keep Accrue tables in the default schema use:

```elixir
config :accrue, :billing_schema, "public"
```

Existing or future compatibility lanes can also pin the current default explicitly:

```elixir
config :accrue, :billing_schema, "billing"
```

The `:billing_schema` setting belongs in `config/config.exs`, not `config/runtime.exs`, because `Accrue.Schema` compiles Ecto `@schema_prefix` from application compile-time configuration. Runtime-only changes are not enough to safely change compiled schema prefixes.

## Authoritative Surfaces

The executable contract is authoritative in these surfaces:

| Surface | Role | Evidence |
|---|---|---|
| `Accrue.Config` | Defines the `:billing_schema` default, option docs, and identifier validation. | `accrue/lib/accrue/config.ex` |
| `Accrue.Schema` | Applies the compile-time Ecto `@schema_prefix` used by Accrue-owned schemas. | `accrue/lib/accrue/schema.ex` |
| `Accrue.Migration` | Creates the configured schema and centralizes migration prefix helpers plus raw SQL table qualification. | `accrue/lib/accrue/migration.ex` |
| Installer generation | Parses `--billing-schema`, validates it, and writes generated host config. | `accrue/lib/accrue/install/options.ex`, `accrue/lib/accrue/install/patches.ex`, `accrue/lib/accrue/install/templates.ex`, `accrue/lib/mix/tasks/accrue.install.ex` |

Mirror surfaces are important but not independent sources of truth:

| Mirror | Role | Evidence |
|---|---|---|
| Installer tests | Prove generated default `billing`, explicit `public`, and installer option visibility. | `accrue/test/mix/tasks/accrue_install_test.exs` |
| Public guides | Explain compile-time schema config, default `billing`, explicit `public`, and host-owned data movement. | `accrue/guides/configuration.md`, `accrue/guides/first_hour.md`, `accrue/guides/upgrade.md` |
| Example host config | Pins the checked-in evaluation app to the default dedicated schema. | `examples/accrue_host/config/config.exs` |

Future hardening should keep the authoritative surfaces and mirror surfaces aligned, but Phase 203 only records the contract.

## Why Not Rename Default to `accrue`

The schema name `accrue` has one real advantage: it is brand-obvious in database tooling. That benefit is smaller than the compatibility cost.

Accrue keeps `billing` because it names the Phoenix domain boundary more clearly than the package name does. `billing.accrue_customers` is readable: the schema is the domain, and the table prefix names ownership. `accrue.accrue_customers` repeats the brand without adding a stronger safety property.

Default renames are also upgrade-sensitive. Existing installs compiled or migrated against `billing` could query an empty or wrong schema after a default change unless the host pins placement before recompiling. A rename would require coordinated code, installer, tests, public docs, example-host, and upgrade work. That is out of scope for v1.55, and it does not improve the actual goal: avoiding unintentional `public` pollution.

## Consequences

Positive consequences:

- New installs keep Accrue-owned tables out of `public` by default.
- Explicit `public` remains available for hosts that choose the default Postgres schema intentionally.
- The database namespace stays domain-oriented and Phoenix-native.
- The current default avoids a default-rename upgrade risk for existing installs.
- The contract is proof-checkable against `Accrue.Config`, `Accrue.Schema`, `Accrue.Migration`, installer output, tests, and guides.

Tradeoffs:

- Users looking for a brand-named schema need docs that explain why `billing` is the default.
- Prefix consistency remains a hardening target because Ecto schemas use compile-time prefix config while migration/raw SQL helpers read the configured schema at migration or helper execution time.
- Tests and docs can drift from executable surfaces unless a future implementation milestone adds explicit agreement checks.

## Future Hardening Work

Add a future implementation milestone for:

1. Centralizing the default `billing` schema constant so `Accrue.Config`, `Accrue.Schema`, installer defaults, docs tests, and example host cannot drift silently.
2. Adding representative schema-prefix assertions for default `billing`.
3. Adding explicit compatibility lanes for default `billing`, explicit `public`, and explicit `billing`.
4. Adding a static guard for unqualified raw SQL references to Accrue-owned `accrue_*` tables outside approved migration helpers.
5. Keeping installer `--billing-schema public` covered.
6. Keeping configuration, First Hour, Upgrade, and example-host mirrors aligned.
7. Preserving the host-owned data migration boundary for any future relocation work.

## Non-Goals

- Do not rename tables.
- Do not move existing data automatically.
- Do not change the default schema from `billing` to `accrue`.
- Do not use Postgres `search_path` as the primary Accrue contract.
- Do not put host-owned users, organizations, Oban jobs, or app tables under Accrue's schema.
- Do not implement schema-prefix hardening in Phase 203.

## Verification

Current evidence to preserve:

- `accrue/lib/accrue/config.ex`
- `accrue/lib/accrue/schema.ex`
- `accrue/lib/accrue/migration.ex`
- `accrue/lib/accrue/install/options.ex`
- `accrue/lib/accrue/install/patches.ex`
- `accrue/lib/accrue/install/templates.ex`
- `accrue/lib/mix/tasks/accrue.install.ex`
- `accrue/test/mix/tasks/accrue_install_test.exs`
- `accrue/guides/configuration.md`
- `accrue/guides/first_hour.md`
- `accrue/guides/upgrade.md`
- `examples/accrue_host/config/config.exs`

Future implementation should prove that schema prefix, migration prefix, docs, installer output, and example host all agree.
