---
phase: 06
name: email-pdf
status: context-captured
created: 2026-04-15
---

# Phase 6 — Email + PDF — Context

## Goal (from ROADMAP)

Every lifecycle event that should notify the customer sends a branded, responsive transactional email (plain-text + HTML + MJML), and every invoice can render as a branded PDF via ChromicPDF from the **same data + shared HEEx components** that drive the email HTML body — with `Accrue.Mailer.Test` and `Accrue.PDF.Test` adapters for assertion-based testing.

**Requirements covered:** MAIL-02..MAIL-21, PDF-02..PDF-11.

## Prior context

Phase 1 already shipped the skeleton:

- `Accrue.Mailer` behaviour + facade with semantic API `deliver(type, assigns)` (D-21)
- `Accrue.Mailer.Default` — Oban enqueue adapter with scalar-only assigns safety (D-27)
- `Accrue.Mailer.Swoosh` — delivery adapter
- `Accrue.Workers.Mailer` — worker with 4-rung override ladder (D-23 rungs 1 + 3; Phase 6 adds rung 2 MFA conditional)
- `Accrue.Emails.PaymentSucceeded` reference using idiomatic `use MjmlEEx, mjml_template:` (D-22 corrected)
- `Accrue.PDF` behaviour + `ChromicPDF` + `Test` adapters (D-32/D-33/D-34)
- `Accrue.Cldr` backend (ex_money, Cldr.Number)
- Kill switch `:emails` (D-25), telemetry spans (D-28, T-MAIL-02, T-PDF-01)

**Tech stack locked in CLAUDE.md:** `:swoosh ~> 1.25`, `:phoenix_swoosh ~> 1.2`, `:mjml_eex ~> 0.13`, `:chromic_pdf ~> 1.17`, `:ex_money ~> 5.24`, `:nimble_options ~> 1.1`.

## Locked Decisions

### D6-01 — Shared components, format-specific shells

**Phase 6 uses a three-layer rendering architecture**: `Accrue.Invoices.Render` (data hydration) + `Accrue.Invoices.Components` (shared `Phoenix.Component` HEEx) + two format shells — `mjml_eex` for email via `<mj-raw>`, print-CSS HEEx for ChromicPDF. Roadmap SC #2 is refined from "byte-identical layout" to "shared components + shared brand config," because MJML (email-client table soup) and print CSS (`@page`, paginated) are fundamentally different layout engines. The real guarantee is single-source content + brand, not literal output equality.

**Why:** Pay (Rails), Cashier (PHP), and Bling (Elixir) all ship two disconnected code paths — that's the design regret Accrue is closing. Phoenix 1.8 function components are the idiomatic reuse primitive, not templates. `mjml_eex`'s `<mj-raw>` is the official escape hatch for embedding HEEx-rendered HTML inside an MJML responsive shell with zero rework to the Phase 1 pattern.

**File tree added in Phase 6:**
```
accrue/lib/accrue/
  invoices/
    render.ex              # build_assigns(invoice_id) -> map
    components.ex          # Phoenix.Component: invoice_header, line_items, totals, footer
  emails/
    payment_succeeded.ex   # (existing, unchanged)
    invoice_paid.ex        # + 11 more email type modules
    ...
  pdf/
    invoice.ex             # Accrue.PDF.Invoice.render(invoice_id, opts)
    layouts.ex             # print_shell Phoenix.Component with @page CSS

accrue/priv/accrue/templates/
  layouts/
    transactional.mjml.eex
    transactional.heex
  emails/
    payment_succeeded.mjml.eex   # (existing)
    invoice_paid.mjml.eex        # <mj-raw><%= render_component(...) %></mj-raw>
    ...
  pdf/
    invoice.html.heex            # <.print_shell><.invoice_header/>...
    _print.css
```

**Adding a new notification that renders as both:** 1 Component + 1 `.mjml.eex` shell + (if applicable) 1 `.html.heex` pdf shell. ~80 LOC per notification.

**Roadmap action:** update SC #2 wording from "byte-identical in layout" to "visually consistent and brand-coherent, because both render from shared `Accrue.Invoices.Components` and the same `Accrue.Config.branding` source."

**Pitfalls:**
- MJML's `<mj-raw>` bypasses MJML's style inlining — embedded HEEx must inline its own styles via a `brand_style/1` helper reading `Accrue.Config.branding/0`.
- ChromicPDF + webfonts: document base64-embed pattern in the PDF guide.
- Do not let "fix SC#2" attempts render PDFs from MJML output — that's the wrong answer even though it looks literal.

---

### D6-02 — Branding is a nested NimbleOptions-validated `:branding` key

Add a nested `:branding` keyword list under `Accrue.Config` `@schema`. Deprecates the flat keys (`business_name`, `logo_url`, `from_email`, `from_name`, `support_email`, `business_address`) with a one-minor shim. **Not DB-backed. Not layered with runtime DB override in v1.0.** Phase 7 admin UI is **read-only** against branding; editable DB-backed theming is a post-v1.0 feature behind an optional `Accrue.Branding.Adapter` with a default `Config` adapter.

**Schema (to add to `Accrue.Config`):**
```elixir
branding: [
  type: :keyword_list,
  required: false,
  default: [],
  keys: [
    business_name:   [type: :string, default: "Accrue"],
    from_name:       [type: :string, default: "Accrue"],
    from_email:      [type: :string, required: true],
    support_email:   [type: :string, required: true],
    reply_to_email:  [type: {:or, [:string, nil]}, default: nil],
    logo_url:        [type: {:or, [:string, nil]}, default: nil],
    logo_dark_url:   [type: {:or, [:string, nil]}, default: nil],
    accent_color:    [type: {:custom, __MODULE__, :validate_hex, []}, default: "#1F6FEB"],
    secondary_color: [type: {:custom, __MODULE__, :validate_hex, []}, default: "#6B7280"],
    font_stack:      [type: :string,
                      default: ~s(-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif)],
    company_address: [type: {:or, [:string, nil]}, default: nil,
                      doc: "Postal address for CAN-SPAM footer. Optional; recommended for EU/CA senders."],
    support_url:     [type: {:or, [:string, nil]}, default: nil],
    social_links:    [type: :keyword_list, default: []],
    list_unsubscribe_url: [type: {:or, [:string, nil]}, default: nil,
                           doc: "Opt-in RFC 8058 List-Unsubscribe header. Point at a real preferences page."]
  ]
]
```

Add `Accrue.Config.branding/0` and `Accrue.Config.branding(key)` helpers. Add `validate_hex/1` sibling to `validate_descending/1`.

**Connect verdict:** Platform brand always wins. Connect connected accounts inherit the platform's `:branding`. No per-account override in v1.0 — that's a post-v1.0 adapter surface if demand materializes. Document explicitly.

**Why:** NimbleOptions is the single validation surface across Accrue. DB-backed would force Accrue to own a migration + schema + cache for data that changes ~never. Every first-tier billing library (Pay, Cashier, Bling) keeps brand in host config — precedent is overwhelming.

---

### D6-03 — Per-customer locale + timezone columns, deliver-time override allowed

Add `preferred_locale :string` and `preferred_timezone :string` (both nullable) to `accrue_customers`. Resolve in `Accrue.Workers.Mailer.enrich/2` with precedence **caller assigns > customer column > application default > hardcoded (`"en"` / `"Etc/UTC"`)**. Unknown/unsupported locales log `[:accrue, :email, :locale_fallback]` telemetry and fall back to `"en"` — **never raise**.

**Migration:**
```elixir
defmodule Accrue.Repo.Migrations.AddLocaleAndTimezoneToCustomers do
  use Ecto.Migration

  def change do
    alter table(:accrue_customers) do
      add :preferred_locale,   :string, size: 35  # BCP-47 max practical
      add :preferred_timezone, :string, size: 64  # IANA max 64
    end
  end
end
```

`Accrue.Billing.Customer` gains `field :preferred_locale, :string` and `field :preferred_timezone, :string` added to `@cast_fields`. No `validate_inclusion` — the library can't know which locales the host's CLDR backend compiled in.

**CLDR backend:** `Accrue.Cldr` stays at `locales: ["en"]` default. Document escape hatch: `config :accrue, :cldr_backend, MyApp.Cldr`.

**Timezone database:** Do not hard-require `:tz` or `:tzdata`. Document in install guide: "Configure a `Calendar.TimeZoneDatabase` in your host app (`:tz` recommended). Missing TZDB causes non-UTC timestamps to fall back to `Etc/UTC` with a telemetry warning." Wrap `DateTime.shift_zone/2` with rescue → `Etc/UTC`.

**Stripe / Pay lesson:** Cashier's pre-2022 "`App.setLocale()` before `->sendInvoice()`" pattern was the #1 support thread source — don't replicate.

---

### D6-04 — Lazy render on demand, no storage in v1.0

`Accrue.Billing.render_invoice_pdf(invoice, opts)` always re-renders from current DB + branding state. **Accrue persists zero PDF bytes in v1.0.** A thin `Accrue.Storage` behaviour is scaffolded with a `Null` adapter wired as the default; `Filesystem` adapter lands in v1.1, S3 is host-owned (companion lib or host code). **No new columns on `accrue_invoices`.**

**Primary API:**
```elixir
@spec render_invoice_pdf(Invoice.t() | id, keyword()) :: {:ok, binary()} | {:error, term()}
Accrue.Billing.render_invoice_pdf(invoice, archival: false, locale: "en")

@spec store_invoice_pdf(Invoice.t()) :: {:ok, key :: String.t()} | {:error, term()}
Accrue.Billing.store_invoice_pdf(invoice)  # no-op on Null

Accrue.Billing.fetch_invoice_pdf(invoice)  # {:error, :not_configured} on Null
```

**Storage behaviour:**
```elixir
defmodule Accrue.Storage do
  @callback put(key :: String.t(), binary(), meta :: map()) :: {:ok, String.t()} | {:error, term()}
  @callback get(key :: String.t()) :: {:ok, binary()} | {:error, term()}
  @callback delete(key :: String.t()) :: :ok | {:error, term()}
end
```
Bundled: `Accrue.Storage.Null` (v1.0 default). `Accrue.Storage.Filesystem` ships in v1.1. Key scheme: `"invoices/#{invoice.id}.pdf"` — derived, not stored.

**`invoice.finalized` webhook does NOT trigger a render.** The handler updates `finalized_at` + `pdf_url` (Stripe URL) + `hosted_url` and enqueues the `Accrue.Mail.InvoiceFinalized` Oban job. That job calls `render_invoice_pdf/1` synchronously and attaches the binary to the Swoosh email. If `Accrue.PDF.Null` is configured, the email ships without an attachment and includes the Stripe `hosted_invoice_url` as a link (graceful degradation satisfies SC #4).

**Performance posture:** Document host recommendation — dev/test `{ChromicPDF, on_demand: true}`, prod `{ChromicPDF, session_pool: [size: 3]}`. Bump to 10 for bursty monthly-billing runs. Ensure `accrue_mailers` Oban queue concurrency ≤ ChromicPDF pool size.

**Safety net:** Facade wraps `Process.whereis(ChromicPDF) == nil` → `{:error, :chromic_pdf_not_started}` with clear message.

**Audit retention note:** Lazy + branded retroactive-change is explicitly by design — SC #2 requires it. Hosts with regulated retention should wire `Accrue.Storage.Filesystem` + a cron calling `store_invoice_pdf/1` on finalize, and keep branding config under version control. Documented in the PDF guide.

---

### D6-05 — `Accrue.Mailer.Test` is a behaviour-layer adapter

`Accrue.Mailer.Test` replaces `Accrue.Mailer.Default` at the behaviour layer — intercepts `Accrue.Mailer.deliver/2` **before** Oban enqueue. `deliver(type, assigns)` sends `{:accrue_email_delivered, type, assigns}` to `self()` and returns `{:ok, :test}`. Symmetric with `Accrue.PDF.Test` (D-34) which sends `{:pdf_rendered, html, opts}`. Assertions live in `Accrue.Test.MailerAssertions`.

**Assertion API:**
```elixir
assert_email_sent(type)
assert_email_sent(type, opts)                   # opts :: [to: _, customer_id: _, assigns: map, matches: fn]
assert_email_sent(type, opts, timeout)          # default 100ms
refute_email_sent(type)
refute_email_sent(type, opts)
assert_no_emails_sent()
assert_emails_sent(count)
```

**Matching rules:** `:to` matches `assigns[:to] || assigns["to"]`; `:customer_id` matches `assigns[:customer_id]`; `:assigns` is a subset match via `Map.take/2`; `:matches` is an arbitrary 1-arg fn escape hatch.

**Oban interaction:** Test adapter sidesteps Oban entirely — no queue to drain, no `:inline` mode required, no render pipeline exercised. For tests that need the rendered `%Swoosh.Email{}` body (subject string assertions, attachment checks), swap to `Accrue.Mailer.Default` + `Swoosh.Adapters.Test` in that specific test module. Document this one sentence in the testing guide.

**Wired in `config/test.exs`:** `config :accrue, :mailer, Accrue.Mailer.Test`.

**Why:** Accrue's Mailer API is semantic by design (D-21). Tests should assert at the same layer — on the intent (`:receipt`) + assigns, not on rendered HTML that would couple tests to template internals. Mirrors the `Accrue.PDF.Test` pattern exactly.

---

### D6-06 — `Accrue.PDF.Null` returns `{:error, %Accrue.Error.PdfDisabled{}}`

Matches the existing `Accrue.Error.*` struct taxonomy (`NotAttached`, `InvalidState`, `NoDefaultPaymentMethod`, etc.) — a `defexception` struct with `:reason` and `:docs_url` fields, raisable AND pattern-matchable. Fits the existing `@callback render(html(), opts()) :: {:ok, binary()} | {:error, term()}` contract.

**Shape:**
```elixir
defmodule Accrue.Error.PdfDisabled do
  defexception [:reason, :docs_url, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(_), do: "PDF rendering disabled on this Accrue instance (Accrue.PDF.Null configured)"
end

defmodule Accrue.PDF.Null do
  @behaviour Accrue.PDF
  require Logger

  @impl true
  def render(_html, _opts) do
    Logger.debug("Accrue.PDF.Null: skipping PDF render (adapter disabled)")
    {:error,
     %Accrue.Error.PdfDisabled{
       reason: :adapter_disabled,
       docs_url: "https://hexdocs.pm/accrue/pdf.html#null-adapter"
     }}
  end
end
```

**Invoice email worker fallback rule:**
```elixir
case Accrue.PDF.render(html, size: :a4) do
  {:ok, pdf} -> Swoosh.Email.attachment(email, %Swoosh.Attachment{...pdf...})
  {:error, %Accrue.Error.PdfDisabled{}} -> append_hosted_invoice_link(email, invoice.hosted_invoice_url)
  {:error, other} -> raise Accrue.PDF.RenderFailed, reason: other
end
```

`PdfDisabled` is **expected and terminal** — no Oban retry, no crash. Any other `{:error, _}` re-raises so Oban backoff handles transient failures. The email pipeline **cannot crash on `PdfDisabled`**.

**Log level:** `:debug` — host opted in explicitly via config; `:info`/`:warning` would spam logs for a deliberate configuration choice.

**Rejected alternatives:** bare `:pdf_unavailable` atom (inconsistent with taxonomy), `raise Accrue.PDF.Disabled` (breaks behaviour contract, crashes Oban workers), placeholder binary (compliance hazard — must never silently substitute invoice content), `{:ok, text_fallback}` (violates `binary() == PDF` semantic, MIME-type confusion).

---

### D6-07 — Transactional footer: address + support optional, no unsubscribe

All 13+ email types are 100% transactional under CAN-SPAM, CASL, and GDPR — exemption applies cleanly. Safe defaults: shared `layouts/transactional.{heex,mjml.eex}` footer partial always renders `business_name` + `support_email`, conditionally renders `company_address` when the host has supplied one. **Never renders an unsubscribe link** (exempt). `List-Unsubscribe` + `List-Unsubscribe-Post: List-Unsubscribe=One-Click` (RFC 8058) opt-in via the `:branding` schema's `list_unsubscribe_url` key — **off by default** because pointing it at a non-functional URL harms deliverability more than omitting it.

**Consistency beats per-template optimization:** payment_failed and trial_ending use the same footer as receipt — no per-template `@transactional_footer?` flag. Footer is visually de-emphasized below the primary CTA anyway.

**Config validator:** Warn (don't fail) in `Accrue.Config` start-up when `:company_address` is nil and any `accrue_customers.preferred_locale` begins with `fr`, `de`, `nl`, `en-GB`, `en-CA`, etc. (deferred to start-up telemetry, not compile).

**Docs line for the user guide:** "Accrue emails are transactional under CAN-SPAM and CASL, which exempts them from unsubscribe and physical-address requirements. We render `business_name` and `support_email` on every email, and `company_address` when you configure it — recommended if you send to EU or Canadian recipients. `list_unsubscribe_url` is opt-in once you have a real preferences page."

---

### D6-08 — Phase 6 ships `mix accrue.mail.preview`; Phase 7 adds the LiveView admin preview route

**Phase 6 (this phase):**
- `mix accrue.mail.preview [--only receipt,payment_failed] [--format html|pdf|both]` — renders every email type with canned fixtures and writes `.accrue/previews/{type}.{html,txt,pdf}` (git-ignored).
- `Accrue.Emails.Fixtures` — single module of canned assigns (one function per email type). Shared between the mix task, unit tests, and (later) Phase 7 LiveView preview.
- Add `.accrue/` to the `mix accrue.install` generated `.gitignore`.
- **Does not** reimplement `Swoosh.Adapters.Local` / `/dev/mailbox` — document that as host-owned integration-test wiring in the testing guide.

**Phase 7 handoff:**
- `AccrueAdmin.EmailPreviewLive` mounted at `/billing/_dev/emails/:type` imports `Accrue.Emails.Fixtures` and calls the same renderers — zero duplication, no rewrite.

**Why split this way:** The mix task is the only preview shape that works in Phase 6 — no router, no LiveView, no auth, no Oban round-trip. It directly exercises the "single HEEx → email + PDF" invariant from D6-01 using real branding config + `Phoenix.Component` calls. Swoosh's `/dev/mailbox` shows sent email but never PDFs; the mix task covers the full render surface. Phase 7's LiveView route is the richer UX when the admin mount exists, and it can reuse the fixture module for free.

---

## Deferred / out of scope (for v1.1+)

- **Editable DB-backed branding** via `Accrue.Branding.Adapter` with an `Ecto` adapter. v1.0 stays config-only.
- **`Accrue.Storage.Filesystem` + `Accrue.Storage.S3`** adapters. v1.0 ships `Null` only + the behaviour.
- **Per-connected-account brand overrides** for Stripe Connect platforms. No per-account theming in v1.0.
- **Rich email preview UI in `accrue_admin`** LiveView. v1.0 ships the mix task; Phase 7 adds the LiveView route.
- **Multi-locale CLDR backend** pre-compiled by default. v1.0 stays `locales: ["en"]`; hosts override via `config :accrue, :cldr_backend, MyApp.Cldr`.
- **`preferred_locales` as an array** on customer (Stripe's shape). v1.0 ships a single string; widen later without migration pain.

## Open items for Researcher / Planner

- Inventory the **13+ email types** against Phase 2/3/4 webhook events and name each one explicitly (receipt, payment_failed, trial_ending, trial_ended, invoice_finalized, invoice_paid, invoice_payment_failed, subscription_canceled, subscription_paused, subscription_resumed, refund_issued, coupon_applied, plus multipart variants). Researcher confirms requirement-to-type mapping; Planner groups into waves.
- **MFA override ladder rung 2** (`:emails` value as `{Mod, :fun, args}`) — land in `Accrue.Workers.Mailer.resolve_template/1` alongside rung 3.
- **Font strategy for PDFs** — base64-embed vs host-served `file://`. Research phase reads ChromicPDF docs and recommends.
- **Page-break + long-invoice behavior** for invoices with >20 line items — CSS `page-break-inside: avoid` per line row vs per section.
- **Config migration for the 6 deprecated flat branding keys** — one-minor shim + boot-time deprecation log; remove pre-1.0.

## Next step

`/gsd-plan-phase 06-email-pdf` — planner consumes this CONTEXT + RESEARCH.md (to be produced by phase-researcher) and produces wave-ordered plans.
