# Phase 16: Expansion Discovery - Research

**Researched:** 2026-04-17
**Domain:** Ranking future billing expansion work without weakening Accrue's current Stripe-first, host-owned architecture
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DISC-01 | Tax support options are evaluated and captured as a future milestone recommendation. | Recommend Stripe Tax as the only near-term tax path because Accrue is already Stripe-first, Stripe Tax supports subscriptions and invoices, and existing recurring items require explicit migration planning. [VERIFIED: repo files] [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/tax/customer-locations] |
| DISC-02 | Revenue recognition and export options are evaluated and captured as a future milestone recommendation. | Recommend Stripe-native reporting and export paths first: Revenue Recognition dashboard/CSV, Revenue Recognition API public preview, Sigma scheduled queries, and Data Pipeline warehouse delivery. [CITED: https://docs.stripe.com/revenue-recognition/get-started] [CITED: https://docs.stripe.com/revenue-recognition/api] [CITED: https://docs.stripe.com/stripe-data/export-customizations] [CITED: https://docs.stripe.com/sigma/scheduled-queries] |
| DISC-03 | Additional processor adapter candidates are evaluated without weakening the existing Stripe-first abstraction. | Recommend no core second-processor milestone now; keep the current custom-processor escape hatch documented, treat official second-processor work as a planted seed, and avoid false parity. [VERIFIED: repo files] [VERIFIED: .planning/PROJECT.md] [CITED: https://github.com/pay-rails/pay] [CITED: https://laravel.com/docs/12.x/billing] [CITED: https://laravel.com/docs/11.x/cashier-paddle] |
| DISC-04 | Organization and multi-tenant billing flows are evaluated against Sigra and host-owned schema constraints. | Recommend org-first billing as backlog work gated on Sigra org support, using Accrue's existing `owner_type`/`owner_id` model plus Ecto foreign-key tenancy patterns rather than schema-prefix tenancy. [VERIFIED: repo files] [VERIFIED: .planning/PROJECT.md] [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html] |
| DISC-05 | Expansion candidates are ranked into a recommended next implementation milestone, backlog, or planted seed. | Rank Stripe Tax as the next milestone, organization/multi-tenant and revenue/export as backlog items with prerequisites, and second-processor work as a planted seed. [VERIFIED: repo files] [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/revenue-recognition/get-started] [CITED: https://github.com/pay-rails/pay] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Accrue stays on Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, PostgreSQL `14+`, and should not widen its platform surface as part of discovery work. [VERIFIED: CLAUDE.md]
- Stripe remains the current processor baseline through `lattice_stripe`; discovery work should not recommend architecture that weakens the existing Stripe-first contract without proof of demand. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/PROJECT.md]
- Generated files, routing, auth, runtime config, and billable ownership remain host-owned boundaries. [VERIFIED: CLAUDE.md] [VERIFIED: accrue/README.md]
- Webhook verification is mandatory, secrets stay runtime-only, and payment-method details remain processor references rather than stored PII. Any expansion path must preserve those constraints. [VERIFIED: CLAUDE.md]
- `sigra` is optional today, and organization support is explicitly future work rather than a shipped dependency Accrue can rely on now. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/PROJECT.md]
- `workflow.nyquist_validation` is enabled in `.planning/config.json`, so the plan should include concrete verification for whatever decision artifact Phase 16 produces. [VERIFIED: .planning/config.json]

## Summary

Phase 16 should be planned as a decision artifact phase, not an implementation phase. The repo already hardens two key boundaries that constrain every recommendation: Accrue is intentionally Stripe-first today, and the billable/install/auth/runtime surface is host-owned. The current customer model is polymorphic through `owner_type` and `owner_id`, and the processor boundary is a documented extension point, but the public docs explicitly warn against pretending every custom processor can match full Stripe parity. [VERIFIED: repo files] [VERIFIED: .planning/PROJECT.md]

Current official docs make the ranking clearer than training-memory would. Stripe Tax is the cleanest next milestone because it directly extends the Stripe Billing surface Accrue already uses, while keeping the processor model unchanged. Revenue recognition and export are better treated as Stripe-native reporting/export follow-ons because Stripe already offers dashboard reports, CSV export, scheduled Sigma queries, Data Pipeline delivery, and a Revenue Recognition API that is still in public preview. Organization and multi-tenant billing remain structurally plausible because Accrue already stores polymorphic ownership, but Sigra organization support is still a dependency and Ecto's own guidance says query-prefix tenancy carries real migration and operational cost compared with foreign-key tenancy. [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/revenue-recognition/get-started] [CITED: https://docs.stripe.com/revenue-recognition/api] [CITED: https://docs.stripe.com/stripe-data/export-customizations] [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html] [VERIFIED: .planning/PROJECT.md]

The strongest "do not rush this" result is processor expansion. Official ecosystem precedent is cautionary: Pay supports multiple processors but warns that complex apps are better off sticking to one provider, and Laravel maintains separate Cashier packages for Stripe and Paddle rather than a single shared billing package. That lines up with Accrue's own project history: preserve Stripe-first clarity, keep the custom processor hook available for host-specific adapters, and plant official second-processor work as a seed instead of the next milestone. [CITED: https://github.com/pay-rails/pay] [CITED: https://laravel.com/docs/12.x/billing] [CITED: https://laravel.com/docs/11.x/cashier-paddle] [VERIFIED: .planning/PROJECT.md]

**Primary recommendation:** Plan Phase 16 to produce a ranked recommendation document that promotes Stripe Tax to the next milestone, puts org-first tenancy and Stripe-native revenue/export work into backlog with prerequisites, and parks official second-processor support as a planted seed. [VERIFIED: repo files] [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://github.com/pay-rails/pay]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tax calculation and collection | Processor / Stripe Billing | Host app customer-data capture | Stripe Tax is a Stripe-side capability, while the host app must collect and maintain customer location data needed to enable it. [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/tax/customer-locations] |
| Revenue recognition and exports | Stripe reporting layer | Host finance integrations / warehouse | Stripe already owns the ledger/report generation paths; Accrue should orchestrate export access rather than recreate accounting logic first. [CITED: https://docs.stripe.com/revenue-recognition/get-started] [CITED: https://docs.stripe.com/revenue-recognition/api] [CITED: https://docs.stripe.com/stripe-data/export-customizations] |
| Additional processor support | Separate adapter package or host-owned adapter | Core `Accrue.Processor` contract | The repo documents the behaviour as an extension point, but official ecosystem evidence argues against forcing broad parity into the core library. [VERIFIED: accrue/guides/custom_processors.md] [CITED: https://github.com/pay-rails/pay] [CITED: https://laravel.com/docs/11.x/cashier-paddle] |
| Organization / multi-tenant scoping | Host app auth + tenancy boundary | Core billing ownership model | Accrue already models billables polymorphically, but tenancy context and actor resolution still belong to the host app and future Sigra org support. [VERIFIED: repo files] [VERIFIED: .planning/PROJECT.md] |
| Decision ranking artifact | Planning/docs tier | Repo test/docs contract | Phase 16's immediate output is a checked-in recommendation artifact that future planners consume. [VERIFIED: repo files] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Existing `accrue` core | `0.1.2` [VERIFIED: accrue/mix.exs] | Baseline architecture being evaluated | Phase 16 should extend roadmap decisions from the shipped Stripe-first surface, not introduce a parallel billing stack. [VERIFIED: accrue/mix.exs] [VERIFIED: .planning/PROJECT.md] |
| `lattice_stripe`-backed Stripe Billing integration | `~> 1.1` in repo [VERIFIED: accrue/mix.exs] | Current processor substrate | Tax and revenue/export recommendations should stay on top of the Stripe integration Accrue already depends on. [VERIFIED: accrue/mix.exs] [VERIFIED: CLAUDE.md] |
| Stripe Tax | Stripe product, no extra package [CITED: https://docs.stripe.com/tax/set-up] | Automated subscription/invoice tax calculation | It fits the existing Stripe-first architecture and avoids inventing a provider-agnostic tax layer. [CITED: https://docs.stripe.com/tax/set-up] |
| Stripe Revenue Recognition + Stripe Data exports | Stripe product, no extra package [CITED: https://docs.stripe.com/revenue-recognition/get-started] | Accounting reports and export paths | Stripe already provides dashboard reports, CSVs, API access, Sigma, and Data Pipeline, so the standard path is to use those first. [CITED: https://docs.stripe.com/revenue-recognition/get-started] [CITED: https://docs.stripe.com/revenue-recognition/api] [CITED: https://docs.stripe.com/stripe-data/export-customizations] |
| Ecto multi-tenant patterns | `3.13.5` [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] | Guidance for org/multi-tenant planning | Official Ecto guidance favors foreign-key tenancy as the cheaper default and treats query prefixes as more operationally expensive. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Accrue.Processor` behaviour | repo-local [VERIFIED: accrue/lib/accrue/processor.ex] | Future adapter seam | Use for host-owned or future separate-package processor experiments, not as justification for core parity work now. [VERIFIED: accrue/lib/accrue/processor.ex] [VERIFIED: accrue/guides/custom_processors.md] |
| Stripe Sigma scheduled queries | Stripe product [CITED: https://docs.stripe.com/sigma/scheduled-queries] | Scheduled operational/accounting exports | Use when teams need recurring CSV/webhook deliveries without warehouse setup. [CITED: https://docs.stripe.com/sigma/scheduled-queries] |
| Stripe Data Pipeline | Stripe product [CITED: https://docs.stripe.com/stripe-data/export-customizations] | Warehouse delivery for finance/reporting | Use when customers need warehouse-native exports instead of app-managed CSV downloads. [CITED: https://docs.stripe.com/stripe-data/export-customizations] |
| Ecto `prepare_query/3` + `default_options/1` + composite FKs | `3.13.5` docs [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] | Safe row-scoped tenancy | Use for future org billing if Accrue adds stronger tenant guarantees beyond today's polymorphic ownership model. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Stripe Tax | Manual tax rates or a custom tax engine | Stripe already supports automatic tax on subscriptions and invoices; manual/custom tax logic would shift compliance risk and migration burden into Accrue. [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/tax/customer-locations] |
| Stripe-native revenue/export paths | Custom accounting ledger/export subsystem in Accrue | Stripe already provides reports, CSV export, Sigma, Data Pipeline, and a Revenue Recognition API, so a first-party ledger would be higher risk and duplicate surface area. [CITED: https://docs.stripe.com/revenue-recognition/get-started] [CITED: https://docs.stripe.com/revenue-recognition/api] [CITED: https://docs.stripe.com/stripe-data/export-customizations] |
| Foreign-key tenancy for future org billing | Query-prefix tenancy | Prefix isolation is stronger, but Ecto documents the per-tenant migration and versioning cost explicitly. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html] |
| No official second processor yet | Paddle, Lemon Squeezy, or Braintree in core | Mature alternatives exist, but processor models differ materially and ecosystem precedent warns against promising broad parity. [CITED: https://github.com/pay-rails/pay] [CITED: https://laravel.com/docs/11.x/cashier-paddle] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] |

**Installation:**
```bash
# No new runtime dependencies are recommended for Phase 16 itself.
# The phase output should be a checked-in recommendation artifact.
```

**Version verification:** No new package install is recommended for this phase; the relevant implementation stack is already present in repo (`accrue` `0.1.2`, `accrue_admin` `0.1.2`, `lattice_stripe ~> 1.1`). [VERIFIED: accrue/mix.exs] [VERIFIED: accrue_admin/mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
Current Accrue host app
        |
        +--> Host-owned billable + auth boundary
        |         |
        |         +--> future org context from Sigra / host tenancy
        |         +--> customer location and billing profile capture
        |
        +--> Accrue billing facade
        |         |
        |         +--> Stripe-first processor contract
        |         +--> local projection tables with owner_type / owner_id
        |
        +--> Expansion options
                  |
                  +--> Stripe Tax -> tax settings + customer location + recurring item migration
                  +--> Stripe Revenue/Exports -> reports/API/Sigma/Data Pipeline
                  +--> Org tenancy -> stronger host scoping + optional org data model evolution
                  +--> Second processor -> separate-package or host-owned adapter only if demand clears
```

### Recommended Project Structure

```text
.planning/phases/16-expansion-discovery/   # ranked recommendation artifact
accrue/guides/custom_processors.md         # existing adapter boundary
accrue/guides/sigra_integration.md         # existing auth/org dependency boundary
accrue/lib/accrue/billable.ex              # current polymorphic owner model
accrue/lib/accrue/billing/customer.ex      # owner_type/owner_id customer projection
.planning/PROJECT.md                       # prior-art and milestone constraints
```

### Pattern 1: Stripe-Native Expansion First
**What:** Prefer Stripe products that deepen the current Stripe Billing integration before adding provider-agnostic abstractions. [VERIFIED: .planning/PROJECT.md] [CITED: https://docs.stripe.com/tax/set-up]
**When to use:** Tax and revenue/export recommendations. [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/revenue-recognition/get-started]
**Example:**
```text
Host app collects/updates customer location
        -> Accrue enables Stripe automatic_tax on subscription/invoice flows
        -> Stripe calculates tax
        -> Accrue stores local billing state and reacts to webhook/status changes
```

### Pattern 2: Rank By Architecture Drag, Not Just Feature Desire
**What:** Prefer candidates that preserve the existing processor contract, host-owned boundary, and projection model. [VERIFIED: repo files]
**When to use:** Deciding milestone vs backlog vs seed. [VERIFIED: repo files]
**Example:**
```text
Stripe Tax: extends existing Stripe flow -> next milestone
Revenue exports: existing Stripe reporting exists -> backlog
Second processor: changes contract expectations and parity burden -> planted seed
```

### Pattern 3: Org Tenancy Through Row Scoping Before Schema Sharding
**What:** If Accrue later adds stronger tenant guarantees, start with row-scoped `org_id` patterns and composite foreign keys rather than prefix-per-tenant schemas. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]
**When to use:** Org/multi-tenant design after Sigra org support lands. [VERIFIED: .planning/PROJECT.md]
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html
# Use Repo default options / prepare_query plus composite foreign keys
# so all tenant-bound rows carry org_id and associations cannot cross tenants.
```

### Anti-Patterns to Avoid

- **Fake multi-processor parity:** Pay explicitly warns that complex apps should stick to one provider, and Accrue should not promise a generic cross-provider billing surface before demand exists. [CITED: https://github.com/pay-rails/pay]
- **Merchant-of-record confusion:** Paddle and Lemon Squeezy remove tax liability by becoming merchant of record, which changes billing ownership assumptions compared with Stripe. [CITED: https://developer.paddle.com/concepts/sell/supported-countries-locales] [CITED: https://docs.lemonsqueezy.com/help/payments/sales-tax-vat]
- **Prefix-per-tenant by default:** Ecto documents the migration/versioning cost clearly; do not choose schema prefixes as the first org-billing move unless isolation requirements justify it. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]
- **Custom accounting engine first:** Stripe already generates revenue reports and exports; recreating that inside Accrue would add a lot of surface area before user demand is proven. [CITED: https://docs.stripe.com/revenue-recognition/get-started] [CITED: https://docs.stripe.com/revenue-recognition/api]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tax calculation | Custom tax matrix/rules engine | Stripe Tax | Stripe already handles recurring billing tax calculation and documents the setup/migration edge cases. [CITED: https://docs.stripe.com/tax/set-up] |
| Revenue recognition | Custom accrual engine in Accrue | Stripe Revenue Recognition reports/API | Stripe already provides reports, CSV export, and API access; the API is still preview, so even then the right move is orchestration, not reinvention. [CITED: https://docs.stripe.com/revenue-recognition/get-started] [CITED: https://docs.stripe.com/revenue-recognition/api] |
| Warehouse exports | Bespoke CSV scheduler and storage fan-out | Stripe Sigma / Data Pipeline | Scheduled queries and pipeline delivery already exist in Stripe. [CITED: https://docs.stripe.com/sigma/scheduled-queries] [CITED: https://docs.stripe.com/stripe-data/export-customizations] |
| Tenant isolation guarantees | Ad hoc `where org_id = ...` discipline everywhere | Ecto repo callbacks + composite foreign keys | Ecto documents a stronger standard pattern that reduces accidental cross-tenant reads/writes. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] |
| Cross-provider abstraction | One core adapter promising equal feature coverage | Separate-package or host-owned adapter strategy | Official ecosystem precedent shows provider differences leak heavily. [CITED: https://github.com/pay-rails/pay] [CITED: https://laravel.com/docs/11.x/cashier-paddle] |

**Key insight:** The best Phase 16 output is not "which feature sounds biggest"; it is "which expansion compounds today's Stripe-first core without forcing Accrue to absorb external complexity too early." [VERIFIED: .planning/PROJECT.md] [CITED: https://github.com/pay-rails/pay]

## Common Pitfalls

### Pitfall 1: Enabling tax without customer location hygiene
**What goes wrong:** Automatic tax can disable itself or invoices can finalize without tax when customer location data is missing or invalid. [CITED: https://docs.stripe.com/tax/customer-locations]
**Why it happens:** Stripe Tax requires a valid customer location and recommends validating it when customer data changes. [CITED: https://docs.stripe.com/tax/customer-locations]
**How to avoid:** Treat customer location capture and validation as part of the tax milestone, not a docs afterthought. [CITED: https://docs.stripe.com/tax/customer-locations]
**Warning signs:** `automatic_tax.enabled` flips off, `disabled_reason` fields appear, or finance sees untaxed recurring invoices after rollout. [CITED: https://docs.stripe.com/tax/customer-locations]

### Pitfall 2: Assuming Stripe Tax retrofits existing recurring items automatically
**What goes wrong:** Teams enable Stripe Tax globally and expect existing subscriptions/invoices/payment links to start collecting tax. [CITED: https://docs.stripe.com/tax/set-up]
**Why it happens:** Stripe documents that existing recurring objects must be updated separately. [CITED: https://docs.stripe.com/tax/set-up]
**How to avoid:** Plan an explicit migration path for existing subscriptions and invoice templates. [CITED: https://docs.stripe.com/tax/set-up]
**Warning signs:** New signups collect tax while legacy subscribers do not. [CITED: https://docs.stripe.com/tax/set-up]

### Pitfall 3: Treating revenue exports like a product surface before the accounting model is agreed
**What goes wrong:** The library grows CSV endpoints or local GL concepts that do not match how finance actually books revenue. [CITED: https://docs.stripe.com/revenue-recognition/reports] [CITED: https://docs.stripe.com/revenue-recognition/api]
**Why it happens:** Revenue reporting needs product/price/tax/discount modeling discipline, and Stripe's API/report fields are still evolving in places like the Revenue Recognition API preview. [CITED: https://docs.stripe.com/revenue-recognition/reports] [CITED: https://docs.stripe.com/revenue-recognition/api]
**How to avoid:** Start with export/integration paths and buyer workflows, not a first-party accounting subsystem. [CITED: https://docs.stripe.com/revenue-recognition/get-started] [CITED: https://docs.stripe.com/stripe-data/export-customizations]
**Warning signs:** Debate centers on chart-of-accounts columns before there is a clear consumer or system of record. [CITED: https://docs.stripe.com/revenue-recognition/get-started]

### Pitfall 4: Choosing schema prefixes as the default org-tenancy move
**What goes wrong:** Tenant migrations and operational complexity explode early. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]
**Why it happens:** Prefix isolation feels safer, but Ecto explicitly documents the migration/versioning cost. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]
**How to avoid:** Prefer row-scoped foreign-key tenancy first if Accrue later hardens org support. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html]
**Warning signs:** Design discussions drift into per-tenant DDL and migration orchestration before user-facing org billing flows are even defined. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]

### Pitfall 5: Letting processor candidates rewrite the product's ownership model
**What goes wrong:** Accrue starts bending around MoR-specific assumptions or weakest-common-denominator features. [CITED: https://developer.paddle.com/concepts/sell/supported-countries-locales] [CITED: https://docs.lemonsqueezy.com/help/payments/sales-tax-vat]
**Why it happens:** Mature alternatives differ on who is merchant of record, how subscriptions are modeled, and what billing surfaces are native. [CITED: https://developer.paddle.com/concepts/sell/supported-countries-locales] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] [CITED: https://docs.lemonsqueezy.com/help/payments/sales-tax-vat]
**How to avoid:** Keep second-processor work outside the next milestone and prefer separate-package thinking if demand eventually exists. [CITED: https://laravel.com/docs/11.x/cashier-paddle] [CITED: https://laravel.com/docs/12.x/billing]
**Warning signs:** A recommendation starts with "all processors should..." instead of "this specific processor changes these assumptions." [CITED: https://github.com/pay-rails/pay]

## Code Examples

Verified patterns from official or repo sources:

### Current polymorphic billable boundary
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/billable.ex
defmodule MyApp.User do
  use Ecto.Schema
  use Accrue.Billable, billable_type: "User"
end
```
[VERIFIED: accrue/lib/accrue/billable.ex]

### Current custom processor boundary
```elixir
# Source: /Users/jon/projects/accrue/accrue/guides/custom_processors.md
defmodule MyApp.Billing.AcmePay do
  @behaviour Accrue.Processor

  def create_customer(params, opts), do: {:ok, %{id: "cus_custom_123", params: params, opts: opts}}
  def retrieve_customer(id, _opts), do: {:ok, %{id: id}}
  def update_customer(id, params, _opts), do: {:ok, %{id: id, params: params}}
end
```
[VERIFIED: accrue/guides/custom_processors.md]

### Ecto row-scoped tenancy pattern
```elixir
# Source: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html
@impl true
def default_options(_operation) do
  [org_id: get_org_id()]
end
```
[CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual tax rates per invoice/subscription | Stripe Tax automatic tax across subscriptions and invoices | Current Stripe docs, verified 2026-04-17 | Makes tax the clearest next expansion because it rides the existing Stripe Billing model. [CITED: https://docs.stripe.com/tax/set-up] |
| Dashboard-only finance exports | Dashboard CSV plus Sigma, Data Pipeline, and Revenue Recognition API public preview | Current Stripe docs, verified 2026-04-17 | Lowers pressure for Accrue to build its own export engine first. [CITED: https://docs.stripe.com/revenue-recognition/api] [CITED: https://docs.stripe.com/stripe-data/export-customizations] [CITED: https://docs.stripe.com/sigma/scheduled-queries] |
| Prefix tenancy as the default mental model | Ecto documents foreign-key tenancy as the cheaper baseline and prefixes as costlier to operate | Ecto `3.13.5` docs | Supports org-billing backlog work that starts with row scoping and composite FKs. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html] |
| Single shared multi-processor story | Ecosystem splits or warns: Pay cautions against provider mixing; Laravel ships separate Stripe and Paddle packages | Current docs/repo pages, verified 2026-04-17 | Supports keeping official second-processor work out of the next milestone. [CITED: https://github.com/pay-rails/pay] [CITED: https://laravel.com/docs/12.x/billing] [CITED: https://laravel.com/docs/11.x/cashier-paddle] |

**Deprecated/outdated:**
- "Just turn on tax and everything updates" is outdated; Stripe documents separate updates for existing recurring objects. [CITED: https://docs.stripe.com/tax/set-up]
- "Schema prefixes are the obvious first multitenancy step" is outdated for most early SaaS org models; Ecto documents the operational cost directly. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]

## Ranked Recommendation

| Rank | Candidate | Outcome | User Value | Architecture Impact | Risk | Prerequisites |
|------|-----------|---------|------------|---------------------|------|---------------|
| 1 | Stripe Tax support | **Next milestone** | High: tax compliance blocks real-world rollout in more markets and reduces manual finance work. [CITED: https://docs.stripe.com/tax/set-up] | Moderate: add customer location capture, tax enablement flows, and migration handling for existing subscriptions without changing processor strategy. [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/tax/customer-locations] | Moderate: rollout mistakes can silently disable tax or leave legacy subscriptions untaxed. [CITED: https://docs.stripe.com/tax/customer-locations] | Customer address strategy, tax settings defaults, existing recurring-item migration plan, product/price tax-code policy. [CITED: https://docs.stripe.com/tax/set-up] |
| 2 | Organization / multi-tenant billing | **Backlog** | High for B2B SaaS teams that bill organizations instead of individual users. [VERIFIED: .planning/REQUIREMENTS.md] | High: likely needs host-facing org billing UX and stronger tenant scoping rules, but existing polymorphic ownership reduces schema churn risk. [VERIFIED: repo files] [VERIFIED: .planning/PROJECT.md] | High: access-control and data-isolation mistakes are costly. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] | Sigra org support or equivalent host auth/org model, explicit owner semantics (`User` vs `Org`), tenancy verification strategy. [VERIFIED: .planning/PROJECT.md] |
| 3 | Revenue recognition / exports | **Backlog** | Medium to high for finance-heavy adopters; lower for first-time Phoenix teams trying to launch. [ASSUMED] [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://docs.stripe.com/revenue-recognition/get-started] | Moderate: export surfaces and documentation can stay thin if Stripe remains source of truth. [CITED: https://docs.stripe.com/revenue-recognition/api] [CITED: https://docs.stripe.com/stripe-data/export-customizations] | Moderate: accounting expectations vary and API/reporting surfaces are still evolving. [CITED: https://docs.stripe.com/revenue-recognition/api] | Decide target consumers first: CSV download, warehouse sync, webhook, or accounting-system handoff. [CITED: https://docs.stripe.com/stripe-data/export-customizations] |
| 4 | Official second processor adapter | **Planted seed** | Variable: valuable only when there is proven demand outside Stripe-first teams. [VERIFIED: .planning/REQUIREMENTS.md] | Very high: changes expectations around parity, docs, testing, and long-term maintenance. [CITED: https://github.com/pay-rails/pay] [CITED: https://laravel.com/docs/11.x/cashier-paddle] | High: processor models differ materially, especially MoR vs PSP billing ownership. [CITED: https://developer.paddle.com/concepts/sell/supported-countries-locales] [CITED: https://docs.lemonsqueezy.com/help/payments/sales-tax-vat] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] | Demonstrated user demand, separate-package strategy decision, processor-specific contract, and migration story. [CITED: https://laravel.com/docs/11.x/cashier-paddle] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Revenue/export is lower immediate user value than tax and org billing for the next milestone. [ASSUMED] | Ranked Recommendation | Milestone ordering could overfit the current maintainer view instead of actual adopter demand. |

## Open Questions (RESOLVED)

1. **What finance workflow should Accrue optimize first: manual CSV export, scheduled report delivery, warehouse sync, or accounting-system handoff?**
   - What we know: Stripe already supports all four shapes to different degrees. [CITED: https://docs.stripe.com/revenue-recognition/api] [CITED: https://docs.stripe.com/stripe-data/export-customizations] [CITED: https://docs.stripe.com/sigma/scheduled-queries]
   - Outcome: Optimize first for host-authorized scheduled report delivery backed by Stripe-native reporting surfaces, with manual CSV remaining an operator fallback and warehouse or accounting handoff treated as downstream consumers rather than first-class Accrue product surface.
   - Why this resolves the question: It matches the backlog recommendation to start with a thin handoff layer instead of inventing a local accounting engine or broad export subsystem.

2. **When Sigra ships organizations, should Accrue support both user-billed and org-billed ownership in the same host app?**
   - What we know: The current model can represent either through `owner_type`/`owner_id`. [VERIFIED: accrue/lib/accrue/billing/customer.ex] [VERIFIED: accrue/lib/accrue/billable.ex]
   - Outcome: Yes at the model level, but not as a first-class mixed-ownership UX requirement for the first org-billing milestone. The planning baseline is that Accrue keeps the polymorphic ownership model, while the initial org milestone can scope its public host flows to one active billing owner path at a time.
   - Why this resolves the question: It preserves the existing schema flexibility without forcing Phase 16 to recommend broader org UX or tenancy scope than the current host-owned boundary can safely support.

3. **If second-processor demand appears, should official support live in core or a separate package?**
   - What we know: Ecosystem precedent favors separation and provider-specific packages. [CITED: https://laravel.com/docs/12.x/billing] [CITED: https://laravel.com/docs/11.x/cashier-paddle]
   - Outcome: Official support should live outside core, either as a separate package or a host-owned adapter, while `accrue` remains Stripe-first and keeps only the documented custom-processor extension point.
   - Why this resolves the question: It removes ambiguity before any future adapter work and aligns the planted-seed recommendation with both repo history and external precedent.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit / Mix task contracts in repo [VERIFIED: repo files] |
| Config file | none; Mix aliases are the operative contract today. [VERIFIED: accrue/mix.exs] [VERIFIED: examples/accrue_host/mix.exs] |
| Quick run command | `cd accrue && mix test` [VERIFIED: accrue/mix.exs] |
| Full suite command | `cd examples/accrue_host && mix verify.full` [VERIFIED: examples/accrue_host/mix.exs] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DISC-01 | Tax recommendation is captured with value, impact, risk, and prerequisites. | docs contract | `rg -n "Stripe Tax|automatic tax|customer location" .planning/phases/16-expansion-discovery/16-RESEARCH.md` | ❌ Wave 0 |
| DISC-02 | Revenue/export recommendation names standard Stripe-native paths. | docs contract | `rg -n "Revenue Recognition|Sigma|Data Pipeline|CSV" .planning/phases/16-expansion-discovery/16-RESEARCH.md` | ❌ Wave 0 |
| DISC-03 | Processor recommendation preserves Stripe-first boundary. | docs contract | `rg -n "planted seed|single provider|separate package|custom processor" .planning/phases/16-expansion-discovery/16-RESEARCH.md` | ❌ Wave 0 |
| DISC-04 | Org/multi-tenant recommendation reflects Sigra and host-owned constraints. | docs contract | `rg -n "Sigra|owner_type|owner_id|foreign keys|query prefixes" .planning/phases/16-expansion-discovery/16-RESEARCH.md` | ❌ Wave 0 |
| DISC-05 | All candidates are ranked into next milestone/backlog/seed. | docs contract | `rg -n "Next milestone|Backlog|Planted seed|Ranked Recommendation" .planning/phases/16-expansion-discovery/16-RESEARCH.md` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `rg -n "DISC-0[1-5]" .planning/phases/16-expansion-discovery/16-RESEARCH.md`
- **Per wave merge:** `cd examples/accrue_host && mix verify.full`
- **Phase gate:** Research artifact present and requirement/ranking grep checks pass before `/gsd-plan-phase`

### Wave 0 Gaps
- [ ] Add a narrow docs-contract test or script that asserts the Phase 16 artifact includes all four candidate areas plus ranking outcome.
- [ ] Decide whether that contract should live as ExUnit docs test or a simple `rg`-backed script in `scripts/ci/`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host auth remains the source of identity; future org billing should stay behind host/Sigra auth boundaries. [VERIFIED: accrue/guides/sigra_integration.md] |
| V3 Session Management | yes | Keep tenant context host-owned; Accrue should consume actor/owner context rather than invent sessions. [VERIFIED: accrue/guides/sigra_integration.md] |
| V4 Access Control | yes | Multi-tenant billing must enforce tenant scoping explicitly; Ecto row-scoping guidance is the standard pattern. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] |
| V5 Input Validation | yes | Tax/location and export parameters should validate through existing config and facade boundaries, not ad hoc maps. [VERIFIED: CLAUDE.md] [CITED: https://docs.stripe.com/tax/customer-locations] |
| V6 Cryptography | no new crypto | Keep existing webhook verification and Stripe secret handling; do not add custom crypto for export or processor work. [VERIFIED: CLAUDE.md] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant data access in org billing | Information Disclosure / Elevation of Privilege | Row-scoped tenant defaults plus composite foreign keys if stronger tenant modeling is added. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html] |
| Untaxed recurring invoices after partial rollout | Tampering / Repudiation | Explicit migration/update plan for existing recurring items and disabled-reason monitoring. [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/tax/customer-locations] |
| Exporting finance data to the wrong audience | Information Disclosure | Keep exports host-authorized and favor existing Stripe team/reporting controls before in-app download features. [CITED: https://docs.stripe.com/sigma/scheduled-queries] [CITED: https://docs.stripe.com/stripe-data/export-customizations] |
| Processor downgrade into weakest-common-denominator semantics | Tampering | Keep second-processor work out of core until provider-specific boundaries are explicit. [CITED: https://github.com/pay-rails/pay] [CITED: https://laravel.com/docs/11.x/cashier-paddle] |

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/accrue/accrue/lib/accrue/billable.ex` - current billable ownership model. [VERIFIED: repo files]
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing/customer.ex` - current polymorphic customer model. [VERIFIED: repo files]
- `/Users/jon/projects/accrue/accrue/lib/accrue/processor.ex` - current processor behaviour surface. [VERIFIED: repo files]
- `/Users/jon/projects/accrue/accrue/guides/custom_processors.md` - documented custom adapter boundary. [VERIFIED: repo files]
- `/Users/jon/projects/accrue/.planning/PROJECT.md` - project-level prior-art and milestone constraints. [VERIFIED: repo files]
- `https://docs.stripe.com/tax/set-up` - tax setup, recurring-item migration caveat. [CITED: https://docs.stripe.com/tax/set-up]
- `https://docs.stripe.com/tax/customer-locations` - customer location requirements and automatic-tax failure modes. [CITED: https://docs.stripe.com/tax/customer-locations]
- `https://docs.stripe.com/revenue-recognition/get-started` - baseline Revenue Recognition capabilities. [CITED: https://docs.stripe.com/revenue-recognition/get-started]
- `https://docs.stripe.com/revenue-recognition/api` - programmatic export path and preview status. [CITED: https://docs.stripe.com/revenue-recognition/api]
- `https://docs.stripe.com/stripe-data/export-customizations` - Data Pipeline and dashboard report delivery. [CITED: https://docs.stripe.com/stripe-data/export-customizations]
- `https://docs.stripe.com/sigma/scheduled-queries` - scheduled query export path. [CITED: https://docs.stripe.com/sigma/scheduled-queries]
- `https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html` - official Ecto row-scoped multitenancy guidance. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html]
- `https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html` - official Ecto prefix-based multitenancy tradeoffs. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]

### Secondary (MEDIUM confidence)
- `https://github.com/pay-rails/pay` - mature multi-processor precedent and warning about sticking to one provider for complex billing. [CITED: https://github.com/pay-rails/pay]
- `https://laravel.com/docs/12.x/billing` - official Cashier Stripe package docs. [CITED: https://laravel.com/docs/12.x/billing]
- `https://laravel.com/docs/11.x/cashier-paddle` - official Cashier Paddle package docs, demonstrating separate-package strategy. [CITED: https://laravel.com/docs/11.x/cashier-paddle]
- `https://developer.paddle.com/concepts/sell/supported-countries-locales` - Paddle merchant-of-record and tax stance. [CITED: https://developer.paddle.com/concepts/sell/supported-countries-locales]
- `https://docs.lemonsqueezy.com/help/payments/sales-tax-vat` - Lemon Squeezy merchant-of-record tax stance. [CITED: https://docs.lemonsqueezy.com/help/payments/sales-tax-vat]
- `https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/` - Braintree recurring billing model. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the recommended stack is mostly the existing repo plus current official Stripe/Ecto documentation. [VERIFIED: repo files] [CITED: https://docs.stripe.com/tax/set-up]
- Architecture: HIGH - Accrue's current boundaries are clear in repo, and the ranking follows those boundaries directly. [VERIFIED: repo files]
- Pitfalls: HIGH - tax and multitenancy pitfalls are documented in current official Stripe and Ecto guides. [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 for repo constraints; re-check Stripe docs within 7 days if Phase 16 planning turns into implementation planning for tax or reporting APIs. [CITED: https://docs.stripe.com/revenue-recognition/api]
