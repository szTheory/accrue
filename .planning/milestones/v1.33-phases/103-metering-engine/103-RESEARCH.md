# Phase 103: Metering Engine - Research

**Researched:** 2026-05-02
**Domain:** Braintree-local metering, renewal convergence, and local-ledger-first settlement. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md] [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md]
**Confidence:** HIGH [VERIFIED: accrue/lib/accrue/billing/meter_event_actions.ex] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue/lib/accrue/processor/braintree.ex]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Usage aggregation contract

- **D-01:** Raw usage ingress stays on `Accrue.Billing.report_usage/3`. Hosts continue reporting product-domain usage facts such as `report_usage(customer, "ai_tokens", value: 1200)` rather than subscription-item ids on every call.
- **D-02:** Billable usage is defined by an **Accrue-owned local meter definition**, not by `event_name` alone. A meter definition explicitly binds one ingress event name to one billable target, aggregation formula, and cycle-end charging behavior.
- **D-03:** The recommended default is a **host-light meter-definition model**: keep event reporting simple, while making billability explicit in local Accrue data.
- **D-04:** Meter definitions must bind usage to a concrete billable target such as a metered subscription item / price, so the resulting charge can be explained as a real line item instead of a stringly-typed overage blob.
- **D-05:** Cycle-end aggregation must snapshot or otherwise bind the billing-period inputs that were active for that period. Plan swaps, item changes, or later meter-definition edits must not silently rewrite already-earned usage.
- **D-06:** Unmatched or unusable events must not be dropped silently. They need an explicit operator-visible outcome and troubleshooting path.
- **D-07:** Phase 103 explicitly rejects two default contracts:
  - raw `event_name` as the permanent billing contract
  - requiring hosts to pass `subscription_item_id` / `price_id` on every usage report

### Renewal timing and trigger

- **D-08:** Renewal orchestration is **webhook-primary with a scheduled backstop**.
- **D-09:** Accrue must not treat local month-end or `current_period_end` as an immediate “charge now” trigger. For Braintree, those fields mean “expect renewal soon,” not “gateway renewal definitely happened.”
- **D-10:** A renewal window becomes billable when Braintree lifecycle signals prove that the subscription advanced to the next billing cycle.
- **D-11:** Accrue records one immutable local renewal record per `subscription + period_start + period_end` window. This renewal record is the idempotency and audit anchor for Phase 103.
- **D-12:** The webhook path opens or advances the renewal record, then enqueues the unique Oban job that computes usage and creates the metered sale.
- **D-13:** A narrow scheduled backstop exists only to detect stale renewal windows where gateway renewal should have occurred but no webhook-derived renewal record arrived after a grace period.
- **D-14:** All renewal-window math persists UTC period boundaries. Host-local timezones are presentation-only.
- **D-15:** Phase 103 explicitly rejects:
  - midnight/local-anchor sweeps as the primary trigger
  - treating every `subscription_charged_successfully` event as a month-end metered close without renewal-window classification

### Month-end charge shape

- **D-16:** Accrue's **local invoice ledger is canonical** for Braintree metered billing.
- **D-17:** At cycle close, Accrue aggregates raw usage into local invoice items, finalizes one local month-end invoice per subscription-cycle, and settles that invoice with a single off-session Braintree `Transaction.sale`.
- **D-18:** The external payment object is settlement truth, not modeling truth. Operators and future portal/admin surfaces must be able to answer “what was charged?” from local invoice and usage records without reverse-engineering Braintree metadata.
- **D-19:** The system must preserve the full audit chain:
  `meter_event -> renewal window -> usage aggregate -> invoice item(s) -> Braintree sale -> refund/recovery actions`
- **D-20:** Phase 103 explicitly rejects:
  - one external charge per meter/category as the default architecture
  - “description-only” consolidated sales with no local decomposition
  - last-minute Braintree subscription add-on mutation as the default metering mechanism

### Failure and retry behavior

- **D-21:** Metered month-end charging uses a **tiered, replay-safe recovery model**, not “retry everything” and not “fail everything.”
- **D-22:** Automatic retries are reserved for transient or explicitly retryable Braintree failures. Hard declines and “do not retry” guidance transition the renewal/charge attempt into an operator/customer-visible payment-method-repair state.
- **D-23:** Replay after payment-method repair or explicit operator action must target the **same renewal-window charge unit** idempotently, so recovery never creates a second sale for the same billing period.
- **D-24:** Recovery after customer repair should use the **current repaired default payment method**, while preserving the original failed attempt details for auditability.
- **D-25:** Ops telemetry fires on durable state transitions, not every raw attempt, following Accrue's existing high-signal ops posture.
- **D-26:** Durable charge-state semantics should distinguish at least:
  - `pending`
  - `retry_scheduled`
  - `awaiting_payment_method`
  - `paid`
  - `failed_exhausted`
- **D-27:** Phase 103 must not rely on Braintree duplicate checking or Oban uniqueness alone as the idempotency guarantee. Local renewal/charge records are the canonical dedupe contract.

### DX and downstream workflow defaults

- **D-28:** Downstream planning and execution should **auto-resolve low-impact metering choices** when they do not materially change product semantics, strategic scope, or user surprise.
- **D-29:** Only genuinely high-impact choices should be reopened interactively in later GSD steps. Examples include expanding beyond the local meter-definition model, changing the canonical renewal trigger, or replacing the local-invoice-plus-single-sale architecture.
- **D-30:** Documentation and public language should stay explicit about the processor distinction:
  - Stripe has native meter APIs.
  - Braintree metering is Accrue-owned local aggregation plus external settlement.
- **D-31:** The implementation should favor typed errors, narrow state machines, auditable local records, and operator-friendly telemetry over clever “automatic” behavior that hides why billing happened.

### Claude's Discretion

- Exact schema/module names for meter definitions, renewal records, and metered charge attempts
- Exact retry cadence / grace-window thresholds, provided the tiered recovery model stays intact
- Exact telemetry event names and metadata fields, provided they follow existing Accrue conventions
- Exact public guide split between `metering.md`, a new Braintree metering guide, and operator recovery docs
- Exact UI copy for future portal/admin/operator surfaces, provided it reflects the local-ledger-plus-external-settlement truth honestly

### Deferred Ideas (OUT OF SCOPE)

- Multi-dimensional usage rules / payload-driven rating DSL
- Per-meter or per-category external Braintree charges as a default customer-facing model
- Subscription add-on mutation as the default metering implementation
- Requiring hosts to report subscription-item ids on every usage event
- Reopening low-impact implementation choices in later GSD steps when the current defaults are already coherent
- Global workflow-engine changes outside the Phase 103 planning artifacts, unless later project-level workflow work explicitly scopes them
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BT-06 | System MUST aggregate metered usage via a local engine for Braintree subscriptions. [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md] | Reuse `report_usage/3` and the durable meter-event ledger; add local meter definitions and renewal-window aggregation on top. [VERIFIED: accrue/lib/accrue/billing.ex] [VERIFIED: accrue/lib/accrue/billing/meter_event_actions.ex] |
| BT-07 | System MUST create separate `Transaction.sale` charges against vaulted payment methods at cycle renewal based on aggregated usage. [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md] | Finalize the bill locally first, then settle one renewal-window-owned Braintree sale. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md] [VERIFIED: accrue/lib/accrue/processor/braintree.ex] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep Accrue headless at core boundaries; host-owned Repo/Oban/runtime config remains the rule. [VERIFIED: CLAUDE.md]
- Prefer explicit local truth, typed errors, and low-noise ops telemetry over implicit processor magic. [VERIFIED: CLAUDE.md]
- Preserve webhook signature enforcement, PII-safe logging, and the `<100ms` webhook ingress path posture; heavy metering work belongs off the request path. [VERIFIED: CLAUDE.md]
- Stay within the locked stack: Elixir 1.17+, OTP 27+, PostgreSQL 14+, Oban, Telemetry, and Braintree as the active second processor. [VERIFIED: CLAUDE.md]

## Summary

Phase 103 should **not** extend Stripe meter semantics. It should layer a Braintree-local metering core onto seams that already exist: `Accrue.Billing.report_usage/3` for ingress, `MeterEvent` for durable raw facts, `DefaultHandler` for webhook-first convergence, `Subscription` / `SubscriptionItem` for cycle boundaries and billable targets, `InvoiceItem` for local decomposition, and `Telemetry.Ops` / `Telemetry.Metrics` for durable ops visibility. [VERIFIED: accrue/lib/accrue/billing.ex] [VERIFIED: accrue/lib/accrue/billing/meter_event.ex] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue/lib/accrue/billing/subscription.ex] [VERIFIED: accrue/lib/accrue/billing/subscription_item.ex] [VERIFIED: accrue/lib/accrue/billing/invoice_item.ex] [VERIFIED: accrue/lib/accrue/telemetry/ops.ex] [VERIFIED: accrue/lib/accrue/telemetry/metrics.ex]

The main gap is **post-ingress local truth**. The current Braintree adapter leaves `report_meter_event/1`, `create_charge/2`, `retrieve_charge/2`, and invoice writes unsupported, so Phase 103 needs its own renewal-window-owned settlement path rather than reusing the existing Stripe-shaped charge or invoice actions. [VERIFIED: accrue/lib/accrue/processor/braintree.ex] [VERIFIED: accrue/lib/accrue/billing/charge_actions.ex]

**Primary recommendation:** keep host ingress unchanged, add local meter definitions plus immutable renewal windows, write the month-end bill into local invoice rows first, then settle one Braintree sale per renewal window with replay-safe local idempotency. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]

## Existing Code Seams To Reuse

| Need | Reuse | Why this is the seam |
|------|-------|----------------------|
| Meter ingress | `Accrue.Billing.report_usage/3` -> `MeterEventActions.report_usage/3` -> `MeterEvent` [VERIFIED: accrue/lib/accrue/billing.ex] [VERIFIED: accrue/lib/accrue/billing/meter_event_actions.ex] [VERIFIED: accrue/lib/accrue/billing/meter_event.ex] | Already gives host-light API, durable insert-before-processing, deterministic identifiers, and replay-safe raw usage storage. [VERIFIED: accrue/lib/accrue/billing/meter_event_actions.ex] |
| Renewal detection | `Accrue.Webhook.DefaultHandler` Braintree path and `normalize_braintree_type/1` [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] | Renewal classification belongs at webhook convergence. The current Braintree mapping already normalizes subscription lifecycle events and maps `subscription_charged_successfully` to `invoice.paid`, which is the correct insertion point for a renewal-window classifier. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] |
| Invoice decomposition | `InvoiceItem` schema and the existing Braintree branch in invoice projection tests [VERIFIED: accrue/lib/accrue/billing/invoice_item.ex] [VERIFIED: accrue/test/accrue/billing/invoice_projection_test.exs] [VERIFIED: accrue/test/accrue/billing/invoice_projection_braintree_refund_test.exs] | Keep the local ledger explanation shape: line items with description, quantity, period window, and billable refs. Do not collapse the metered bill into a single opaque sale description. [VERIFIED: accrue/lib/accrue/billing/invoice_item.ex] [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md] |
| Charge creation | `ChargeActions` idempotency/error posture, but not its current processor path [VERIFIED: accrue/lib/accrue/billing/charge_actions.ex] | Reuse the local deterministic-idempotency and “no silent PM fallback” rules; do not reuse the current Braintree adapter callbacks because they are still unsupported. [VERIFIED: accrue/lib/accrue/billing/charge_actions.ex] [VERIFIED: accrue/lib/accrue/processor/braintree.ex] |
| Retries | `MeterEvents.mark_failed_with_telemetry/4` plus `MeterEventsReconciler` posture [VERIFIED: accrue/lib/accrue/billing/meter_events.ex] [VERIFIED: accrue/lib/accrue/jobs/meter_events_reconciler.ex] | The established pattern is durable state transition first, one ops event per durable failure epoch, and a narrow backstop job for stale local state. [VERIFIED: accrue/lib/accrue/billing/meter_events.ex] [VERIFIED: accrue/lib/accrue/jobs/meter_events_reconciler.ex] |
| Typed errors | `Accrue.Error.*` family, especially `NoDefaultPaymentMethod` and `DiscountMappingInvalid` [VERIFIED: accrue/lib/accrue/errors.ex] | Phase 103 should add narrow metered-settlement errors rather than returning raw Braintree failures or flattening payment-method-repair into generic `APIError`. [VERIFIED: accrue/lib/accrue/errors.ex] [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md] |
| Ops telemetry | `Accrue.Telemetry.Ops`, `Telemetry.Metrics.defaults/0`, `guides/telemetry.md`, and `guides/operator-runbooks.md` [VERIFIED: accrue/lib/accrue/telemetry/ops.ex] [VERIFIED: accrue/lib/accrue/telemetry/metrics.ex] [VERIFIED: accrue/guides/telemetry.md] [VERIFIED: accrue/guides/operator-runbooks.md] | The repo already reserves `:charge_failed` and documents durable-source telemetry semantics. Phase 103 should extend that posture, not invent a second ops vocabulary. [VERIFIED: accrue/lib/accrue/telemetry/ops.ex] [VERIFIED: accrue/guides/telemetry.md] |

## Recommended Architecture

### Local meter definitions

- Add a local meter-definition record keyed by processor, `event_name`, and billable target, with enough frozen fields to explain how a renewal window was rated. Exact module name is discretionary; `Accrue.Billing.MeterDefinition` is a strong default. [ASSUMED]
- Bind each definition to a concrete `SubscriptionItem.price_id` / plan-facing target so month-end lines stay explainable in local invoice items. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md] [VERIFIED: accrue/lib/accrue/billing/subscription_item.ex] [VERIFIED: accrue/lib/accrue/billing/invoice_item.ex]
- Resolve billability after raw ingress, not during the host API call. Raw usage remains the durable fact ledger; meter-definition matching becomes a second-stage local concern. [VERIFIED: accrue/guides/metering.md] [VERIFIED: accrue/lib/accrue/billing/meter_event.ex]

### Renewal-window records

- Add one immutable renewal-window record per `subscription + period_start + period_end`. Exact module name is discretionary; `Accrue.Billing.RenewalWindow` is a strong default. [ASSUMED]
- Persist UTC `period_start` / `period_end`, the subscription snapshot needed for that close, durable status, and a unique local dedupe key. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md] [VERIFIED: accrue/lib/accrue/billing/subscription.ex]
- Let the renewal window own the downstream aggregate, local invoice rows, settlement attempt, replay history, and operator recovery state. That keeps the required audit chain on one local anchor. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]

### Month-end billing flow

1. Host reports usage through `report_usage/3`. [VERIFIED: accrue/lib/accrue/billing.ex]
2. Raw `MeterEvent` rows accumulate unchanged. [VERIFIED: accrue/lib/accrue/billing/meter_event.ex]
3. Webhook convergence detects a proven cycle advance and opens the immutable renewal window. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]
4. A unique background job aggregates matching usage for that window and writes canonical local invoice item rows first. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md] [VERIFIED: accrue/lib/accrue/billing/invoice_item.ex]
5. Only after local bill authoring does the Braintree settlement step run for one off-session sale tied to that renewal window. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md] [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md]

## Recommended Renewal Trigger Model

- Use **webhook-primary with scheduled backstop** exactly as locked in `103-CONTEXT.md`. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]
- Put the renewal classifier in `Accrue.Webhook.DefaultHandler`, ahead of any metered billing job enqueue, because that is already the non-disableable convergence boundary for Braintree subscription lifecycle events. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]
- Treat the current Braintree normalization as a starting point, not the final trigger. `subscription_charged_successfully` currently normalizes to `invoice.paid`; Phase 103 should classify whether that event actually proves a new cycle and derive the new closed window from subscription state before enqueuing work. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]
- Add one narrow stale-window backstop job patterned after `MeterEventsReconciler`: detect subscriptions whose next renewal should have converged already, refetch, and open the missing renewal window once. Do not make the scheduler the primary clock. [VERIFIED: accrue/lib/accrue/jobs/meter_events_reconciler.ex] [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]

## Main Risks And Sequencing Constraints

- **Do not start with settlement.** Braintree charge creation is still unsupported in the adapter, so building retry logic first would force planners to invent idempotency without the canonical renewal-window anchor. [VERIFIED: accrue/lib/accrue/processor/braintree.ex]
- **Do not rely on raw event names as billing truth.** The locked contract requires local meter definitions; otherwise plan swaps and future definition edits can rewrite already-earned usage semantics. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]
- **Do not reuse the current Braintree invoice projection as the month-end authoring path.** The existing read model proves Braintree projection can decompose transactions, but it only covers “subscription transaction -> invoice-ish projection,” not renewal-window-rated multi-line local bills. [VERIFIED: accrue/test/accrue/billing/invoice_projection_test.exs]
- **Keep durable retry states local.** Oban uniqueness and webhook dedupe are not enough for repaired-payment-method replay; the renewal window must own `pending`, `retry_scheduled`, `awaiting_payment_method`, `paid`, and `failed_exhausted`. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]
- **Telemetry must fire on durable transitions only.** Follow the same one-transition-one-ops-event rule already used by `meter_reporting_failed`; do not emit per-attempt noise. [VERIFIED: accrue/lib/accrue/billing/meter_events.ex] [VERIFIED: accrue/guides/telemetry.md]

## Recommended Plan Breakdown

### Plan 1: Meter Definitions + Renewal Windows

- Add the local meter-definition model and matching logic above existing raw `MeterEvent` rows. [VERIFIED: accrue/lib/accrue/billing/meter_event.ex] [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]
- Add immutable renewal-window records and webhook classification in `DefaultHandler`. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue/lib/accrue/billing/subscription.ex]

### Plan 2: Aggregation + Local Invoice Authoring

- Build the renewal-window worker that snapshots billable inputs, aggregates matched usage, and writes canonical local invoice items. [VERIFIED: accrue/lib/accrue/billing/invoice_item.ex] [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]
- Add explicit unmatched / unusable event outcomes and operator-visible audit trails. [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]

### Plan 3: Braintree Settlement + Recovery

- Implement the Braintree metered settlement seam behind `Accrue.Processor.Braintree`, keyed by renewal window, with one off-session sale per closed window. [VERIFIED: accrue/lib/accrue/processor/braintree.ex] [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md]
- Add typed metered-settlement errors and durable charge-state transitions for retry scheduling and payment-method repair. [VERIFIED: accrue/lib/accrue/errors.ex] [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]

### Plan 4: Backstop + Telemetry + Docs

- Add the stale-renewal backstop job and focused replay / duplicate / recovery tests. [VERIFIED: accrue/lib/accrue/jobs/meter_events_reconciler.ex] [VERIFIED: accrue/mix.exs]
- Update `guides/metering.md`, `guides/telemetry.md`, and `guides/operator-runbooks.md` so the Braintree-local settlement model and recovery semantics are explicit. [VERIFIED: accrue/guides/metering.md] [VERIFIED: accrue/guides/telemetry.md] [VERIFIED: accrue/guides/operator-runbooks.md]

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | ExUnit via `mix test` / `mix test.all` [VERIFIED: accrue/mix.exs] |
| Quick run command | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/invoice_projection_braintree_refund_test.exs` [VERIFIED: accrue/mix.exs] |
| Full suite command | `cd accrue && mix test.all` [VERIFIED: accrue/mix.exs] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Accrue.Billing.MeterDefinition` is the right module/schema name. | Recommended Architecture | Low — naming only. |
| A2 | `Accrue.Billing.RenewalWindow` is the right module/schema name. | Recommended Architecture | Low — naming only. |

## Sources

- `CLAUDE.md` [VERIFIED: CLAUDE.md]
- `.planning/milestones/v1.33-REQUIREMENTS.md` [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md]
- `.planning/phases/103-metering-engine/103-CONTEXT.md` [VERIFIED: .planning/phases/103-metering-engine/103-CONTEXT.md]
- `.planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md` [VERIFIED: .planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md]
- `.planning/phases/102-coupon-discount-mapping/102-CONTEXT.md` [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md]
- `.planning/research/v1.10-METERING-SPIKE.md` [VERIFIED: .planning/research/v1.10-METERING-SPIKE.md]
- `.planning/research/v1.33-BRAINTREE-FULL-MATURITY.md` [VERIFIED: .planning/research/v1.33-BRAINTREE-FULL-MATURITY.md]
- `accrue/guides/metering.md` [VERIFIED: accrue/guides/metering.md]
- `accrue/guides/telemetry.md` [VERIFIED: accrue/guides/telemetry.md]
- `accrue/guides/operator-runbooks.md` [VERIFIED: accrue/guides/operator-runbooks.md]
- `accrue/lib/accrue/billing.ex` [VERIFIED: accrue/lib/accrue/billing.ex]
- `accrue/lib/accrue/billing/meter_event.ex` [VERIFIED: accrue/lib/accrue/billing/meter_event.ex]
- `accrue/lib/accrue/billing/meter_event_actions.ex` [VERIFIED: accrue/lib/accrue/billing/meter_event_actions.ex]
- `accrue/lib/accrue/billing/meter_events.ex` [VERIFIED: accrue/lib/accrue/billing/meter_events.ex]
- `accrue/lib/accrue/jobs/meter_events_reconciler.ex` [VERIFIED: accrue/lib/accrue/jobs/meter_events_reconciler.ex]
- `accrue/lib/accrue/webhook/default_handler.ex` [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]
- `accrue/lib/accrue/billing/subscription.ex` [VERIFIED: accrue/lib/accrue/billing/subscription.ex]
- `accrue/lib/accrue/billing/subscription_item.ex` [VERIFIED: accrue/lib/accrue/billing/subscription_item.ex]
- `accrue/lib/accrue/billing/invoice_item.ex` [VERIFIED: accrue/lib/accrue/billing/invoice_item.ex]
- `accrue/lib/accrue/billing/charge_actions.ex` [VERIFIED: accrue/lib/accrue/billing/charge_actions.ex]
- `accrue/lib/accrue/processor/braintree.ex` [VERIFIED: accrue/lib/accrue/processor/braintree.ex]
- `accrue/lib/accrue/errors.ex` [VERIFIED: accrue/lib/accrue/errors.ex]
- `accrue/lib/accrue/telemetry/ops.ex` [VERIFIED: accrue/lib/accrue/telemetry/ops.ex]
- `accrue/lib/accrue/telemetry/metrics.ex` [VERIFIED: accrue/lib/accrue/telemetry/metrics.ex]
- `accrue/test/accrue/billing/invoice_projection_test.exs` [VERIFIED: accrue/test/accrue/billing/invoice_projection_test.exs]
- `accrue/test/accrue/billing/invoice_projection_braintree_refund_test.exs` [VERIFIED: accrue/test/accrue/billing/invoice_projection_braintree_refund_test.exs]
