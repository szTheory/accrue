# Phase 237: Admin Invoices, Payments & Recovery - Context

**Gathered:** 2026-10-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Refine the existing Admin invoice list/detail, payment/charge/refund list/detail, and recovery views so operators can distinguish invoice state, read exact money, review supported actions, understand outcomes from their actual evidence, and navigate recovery work without losing its owner or time window.

This phase owns ADM-02, ADM-05, and ADM-06. Preserve existing billing APIs, provider capability boundaries, owner scoping, host/operator authorization, step-up, and the separate actor/customer/provider identities. Do not add billing capabilities, providers, a generalized reconciliation service, or Phase 238 event/webhook/catalog work.

</domain>

<decisions>
## Implementation Decisions

Auto mode selected all identified discussion areas. The user directed us to follow the recommended defaults. The current roadmap, prior Admin decisions, and source contracts already settle the phase boundary and safety posture.

### Invoice facts and amount precision

- **D-01:** Preserve the stored invoice lifecycle state. Show overdue as a collection fact only when the invoice is open and an applicable known due date has passed under the established date convention. Missing due dates stay explicitly unavailable; draft, open, paid, void, and uncollectible remain distinct.
- **D-02:** Use the canonical currency-aware minor-unit formatter for invoice, payment, refund, and recovery amounts. Preserve real zero amounts and zero-/three-decimal currency precision. A missing amount or unsupported/missing currency remains unavailable; never substitute zero or the configured/default USD currency.

### Payment actions and result evidence

- **D-03:** Reuse the existing staged review-and-confirm interaction for supported invoice payment/finalization and refund actions. Before confirmation, name the exact scoped record and action, show the exact known amount and currency, and state the actual consequence. Revalidate the same owner-scoped target, current eligibility, authorization, and action-relevant facts immediately before dispatch, including after step-up. Do not expose unsupported actions or infer a charge/refund amount.
- **D-04:** Describe accepted, requires-action, failed, and completed outcomes separately when the existing result contract supports them. Tie the visible outcome to the scoped resulting invoice/payment/refund or available history. If the result is ambiguous, say it is not confirmed; do not claim failure or success, replay automatically, or introduce a new reconciliation system.

### Recovery scope and history

- **D-05:** Keep the selected recovery time window, current owner scope, and each currency attached to recovery measures. Preserve validated owner, window, and return context across links into existing records. Keep campaign and failure events as historical evidence; current invoice and subscription status come from their own current observations and must not be overwritten by an older recovery event. Do not combine currencies or fabricate a currency for empty data.

### Verification and bounded implementation

- **D-06:** Carry forward the project shift-left default from PROJECT.md, STATE.md, and prior phase decisions: every testable acceptance claim gets deterministic executable evidence at its cheapest credible seam. Use unit/contract tests for pure money/state rules, scoped LiveView tests for actions and evidence, and representative served-browser proof for real navigation, keyboard/focus, responsive layout, theme, and pending/denied/error states. Keep stable recurring checks in the existing merge-blocking CI lanes when they protect future behavior. Target zero confirmation-only human UAT; hand off only genuine product decisions, unavailable external/live-provider evidence, irreversible external actions, or irreducible subjective judgment, recording the boundary and reason.
- **D-07:** Keep the slice finite and follow the established Admin visual and interaction contract: semantic controls, visible focus, announced outcomes, readable 320 CSS-pixel reflow, theme coverage, current served assets, and current-source screenshots where visual claims require them. Reuse existing components and gates; no broad CI redesign or all-routes-by-all-states matrix.

### the agent's Discretion

- The planner and implementer may choose the smallest local component/query changes and precise copy that meet these decisions, after confirming current source behavior and provider contracts.
- Select representative evidence by distinct behavior and recurring maintenance value; avoid duplicating an invariant in more expensive layers when a lower layer proves it credibly.
- Use current Admin patterns and design tokens; only extract a helper when actual repetition or handler complexity warrants it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary, requirements, and inherited product decisions

- .planning/ROADMAP.md §Phase 237 — goal, dependency, requirements, and success criteria.
- .planning/REQUIREMENTS.md — ADM-02, ADM-05, and ADM-06.
- .planning/PROJECT.md §§Development Posture, Current Milestone v1.63, Verification posture — stable-core guardrails, ownership boundaries, and shift-left default.
- .planning/STATE.md — Phase 234–235 standing decisions; especially auto-first verification and no churn on verified coverage absent new evidence.
- .planning/phases/234-admin-customers-subscriptions/234-CONTEXT.md — exact money, current versus historical facts, owner scope, staged actions, result evidence, visual/accessibility, architecture, and evidence patterns.
- .planning/phases/233-shared-direction-portal-contract/233-CONTEXT.md — shared semantic roles, shell and package ownership, theme, responsive, keyboard, and served-asset boundaries.
- .planning/phases/233-shared-direction-portal-contract/233-UI-SPEC.md — ratified visual and interaction acceptance contract.
- .planning/phases/235-customer-plan-selection-checkout/235-CONTEXT.md — truthful payment outcomes, uncertainty, no blind retry, and automated verification preference.
- .planning/phases/236-portal-billing-self-service/236-CONTEXT.md — current milestone evidence conventions and Portal boundary; broader customer self-service is out of scope here.
- .planning/notes/2026-10-07-accrue-ui-refinement-scope.md §§4–9, 12 — current route inventory, Phase 237 scope, known source findings, information architecture, accessible behavior, and evidence strategy.
- .planning/processor-support-matrix.md — actual processor-specific capabilities and limits.
- PRODUCT.md — actor, owner/customer, operator, and product boundaries.

### Admin implementation and automated proof seams

- accrue_admin/lib/accrue_admin/queries/invoices.ex — owner-scoped invoice reads, status filters, due date, and amount fields.
- accrue_admin/lib/accrue_admin/queries/charges.ex — owner-scoped payment reads and refund relations.
- accrue_admin/lib/accrue_admin/queries/dunning.ex — recovery windows, currency grouping, owner filtering, campaign evidence, and at-risk reads.
- accrue_admin/lib/accrue_admin/live/invoices_live.ex and accrue_admin/lib/accrue_admin/live/invoice_live.ex — invoice list, detail, actions, confirmation, and result presentation.
- accrue_admin/lib/accrue_admin/live/charges_live.ex and accrue_admin/lib/accrue_admin/live/charge_live.ex — payment and refund entry/detail flows.
- accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex — URL-backed 7/30/90-day window and recovery presentation.
- accrue_admin/lib/accrue_admin/components/money_formatter.ex — shared locale-aware currency formatting and unavailable-money behavior.
- accrue_admin/lib/accrue_admin/components/detail_drawer.ex — staged detail/action interaction.
- accrue_admin/lib/accrue_admin/components/at_risk_table.ex and accrue_admin/lib/accrue_admin/components/window_selector.ex — recovery navigation and window controls.
- accrue_admin/lib/accrue_admin/owner_scope.ex, accrue_admin/lib/accrue_admin/scoped_path.ex, and accrue_admin/lib/accrue_admin/step_up.ex — owner context, local return paths, and step-up boundary.
- accrue_admin/lib/accrue_admin/copy/invoice.ex and accrue_admin/lib/accrue_admin/copy/dunning.ex — existing user-facing terminology and state copy.
- accrue/lib/accrue/invoices/render.ex — canonical currency/minor-unit rendering.
- accrue/lib/accrue/billing/invoice_actions.ex, accrue/lib/accrue/billing/charge_actions.ex, and accrue/lib/accrue/billing/refund_actions.ex — authoritative supported action and result contracts.

### Existing verification and CI

- accrue_admin/test/accrue_admin/live/invoices_live_test.exs and accrue_admin/test/accrue_admin/live/invoice_live_test.exs — invoice state, amount, scope, action, and result tests.
- accrue_admin/test/accrue_admin/live/charges_live_test.exs and accrue_admin/test/accrue_admin/live/charge_live_test.exs — payment and refund proof patterns.
- accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs — recovery window, owner, currency, and history tests.
- examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js and examples/accrue_host/e2e/verify01-admin-denial.spec.js — current served Admin browser and mounted denial patterns.
- .github/workflows/ci.yml — existing recurring browser and package verification lanes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Queries.Invoices selects invoice status, due_date, total/due/paid/remaining amounts, customer identity, and owner identity; its detail read is owner-scoped and preloads invoice lines and related records.
- MoneyFormatter delegates to Accrue.Invoices.Render.format_money and prints unavailable for missing or unsupported money rather than inventing currency.
- Invoice and charge detail LiveViews contain existing staged action/review patterns and use the current billing action APIs.
- Queries.Dunning and RecoveryLive already support organization scoping, 7/30/90-day windows, per-currency recovery summaries, campaign funnels, and at-risk subscription navigation.
- Existing LiveView suites cover invoice, payment/refund, and recovery screens; the example host has a served Admin Playwright lane registered with CI.

### Established Patterns

- Owner scope applies to read queries, action target reloads, related links, and result refreshes; URL/context parameters do not authorize access.
- Keep stored lifecycle, derived due-date facts, historical events, and current billing state separate.
- The shared formatter can preserve minor-unit precision; local formatters or currency fallbacks must not weaken this behavior.
- Payment acceptance, provider-required customer action, confirmed completion, definitive failure, and ambiguous outcome are distinct result states. Local audit/history evidence does not establish an external processor outcome by itself.
- Keep existing per-record confirmation, step-up, and idempotency semantics; no custom exactly-once or reconciliation framework is implied.

### Integration Points

- Invoice list and detail routes connect to current customer/subscription records, supported invoice actions, hosted/rendered documents, and invoice event history.
- Charge detail connects the original payment to partial/full refund records and their returned billing evidence.
- Recovery summary and at-risk views join owner-scoped campaign events, invoices, subscriptions, and scheduled dunning jobs, then link into existing scoped details.
- Admin shell owner selection, configured mount path, LiveView authorization, and CI browser setup remain host-owned integration boundaries.

</code_context>

<specifics>
## Specific Ideas

The user wants recurring verification moved into automation/CI when it provides continuing value, zero human UAT as the default, and handoffs only for the irreducible. The preference is already standing policy in .planning/PROJECT.md and .planning/STATE.md; preserve it here without reopening that decision.

</specifics>

<deferred>
## Deferred Ideas

- New providers, billing operations, public APIs, automatic payment retries, durable result reconciliation, and a generalized recovery command center are outside this phase.
- Events/webhook deep investigation, retry/replay work, coupons, promotion codes, and Connect belong to Phase 238.
- Portal customer invoice/payment self-service and integrated cross-surface milestone handoff remain owned by Phases 236 and 239.

</deferred>

---

*Phase: 237-admin-invoices-payments-recovery*
*Context gathered: 2026-10-08*

