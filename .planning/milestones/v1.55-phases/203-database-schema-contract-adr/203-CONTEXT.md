# Phase 203: database-schema-contract-adr - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 203 produces `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`: an accepted ADR that locks Accrue's current Postgres schema-prefix contract without changing runtime behavior, migrations, installer defaults, docs defaults, CI topology, package metadata, or product surface.

The ADR must keep `billing` as the default Accrue-owned Postgres schema, preserve explicit `public` as an opt-in escape hatch, explain why renaming the default to `accrue` is out of scope for v1.55, and hand Phase 204 a structured list of future schema-prefix hardening checks to rank against the Phase 201 and Phase 202 evidence.

</domain>

<decisions>
## Implementation Decisions

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

### Claude's Discretion
- The planner/researcher may tune section order, table labels, and exact ADR phrasing as long as D-01 through D-25 hold.
- The planner/researcher may use BCP-14-style words without formally importing every RFC convention, but the current-vs-future boundary must stay unambiguous.
- The planner/researcher may add concise examples when they improve developer understanding, but must avoid turning the ADR into an implementation guide or schema-move runbook.

### Reviewed Todos
- `White-label billing portal design system` (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) - reviewed as UI/portal hardening, not folded into this DB schema ADR.
- `Shared page_header component for accrue_admin list pages` (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`) - reviewed as admin UI cleanup/resolved evidence, not folded into this DB schema ADR.
- `Use the Accrue favicon in the brandbook HTML` (`.planning/todos/pending/2026-06-19-brandbook-use-accrue-favicon.md`) - reviewed as brandbook polish, not folded into this DB schema ADR.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/PROJECT.md` - Stable-core posture, v1.55 audit-only maintenance goal, and current milestone rationale.
- `.planning/ROADMAP.md` - Phase 203 boundary, success criteria, dependency shape, and no-code-change posture.
- `.planning/REQUIREMENTS.md` - DB-01..DB-04 and RD-01..RD-04 requirements and traceability.
- `.planning/STATE.md` - Current v1.55 state, known deferred items, and standing intake rules.
- `.planning/phases/201-software-quality-evaluation/201-CONTEXT.md` - Phase 201 split: Phase 203 owns schema-prefix ADR details, not Phase 201.
- `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` - Cross-quality audit that identifies schema-prefix safety as a data/upgrade risk.
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` - Phase 202 handoff precedent and audit-only discipline.
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` - Specialist CI/CD evidence that Phase 204 will rank alongside Phase 203.
- `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` - Downstream integration target for ranked hardening work.

### Phase Artifact
- `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` - Canonical ADR to refine; current draft already keeps `billing`, preserves explicit `public`, rejects `accrue` rename, and lists future hardening work.

### Schema Contract Code
- `accrue/lib/accrue/config.ex` - `:billing_schema` default, validation, and configuration docs.
- `accrue/lib/accrue/schema.ex` - Ecto schema prefix setup through compile-time config.
- `accrue/lib/accrue/migration.ex` - migration prefix helpers, schema creation, identifier quoting, and raw SQL table qualification helpers.
- `accrue/lib/accrue/install/options.ex` - installer `--billing-schema` default and validation.
- `accrue/lib/accrue/install/patches.ex` - generated host config snippet for `:billing_schema`.
- `accrue/lib/accrue/install/templates.ex` - installer defaults passed into generated files.
- `accrue/lib/mix/tasks/accrue.install.ex` - CLI docs, reporting, and installer wiring for `--billing-schema`.
- `accrue/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs` - representative Accrue-owned table migration using `Accrue.Migration.*`.
- `accrue/lib/accrue/analytics/dunning.ex` - representative runtime query module using `Accrue.Migration.qualified_table/1`.
- `scripts/ci/accrue_host_seed_e2e.exs` - representative proof/fixture script using qualified table helpers.

### Tests And Public Docs
- `accrue/test/mix/tasks/accrue_install_test.exs` - current tests for generated default `billing`, explicit `public`, and installer option docs.
- `accrue/test/mix/tasks/accrue_install_uat_test.exs` - installer UAT coverage and generated public-boundary behavior.
- `examples/accrue_host/test/install_boundary_test.exs` - example-host install boundary checks.
- `accrue/guides/configuration.md` - public configuration guide for compile-time `:billing_schema`, default `billing`, and explicit `public`.
- `accrue/guides/first_hour.md` - first-run guide that surfaces generated schema config and `--billing-schema public`.
- `accrue/guides/upgrade.md` - upgrade contract, existing `public` install warning, and host-owned schema move boundary.
- `examples/accrue_host/config/config.exs` - checked-in example host pinning `billing`.

### Product, Voice, And Research Lens
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - adopter-first, idiomatic-Elixir, DX-heavy, repo-local-truth research lens requested by the maintainer.
- `prompts/accrue-brand-book.md` - older brand research; use only where not superseded by committed brandbook artifacts.
- `brandbook/voice.md` - authoritative voice system: measured, exact, Phoenix-native, durable, mechanism-led, proof-checkable.
- `brandbook/copy.md` - approved public-surface copy patterns and mechanism-led claim posture.
- `brandbook/README.md` - current committed brand asset system and source of truth over older prompt material.

### Reviewed Todos
- `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md` - reviewed and not folded; UI/portal scope.
- `.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md` - reviewed and not folded; admin UI/stale todo scope.
- `.planning/todos/pending/2026-06-19-brandbook-use-accrue-favicon.md` - reviewed and not folded; brandbook polish scope.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `203-DB-SCHEMA-CONTRACT-ADR.md`: seeded ADR baseline already states the accepted default, public opt-out, why `accrue` is not the default, consequences, non-goals, and future hardening list.
- `Accrue.Schema`: the compile-time Ecto prefix mechanism exists and validates the configured schema before applying `@schema_prefix`.
- `Accrue.Migration`: the migration prefix helper layer exists for tables, references, indexes, unique indexes, schema creation, and raw SQL table qualification.
- Installer option/patch/template/task code: the generated host config already defaults to `billing` and can write explicit `public`.
- Installer tests and public guides: current evidence already proves default `billing` and explicit `public` are documented and generated.

### Established Patterns
- Accrue favors proof-led claims and named mechanisms. The ADR should name `@schema_prefix`, migration `prefix`, compile-time config, and qualified table helpers rather than saying the schema posture is merely "safe" or "clean".
- The project keeps host ownership explicit: host apps own Repo, migrations, runtime secrets, auth, routes, and data migration work; Accrue owns the billing engine and Accrue-owned tables.
- v1.55 is audit/documentation/hardening-roadmap work. Implementation guards should be described for Phase 204 ranking, not shipped inside Phase 203.
- The brand voice prefers exact Phoenix terms and mechanism-led support boundaries. Avoid Rails vocabulary except when crediting ecosystem lessons.

### Integration Points
- Phase 203 output feeds Phase 204. The ADR needs a structured handoff table so Phase 204 can rank DB hardening against software-quality and CI/CD hardening without re-mining prose.
- Future implementation likely touches `Accrue.Config`, `Accrue.Schema`, `Accrue.Migration`, installer code, docs, tests, and static checks for raw SQL qualification. Phase 203 should identify these surfaces but not edit them.
- Any future default rename or schema relocation would require docs, tests, installer, example host, upgrade guidance, compatibility lanes, and host-owned data migration planning. This phase rejects that default rename for v1.55.

</code_context>

<specifics>
## Specific Ideas

- The cohesive recommendation set is: hybrid accepted ADR, layered authoritative surfaces, detailed compatibility warning, and structured Phase 204 handoff table.
- Ecto official docs support the current approach: `@schema_prefix` applies a prefix whenever the schema is used, while Ecto migrations support `prefix:` for tables/indexes/references.
- Ecto prefix precedence and Postgres schema behavior reinforce why Accrue should use explicit prefixes and qualified helper names rather than rely on `search_path`.
- Phoenix contexts reinforce domain naming: `billing` is the domain boundary a Phoenix developer expects; `accrue.accrue_*` is brand-redundant and less readable.
- Oban is the closest Elixir ecosystem precedent: prefix support is explicit in migration calls and config, and the docs state that the prefixed migration creates the schema/tables in that namespace.
- Laravel Cashier and Pay for Rails show what successful billing libraries get right: framework-native install steps, host-visible migrations, explicit config, background-job/webhook setup, and upgrade notes for data/schema changes. Their footgun lesson is that schema terminology and migration changes become support burden when they are unclear or look user-facing but are actually internal.
- External references consulted during discussion:
  - `https://ecto.hexdocs.pm/Ecto.Schema.html`
  - `https://ecto-sql.hexdocs.pm/Ecto.Migration.html`
  - `https://github.com/elixir-ecto/ecto/blob/master/guides/howtos/Multi%20tenancy%20with%20query%20prefixes.md`
  - `https://www.postgresql.org/docs/current/ddl-schemas.html`
  - `https://www.postgresql.org/docs/current/sql-createschema.html`
  - `https://phoenix.hexdocs.pm/contexts.html`
  - `https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Gen.Context.html`
  - `https://oban.hexdocs.pm/2.5.0/Oban.Migrations.html`
  - `https://laravel.com/docs/13.x/billing`
  - `https://github.com/laravel/cashier-stripe/blob/16.x/UPGRADE.md`
  - `https://github.com/pay-rails/pay/`
  - `https://github.com/pay-rails/pay/blob/main/docs/1_installation.md`
  - `https://api.rubyonrails.org/classes/ActiveRecord/Migration.html`
  - `https://datatracker.ietf.org/doc/html/rfc2119`
  - `https://datatracker.ietf.org/doc/html/rfc8174`

</specifics>

<deferred>
## Deferred Ideas

- Actual schema-prefix hardening implementation: central constants, drift guards, compatibility lanes, raw SQL qualification checks, installer/doc/test guardrails, or example-host verification.
- Any default schema rename from `billing` to `accrue`.
- Any automatic production data movement between `public`, `billing`, or any future schema.
- Any public migration recipe for moving existing production data between schemas, unless a future implementation milestone intentionally supports schema relocation guidance.
- Any product behavior, public API, route, UI, CI topology, release automation, package metadata, or runtime config changes.

### Reviewed Todos (not folded)
- `White-label billing portal design system` - future portal/UI hardening candidate; unrelated to the DB schema ADR.
- `Shared page_header component for accrue_admin list pages` - admin UI/stale todo cleanup; unrelated to the DB schema ADR.
- `Use the Accrue favicon in the brandbook HTML` - brandbook polish; unrelated to the DB schema ADR.

</deferred>

---

*Phase: 203-database-schema-contract-adr*
*Context gathered: 2026-07-02*
