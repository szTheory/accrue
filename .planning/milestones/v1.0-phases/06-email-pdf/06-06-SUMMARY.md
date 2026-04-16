---
phase: 06-email-pdf
plan: 06
subsystem: invoice-emails-and-pdf-facade
tags: [emails, mjml, pdf, invoices, html-bridge, mail-07, mail-08, mail-09, mail-12, mail-13, pdf-02, pdf-05, pdf-06, pdf-07, pdf-09, pdf-10, d6-04, d6-07, d6-08]

requires:
  - phase: 06-email-pdf
    provides: "Plan 06-02 Accrue.Error.PdfDisabled + Accrue.Storage + Accrue.PDF.Null adapter"
  - phase: 06-email-pdf
    provides: "Plan 06-03 Accrue.Invoices.Render.build_assigns/2 + Accrue.Invoices.Layouts.print_shell/1 + Accrue.Invoices.Components.{invoice_header,line_items,totals,footer} + Accrue.Emails.HtmlBridge"
  - phase: 06-email-pdf
    provides: "Plan 06-04 Accrue.Workers.Mailer.resolve_template/1 — 5 invoice-bearing atoms already mapped to modules landing in this plan"
provides:
  - "Accrue.Invoices — render_invoice_pdf/2 + store_invoice_pdf/2 + fetch_invoice_pdf/1 facade (D6-04)"
  - "Accrue.Billing.render_invoice_pdf/2 + store_invoice_pdf/2 + fetch_invoice_pdf/1 — defdelegates"
  - "Accrue.Emails.InvoiceFinalized (MAIL-07)"
  - "Accrue.Emails.InvoicePaid (MAIL-08)"
  - "Accrue.Emails.InvoicePaymentFailed (MAIL-09)"
  - "Accrue.Emails.RefundIssued (MAIL-12)"
  - "Accrue.Emails.CouponApplied (MAIL-13)"
  - "Accrue.Emails.Fixtures — 13-type canned-assigns module for preview + tests (D6-08)"
affects: [06-07]

tech-stack:
  added: []
  patterns:
    - "Lazy-render PDF facade: no bytes persisted; every render re-hydrates from current DB + current branding snapshot (roadmap SC #2 — retroactive brand consistency)"
    - "ChromicPDF safety net via Process.whereis(ChromicPDF) in Accrue.Invoices — surfaces missing supervisor child as {:error, :chromic_pdf_not_started} instead of raw GenServer crash"
    - "safe_build_assigns/2 wraps Render.build_assigns in try/rescue so Ecto.NoResultsError + other render exceptions become tagged tuples (T-06-06-08 mitigation)"
    - "Invoice-bearing email templates embed Accrue.Invoices.Components.{invoice_header,line_items,totals} via HtmlBridge <mj-raw> — email body mirrors PDF attachment byte-for-byte"
    - "Accrue.Emails.Fixtures lives in lib/ (not test/support/) so mix tasks + Phase 7 LiveView can import without test-env deps"
    - "Per-email TDD: RED-only test commit, then GREEN implementation commit — three tasks × two commits each"

key-files:
  created:
    - accrue/lib/accrue/invoices.ex
    - accrue/lib/accrue/emails/invoice_finalized.ex
    - accrue/lib/accrue/emails/invoice_paid.ex
    - accrue/lib/accrue/emails/invoice_payment_failed.ex
    - accrue/lib/accrue/emails/refund_issued.ex
    - accrue/lib/accrue/emails/coupon_applied.ex
    - accrue/lib/accrue/emails/fixtures.ex
    - accrue/priv/accrue/templates/emails/invoice_finalized.mjml.eex
    - accrue/priv/accrue/templates/emails/invoice_finalized.text.eex
    - accrue/priv/accrue/templates/emails/invoice_paid.mjml.eex
    - accrue/priv/accrue/templates/emails/invoice_paid.text.eex
    - accrue/priv/accrue/templates/emails/invoice_payment_failed.mjml.eex
    - accrue/priv/accrue/templates/emails/invoice_payment_failed.text.eex
    - accrue/priv/accrue/templates/emails/refund_issued.mjml.eex
    - accrue/priv/accrue/templates/emails/refund_issued.text.eex
    - accrue/priv/accrue/templates/emails/coupon_applied.mjml.eex
    - accrue/priv/accrue/templates/emails/coupon_applied.text.eex
    - accrue/test/accrue/billing/pdf_test.exs
    - accrue/test/accrue/emails/invoice_finalized_test.exs
    - accrue/test/accrue/emails/invoice_paid_test.exs
    - accrue/test/accrue/emails/invoice_payment_failed_test.exs
    - accrue/test/accrue/emails/refund_issued_test.exs
    - accrue/test/accrue/emails/coupon_applied_test.exs
    - accrue/test/accrue/emails/invoice_multipart_coverage_test.exs
    - accrue/test/accrue/emails/fixtures_test.exs
  modified:
    - accrue/lib/accrue/billing.ex

decisions:
  - "Task 1 tests need Code.ensure_loaded!(Accrue.Billing) before function_exported?/3 checks because defdelegate targets are resolved at runtime in a test process that may not have autoloaded the facade module yet"
  - "adapter_opts/1 whitelist includes header_html + footer_html alongside paper-size keys — covers ChromicPDF header/footer overrides even though the print_shell layout carries them inline"
  - "RefundIssued + CouponApplied deliberately do NOT embed the shared invoice components (invoice_header/line_items/totals) — refunds and coupons are distinct flows from invoice lifecycles; embedding would force a misleading invoice-shaped render"
  - "InvoicePaymentFailed CTA routes directly to @context.invoice.hosted_invoice_url (Stripe-hosted pay page) rather than a host-supplied update_pm_url — MAIL-09 payment-action semantics require a payable surface, not a payment-method edit surface"
  - "base_context formatted_issued_at set to 'April 15, 2026' static string (not DateTime-derived) to honor D6-08 determinism — Accrue.Emails.Fixtures has zero DateTime.utc_now calls"

requirements-completed: [MAIL-07, MAIL-08, MAIL-09, MAIL-12, MAIL-13, PDF-02, PDF-05, PDF-06, PDF-07, PDF-09, PDF-10]

metrics:
  duration: "~8m"
  tasks_completed: 3
  files_changed: 26
  tests_added: 58
  completed_date: "2026-04-15"
---

# Phase 6 Plan 06: Invoice-bearing Emails + PDF Facade Summary

**One-liner:** Ships the Accrue.Invoices lazy-render PDF facade (with ChromicPDF safety net, Null tagged-error fallback, and Storage delegation), five invoice-bearing email types (InvoiceFinalized / InvoicePaid / InvoicePaymentFailed / RefundIssued / CouponApplied) with shared-component embedding via HtmlBridge, and the Accrue.Emails.Fixtures canned-assigns module reused by Plan 06-07's mix preview task and the Phase 7 LiveView.

## Deliverables

### 1. Accrue.Invoices facade (D6-04)

Exact signatures:

```elixir
@spec render_invoice_pdf(Accrue.Billing.Invoice.t() | String.t(), keyword()) ::
        {:ok, binary()} | {:error, term()}

@spec store_invoice_pdf(Accrue.Billing.Invoice.t() | String.t(), keyword()) ::
        {:ok, String.t()} | {:error, term()}

@spec fetch_invoice_pdf(Accrue.Billing.Invoice.t() | String.t()) ::
        {:ok, binary()} | {:error, term()}
```

**Error tuple shapes the facade can return:**

| Tuple | Cause | Caller disposition |
|-------|-------|---------------------|
| `{:ok, binary}` | `Accrue.PDF.Test` or `ChromicPDF` rendered successfully | attach to email or store |
| `{:error, %Accrue.Error.PdfDisabled{}}` | `Accrue.PDF.Null` configured | fall through to `hosted_invoice_url` link |
| `{:error, :chromic_pdf_not_started}` | `Accrue.PDF.ChromicPDF` configured but no `ChromicPDF` GenServer in host supervisor (Pitfall 4) | non-retriable; log + return to user as `:server_error` |
| `{:error, %Ecto.NoResultsError{}}` | invoice id not found (wrapped by `safe_build_assigns/2`) | not a transient failure; log + drop |
| `{:error, other}` | render or storage adapter error | Plan 07 worker retries via Oban backoff |

**Lazy render rationale:** no PDF bytes persisted; every call re-hydrates the invoice from current DB state + current branding snapshot. This preserves retroactive brand consistency (roadmap SC #2) and removes the pressure to force a storage backend on hosts that don't need one.

**Opts whitelist forwarded to adapter:** `:size`, `:paper_width`, `:paper_height`, `:margin_top`, `:margin_bottom`, `:margin_left`, `:margin_right`, `:archival`, `:header_html`, `:footer_html`. Per Pitfall 6, paper size is an adapter option — never a CSS `@page` rule.

### 2. Five invoice-bearing email modules

| Module | MAIL ID | Subject shape | Shared components? | PDF-attach path? |
|--------|---------|---------------|--------------------|-------------------|
| `Accrue.Emails.InvoiceFinalized` | MAIL-07 | "Invoice {num} from {business_name}" | invoice_header + line_items + totals + footer | yes (wired by Plan 07) |
| `Accrue.Emails.InvoicePaid` | MAIL-08 | "Payment received for invoice {num}" | invoice_header + line_items + totals + footer | yes (wired by Plan 07) |
| `Accrue.Emails.InvoicePaymentFailed` | MAIL-09 | "Action required: payment failed for invoice {num}" | footer only + Pay now CTA → `hosted_invoice_url` | no (link only) |
| `Accrue.Emails.RefundIssued` | MAIL-12 | "Refund issued for charge {charge.id}" | footer + fee-breakdown table | no |
| `Accrue.Emails.CouponApplied` | MAIL-13 | "Discount applied — {coupon.name\|promotion.code}" | footer + cond fan-out for percent_off/amount_off | no |

Each module is ~40 LOC — same pattern as Plan 05 non-invoice modules: `use MjmlEEx` + `subject/1` (two-clause with fallback) + `render_text/1` via `EEx.eval_file` + `to_keyword/1` helper that silently drops unknown string keys.

Every template:
* Honors D6-07 (no unsubscribe line)
* Renders `Accrue.Invoices.Components.footer/1` via `HtmlBridge` inside `<mj-raw>`
* MJML compiler emits MSO conditionals automatically (MAIL-19)

### 3. Accrue.Emails.Fixtures (D6-08)

Pure-data module in `lib/` providing one builder per email type (13 total) plus `base_context/0` + `all/0` aggregator. Deterministic (no `DateTime.utc_now/0`), zero side effects (no `Accrue.Repo` calls), rendering-safe (every fixture passes through its corresponding email module's `subject/1 + render/1 + render_text/1` without raising).

**Per-type additional fields beyond `base_context()`:**

| Fixture | Extra fields |
|---------|--------------|
| `receipt` | — |
| `payment_failed` | `update_pm_url` |
| `trial_ending` | `days_until_end: 3`, `cta_url` (also set on ctx) |
| `trial_ended` | `cta_url` |
| `invoice_finalized` | — (uses base) |
| `invoice_paid` | — |
| `invoice_payment_failed` | — (uses base's `invoice.hosted_invoice_url`) |
| `subscription_canceled` | — |
| `subscription_paused` | `pause_behavior: "keep_as_draft"` |
| `subscription_resumed` | — |
| `refund_issued` | `refund: %{formatted_amount, formatted_stripe_fee_refunded, formatted_merchant_loss}`, `charge: %{id}` |
| `coupon_applied` | `coupon: %{name, percent_off, formatted_amount_off}`, `promotion_code: %{code}` |
| `card_expiring_soon` | `last4`, `exp_month`, `exp_year`, `brand`, `cta_url` |

## Commits

| Task | RED commit | GREEN commit | Tests |
|------|-----------|---------------|-------|
| 1 — PDF facade + Billing delegates | `31cc3ad` | `f9bd759` | 12 |
| 2 — 5 invoice-bearing email modules | `d04c2ba` | `4c1cd16` | 39 |
| 3 — Accrue.Emails.Fixtures | `2d24af8` | `1909218` | 7 |

**Total: 58 new tests. All green. Full suite 46 properties + 971 tests + 0 failures.**

## PDF-attachment Branch — Hand-off to Plan 07

Plan 07 wires `Accrue.Workers.Mailer` to:

1. On `:invoice_finalized` or `:invoice_paid` dispatch: call `Accrue.Invoices.render_invoice_pdf(ctx.invoice, locale: ctx.locale, timezone: ctx.timezone)`.
2. On `{:ok, binary}`: attach via `Swoosh.Email.attachment(%Swoosh.Attachment{filename: "invoice-#{inv.number}.pdf", content_type: "application/pdf", data: binary})`.
3. On `{:error, %Accrue.Error.PdfDisabled{}}`: do NOT attach — rely on the template's `<a href="#{hosted_invoice_url}">` link as graceful fallback (Phase 6 SC #4).
4. On `{:error, :chromic_pdf_not_started}`: log a clear warning AND fall through to the same hosted-link path — do NOT retry (stable adapter misconfig, not a transient failure).
5. On any other `{:error, _}`: let Oban retry with backoff.

The templates for `invoice_finalized` + `invoice_paid` already carry the "A PDF copy is attached" prose wired to display regardless of whether the attachment actually lands — the fallback hosted-URL link renders alongside it, so a Null-adapter render still surfaces a working payment surface.

## Deviations from Plan

**None as deviations — one minor test-side discovery documented below.**

### Test harness note: `Code.ensure_loaded!/1` before `function_exported?/3`

**Found during:** Task 1 GREEN verification.

**Issue:** Three defdelegate assertions (`assert function_exported?(Accrue.Billing, :render_invoice_pdf, 2)`) failed on first GREEN run because `function_exported?/3` returns `false` for modules that have not been loaded into the current VM. Test processes in this codebase don't auto-load `Accrue.Billing` until first call.

**Fix:** Added `Code.ensure_loaded!(Accrue.Billing)` before each `function_exported?` assertion. The three per-delegate tests still pass the subsequent actual-call assertion, so the property being tested is preserved.

**Files modified:** `accrue/test/accrue/billing/pdf_test.exs` (folded into Task 1 GREEN commit `f9bd759`).

Not classified as a deviation — it's a test-harness adjustment, not a plan-level correction.

## Authentication Gates

None.

## Known Stubs

None. Every email module has complete working copy, every template renders, every fixture is self-consistent.

## Self-Check: PASSED

Verified on disk:

- `accrue/lib/accrue/invoices.ex` — FOUND
- `accrue/lib/accrue/emails/invoice_finalized.ex` — FOUND
- `accrue/lib/accrue/emails/invoice_paid.ex` — FOUND
- `accrue/lib/accrue/emails/invoice_payment_failed.ex` — FOUND
- `accrue/lib/accrue/emails/refund_issued.ex` — FOUND
- `accrue/lib/accrue/emails/coupon_applied.ex` — FOUND
- `accrue/lib/accrue/emails/fixtures.ex` — FOUND
- 10 templates under `accrue/priv/accrue/templates/emails/` — FOUND
- 8 test files — FOUND (pdf_test, 5 × per-email, invoice_multipart_coverage, fixtures)
- Commit `31cc3ad` (Task 1 RED) — FOUND
- Commit `f9bd759` (Task 1 GREEN) — FOUND
- Commit `d04c2ba` (Task 2 RED) — FOUND
- Commit `4c1cd16` (Task 2 GREEN) — FOUND
- Commit `2d24af8` (Task 3 RED) — FOUND
- Commit `1909218` (Task 3 GREEN) — FOUND
- Plan-scoped tests: 58 new, 0 failures
- Full regression: `mix test` → 46 properties + 971 tests + 0 failures (10 excluded live_stripe/slow tags)
- `mix compile --warnings-as-errors` — clean

## Verification

```bash
cd accrue && mix compile --warnings-as-errors
  # Generated accrue app (no warnings)

cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/emails/
  # 129 tests, 0 failures

cd accrue && mix test
  # 46 properties, 971 tests, 0 failures (10 excluded)
```

`mix format --check-formatted` was not run — the `accrue/` package does not ship a `.formatter.exs` at the project root (historical), which is a plan-wide observation, not a Plan 06-06 regression. `mix credo --strict` and `mix dialyzer` were not run in this agent session (same rationale as Plan 05: baseline checks expected to pass, new findings out of plan scope).

## Ready for

Plan 06-07 — close-out plan: mix accrue.mail.preview task + guides/pdf.md + guides/emails.md. The Fixtures module shipped here is its primary dependency.
