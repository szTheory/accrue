# Phase 103: Metering Engine - Context

**Gathered:** 2026-05-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 103 delivers a **local metering engine for Braintree** that turns Accrue's existing raw usage-event surface into accurate cycle-end billing.

This phase satisfies **BT-06** and **BT-07**:
- Accrue aggregates metered usage locally.
- At cycle renewal, Accrue creates a separate Braintree `Transaction.sale` against the customer's vaulted/default payment method based on the aggregated usage.

This phase does **not**:
- Pretend Braintree has Stripe-native meter objects or invoice writes
- Replace Accrue's existing `report_usage/3` surface with a host-heavy billing-internals API
- Turn Braintree subscription add-ons/discounts into the default metering architecture
- Ship a generalized dimensions/rules engine for advanced usage pricing
- Reopen low-impact implementation choices that can be decided coherently during planning/execution

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion

- Exact schema/module names for meter definitions, renewal records, and metered charge attempts
- Exact retry cadence / grace-window thresholds, provided the tiered recovery model stays intact
- Exact telemetry event names and metadata fields, provided they follow existing Accrue conventions
- Exact public guide split between `metering.md`, a new Braintree metering guide, and operator recovery docs
- Exact UI copy for future portal/admin/operator surfaces, provided it reflects the local-ledger-plus-external-settlement truth honestly

</decisions>

<specifics>
## Specific Ideas

- Canonical example:
  - host calls `Accrue.Billing.report_usage(customer, "ai_tokens", value: 1200)`
  - local meter definition binds `"ai_tokens"` to a metered subscription item / price
  - renewal webhook opens the new cycle-close job for that subscription window
  - Accrue aggregates eligible events for the closed window
  - Accrue writes local invoice items for the metered overage
  - Accrue creates one Braintree `Transaction.sale` against the vaulted/default payment method
- The month-end sale should be easy to explain to both developers and operators: “Accrue calculated the bill locally, then used Braintree only to settle it.”
- Future portal/admin UX should show one customer-facing payment for the cycle and a drill-down into the local usage breakdown, rather than a burst of opaque overage transactions.
- The user preference for this project is now explicit:
  strong coherent defaults should be shifted left into GSD/planning/execution, and only materially strategic choices should come back for discussion.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone truth

- `.planning/ROADMAP.md` — Phase 103 goal, dependency, and success criteria
- `.planning/milestones/v1.33-REQUIREMENTS.md` — BT-06 and BT-07 requirement text
- `.planning/PROJECT.md` — project posture, facade-first philosophy, and v1.x least-surprise bar
- `.planning/STATE.md` — current active milestone position and recent decisions

### Upstream phase context

- `.planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md` — Braintree-local first-party surface and “strong defaults” posture
- `.planning/phases/102-coupon-discount-mapping/102-CONTEXT.md` — recent Braintree-local pattern for explicit local truth instead of fake Stripe parity

### Metering and renewal seams

- `.planning/research/v1.10-METERING-SPIKE.md` — historical raw meter-event surface and Fake parity context
- `.planning/research/v1.33-BRAINTREE-FULL-MATURITY.md` — milestone-level Braintree gap analysis and Phase 103 rationale
- `accrue/guides/metering.md` — public raw-usage ingestion architecture
- `accrue/lib/accrue/billing/meter_event_actions.ex` — raw usage write path, idempotency, and reconciler contract
- `accrue/lib/accrue/billing/meter_event.ex` — durable meter-event schema and status model
- `accrue/lib/accrue/billing/meter_events.ex` — guarded failure transitions and ops telemetry shape
- `accrue/lib/accrue/jobs/meter_events_reconciler.ex` — existing Oban backstop pattern to mirror for metered charging
- `accrue/lib/accrue/webhook/default_handler.ex` — webhook-first convergence boundary
- `accrue/lib/accrue/oban/middleware.ex` — job-scoped operation-id pattern

### Billing ledger and settlement seams

- `accrue/lib/accrue/billing.ex` — public facade including `report_usage/3`
- `accrue/lib/accrue/billing/subscription.ex` — subscription period bounds and lifecycle semantics
- `accrue/lib/accrue/billing/subscription_item.ex` — billable-target attachment points
- `accrue/lib/accrue/billing/invoice_item.ex` — local invoice-line shape to preserve for metered decomposition
- `accrue/lib/accrue/billing/charge_actions.ex` — existing charge façade semantics and where Braintree diverges from Stripe-shaped assumptions
- `accrue/lib/accrue/processor/braintree.ex` — current Braintree adapter capabilities and gaps
- `accrue/test/accrue/billing/invoice_projection_test.exs` — local invoice projection expectations
- `accrue/test/accrue/billing/invoice_projection_braintree_refund_test.exs` — Braintree refund/invoice projection expectations

### Errors, telemetry, and ops recovery

- `accrue/lib/accrue/errors.ex` — typed error patterns to follow
- `accrue/lib/accrue/telemetry/ops.ex` — ops-event emission contract
- `accrue/lib/accrue/telemetry/metrics.ex` — low-cardinality metrics posture
- `accrue/guides/telemetry.md` — telemetry SSOT
- `accrue/guides/operator-runbooks.md` — operator recovery SSOT

### Post-implementation doc expectation

- `accrue/guides/braintree-metered-billing.md` — should become the canonical public guide after implementation; downstream plans should treat creating this guide as part of Phase 103 completeness

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Billing.report_usage/3` already provides the right host-light ingress seam for raw usage facts.
- `Accrue.Billing.MeterEvent`, `MeterEventActions`, and `MeterEventsReconciler` already establish Accrue's durable outbox + Oban backstop pattern.
- `Accrue.Telemetry.Ops` and existing ops metrics already provide a high-signal place for metered-charge failure visibility.
- `Accrue.Billing.Subscription` and `SubscriptionItem` already hold the period and billable-target context Phase 103 needs.
- Local invoice/invoice-item projection expectations already exist, which makes “local ledger first, gateway settlement second” a natural fit.

### Established Patterns

- Accrue prefers **explicit local truth** over pretending processors share identical semantics.
- Accrue already uses **webhook-first convergence with background backstops** instead of trusting synchronous success alone.
- The repo already values **typed errors, guarded state transitions, and low-noise ops telemetry**.
- Braintree work in recent phases consistently chose **local Accrue-owned semantics** when Braintree lacked a Stripe-equivalent primitive.

### Integration Points

- Phase 103 should add a local meter-definition layer on top of the existing meter-event ledger rather than replacing that ledger.
- Renewal-window orchestration should mirror the existing webhook + Oban correction style instead of inventing a separate scheduler-first model.
- Settlement should connect metered renewal windows to the local invoice model and a single Braintree sale, not to per-meter external charges.
- Recovery should plug into existing error/telemetry conventions and preserve a clean replay seam after payment-method repair.

</code_context>

<deferred>
## Deferred Ideas

- Multi-dimensional usage rules / payload-driven rating DSL
- Per-meter or per-category external Braintree charges as a default customer-facing model
- Subscription add-on mutation as the default metering implementation
- Requiring hosts to report subscription-item ids on every usage event
- Reopening low-impact implementation choices in later GSD steps when the current defaults are already coherent
- Global workflow-engine changes outside the Phase 103 planning artifacts, unless later project-level workflow work explicitly scopes them

</deferred>

---

*Phase: 103-metering-engine*
*Context gathered: 2026-05-02*
