Accrue Admin/UI deep research: billing-library best practices, operator jobs-to-be-done, and product doctrine

Executive synthesis

For Accrue, the admin/operator UI should not try to be “Stripe Dashboard inside Phoenix.” The strongest opportunity is to be the billing operations cockpit for your app’s local billing truth: customers, subscriptions, invoices, entitlements, webhook ingestion, async jobs, replay, dunning state, audit history, and the exact reason a user does or does not have access.

Stripe already has the canonical payment dashboard. Stripe’s Customer Portal already gives end users hosted self-service for billing details, payment methods, invoices, cancellations, promotion codes, and subscription updates, within Stripe’s configuration limits.   Accrue Admin should instead answer the questions Stripe cannot answer in app context:

“This customer says they paid. Why are they blocked?”

“Did our webhook pipeline ingest the event, reduce it, update entitlements, and notify the app?”

“Is this subscription state local, remote, stale, failed, retrying, overridden, or intentionally in grace?”

“What safe action can an operator take without corrupting billing state?”

That is the differentiator. The best billing-library UI is less a dashboard and more a support, reconciliation, and incident-response interface.

Accrue’s current direction already lines up with this: its docs frame the app as owning routes, auth, product code, and runtime config, while Accrue owns the billing engine behind them; the proof path explicitly includes starting a Fake-backed subscription, posting a signed webhook, and inspecting/replaying it in admin.   The project docs also describe Accrue as a Phoenix-era billing library with subscriptions, invoices, checkout, webhooks, Fake processor support, and documentation organized around Jobs-to-Be-Done, testing, production readiness, webhooks, entitlements, and admin concerns.  

The UI doctrine I would bake into Accrue is:

Accrue Admin is a safe, auditable control plane for billing projections and billing operations. It should help humans understand, reconcile, and repair billing state without pretending the local database is the payment processor.

⸻

1. Core product thesis for Accrue Admin

Accrue sits between three worlds:

1. The processor world: Stripe, and later possibly other providers.
2. The application world: Phoenix app, accounts, teams, orgs, entitlements, access checks.
3. The operations world: support agents, founders, finance, SREs, and developers debugging real incidents.

Most billing libraries focus heavily on developer ergonomics: subscribe, cancel, resume, swap, charge, webhook handlers, local schemas, and status predicates. That is necessary, but the operational failure modes are where real SaaS pain appears. Stripe’s own webhook docs call out timeouts, automatic retries, duplicate events, non-guaranteed ordering, CSRF exemptions, TLS, and signature verification.   These are not edge cases in production; they are the normal messiness of distributed billing systems.

So the UI should be designed around uncertainty and reconciliation, not just CRUD.

A normal admin UI says:

Subscription: active.

A great billing ops UI says:

Subscription appears active locally. Last processor sync: 3 minutes ago. Latest relevant webhook: customer.subscription.updated, processed successfully. Entitlements: Pro + 12 seats. No drift detected. Next invoice: July 31, 2026. No failed jobs.

Or:

Subscription is past_due locally. Stripe invoice payment failed. Customer remains in app grace until July 10, 2026. Stripe retry schedule is still active. Last webhook failed because plan mapping price_abc is unknown. Operator action: map price, replay event, then re-evaluate entitlements.

That distinction is the product.

⸻

2. Cross-ecosystem lessons that matter most

Rails Pay: best lesson is developer ergonomics plus testing/fake processor

The Pay gem is still the strongest reference for a framework-integrated billing library because it provides a compact mental model around billable owners, customers, subscriptions, charges, payment methods, webhooks, and multiple processors. It supports Stripe, Paddle, Braintree, Lemon Squeezy, and a Fake Processor, while explicitly warning that processors behave differently and that complex apps are often better off sticking to one provider.  

The most transferable lessons for Accrue are:

Fake processor as first-class product surface. Pay’s Fake Processor is not just a test helper; it changes the way developers build and demo billing flows. Accrue’s current docs similarly highlight Fake-backed subscriptions and local/testing flows.   In Phoenix, this should become a major differentiator: seed local customers, subscriptions, invoices, payment failures, grace periods, webhook failures, and replay scenarios without touching Stripe.

Webhook processing must be observable. Pay’s installation docs note that it uses ActiveJob for webhook processing and that if the async worker is not running, incoming webhooks may never be processed and charges/subscriptions may not appear in app records.   In Accrue, the equivalent footgun is Oban queue misconfiguration or disabled workers. The admin UI should surface that immediately.

Multi-provider support is valuable but leaky. Pay’s docs and ecosystem experience show that a common API can be pleasant, but Stripe, Paddle, Braintree, Lemon Squeezy, and other processors do not share one clean billing model.   Accrue should be provider-honest: expose capability flags, not fake uniformity.

Laravel Cashier: best lesson is fluent DX; biggest caution is local schema assumptions

Laravel Cashier is an example of first-party framework integration done well: it provides an expressive interface for Stripe subscription billing, including coupons, swapping subscriptions, quantities, cancellation grace periods, and invoice PDFs.   Its setup adds columns to the users table and creates subscriptions and subscription_items tables; the billable model uses a Billable trait and is usually App\Models\User, though custom models can be configured.  

The caution for Accrue is that this model can become awkward once billing belongs to teams, organizations, workspaces, accounts, resellers, or multiple billable models. A Cashier issue proposing a separate polymorphic Stripe customer model explicitly calls out the benefits for applications with multiple billable models and webhooks that need to map back cleanly.   This supports the Pay-style and Accrue-style instinct: do not hardwire billing into users.

Cashier also reinforces the webhook lesson. Its docs say Cashier handles many Stripe webhooks automatically and list required events for cancellations, subscription updates, customer updates, and payment methods.   The docs also warn that subscription Checkout flows require the customer.subscription.created webhook so Cashier can create local subscription and subscription-item records.   That is a huge UI lesson: the admin should detect “checkout completed but subscription row missing” as a known diagnostic pattern.

Community issues show familiar production pain: out-of-order Stripe webhooks can leave local subscription records incorrect, and idempotency support is requested to avoid duplicate operations during retries or races.   Accrue Admin should make these failure modes visible instead of leaving developers to grep logs.

dj-stripe: best lesson is “do not mirror the world”

dj-stripe is the key warning case. Its maintainers concluded that trying to maintain 1:1 Django models for Stripe’s moving API became extremely hard: too many models and fields, large migrations, cumbersome database state, and limited usefulness for most fields.   In version 2.10.0, dj-stripe moved toward storing full Stripe payloads in a stripe_data JSON field while keeping important/indexed fields separately, explicitly saying that full 1:1 column mapping was no longer a reasonable goal.  

For Accrue, the admin/UI implication is: display rich raw/provider data, but do not over-model every provider field as first-class local state. Use local columns for queries, filters, access decisions, and operational workflows. Use JSON payloads for forensic context, replay, and future compatibility.

dj-stripe also shows the tradeoff between convenience and complexity. Its docs describe automatic sync from Stripe to Django via webhooks, manual model sync commands, and event reprocessing commands.   Community feedback is mixed: some developers value model syncing and webhook support, while others find dj-stripe overkill, migration-heavy, upgrade-painful, or prone to race/deadlock concerns.   Accrue should avoid turning the local database into a second Stripe.

Stripe itself: the source-of-truth constraints the UI must respect

Stripe’s webhook docs are the core operational spec. Stripe recommends deferring complex logic and returning a successful response quickly to avoid timeouts; live-mode failed webhook deliveries are retried for up to three days with exponential backoff; event ordering is not guaranteed; duplicate events can occur; and endpoints should log processed event IDs and verify signatures.  

Stripe’s API idempotency model is also essential: mutating requests can include idempotency keys so retries safely return the same result; keys are pruned after at least 24 hours, and parameter mismatches are rejected.   Accrue Admin actions that create/refund/cancel/swap should always have operator-visible idempotency, reason capture, and audit records.

Stripe’s Customer Portal is powerful but bounded. It lets customers manage subscriptions, billing information, payment methods, invoices, cancellations, and promotion-code-related flows, but it has limitations around some usage-based, multi-product, scheduling, and embedded use cases.   Accrue Admin should treat the portal as the preferred self-service surface when possible, while making its limitations explicit.

⸻

3. Accrue-specific positioning

Based on the public Accrue docs and repository metadata, the emerging architecture is already close to the right shape.

Accrue describes itself as an open-source billing library for Elixir, Ecto, and Phoenix where the host app owns the billing facade, routes, auth boundary, and runtime config, while Accrue owns the billing engine.   Its internal project docs position it as inspired by Pay and Laravel Cashier but idiomatic to Elixir, Ecto, Plug, and Phoenix, with a batteries-included goal around subscriptions, checkout, invoices, coupons, emails, PDFs, webhooks, admin UI, telemetry, and a companion admin UI.  

That host/app boundary is important. Do not make the admin UI assume one universal SaaS data model. Instead:

The host app owns:

Auth, authorization, tenancy, actor identity, billing facade module, product semantics, plan-to-entitlement mapping, support policy, finance policy, customer communications policy, and destructive-action permissions.

Accrue owns:

Processor integration, billing schemas, subscription/invoice/charge/payment-method projections, webhook event ingestion, reducer behavior, idempotency, replay, fake processor behavior, audit ledger, telemetry, operational views, and safe action primitives.

Accrue’s own Jobs-to-Be-Done docs already say the app owns auth, routing, tenancy, and product semantics, while Accrue owns subscriptions, invoices, charges, and audit trail; the processor remains source of truth while Accrue keeps local state queryable at LiveView speed.   That is the right philosophical center.

⸻

4. Personas, hats, and jobs-to-be-done

A billing admin UI is used by people wearing different hats, often under pressure. Design for the situation, not just the role title.

4.1 Founder / owner / small-team admin

Main job: “Is billing healthy, and can I handle support without becoming a Stripe expert?”

They need a dashboard that answers:

* Are subscriptions, invoices, webhooks, and entitlements healthy?
* Are customers getting blocked incorrectly?
* Are failed payments being handled?
* Did the latest deployment break billing?
* Are we safely in test or live mode?
* Are there unresolved DLQ events?
* Are there unknown prices/plans that might affect access?

Avoid giving this persona an overconfident “MRR” number unless Accrue can define exactly what it means. Accrue’s own scope docs distinguish core billing operations from full revenue recognition, accounting exports, and advanced MRR/ARR/churn analytics.   That boundary is good.

4.2 Customer support agent

Main job: “A customer contacted us. I need to understand and resolve the issue safely.”

Common support questions:

* Did they pay?
* Why did they lose access?
* Are they in trial, grace, past_due, canceled, paused, or active?
* Is their payment method failing?
* Can I send a billing portal link?
* Can I resend an invoice?
* Can I issue a refund?
* Can I extend trial or grace?
* Can I cancel at period end?
* Can I see what happened chronologically?

The support UI should be customer-centric, not object-centric. Search should accept email, organization name, user ID, processor customer ID, subscription ID, invoice ID, payment intent ID, charge ID, and webhook event ID.

The most important support view is a customer billing timeline:

1. Checkout/session started.
2. Subscription created remotely.
3. Webhook received.
4. Event processed.
5. Local subscription updated.
6. Invoice paid.
7. Entitlements recalculated.
8. Email sent.
9. Operator action taken.

4.3 SRE / DevOps / on-call engineer

Main job: “Billing is degraded. I need to isolate, contain, and repair the pipeline.”

They need:

* Webhook delivery health.
* Signature verification failures.
* DLQ size and recent failure reasons.
* Oban queue latency and retry counts.
* Duplicate/out-of-order event detection.
* Processor API error rates.
* Test/live mode mismatch warnings.
* Raw-body capture diagnostics.
* Replay tools that use the same reducer path as normal processing.
* Links to provider event IDs and request IDs.

Accrue’s webhook gotchas docs already emphasize raw-body capture before Plug.Parsers, mandatory signature verification, secret rotation, webhook payloads as signals rather than source of truth, and replay/DLQ through the same reducer path.   These should be first-class UI concepts, not hidden docs.

4.4 Finance / RevOps

Main job: “I need to understand charges, invoices, refunds, credits, taxes, and reconciliation.”

They need:

* Invoice list and customer drill-down.
* Charge/refund lineage.
* Currency, amount, tax, discount, and status visibility.
* Invoice PDF links.
* Export hooks or links to Stripe for canonical reports.
* Clear warning when a number is operational, not accounting-grade.
* Refund controls with permissions and reason capture.

Stripe supports full and partial refunds, allows multiple refunds up to the original charge amount, and records refund reasons/notes in Dashboard workflows.   Accrue Admin should mirror the operational workflow while being honest that the processor is canonical.

4.5 Product / growth / customer success

Main job: “How do plan changes, trials, coupons, cancellations, seats, and entitlements affect customer experience?”

They need:

* Trial state.
* Grace state.
* Plan and feature mapping.
* Seats and usage.
* Cancellation reason capture if integrated.
* Upgrade/downgrade preview.
* Coupon/promo visibility.
* “What will happen if I change this?” previews.

Accrue’s JTBD docs already describe preview-then-commit for proration, seat quantity changes, pause/resume/cancel flows, entitlements, and unmapped-plan drift.   This is exactly where an admin UI can be more useful than raw Stripe views.

4.6 Developer / maintainer

Main job: “I need to understand the exact system behavior and safely debug integration mistakes.”

They need:

* Event payloads, redacted.
* Reducer result.
* Diff of local state before/after.
* Idempotency key.
* API request IDs.
* Error stack or sanitized reason.
* Version/config info.
* Local facade/action that triggered the processor call.
* Links to docs for common issues.
* Test/Fake scenario generators.

4.7 Security / compliance / admin owner

Main job: “Make sure billing operations are authorized, auditable, and not leaking sensitive data.”

They need:

* RBAC hooks.
* Tenant scoping.
* Actor identity on every action.
* Reason capture for risky operations.
* Immutable audit trail.
* PII redaction controls.
* No raw card data.
* Break-glass flows.
* Export/delete/retention policy hooks.
* Environment separation between test and live.

⸻

5. The admin UI should be organized around workflows, not tables

A naive UI has tabs for Customers, Subscriptions, Invoices, Charges, Webhooks.

A strong UI has those, but the core workflows should be obvious:

5.1 “Paid but blocked” workflow

This is the highest-value support workflow.

The UI should answer, in one screen:

* Who is the billable owner?
* What is the processor customer ID?
* What subscription should grant access?
* What does the local projection say?
* What does the processor currently say?
* When was the last sync?
* Which webhook events affected this object?
* Did any event fail?
* Are entitlements mapped?
* Is the customer in grace?
* Is there an override?
* What should the operator do next?

Good actions:

* Sync from processor
* Replay failed event
* Map unknown price
* Send billing portal link
* Extend grace with reason and expiry
* Create support note
* Escalate with diagnostic bundle

Dangerous action to avoid:

* “Mark subscription active.”

That action corrupts the model unless it is represented as a clearly labeled, expiring, local access override with actor, reason, scope, and audit trail.

5.2 Webhook incident workflow

Stripe explicitly says event ordering is not guaranteed and duplicate events can occur.   The UI should assume webhook incidents will happen.

Required screens:

* Delivery status by endpoint/mode.
* Signature failures.
* Events received but not processed.
* Events processed with no local object found.
* Events that reduced to no-op.
* Events that failed due to unknown plan/price.
* Events that failed due to API fetch failure.
* DLQ with retry count and next retry.
* Bulk replay with guardrails.
* Dry-run replay where possible.
* “Replay through same reducer” guarantee.

The worst anti-pattern is an admin replay button that executes a different code path from normal webhook handling. Accrue’s docs already say DLQ/replay should use the same reducer path and preserve metadata.   Keep that doctrine.

5.3 Subscription change workflow

A good operator flow is:

1. Select current subscription.
2. Choose target plan/price/quantity.
3. Preview provider-supported outcome.
4. Show proration, next invoice, billing-cycle impact, and unsupported capabilities.
5. Require reason.
6. Commit with idempotency key.
7. Record ledger event.
8. Wait for webhook reconciliation.
9. Show final local/remote convergence.

Accrue’s docs already describe preview-then-commit for proration and provider honesty around Stripe/Fake/Braintree support.   The UI should make provider capability boundaries explicit.

5.4 Refund workflow

Refunds are deceptively simple and operationally risky.

UI should show:

* Original charge.
* Invoice and subscription context.
* Amount paid.
* Amount already refunded.
* Maximum refundable amount.
* Currency.
* Tax/discount context.
* Reason.
* Customer communication option.
* Provider canonical status.
* Idempotency key.
* Resulting event timeline.

Avoid:

* Refund button hidden deep in charge table with no context.
* Allowing multiple operators to race a refund.
* Not showing partial vs full refund.
* Not showing already-refunded amount.

5.5 Dunning / failed payment workflow

Accrue’s docs correctly state that Stripe owns retry cadence while Accrue owns the local grace/terminal access decision.   The UI should separate those two concepts visually:

Processor collection state:

* Invoice failed.
* Retry scheduled.
* Payment method missing/failed.
* Hosted invoice/portal available.

Application access state:

* Still active.
* In grace.
* Read-only mode.
* Suspended.
* Manually overridden until date.

Support actions:

* Send portal link.
* Send invoice link.
* Extend grace with reason.
* Cancel at period end.
* Sync/replay.
* Escalate.

5.6 Entitlements drift workflow

This is where Accrue can be much better than generic billing tools.

The UI should show:

* Plan/price IDs known to processor.
* Local plan mapping.
* Features granted.
* Seat/quantity mapping.
* Current entitlement decision.
* Unknown/unmapped prices.
* Expired or deprecated prices.
* Fail-open/fail-closed behavior.
* Customers affected by mapping drift.

Accrue’s docs already mention fail-closed entitlement checks, active plans/features/grace state, and admin visibility for unmapped-plan drift.   This should be a marquee feature.

5.7 Go-live readiness workflow

Before production launch, the UI should check:

* Stripe secret key present at runtime.
* Webhook signing secret present.
* Test/live mode clearly marked.
* Webhook route installed.
* Raw-body capture configured before parser.
* Oban queue running.
* Webhook endpoint subscribed to required events.
* Signature verification passing.
* Fake processor disabled or clearly local-only in production.
* Billing facade configured.
* Host auth/authorization configured.
* Telemetry wired.
* Admin access gated.

Accrue’s production-readiness docs already call out runtime Stripe keys, webhook signing secrets, raw-body capture before Plug.Parsers, tenancy/billables, observability, test/live lanes, finance handoff, and admin access.   Turn that checklist into UI.

⸻

6. Recommended information architecture

6.1 Dashboard

The dashboard should answer: “Is billing operationally healthy?”

Suggested cards:

* Webhook health: received, processed, failed, DLQ.
* Queue health: running, lag, retries.
* Subscription state: active, trialing, past_due, canceled, paused.
* Entitlement drift: unknown prices, unmapped plans, affected customers.
* Recent high-severity events.
* Failed payments requiring attention.
* Refunds issued recently.
* Config readiness warnings.
* Test/live mode banner.
* Last successful processor sync.

Avoid vanity-first dashboards. MRR, ARR, churn, and LTV are attractive but easy to define incorrectly. Put operational correctness first.

6.2 Customers / billables

The customer page is the core support page.

It should include:

* Host billable owner: user/team/org/workspace.
* Processor customer IDs.
* Subscriptions.
* Current access/entitlement decision.
* Invoices.
* Charges/refunds.
* Payment methods summary.
* Portal/session actions.
* Webhook/event timeline.
* Audit timeline.
* Support notes.
* Diagnostics.

Search should be forgiving. Support agents will paste whatever the customer sent them: email, invoice number, Stripe customer ID, subscription ID, charge ID, payment intent ID, event ID, organization slug, or internal account ID.

6.3 Subscriptions

Filters:

* Active.
* Trialing.
* Past due.
* Grace.
* Paused.
* Canceled.
* Canceling at period end.
* Incomplete/incomplete_expired.
* Unknown/drifted.

Columns:

* Billable.
* Plan/price.
* Quantity/seats.
* Status.
* Current period.
* Trial end.
* Grace end.
* Cancel at.
* Last sync.
* Processor.
* Capability flags.

Actions should be capability-aware: cancel, resume, pause, swap, update quantity, preview invoice, sync, open in provider, open customer.

6.4 Invoices, charges, refunds

These should be linked as a lineage graph, not isolated rows:

Customer → Subscription → Invoice → PaymentIntent/Charge → Refund.

Show:

* Amount.
* Currency.
* Status.
* Attempt count.
* Payment method summary.
* Tax/discount summary.
* PDF/hosted invoice link.
* Refund status.
* Processor links.
* Local events.

6.5 Webhooks and events

This is the SRE cockpit.

Views:

* Event log.
* Failed events.
* DLQ.
* Replay history.
* Endpoint configuration.
* Signature failures.
* Reducer errors.
* Duplicate/no-op events.
* Unknown object references.
* Out-of-order/stale event detection.

Fields:

* Processor.
* Mode.
* Event ID.
* Event type.
* Object ID.
* Created time.
* Received time.
* Processed time.
* Status.
* Attempts.
* Reducer.
* Error class/reason.
* Idempotency/dedupe key.
* Linked billable/subscription/invoice.
* Payload, redacted.
* Headers, redacted.
* Replay button.

6.6 Entitlements

This should be a first-class section, because access bugs are what customers feel.

Views:

* Plan/price mapping.
* Feature mapping.
* Seat mapping.
* Active grants.
* Grace/suspension rules.
* Unknown processor prices.
* Customers affected by drift.
* Entitlement decision explorer.

A great tool here would be:

“Explain access decision”

Given a user/org, show why can?(:use_feature_x) returns true or false.

6.7 Settings / readiness

This is not generic settings. It is an integration safety panel.

Sections:

* Processor mode and credentials presence.
* Webhook endpoint status.
* Required events.
* Oban/queue status.
* Raw-body capture check.
* Host auth adapter.
* Tenant scoping adapter.
* Email/Swoosh config.
* PDF config.
* Portal config.
* Telemetry config.
* Package versions.
* Stripe API version / processor adapter version.
* Fake processor settings.

6.8 Audit ledger

Every important action should be reconstructable.

Event types:

* Operator viewed sensitive billing data.
* Portal link created.
* Subscription change previewed.
* Subscription change committed.
* Refund initiated.
* Grace extended.
* Access override created/expired/revoked.
* Webhook replayed.
* Event marked ignored.
* Price mapping changed.
* Config changed.
* Processor sync executed.

Each event should include:

* Actor.
* Tenant.
* Billable.
* Reason.
* Before/after snapshot or diff.
* Processor request IDs.
* Idempotency key.
* Source IP/session if host app provides it.
* Timestamp.
* Correlation ID.

⸻

7. Best practices to bake into Accrue Admin

7.1 Treat local billing state as a projection

The local DB is not the processor. It is a queryable, operational projection.

Show:

* “Last synced from processor.”
* “Source event.”
* “Processor object updated at.”
* “Local row updated at.”
* “Projection confidence.”
* “Pending webhook/job.”
* “Known stale.”

This avoids the classic support mistake: trusting local status blindly when the webhook pipeline is broken.

7.2 Make every risky operation preview-first

For subscription swaps, quantity changes, cancellations, refunds, trial extensions, and grace overrides:

1. Preview.
2. Explain consequences.
3. Require reason.
4. Commit.
5. Audit.
6. Reconcile through webhook/sync.

No silent mutations.

7.3 Prefer hosted customer self-service where possible

Use Stripe Customer Portal for customer-managed billing information, payment methods, invoices, cancellations, promotion codes, and subscription changes where configured.   Accrue Admin should create/send portal sessions and explain portal limitations rather than rebuilding every self-service flow locally.

7.4 Expose provider capability honestly

Do not show “Pause” if the provider/adapter does not support pause. Do not show “Preview proration” if the provider cannot preview. Do not imply Braintree, Stripe, Paddle, Lemon Squeezy, and Fake behave the same.

Use capability flags:

* supports_checkout?
* supports_portal?
* supports_proration_preview?
* supports_pause?
* supports_resume?
* supports_subscription_items?
* supports_usage_metering?
* supports_invoice_pdf?
* supports_refund_reason?
* supports_tax?

Accrue’s docs already present Stripe as the native/default processor, Fake as local/testing, and Braintree as bounded with limitations around preview, quantity, and subscription items.   That style of honesty should appear in UI.

7.5 Design replay as a safe primitive

Replay is one of the most important admin actions.

Rules:

* Replay uses the same reducer path as normal processing.
* Replay is idempotent.
* Replay stores actor and reason.
* Replay shows before/after.
* Replay can be dry-run where possible.
* Bulk replay has filters and confirmation.
* Replay cannot mutate raw event history.
* Replay does not bypass signature/origin metadata.
* Replay failure is itself auditable.

Accrue’s webhook docs already emphasize replay/DLQ using the same reducer path and preserving metadata.  

7.6 Build around idempotency everywhere

Idempotency is not just a Stripe API feature. It should be an Accrue product invariant.

Use idempotency for:

* Processor API calls.
* Webhook event processing.
* Refunds.
* Subscription swaps.
* Quantity updates.
* Portal/session creation where relevant.
* Replay.
* Internal jobs.
* Email sends.
* Meter events.

Stripe’s idempotency docs provide the external model: mutating requests can safely be retried with idempotency keys, and Stripe returns the same result for the first key.   Accrue should extend that idea through the local system.

7.7 Make test/live mode impossible to confuse

Always show:

* Current processor mode.
* Key mode if detectable.
* Webhook endpoint mode.
* Customer/subscription mode.
* Fake processor banner.
* Production warning if Fake/test artifacts appear.

Do not let an operator refund a live customer from a screen that visually resembles test mode.

7.8 Use raw payloads for forensics, not primary state

Store enough payload data to debug and replay, but use explicit columns only for indexed/queryable/semantic state. dj-stripe’s move away from full 1:1 column mapping is the cautionary precedent.  

7.9 Make “unknown” a real UI state

Billing systems often lie by omission. Use explicit states:

* Unknown.
* Not synced.
* Sync pending.
* Sync failed.
* Webhook missing.
* Webhook failed.
* Processor unreachable.
* Local override active.
* Mapping unknown.
* Provider unsupported.
* Permission denied.
* Requires operator decision.

Unknown is safer than false certainty.

⸻

8. Anti-patterns and footguns

8.1 “Mark as active” button

This is the most dangerous support shortcut.

Bad:

Operator clicks “Mark active,” local subscription status changes, access granted forever, Stripe still says unpaid/canceled.

Better:

Operator creates a local access override with scope, reason, actor, expiry, and visible warning. The subscription remains processor-honest.

8.2 Returning 200 before durable webhook persistence

If the endpoint returns success but fails before storing the event, the event may be lost from the app’s perspective. Stripe retries failed deliveries, but a successful 2xx tells Stripe the delivery succeeded. Stripe’s docs emphasize fast successful responses, retries for failed deliveries, and separate handling for undelivered events.  

The safe pattern:

1. Verify signature.
2. Durably insert event or detect duplicate.
3. Enqueue job.
4. Return 2xx.
5. Process async.

8.3 Trusting webhook payloads as current truth

Stripe says event ordering is not guaranteed and recommends retrieving missing/current objects when needed.   Accrue’s own docs say webhook payloads are signals, not source of truth, and recommend re-fetching current objects to avoid stale/out-of-order state.  

The UI should show when an event was reduced from payload only versus reconciled against current processor state.

8.4 Hidden duplicate/out-of-order handling

Do not silently discard events without showing why.

Show:

* Duplicate by event ID.
* Duplicate by object ID + event type.
* Stale event ignored because newer processor state already applied.
* Event processed but produced no state change.
* Event could not be linked to local billable.

8.5 Heavy synchronous webhook work

Stripe recommends deferring complex logic and returning quickly to avoid timeouts.   In Phoenix, this means Oban or equivalent async processing. The UI should detect when jobs are not running.

8.6 Raw-body capture mistakes

Stripe signature verification depends on exact request payload bytes. Accrue’s webhook gotchas docs explicitly call out raw-body capture before Plug.Parsers and warn against installing a body reader globally.   The readiness UI should test this path.

8.7 Over-generalized multi-provider UI

A uniform UI that pretends all processors support the same operations will mislead operators.

Bad:

Every subscription has Pause, Resume, Swap, Preview, Quantity, Portal, Invoice PDF, and Metering buttons.

Better:

Actions are shown or disabled based on adapter capability, with explanation.

8.8 Rebuilding all of Stripe Dashboard

Stripe Dashboard and Workbench already provide provider-native request logs, events, webhook delivery inspection, API objects, and integration errors.   Accrue should link out to Stripe for canonical provider details and focus on app-local context.

8.9 Full local mirror of provider API

dj-stripe’s long-term experience shows that full API mirroring becomes expensive to maintain as provider APIs evolve.   Accrue should store full objects as JSON for context but avoid modeling every field.

8.10 Misleading metrics

MRR, ARR, churn, expansion, contraction, and trial conversion are business-specific. They depend on currency conversion, discounts, taxes, annual contracts, usage, coupons, refunds, cancellations, pauses, and revenue recognition rules.

A billing library can provide raw operational aggregates, but should avoid presenting accounting-grade or investor-grade metrics unless the definitions are explicit.

8.11 No RBAC or tenant boundary

Billing admin actions are sensitive. The UI must integrate with host authorization. Accrue’s docs already frame admin access as gated by host auth.  

8.12 Unredacted payloads

Raw webhook payloads are useful, but the UI should redact sensitive PII and never store or display raw card data. Operators usually need identifiers, status, amounts, and links, not full unfiltered payloads.

8.13 Bulk replay without guardrails

Bulk replay can fix incidents or amplify them.

Require:

* Narrow filters.
* Dry-run/count.
* Max batch size.
* Reason.
* Actor.
* Rate limiting.
* Idempotency.
* Progress reporting.
* Roll-forward-only semantics.

8.14 Hard-coded price IDs with no drift detection

This causes silent access bugs when Stripe prices change.

Accrue Admin should detect:

* Price exists in processor but not local mapping.
* Local mapping references missing/deprecated price.
* Multiple active prices map to same plan unexpectedly.
* Customer has subscription item with unknown price.
* Entitlements fail closed because of unknown mapping.

8.15 No support notes or reason capture

Billing actions without reasons are future incidents.

Every manual action should ask:

“Why are you doing this?”

The answer should appear in the customer timeline.

⸻

9. Key tradeoffs

9.1 Stripe Dashboard vs Accrue Admin vs Customer Portal

Surface	Best for	Weakness
Stripe Dashboard	Canonical provider operations, logs, raw payment objects, refunds, disputes, invoices	No app tenancy, no entitlement context, broad access risk for support users
Stripe Customer Portal	End-user self-service for billing details, invoices, payment methods, subscription changes/cancellation	Limited by Stripe configuration and supported flows; not an operator/debugging tool
Accrue Admin	App-aware support, local projection, entitlements, webhook health, replay, audit, safe actions	Must avoid pretending to be canonical processor; must not duplicate too much provider UI

The winning strategy is not choosing one. It is using each for its proper job.

9.2 Minimal local projection vs full mirror

Minimal projection plus JSON payloads

Pros:

* Easier to maintain.
* Better upgrade path.
* Faster local queries for important states.
* Avoids modeling provider churn.
* Supports forensic/debug payloads.

Cons:

* Some queries require JSON or provider fetch.
* Less complete local analytics.
* Requires thoughtful column selection.

Full mirror

Pros:

* Rich local querying.
* Fewer provider API calls for obscure fields.
* Feels complete.

Cons:

* Migration burden.
* API drift.
* Slow upgrades.
* Many fields not useful.
* Maintenance sink.

dj-stripe’s evolution strongly favors the minimal projection plus JSON approach.  

9.3 Admin UI in core package vs companion package

Core package

Pros:

* Immediate batteries-included experience.
* Docs and UI stay aligned.
* Easier proof path.
* Stronger differentiation.

Cons:

* Pulls LiveView/admin dependencies into everyone’s app.
* More surface area to maintain.
* Harder to support host-specific design systems/auth.

Companion package

Pros:

* Cleaner core.
* Optional dependency.
* Easier to customize/replace.
* Matches ecosystem precedent: Pay/Jumpstart, Cashier/Spark, Bling/Bankroll.

Cons:

* Weaker first-run experience.
* Version compatibility burden.
* Users may miss operational UI entirely.

Accrue appears already split conceptually around accrue, accrue_admin, and accrue_portal in docs.   That is the right shape: core engine plus optional LiveView admin.

9.4 Provider abstraction vs Stripe-first

Stripe-first

Pros:

* Deep correctness.
* Better docs.
* Fewer leaky abstractions.
* More complete admin workflows.
* Matches market demand.

Cons:

* Later providers require adapter seams.
* Some users may want Paddle, Lemon Squeezy, Braintree, or MoR behavior.

Abstract from day one

Pros:

* Cleaner conceptual interface.
* Future adapters easier in theory.

Cons:

* Lowest-common-denominator design.
* Fake parity.
* More complicated UI.
* Harder docs.
* Processor-specific edge cases leak anyway.

Laravel’s separate Cashier packages and Pay’s processor warnings both support a Stripe-first but extensible design.  

9.5 Local operator actions vs hosted-only actions

Hosted-only

Pros:

* Processor remains canonical.
* Less liability.
* Less local UI complexity.
* Better SCA/payment-method handling.

Cons:

* Support agents cannot resolve everything.
* Context switching.
* Harder to audit in app.

Local operator actions

Pros:

* Better support workflows.
* App-aware.
* Auditable.
* Can handle entitlements and grace.

Cons:

* Risk of corrupting state.
* Must be permissioned, idempotent, previewed, and reconciled.

Best answer: local UI for orchestration and safe operational actions; hosted portal/dashboard for canonical payment operations when appropriate.

⸻

10. Concrete UI patterns worth implementing

10.1 Customer “billing health card”

At top of customer page:

* Current app access: Active / Grace / Suspended / Trial / Unknown.
* Reason: “Subscription active and current period valid.”
* Processor status: active.
* Local status: active.
* Last sync: timestamp.
* Entitlement mapping: OK / drift.
* Open issues: failed webhook, unknown price, failed payment, stale projection.
* Primary next action.

10.2 Timeline with typed events

A chronological view:

* Checkout created.
* Processor session completed.
* Webhook received.
* Event reduced.
* Subscription upserted.
* Invoice paid.
* Entitlements updated.
* Email sent.
* Operator action.
* Replay performed.

Each event expandable with payload, diff, actor, request ID, idempotency key, and linked records.

10.3 “Explain entitlement” panel

For any billable:

Feature: advanced_reports
Decision: allowed
Source: subscription sub_123, price price_pro, quantity 12
Grace: not needed
Mapping version: 4
Last evaluated: timestamp
Drift: none

For denial:

Decision: denied
Reason: subscription past_due and grace expired July 1, 2026
Last invoice failed
Action: send portal link or extend grace

10.4 Webhook replay diff

Before replay:

* Current subscription status: past_due.
* Incoming event type: invoice.paid.
* Remote fetch result: subscription active.
* Expected local changes: status past_due → active; grace cleared; entitlement Pro restored.
* Side effects: none / email / telemetry.

After replay:

* Show actual diff.
* Mark event processed.
* Link audit record.

10.5 Safe action drawers

Every risky action opens a drawer/modal with:

* What will happen.
* What Accrue will call.
* Whether provider supports preview.
* Expected webhook follow-up.
* Idempotency key.
* Required reason.
* Permission requirement.
* Audit notice.
* Confirmation.

10.6 Environment banners

Persistent banner:

* LIVE Stripe mode.
* TEST Stripe mode.
* Fake processor.
* Local/dev.
* Webhook endpoint mismatch.
* Secret missing.
* Oban queue stopped.

Never rely on subtle badges.

⸻

11. Recommended data model additions for admin excellence

Even if the core billing tables exist, the admin UI becomes much better with a few operational tables/concepts.

11.1 WebhookEvent

Fields:

* Processor.
* Mode.
* Processor event ID.
* Event type.
* Object ID.
* Object type.
* Received at.
* Processor created at.
* Signature verified.
* Payload JSON.
* Headers JSON, redacted.
* Status: received, enqueued, processing, processed, failed, ignored, duplicate.
* Error reason.
* Attempts.
* Last attempted at.
* Processed at.
* Linked local records.
* Reducer version.
* Replay count.

11.2 BillingEvent / AuditLedger

Separate from raw webhooks. This is the app/audit timeline.

Fields:

* Event type.
* Actor type/id.
* Billable type/id.
* Customer/subscription/invoice/charge IDs.
* Source: webhook, operator, system, processor_sync, fake.
* Reason.
* Metadata.
* Before/after diff.
* Correlation ID.
* Idempotency key.
* Timestamp.

Accrue docs mention an append-only tamper-evident event ledger and state/timeline observability.   This is worth making central.

11.3 ProcessorRequest

For actions initiated from Accrue:

* Action.
* Processor.
* Mode.
* Idempotency key.
* Request params, redacted.
* Response summary.
* Request ID.
* Status.
* Error.
* Actor.
* Reason.
* Linked audit event.

11.4 EntitlementDecisionLog, optional

For debugging access issues:

* Billable.
* Feature.
* Decision.
* Inputs.
* Mapping version.
* Subscription state.
* Evaluated at.
* Request/correlation ID.

This could be sampled or debug-only to avoid high-volume writes.

11.5 AccessOverride

For support exceptions:

* Billable.
* Feature/plan/scope.
* Starts at.
* Expires at.
* Reason.
* Actor.
* Status.
* Audit link.

This is much safer than mutating subscriptions.

⸻

12. Operator permissions model

A useful default permission vocabulary:

* billing.view
* billing.view_sensitive
* billing.send_portal_link
* billing.sync
* billing.replay_webhook
* billing.refund
* billing.cancel
* billing.change_subscription
* billing.extend_trial
* billing.extend_grace
* billing.override_access
* billing.manage_price_mappings
* billing.manage_webhooks
* billing.bulk_replay
* billing.export
* billing.admin

Accrue should not implement the host’s authorization model, but it should expose hooks so the host can authorize each action. This matches Accrue’s host-owned auth boundary.  

⸻

13. Examples of good admin copy

Good billing UI copy should explain distributed state clearly.

Instead of:

Failed

Use:

Webhook received and stored, but processing failed. No local subscription changes were applied. You can replay after fixing the error.

Instead of:

Active

Use:

Active locally and confirmed by Stripe 2 minutes ago.

Instead of:

Unknown plan

Use:

Stripe price price_123 is not mapped to an Accrue plan. Entitlements are failing closed for this subscription.

Instead of:

Refund

Use:

Refund through Stripe. Accrue will create an audit record and wait for the refund webhook to reconcile local state.

Instead of:

Replay

Use:

Replay this stored event through the normal reducer. This is idempotent and will not create a second raw event.

⸻

14. What Accrue should intentionally not do

Do not build a full accounting system.

Do not build revenue recognition.

Do not build investor-grade SaaS metrics unless explicitly scoped and defined.

Do not replace Stripe Dashboard.

Do not store raw card details.

Do not model every Stripe object and field as first-class columns.

Do not let operators mutate subscription truth directly.

Do not hide webhook/job failure state.

Do not abstract providers into fake sameness.

Do not make the admin UI assume billing always belongs to users.

Do not make the UI require LiveView customization by forking generated code forever.

Do not make replay a separate code path.

Do not make test/live differences subtle.

⸻

15. “Batteries included” checklist for Accrue Admin v1

A credible v1 admin surface should include:

* Customer/billable search.
* Customer billing detail page.
* Subscription list and detail page.
* Invoice/charge/refund list and detail pages.
* Webhook event log.
* DLQ/replay.
* Billing event/audit timeline.
* Entitlements mapping/drift view.
* Portal-link action.
* Sync-from-processor action.
* Refund action with reason and idempotency.
* Cancel/resume/swap/update quantity where supported.
* Go-live readiness checklist.
* Test/live/Fake banners.
* Oban/queue health integration.
* Telemetry hooks.
* Host auth/authorization hooks.
* Redacted raw payload viewer.
* Provider links.
* Fake scenario generator for local/dev.

⸻

16. Best “north star” user stories

These are the stories I would use to evaluate the admin UI.

Support story

A customer emails: “I paid but I’m locked out.”
The support agent searches by email, sees the subscription is active in Stripe but local entitlements are denied because a webhook failed on unknown price mapping. The UI suggests mapping the price and replaying the event. The agent does that, access is restored, and the timeline records everything.

SRE story

Stripe webhooks are failing after a deploy.
The SRE opens Accrue Admin, sees signature verification failures started at a specific deploy time, confirms raw-body capture is broken, fixes config, then replays stored failed events from the DLQ.

Finance story

A customer needs a partial refund.
Finance opens the charge, sees invoice/subscription context and already-refunded amount, enters a reason, previews the maximum refundable amount, submits refund through Stripe with idempotency, and sees the refund webhook reconcile.

Founder story

The founder is launching billing today.
They open readiness and see webhook signing secret missing, Oban billing queue disabled, and Stripe test mode still active. They fix those before accepting live payments.

Developer story

A test suite needs subscription states without Stripe.
The developer uses Fake processor scenarios to create active, trialing, past_due, canceled, grace, failed-webhook, and unknown-plan cases locally.

⸻

17. Compact LLM context block for future Accrue work

You can paste this into future design/code sessions:

Accrue is a Phoenix/Ecto/LiveView billing library. The host app owns auth, routing, tenancy, product semantics, plan-to-entitlement mapping, and policy. Accrue owns billing engine state: customers, subscriptions, invoices, charges, payment methods, webhooks, idempotency, audit ledger, processor adapters, Fake processor, telemetry, and optional admin/portal UI.
Accrue Admin should not be a Stripe Dashboard clone. It is an app-aware billing operations cockpit for support, SRE, finance, founders, and developers. Its central job is to answer: “Why does this customer have or not have access, what billing events caused that, is local state converged with the processor, and what safe action can an operator take?”
Core doctrine:
- Processor is canonical for money movement.
- Local DB is a queryable projection plus audit ledger.
- Webhook payloads are signals, not always current truth.
- Webhook processing must be durable, idempotent, async, replayable, and observable.
- Admin actions must be preview-first, permissioned, reasoned, idempotent, audited, and reconciled.
- Provider capabilities must be shown honestly; do not fake uniform parity.
- Entitlements are first-class; show explainable access decisions and mapping drift.
- Test/live/Fake modes must be visually impossible to confuse.
- Unknown/stale/failed states are real UI states.
- Prefer hosted Stripe Portal/Dashboard for canonical provider flows; use Accrue Admin for app context, support workflows, replay, audit, entitlements, and safe orchestration.
Avoid:
- “Mark subscription active” buttons.
- Heavy synchronous webhook logic.
- Returning 200 before durable event storage.
- Trusting webhook order.
- Unredacted payloads.
- Full 1:1 Stripe object mirroring.
- Misleading MRR/ARR metrics.
- Bulk replay without guardrails.
- Provider abstraction that hides real capability differences.

⸻

18. Final recommendation

The best Accrue Admin is a billing support and reliability console.

Make it exceptional at five things:

1. Explain access: why a billable has or lacks entitlements.
2. Reveal drift: local vs processor vs entitlement mapping vs jobs.
3. Repair safely: sync, replay, map, portal-link, refund, cancel, override-with-expiry.
4. Audit everything: actor, reason, idempotency key, processor request, before/after.
5. Teach operators: every failure state should explain the likely cause and safest next action.

That is the gap Rails Pay, Laravel Cashier, and dj-stripe only partially cover. Pay has great library DX and Fake processor ideas; Cashier has fluent framework integration; dj-stripe has deep sync lessons; Stripe has the canonical payment surfaces. Accrue can combine those lessons in a Phoenix-native way by making the invisible operational layer visible, safe, and boring.