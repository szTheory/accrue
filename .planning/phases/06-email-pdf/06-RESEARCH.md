# Phase 6: Email + PDF — Research

**Researched:** 2026-04-15
**Domain:** Transactional email pipeline + invoice PDF rendering (Elixir/Phoenix/Swoosh/ChromicPDF)
**Confidence:** HIGH for stack + adapter shapes (Phase 1 scaffolding, verified via Hex.pm + code read). MEDIUM for the HEEx↔MJML bridge (the most nuanced piece — mjml_eex does not natively understand Phoenix.Component; we adapt). MEDIUM for ChromicPDF PDF/A + font strategy (requires runtime environment choices).

## Summary

Phase 6 is the biggest requirement-count phase in the roadmap (30 reqs: MAIL-02..21 + PDF-02..11) but is **not** starting from zero. Phase 1 already shipped `Accrue.Mailer` behaviour + `Default`/`Swoosh`/`Test` surface, `Accrue.PDF` behaviour + `ChromicPDF`/`Test` adapters, `Accrue.Workers.Mailer` Oban worker with a 4-rung override ladder (rungs 1 + 3 done), a reference `Accrue.Emails.PaymentSucceeded` module wired via the idiomatic `use MjmlEEx, mjml_template:` pattern, and the `Accrue.Cldr` backend. The locked Phase 1 decisions (D-21..D-34) plus the eight Phase 6 decisions (D6-01..D6-08) in `06-CONTEXT.md` constrain this work tightly.

The single hardest technical question is **how the "shared HEEx template" contract in MAIL-14 / PDF-05 is actually delivered**. Investigation reveals a subtlety: `mjml_eex` is **not** based on `Phoenix.Component`. Its own `MjmlEEx.Component` behaviour uses string-concatenated render functions, not HEEx. So literal "single HEEx template drives both email and PDF" is impossible at the file level — D6-01 already acknowledges this and correctly refines SC #2 to "shared components + shared brand config, two format shells." The research here confirms that's the only defensible path and pins down the exact bridge (`Phoenix.LiveView.HTMLEngine.component_to_iodata/3` → safe-HTML-string → `<mj-raw>` inside mjml_eex). Every Phase 6 plan flows from that decision.

The second hardest question is **rendering the 13 email types as 13 finished deliverables on a tight phase timeline**. Most of the required work per email type is mechanical once the component library + render-context struct + test adapter are in place (~80 LoC per type, per D6-01). The critical-path waves are: (1) branding config refactor + render-context struct + Phase 1 worker extensions, (2) shared `Accrue.Invoices.Components` library + PDF shell + MJML shell layouts, (3) the 13 email-type modules in parallel, (4) Oban dispatch wiring from domain events + test adapter + mix preview task.

**Primary recommendation:** Build Phase 6 as 6 waves: Config/Branding → Render Context + Components → Layout Shells → Email Type Modules (parallel) → Dispatch Wiring + Test Adapters → Preview Mix Task + Documentation. Treat D6-01's three-layer rendering architecture as non-negotiable; every other decision follows from it.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**D6-01 — Shared components, format-specific shells (three-layer rendering architecture).**
Three layers: `Accrue.Invoices.Render` (data hydration → `%Accrue.Invoices.RenderContext{}`-ish map), `Accrue.Invoices.Components` (shared `Phoenix.Component` HEEx function components), plus two format shells — `mjml_eex` for email (HEEx rendered to HTML string, embedded via `<mj-raw>`), print-CSS HEEx for ChromicPDF. **Roadmap SC #2 refined from "byte-identical" to "visually consistent, brand-coherent, shared components + branding config."** MJML's `<mj-raw>` bypasses MJML style inlining — embedded HEEx must inline its own styles via a `brand_style/1` helper reading `Accrue.Config.branding/0`. Never render PDFs from MJML output.

**D6-02 — Branding is a nested NimbleOptions-validated `:branding` key.**
Add nested `:branding` keyword list under `Accrue.Config` `@schema`. Deprecates flat keys (`business_name`, `logo_url`, `from_email`, `from_name`, `support_email`, `business_address`) with a one-minor shim. **Not DB-backed in v1.0.** Phase 7 admin UI is read-only against branding. Schema keys: `business_name`, `from_name`, `from_email` (required), `support_email` (required), `reply_to_email`, `logo_url`, `logo_dark_url`, `accent_color` (hex validator), `secondary_color` (hex validator), `font_stack`, `company_address`, `support_url`, `social_links`, `list_unsubscribe_url`. Add `Accrue.Config.branding/0` + `branding(key)` helpers + `validate_hex/1` custom validator. **Connect verdict:** platform brand always wins; no per-connected-account override in v1.0.

**D6-03 — Per-customer locale + timezone columns; deliver-time override allowed.**
Add `preferred_locale :string (size 35)` + `preferred_timezone :string (size 64)` to `accrue_customers`. Resolve in `Accrue.Workers.Mailer.enrich/2` with precedence **caller assigns > customer column > application default > hardcoded (`"en"` / `"Etc/UTC"`)**. Unknown locales log `[:accrue, :email, :locale_fallback]` telemetry and fall back — **never raise**. CLDR backend stays `locales: ["en"]`; host overrides via `config :accrue, :cldr_backend, MyApp.Cldr`. TZ database not hard-required; wrap `DateTime.shift_zone/2` with rescue → `Etc/UTC` + telemetry.

**D6-04 — Lazy render on demand; no PDF storage in v1.0.**
`Accrue.Billing.render_invoice_pdf(invoice, opts)` always re-renders from current DB + branding. Zero PDF bytes persisted in v1.0. `Accrue.Storage` behaviour scaffolded with `Null` default; `Filesystem` adapter lands in v1.1. **No new columns on `accrue_invoices`.** `invoice.finalized` webhook does NOT trigger a render — handler updates `finalized_at`/`pdf_url`/`hosted_url` and enqueues `Accrue.Mail.InvoiceFinalized` Oban job, which calls `render_invoice_pdf/1` synchronously at delivery time. On `Accrue.PDF.Null`, email ships without attachment + Stripe `hosted_invoice_url` link (graceful SC #4 degradation). Host guidance: dev/test `{ChromicPDF, on_demand: true}`; prod `session_pool: [size: 3]`; ensure `accrue_mailers` Oban queue concurrency ≤ ChromicPDF pool size. Facade wraps `Process.whereis(ChromicPDF) == nil` → `{:error, :chromic_pdf_not_started}`.

**D6-05 — `Accrue.Mailer.Test` is a behaviour-layer adapter.**
Replaces `Accrue.Mailer.Default` at the behaviour layer; intercepts `Accrue.Mailer.deliver/2` **before** Oban enqueue. `deliver(type, assigns)` sends `{:accrue_email_delivered, type, assigns}` to `self()` and returns `{:ok, :test}`. Symmetric with `Accrue.PDF.Test` (D-34, already in Phase 1). Assertions in `Accrue.Test.MailerAssertions`: `assert_email_sent/1..3`, `refute_email_sent/1..2`, `assert_no_emails_sent/0`, `assert_emails_sent/1`. Matching: `:to`, `:customer_id`, `:assigns` (subset via `Map.take/2`), `:matches` (1-arity fn). Test adapter sidesteps Oban entirely — no queue drain, no render exercised. For tests asserting on rendered Swoosh `%Email{}` bodies, document the escape hatch: swap to `Accrue.Mailer.Default` + `Swoosh.Adapters.Test` in that specific test module. Wire `config :accrue, :mailer, Accrue.Mailer.Test` in `config/test.exs`.

**D6-06 — `Accrue.PDF.Null` returns `{:error, %Accrue.Error.PdfDisabled{}}`.**
Matches existing `Accrue.Error.*` taxonomy — `defexception` struct with `:reason` + `:docs_url` + `:message` fields, raisable AND pattern-matchable. Fits existing `@callback render(html(), opts()) :: {:ok, binary()} | {:error, term()}`. Invoice email worker fallback rule: match `{:error, %Accrue.Error.PdfDisabled{}}` → append `hosted_invoice_url` link; other errors re-raise `Accrue.PDF.RenderFailed` so Oban backoff handles transients. **`PdfDisabled` is expected + terminal — no Oban retry, no crash.** Log level `:debug`. Rejected: bare atoms, raise-in-adapter (breaks behaviour), placeholder binary (compliance hazard), `{:ok, text_fallback}` (MIME confusion).

**D6-07 — Transactional footer: address + support optional, no unsubscribe.**
All 13+ email types transactional under CAN-SPAM/CASL/GDPR — exemption applies. Shared `layouts/transactional.{heex,mjml.eex}` footer always renders `business_name` + `support_email`, conditionally renders `company_address` when host supplied. **Never renders an unsubscribe link.** `List-Unsubscribe` + `List-Unsubscribe-Post: List-Unsubscribe=One-Click` (RFC 8058) opt-in via `branding.list_unsubscribe_url` — off by default. Config validator: warn (don't fail) at boot when `company_address` nil AND any `accrue_customers.preferred_locale` starts with `fr`, `de`, `nl`, `en-GB`, `en-CA`.

**D6-08 — Phase 6 ships `mix accrue.mail.preview`; Phase 7 adds LiveView admin preview route.**
`mix accrue.mail.preview [--only types] [--format html|pdf|both]` renders every email type with canned fixtures → `.accrue/previews/{type}.{html,txt,pdf}` (git-ignored). `Accrue.Emails.Fixtures` — single module of canned assigns (one function per type). Does NOT reimplement `Swoosh.Adapters.Local` / `/dev/mailbox` (document as host-owned). Phase 7 handoff: `AccrueAdmin.EmailPreviewLive` mounted at `/billing/_dev/emails/:type` imports `Accrue.Emails.Fixtures` and calls the same renderers.

### Claude's Discretion

- **Font strategy for PDFs** — base64-embed vs host-served `file://`. Researcher/planner recommendation below.
- **Page-break + long-invoice behavior** for >20 line items — CSS tactic selection.
- **Config migration for 6 deprecated flat branding keys** — one-minor shim shape + boot-time deprecation log.
- **MFA override ladder rung 2** (`:emails` value `{Mod, :fun, args}`) — must land in `Accrue.Workers.Mailer.resolve_template/1` alongside rung 3.
- **13 email type grouping into waves** — planner discretion informed by the requirement-to-trigger map below.
- **Plain-text generation strategy** — separate `.text.eex` template (current Phase 1 precedent) vs Floki-strip of rendered HTML vs hybrid.

### Deferred Ideas (OUT OF SCOPE — v1.1+)

- Editable DB-backed branding via `Accrue.Branding.Adapter` + `Ecto` adapter.
- `Accrue.Storage.Filesystem` + `Accrue.Storage.S3` adapters (v1.0 ships `Null` + behaviour only).
- Per-connected-account brand overrides for Stripe Connect platforms.
- Rich email preview UI in `accrue_admin` LiveView (v1.0 ships mix task; Phase 7 adds the route).
- Multi-locale CLDR backend pre-compiled by default (stays `locales: ["en"]`).
- `preferred_locales` as array (v1.0 ships single string; widen later without migration pain).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAIL-02 | `Mailer.Test` adapter for `assert_email_sent/1` | D6-05 behaviour-layer adapter; `Accrue.Test.MailerAssertions` API documented below |
| MAIL-03 | Email: `receipt` (payment succeeded) | Phase 1 `Accrue.Emails.PaymentSucceeded` reference exists; extend to full render context |
| MAIL-04 | Email: `payment_failed` with retry guidance | Domain event `charge.failed` / `invoice.payment_failed`; email catalogue entry |
| MAIL-05 | Email: `trial_ending` (3 days before) | `trial_will_end` webhook already wired in Phase 3; enqueue mailer from webhook reducer |
| MAIL-06 | Email: `trial_ended` | `subscription.trial_ended` state transition in Phase 3 |
| MAIL-07 | Email: `invoice_finalized` with optional PDF attachment | D6-04: handler enqueues mailer job; job calls `render_invoice_pdf/1` sync + attaches |
| MAIL-08 | Email: `invoice_paid` | `invoice.paid` webhook reducer exists; enqueue mailer |
| MAIL-09 | Email: `invoice_payment_failed` with payment action link | `invoice.payment_failed` reducer; link uses `invoice.hosted_invoice_url` |
| MAIL-10 | Email: `subscription_canceled` | `subscription.deleted` reducer; existing `subscription_canceled` event schema |
| MAIL-11 | Email: `subscription_paused` / `subscription_resumed` | Phase 4 pause/resume actions already emit events |
| MAIL-12 | Email: `refund_issued` with fee breakdown | Phase 3 `refund_created` event; render `merchant_loss_amount` + `stripe_fee_refunded_amount` |
| MAIL-13 | Email: `coupon_applied` | Phase 4 `coupon.applied` event; renders discount amount + promo code |
| MAIL-14 | HEEx templates shared between email HTML body and invoice PDF | D6-01 three-layer architecture; `Accrue.Invoices.Components` is the shared surface |
| MAIL-15 | Plain-text AND HTML multipart mandatory | Phase 1 `render_text/1` precedent; per-type `.text.eex` sibling template |
| MAIL-16 | Single-point branding config | D6-02 nested `:branding` schema |
| MAIL-17 | Per-template override for full customization | Phase 1 D-23 rung 3 (`:email_overrides`); Phase 6 adds rung 2 (MFA) |
| MAIL-18 | MJML via `mjml_eex` for responsive templates | Phase 1 precedent via `use MjmlEEx, mjml_template:` |
| MAIL-19 | Outlook MSO conditional block compatibility | MJML handles Outlook 2007-2016 conditional VML/MSO fallbacks at compile time (built-in) |
| MAIL-20 | Async email sending via Oban | Phase 1 `Accrue.Workers.Mailer` + `accrue_mailers` queue already wired |
| MAIL-21 | CLDR localization (currency + date formatting) | D6-03 per-customer locale; `Accrue.Cldr` + `ex_money` + `Cldr.DateTime` |
| PDF-02 | `Accrue.PDF.ChromicPDF` default adapter | Phase 1 scaffold already in place; Phase 6 adds content pipeline |
| PDF-03 | `Accrue.PDF.Test` for assertion testing | Phase 1 adapter sends `{:pdf_rendered, html, opts}`; add `Accrue.Test.PdfAssertions` |
| PDF-04 | `Accrue.PDF.Null` for Chrome-hostile deploys | D6-06 shape; returns `{:error, %Accrue.Error.PdfDisabled{}}` |
| PDF-05 | Invoice PDF shared HEEx with email | D6-01; realized by `Accrue.Invoices.Components` not template files |
| PDF-06 | Branded PDF inheriting Mailer branding config | D6-02 `Accrue.Config.branding/0` is single source; both shells call `brand_style/1` |
| PDF-07 | PDF download route helper | `AccrueAdmin` concern in Phase 7; core exposes `render_invoice_pdf/2` + stream helper doc |
| PDF-08 | PDF attachment on email helpers | D6-04 `Accrue.Mail.InvoiceFinalized` worker; `Swoosh.Email.attachment/2` with `%Swoosh.Attachment{}` |
| PDF-09 | Async PDF render via Oban with cache | D6-04: render is sync inside the mailer job; "cache" = no separate cache layer in v1.0 (lazy re-render), documented |
| PDF-10 | Timezone + locale threading through render context | D6-03 precedence ladder; `%Accrue.Invoices.RenderContext{locale, timezone}` field |
| PDF-11 | Gotenberg sidecar as custom adapter path | Guide page only; no first-party adapter (CLAUDE.md §Alternatives Considered) |

## Architectural Responsibility Map

Accrue is a headless billing library — there is no browser tier in core. The relevant "tiers" are the rendering pipeline stages.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Domain-event → email dispatch | Webhook reducers (Phase 3/4 default handler) + `Accrue.Billing.*` action modules | Oban worker (`Accrue.Workers.Mailer`) | Events and actions already own the "when"; mailer worker owns the "how" (D-21 semantic API) |
| Assign hydration (id → full data) | `Accrue.Invoices.Render` (new in P6) | `Accrue.Workers.Mailer.enrich/2` | Worker does locale/TZ enrichment; Render module does DB fetches + decimal math |
| Shared layout components | `Accrue.Invoices.Components` (Phoenix.Component) | `Accrue.Invoices.Layouts` for page shells | Components are the single format-neutral content source (D6-01) |
| Email HTML rendering | `use MjmlEEx, mjml_template:` modules per type | `Phoenix.LiveView.HTMLEngine.component_to_iodata/3` (HEEx→string bridge) | mjml_eex owns responsive email; HEEx bridge embeds shared components via `<mj-raw>` |
| Plain-text rendering | Per-type `.text.eex` template | `Accrue.Emails.<Type>.render_text/1` | Matches Phase 1 precedent; Floki-strip would over-format and break CLDR money formatting |
| PDF rendering | `Accrue.PDF.ChromicPDF` adapter | `Accrue.Invoices.Layouts.print_shell/1` HEEx component | Adapter owns binary; print shell owns `@page`-adjacent CSS and component assembly |
| Config + branding | `Accrue.Config` NimbleOptions schema (runtime) | `Accrue.Config.branding/0` helper | Single source of truth for brand across email + PDF (D6-02) |
| Locale + timezone resolution | `Accrue.Workers.Mailer.enrich/2` | `Accrue.Billing.Customer` columns | Worker applies precedence ladder; customer columns are one tier of the ladder (D6-03) |
| Dev/preview rendering | `mix accrue.mail.preview` task | `Accrue.Emails.Fixtures` module | Task is the only viable preview in a headless lib; fixtures module is reused by Phase 7 LiveView |
| Test assertion surface | `Accrue.Mailer.Test` + `Accrue.PDF.Test` adapters | `Accrue.Test.MailerAssertions` + `Accrue.Test.PdfAssertions` | D6-05 behaviour-layer swap avoids Oban plumbing in tests |

## Standard Stack

All versions already pinned in `accrue/mix.exs` (verified at `accrue/mix.exs:47-62`) and **re-verified** against Hex.pm API 2026-04-15:

### Core (already declared)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:swoosh` | `~> 1.25` | Email delivery | Hex confirms **1.25.0** (current). Phoenix's default mailer since 1.6. `[VERIFIED: hex.pm/packages/swoosh 2026-04-15]` |
| `:phoenix_swoosh` | `~> 1.2` | HEEx rendering for emails | Hex confirms **1.2.1**. Provides `render_body/3` and `new_email/1` — though mjml_eex sidesteps `render_body` for the HTML body (see Architecture Patterns). `[VERIFIED: hex.pm]` |
| `:mjml_eex` | `~> 0.13` | Responsive email via MJML | Hex confirms **0.13.0**. Rustler NIF (default) + Node fallback. **NOT HEEx-based** — uses its own `MjmlEEx.Component` behaviour with string render output. `[VERIFIED: hex.pm + hexdocs.pm/mjml_eex/readme.html]` |
| `:chromic_pdf` | `~> 1.17` | Default PDF adapter | Hex confirms **1.17.1** (2026-03-19). Requires Chrome/Chromium on host; Ghostscript only when `print_to_pdfa/1` used. **`@page` CSS NOT interpreted** — use Chromium paper-size options instead. `[VERIFIED: hex.pm + hexdocs.pm/chromic_pdf/ChromicPDF.html]` |
| `:ex_money` | `~> 5.24` | Money value type + formatting | Hex confirms **5.24.2**. Backed by `Accrue.Cldr`. Formatting via `Money.to_string/2` with `:locale` option. `[VERIFIED: hex.pm + accrue/lib/accrue/cldr.ex]` |
| `:nimble_options` | `~> 1.1` | Config schema | Needs `:branding` nested keyword_list validator + custom `validate_hex/1`. Already validated for other nested schemas (e.g., `:dunning`, `:connect`). `[VERIFIED: accrue/lib/accrue/config.ex]` |
| `:telemetry` | `~> 1.3` | Event instrumentation | `[:accrue, :mailer, :deliver, :*]` and `[:accrue, :pdf, :render, :*]` spans already wired in Phase 1. `[VERIFIED]` |
| `:oban` | `~> 2.21` | Async email queue | `accrue_mailers` queue + `Accrue.Workers.Mailer` already wired (`accrue/lib/accrue/workers/mailer.ex`). `[VERIFIED]` |

### Supporting (already in ex_money's CLDR stack)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:ex_cldr` | `~> 2.47` | CLDR backend | Already loaded via `ex_money`. Backend module is `Accrue.Cldr`. `[VERIFIED: hex.pm 2.47.2 + accrue/lib/accrue/cldr.ex]` |
| `:ex_cldr_numbers` | transitive | Number formatting | Provider already declared in `Accrue.Cldr` (`providers: [Cldr.Number, Money]`). No additional dep. `[CITED: accrue/lib/accrue/cldr.ex:15]` |
| `:ex_cldr_dates_times` | **NOT YET DECLARED** | Date/time formatting per locale | **Phase 6 must add** if MAIL-21 date formatting is required. Add as optional transitive once locale > `"en"`. Alternative: `Calendar.strftime/2` for English-only v1.0. `[ASSUMED: planner decision]` |

### No new required deps for Phase 6

This is a green flag. All rendering libraries already live in `mix.exs`. The only candidate new dep is `:ex_cldr_dates_times` **if** the planner decides MAIL-21 date formatting requires more than `Calendar.strftime/2` on the v1.0 `"en"`-locale default.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:mjml_eex` | `:mjmleex` (Elonsoft) | Only if Rustler NIF fails on a target arch. mjml_eex has more downloads + active maintenance. |
| `:chromic_pdf` | `:gotenberg` sidecar | Host apps in Chrome-hostile environments. Custom `Accrue.PDF` adapter, not first-party. **Document in PDF guide only.** |
| Separate `.text.eex` | Floki-strip rendered HTML | Floki loses CLDR-formatted money boundaries and injects unwanted whitespace. Separate template is the Pay/Cashier precedent; matches Phase 1. |
| Per-email HEEx | HEEx + render_body/3 directly | `phoenix_swoosh`'s `render_body/3` works for plain HEEx emails but we need MJML shells for responsiveness, so `mjml_eex` supersedes it for the HTML body. phoenix_swoosh is still useful for `new_email/1`. |
| `:ex_cldr_dates_times` for v1.0 | `Calendar.strftime/2` for English-only | If CLDR locale stays `"en"` in v1.0, strftime is zero-dep and sufficient. Add CLDR dates in v1.1 when multi-locale backend ships. |

**Version verification:** Ran Hex.pm API 2026-04-15 — all pinned `~>` constraints resolve to a current minor release. No Phase 6 bump required.

## Architecture Patterns

### System Architecture Diagram

```
+---------------------------+       +--------------------------+
| Domain action or          |       | Stripe webhook arrives   |
| Accrue.Billing.*          |       | Accrue.Webhook.Ingest    |
| (e.g., refund/2, pay/3)   |       | → DefaultHandler reducer |
+-------------+-------------+       +------------+-------------+
              |                                  |
              +-------------+--------------------+
                            |
                            v
               +-----------------------------+
               | Accrue.Mailer.deliver(      |
               |   type, %{customer_id: _,   |
               |            invoice_id: _,   |
               |            locale: _, ...}) |
               | (behaviour facade)          |
               +--------------+--------------+
                              |
             kill-switch? ----+---- yes → {:ok, :skipped}
                              |
                              v
        +---------------------+-----------------------+
        |                                             |
        v                                             v
  :mailer = Default                            :mailer = Test (test env)
        |                                             |
        v                                             v
  Accrue.Workers.Mailer                         send self()
  Oban job on :accrue_mailers              {:accrue_email_delivered,
        |                                    type, assigns}
        |    (async, async, async)                    |
        v                                             v
  perform/1:                                 Accrue.Test.MailerAssertions
    resolve_template/1 (rung 2 MFA              assert_email_sent/1..3
                        + rung 3 overrides)
    enrich/2 (locale + TZ precedence ladder)
    atomize_known_keys/1
        |
        v
  +-----+------+
  |            |
  v            v
 type needs   regular
 invoice PDF? email type
  |            |
  v            v
 Accrue.Billing.render_invoice_pdf(invoice_id, opts)
  |                                             |
  | uses Accrue.PDF.impl()                      |
  |                                             |
  v                                             v
 adapter = ChromicPDF / Null / Test             |
  |                                             |
  | if Null → {:error, %Accrue.Error.          |
  |            PdfDisabled{}} → fallback to    |
  |            hosted_invoice_url link          |
  |                                             |
  | if ChromicPDF:                              |
  |   Accrue.Invoices.Render.build_assigns/1    |
  |     → %RenderContext{branding, locale,      |
  |        timezone, invoice, line_items, ...}  |
  |     ↓                                       |
  |   Accrue.Invoices.Layouts.print_shell/1     |
  |     (HEEx function component)               |
  |     ↓                                       |
  |   Phoenix.LiveView.HTMLEngine render → html |
  |     ↓                                       |
  |   ChromicPDF.Template.source_and_options    |
  |     ↓                                       |
  |   print_to_pdf/1 or print_to_pdfa/1         |
  |     → {:ok, binary()} / {:error, _}         |
  |                                             |
  v                                             |
 Swoosh.Email.new()                             |
   |> Accrue.Mailer.Swoosh.new_email(           |
        [from: branding, to: ..., subject: ...])|
   |> Swoosh.Email.html_body(                   |
        MyEmailType.render(assigns)) # mjml_eex |
   |> Swoosh.Email.text_body(                   |
        MyEmailType.render_text(assigns))       |
   |> maybe_attach_pdf_or_hosted_link/2         |
        |                                       |
        v                                       |
 Accrue.Mailer.Swoosh.deliver(email)  ----------+
   (configured Swoosh adapter, host-owned)
        |
        v
 [:accrue, :mailer, :deliver, :stop] telemetry
```

### Recommended Project Structure (additions in Phase 6)

```
accrue/lib/accrue/
├── invoices/
│   ├── render.ex                    # build_assigns(invoice_id, opts) -> RenderContext-shaped map
│   ├── render_context.ex            # %Accrue.Invoices.RenderContext{} struct (optional; can stay map)
│   ├── components.ex                # Phoenix.Component: invoice_header, line_items, totals, footer
│   └── layouts.ex                   # print_shell/1 + @page CSS helpers
├── emails/
│   ├── fixtures.ex                  # canned assigns for mix preview + test + Phase 7 LiveView
│   ├── html_bridge.ex               # Phoenix.Component render → safe HTML string (for <mj-raw>)
│   ├── payment_succeeded.ex         # (existing, unchanged)
│   ├── receipt.ex                   # alias/rename path per MAIL-03 naming
│   ├── payment_failed.ex
│   ├── trial_ending.ex
│   ├── trial_ended.ex
│   ├── invoice_finalized.ex
│   ├── invoice_paid.ex
│   ├── invoice_payment_failed.ex
│   ├── subscription_canceled.ex
│   ├── subscription_paused.ex
│   ├── subscription_resumed.ex
│   ├── refund_issued.ex
│   └── coupon_applied.ex
├── mailer/
│   ├── default.ex                   # (existing)
│   ├── swoosh.ex                    # (existing)
│   └── test.ex                      # NEW — D6-05 behaviour-layer adapter
├── pdf/
│   ├── chromic_pdf.ex               # (existing)
│   ├── test.ex                      # (existing)
│   └── null.ex                      # NEW — D6-06 adapter
├── error/
│   └── pdf_disabled.ex              # NEW — defexception (D6-06)
├── storage.ex                       # NEW — D6-04 behaviour
├── storage/
│   └── null.ex                      # NEW — D6-04 default adapter
├── test/
│   ├── mailer_assertions.ex         # NEW — D6-05 assertion API
│   └── pdf_assertions.ex            # NEW — PDF-03 assertion API
└── workers/
    └── mailer.ex                    # EXTEND — add rung 2 MFA + full resolve_template/1 catalogue

accrue/priv/accrue/templates/
├── layouts/
│   ├── transactional.mjml.eex       # shared MJML shell (branding header/footer)
│   └── transactional.text.eex       # shared plain-text header/footer
├── emails/
│   ├── payment_succeeded.mjml.eex   # (existing)
│   ├── payment_succeeded.text.eex   # (existing)
│   ├── receipt.mjml.eex             # + .text.eex sibling for each
│   ├── ... (13 email types × 2 templates each)
└── pdf/
    └── invoice.html.heex            # ChromicPDF HTML source — uses Invoices.Components

accrue/lib/mix/tasks/
└── accrue.mail.preview.ex           # NEW — D6-08 mix task

accrue/priv/repo/migrations/
└── <ts>_add_locale_and_timezone_to_customers.exs   # D6-03 migration
```

### Pattern 1: HEEx → MJML bridge via `<mj-raw>` + html bridge module

**What:** `mjml_eex` cannot directly call `Phoenix.Component` function components — they don't share a template engine. The bridge is a thin module that takes a component function + assigns, renders it through `Phoenix.LiveView.HTMLEngine` (or simpler: `Phoenix.HTML.Safe.to_iodata/1` after `Phoenix.Template.render_to_iodata/4`) to an HTML string, then embeds that string inside MJML via `<mj-raw>`.

**When to use:** Every email template that needs to share markup with the PDF (i.e., every invoice-bearing email).

**Example:**

```elixir
# accrue/lib/accrue/emails/html_bridge.ex
defmodule Accrue.Emails.HtmlBridge do
  @moduledoc """
  Renders a Phoenix.Component function component to a safe HTML string
  suitable for embedding inside `<mj-raw>` in an mjml_eex template.

  Style MUST be inlined inside the component itself — MJML's post-render
  CSS inliner does not descend into <mj-raw> blocks.
  """

  import Phoenix.Component, only: [sigil_H: 2]

  @spec render(component :: (map() -> Phoenix.LiveView.Rendered.t()), map()) :: String.t()
  def render(component, assigns) when is_function(component, 1) and is_map(assigns) do
    assigns
    |> component.()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end

# accrue/priv/accrue/templates/emails/invoice_paid.mjml.eex
# (fragment — inside the MJML body)
<mj-raw>
  <%= Accrue.Emails.HtmlBridge.render(
        &Accrue.Invoices.Components.invoice_header/1,
        @render_context
      ) %>
</mj-raw>
```

`[CITED: Phoenix.HTML.Safe protocol — hexdocs.pm/phoenix_html/Phoenix.HTML.Safe.html]`
`[ASSUMED: exact path through Phoenix.HTML.Safe for a function component's Rendered struct — validate with a spike at start of Wave 2. Phoenix.LiveView 1.1 Rendered struct implements Phoenix.HTML.Safe, but the idiomatic "function component → static HTML string" call shape needs one-off testing.]`

### Pattern 2: Render context struct (format-neutral)

**What:** `%Accrue.Invoices.RenderContext{}` (or just a map with documented keys) — the single "hydrated invoice plus branding plus locale" payload that flows through both the email HTML body, the plain-text body, and the PDF. Built once by `Accrue.Invoices.Render.build_assigns/2` (D6-04 API).

**Fields (recommended):**

```elixir
defmodule Accrue.Invoices.RenderContext do
  @type t :: %__MODULE__{
    invoice: Accrue.Billing.Invoice.t(),
    customer: Accrue.Billing.Customer.t(),
    line_items: [Accrue.Billing.InvoiceItem.t()],
    subtotal_minor: integer(),
    discount_minor: integer(),
    tax_minor: integer(),
    total_minor: integer(),
    currency: atom(),
    branding: keyword(),           # from Accrue.Config.branding/0 at render time
    locale: String.t(),            # D6-03 resolved locale
    timezone: String.t(),          # D6-03 resolved timezone
    now: DateTime.t(),             # for "rendered at" timestamp, already in timezone
    hosted_invoice_url: String.t() | nil,
    receipt_url: String.t() | nil,
    formatted_total: String.t(),   # CLDR-formatted string, pre-computed
    formatted_subtotal: String.t(),
    formatted_issued_at: String.t()
  }

  defstruct [...]
end
```

**Why pre-format money + dates in the struct, not inside HEEx:** keeps CLDR calls off the hot template path (templates render fast + predictably) and ensures email and PDF both hit identical strings.

### Pattern 3: Branding config helper pattern (mirroring `Accrue.Config.dunning/0`)

```elixir
def branding, do: Keyword.fetch!(all(), :branding)
def branding(key), do: Keyword.fetch!(branding(), key)
```

Same shape as `Accrue.Config.dunning/0` (Phase 4, `accrue/lib/accrue/config.ex`) and `connect/0` (Phase 5, STATE.md entry P05). `[VERIFIED: STATE.md decisions "Accrue.Config.connect/0 helper added mirroring dunning/0"]`

### Pattern 4: Null-adapter graceful degradation

Every place that calls `Accrue.PDF.render/2` MUST pattern-match `{:error, %Accrue.Error.PdfDisabled{}}` explicitly and fall through to a non-PDF path. Other errors re-raise (terminal vs transient distinction — D6-06).

```elixir
# In Accrue.Mail.InvoiceFinalized or invoice_paid worker perform
with {:ok, html} <- render_email_html(assigns),
     {:ok, pdf} <- Accrue.Billing.render_invoice_pdf(invoice_id) do
  email
  |> Swoosh.Email.html_body(html)
  |> Swoosh.Email.attachment(Swoosh.Attachment.new({:data, pdf},
       filename: "invoice-#{invoice.number}.pdf",
       content_type: "application/pdf"))
  |> deliver()
else
  {:error, %Accrue.Error.PdfDisabled{}} ->
    # D6-06 graceful degradation — append hosted invoice URL instead
    email
    |> Swoosh.Email.html_body(append_hosted_link(html, invoice.hosted_invoice_url))
    |> deliver()
  {:error, other} ->
    raise Accrue.PDF.RenderFailed, reason: other  # lets Oban backoff handle transients
end
```

### Anti-Patterns to Avoid

- **Rendering PDFs from MJML output.** Tempting (looks literal), wrong answer. MJML compiles to email-client table soup that is unusable as a print document. `[CITED: D6-01 "Do not let 'fix SC#2' attempts render PDFs from MJML output"]`
- **Inlining CSS inside `<mj-raw>` blocks at the MJML post-processor level.** mjml_eex post-processes only non-raw MJML styles. Embedded HEEx must pre-inline its own styles. `[CITED: D6-01 pitfall list]`
- **Using `@page` CSS to control PDF paper size.** ChromicPDF's documented behavior: `@page` is "not correctly interpreted" — use ChromicPDF options (`:size`, `paperWidth`, `paperHeight`) instead. `[VERIFIED: hexdocs.pm/chromic_pdf]`
- **Starting ChromicPDF from `Accrue.Application`.** D-33 + D6-04 + CLAUDE.md all agree: host app owns the pool so per-env tuning works. Accrue.Application stays empty-supervisor (FND-05). `[CITED: accrue/lib/accrue/pdf/chromic_pdf.ex:3-13]`
- **Passing `%Ecto.Schema{}` structs through Oban args.** D-27 scalar-only rule; `only_scalars!/1` in `Accrue.Mailer.Default` already enforces this. Pass IDs, rehydrate in `enrich/2`. `[VERIFIED: accrue/lib/accrue/mailer/default.ex:49-80]`
- **Atomizing untrusted webhook-payload string keys via `String.to_atom/1`.** Phase 1 uses `String.to_existing_atom/1` rescue ArgumentError — same pattern must apply to any new enrich step. `[VERIFIED: accrue/lib/accrue/workers/mailer.ex:82-94]`
- **Using `Floki` to strip HTML into plain text.** Loses money-formatting boundaries and injects unwanted whitespace around `<td>` elements. Ship a separate `.text.eex` template per type (Phase 1 precedent).
- **Using `String.to_atom/1` for locale/timezone lookups.** D6-03 explicitly says fall back with telemetry — never raise. Unknown locales go to `"en"`, unknown TZs go to `"Etc/UTC"`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML email MSO conditionals | Hand-write `<!--[if mso]>` blocks per template | MJML via `mjml_eex` (compiles these in) | MAIL-19: Outlook 2007-2016 conditional compatibility is MJML's single biggest value; 13 templates × hand-rolled Outlook fallbacks = 13 sources of deliverability bugs. |
| HTML → PDF conversion | Anything involving `wkhtmltopdf`, `weasyprint` sidecar, or hand-rolled headless Chrome | `ChromicPDF` (D-32, Phase 1 locked) | wkhtmltopdf is archived with CVEs (CLAUDE.md §What NOT to Use). ChromicPDF is the idiomatic Elixir answer and already wired. |
| Currency formatting | Hand-rolled minor→major conversion + locale formatting | `Money.to_string(%Money{}, locale: ctx.locale)` via `ex_money` + `Accrue.Cldr` | Zero-decimal + three-decimal currencies (JPY, KWD) break naive `/100` math. Phase 1's `Accrue.Money` already wraps this correctly. `[VERIFIED: accrue/lib/accrue/money.ex]` |
| Date formatting per locale | Hand-rolled `"#{day}/#{month}/#{year}"` | For v1.0 `en`-only default: `Calendar.strftime/2`. For multi-locale (v1.1): `Cldr.DateTime.to_string/2` from `ex_cldr_dates_times` | Don't invent locale rules. |
| Timezone conversion | `DateTime.add/3` with hardcoded offsets | `DateTime.shift_zone/3` (wrapped with rescue → `Etc/UTC` + telemetry per D6-03) | Daylight saving transitions break naive offset math. |
| Email HTML assertion testing | Parse rendered HTML and check substrings | `Accrue.Mailer.Test` sends intent tuples to test pid (D6-05) — assert on `(type, assigns)` not on HTML | Tests should assert on intent, not implementation. HTML assertion tightly couples tests to template layout and breaks on brand tweaks. |
| PDF binary assertion testing | Parse PDF binary and check fields | `Accrue.PDF.Test` sends `{:pdf_rendered, html, opts}` to test pid (Phase 1 D-34); assert on the HTML source | Same reasoning — assert on the HTML you fed to the adapter, not on `binary.contains?("$100.00")`. |
| List-Unsubscribe header for transactional mail | Generate unsubscribe tokens + routes | **Don't generate at all** (D6-07 — transactional exemption). Opt-in via `branding.list_unsubscribe_url` pointing at a host-owned preferences page | Broken unsubscribe links hurt deliverability more than omission. |
| Config hot-reload branding | Watch file for changes, recompile templates | Runtime reads via `Accrue.Config.branding/0` (D6-02); no recompile ever needed | `runtime.exs` + helper reads give you "change-logo-without-deploy" for free. |

**Key insight:** Phase 6 is thin because Phase 1 did the hard plumbing. Every custom solution temptation listed above already has a standard library answer baked in. The phase's real complexity is the component-library design (D6-01) and the 13 email type catalogue, not any new infrastructure.

## Common Pitfalls

### Pitfall 1: Assuming mjml_eex is HEEx-based

**What goes wrong:** Plan authors write "embed the shared `<.invoice_header/>` function component inside the MJML template" and it doesn't compile because `mjml_eex` templates use a different engine.

**Why it happens:** Docs say "EEx + MJML" and the library name contains "eex," so readers assume Phoenix.Component interop. It's actually a separate behaviour (`MjmlEEx.Component`) with string-return render functions, not HEEx.

**How to avoid:** Treat HEEx as the shared-component engine and render components through the `Accrue.Emails.HtmlBridge` module (Pattern 1 above) to a string that gets embedded via `<mj-raw>`. At spike time, confirm the exact `Phoenix.HTML.Safe.to_iodata/1` call path for a `Phoenix.Component` function call.

**Warning signs:** Compile errors like `(UndefinedFunctionError) function Phoenix.Component.XYZ/1 is undefined inside an .mjml.eex template`. Or: a PR that imports `Phoenix.Component` into an `Accrue.Emails.*` module and calls it without going through the bridge.

`[VERIFIED: hexdocs.pm/mjml_eex/readme.html shows render_dynamic_component using its own MjmlEEx.Component behaviour with string-return render functions, not HEEx]`

### Pitfall 2: `<mj-raw>` bypasses MJML style inlining

**What goes wrong:** Email looks perfect in preview but renders as unstyled HTML inside Outlook/Gmail because the CSS defined in the MJML `<mj-style>` block never reached the `<mj-raw>` children.

**Why it happens:** MJML's CSS inliner runs on MJML-native elements only. Raw blocks are passed through verbatim — intentional, but surprising.

**How to avoid:** Every shared component must inline its own `style=".."` attributes using a `brand_style/1` helper that reads `Accrue.Config.branding/0`. Add a `mix accrue.mail.preview` assertion (or plain unit test) that opens a Chromium headless render and checks computed styles.

**Warning signs:** Preview with `mix accrue.mail.preview` looks styled but actual mailbox render is unstyled. Or: a shared component that relies on a top-level `<style>` block.

`[CITED: D6-01 pitfall list "MJML's <mj-raw> bypasses MJML's style inlining"]`

### Pitfall 3: ChromicPDF not started by host

**What goes wrong:** Production deploy calls `Accrue.Billing.render_invoice_pdf/1`, `ChromicPDF` process isn't registered, Oban worker crashes with a cryptic `GenServer.call/3` error, mailer job retries, eventually DLQs, and the customer never gets their receipt email.

**Why it happens:** D-33 says Accrue does not start ChromicPDF — host must. If the host install guide is skipped, the failure mode is silent at compile time and loud at runtime.

**How to avoid:** (1) Facade wraps `Process.whereis(ChromicPDF) == nil` → `{:error, :chromic_pdf_not_started}` with a clear install message (D6-04). (2) `Accrue.Application` boot-time check (same slot as the existing config validators) logs a warning if `pdf_adapter == Accrue.PDF.ChromicPDF` AND `Process.whereis(ChromicPDF) == nil` AND Mix env is `:prod`. (3) Install guide calls it out in a fenced code block.

**Warning signs:** Production logs show `Accrue.PDF.ChromicPDF.render/2` crashes with `:noproc` or `GenServer.call(nil, ...)` errors.

`[CITED: accrue/lib/accrue/pdf/chromic_pdf.ex:3-13]`

### Pitfall 4: Oban queue concurrency > ChromicPDF pool size

**What goes wrong:** Monthly billing run enqueues 2000 invoice email jobs on `accrue_mailers` with concurrency 20. ChromicPDF runs with `session_pool: [size: 3]`. Jobs contend on the Chrome pool, backpressure cascades, Swoosh adapter times out on downstream email service, and ~30% of the invoice batch DLQs with `:timeout` errors.

**Why it happens:** Oban queue concurrency and ChromicPDF pool size are two independent configuration surfaces, and the ordering relation isn't obvious.

**How to avoid:** Documentation recipe: ensure `accrue_mailers` queue concurrency ≤ `session_pool` size (D6-04). Provide a boot-time warning in `Accrue.Application` when `attach_invoice_pdf: true` and `session_pool[:size]` < Oban `accrue_mailers` concurrency (if detectable at boot).

**Warning signs:** Bursts of `{:error, :timeout}` in Oban `accrue_mailers` queue during batch invoice runs.

`[CITED: D6-04 "Performance posture"]`

### Pitfall 5: Locale fallback raises instead of defaulting

**What goes wrong:** A customer has `preferred_locale: "zz"` from a seeded dev DB. `Cldr.Number.to_string/2` or `Money.to_string/2` raises `Cldr.UnknownLocaleError`, the entire email job crashes, Oban retries 5 times, job goes to DLQ. Bad data corrupts the entire month's receipt batch.

**Why it happens:** D6-03 says "never raise" but it's easy to wire `Cldr.Number.to_string(100, locale: ctx.locale)` directly without a rescue. CLDR raises on unknown locales by default.

**How to avoid:** Every locale-sensitive call lives inside `Accrue.Invoices.Render.format_money/3` (or similar helper) that does `try/rescue` → `"en"` fallback + emits `[:accrue, :email, :locale_fallback]` telemetry. Same pattern for timezone: wrap `DateTime.shift_zone/3` with rescue → `"Etc/UTC"`.

**Warning signs:** Oban DLQ contains `Cldr.UnknownLocaleError` or `FunctionClauseError` from `Calendar.ISO` on unknown timezones.

`[CITED: D6-03 "never raise"]`

### Pitfall 6: ChromicPDF `@page` CSS ignored

**What goes wrong:** Plan writes a print-CSS HEEx template with `@page { size: A4; margin: 20mm; }`. PDF comes out 8.5x11 with default margins because ChromicPDF ignores `@page` and uses its own size options.

**Why it happens:** `@page` is CSS-valid and works in most HTML-to-PDF pipelines, but ChromicPDF documents it is "not correctly interpreted."

**How to avoid:** Pass `:size`, `:paper_width`, `:paper_height`, `:margin_top`, etc. via `ChromicPDF.Template.source_and_options/1` options — the Phase 1 adapter already takes `:size` (`accrue/lib/accrue/pdf/chromic_pdf.ex:60-68`). Add optional `:margin_*` passthroughs. Do not rely on `@page`.

**Warning signs:** PDF margins do not match the print-CSS declaration. Page size comes out as `Letter` on European deploys.

`[VERIFIED: hexdocs.pm/chromic_pdf/ChromicPDF.html "the @page section in CSS is not correctly interpreted"]`

### Pitfall 7: Double-dispatch of mailer from both webhook reducer and billing action

**What goes wrong:** `Accrue.Billing.pay/3` calls `Accrue.Mailer.deliver(:invoice_paid, ...)` AND the downstream `invoice.paid` webhook reducer also calls `Accrue.Mailer.deliver(:invoice_paid, ...)`. Customer gets two receipts.

**Why it happens:** The billing library has two causal paths — synchronous action return + asynchronous webhook — and both "know" about the state change.

**How to avoid:** Pick one dispatch point per email type and document it. Recommended rule: **webhook reducer is the single dispatch point for state-change emails**, because it fires for both direct API actions AND dashboard-initiated changes. The only exception is emails triggered by Accrue-local events with no webhook counterpart (e.g., `card_expiring_soon`, dunning threshold notifications). Add Oban uniqueness config on `Accrue.Workers.Mailer` to catch double-enqueues — already wired as `unique: [period: 60, fields: [:args, :worker]]` (`accrue/lib/accrue/workers/mailer.ex:20`). `[VERIFIED]`

**Warning signs:** Customers reporting duplicate receipts. Oban jobs with identical `args` at close timestamps.

### Pitfall 8: Branding config drift between email and PDF

**What goes wrong:** Branding is read at two different points in the render pipeline — once for email HTML at mailer-worker time, once for PDF at render-invoice-pdf time — and the second read happens after a config reload, so email header logo and PDF header logo disagree.

**Why it happens:** `Accrue.Config.branding/0` is called twice.

**How to avoid:** Freeze the branding snapshot into the `RenderContext` once at `Accrue.Invoices.Render.build_assigns/2`, then pass the context through both the email and PDF shells. Never re-read `Accrue.Config.branding/0` downstream.

**Warning signs:** Mixed branding between email header and attached PDF in the same delivery.

## Runtime State Inventory

Phase 6 **is a greenfield phase** — no rename or migration. This section is included only to confirm there is nothing to audit:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Phase 6 adds two nullable columns (`preferred_locale`, `preferred_timezone`) to `accrue_customers`. No rename of existing data. | Simple migration; no data backfill. |
| Live service config | None — branding + locale are host-owned `config/runtime.exs`, not external service state. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None — Phase 6 reads the same Stripe keys Phase 3–5 already use; no new secret names. | None. |
| Build artifacts | None — mjml_eex's Rustler NIF is already built from Phase 1. | None. |

**Nothing found in category:** Confirmed — Phase 6 only adds new modules and two DB columns.

## Code Examples

### Invoice component — shared between email HEEx bridge and PDF shell

```elixir
# accrue/lib/accrue/invoices/components.ex
defmodule Accrue.Invoices.Components do
  @moduledoc """
  Phoenix.Component function components shared by email (via
  Accrue.Emails.HtmlBridge + <mj-raw>) and PDF (via Accrue.Invoices.Layouts.print_shell/1).

  Every component must inline its own styles via brand_style/1 because
  MJML's <mj-raw> does not descend for style inlining (D6-01 Pitfall).
  """

  use Phoenix.Component

  attr :context, :map, required: true
  def invoice_header(assigns) do
    ~H"""
    <table style={brand_style(:table_reset)} role="presentation" cellpadding="0" cellspacing="0" width="100%">
      <tr>
        <td style={brand_style(:logo_cell)}>
          <img src={@context.branding[:logo_url]} alt={@context.branding[:business_name]} />
        </td>
        <td style={brand_style(:number_cell)}>
          Invoice #<%= @context.invoice.number %>
        </td>
      </tr>
    </table>
    """
  end

  attr :context, :map, required: true
  def line_items(assigns) do
    ~H"""
    <table style={brand_style(:line_items)} role="presentation" cellpadding="0" cellspacing="0" width="100%">
      <thead>
        <tr>
          <th style={brand_style(:th)}>Description</th>
          <th style={brand_style(:th)}>Qty</th>
          <th style={brand_style(:th)}>Amount</th>
        </tr>
      </thead>
      <tbody>
        <%= for item <- @context.line_items do %>
          <tr style={brand_style(:line_row)}>
            <td style={brand_style(:td)}><%= item.description %></td>
            <td style={brand_style(:td_num)}><%= item.quantity %></td>
            <td style={brand_style(:td_num)}><%= format_money(item.amount_minor, @context.currency, @context.locale) %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  # ... totals/1, footer/1, etc.

  defp brand_style(key), do: Accrue.Invoices.Styles.for(key, Accrue.Config.branding())
  defp format_money(minor, currency, locale),
    do: Accrue.Invoices.Render.format_money(minor, currency, locale)
end
```

### Email module shape (uniform, ~80 LoC per type)

```elixir
# accrue/lib/accrue/emails/invoice_paid.ex
defmodule Accrue.Emails.InvoicePaid do
  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/invoice_paid.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{invoice: %{number: n}}}), do: "Payment received — Invoice #{n}"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_path(), assigns: Enum.into(assigns, []))
  end

  defp text_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/invoice_paid.text.eex")
  end
end
```

### Mailer.Test behaviour-layer adapter

```elixir
# accrue/lib/accrue/mailer/test.ex
defmodule Accrue.Mailer.Test do
  @moduledoc """
  Test adapter for Accrue.Mailer. Sidesteps Oban — sends the intent
  directly to the calling test pid.
  """

  @behaviour Accrue.Mailer

  @impl true
  def deliver(type, assigns) when is_atom(type) and is_map(assigns) do
    send(self(), {:accrue_email_delivered, type, assigns})
    {:ok, :test}
  end
end
```

### Mailer assertion helper

```elixir
# accrue/lib/accrue/test/mailer_assertions.ex
defmodule Accrue.Test.MailerAssertions do
  import ExUnit.Assertions

  def assert_email_sent(type, opts \\ [], timeout \\ 100) do
    receive do
      {:accrue_email_delivered, ^type, assigns} ->
        matches?(assigns, opts) ||
          flunk("email of type #{inspect(type)} delivered but did not match opts #{inspect(opts)}; got assigns #{inspect(assigns)}")
    after
      timeout -> flunk("no email of type #{inspect(type)} delivered within #{timeout}ms")
    end
  end

  def refute_email_sent(type, opts \\ [], timeout \\ 100) do
    receive do
      {:accrue_email_delivered, ^type, assigns} ->
        if matches?(assigns, opts),
          do: flunk("unexpected email of type #{inspect(type)} delivered with assigns #{inspect(assigns)}")
    after
      timeout -> :ok
    end
  end

  def assert_emails_sent(expected_count) when is_integer(expected_count), do:
    # drain inbox counting :accrue_email_delivered messages within a short window
    ...

  defp matches?(assigns, opts) do
    Enum.all?(opts, fn
      {:to, v} -> (assigns[:to] || assigns["to"]) == v
      {:customer_id, v} -> assigns[:customer_id] == v
      {:assigns, m} -> Map.take(assigns, Map.keys(m)) == m
      {:matches, f} when is_function(f, 1) -> f.(assigns)
    end)
  end
end
```

### Render precedence ladder (D6-03)

```elixir
# accrue/lib/accrue/workers/mailer.ex — enrich/2 EXTENSION
defp enrich(type, assigns) when is_map(assigns) do
  customer = maybe_load_customer(assigns)

  locale =
    assigns[:locale] || assigns["locale"] ||
      (customer && customer.preferred_locale) ||
      Application.get_env(:accrue, :default_locale) ||
      "en"

  timezone =
    assigns[:timezone] || assigns["timezone"] ||
      (customer && customer.preferred_timezone) ||
      Application.get_env(:accrue, :default_timezone) ||
      "Etc/UTC"

  {locale, timezone} = safe_locale_timezone(locale, timezone)

  assigns
  |> Map.put(:locale, locale)
  |> Map.put(:timezone, timezone)
end

defp safe_locale_timezone(locale, timezone) do
  resolved_locale =
    try do
      _ = Cldr.Locale.new!(locale, Accrue.Config.cldr_backend())
      locale
    rescue
      _ ->
        :telemetry.execute([:accrue, :email, :locale_fallback], %{}, %{requested: locale})
        "en"
    end

  resolved_tz =
    try do
      _ = DateTime.shift_zone!(DateTime.utc_now(), timezone)
      timezone
    rescue
      _ ->
        :telemetry.execute([:accrue, :email, :timezone_fallback], %{}, %{requested: timezone})
        "Etc/UTC"
    end

  {resolved_locale, resolved_tz}
end
```

## Email Type Catalogue + Domain Event Mapping

This is the canonical map for planner wave composition. Each row is one `Accrue.Emails.*` module + matching `.mjml.eex` + `.text.eex` + Oban dispatch wiring.

| # | Email type | MAIL-# | Triggered by | Dispatch point | Attaches PDF? | Requires invoice context? |
|---|------------|--------|--------------|----------------|---------------|--------------------------|
| 1 | `receipt` | MAIL-03 | `charge.succeeded` webhook OR `Accrue.Billing.charge/3` success | Webhook reducer (Pitfall 7) | No | No |
| 2 | `payment_failed` | MAIL-04 | `charge.failed` / `payment_intent.payment_failed` | Webhook reducer | No | No |
| 3 | `trial_ending` | MAIL-05 | `customer.subscription.trial_will_end` | Webhook reducer | No | No |
| 4 | `trial_ended` | MAIL-06 | `customer.subscription.updated` w/ status `trialing→active` | Webhook reducer | No | No |
| 5 | `invoice_finalized` | MAIL-07 | `invoice.finalized` | Webhook reducer | **Yes** (D6-04) | Yes |
| 6 | `invoice_paid` | MAIL-08 | `invoice.paid` | Webhook reducer | **Yes** | Yes |
| 7 | `invoice_payment_failed` | MAIL-09 | `invoice.payment_failed` | Webhook reducer | No (link to `hosted_invoice_url`) | Yes |
| 8 | `subscription_canceled` | MAIL-10 | `customer.subscription.deleted` OR `Accrue.Billing.cancel/2` | Webhook reducer | No | No |
| 9 | `subscription_paused` | MAIL-11a | `customer.subscription.updated` w/ `pause_collection` set | Webhook reducer | No | No |
| 10 | `subscription_resumed` | MAIL-11b | `customer.subscription.updated` w/ `pause_collection` cleared | Webhook reducer | No | No |
| 11 | `refund_issued` | MAIL-12 | `charge.refunded` | Webhook reducer | No | No (but embeds fee breakdown from `Refund` schema) |
| 12 | `coupon_applied` | MAIL-13 | `Accrue.Billing.apply_promotion_code/3` success + webhook `invoice.updated` | **Action module** (no Stripe webhook directly for "coupon applied to subscription" — Phase 4 P05 emits the event synchronously) | No | No |
| 13 | `card_expiring_soon` | (existing Phase 3) | `Accrue.Workers.DetectExpiringCards` cron | Oban cron output | No | No |

**Note:** Row 13 (`card_expiring_soon`) already has its detection job in Phase 3 (`accrue/lib/accrue/workers/` — STATE.md P03 entry). Phase 6 adds the email type module + template. Whether it counts toward the "13+" in D6-01 is a naming question, not a build question.

**Critical: the `invoice_finalized` + `invoice_paid` pair are the only two that require PDF rendering at mailer-worker time** (D6-04 lazy render). All other types render email-only and do not touch `Accrue.PDF`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolled HTML email with inline MSO conditionals | MJML via mjml_eex (Rustler NIF) | MJML 4.x (2019+), mjml_eex 0.13 (2025-12) | Build once, responsive everywhere, Outlook compat solved |
| `wkhtmltopdf` sidecar | ChromicPDF (headless Chrome pool) | ChromicPDF 1.x (2020+); wkhtmltopdf archived 2023 | Current fonts, current CSS, active maintenance, Elixir-native pool |
| Bamboo mailer | Swoosh | Phoenix 1.6 defaulted to Swoosh (2021) | Swoosh is the ecosystem default; Bamboo is maintenance-mode |
| `phoenix_swoosh render_body/3` for HEEx email HTML | `mjml_eex` for responsive HTML body + `phoenix_swoosh` for `new_email/1` composition | mjml_eex became the MJML default in Elixir (2023) | HEEx + MJML is incompatible; mjml_eex is the standard escape |
| Flat brand config keys (`:logo_url`, `:from_email`) | Nested `:branding` keyword list via NimbleOptions | D6-02 | Single validated surface; deprecate flat keys with one-minor shim |
| PDF byte storage on `accrue_invoices` | Lazy render on demand from branding config | D6-04 | Brand updates retroactively reflect without schema migration |

**Deprecated / outdated:**
- **`wkhtmltopdf`** — archived, CVEs unpatched. Explicit CLAUDE.md ban.
- **`bamboo`** — maintenance-mode. CLAUDE.md ban.
- **`Bling` (Elixir billing lib)** — precedent Accrue is replacing; its two-disconnected-code-paths template design is exactly the regret D6-01 closes.
- **Flat Accrue config keys `business_name`, `logo_url`, `from_email`, `from_name`, `support_email`, `business_address`** — deprecated by D6-02 with a one-minor shim; boot-time warning; removed pre-1.0. `[CITED: accrue/lib/accrue/config.ex:77-106]`

## Font Strategy Recommendation (Claude's Discretion item)

**Recommendation: base64-embed font files into the print-CSS template for PDF. Skip webfonts entirely.**

Reasoning:
1. ChromicPDF's headless Chromium has network access to external webfont CDNs but load order is non-deterministic — ghost fonts or FOIT can sneak through.
2. Base64 embedding makes the PDF render fully deterministic + fully offline, which matches the "branded and reproducible" SC #2 posture.
3. File size cost is small (~40KB per font weight for a subset); we only need the branding font stack, and `Accrue.Config.branding.font_stack` is already a system-font stack by default.
4. The `@font-face { src: url(data:...) }` pattern is supported in Chromium headless and doesn't require any ChromicPDF-specific options.

For v1.0 default branding (system fonts), no embedding is needed. Ship a guide page describing the base64 technique for hosts who override `font_stack` to a custom font. Do NOT ship custom font binaries in the `accrue` hex package.

`[ASSUMED: trade-off analysis; validate with a spike in Wave 3 if custom-font support is demanded]`

## Page-Break Strategy Recommendation (Claude's Discretion item)

**Recommendation: `page-break-inside: avoid` on each `<tr class="line-item">` AND `page-break-after: avoid` on the totals section.**

Reasoning:
1. Chromium respects `page-break-inside: avoid` and `break-inside: avoid` at block-level and table-row-level. `[ASSUMED based on general Chromium CSS support; verify with a long-invoice spike test]`
2. Page-breaking inside a table row is the #1 visual bug in long invoices.
3. For invoices >100 line items, a single continuation page with a repeating `<thead>` via `display: table-header-group` keeps columns aligned.

Document the CSS snippet in the PDF customization guide. No code needed in the adapter.

## Config Migration Shim (Claude's Discretion item)

**Recommendation:**

1. Keep the 6 deprecated flat keys in `@schema` but mark their `doc` with "**DEPRECATED** — use `:branding` nested key instead. Removed in v1.0."
2. Add `Accrue.Config.branding/0` that first reads the nested `:branding` key; if empty, falls back to building a keyword list from the flat keys AND emits a `Logger.warning/1` with the migration path and a once-per-boot `:persistent_term` dedupe.
3. Nested `:branding` has precedence when both are set.
4. Remove the fallback branch entirely before v1.0 release cut.

**Boot-time deprecation:** Add a `warn_deprecated_branding/1` check in `Accrue.Application.start/2` that logs if any flat key is configured AND `:branding` is empty. Same slot as the `enforce_immutability` check.

## Plain-Text Generation Strategy (Claude's Discretion item)

**Recommendation: separate `.text.eex` template per type.** Matches Phase 1 precedent (`accrue/priv/accrue/templates/emails/payment_succeeded.text.eex`). Rationale above under Don't Hand-Roll. The incremental cost is low (~20 LoC per template, mostly static copy) and gives per-type control over the plain-text wording — which matters for MAIL-04 (payment_failed retry guidance) and MAIL-09 (invoice_payment_failed with payment action link).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP 27+ | All | ✓ | (project-pinned) | — |
| Elixir 1.17+ | All | ✓ | (project-pinned) | — |
| Postgres 14+ | Customer migration (D6-03) | ✓ | (project-pinned) | — |
| `mjml` Rustler NIF | mjml_eex compile-time | ✓ | 0.13.0 | Node + `mjml` npm package (library auto-falls back) |
| Chromium / Chrome | `Accrue.PDF.ChromicPDF` runtime (prod) | **host-owned** | (documented min via ChromicPDF) | `Accrue.PDF.Null` adapter — D6-06 graceful degradation |
| Ghostscript | `ChromicPDF.print_to_pdfa/1` (only when `:archival` opt true) | **host-owned** | 9.52+ typical | Skip `:archival` option; use standard `print_to_pdf/1` |
| Calendar.TimeZoneDatabase (`tz` or `tzdata` dep) | `DateTime.shift_zone/3` for non-UTC | **host-owned, optional** | — | D6-03: wrap with rescue → `Etc/UTC` + telemetry |

**Missing dependencies with no fallback:** None for the library itself. Chromium is host-owned and `Accrue.PDF.Null` is the first-class fallback (D6-06).

**Missing dependencies with fallback:**
- Chromium absent → `Accrue.PDF.Null` returns `{:error, %Accrue.Error.PdfDisabled{}}` → email ships with `hosted_invoice_url` link instead of attachment.
- TZ database absent → wrapped shift falls back to `Etc/UTC` + telemetry warning.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `ExUnit` (pinned via Elixir 1.17) |
| Config file | `accrue/test/test_helper.exs` (existing) |
| Quick run command | `cd accrue && mix test test/accrue/emails test/accrue/pdf test/accrue/invoices test/accrue/mailer --include phase:6` |
| Full suite command | `cd accrue && mix test.all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MAIL-02 | `assert_email_sent(:receipt, to: _)` helper matches intent + options | unit | `mix test test/accrue/test/mailer_assertions_test.exs` | ❌ Wave 0 |
| MAIL-03..13 | Each email type resolves via `resolve_template/1` + subject/render/render_text functions return sane strings | unit (per type) | `mix test test/accrue/emails/<type>_test.exs` | ❌ Wave 0 |
| MAIL-14 | Shared `Accrue.Invoices.Components.invoice_header/1` is rendered by both the HTML bridge and the print_shell | unit | `mix test test/accrue/invoices/components_test.exs` | ❌ Wave 0 |
| MAIL-15 | Every email type has both `render/1` + `render_text/1` returning non-empty binaries | property (over email-type atom list) | `mix test test/accrue/emails/multipart_coverage_test.exs` | ❌ Wave 0 |
| MAIL-16 | `Accrue.Config.branding/0` returns a keyword list with required keys; deprecated flat keys emit warning | unit | `mix test test/accrue/config_branding_test.exs` | ❌ Wave 0 |
| MAIL-17 | `:email_overrides` swap on one type doesn't affect others | unit | `mix test test/accrue/workers/mailer_resolve_template_test.exs` | ❌ Wave 0 |
| MAIL-18 | MJML templates compile to valid HTML containing MJML-emitted MSO conditionals | unit (string contains `<!--[if mso`) | same as MAIL-03..13 | ❌ Wave 0 |
| MAIL-19 | Outlook MSO fallback present in rendered output | unit (string contains `mso-`) | same as MAIL-18 | ❌ Wave 0 |
| MAIL-20 | Oban job enqueued on `accrue_mailers` via `Accrue.Mailer.Default` | integration (Oban.Testing, async: false) | `mix test test/accrue/mailer/default_test.exs` | ❌ Wave 0 |
| MAIL-21 | Money formatting uses CLDR via `Accrue.Cldr` + `ex_money`; unknown locale falls back to `"en"` without raising | property (StreamData over currency × locale × amount) | `mix test test/accrue/invoices/format_money_property_test.exs` | ❌ Wave 0 |
| PDF-02 | `Accrue.PDF.ChromicPDF.render/2` delegates to `ChromicPDF.print_to_pdf/1` | unit (mock ChromicPDF) | `mix test test/accrue/pdf/chromic_pdf_test.exs` | partial (Phase 1) |
| PDF-03 | `Accrue.PDF.Test.render/2` sends `{:pdf_rendered, html, opts}` to `self()` | unit | `mix test test/accrue/pdf/test_test.exs` | ✅ Phase 1 |
| PDF-04 | `Accrue.PDF.Null.render/2` returns `{:error, %Accrue.Error.PdfDisabled{}}` | unit | `mix test test/accrue/pdf/null_test.exs` | ❌ Wave 0 |
| PDF-05 | Shared components produce identical component output regardless of shell | unit | same as MAIL-14 | ❌ Wave 0 |
| PDF-06 | Branding config change is reflected in re-rendered PDF HTML | unit (render twice with different branding) | `mix test test/accrue/invoices/render_test.exs` | ❌ Wave 0 |
| PDF-07 | `Accrue.Billing.render_invoice_pdf/2` returns `{:ok, binary}` in normal path, pattern-matchable errors otherwise | unit | `mix test test/accrue/billing/pdf_test.exs` | ❌ Wave 0 |
| PDF-08 | `Accrue.Mail.InvoiceFinalized` worker attaches PDF via `Swoosh.Email.attachment/2` on success, link on `PdfDisabled` | integration | `mix test test/accrue/workers/invoice_finalized_test.exs` | ❌ Wave 0 |
| PDF-09 | Invoice PDF render happens synchronously inside mailer Oban job; `accrue_mailers` queue concurrency ≤ `session_pool` size per guide | docs + integration (doctest + Oban.Testing) | `mix test test/accrue/workers/pdf_concurrency_test.exs` | ❌ Wave 0 |
| PDF-10 | `%RenderContext{locale, timezone}` threads to both email HTML and PDF HTML | unit | `mix test test/accrue/invoices/render_context_test.exs` | ❌ Wave 0 |
| PDF-11 | Gotenberg adapter path documented in `guides/pdf.md` with a dummy adapter example; no first-party adapter shipped | docs check | `mix test test/accrue/docs/guides_gotenberg_test.exs` (or doctest) | ❌ Wave 0 |

**Manual validation required** (not automatable in CI):
1. **Responsive rendering check matrix** — render each of the 13 email types via `mix accrue.mail.preview` and open in a real mailbox: Gmail web, Gmail iOS/Android, Apple Mail macOS, Apple Mail iOS, Outlook 365 web, Outlook 2019 desktop. Document results in `.planning/phases/06-email-pdf/manual-responsive-check.md`. Acceptance = no horizontal scroll, logo visible, CTA button tappable on mobile.
2. **Real ChromicPDF render** — with Chromium installed, run `mix accrue.mail.preview --only invoice_paid --format pdf` and visually inspect the output. Checks: (a) branding colors apply, (b) line items aligned, (c) totals section not split across pages, (d) `@font-face` fallback to system stack if custom font absent.
3. **PDF/A archival path** — run `Accrue.PDF.render(html, archival: true)` with Ghostscript installed and verify the output passes a PDF/A validator (e.g., veraPDF). Ghostscript requirement is host-owned.
4. **Deliverability smoke test** — send a `receipt` email from a dev sandbox through the host's Swoosh adapter to a mail-tester.com or GlockApps inbox and record the SpamAssassin score. Acceptance = ≥8/10 with default branding.

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/{emails,invoices,pdf,mailer,workers} --exclude live_stripe`
- **Per wave merge:** `cd accrue && mix test.all` (runs format, credo strict, compile --warnings-as-errors, full test)
- **Phase gate:** Full suite green + 4 manual validation checklists complete + `mix accrue.mail.preview --format both` runs clean locally.

### Wave 0 Gaps

- [ ] `test/accrue/test/mailer_assertions_test.exs` — MAIL-02
- [ ] `test/accrue/emails/<type>_test.exs` × 13 (one per email type) — MAIL-03..13
- [ ] `test/accrue/emails/multipart_coverage_test.exs` — MAIL-15
- [ ] `test/accrue/invoices/components_test.exs` — MAIL-14 + PDF-05
- [ ] `test/accrue/invoices/render_test.exs` — PDF-06 + PDF-10
- [ ] `test/accrue/invoices/format_money_property_test.exs` — MAIL-21
- [ ] `test/accrue/config_branding_test.exs` — MAIL-16
- [ ] `test/accrue/workers/mailer_resolve_template_test.exs` — MAIL-17
- [ ] `test/accrue/workers/invoice_finalized_test.exs` — PDF-08
- [ ] `test/accrue/pdf/null_test.exs` — PDF-04
- [ ] `test/accrue/pdf/chromic_pdf_test.exs` — PDF-02 (extend existing)
- [ ] `test/accrue/billing/pdf_test.exs` — PDF-07 (`render_invoice_pdf/2` + `store_invoice_pdf/1` + `fetch_invoice_pdf/1`)
- [ ] `test/accrue/mix/tasks/accrue_mail_preview_test.exs` — D6-08
- [ ] `.accrue/` added to `.gitignore` (via `mix accrue.install` output update in Phase 8; Phase 6 adds a root-level entry)
- [ ] `test/support/email_fixtures.ex` or `accrue/lib/accrue/emails/fixtures.ex` — D6-08 fixture module

*(Framework install: none needed — ExUnit + Oban.Testing + Mox + StreamData are already in place from Phase 1.)*

## Security Domain

Phase 6 touches transactional emails and PDFs containing PII (customer email, invoice amounts, company address). Security enforcement is enabled (default).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Mailer has no auth surface; auth lives at `accrue_admin` (Phase 7) |
| V3 Session Management | no | Stateless render pipeline |
| V4 Access Control | yes | `Accrue.Billing.render_invoice_pdf/2` must verify caller has access to the invoice before returning the binary. Host-owned enforcement at the context-function layer; Phase 7 admin UI adds explicit step-up auth for destructive actions, not reads. Document in guide. |
| V5 Input Validation | yes | `NimbleOptions` validates `:branding` schema (hex colors, email format via `:string`). Locale strings validated via CLDR at enrich time. Timezone strings validated via `DateTime.shift_zone/3` attempt. `assigns[:to]` email address validated implicitly by Swoosh adapter. |
| V6 Cryptography | no | No crypto in this phase; webhook signature verification stays in Phase 2 |
| V7 Error Handling + Logging | yes | Telemetry metadata MUST NOT carry rendered email bodies or raw `assigns` maps — they may contain PII. Phase 1 mailer/pdf span metadata already restricted (`accrue/lib/accrue/mailer.ex:22-25`). Phase 6 adds `[:accrue, :email, :locale_fallback]` + `[:accrue, :email, :timezone_fallback]` — metadata keys are `:requested` only. |
| V9 Communication | yes | Email transport TLS is Swoosh-adapter-owned (host config). PDFs with PII MUST NOT be logged. |
| V13 API | yes (if PDF download route exposed) | PDF-07's download helper must verify access — documented in guide, not automatic. |

### Known Threat Patterns for Email/PDF stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Template injection via customer-controlled `assigns` (e.g., `customer.name` contains `</script><script>`) | Tampering | HEEx auto-escapes all `<%= %>` interpolations by default. Plain-text `.text.eex` does not escape — treat text-body assigns as pre-escaped or route through `Plug.HTML.html_escape_to_iodata/1` for paranoia. |
| PII in logs / telemetry | Information Disclosure | Phase 1 telemetry metadata already restricted to `%{email_type, customer_id}` and `%{size, archival, adapter}`. Phase 6 MUST NOT extend these with assigns or HTML. |
| SSRF via `logo_url` / `hosted_invoice_url` fetched at render time | SSRF | Do not fetch URLs at render time. `logo_url` is referenced by `<img src=...>` inside the rendered HTML; the mail client or PDF renderer decides whether to fetch. For PDFs, recommendation is base64-embed branding logo at startup (host-side) via the same `@font-face` trick. |
| Webhook-driven mailer flood (attacker triggers replays) | DoS | Phase 2 webhook idempotency + Phase 1 Oban `unique: [period: 60, fields: [:args, :worker]]` on `Accrue.Workers.Mailer` — already in place. `[VERIFIED: accrue/lib/accrue/workers/mailer.ex:20]` |
| PDF rendering DoS (infinite inline SVG) | DoS | Chromium has built-in time + memory limits; ChromicPDF session pool timeouts catch runaways. D6-04 performance posture caps concurrency. |
| Unbounded locale atom creation | DoS (atom table exhaustion) | D6-03 `safe_locale_timezone/2` uses try/rescue on CLDR lookup; never `String.to_atom/1`. |
| PDF/A archival forgery | Tampering / Repudiation | Out of scope for v1.0 — no tamper-evident audit on the PDF binary itself; the `accrue_events` ledger is the audit surface. Guide should call out that PDFs are renders, not records. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Phoenix.LiveView.HTMLEngine.component_to_iodata/3` or `Phoenix.HTML.Safe.to_iodata/1` on a `Rendered` struct is the idiomatic HEEx-component → HTML-string bridge for `<mj-raw>` embedding | Pattern 1 + Code Examples | Low — worst case adds a minor API exploration task in Wave 2. The concept (render HEEx → string → embed) is sound; exact function path is the only uncertainty. |
| A2 | mjml_eex Rustler NIF already builds on monorepo target platforms (confirmed by Phase 1 `PaymentSucceeded` existence) | Standard Stack | Already mitigated — Phase 1 shipped the module. Low residual risk. |
| A3 | `ex_cldr_dates_times` is not required for v1.0 if the CLDR backend stays `locales: ["en"]` — `Calendar.strftime/2` is sufficient | Standard Stack + Claude's Discretion | Low for English-only v1.0. If MAIL-21 acceptance requires non-English date localization, add `ex_cldr_dates_times ~> 2.x` in Wave 1. |
| A4 | `Chromium headless` supports `page-break-inside: avoid` on `<tr>` elements | Page-Break Strategy Recommendation | Medium — Chromium's CSS support is generally complete but print-media-query behavior has edge cases. Validate with a long-invoice spike in Wave 4. |
| A5 | `Swoosh.Email.attachment/2` with `{:data, binary}` source is supported and doesn't require temp files | Code Examples + PDF-08 | Low — Swoosh has supported data attachments since 1.x. Verify at implementation time. |
| A6 | CLDR locale string validation via `Cldr.Locale.new!/2` raises on unknown, catchable via rescue | Pattern / Pitfall 5 / Code Examples | Low — CLDR's `new!/2` follows the Elixir bang-fn convention; `new/2` returns `{:error, _}`. Either works. |
| A7 | `Accrue.Billing.Customer` changeset accepts adding two new optional fields (`preferred_locale`, `preferred_timezone`) without breaking existing changeset validations | D6-03 migration | Low — Phase 2 schema is the host-polymorphic Customer, already has `data` jsonb + other optional fields. Similar additions made in Phase 5 for Connect without issue. |
| A8 | The "13+" email types count card_expiring_soon (Phase 3) toward the catalogue rather than as a separate item | Email Type Catalogue | Naming only; planner confirms wave composition. |
| A9 | Rendering a `%Phoenix.LiveView.Rendered{}` (from a function component call outside of a live view mount) via `Phoenix.HTML.Safe.to_iodata/1` yields valid HTML for email embedding | Pattern 1 | Low-medium — this is the load-bearing bridge. Validate first task in Wave 2 with a unit test: call component, render, byte-check against expected markup. |

## Open Questions

1. **Exact HEEx → HTML-string bridge API**
   - What we know: HEEx function components return `%Phoenix.LiveView.Rendered{}` which implements `Phoenix.HTML.Safe`, so `Phoenix.HTML.Safe.to_iodata/1` should produce iodata. `Phoenix.HTML.safe_to_string/1` is the canonical one-shot.
   - What's unclear: Whether this works outside a LiveView process without mounting; whether `Phoenix.Component.to_form/1`-style helpers assume a socket context.
   - Recommendation: First Wave-2 task is a 20-LoC spike in `test/accrue/emails/html_bridge_test.exs` that asserts the call round-trips a trivial `<.foo/>` component with atoms + strings. 10 minutes, unblocks the rest of the wave.

2. **How to plumb the `Accrue.Storage` behaviour through `Accrue.Billing.render_invoice_pdf/2` without adding dead code**
   - What we know: D6-04 says `Null` is the only v1.0 adapter and `store_invoice_pdf/1` no-ops.
   - What's unclear: Whether `fetch_invoice_pdf/1` should live on the Storage behaviour (v1.0 returns `{:error, :not_configured}`) or on `Accrue.Billing` delegating to adapter. Former is cleaner; latter makes v1.1 `Filesystem` easier to wire.
   - Recommendation: Behaviour-layer. Define `@callback put/3`, `@callback get/1`, `@callback delete/1` on `Accrue.Storage`; `Null` returns `{:error, :not_configured}` for `get`. `Accrue.Billing.fetch_invoice_pdf/1` delegates to `Application.get_env(:accrue, :storage_adapter, Accrue.Storage.Null)`.

3. **Do we ship a `Accrue.Mail.*` module namespace for per-email "Oban job wrapper" modules, or fold that into `Accrue.Workers.Mailer`?**
   - What we know: D6-04 mentions `Accrue.Mail.InvoiceFinalized` as the job that renders + attaches PDF.
   - What's unclear: Whether every email type gets its own worker module, or whether `Accrue.Workers.Mailer` stays the single worker and dispatches internally.
   - Recommendation: **Single worker.** Phase 1 already has `Accrue.Workers.Mailer` and adding 13 more workers multiplies Oban queue plumbing. Handle the `invoice_finalized` + `invoice_paid` PDF-attachment branch inline via a `needs_pdf?(type)` predicate in `perform/1`. The D6-04 reference to `Accrue.Mail.InvoiceFinalized` is a naming convention, not a module boundary.

4. **Is `Accrue.Invoices.RenderContext` a struct or a map?**
   - What we know: Both work for `Phoenix.Component` assigns.
   - What's unclear: Whether the type safety + dialyzer value of a struct outweighs the flexibility cost when passing through Oban worker enrichment.
   - Recommendation: **Struct in the render layer, plain map when crossing Oban JSON boundary.** `Accrue.Invoices.Render.build_assigns/2` returns a struct; `Accrue.Workers.Mailer.perform/1` passes a map (JSON-safe IDs only) to the worker, and the worker rehydrates into a struct at render time.

5. **Does Phase 6 touch `accrue_admin` at all, or strictly the `accrue` package?**
   - What we know: D6-08 says Phase 6 ships `mix accrue.mail.preview` (in `accrue` package); Phase 7 adds the LiveView preview route (in `accrue_admin` package).
   - What's unclear: Whether the `AccrueAdmin.EmailPreviewLive` scaffold can be sketched in Phase 6 or must wait.
   - Recommendation: **Strictly `accrue` in Phase 6.** Keep the handoff clean. Fixture module (`Accrue.Emails.Fixtures`) lives in `accrue/lib` so `accrue_admin` can `import` it in Phase 7.

## Sources

### Primary (HIGH confidence)

- **Codebase files read:** `accrue/mix.exs` (line 47-62 deps), `accrue/lib/accrue/mailer.ex` (full), `accrue/lib/accrue/mailer/default.ex` (full), `accrue/lib/accrue/workers/mailer.ex` (full), `accrue/lib/accrue/pdf.ex` (full), `accrue/lib/accrue/pdf/chromic_pdf.ex` (full), `accrue/lib/accrue/emails/payment_succeeded.ex` (full), `accrue/lib/accrue/cldr.ex` (full), `accrue/lib/accrue/config.ex` (lines 1-180 schema sections).
- **Planning documents:** `.planning/phases/06-email-pdf/06-CONTEXT.md` (all 8 locked decisions), `.planning/REQUIREMENTS.md` (MAIL-02..21 + PDF-02..11 + traceability), `.planning/ROADMAP.md` (Phase 6 goal + SC), `.planning/STATE.md` (Phase 1-5 decisions + STATE entries that flow into Phase 6 assumptions).
- **CLAUDE.md §Technology Stack + §Alternatives Considered + §What NOT to Use** — authoritative for stack + forbidden libraries.
- **Hex.pm API (2026-04-15):** verified current versions of `phoenix_swoosh 1.2.1`, `mjml_eex 0.13.0`, `chromic_pdf 1.17.1`, `swoosh 1.25.0`, `ex_cldr 2.47.2`, `ex_money 5.24.2`.

### Secondary (MEDIUM confidence)

- **hexdocs.pm/chromic_pdf/ChromicPDF.html** (2026-04-15 WebFetch): confirmed `@page` CSS is "not correctly interpreted," Ghostscript required for `print_to_pdfa/1`, `print_to_pdf/2` + `Template.source_and_options/1` signatures, session_pool vs on_demand trade-offs.
- **hexdocs.pm/mjml_eex/readme.html** (2026-04-15 WebFetch): confirmed `MjmlEEx.Component` is its own behaviour with string-return render functions, not HEEx. `render_dynamic_component` example shape.
- **github.com/akoutmos/mjml_eex** (2026-04-15 WebFetch): `use MjmlEEx.Component, mode: :runtime` pattern + `<mj-raw>` is an MJML-native pass-through tag (not mjml_eex-specific).

### Tertiary (LOW confidence — flagged for validation)

- **Exact Phoenix.Component → HTML-string API path** — training knowledge says `Phoenix.HTML.Safe.to_iodata/1` on the `Rendered` struct works; not re-verified against Phoenix 1.8 / LiveView 1.1 in this session. Validated at spike time (Wave 2 Task 1 per Open Question 1).
- **Chromium `page-break-inside: avoid` on `<tr>` support** — training knowledge; validate with long-invoice spike.
- **CLDR `Cldr.Locale.new!/2` rescue semantics** — training knowledge; verify at implementation time in `Accrue.Workers.Mailer.enrich/2` rewrite.

## Metadata

**Confidence breakdown:**
- **Standard Stack:** HIGH — all versions verified on Hex.pm 2026-04-15, all deps already in `mix.exs` from Phase 1.
- **Architecture (D6-01 three-layer + bridge):** MEDIUM-HIGH — locked by CONTEXT.md; the HEEx → `<mj-raw>` bridge is conceptually sound but the exact API call needs a 20-LoC spike.
- **Email type catalogue:** HIGH — mapped directly to Phase 3/4 webhook reducers and existing event schemas via STATE.md decisions.
- **Pitfalls:** HIGH — every listed pitfall is either codebase-verified or documented in CONTEXT.md / CLAUDE.md / the ChromicPDF/mjml_eex docs.
- **Test strategy (Validation Architecture):** MEDIUM-HIGH — behaviour-layer `Accrue.Mailer.Test` + `Accrue.PDF.Test` precedent from Phase 1 generalizes cleanly; manual responsive-check matrix is inherently not automatable in CI.
- **Security:** MEDIUM — no new crypto or auth surface, mostly inherits Phase 1 telemetry/logging restrictions. Access-control enforcement for `render_invoice_pdf/2` is host-owned (documented in guide), not automatic.

**Research date:** 2026-04-15
**Valid until:** 2026-06-15 (60 days) — stack is stable, deps are at current minor versions, no fast-moving pieces. Re-verify only if mjml_eex or chromic_pdf cut a major version before Wave 0 starts.
