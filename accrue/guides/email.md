# Email

Accrue's transactional email pipeline — semantic API, override ladder,
async dispatch via Oban, localization, testing, and regulatory context.

This guide documents Phase 6 (Email + PDF) as shipped in v1.0.

## Quickstart

Minimal config for a host Phoenix app:

```elixir
# config/config.exs
config :accrue,
  mailer: Accrue.Mailer.Default,
  pdf_adapter: Accrue.PDF.ChromicPDF,
  branding: [
    business_name: "Acme Corp",
    from_name: "Acme Billing",
    from_email: "billing@acme.example",
    support_email: "support@acme.example",
    company_address: "123 Main St, San Francisco, CA 94103",
    logo_url: "https://cdn.acme.example/logo.png",
    accent_color: "#1F6FEB",
    secondary_color: "#6B7280",
    font_stack: "-apple-system, BlinkMacSystemFont, sans-serif"
  ]

# config/runtime.exs
config :accrue, Accrue.Mailer.Swoosh,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: System.fetch_env!("SENDGRID_API_KEY")
```

The host application's supervision tree is responsible for starting
Oban, ChromicPDF, and the Swoosh adapter — Accrue does not start them
itself (D-33, D-42).

## Semantic API

Callers send an email by type + scalar assigns map — never by
constructing a `%Swoosh.Email{}` directly:

```elixir
Accrue.Mailer.deliver(:receipt, %{
  customer_id: "cus_abc",
  charge_id: "ch_xyz"
})
```

Full 13-type catalogue (Phase 6 MAIL-03 through MAIL-13):

| Type atom | Trigger | PDF attached | Required assigns |
|-----------|---------|--------------|------------------|
| `:receipt` | `charge.succeeded` webhook | no | `customer_id`, `charge_id` |
| `:payment_failed` | `charge.failed` / `payment_intent.payment_failed` | no | `customer_id`, `charge_id` |
| `:trial_ending` | `customer.subscription.trial_will_end` | no | `customer_id`, `subscription_id` |
| `:trial_ended` | cron | no | `customer_id`, `subscription_id` |
| `:invoice_finalized` | `invoice.finalized` | yes | `customer_id`, `invoice_id` |
| `:invoice_paid` | `invoice.paid` | yes | `customer_id`, `invoice_id` |
| `:invoice_payment_failed` | `invoice.payment_failed` | no | `customer_id`, `invoice_id`, `hosted_invoice_url` |
| `:subscription_canceled` | `customer.subscription.deleted` | no | `customer_id`, `subscription_id` |
| `:subscription_paused` | `customer.subscription.updated` (paused) | no | `customer_id`, `subscription_id` |
| `:subscription_resumed` | `customer.subscription.updated` (resumed) | no | `customer_id`, `subscription_id` |
| `:refund_issued` | `charge.refunded` | no | `customer_id`, `refund_id`, `charge_id` |
| `:coupon_applied` | `Accrue.Billing.apply_coupon/3` (action) | no | `customer_id`, `coupon_id` |
| `:card_expiring_soon` | cron (`Accrue.Jobs.DetectExpiringCards`) | no | `customer_id`, `payment_method_id` |

**Scalar-only assigns** (D-27): pass IDs, not `%Ecto.Schema{}` structs.
The worker rehydrates entities at delivery time. `Accrue.Mailer.Default`
raises `ArgumentError` on non-scalar values to fail loud at the call
site.

## Override ladder

Accrue follows a Pay-inspired three-rung override ladder for template
customization (D-23):

### Rung 1 — per-type kill switch

```elixir
config :accrue, :emails,
  trial_ending: false
```

`Accrue.Mailer.deliver(:trial_ending, ...)` short-circuits with
`{:ok, :skipped}` before any adapter dispatch.

### Rung 2 — MFA conditional module

```elixir
config :accrue, :email_overrides,
  receipt: {MyApp.TemplatePicker, :pick, []}
```

At render time the worker calls
`MyApp.TemplatePicker.pick(:receipt)`. Extra args are passed through:
`{Mod, :fun, [arg1, arg2]}` becomes `Mod.fun(:receipt, arg1, arg2)`.
Return a module implementing the same `subject/1`, `render/1`, and
`render_text/1` contract as the default template.

### Rung 3 — atom module swap

```elixir
config :accrue, :email_overrides,
  receipt: MyApp.Emails.CustomReceipt
```

The override module replaces the default `Accrue.Emails.Receipt`
entirely. It must implement:

```elixir
@callback subject(map()) :: String.t()
@callback render(map()) :: String.t()
@callback render_text(map()) :: String.t()
```

### Rung 4 — full pipeline replace

```elixir
config :accrue, :mailer, MyApp.Mailer
```

Point `:mailer` at any module implementing the `Accrue.Mailer`
behaviour. Use this for integrations with non-Swoosh delivery layers
(e.g., a third-party transactional-email SDK that manages its own
templates).

## Testing

Accrue ships a test adapter `Accrue.Mailer.Test` that intercepts
`Accrue.Mailer.deliver/2` calls before Oban enqueue and sends an intent
tuple `{:accrue_email_delivered, type, assigns}` to the calling
process. Use `Accrue.Test.MailerAssertions` for ExUnit assertions:

```elixir
use ExUnit.Case, async: true
use Accrue.Test.MailerAssertions

test "subscribing sends receipt" do
  {:ok, _} = Accrue.Billing.subscribe(customer, "price_monthly")

  assert_email_sent(:receipt, customer_id: customer.id)
end
```

Match keys:

- `:to` — matches `assigns[:to]` or `assigns["to"]`
- `:customer_id` — matches `assigns[:customer_id]`
- `:assigns` — subset match via `Map.take/2`
- `:matches` — 1-arity predicate escape hatch

For tests that need a rendered `%Swoosh.Email{}` body (subject / HTML
assertions), swap to `Accrue.Mailer.Default` + `Swoosh.Adapters.Test`
in that specific test module.

## CAN-SPAM / CASL / GDPR exemption

Accrue's transactional emails do NOT include unsubscribe links. This
is intentional and legally-grounded:

- **CAN-SPAM (US):** transactional messages whose "primary purpose"
  is a transaction the recipient initiated are exempt from the
  unsubscribe requirement.
- **CASL (Canada):** transactional messages are subject to reduced
  obligations — no express consent and no unsubscribe required, but
  sender identification + postal address recommended.
- **GDPR (EU):** transactional emails are based on contract necessity
  (Art. 6(1)(b)) — no opt-in / opt-out required. Postal address
  required for B2B senders under national implementations.

For EU/CA senders set `:branding[:company_address]` — Accrue's boot
check (`warn_company_address_locale_mismatch/0`) logs a warning when
customer locales indicate EU/CA audiences and the address is unset.

### RFC 8058 opt-in (advanced)

Some hosts ship a `list_unsubscribe_url` even on transactional emails
for deliverability reasons (Gmail Promotions tab demotion). Accrue's
templates do NOT add one by default. To opt in, supply
`:list_unsubscribe_url` in the branding config and override the
template rung-3 style to inject the `List-Unsubscribe` header.

## Async dispatch via Oban

Configure `:accrue_mailers` in the host Oban config:

```elixir
config :accrue, Oban,
  repo: MyApp.Repo,
  queues: [
    accrue_mailers: 20,
    accrue_webhooks: 10
  ]
```

Recommended concurrency: 20. **Pitfall 4:** set
`accrue_mailers` concurrency ≤ `chromic_pdf_pool_size` (default 3)
when `:attach_invoice_pdf` is enabled, otherwise invoice emails can
back-pressure the PDF pool. Accrue emits a boot-time warning when
this invariant is violated.

## Localization

Email rendering honors `customer.preferred_locale` and
`customer.preferred_timezone` via the D6-03 precedence ladder:

1. `assigns[:locale]` / `assigns[:timezone]` explicit override
2. `customer.preferred_locale` / `customer.preferred_timezone`
3. `Accrue.Config.default_locale/0` / `Accrue.Config.default_timezone/0`
4. Hardcoded `"en"` / `"Etc/UTC"` fallback

Unknown locales/timezones emit
`[:accrue, :email, :locale_fallback]` and
`[:accrue, :email, :timezone_fallback]` telemetry and fall back to
`"en"` / `"Etc/UTC"`. The worker's `enrich/2` NEVER raises — Pitfall
5 defense.

Override the CLDR backend via `config :accrue, :cldr_backend, MyApp.Cldr`.

## mix accrue.mail.preview

Render every email type with canned fixtures (D6-08):

```bash
# Render all 13 types as HTML + TXT
mix accrue.mail.preview

# Only specific types
mix accrue.mail.preview --only receipt,trial_ending

# Only one format
mix accrue.mail.preview --only receipt --format html
mix accrue.mail.preview --only invoice_finalized --format pdf
```

Output lands in `.accrue/previews/{type}.{html,txt,pdf}`. The
`.accrue/` directory is git-ignored by convention. Paste the HTML into
Litmus/Email on Acid/Gmail/Outlook for visual QA — Accrue does not
ship a headless rendering matrix.

## Pitfall 7 — single dispatch discipline

The webhook reducer (`Accrue.Webhook.DefaultHandler`) is the single
dispatch point for state-change emails in the catalogue. Do NOT call
`Accrue.Mailer.deliver/2` from `Accrue.Billing.*` action modules for
these types — double dispatch causes duplicate emails on webhook
replay.

Exceptions (action-dispatched types):

- `:card_expiring_soon` — dispatched from cron job `Accrue.Jobs.DetectExpiringCards`
- `:coupon_applied` — dispatched from `Accrue.Billing.CouponActions`

The second layer of defense is Oban uniqueness on `Accrue.Workers.Mailer`:

```elixir
unique: [period: 60, fields: [:args, :worker]]
```

A duplicate enqueue within 60 seconds is silently dropped. DO NOT
remove this option — it's the only guard against action + webhook
double-dispatch.
