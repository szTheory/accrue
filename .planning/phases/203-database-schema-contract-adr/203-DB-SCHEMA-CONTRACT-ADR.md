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

## Compatibility and Upgrade Warning

Existing installs should pin their intended placement before recompiling Accrue.

For current public-schema installs:

```elixir
config :accrue, :billing_schema, "public"
```

For existing billing-schema installs, or hosts that want to make the default explicit:

```elixir
config :accrue, :billing_schema, "billing"
```

Fresh installs keep `billing`.

Moving production data between `public`, `billing`, or any future schema is host-owned data migration work. Accrue does not automate that movement, hide it behind a default change, or publish a casual relocation recipe in Phase 203. A future relocation guide should only exist if a later implementation milestone intentionally supports schema relocation with backup, foreign-key, trigger, and verification guidance.

Explicit `public` remains supported when a host intentionally wants Accrue tables in the default schema. It is an opt-out from the dedicated-schema default, not a deprecated or inferior path.

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

## Phase 204 Handoff

Phase 204 should rank these rows against the Phase 201 software-quality audit and the Phase 202 CI/CD audit. These are local DB-schema-contract inputs only, not final cross-audit ordering and not issue-ready implementation cards. Phase 203 does not implement the checks below.

| Area | Evidence path | Current risk | Expected impact | Tradeoff | Implementation approach | Verification | Rollback | Metric/evidence-needed status | Non-goals |
|---|---|---|---|---|---|---|---|---|---|
| Centralize default `billing` schema constant | `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/schema.ex`, `accrue/lib/accrue/install/options.ex`, `examples/accrue_host/config/config.exs` | The default appears as repeated `"billing"` literals across executable and mirror surfaces. Drift could make generated config, compiled schemas, and examples disagree. | One named default reduces support-contract drift and makes future changes deliberate. | Adds a shared constant surface that must avoid compile-time dependency cycles. | Centralize the default in the lowest safe module or generated constant pattern, then route config/schema/installer/example checks through it. | Focused tests prove default generated config, `Accrue.Config`, and representative `Accrue.Schema` prefix all agree. | Revert to literals if the constant introduces compile-order friction. | Evidence exists; Phase 204 needs final ranking and implementation design. | No default rename and no runtime behavior change. |
| Add schema-prefix prefix-agreement assertions | `accrue/lib/accrue/schema.ex`, `accrue/lib/accrue/migration.ex`, representative migrations | Ecto schemas compile `@schema_prefix`, while migration helpers read configured prefixes during migration/helper execution. Missing prefix-agreement checks could hide drift. | Catches a mismatch before a release or support incident. | Tests may need compile-time config isolation to avoid global app-env coupling. | Add representative assertions for `__schema__(:prefix) == "billing"` and migration helper prefix behavior under default config. | ExUnit proves representative Accrue schemas and migration helpers agree on default `billing`. | Remove or narrow assertions if compile-time isolation makes the check flaky. | Needs implementation spike only if Phase 204 ranks it. | No full matrix over every schema in Phase 203. |
| Add explicit `billing` / `public` compatibility lanes | `accrue/test/mix/tasks/accrue_install_test.exs`, `accrue/guides/upgrade.md`, `examples/accrue_host/config/config.exs` | Current tests prove installer default `billing` and explicit `public`, but not a complete old-default compatibility story. | Keeps existing billing-schema installs and explicit public installs safe across future refactors. | More test lanes increase CI time unless scoped carefully. | Add focused checks for default `billing`, explicit `public`, and explicit `billing` compatibility rather than broad database suites. | Targeted ExUnit or installer fixture tests pass for all three placement modes. | Drop the added lane or move it to nightly if runtime proves too high. | Static repo evidence exists; Phase 204 should rank against CI cost. | No production data migration and no new schema default. |
| Add raw SQL qualification guard | `accrue/lib/accrue/migration.ex`, `accrue/lib/accrue/analytics/dunning.ex`, `scripts/ci/accrue_host_seed_e2e.exs` | Unqualified raw SQL references to Accrue-owned `accrue_*` tables could bypass configured schema placement through `search_path`. | Prevents accidental schema-unsafe SQL from entering Accrue-owned code. | A static check needs an allowlist for generated migrations, docs snippets, and approved helper definitions. | Add a grep/Credo-style guard that flags raw SQL `accrue_*` table names outside `Accrue.Migration.qualified_table/1` and approved helper code. | A negative fixture fails when an unqualified table is introduced; existing qualified callsites pass. | Remove the guard or narrow its allowlist if it blocks legitimate helper code. | Needs candidate command and false-positive sample before final rollout. | No SQL rewrite in Phase 203 and no `search_path` contract. |
| Keep installer `--billing-schema public` coverage | `accrue/lib/accrue/install/options.ex`, `accrue/lib/accrue/install/patches.ex`, `accrue/test/mix/tasks/accrue_install_test.exs` | Public-schema opt-out support can regress if installer parsing or snippets drift. | Preserves explicit `public` as a supported host choice, not a deprecated path. | Installer tests already exist, so extra checks should avoid duplicating them. | Keep or extend the focused installer test that writes `config :accrue, :billing_schema, "public"`. | Installer test proves `--billing-schema public` remains accepted and generated into `config/config.exs`. | Revert to current coverage if added assertions become redundant. | Current evidence exists; Phase 204 should decide whether coverage is already sufficient. | No public deprecation and no docs-only claim without test support. |
| Align configuration, First Hour, Upgrade, and example-host mirrors | `accrue/guides/configuration.md`, `accrue/guides/first_hour.md`, `accrue/guides/upgrade.md`, `examples/accrue_host/config/config.exs` | Docs and example-host mirrors can drift from executable behavior, especially around compile-time config and explicit `public`. | Keeps adopter-facing setup and upgrade language consistent with the executable contract. | Docs-contract checks add maintenance surface and can become brittle if wording is over-specified. | Add narrow documentation assertions for default `billing`, `config/config.exs`, not `config/runtime.exs`, explicit `public`, First Hour install guidance, Upgrade pinning, and example-host `billing`. | Docs or package-docs gate proves each mirror still carries the required concepts. | Relax assertions to concept-level checks if exact wording creates churn. | Needs final check shape and integration point in Phase 204. | No public docs mirror edits in Phase 203. |
| Preserve host-owned data migration boundary | `accrue/guides/upgrade.md`, `.planning/phases/203-database-schema-contract-adr/203-CONTEXT.md` | A future schema relocation guide could look like Accrue automates production table movement, causing unsafe upgrade expectations. | Keeps schema relocation explicit, deliberate, and host-owned. | Stronger warnings can be misread as discouraging supported `public`; wording must keep `public` supported. | Keep future relocation work behind an implementation milestone and require backup/FK/trigger verification language if a guide is ever written. | ADR and Upgrade docs continue to say moving data between `public`, `billing`, or any future schema is host-owned data migration. | Revert any relocation recipe that ships without explicit milestone support. | Phase 204 should decide whether a relocation guide is worth doing at all. | No automated data movement, no casual public-to-billing recipe, and no default rename. |

## Non-Goals

- Do not rename tables.
- Do not move existing data automatically.
- Do not change the default schema from `billing` to `accrue`.
- Do not use Postgres `search_path` as the primary Accrue contract.
- Do not put host-owned users, organizations, Oban jobs, or app tables under Accrue's schema.
- Do not implement schema-prefix hardening in Phase 203.
- Do not change current defaults, database schemas, migrations, installer behavior, source code, runtime behavior, public docs defaults, CI topology, package metadata, or product surface.
- Do not publish a public-to-billing schema relocation recipe in this ADR.

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

Phase 203 verification is markdown/content verification because schema-relevant files are evidence only. If any implementation, public docs mirror, CI, package metadata, example-host, or script file changes while executing this phase, that violates the boundary and requires stopping or rerouting to an implementation milestone.

## Requirement Coverage

| Requirement | Coverage |
|---|---|
| DB-01 | Current Contract and Authoritative Surfaces explain default `billing`, explicit `public`, compile-time `Accrue.Schema`, `Accrue.Migration` prefix helpers, and host-owned data migration responsibility. |
| DB-02 | Why Not Rename Default to `accrue` explains the tradeoff, the `accrue.accrue_` readability issue, and the upgrade risk of switching away from `billing`. |
| DB-03 | Phase 204 Handoff lists concrete future hardening checks for prefix-agreement, schema-prefix assertions, raw SQL qualification, installer coverage, docs/test alignment, and old-default compatibility. |
| DB-04 | Non-Goals plus Phase Handoff and Boundary identify future implementation milestone work and work not worth doing now. |

## Phase Handoff and Boundary

Phase 203 updates only `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`. It does not change current defaults, database schemas, migrations, installer behavior, source code, runtime behavior, public docs defaults, CI topology, package metadata, or product surface.

The Phase 204 Handoff is advisory follow-up implementation work for Phase 204 to rank. Phase 203 local DB-schema-contract priorities are not final cross-audit ordering.

Because schema-relevant files are evidence only, no schema push task is required. This ADR cites code, migrations, installer behavior, docs, tests, and example-host config as evidence; it does not ask the executor to alter schema state.
