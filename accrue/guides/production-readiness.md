# Production readiness

Single **checklist spine** for shipping Accrue-backed billing in a real Phoenix SaaS. It does not replace the deep guides — it tells you **what to verify** and **where to read next**. Accrue stays **Stripe-first** and **host-owned** for auth, tenancy, secrets, and export delivery.

## Before you treat billing as “done”

Work through the sections in order the first time you promote to production; later you can skim by risk area.

### 1. Install pins and upgrades

- [ ] **`accrue` / `accrue_admin`** use the same published **`~>`** line; **`mix.lock`** is the stability boundary for pre-1.0 minors. See [First Hour — Install the packages](first_hour.md#install-the-packages) and [Upgrade guide](upgrade.md).

### 2. Runtime secrets and config

- [ ] **`:stripe_secret_key`** and **`:webhook_signing_secret`** are read from **`config/runtime.exs`** (or equivalent), not compile-time config. See [Configuration](configuration.md#required-runtime-keys).
- [ ] Optional adapters (**`:auth_adapter`**, **`:pdf_adapter`**, **`:mailer`**) match how you run in prod vs dev/test.

### 3. Webhooks (highest ROI failure surface)

- [ ] Raw-body capture runs **before** `Plug.Parsers` on the Stripe webhook route. See [Webhooks](webhooks.md) and [Webhook gotchas](webhook_gotchas.md).
- [ ] Signing secret(s) match the Stripe Dashboard endpoint(s); you understand test vs live mode boundaries. See [Troubleshooting — webhook anchors](troubleshooting.md#accrue-dx-webhook-raw-body).

### 4. Tenancy and billables

- [ ] Billable **`owner_type` / `owner_id`** and admin queries match your org model; cross-tenant paths are denied at the host boundary. See [Organization billing](organization_billing.md) (Sigra and non-Sigra recipes).

### 5. Tax and pricing rollouts (if enabled)

- [ ] Customer tax location and rollout safety match your Stripe Tax story — no “flip automatic tax” surprises on legacy subscriptions. Cross-check [Organization billing](organization_billing.md) and Stripe’s own tax docs via your finance process.

### 6. Observability and operations

- [ ] **`:telemetry`** handlers (and optional OpenTelemetry) are wired in the **host** app for the ops events you need on-call. See [Telemetry](telemetry.md) and [Operator runbooks](operator-runbooks.md).

### 7. Testing stance in CI vs live

- [ ] Merge-blocking **Fake** / host proof path is green (`mix verify` / `mix verify.full` per your policy). See [Testing](testing.md).
- [ ] Stripe **test-mode** and **live** lanes are understood as **non-merge-blocking** unless you explicitly chose otherwise. See repo **`guides/testing-live-stripe.md`**.

### 8. Finance and compliance boundaries

- [ ] Revenue recognition / accounting stays **downstream** of Accrue; you use Stripe-native handoff where appropriate. See [Finance handoff](finance-handoff.md).

### 9. Customer portal and hosted surfaces

- [ ] Stripe Billing Portal / Checkout expectations match what you expose to end users. See [Portal configuration checklist](portal_configuration_checklist.md) and [Branding](branding.md) for customer-facing polish.

### 10. Admin access

- [ ] **`Accrue.Auth`** (or Sigra adapter) enforces who may open **`accrue_admin`** routes in production. See [Auth adapters](auth_adapters.md).

## Proof vocabulary (local / CI)

For the canonical Fake-backed walkthrough and VERIFY-01 vocabulary, keep using [`examples/accrue_host/README.md`](../../examples/accrue_host/README.md#proof-and-verification) alongside [First Hour](first_hour.md).

## Explicit non-goals (until a milestone says otherwise)

Second processor (**PROC-08**), app-owned finance exports (**FIN-03**), and Stripe Dashboard–only workflows that Accrue does not own — see the package [README](README.md) **Stability** / deprecation posture and repository **`RELEASING.md`** for maintainer boundaries (clone-only planning detail lives under **`.planning/PROJECT.md`** in the GitHub repo).
