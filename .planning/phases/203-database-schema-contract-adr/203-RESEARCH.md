# Phase 203: Database Schema Contract ADR - Research

**Researched:** 2026-07-02  
**Domain:** Elixir/Ecto/PostgreSQL schema-prefix contract ADR  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Every item in this section is copied from `.planning/phases/203-database-schema-contract-adr/203-CONTEXT.md`; that file is the source for this whole constraints block. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

### Locked Decisions

### Research And Recommendation Method
- **D-01:** Discuss all four gray areas as one coherent decision set: ADR contract strength, binding surfaces, compatibility story, and Phase 204 handoff shape.
- **D-02:** Use parallel subagent research plus local repo evidence and official primary sources to make one-shot recommendations. The user explicitly prefers not to review every tradeoff manually; downstream agents should treat the captured recommendations as locked unless new repo evidence contradicts them.
- **D-03:** Apply the prompt corpus and brandbook lens: repo-local truth first, adopter/DX value over perfectionism, Phoenix/Ecto-native vocabulary, measured and proof-checkable wording, and no hype. `brandbook/voice.md` supersedes older wording in `prompts/accrue-brand-book.md` if they differ.
- **D-04:** UI/UX and graphic design are not direct Phase 203 implementation scope. Apply those lenses to developer experience, docs/API clarity, naming, upgrade microcopy, and least-surprise support boundaries. Do not expose backend internals unless the Ecto/Postgres contract requires it for safe use.

### ADR Contract Strength
- **D-05:** Use a **hybrid accepted ADR**: normative current contract plus advisory future hardening. The ADR should be firm enough to serve as support-contract evidence, but it must not imply unimplemented guards already exist.
- **D-06:** Normative current contract: Accrue **MUST** keep `billing` as the default Accrue-owned Postgres schema for v1.55 / v1.x; Accrue **MAY** support explicit `public` only when the host opts in; Accrue **MUST NOT** rename the default to `accrue` in this milestone; Accrue **MUST NOT** rely on Postgres `search_path` as its primary contract.
- **D-07:** Advisory future hardening: the ADR should say Accrue **SHOULD** add prefix-agreement checks, raw-SQL qualification checks, installer/docs/test coverage, explicit `billing`/`public` compatibility lanes, and old-default compatibility checks in a future implementation milestone if Phase 204 ranks them high enough.
- **D-08:** Use BCP-14-style language sparingly and readably. The voice should sound like a maintainer locking a support boundary, not a legal spec. The strongest words belong to current behavior and non-goals; future checks stay clearly labeled as follow-up work.

### Binding Surfaces
- **D-09:** Use a **layered authoritative-surfaces** model. The executable contract is authoritative in `Accrue.Config`, `Accrue.Schema`, `Accrue.Migration`, and installer generation. Docs, example host config, and tests mirror that contract and should be called out as drift-prone mirrors, not as independent sources of truth.
- **D-10:** The ADR should name the binding surfaces explicitly:
  - `accrue/lib/accrue/config.ex` - default `:billing_schema`, validation, and option docs.
  - `accrue/lib/accrue/schema.ex` - compile-time `@schema_prefix` via `Application.compile_env/3`.
  - `accrue/lib/accrue/migration.ex` - schema creation, migration table/reference/index prefix helpers, and raw SQL table qualification helpers.
  - `accrue/lib/accrue/install/options.ex`, `accrue/lib/accrue/install/patches.ex`, `accrue/lib/accrue/install/templates.ex`, and `accrue/lib/mix/tasks/accrue.install.ex` - installer option parsing, default generation, CLI docs, and generated host config.
  - `accrue/test/mix/tasks/accrue_install_test.exs` and related installer tests - current evidence for default `billing` and explicit `public`.
  - `accrue/guides/configuration.md`, `accrue/guides/first_hour.md`, `accrue/guides/upgrade.md`, and `examples/accrue_host/config/config.exs` - public docs and example-host mirrors.
  - Existing `Accrue.Migration.qualified_table/1` callsites - proof that raw SQL-like paths already use helper-qualified table names where needed.
- **D-11:** The ADR must state that `:billing_schema` is compile-time configuration for Ecto schemas and belongs in `config/config.exs`, not `config/runtime.exs`. Runtime-only config changes are not enough to change compiled schema prefixes safely.
- **D-12:** The phase should not implement hardening across all binding surfaces. It should document the contract now and hand Phase 204 the future guard list.

### Compatibility Story
- **D-13:** Use a **detailed upgrade warning**, not a terse note and not a public-to-billing migration recipe.
- **D-14:** Existing installs must pin their intended placement before recompiling: `config :accrue, :billing_schema, "public"` for existing public-schema installs, or `config :accrue, :billing_schema, "billing"` for existing/default billing-schema installs. Fresh installs keep `"billing"`.
- **D-15:** Moving production data between schemas is host-owned data migration work. Accrue should not automate it, hide it behind a default change, or publish a casual recipe in this phase. A future relocation guide is only appropriate if a later implementation milestone intentionally supports schema relocation.
- **D-16:** Explicit `public` remains a supported opt-out, not an inferior or deprecated path. The least-surprise contract is: default dedicated schema for new installs; explicit `public` when a host intentionally wants Accrue tables in the default schema.
- **D-17:** Do not rename the default to `accrue`. `accrue.accrue_*` is redundant in database tooling, creates upgrade-sensitive lookup risk for existing installs, and does not improve the real goal, which is avoiding unintentional `public` pollution.

### Phase 204 Handoff Shape
- **D-18:** Use a readable ADR followed by a **structured Phase 204 handoff table/checklist**. Do not leave future work as a short narrative list, and do not create issue-ready implementation cards before Phase 204 ranks cross-audit work.
- **D-19:** Each Phase 204 handoff row should include: area, evidence path, current risk, expected impact, tradeoff, implementation approach, verification, rollback, metric/evidence-needed status where relevant, and non-goals.
- **D-20:** Include at least these handoff rows for Phase 204 to rank:
  - Centralize the default billing schema constant so config, schema, installer, docs tests, and example host cannot drift silently.
  - Add representative schema-prefix assertions, including default `billing`.
  - Add explicit test lanes or focused checks for default `billing`, explicit `public`, and explicit `billing` compatibility.
  - Add a static guard for unqualified raw SQL references to Accrue-owned `accrue_*` tables outside approved migration helpers.
  - Keep installer `--billing-schema public` tested.
  - Keep configuration, First Hour, Upgrade, and example-host docs aligned on compile-time schema config.
  - Preserve the host-owned data migration boundary for any future schema relocation.
- **D-21:** Phase 203 priorities are local DB-schema-contract priorities, not final roadmap ranking. Phase 204 decides final ordering after consuming Phases 201, 202, and 203.

### Ecosystem And DX Lessons
- **D-22:** Ecto's native shape supports this contract: schema prefixes, migration prefixes, and query/repo prefixes are explicit mechanisms. Accrue should use explicit schema-qualified helpers rather than `search_path` assumptions.
- **D-23:** Phoenix's idiom is named domain boundaries and context modules. A domain-oriented schema name like `billing` fits the domain model better than a brand-redundant schema name like `accrue`.
- **D-24:** Oban is the closest Elixir ecosystem precedent: successful database-owning libraries make prefix use explicit in migrations and config. Cashier and Pay show the same cross-ecosystem lesson: framework-native billing libraries succeed when install, migrations, config, background jobs, upgrades, and provider boundaries are explicit.
- **D-25:** Great DX here means one clear default, one explicit opt-out, a compile-time warning boundary that users can understand, and proof-checkable docs. Do not make adopters learn internal modules unless those modules explain the real Ecto/Postgres constraint.

### Reviewed Todos
- `White-label billing portal design system` (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) - reviewed as UI/portal hardening, not folded into this DB schema ADR.
- `Shared page_header component for accrue_admin list pages` (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`) - reviewed as admin UI cleanup/resolved evidence, not folded into this DB schema ADR.
- `Use the Accrue favicon in the brandbook HTML` (`.planning/todos/pending/2026-06-19-brandbook-use-accrue-favicon.md`) - reviewed as brandbook polish, not folded into this DB schema ADR.

### the agent's Discretion

- The planner/researcher may tune section order, table labels, and exact ADR phrasing as long as D-01 through D-25 hold.
- The planner/researcher may use BCP-14-style words without formally importing every RFC convention, but the current-vs-future boundary must stay unambiguous.
- The planner/researcher may add concise examples when they improve developer understanding, but must avoid turning the ADR into an implementation guide or schema-move runbook.

### Deferred Ideas (OUT OF SCOPE)

- Actual schema-prefix hardening implementation: central constants, drift guards, compatibility lanes, raw SQL qualification checks, installer/doc/test guardrails, or example-host verification.
- Any default schema rename from `billing` to `accrue`.
- Any automatic production data movement between `public`, `billing`, or any future schema.
- Any public migration recipe for moving existing production data between schemas, unless a future implementation milestone intentionally supports schema relocation guidance.
- Any product behavior, public API, route, UI, CI topology, release automation, package metadata, or runtime config changes.

### Reviewed Todos (not folded)
- `White-label billing portal design system` - future portal/UI hardening candidate; unrelated to the DB schema ADR.
- `Shared page_header component for accrue_admin list pages` - admin UI/stale todo cleanup; unrelated to the DB schema ADR.
- `Use the Accrue favicon in the brandbook HTML` - brandbook polish; unrelated to the DB schema ADR.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DB-01 | Maintainer can read one ADR explaining the current Accrue-owned Postgres schema contract: default `billing`, explicit `public`, Ecto compile-time schema prefix, migration prefix helpers, and host-owned data-migration responsibility. | Local repo surfaces already implement and document these points, and Ecto/Postgres docs support explicit prefixes over implicit `search_path`. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: repo rg; CITED: https://ecto.hexdocs.pm/Ecto.Schema.html; CITED: https://www.postgresql.org/docs/current/ddl-schemas.html] |
| DB-02 | The ADR explains why v1.55 keeps `billing` instead of switching to `accrue`, including pros/cons and upgrade risk. | Phase decisions lock this rationale: `billing` is domain-oriented, `accrue.accrue_*` is redundant, and a default rename creates upgrade-sensitive lookup risk. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |
| DB-03 | The ADR lists concrete future hardening checks for prefix agreement, raw SQL qualification, installer/docs/test coverage, and explicit old-default compatibility. | Phase decisions require a structured Phase 204 handoff table with those check classes; local code has helper and test surfaces to reference. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md; VERIFIED: repo rg] |
| DB-04 | The ADR identifies which schema-related work belongs in a future implementation milestone and which work is not worth doing now. | v1.55 is audit/documentation/roadmap work only; runtime defaults, product behavior, CI topology, and package metadata changes are out of scope. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/PROJECT.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 203 should produce one accepted ADR, not code. The ADR should lock the current executable contract: `billing` remains the default Accrue-owned PostgreSQL schema, explicit `public` remains supported when the host opts in, Ecto schema prefix configuration is compile-time, migration/raw-SQL helpers must stay explicit, and data movement between schemas is host-owned migration work. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: accrue/lib/accrue/config.ex; VERIFIED: accrue/lib/accrue/schema.ex; VERIFIED: accrue/lib/accrue/migration.ex]

The strongest planning risk is wording that overstates implementation. The ADR can use BCP-14-style words for the current contract and non-goals, but future hardening must stay advisory and explicitly handed to Phase 204 for ranking. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md; CITED: https://www.rfc-editor.org/rfc/rfc2119; CITED: https://www.rfc-editor.org/rfc/rfc8174]

**Primary recommendation:** Refine `203-DB-SCHEMA-CONTRACT-ADR.md` into a hybrid accepted ADR with a structured Phase 204 handoff table; do not change config defaults, migrations, installer behavior, docs defaults, CI, package metadata, or runtime behavior in Phase 203. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

## Project Constraints (from CLAUDE.md)

- Accrue is an Elixir/Phoenix billing library with a stable-core, demand-driven expansion posture; Phase 203 must preserve the v1.55 audit-only maintenance boundary. [VERIFIED: CLAUDE.md; VERIFIED: .planning/PROJECT.md]
- The relevant stack baseline is Elixir, OTP, Phoenix, Ecto, PostgreSQL, Oban, Postgrex, and project-local Mix/ExUnit verification. [VERIFIED: CLAUDE.md; VERIFIED: accrue/mix.exs; VERIFIED: accrue/mix.lock]
- Core architectural ownership stays explicit: host apps own Repo, migrations, Oban supervision, auth, runtime secrets, and app-domain policy; Accrue owns its billing engine and Accrue-owned tables. [VERIFIED: .planning/PROJECT.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]
- Webhook, PII, and payment security rules are project-level constraints but not direct Phase 203 implementation surfaces. [VERIFIED: CLAUDE.md; VERIFIED: .planning/ROADMAP.md]
- Repo-local truth and proof-checkable wording are required; brand voice should be measured, exact, Phoenix-native, durable, and mechanism-led. [VERIFIED: brandbook/voice.md; VERIFIED: prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md]
- GSD workflow enforcement is active; this invocation is a GSD research phase and the implementation plan should remain within planning artifacts. [VERIFIED: CLAUDE.md; VERIFIED: .planning/config.json]
- No `AGENTS.md` file and no project-local `.claude/skills/` or `.agents/skills/` skill files were found. [VERIFIED: rg --files -uu; VERIFIED: find .claude/skills .agents/skills]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| ADR support contract | Documentation / Planning | API / Backend | Phase 203 produces a planning ADR while citing executable backend surfaces as evidence. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |
| Default schema posture | API / Backend | Database / Storage | `Accrue.Config`, `Accrue.Schema`, installer generation, and migration helpers define where Accrue-owned tables live. [VERIFIED: accrue/lib/accrue/config.ex; VERIFIED: accrue/lib/accrue/schema.ex; VERIFIED: accrue/lib/accrue/migration.ex] |
| Explicit `public` opt-out | API / Backend | Database / Storage | Installer options and docs already support `--billing-schema public` and `config :accrue, :billing_schema, "public"`. [VERIFIED: accrue/lib/accrue/install/options.ex; VERIFIED: accrue/test/mix/tasks/accrue_install_test.exs; VERIFIED: accrue/guides/configuration.md] |
| Schema relocation boundary | Database / Storage | Documentation / Planning | Any data movement between schemas would affect host-owned production data and must remain outside this ADR phase. [VERIFIED: accrue/guides/upgrade.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |
| Future hardening rank list | Documentation / Planning | API / Backend | Phase 203 identifies guardrails; Phase 204 ranks implementation across Phase 201-203 evidence. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| PostgreSQL | Local `14.17`; project floor `14+` | Schema namespace, `public`, `search_path`, and table placement semantics | PostgreSQL docs define schema namespaces and `search_path`; Accrue's project floor is PostgreSQL 14+. [VERIFIED: psql --version; VERIFIED: CLAUDE.md; CITED: https://www.postgresql.org/docs/current/ddl-schemas.html] |
| Ecto | Locked `3.13.6`; latest checked `3.14.0` | Schema prefix contract through `@schema_prefix` and `__schema__(:prefix)` | Ecto is the repo's domain modeling layer and official docs define schema-prefix behavior. [VERIFIED: accrue/mix.lock; VERIFIED: mix hex.info ecto; CITED: https://ecto.hexdocs.pm/Ecto.Schema.html] |
| Ecto SQL | Locked `3.13.5`; latest checked `3.14.0` | Migration table/reference/index prefix support | Ecto SQL is the repo's migration layer; Ecto docs show explicit `prefix:` migration patterns. [VERIFIED: accrue/mix.lock; VERIFIED: mix hex.info ecto_sql; CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html] |
| Postgrex | Locked `0.22.2` | PostgreSQL adapter for Ecto | Existing repo adapter for PostgreSQL; no Phase 203 changes needed. [VERIFIED: accrue/mix.lock; VERIFIED: mix deps] |
| Mix / ExUnit | Mix `1.19.5` | Targeted verification commands and markdown/content checks | Existing Elixir verification stack for repo tests and docs checks. [VERIFIED: mix --version; VERIFIED: accrue/mix.exs; VERIFIED: accrue/test/test_helper.exs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Phoenix | Locked `1.8.7` in `accrue`; example host `1.8.8` | Context vocabulary and domain boundary framing | Use for ADR wording that explains `billing` as a Phoenix-native domain boundary. [VERIFIED: accrue/mix.lock; VERIFIED: examples/accrue_host/mix.lock; CITED: https://phoenix.hexdocs.pm/contexts.html] |
| Oban | Locked `2.23.0` | Ecosystem precedent for explicit prefixed database-owning library tables | Cite as precedent only; Phase 203 does not change Oban config. [VERIFIED: accrue/mix.lock; VERIFIED: mix hex.info oban; CITED: https://oban.hexdocs.pm/Oban.Migration.html] |
| RFC 2119 / RFC 8174 | BCP 14 | Requirement keyword guidance | Use sparingly for current contract and non-goals; keep future hardening advisory. [CITED: https://www.rfc-editor.org/rfc/rfc2119; CITED: https://www.rfc-editor.org/rfc/rfc8174] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Default schema `billing` | Default schema `accrue` | Rejected for v1.55: `billing` already avoids `public` pollution, fits the domain boundary, and avoids upgrade-sensitive lookup risk. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |
| Explicit Ecto/Postgres prefixes | Rely on PostgreSQL `search_path` | Rejected as primary contract because unqualified references resolve through `search_path`; explicit helpers are more proof-checkable. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html; VERIFIED: accrue/lib/accrue/migration.ex] |
| ADR-only Phase 203 | Implement hardening guards now | Rejected by milestone scope; hardening implementation belongs in Phase 204 ranking and later execution. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |
| Host-owned schema move boundary | Publish a public-to-billing move recipe | Rejected for this phase because production data movement is host-owned and requires migration planning outside an ADR. [VERIFIED: accrue/guides/upgrade.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |

**Installation:**

```bash
# No new package install for Phase 203.
# Use the existing repo stack and edit only the phase ADR artifact.
```

**Version verification:** versions were checked with `mix deps`, `mix hex.info`, `mix --version`, `psql --version`, and local `mix.lock`. [VERIFIED: command output]

## Package Legitimacy Audit

No external package installation is recommended for Phase 203, so the Package Legitimacy Gate is not required. Existing package names above come from the checked-in repository lockfiles and Hex metadata, not from a new recommendation. [VERIFIED: .planning/ROADMAP.md; VERIFIED: accrue/mix.lock; VERIFIED: mix hex.info]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | none | n/a | n/a | n/a | n/a | No install in this phase. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no Phase 203 installs]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no Phase 203 installs]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 203 inputs
  |
  |-- CONTEXT decisions DB-01..DB-04
  |-- local code/docs/tests evidence
  |-- official Ecto/Postgres/Phoenix/Oban docs
  v
ADR refinement
  |
  |-- current contract: billing default, explicit public, compile-time schema prefix
  |-- binding surfaces: Config, Schema, Migration, installer, tests, guides, example host
  |-- non-goals: no default rename, no data movement, no runtime behavior changes
  |-- Phase 204 handoff table: future hardening checks with evidence and tradeoffs
  v
203-DB-SCHEMA-CONTRACT-ADR.md
  |
  v
Phase 204 ranked hardening roadmap consumes the structured handoff
```

The diagram reflects the phase dependency and artifact flow in `.planning/ROADMAP.md` and `.planning/phases/203-database-schema-contract-adr/203-CONTEXT.md`. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

### Recommended Project Structure

```text
.planning/phases/203-database-schema-contract-adr/
├── 203-CONTEXT.md
├── 203-RESEARCH.md
├── 203-01-PLAN.md
└── 203-DB-SCHEMA-CONTRACT-ADR.md
```

The only implementation artifact Phase 203 should edit is `203-DB-SCHEMA-CONTRACT-ADR.md`. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

### Pattern 1: Hybrid Accepted ADR

**What:** Make current behavior normative and future hardening advisory. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**When to use:** Use for support-contract documentation where the current contract exists but guardrail implementation is intentionally deferred. [VERIFIED: .planning/ROADMAP.md]  
**Example:**

```markdown
<!-- Source: phase decisions [VERIFIED: 203-CONTEXT.md] -->
## Decision

Accrue MUST keep `billing` as the default Accrue-owned Postgres schema for v1.x.
Accrue MAY support explicit `public` when the host opts in.

## Future Hardening

Accrue SHOULD add prefix-agreement checks in a later implementation milestone
if Phase 204 ranks that work high enough.
```

### Pattern 2: Layered Authoritative Surfaces

**What:** Separate executable sources of truth from mirrors. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**When to use:** Use when docs and tests must explain code/config behavior without pretending docs independently define runtime behavior. [VERIFIED: repo rg]  
**Example:**

```markdown
<!-- Source: phase decisions [VERIFIED: 203-CONTEXT.md] -->
Executable surfaces:
- `Accrue.Config`
- `Accrue.Schema`
- `Accrue.Migration`
- installer generation

Mirrors:
- guides
- example host config
- installer tests
```

### Pattern 3: Compile-Time Prefix Boundary

**What:** Treat Ecto schema prefix config as compile-time for schema modules, while migrations/raw SQL helpers read the configured billing schema through helper functions. [VERIFIED: accrue/lib/accrue/schema.ex; VERIFIED: accrue/lib/accrue/migration.ex]  
**When to use:** Use when explaining why `config/config.exs` is the correct placement and why `config/runtime.exs` alone cannot safely change compiled schema prefixes. [VERIFIED: accrue/guides/configuration.md; CITED: https://ecto.hexdocs.pm/Ecto.Schema.html]  
**Example:**

```elixir
# Source: accrue/lib/accrue/schema.ex [VERIFIED: repo sed]
@billing_schema Application.compile_env(:accrue, :billing_schema, "billing")

defmacro __using__(_opts) do
  billing_schema = Accrue.Config.validate_billing_schema!(@billing_schema)

  quote bind_quoted: [billing_schema: billing_schema] do
    use Ecto.Schema
    @schema_prefix billing_schema
  end
end
```

### Pattern 4: Structured Phase 204 Handoff

**What:** Every future hardening row should include area, evidence path, current risk, expected impact, tradeoff, implementation approach, verification, rollback, metric/evidence status, and non-goals. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**When to use:** Use at the end of the ADR so Phase 204 can rank work without mining prose. [VERIFIED: .planning/ROADMAP.md]  
**Example:**

```markdown
| Area | Evidence path | Current risk | Expected impact | Tradeoff | Implementation approach | Verification | Rollback | Evidence needed | Non-goals |
|------|---------------|--------------|-----------------|----------|-------------------------|--------------|----------|-----------------|-----------|
| Raw SQL qualification guard | `accrue/lib/accrue/analytics/dunning.ex` | Unqualified `accrue_*` SQL could bypass schema prefix. | Catches drift before release. | Static check may need allowlist. | Add grep/Credo guard outside helpers. | Failing fixture with unqualified table. | Remove guard or narrow allowlist. | Phase 204 ranking. | No SQL rewrite in Phase 203. |
```

### Anti-Patterns to Avoid

- **Runtime behavior change hidden in ADR work:** Phase 203 must not change defaults, migrations, installer behavior, or runtime code. [VERIFIED: .planning/ROADMAP.md]
- **Saying future guards already exist:** The ADR should not imply central constants, static guards, or compatibility lanes have shipped if they are only Phase 204 candidates. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]
- **Treating `public` as deprecated:** Explicit `public` remains supported when the host opts in. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md; VERIFIED: accrue/test/mix/tasks/accrue_install_test.exs]
- **Relying on `search_path`:** PostgreSQL resolves unqualified names through `search_path`, so Accrue should keep explicit prefix helpers as the primary contract. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html; VERIFIED: accrue/lib/accrue/migration.ex]
- **Publishing a casual schema-move recipe:** Moving production data is host-owned migration work and is out of Phase 203 scope. [VERIFIED: accrue/guides/upgrade.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ecto schema prefix semantics | Custom runtime table resolver | Ecto `@schema_prefix` through `Accrue.Schema` | Ecto already defines schema-prefix behavior and reflection. [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html; VERIFIED: accrue/lib/accrue/schema.ex] |
| Migration prefix agreement | Per-migration copied `prefix:` literals | `Accrue.Migration.table/2`, `references/2`, `index/3`, `unique_index/3` | Existing helpers centralize the configured schema prefix. [VERIFIED: accrue/lib/accrue/migration.ex] |
| Raw SQL table names | Interpolated unqualified `accrue_*` names | `Accrue.Migration.qualified_table/1` | Existing callsites already qualify raw SQL-like paths. [VERIFIED: accrue/lib/accrue/analytics/dunning.ex; VERIFIED: scripts/ci/accrue_host_seed_e2e.exs] |
| Config validation | Ad hoc schema-name string checks in docs | Existing `Accrue.Config.validate_billing_schema!/1` and installer validation | Existing code validates PostgreSQL-identifier-shaped schema names. [VERIFIED: accrue/lib/accrue/config.ex; VERIFIED: accrue/lib/accrue/install/options.ex] |
| Hardening prioritization | Issue-ready implementation cards in ADR | Phase 204 handoff table | Phase 204 owns final ranking after consuming Phases 201-203. [VERIFIED: .planning/ROADMAP.md] |

**Key insight:** The project already has explicit Ecto/Postgres mechanisms; Phase 203 should document and structure them, not replace them. [VERIFIED: repo rg; CITED: https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html]

## Common Pitfalls

### Pitfall 1: Compile-Time vs Runtime Config Confusion

**What goes wrong:** The ADR says changing `config/runtime.exs` is enough to change Accrue schema placement. [VERIFIED: accrue/guides/configuration.md]  
**Why it happens:** Ecto schemas compile `@schema_prefix`; migration helpers read config during migration execution. [VERIFIED: accrue/lib/accrue/schema.ex; VERIFIED: accrue/lib/accrue/migration.ex]  
**How to avoid:** State that `:billing_schema` belongs in `config/config.exs` and existing installs must pin placement before recompiling. [VERIFIED: accrue/guides/configuration.md; VERIFIED: accrue/guides/upgrade.md]  
**Warning signs:** ADR examples show only runtime config or omit recompilation language. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

### Pitfall 2: Normative Wording Overreach

**What goes wrong:** The ADR uses `MUST` for future static checks and implies they already ship. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**Why it happens:** BCP-14 language is tempting in ADRs, but RFC 2119 warns imperative words should be used sparingly. [CITED: https://www.rfc-editor.org/rfc/rfc2119]  
**How to avoid:** Use `MUST` for current contract and non-goals; use `SHOULD` or plain advisory language for Phase 204 candidates. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**Warning signs:** A future hardening checklist reads like an implemented verification gate. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

### Pitfall 3: `search_path` as the Contract

**What goes wrong:** Unqualified SQL can hit a table based on `search_path` instead of the intended Accrue schema. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html]  
**Why it happens:** PostgreSQL resolves unqualified names by traversing `search_path`, and `public` is the default location in a default setup. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html]  
**How to avoid:** Keep `Accrue.Migration.qualified_table/1` as the named mechanism and hand Phase 204 a raw-SQL qualification guard. [VERIFIED: accrue/lib/accrue/migration.ex; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**Warning signs:** Raw SQL fragments contain `"accrue_events"` instead of `Accrue.Migration.qualified_table(:accrue_events)`. [VERIFIED: accrue/lib/accrue/analytics/dunning.ex]

### Pitfall 4: Treating `public` as Inferior

**What goes wrong:** The ADR frames `public` as deprecated or unsafe for all hosts. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**Why it happens:** Dedicated schema is the default, but `public` is still a deliberate compatibility path. [VERIFIED: accrue/test/mix/tasks/accrue_install_test.exs; VERIFIED: accrue/guides/configuration.md]  
**How to avoid:** Phrase `public` as an explicit opt-out for hosts that intentionally want Accrue tables in the default schema. [VERIFIED: accrue/guides/configuration.md]  
**Warning signs:** Upgrade text tells public-schema installs to move data during Phase 203. [VERIFIED: accrue/guides/upgrade.md]

### Pitfall 5: Weak Phase 204 Handoff

**What goes wrong:** Future hardening is left as a short prose list, forcing Phase 204 to re-rank vague work. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**Why it happens:** The current phase has advisory future work but no implementation authority, so the ADR needs an explicit handoff shape. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**How to avoid:** Include the required handoff columns and evidence paths in the ADR. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
**Warning signs:** Future work lacks verification, rollback, tradeoff, or non-goal fields. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

## Code Examples

Verified patterns from local code and official sources:

### Compile-Time Ecto Schema Prefix

```elixir
# Source: accrue/lib/accrue/schema.ex [VERIFIED: repo sed]
@billing_schema Application.compile_env(:accrue, :billing_schema, "billing")

defmacro __using__(_opts) do
  billing_schema = Accrue.Config.validate_billing_schema!(@billing_schema)

  quote bind_quoted: [billing_schema: billing_schema] do
    use Ecto.Schema
    @schema_prefix billing_schema
  end
end
```

Ecto documents `@schema_prefix` and `__schema__(:prefix)` for this class of behavior. [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html]

### Migration Prefix Helpers

```elixir
# Source: accrue/lib/accrue/migration.ex [VERIFIED: repo sed]
def billing_prefix, do: Accrue.Config.billing_schema()

def table(name, opts \\ []) do
  Ecto.Migration.table(name, Keyword.put_new(opts, :prefix, billing_prefix()))
end

def qualified_table(name), do: qualified_name(billing_prefix(), name)
```

Ecto's migration-prefix docs support using explicit `prefix:` on migration table operations. [CITED: https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html]

### Installer Public Opt-Out

```elixir
# Source: accrue/test/mix/tasks/accrue_install_test.exs [VERIFIED: repo sed]
run_install(app, ["--yes", "--billing-schema", "public"])

assert InstallFixture.assert_contains!(
         app,
         "config/config.exs",
         "config :accrue, :billing_schema, \"public\""
       )
```

This test proves the current installer path preserves explicit `public`. [VERIFIED: accrue/test/mix/tasks/accrue_install_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Let billing tables fall into default `public` schema | Default Accrue-owned `billing` schema, with explicit `public` opt-out | Current repo state before Phase 203 | New installs avoid unintended `public` pollution while existing public-schema hosts can pin placement. [VERIFIED: accrue/guides/configuration.md; VERIFIED: accrue/guides/upgrade.md] |
| Rely on PostgreSQL `search_path` | Use Ecto schema prefixes, migration `prefix:` helpers, and qualified table helpers | Current repo state before Phase 203 | Query and migration behavior is explicit and checkable. [VERIFIED: accrue/lib/accrue/schema.ex; VERIFIED: accrue/lib/accrue/migration.ex; CITED: https://www.postgresql.org/docs/current/ddl-schemas.html] |
| Prose-only future work | Structured Phase 204 handoff rows | Locked by Phase 203 context | Phase 204 can rank DB hardening against software-quality and CI/CD findings. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md; VERIFIED: .planning/ROADMAP.md] |
| Brand-based database schema name | Domain-oriented `billing` schema | Locked by Phase 203 context | `billing.accrue_*` is clearer than `accrue.accrue_*` for database tooling and Phoenix domain vocabulary. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md; CITED: https://phoenix.hexdocs.pm/contexts.html] |

**Deprecated/outdated:**
- Treating `search_path` as Accrue's primary schema contract is out of scope and explicitly rejected. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md; CITED: https://www.postgresql.org/docs/current/ddl-schemas.html]
- Renaming the default schema to `accrue` is out of scope for v1.55 and v1.x current contract wording. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| none | No assumed claims remain in this research. | n/a | n/a |

All implementation-relevant claims were verified against repo files, project planning files, Hex/Mix output, or official docs. [VERIFIED: repo commands; CITED: official docs listed in Sources]

## Open Questions

1. **Does Phase 204 rank DB schema hardening above other audit findings?**  
   What we know: Phase 203 must hand off DB hardening candidates, and Phase 204 consumes Phases 201, 202, and 203. [VERIFIED: .planning/ROADMAP.md]  
   What's unclear: Final priority ranking is intentionally downstream. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]  
   Recommendation: Do not pre-rank beyond local DB priority; make ADR rows structured enough for Phase 204. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix/ExUnit verification | yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: elixir --version] |
| Mix | Dependency and test commands | yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: mix --version] |
| PostgreSQL server | Existing Accrue DB tests | yes | `pg_isready` accepted connections on `/tmp:5432` | For ADR-only markdown checks, DB tests can be skipped if no code changed. [VERIFIED: pg_isready; VERIFIED: .planning/ROADMAP.md] |
| psql | DB version probe | yes | 14.17 | None needed. [VERIFIED: psql --version] |
| Git | Optional GSD research commit | yes | available through repo status | Commit only the research file; do not include existing unrelated changes. [VERIFIED: git status --short] |

**Missing dependencies with no fallback:** none found for research and docs-only planning. [VERIFIED: environment probes]  
**Missing dependencies with fallback:** Context7 MCP/CLI was unavailable; official documentation URLs were fetched directly and cached through the GSD research store. [VERIFIED: command -v ctx7; VERIFIED: research-store put output]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix `1.19.5`; repo uses `accrue/test/test_helper.exs`. [VERIFIED: mix --version; VERIFIED: accrue/test/test_helper.exs] |
| Config file | `accrue/config/test.exs`. [VERIFIED: accrue/config/test.exs] |
| Quick run command | `rg -n "billing|public|compile-time|Phase 204|search_path|host-owned|accrue" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` [VERIFIED: rg available through prior commands] |
| Full suite command | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/config_test.exs` for code evidence confidence; docs-only ADR acceptance can use the grep checklist if no code changed. [VERIFIED: accrue/mix.exs; VERIFIED: test files exist] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DB-01 | ADR explains `billing`, explicit `public`, compile-time schema prefix, migration helpers, and host-owned data migration. | markdown/content smoke | `rg -n "billing|public|compile-time|Accrue\\.Schema|Accrue\\.Migration|host-owned" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes, current draft exists. [VERIFIED: phase artifact read] |
| DB-02 | ADR explains why default does not switch to `accrue`. | markdown/content smoke | `rg -n "accrue\\.accrue_|Why Not|out of scope|upgrade risk|rename" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes, current draft exists. [VERIFIED: phase artifact read] |
| DB-03 | ADR lists concrete future hardening checks. | markdown/content smoke | `rg -n "Phase 204|prefix-agreement|raw SQL|installer|docs|test|compatibility|qualified" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes, current draft exists. [VERIFIED: phase artifact read] |
| DB-04 | ADR separates future implementation work from work not worth doing now. | markdown/content smoke | `rg -n "Future Hardening|Non-Goals|not part|out of scope|implementation milestone" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes, current draft exists. [VERIFIED: phase artifact read] |

### Sampling Rate

- **Per task commit:** run the markdown/content smoke commands for DB-01 through DB-04. [VERIFIED: .planning/REQUIREMENTS.md]
- **Per wave merge:** if code is not changed, no app test suite is required; if any code/doc mirror under `accrue/` changes, run `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/config_test.exs`. [VERIFIED: .planning/ROADMAP.md; VERIFIED: accrue/mix.exs]
- **Phase gate:** ADR file exists and every DB-01..DB-04 smoke command returns at least one line. [VERIFIED: .planning/REQUIREMENTS.md]

### Wave 0 Gaps

None for the ADR artifact. Existing application tests cover installer default `billing`, explicit `public`, and config validation evidence if implementation later touches code. [VERIFIED: accrue/test/mix/tasks/accrue_install_test.exs; VERIFIED: accrue/test/accrue/config_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 203 does not change auth behavior. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Phase 203 does not change sessions. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | limited | Preserve host-owned data migration and schema placement boundaries; do not automate production moves. [VERIFIED: accrue/guides/upgrade.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |
| V5 Input Validation | yes | Preserve existing PostgreSQL identifier validation for `:billing_schema` and installer `--billing-schema`. [VERIFIED: accrue/lib/accrue/config.ex; VERIFIED: accrue/lib/accrue/install/options.ex] |
| V6 Cryptography | no | No cryptographic behavior changes in this phase. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for Elixir/Ecto/PostgreSQL Schema Contracts

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unqualified raw SQL touches the wrong schema through `search_path`. | Tampering | Use `Accrue.Migration.qualified_table/1` and hand Phase 204 a static guard. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html; VERIFIED: accrue/lib/accrue/migration.ex] |
| Default schema rename causes existing installs to query empty or wrong tables after recompilation. | Tampering / Denial of Service | Keep `billing` default, require existing installs to pin placement, and do not rename in v1.55. [VERIFIED: accrue/guides/upgrade.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |
| Invalid schema identifier is accepted into config or installer. | Tampering | Keep `validate_billing_schema!/1` and installer identifier validation; future work can centralize the default constant. [VERIFIED: accrue/lib/accrue/config.ex; VERIFIED: accrue/lib/accrue/install/options.ex] |
| ADR implies unsupported automated data movement. | Repudiation / Tampering | State that schema relocation is host-owned data migration work and outside Phase 203. [VERIFIED: accrue/guides/upgrade.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/203-database-schema-contract-adr/203-CONTEXT.md` - locked phase decisions, scope, binding surfaces, Phase 204 handoff shape. [VERIFIED: local read]
- `.planning/REQUIREMENTS.md` - DB-01 through DB-04 definitions. [VERIFIED: local read]
- `.planning/ROADMAP.md` - Phase 203 goal, success criteria, and audit-only scope. [VERIFIED: local read]
- `.planning/PROJECT.md` and `.planning/STATE.md` - stable-core posture and current milestone state. [VERIFIED: local read]
- `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/schema.ex`, `accrue/lib/accrue/migration.ex` - executable schema contract surfaces. [VERIFIED: repo sed/rg]
- Installer, docs, tests, and example-host files named in the context - mirror surfaces for default `billing` and explicit `public`. [VERIFIED: repo sed/rg]

### Secondary (MEDIUM confidence)

- https://ecto.hexdocs.pm/Ecto.Schema.html - `@schema_prefix` and `__schema__(:prefix)` behavior. [CITED: official docs]
- https://ecto-sql.hexdocs.pm/Ecto.Migration.html - migration table/index/reference docs. [CITED: official docs]
- https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html - prefix precedence and migration prefix examples. [CITED: official docs]
- https://www.postgresql.org/docs/current/ddl-schemas.html - PostgreSQL schema namespaces and `search_path`. [CITED: official docs]
- https://phoenix.hexdocs.pm/contexts.html - Phoenix contexts as domain/API boundaries. [CITED: official docs]
- https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Gen.Context.html - generated contexts as API boundaries around schemas. [CITED: official docs]
- https://oban.hexdocs.pm/Oban.Migration.html and https://oban.hexdocs.pm/isolation.html - Oban prefix migration/config precedent. [CITED: official docs]
- https://www.rfc-editor.org/rfc/rfc2119 and https://www.rfc-editor.org/rfc/rfc8174 - BCP 14 requirement keyword guidance. [CITED: official RFCs]

### Tertiary (LOW confidence)

- none. [VERIFIED: Assumptions Log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions verified from `mix.lock`, `mix deps`, `mix hex.info`, and runtime probes. [VERIFIED: command output]
- Architecture: HIGH - phase scope and binding surfaces are locked in `203-CONTEXT.md` and verified against local files. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md; VERIFIED: repo rg]
- Pitfalls: HIGH - pitfalls are sourced from local code, locked phase decisions, and official docs. [VERIFIED: repo rg; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-CONTEXT.md; CITED: official docs]

**Research date:** 2026-07-02  
**Valid until:** 2026-08-01 for planning purposes; re-check if Ecto/PostgreSQL/Oban prefix docs or the Phase 203 ADR draft change before planning. [VERIFIED: current_date; CITED: official docs]
