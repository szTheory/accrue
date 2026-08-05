# Operator runbooks

This guide is the **RUN-01** procedural companion to [`guides/telemetry.md`](telemetry.md). That file owns the **ops event catalog** for `[:accrue, :ops, :*]` — Accrue does **not** duplicate that table here. Use this document for **ordered triage**, **Oban queue defaults**, **expanded Stripe verification**, and the four **mini-playbooks** where sequence matters.

**Library vs host:** Accrue ships workers and suggested queue names; **your host application configures and starts Oban** (queues, concurrency, pruning). Queue names below are **defaults** Accrue documents in code — you may remap them in host config; treat symptoms and checks as patterns, not hard-coded production names.

## Oban queue topology

Queue names are **host-configurable**; the table lists Accrue’s **documented defaults** from `use Oban.Worker` in `accrue/lib` today.

| Queue (default name) | Worker module | Role / when to look | Typical symptoms | Safe first checks |
|----------------------|----------------|---------------------|------------------|-------------------|
| `:accrue_webhooks` | `Accrue.Webhook.DispatchWorker` | Async webhook handler dispatch after ingest | Webhooks stuck `:processing`, DLQ growth, dead-letter ops | Inspect `accrue_webhook_events`, Oban retries for this queue, handler logs (no raw bodies) |
| `:accrue_mailers` | `Accrue.Workers.Mailer` | Transactional email delivery | Mail backlog, PDF/email failures surfacing as ops | Oban job args shape, mailer adapter, ChromicPDF availability |
| `:accrue_meters` | `Accrue.Jobs.MeterEventsReconciler`, `Accrue.Jobs.MeteredRenewalReconciler`, `Accrue.Jobs.ProcessMeteredRenewal` | Meter usage reconciliation, stale renewal repair, and metered settlement | `meter_reporting_failed`, metered renewal repair, metered settlement recovery | Reconciler jobs, Stripe meter API health, Braintree renewal evidence, `accrue_meter_events`, `accrue_metered_renewals` |
| `:accrue_dunning` | `Accrue.Jobs.DunningSweeper` | Subscription dunning sweeps | Unexpected dunning transitions | Scheduled runs, subscription state vs Stripe |
| `:accrue_reconcilers` | `Accrue.Jobs.ReconcileChargeFees` | Fee reconciliation for charges | Fee drift vs Stripe balance | Reconciler errors, Stripe charge/balance transaction lookups |
| `:accrue_reconcilers` | `Accrue.Jobs.ReconcileRefundFees` | Fee reconciliation for refunds | Refund fee mismatches | Same as above for refund path |
| `:accrue_scheduled` | `Accrue.Jobs.DetectExpiringCards` | Card expiry notices / hygiene | Missing expiry emails, card warnings | Job schedule, customer PM metadata (PII-safe) |
| `:accrue_maintenance` | `Accrue.Webhook.Pruner` | Webhook event retention pruning | Prune telemetry anomalies | Retention config, maintenance window, dry-run if offered |

## Stripe verification pattern

Use a **two-layer** mental model whenever Stripe is involved:

1. **Accrue layer (operational):** local rows (`accrue_*` tables), telemetry and `operation_id`, foreign keys and Stripe ids stored by Accrue (`cus_*`, `sub_*`, `pi_*`, Connect account ids, etc.). This is **application state** for billing workflows — useful for triage, not a substitute for Stripe’s financial records. For **customer billing portal** failures, correlate `[:accrue, :billing, :billing_portal, :create]` **`:stop`** / **`:exception`** latency with **`accrue.customer.id`** and **`operation_id`** per [`telemetry.md`](telemetry.md) — **do not** paste `%Accrue.BillingPortal.Session{}` inspect output into tickets. For **Stripe Checkout** sessions created via **`Accrue.Billing.create_checkout_session/2`**, use the same pattern on `[:accrue, :billing, :checkout_session, :create]`, confirm whether the host runs **`Accrue.Processor.Fake`** vs live Stripe, and read the PII-safe metadata contract at [`telemetry.md#billing-checkout-session-create`](telemetry.md#billing-checkout-session-create) — **do not** paste session URLs or **`client_secret`** values into tickets.
2. **Stripe layer (verification):** confirm each issue against the **Stripe resource type + id** using **canonical documentation** (e.g. [Webhooks](https://stripe.com/docs/webhooks), [Testing webhooks](https://stripe.com/docs/webhooks/test), [Billing meter events](https://stripe.com/docs/billing/subscriptions/usage-based/recording-usage)) and **functional Dashboard paths** (e.g. Developers → Webhooks → event deliveries) rather than brittle deep links.

For finance and tax reporting, use **Stripe Dashboard / reporting products** as your source of truth; Accrue focuses on **state, webhooks, and replay** in your app.

## Mini-playbook: [:accrue, :ops, :webhook_dlq, :dead_lettered]

1. Confirm scope: identify `event_id` / `processor_event_id` from telemetry or admin (do **not** paste full webhook payloads or secrets into tickets).
2. Inspect the `accrue_webhook_events` row and last error; decide fix vs replay **before** mutating data.
3. Check **Oban** for `Accrue.Webhook.DispatchWorker` on `:accrue_webhooks` (see [Oban queue topology](#oban-queue-topology)); ensure the host queue is running and not wedged.
4. If replay is required, prefer **admin-gated** or documented replay flows; use **dry-run** when available — avoid destructive deletes from this path.
5. Cross-check the same event type in Stripe via Developers → Webhooks → recent deliveries ([Webhook docs](https://stripe.com/docs/webhooks)).
6. After fix, enqueue or allow retry; watch `[:accrue, :ops, :webhook_dlq, :replay]` and related metrics for confirmation.

If the dead-lettered row is Braintree-sourced or tied to local portal checkout:

7. Confirm whether the failed row should reduce into `accrue.portal.checkout.completed` or a normalized subscription/invoice event before replaying it.
8. Fix host-local causes first: `portal_base_url`, `portal_mount_path`, auth/session continuity, or Hosted Fields readiness.
9. Replay the persisted row only after the mounted path is healthy; Braintree recovery is local projection convergence, not an upstream hosted checkout retry.

## Mini-playbook: [:accrue, :ops, :events_upcast_failed]

1. Record `event_id`, `type`, and `schema_version` from the ops metadata (identifiers only).
2. Determine whether a **deployed upcaster** is missing vs bad persisted data — do not replay until the schema path is understood.
3. Inspect `Accrue.Events` / event storage per your host (see catalog row in `telemetry.md`); align with code version in the running release.
4. Verify Oban or inline retry behavior will not amplify a bad version skew; pause automated replay if unsure.
5. Queue topology for indirect jobs: see [Oban queue topology](#oban-queue-topology) if downstream dispatch is involved.
6. Validate against Stripe only if the failing payload is a **Stripe-sourced** event; use [Event object](https://stripe.com/docs/api/events/object) docs for shape, not as ledger truth.

## Mini-playbook: [:accrue, :ops, :meter_reporting_failed]

Always read the **contract** (when the tuple fires and what each `source` means) at [`telemetry.md#meter-reporting-semantics`](telemetry.md#meter-reporting-semantics) before changing alert thresholds—this runbook is **procedure** only.

1. Read `source` (`:sync`, `:webhook`, `:reconciler`) plus `meter_event_id` / `event_name` from metadata (identifiers only—no raw payloads).
2. Load the matching `accrue_meter_events` row and note `stripe_status`, `stripe_error`, and timestamps so you know whether the failure epoch is already terminal.

### `:sync` (host request path)

1. Correlate with the host request or job that called `Accrue.Billing.report_usage/3` in the same transaction window; inspect logs around `Accrue.Billing.MeterEventActions` for processor errors surfaced synchronously.
2. Fix configuration or upstream Stripe errors, then retry the host operation with a fresh `operation_id` only when the business case requires a new attempt—idempotent replays should converge on the stored terminal row.

### `:reconciler` (Oban `:accrue_meters`)

1. Inspect Oban jobs for `Accrue.Jobs.MeterEventsReconciler` on `:accrue_meters` ([Oban queue topology](#oban-queue-topology)); confirm the queue is running and not wedged behind retries.
2. After correcting Stripe meter setup or credentials, allow the reconciler to dequeue; watch `[:accrue, :ops, :meter_reporting_failed]` and default metrics for confirmation.

### `:webhook` (meter error report path)

1. Trace the event through `accrue_webhook_events` into `Accrue.Webhook.DefaultHandler` and the async `Accrue.Webhook.DispatchWorker` path; verify signature + dispatch health before mutating rows ([Oban queue topology](#oban-queue-topology)).
2. Resolve the upstream Stripe meter error, then replay or wait for the next reconciler pass; confirm the row leaves terminal `failed` only when business logic intentionally clears it.

Shared verification (all sources):

3. Confirm API keys and Stripe meter configuration for the environment (no key material in logs).
4. Cross-check Stripe usage reporting with [Metered billing](https://stripe.com/docs/billing/subscriptions/usage-based/recording-usage) — operational alignment, not accounting close.
5. After code or config fix, allow reconciler retry where applicable; watch ops counters and host metrics.

## Mini-playbook: Braintree metered renewal and settlement recovery

These steps apply to the Braintree-local metering tuples documented in
[`telemetry.md`](telemetry.md). The ordering matters because Accrue's
local invoice ledger is canonical and Braintree is settlement-only in
this flow.

### `[:accrue, :ops, :metered_renewal_stale_repaired]`

1. Confirm the affected `metered_renewal_id` maps to a subscription period that should already have advanced.
2. Inspect the corresponding subscription in Braintree and verify the cycle actually renewed; the backstop should mirror webhook truth, not invent renewal windows.
3. Check `Accrue.Jobs.MeteredRenewalReconciler` and `Accrue.Jobs.ProcessMeteredRenewal` on `:accrue_meters` ([Oban queue topology](#oban-queue-topology)) so the repaired window continues into local invoice authoring and settlement.
4. If the renewal only became visible after webhook backlog or replay work, pair this tuple with `[:accrue, :ops, :webhook_dlq, :replay]` so the replay trail and the stale-window repair tell one story.

### `[:accrue, :ops, :metered_missing_definition]`

1. Inspect the renewal window and its unmatched meter events; identify which `event_name` rows lack a local meter definition.
2. Add or repair the missing definition so future windows classify those events explicitly.
3. Replay the same renewal window after the definition exists; do not create ad-hoc manual charges that bypass the local invoice decomposition.

### `[:accrue, :ops, :metered_charge_awaiting_payment_method]`

1. Repair or replace the customer's default vaulted payment method.
2. Confirm the local invoice for that renewal window is still the correct settlement target.
3. Replay the same renewal window so Accrue reuses the existing charge unit instead of creating a second `Transaction.sale`.
4. If checkout completion is still ambiguous for the same customer, verify whether `accrue.portal.checkout.completed` already persisted locally before creating any manual recovery plan.

### `[:accrue, :ops, :metered_charge_failed_exhausted]`

1. Confirm the failure class and the current local invoice state before retrying anything.
2. Decide whether to retry, write off, or pair the failed renewal with a later operator-approved recovery step.
3. Preserve the original failed attempt trail; do not delete the renewal or charge-attempt rows to force a clean slate.

## Mini-playbook: [:accrue, :ops, :revenue_loss]

1. Capture `reason`, `subject_type`, `subject_id`, and currency amounts from telemetry (aggregates / IDs only — no customer narrative in shared logs).
2. Triage Accrue rows (invoice, credit note, adjustment) that triggered the signal; avoid manual balance edits without a controlled procedure.
3. Check related async work on `:accrue_reconcilers` and `:accrue_webhooks` if the loss correlates with webhook or fee reconciliation ([Oban queue topology](#oban-queue-topology)).
4. In Stripe, locate the **same business object** (charge, refund, dispute) via Dashboard search or list filters; use [Balance transactions](https://stripe.com/docs/reports/balance-transaction-types) categories as reference for **classification**, not as instructions to reproduce Sigma in-app.
5. Document outcome in your ticketing system; escalate finance questions on Stripe’s side, not via Accrue as a ledger substitute.

## RUN-01 coverage

- **Full ops tuple list and one-line first actions** live under **`## Operator runbooks (first actions)`** in [`telemetry.md`](telemetry.md) — bookmark that table for **every** RUN-01 class, including `:connect_account_deauthorized`, `:connect_payout_failed`, `:dunning_exhaustion`, `:charge_failed`, `:incomplete_expired`, `:pdf_adapter_unavailable`, replay (`:webhook_dlq, :replay`), and prune (`:webhook_dlq, :prune`).
- **This file** adds **depth** for the four classic mini-playbooks above plus the Braintree metered-billing recovery sequence.

## v1.59 multi-rail and offline runbooks

These procedures use the bounded actions in `Accrue.Entitlements.Repair`. The
host authorizes every action and supplies the account, actor, reason, operation
ID, and bounded target. Start with a read-only diagnostic and a dry run where
the action supports it. Record only the scenario/runbook ID, safe correlation,
actor, reason, and before/after revision. Stop when authorization, target
identity, provider health, or the post-action convergence check is uncertain.

No procedure here may automatically reconstruct an account, transfer or merge
ownership, refund, cancel, migrate, prorate, or otherwise mutate provider or
financial state. Escalate those decisions to the host's approved finance or
product process.

### `V159-RUN-MISSED-NOTIFICATION` — missed notification recovery

1. Confirm `apple_purchase_to_web_login` or the affected scenario ID, account
   revision, and safe lineage correlation from the bounded diagnostic.
2. An authorized operator records the reason and runs a dry-run of
   `retry_missed_notification` against that one lineage/environment target.
3. If the dry run is correct, queue the named action once and wait for the
   diagnostic's next revision; stop on an ambiguous lineage or provider error.
4. Record the post-convergence revision. Do not replay raw notification data or
   alter a provider purchase.

### `V159-RUN-CURSOR` — history cursor recovery

1. Confirm the affected lineage, environment, cursor age, and the
   `interrupted_resume` or related scenario ID.
2. An authorized operator dry-runs `recover_history_cursor` for the bounded
   lineage/environment target, then confirms the recorded reason.
3. Run the action only after confirming it resumes a known cursor; stop if a
   cursor would be guessed, rewound without evidence, or crosses environments.
4. Verify the new diagnostic revision and record the safe correlation.

### `V159-RUN-PROVIDER-OUTAGE` — provider outage or rate limit

1. Confirm the provider freshness state, retry age, and safe correlation; do
   not copy provider payloads or credentials into the incident.
2. Hold new issuance when key or provider health is unsafe, preserve the last
   known canonical snapshot, and use bounded retry/backoff.
3. An authorized operator dry-runs `retry_provider_check` for one lineage and
   environment, then queues it when the provider has recovered.
4. Stop on repeated rate limits or an unknown response; record the post-action
   revision and open `V159-WL-APPLE-API` or `V159-WL-STRIPE` reassessment.

### `V159-RUN-OWNERSHIP-CONFLICT` — ownership conflict containment

1. Confirm the bounded diagnostic state and `survivor_grant` scenario; retain
   the safe correlation and current revision.
2. An authorized operator dry-runs `review_ownership_conflict` and records the
   actor and reason.
3. Submit the review action only to contain and audit the conflict. Stop when a
   resolution would require account reconstruction, transfer, or merge.
4. Verify the review disposition and route any ownership decision to the host's
   approved product/support process.

### `V159-RUN-DUPLICATE` — duplicate-charge escalation

1. Confirm `duplicate_purchase_prevention`, the bounded diagnostic, and a safe
   correlation; never place charge or transaction material in the ticket.
2. An authorized operator dry-runs `escalate_duplicate_charge`, then records
   the actor, reason, and current revision.
3. Submit only the escalation action and stop. It does not refund, cancel,
   adjust, or mutate a provider charge.
4. Verify the escalation disposition and hand finance resolution to the host's
   approved process. Reassess `V159-WL-SUPPORT` when the trigger recurs.

### `V159-RUN-DEVICE` — stale or revoked device replacement

1. Confirm `device_replacement` or `refund_revocation`, the device state, safe
   correlation, and canonical revision from the bounded diagnostic.
2. An authorized operator dry-runs `replace_revoked_device`; it accepts no
   proof material, token, or credential.
3. Give the learner the literal next action to reconnect and register the
   replacement device. Stop if a stale state would expand access before
   reconnect.
4. Verify the new revision and retain only the redacted outcome.

### `V159-RUN-KEY-ROTATION` — signing-key compromise or rotation

1. Treat a suspected compromise as a security incident. Record the affected key
   set identifier and safe correlation, never key material or signed proof.
2. Pause issuance where the host cannot verify safe key access, then have an
   authorized operator dry-run `rotate_signing_keys` for the bounded key-set
   target.
3. Run the named action after the host's key-management approval; stop on any
   algorithm fallback, unverifiable proof, or unknown key state.
4. Verify post-rotation convergence, run the relevant golden vectors, and open
   the dated `V159-WL-SECURITY` reassessment.

### `V159-RUN-BACKLOG` — reconciliation backlog drain

1. Confirm backlog age, queue health, limit, and safe correlation from the
   bounded diagnostic; do not inspect or publish worker arguments.
2. An authorized operator dry-runs `drain_reconciliation_backlog` with a small,
   bounded limit and recorded reason.
3. Run the action only while provider and queue health are stable. Stop on a
   growing backlog, rate limit, or post-action convergence failure.
4. Verify the revision and backlog age after each bounded batch. Open
   `V159-WL-HOST` when host queue or resource changes are implicated.

### `V159-RUN-APPLE-INGRESS` — Apple notification ingress triage

1. Read response-class trends and retain only a safe correlation. Treat `429` as
   temporary backpressure; compare it with the trusted deployment edge or shared
   rate policy before changing the host's single-node backstop.
2. Review quarantine growth, reconciliation age/backlog, and `needs_repair` in the
   authenticated diagnostic. Do not inspect or attach provider evidence, worker
   arguments, or failure detail to the incident.
3. Confirm the named `:accrue_entitlements` queue and reconciliation sweeper are
   healthy, then allow the existing bounded job to converge. Stop and escalate if
   backlog age grows, a dependency remains unavailable, or `needs_repair` persists.
4. Record the response trend, safe correlation, job state, and next action. This
   runbook does not authorize an automatic grant, ownership, finance, or provider
   mutation.

### `V159-RUN-APP-REVIEW`, `V159-RUN-PRIVACY`, and `V159-RUN-ROADMAP`

- **App Review:** record the storefront change or rejection, review only
  supported in-app purchase/restore/management wording, obtain product/legal
  approval, and stop before publishing an external-purchase or runtime claim.
- **Privacy:** record the jurisdiction, DSR, retention proposal, or redaction
  finding; confirm bounded diagnostic access and remove sensitive evidence
  before release. Stop until the host's privacy owner signs the reassessment.
- **Roadmap:** when Android or a second adopter triggers Google Play work,
  create a dated proposal for a separate rail-policy research milestone. Do not
  add Play parity opportunistically.

## See also

- [`guides/telemetry.md`](telemetry.md) — ops catalog SSOT and **Operator runbooks (first actions)** table
- `Accrue.Telemetry.Ops` — `emit/3` contract (`lib/accrue/telemetry/ops.ex` in the repo; published API on [Hexdocs](https://hexdocs.pm/accrue/))
- Hexdocs path pattern: `https://hexdocs.pm/accrue/` (pin the version to your `mix.lock`)
