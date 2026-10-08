# Phase 237: Admin Invoices, Payments & Recovery - Research

**Researched:** 2026-10-08  
**Domain:** Phoenix LiveView billing operations, exact money display, owner-scoped recovery analytics  
**Confidence:** HIGH for current code contracts; MEDIUM for how far to expand UI/browser proof

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Auto mode selected all identified discussion areas. The user directed us to follow the recommended defaults. The current roadmap, prior Admin decisions, and source contracts already settle the phase boundary and safety posture.

#### Invoice facts and amount precision

- **D-01:** Preserve the stored invoice lifecycle state. Show overdue as a collection fact only when the invoice is open and an applicable known due date has passed under the established date convention. Missing due dates stay explicitly unavailable; draft, open, paid, void, and uncollectible remain distinct.
- **D-02:** Use the canonical currency-aware minor-unit formatter for invoice, payment, refund, and recovery amounts. Preserve real zero amounts and zero-/three-decimal currency precision. A missing amount or unsupported/missing currency remains unavailable; never substitute zero or the configured/default USD currency.

#### Payment actions and result evidence

- **D-03:** Reuse the existing staged review-and-confirm interaction for supported invoice payment/finalization and refund actions. Before confirmation, name the exact scoped record and action, show the exact known amount and currency, and state the actual consequence. Revalidate the same owner-scoped target, current eligibility, authorization, and action-relevant facts immediately before dispatch, including after step-up. Do not expose unsupported actions or infer a charge/refund amount.
- **D-04:** Describe accepted, requires-action, failed, and completed outcomes separately when the existing result contract supports them. Tie the visible outcome to the scoped resulting invoice/payment/refund or available history. If the result is ambiguous, say it is not confirmed; do not claim failure or success, replay automatically, or introduce a new reconciliation system.

#### Recovery scope and history

- **D-05:** Keep the selected recovery time window, current owner scope, and each currency attached to recovery measures. Preserve validated owner, window, and return context across links into existing records. Keep campaign and failure events as historical evidence; current invoice and subscription status come from their own current observations and must not be overwritten by an older recovery event. Do not combine currencies or fabricate a currency for empty data.

#### Verification and bounded implementation

- **D-06:** Carry forward the project shift-left default from PROJECT.md, STATE.md, and prior phase decisions: every testable acceptance claim gets deterministic executable evidence at its cheapest credible seam. Use unit/contract tests for pure money/state rules, scoped LiveView tests for actions and evidence, and representative served-browser proof for real navigation, keyboard/focus, responsive layout, theme, and pending/denied/error states. Keep stable recurring checks in the existing merge-blocking CI lanes when they protect future behavior. Target zero confirmation-only human UAT; hand off only genuine product decisions, unavailable external/live-provider evidence, irreversible external actions, or irreducible subjective judgment, recording the boundary and reason. 
- **D-07:** Keep the slice finite and follow the established Admin visual and interaction contract: semantic controls, visible focus, announced outcomes, readable 320 CSS-pixel reflow, theme coverage, current served assets, and current-source screenshots where visual claims require them. Reuse existing components and gates; no broad CI redesign or all-routes-by-all-states matrix.

### the agent's Discretion

- The planner and implementer may choose the smallest local component/query changes and precise copy that meet these decisions, after confirming current source behavior and provider contracts.
- Select representative evidence by distinct behavior and recurring maintenance value; avoid duplicating an invariant in more expensive layers when a lower layer proves it credibly.
- Use current Admin patterns and design tokens; only extract a helper when actual repetition or handler complexity warrants it.

### Deferred Ideas (OUT OF SCOPE)

- New providers, billing operations, public APIs, automatic payment retries, durable result reconciliation, and a generalized recovery command center are outside this phase.
- Events/webhook deep investigation, retry/replay work, coupons, promotion codes, and Connect belong to Phase 238.
- Portal customer invoice/payment self-service and integrated cross-surface milestone handoff remain owned by Phases 236 and 239.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADM-02 | Operators can distinguish draft, open, and overdue invoices and see missing due dates honestly; amounts preserve currency and minor-unit precision, including zero- and three-decimal currencies. | Invoice queries already select stored status, due_date, due/paid/remaining minor amounts and currency; derive overdue at presentation only for eligible open invoices. Reuse MoneyFormatter/Render and close USD fallback paths. |
| ADM-05 | Operators can review invoice payments/finalization and refunds with the exact amount, currency, and consequence, and distinguish accepted, requires-action, failed, and completed results. | Existing action drawer, Billing APIs, IntentResult and Refund contracts define reusable seams. Detail LiveViews need dispatch-time scoped reload/revalidation and evidence-specific outcome rendering. |
| ADM-06 | Operators can review recovery with its time window, owner, and currency intact, while historical failures remain distinct from current billing state. | RecoveryLive is URL-window-backed and Queries.Dunning applies owner/time filtering, currency grouping, campaign history, and current at-risk subscription query; fix missing-currency/default and context propagation at links. |
</phase_requirements>

## Summary

This phase is a bounded refinement of existing `accrue_admin` LiveViews and query contracts, with no new packages or billing/provider capability. Invoice and payment reads join each record to its Customer, and organization scope filters through that Customer; detail lookups use the same owner scope and return `:not_found` outside it. Preserve this owner boundary on every re-read, result refresh, event/history lookup, and related navigation. [VERIFIED: accrue_admin/lib/accrue_admin/queries/invoices.ex:24-26,73-85,162-170; accrue_admin/lib/accrue_admin/queries/charges.ex:24-26,67-80,143-152]

The main implementation gap is not missing infrastructure: the current pages already contain review drawers, step-up, supported billing API calls, recovery windows, and focused LiveView coverage. Planning should target precise gaps: current invoice list state omits derived overdue/missing-due semantics; several local `normalize_currency/1` functions coerce unknown/missing currency to USD; both core/global and Admin organization recovery aggregates substitute USD for absent event currency, while the empty dashboard renders configured default currency; and invoice/refund dispatch uses the LiveView's previously loaded struct without a final owner-scoped reload/eligibility check. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoices_live.ex:246-283; accrue_admin/lib/accrue_admin/live/invoice_live.ex:1010-1027,1307-1321; accrue_admin/lib/accrue_admin/live/charge_live.ex:586-604,909-921; accrue_admin/lib/accrue_admin/queries/dunning.ex:65-73; accrue/lib/accrue/analytics/dunning.ex:88-90; accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:38-50]

**Primary recommendation:** Plan a few focused vertical slices around canonical money/state presentation, owner-scoped review-to-dispatch action correctness and result evidence, then recovery currency/window/context integrity. Add pure tests for derived invoice state and money, scoped LiveView tests for denial/races/results, and one representative host served-browser journey integrated with the existing host CI verification lane. Do not add a billing action, provider, replay/reconciliation path, broad CI framework, or Portal behavior. [CITED: `.planning/phases/237-admin-invoices-payments-recovery/237-CONTEXT.md`; `.github/workflows/ci.yml`; `scripts/ci/accrue_host_uat.sh`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Invoice status, due-date and money display | Browser / Client | Database / Storage | Persisted invoice facts come from the scoped query; derived overdue is a presentation fact and must not rewrite lifecycle status. |
| Invoice payment/finalization and refunds | API / Backend | Browser / Client | `Accrue.Billing` owns provider interaction and result contracts; LiveViews stage operator intent and render scoped evidence. |
| Recovery window and owner-scoped analytics | Database / Storage | Browser / Client | Queries aggregate owner-filtered historical events and current at-risk rows; URL-backed LiveView controls selected window and navigation. |
| Served Admin shell, asset/theme/layout proof | Browser / Client | Frontend Server (SSR) | Host serves configured Admin mount and assets; Playwright observes actual rendered DOM and keyboard/layout behavior. |

## Standard Stack

### Core

| Library / subsystem | Version | Purpose | Why Standard |
|--------------------|---------|---------|--------------|
| `accrue_admin` LiveView | Repo-locked | Admin invoice, charge/refund and recovery interfaces | Existing owning package and routes; phase boundary explicitly preserves existing Admin/API surfaces. |
| `Accrue.Invoices.Render.format_money/3` | In-repo | Locale-aware formatting from integer minor units and currency atom | Canonical renderer already used by the shared Admin `MoneyFormatter`; do not add a competing formatter. |
| `Accrue.Billing.InvoiceActions` / `RefundActions` | In-repo | Supported invoice/finalization/payment and refund mutations | They are the authoritative Billing API result shapes and provider boundary. |
| Existing ExUnit LiveView tests | Repo-locked | Scoped presentation and action behavior evidence | Adjacent route test suites already exercise owner denials, drawers, step-up, result flashes and recovery windows. |
| Existing example-host Playwright + `mix verify.full` | Repo-locked | Served-browser evidence and recurring host CI verification | Host CI already runs an integrated seeded browser/a11y/responsive lane; reuse the maintained contract. |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `AccrueAdmin.Components.MoneyFormatter` | Shared formatting and unavailable marker | For any displayed invoice/payment/refund money, including a true zero; only call with a known amount and supported currency. |
| `AccrueAdmin.ScopedPath` | Mount-aware links and allowlisted returns rebuilt under active owner scope | Related links into invoice/payment/subscription details and validated recovery window returns. |
| `AccrueAdmin.StepUp` | Existing freshness/challenge boundary | Existing actions that require it; resume action only after reloading/rechecking the exact target. |
| `AccrueAdmin.Queries.{Invoices,Charges,Dunning}` | Owner-scoped data reads | Use for list/detail/action target reloads and analytics; never authorize from URL scope parameters. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Canonical `MoneyFormatter` | Per-view `normalize_currency` + `Render.format_money` helpers | Duplicated helpers currently fall back to USD for unknown values; shared component already handles unavailable data. |
| Current scoped query/API contracts | New reconciliation service or provider integration | Explicitly outside phase boundary; results must be based on current contract/local resulting rows and available history. |
| Host's `verify.full`/Playwright lane | New generalized browser matrix or separate CI job architecture | Adds maintenance and overlapping coverage; add only a small spec/targeted invocation in existing lane if recurring value is shown. |

**Installation:** None. This phase is constrained to existing package dependencies and tools. [CITED: `.planning/phases/237-admin-invoices-payments-recovery/237-CONTEXT.md`]

## Package Legitimacy Audit

No external packages are recommended or required; package legitimacy checks are not applicable.

## Architecture Patterns

### Recommended project structure

Keep changes within the existing modules: `accrue_admin/lib/accrue_admin/queries/{invoices,charges,dunning}.ex`, the corresponding `live/` modules, existing shared components/copy, and their adjacent `accrue_admin/test/accrue_admin/live/` suites. If served proof needs a new assertion, add it next to `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js` or a focused sibling spec and let the existing host verify path discover/run it. No new service layer is indicated. [CITED: `.planning/phases/237-admin-invoices-payments-recovery/237-CONTEXT.md` canonical refs; `scripts/ci/accrue_host_uat.sh`]

### Pattern 1: Separate stored lifecycle from derived overdue fact

**What:** Render the stored invoice lifecycle status as-is, and calculate a separate overdue collection signal only when the status is open and a known applicable due date is before the established current-date boundary. Preserve missing due date as unavailable; do not translate absent due date into overdue or alter the stored status. The existing list query already selects `status` and `due_date`, while current `status_summary/1` only shows the stored status and presence of finalized/due markers. [VERIFIED: accrue_admin/lib/accrue_admin/queries/invoices.ex:44-53; accrue_admin/lib/accrue_admin/live/invoices_live.ex:246-250]

**When to use:** Invoice list and detail summary surfaces. Pin time at the pure-function seam for deterministic boundary tests; follow the project's established date convention (confirm it from current date helper/source while planning implementation).

**Example:**

```elixir
# Schematic only; choose the existing project clock/date convention in implementation.
case {invoice.status, invoice.due_date} do
  {:open, %DateTime{} = due_date} -> due_date < now
  _ -> false
end
```

The literal status `:open` above is a schematic value, not newly verified schema syntax; inspect the schema and status representation before copying it. [ASSUMED]

### Pattern 2: Review, revalidate, then dispatch exact scoped target

**What:** Keep staged action state minimal (action, exact record identity, exact amount/currency/consequence and relevant source evidence). At confirm time, including after a step-up continuation, reload via `Invoices.detail(id, current_owner_scope)` or `Charges.detail(id, current_owner_scope)`, recalculate eligibility and action-relevant amount/currency facts, recheck authorization, and dispatch only if it is still the reviewed target. Current `execute_action/2` passes `socket.assigns.invoice` directly to Billing; current `execute_refund/2` passes `socket.assigns.charge` directly. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex:1010-1014; accrue_admin/lib/accrue_admin/live/charge_live.ex:586-591]

**Why:** The action remains locally idempotency-seeded, but an open drawer or step-up delay can make the row/status/balance/owner facts stale. Existing scoped `detail/2` lookups are the safe reload seam. [VERIFIED: accrue_admin/lib/accrue_admin/queries/invoices.ex:73-85; accrue_admin/lib/accrue_admin/queries/charges.ex:67-80; accrue/lib/accrue/billing/invoice_actions.ex:63-70; accrue/lib/accrue/billing/refund_actions.ex:45-72]

### Pattern 3: Render outcomes from contract plus persisted evidence

Invoice pay is an intent-result operation: documented returns include `{:ok, %Invoice{}}`, `{:ok, :requires_action, pi}`, and `{:error, term()}`; finalization returns `{:ok, %Invoice{}} | {:error, term()}`. Refund returns `{:ok, %Refund{}} | {:error, term()}` and fee settlement may remain pending on the Refund row. [VERIFIED: accrue/lib/accrue/billing/invoice_actions.ex:43-70; accrue/lib/accrue/billing/refund_actions.ex:31-45]

Treat a successful return plus scoped refreshed invoice/refund row as completed local evidence. Render `requires_action` as a separate customer/provider action requirement. Only state definitive failure when the returned contract provides definitive rejection; an unexpected/ambiguous dispatch result needs “not confirmed” treatment, with no implicit retry. Admin audit event recording is local provenance and by itself cannot prove processor completion. [CITED: `.planning/phases/237-admin-invoices-payments-recovery/237-CONTEXT.md` D-04; VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex:1016-1027; accrue_admin/lib/accrue_admin/live/charge_live.ex:593-604]

### Pattern 4: Recovery is currency-bucketed historical analytics plus current at-risk reads

`RecoveryLive.handle_params/3` parses the URL window, builds bounds, then asks Dunning for currency totals, funnel and at-risk records under the active owner scope. Event totals group by type and event-data currency; at-risk subscription rows are queried from current Subscription/Customer/Oban state and campaign history. Keep those sources distinct: a historical `invoice.payment_failed`/campaign event is evidence of what happened, not current invoice/subscription state. [VERIFIED: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:26-34,169-188; accrue_admin/lib/accrue_admin/queries/dunning.ex:55-73,172-185,200-222]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Currency and minor-unit display | Local formatting, amount-to-decimal conversion, or currency fallback logic | `MoneyFormatter.money_formatter` → `Accrue.Invoices.Render.format_money/3` | It already handles locale and precise currency presentation and emits `--` for missing/unsupported money. |
| Owner authorization | Trust query string, record ID, hidden input, or stale assign as permission | Fresh host authorization plus owner-scoped detail query | Query scope is an isolation boundary, not display-only metadata. |
| Provider capability | Infer an action from record shape/provider label | Existing Billing action contract and processor support matrix | No new capabilities/providers allowed; only expose existing supported action. |
| Retry/exactly-once/reconciliation | Custom retry or reconciliation framework | Existing per-operation idempotency semantics and available local rows/events | Ambiguity must remain visible; user explicitly deferred durable reconciliation and automatic retry. |
| Recovery event replay/state projection | Promote a historical failure event into current invoice/subscription state | Current scoped invoice/subscription reads alongside labeled history | Old recovery events cannot overwrite current observations. |

**Key insight:** Most implementation risk sits at the seams between review time and dispatch, and between a local result/audit row and what the processor actually confirmed. Preserve the existing APIs and make those seams explicit in the UI and tests.

## Common Pitfalls

### Pitfall 1: Conflating overdue with invoice lifecycle status

**What goes wrong:** A view labels an invoice “overdue” as though it replaced `open`, or labels an open invoice overdue when its due date is absent.  
**Why it happens:** The list currently summarizes only stored status/finalized/due markers and has no overdue rule.  
**How to avoid:** Render lifecycle and collection state separately; test draft/open/paid/void/uncollectible, missing due date and due-date boundary.  
**Warning signs:** Status filter values or persisted invoice `status` are changed to introduce `overdue`. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoices_live.ex:246-250]

### Pitfall 2: Silent currency substitution and fake zero

**What goes wrong:** Unknown/missing currency is displayed as USD; absent fee measures become a rendered zero; absent recovery data appears as configured currency total.  
**Why it happens:** Invoice/payment local normalizers return `:usd` for unknown input, recovery query substitutes `"usd"`, refund fee fields use `|| 0`, and empty recovery state synthesizes default currency.  
**How to avoid:** Route all money through `MoneyFormatter`, distinguish integer zero from nil, preserve missing/unsupported currency as unavailable, and render no synthetic per-currency totals for empty data.  
**Warning signs:** `|| :usd`, `|| "usd"`, or `|| 0` in money presentation. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoices_live.ex:261-283; accrue_admin/lib/accrue_admin/live/invoice_live.ex:1299-1321; accrue_admin/lib/accrue_admin/live/charge_live.ex:272-277,856-921; accrue_admin/lib/accrue_admin/queries/dunning.ex:65-66; accrue/lib/accrue/analytics/dunning.ex:88-90; accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:38-50]

### Pitfall 3: Stale authorization/eligibility after review or step-up

**What goes wrong:** Action is submitted against an outdated struct or an owner/status/balance that changed while the drawer or step-up was open.  
**Why it happens:** Current dispatch helper calls Billing with the assign rather than a newly loaded scoped row.  
**How to avoid:** Re-read by ID and active owner scope, compare target/action facts with reviewed intent, re-authorize, re-check current eligibility after any challenge, then dispatch once. If anything changed, cancel review and show the new state.  
**Warning signs:** `Billing.*(socket.assigns.invoice, ...)` or refund call uses `socket.assigns.charge` directly in the dispatch function. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex:1010-1014; accrue_admin/lib/accrue_admin/live/charge_live.ex:586-591]

### Pitfall 4: Overclaiming outcomes

**What goes wrong:** A generic `{:error, _}` is always presented as processor failure, or a local `admin.*.completed` audit row is treated as proof of remote payment/refund completion.  
**Why it happens:** Current pages group errors into generic copy and record admin audit on `{:ok, row}`. Billing's payment API separately exposes `requires_action`, while refund success yields a local Refund record.  
**How to avoid:** Match each result branch explicitly, refresh only through owner-scoped reads, state exactly what row/event confirms, and keep ambiguous returns in an unconfirmed state without replay.  
**Warning signs:** “Refund completed” inferred from mere action submission or result logging; automatic retry after timeout. [VERIFIED: accrue_admin/lib/accrue_admin/live/invoice_live.ex:1016-1027; accrue_admin/lib/accrue_admin/live/charge_live.ex:593-604; accrue/lib/accrue/billing/invoice_actions.ex:63-70]

### Pitfall 5: Combining currencies or carrying unvalidated recovery context

**What goes wrong:** Summing USD and JPY measures or using a URL owner/window as authority; return links lose selected window or target customer context.  
**Why it happens:** Dashboard summary, filters and related detail URLs use separate URL and owner-scope mechanisms.  
**How to avoid:** Keep one KPI pair per observed currency, attach validated current owner and window to links, and rebuild paths via ScopedPath under server-resolved scope. For empty data show an empty/unavailable measure without fabricating currency.  
**Warning signs:** Global sum without currency grouping or pass-through of raw `org`/`return_to` input as authorization. [VERIFIED: accrue_admin/lib/accrue_admin/queries/dunning.ex:172-185,200-222; accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:26-45; accrue_admin/lib/accrue_admin/scoped_path.ex:6-10,26-63]

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json` (`workflow.nyquist_validation: true`). No tests were run during research, per task instruction. [VERIFIED: `.planning/config.json`]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix LiveView tests in `accrue_admin` |
| Config file | `accrue_admin/test/test_helper.exs` (confirm package setup if planning new fixtures) |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs` |
| Full suite command | `cd accrue_admin && mix test --warnings-as-errors` |

Commands are recommendations only; they were not executed. The tracked CI job invokes `cd accrue_admin && mix test --warnings-as-errors`. [CITED: `.github/workflows/ci.yml`]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Existing evidence |
|--------|----------|-----------|-------------------|-------------------|
| ADM-02 | Stored status distinct from derived overdue; missing due date honest; known 0/2/3 fractional currencies preserve exact precision | Pure unit/component + scoped LiveView | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs` | Existing invoice suites cover list/detail/status/action/scoping but current fixtures seen in source are mostly USD; add explicit date/money boundary cases. |
| ADM-05 | Exact staged payment/finalization/refund consequence; target remains scoped/eligible after review and step-up; accepted/requires-action/failed/completed/ambiguous distinctions | LiveView + action contract tests | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs` | Existing tests cover drawer, step-up, authorization and refund audit linkage; add refreshed-target/revoked-eligibility and precise result-evidence variants. |
| ADM-06 | Window, owner, currency and return context stay intact; historical failures separate from current state | Query/LiveView integration + served navigation | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | Existing tests cover 7/30/90d, invalid-window default, KPI requery, scope exclusion and JPY; extend nil/unsupported currency, no-data behavior, and detail-link round-trip assertions. |

### Sampling Rate and Wave 0

- **Per task commit:** the narrow relevant ExUnit file(s) above.
- **Per wave merge:** `cd accrue_admin && mix test --warnings-as-errors` plus host verification if browser-relevant contracts change.
- **Phase gate:** full Admin tests green; served browser contract included in the existing merge-blocking host CI lane where stable recurring value exists.
- **Wave 0 gaps:** No new framework install. Add tests adjacent to current suites for overdue/missing date and known 0-/3-decimal currency; dispatch-time owner/status/balance changes and ambiguous outcome; recovery missing currency/empty data and context round-trip.

### Served-browser evidence seam

`examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js` demonstrates seeded served Admin route navigation, keyboard focus, DOM integrity, contextual return and captured screenshot provenance. CI's `host-integration` job delegates to `mix verify.full` via `scripts/ci/accrue_host_uat.sh`; its existing Playwright discovery is the low-friction recurring proof seam. Add only one representative invoice/payment/recovery journey or focused assertions there if it closes an actual gap, covering live owner scope, keyboard/visible focus, one responsive viewport at 320 CSS px, both themes as needed, and pending/denied/error outcome semantics. Do not mutate Phase 234 immutable evidence. [CITED: `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js`; `scripts/ci/accrue_host_uat.sh`; `.github/workflows/ci.yml`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | Continue using host's authenticated Admin session; phase must not add authentication. |
| V3 Session Management | Yes | Preserve LiveView/session owner scope and step-up freshness semantics. |
| V4 Access Control | Yes | Re-resolve authorization and owner-scoped target at dispatch and result refresh; URL values are not authority. |
| V5 Input Validation | Yes | Validate refund minor-unit input against exact current charge balance and currency; reject stale/ineligible action. |
| V6 Cryptography | No new crypto | Reuse existing signed/session contracts; do not introduce custom signing or token schemes. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant record ID or forged `org`/return query | Elevation of privilege | Owner-scoped query for detail and dispatch; validate return path/customer against loaded scoped row. |
| Stale review accepted after owner membership/action eligibility changes | Elevation of privilege / Tampering | Re-authorize and reload the exact row immediately before action, including after step-up. |
| Refund amount/currency changed or inferred during stale interaction | Tampering | Bind review to integer minor amount and current charge currency; revalidate max and target before Billing API call. |
| Error/timeout shown as success/failure or action retried | Repudiation / Tampering | Separate known result branches from ambiguity; show only local/provider evidence actually returned; no automatic retry. |

## Environment Availability

The feature changes require no new runtime or package. The recurring host browser lane depends on CI-provisioned PostgreSQL, BEAM and Node/Playwright/Chromium; `.github/workflows/ci.yml` explicitly provisions OTP 28, Elixir 1.19.5, Node 22, installs host dependencies and Chromium before `host-integration`. Local availability was not probed because tests/browser execution were explicitly prohibited by the task. [CITED: `.github/workflows/ci.yml`]

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists at the project root. Applicable project instructions from `CLAUDE.md`:

- Use Elixir 1.19+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+; existing package mix constraints take precedence for actual locked versions.
- Preserve mandatory webhook signature verification, sensitive-field logging protections, actor separation, and host-owned auth/config boundaries; this phase adds no provider or auth capability.
- Keep `accrue/` and `accrue_admin/` as sibling packages; avoid cross-package ownership changes.
- From Phase 218 onward, machine-verifiable behavior must be deterministic executable evidence; human UAT is not a completion gate when automation can decide the outcome. Add recurring stable checks to merge-blocking CI only when valuable.
- Never treat empty results as proof of absence without a known-positive control in ad hoc verification.
- Never run destructive git operations in the live tree with uncommitted changes; use scratch repos/worktrees for git behavior experiments.
- Before implementation edits, enter through the appropriate GSD execution workflow; direct edits outside it require an explicit bypass.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Overdue is an instant comparison against `Accrue.Clock.utc_now/0`, and only a due date strictly earlier than now is overdue | Pattern 1; Resolved Question 1 | Resolved from the UTC timestamp schema and canonical fakeable project clock; equality is not overdue. |
| A2 | A representative seeded, read-only served-browser journey belongs in the existing host gate; mutation behavior remains covered with deterministic Fake/LiveView tests | Validation Architecture; Resolved Question 3 | Resolved from existing seeded invoice/charge/refund/recovery records and the existing blocking Playwright host lane. |
| A3 | Existing Admin LiveView result copy can represent an explicit “not confirmed” state without a new status component | Pattern 3 | Resolved from `AccrueAdmin.Live.SubscriptionLive.unconfirmed_action_copy/2` (`accrue_admin/lib/accrue_admin/live/subscription_live.ex:2247`); reuse the local copy/announcement pattern, not a new reconciliation flow. |

## Resolved Questions

1. **Invoice date boundary:** `Invoice.due_date` is stored as `:utc_datetime_usec`, and the project-wide canonical source of current time is `Accrue.Clock.utc_now/0` (which delegates to the Fake clock in tests). Compare UTC instants, not local calendar dates: an open invoice is overdue only when `DateTime.compare(due_date, now) == :lt`; exact equality is not overdue. Missing due dates remain unavailable. This gives deterministic boundary tests without inventing a business-timezone convention. [VERIFIED: `accrue/lib/accrue/billing/invoice.ex:63`; `accrue/lib/accrue/clock.ex:3-23`; comparison convention at `accrue/lib/accrue/billing/discount_mapping_actions.ex:236` and `accrue/lib/accrue/entitlements/apple/admission.ex:119`]
2. **Definitive versus ambiguous action outcomes:** A successful Billing return is accepted local action evidence; show completion only when the returned/refreshed scoped invoice or refund projection supports that state, and keep refund fee settlement as a separate row fact. The Stripe mapper makes `%Accrue.CardError{}` the typed card-decline outcome. Pre-dispatch authorization, eligibility, and validation blocks can be stated as not submitted. Other processor errors do not share one safe finality meaning: Stripe rate-limit/idempotency errors are distinct types, while connection/API/unknown errors collapse to `%Accrue.APIError{}`. Therefore, unless an existing typed result proves a decline or local pre-dispatch block, report the outcome as not confirmed and do not retry automatically. [VERIFIED: `accrue/lib/accrue/billing/invoice_actions.ex:60-71`; `accrue/lib/accrue/billing/refund_actions.ex:10-17,31-46`; `accrue/lib/accrue/billing/intent_result.ex:27-100`; `accrue/lib/accrue/processor/stripe/error_mapper.ex:10-21,68-143`]
3. **Seeded browser evidence:** The deterministic example-host showcase seeds draft/open/paid invoice states, succeeded/refunded/failed charges, full and partial refund rows, and historical recovery/webhook events. The existing Phase 234 Playwright contract already logs into the seeded Admin owner and navigates owner-scoped Admin routes; CI invokes the host verification lane. This supports a representative read-only browser journey through billing and recovery navigation. It does not establish that provider mutations are safe to perform in a browser, so action outcomes stay in Fake-backed LiveView/contract tests. [VERIFIED: `examples/accrue_host/priv/repo/seeds/showcase.exs:130-183,230-248,312-340`; `examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs:232-250`; `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js:129-181`; `.github/workflows/ci.yml`; `scripts/ci/accrue_host_uat.sh`]

## Sources

### Primary (HIGH confidence)

- `accrue_admin/lib/accrue_admin/queries/invoices.ex` — selected invoice facts and owner-scoped detail/list reads.
- `accrue_admin/lib/accrue_admin/queries/charges.ex` — owner-scoped payment detail/list and related refund preload.
- `accrue_admin/lib/accrue_admin/queries/dunning.ex` — windowed, owner-scoped event aggregates and current at-risk subscription reads.
- `accrue/lib/accrue/analytics/dunning.ex` — global-scope recovery aggregation and current null-currency fallback.
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `charge_live.ex`, `invoices_live.ex`, `recovery_live.ex` — current staged actions, UI state, money normalization and recovery display.
- `accrue_admin/lib/accrue_admin/components/money_formatter.ex` and `accrue/lib/accrue/invoices/render.ex` — canonical Admin and core currency formatting behavior.
- `accrue/lib/accrue/billing/invoice_actions.ex`, `refund_actions.ex`, `intent_result.ex` — authoritative invoice/refund action result contracts.
- `accrue_admin/test/accrue_admin/live/{invoices_live_test,invoice_live_test,charges_live_test,charge_live_test}.exs` and `analytics/recovery_live_test.exs` — existing deterministic test cases and gaps.
- `.github/workflows/ci.yml`, `scripts/ci/accrue_host_uat.sh`, `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js` — current recurring Admin/host verification infrastructure.

### Project decisions

- `.planning/phases/237-admin-invoices-payments-recovery/237-CONTEXT.md` — locked phase requirements, boundaries, and user decisions.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md` — phase ownership and inherited shift-left policy.
- `CLAUDE.md` — project-specific technical and workflow constraints; no project skill directories were present.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing repository modules and test/CI paths inspected directly; no dependencies proposed.
- Architecture: HIGH — current scoped query, result, component and LiveView seams read from source.
- Pitfalls: HIGH — identified directly from current implementation paths; UTC instant boundary, action error evidence, and deterministic browser fixture scope are resolved from source contracts.

**Research date:** 2026-10-08  
**Valid until:** 2026-11-07 (stable in-repo contracts; reconfirm if action/provider APIs change)
