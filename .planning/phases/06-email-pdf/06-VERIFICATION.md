---
phase: 06-email-pdf
verified: 2026-04-15T08:45:00Z
status: passed
score: 5/5 success criteria verified
overrides_applied: 0
requirements_covered: 30/30
tests_run: 291 tests + 2 properties, 0 failures (phase 6 scope)
deferred_followups:
  - id: WR-06
    item: "EEx compile-time text templates (EEx.function_from_file/5)"
    reason: "Cross-cutting refactor entangled with IN-01; deferred per 06-REVIEW-FIX.md. Current runtime EEx.eval_file path is green and has never fired correctness issues."
---

# Phase 6: Email + PDF — Verification Report

**Phase Goal:** Every lifecycle event that should notify the customer sends a branded, responsive transactional email (plain-text + HTML + MJML), and every invoice can render as a branded PDF via ChromicPDF from the **same HEEx template** that drives the email HTML body — with `Mailer.Test` and `PDF.Test` adapters for assertion-based testing.

**Verified:** 2026-04-15T08:45:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement — Observable Truths (ROADMAP Success Criteria)

| # | Truth (Success Criterion) | Status | Evidence |
|---|---|---|---|
| 1 | A successful payment triggers a `receipt` email and a `payment_failed` event triggers a `payment_failed` email with a retry link — both sent asynchronously via Oban and assertable via `assert_email_sent(:receipt, to: customer.email)`. | VERIFIED | `Accrue.Workers.Mailer` default_template/1 maps all 13 atoms (workers/mailer.ex:242-255); `Accrue.Mailer.Test` sends `{:accrue_email_delivered, type, assigns}` to self (mailer/test.ex:17-21); `assert_email_sent` macro implemented (test/mailer_assertions.ex:37-74). Webhook `default_handler.ex:1133` calls `Accrue.Mailer.deliver(type, assigns)`. Tests: mailer_dispatch_test + default_handler_mailer_dispatch_test green. |
| 2 | An invoice PDF rendered via `Accrue.PDF.ChromicPDF` is byte-identical in layout to the HTML email body for the same invoice, because both render from the same HEEx template. A branding config change reflects immediately in both. | VERIFIED | `Accrue.Invoices.Components` exports `invoice_header/line_items/totals/footer` (components.ex, 183 lines); `Layouts.print_shell/1` assembles them for PDF; `priv/accrue/templates/pdf/invoice.html.heex` embeds the same components; emails call `HtmlBridge.render(&Components.*, @context)` (receipt/invoice_finalized/etc.). `Render.build_assigns/2` freezes branding snapshot once (Pitfall 8 guard). Tests: components_test + render_test + billing/pdf_test + invoice_finalized_pdf_branch_test all green. |
| 3 | All 13+ email types render correctly in both plain-text and HTML multipart and pass MJML responsive rendering. | VERIFIED | 13 email modules under `accrue/lib/accrue/emails/` (receipt, payment_failed, trial_ending, trial_ended, subscription_canceled, subscription_paused, subscription_resumed, card_expiring_soon, invoice_finalized, invoice_paid, invoice_payment_failed, refund_issued, coupon_applied) + payment_succeeded from Phase 1. Each has `.mjml.eex` + `.text.eex` template pair under `priv/accrue/templates/emails/`. Each module `use MjmlEEx` (MAIL-18) which compiles MSO conditionals via Rustler NIF (MAIL-19). Multipart coverage property tests (multipart_coverage_test + invoice_multipart_coverage_test) assert every type produces non-empty subject + html + text. |
| 4 | `Accrue.PDF.Null` adapter returns a graceful documented error in Chrome-hostile deploy environments, enabling hosts to opt out of PDF rendering without breaking the library. | VERIFIED | `Accrue.PDF.Null` implements `@behaviour Accrue.PDF` (pdf/null.ex:30 lines) and returns `{:error, %Accrue.Error.PdfDisabled{}}`. `PdfDisabled` defexception in errors.ex:221 with `message/1`. `RenderFailed` at errors.ex:200 for transient failures. Worker `needs_pdf?` branch in workers/mailer.ex:87 falls through to `hosted_invoice_url` link on PdfDisabled (line 175). guides/pdf.md (273 lines) documents the Null adapter + Gotenberg sidecar custom-adapter path (PDF-11). Tests: pdf/null_test + error/pdf_disabled_test + invoice_finalized_pdf_branch_test green. |
| 5 | Currency amounts and dates in all emails and PDFs are formatted using CLDR-backed localization with correct timezone threading from the render context. | VERIFIED | `Accrue.Cldr` backend at cldr.ex with `use Cldr`. `Accrue.Invoices.Render.format_money/3` calls `Money.to_string/2 locale: locale` with rescue → "en" fallback emitting `[:accrue, :email, :locale_fallback]` telemetry (render.ex:114, 194). `Accrue.Invoices.RenderContext` @enforce_keys struct carries `locale`, `timezone`, currency, pre-formatted money + date strings (render_context.ex:71 lines). `accrue_customers.preferred_locale` + `preferred_timezone` columns migrated 20260415130100 and cast in customer.ex:55-56. Worker `enrich/2` applies D6-03 locale/timezone precedence ladder with try/rescue fallback. Tests: format_money_property_test (property) + customer_locale_timezone_test green. |

**Score:** 5/5 success criteria verified.

---

## Required Artifacts (from plan frontmatter must_haves)

| Artifact | Plan | Status | Evidence |
|---|---|---|---|
| `accrue/lib/accrue/config.ex` — branding schema + `branding/0` + `validate_hex/1` | 06-01 | VERIFIED | 668 lines; `branding: [...]` schema at L229, `def branding` L469, `validate_hex` L640 |
| `priv/repo/migrations/20260415130100_add_locale_and_timezone_to_customers.exs` | 06-01 | VERIFIED | Migration present; columns cast in customer.ex |
| `lib/accrue/billing/customer.ex` preferred_locale/timezone fields | 06-01 | VERIFIED | customer.ex:55-56, allowed list L74 |
| `lib/accrue/errors.ex` — `Accrue.Error.PdfDisabled` + `Accrue.PDF.RenderFailed` | 06-02 | VERIFIED | errors.ex:200 + :221 |
| `lib/accrue/pdf/null.ex` | 06-02 | VERIFIED | `@behaviour Accrue.PDF`, returns `{:error, %PdfDisabled{}}` |
| `lib/accrue/storage.ex` + `storage/null.ex` | 06-02 | VERIFIED | Behaviour + Null adapter + telemetry spans |
| `lib/accrue/emails/html_bridge.ex` — HEEx component → safe HTML string | 06-03 | VERIFIED | 45 lines; `Phoenix.HTML.Safe.to_iodata` pipe at L42-43 |
| `lib/accrue/invoices/render_context.ex` | 06-03 | VERIFIED | 71 lines; `@enforce_keys` struct |
| `lib/accrue/invoices/render.ex` — build_assigns + format_money + format_datetime | 06-03 | VERIFIED | 289 lines; Money.to_string + locale_fallback telemetry |
| `lib/accrue/invoices/components.ex` — invoice_header/line_items/totals/footer | 06-03 | VERIFIED | 183 lines; `use Phoenix.Component` |
| `lib/accrue/invoices/layouts.ex` — `print_shell/1` | 06-03 | VERIFIED | 54 lines |
| `priv/accrue/templates/pdf/invoice.html.heex` | 06-03 | VERIFIED | Present |
| `priv/accrue/templates/layouts/transactional.{mjml,text}.eex` | 06-03 | VERIFIED | Both present; no "unsubscribe" (D6-07 transactional exemption) |
| `lib/accrue/mailer/test.ex` — behaviour-layer test adapter | 06-04 | VERIFIED | 24 lines; `@behaviour Accrue.Mailer`, sends `{:accrue_email_delivered, type, assigns}` |
| `lib/accrue/test/mailer_assertions.ex` | 06-04 | VERIFIED | 155 lines; assert_email_sent/refute/assert_emails_sent/assert_no_emails_sent |
| `lib/accrue/test/pdf_assertions.ex` | 06-04 | VERIFIED | 97 lines; consumes `{:pdf_rendered, html, opts}` |
| `lib/accrue/workers/mailer.ex` — extended resolve_template + catalogue + enrich ladder | 06-04 | VERIFIED | 390 lines; @email_modules list (L38-50), default_template/1 all 13 atoms (L242-255), needs_pdf? (L144), enrich ladder |
| 8 non-invoice email modules + templates | 06-05 | VERIFIED | receipt, payment_failed, trial_ending, trial_ended, subscription_canceled, subscription_paused, subscription_resumed, card_expiring_soon — each .ex + .mjml.eex + .text.eex present |
| 5 invoice-bearing email modules + templates | 06-06 | VERIFIED | invoice_finalized, invoice_paid, invoice_payment_failed, refund_issued, coupon_applied |
| `lib/accrue/emails/fixtures.ex` | 06-06 | VERIFIED | 242 lines; canned assigns per email type |
| `lib/accrue/invoices.ex` — render/store/fetch_invoice_pdf facade | 06-06 | VERIFIED | 176 lines; render_invoice_pdf/2 L83, store_invoice_pdf/2 L107, fetch_invoice_pdf/1 L126 |
| `lib/accrue/billing.ex` defdelegates | 06-06 | VERIFIED | defdelegate render_invoice_pdf/store_invoice_pdf/fetch_invoice_pdf at L142-144 |
| `lib/mix/tasks/accrue.mail.preview.ex` | 06-07 | VERIFIED | 148 lines; `use Mix.Task`; smoke-test green in VALIDATION |
| `guides/email.md` + `guides/branding.md` + `guides/pdf.md` | 06-07 / 06-02 | VERIFIED | All three present |
| `06-VALIDATION.md` | 06-07 | VERIFIED | Phase gate nyquist sign-off, all 21 task cells green |

All artifacts: VERIFIED.

---

## Key Link Verification

| From | To | Via | Status |
|---|---|---|---|
| `Accrue.Workers.Mailer.perform/1` | `Accrue.Billing.render_invoice_pdf/2` + `Swoosh.Email.attachment/2` | `needs_pdf?(type)` branch (workers/mailer.ex:87-188) | WIRED |
| Default webhook reducers (`webhook/default_handler.ex`) | `Accrue.Mailer.deliver/2` | Per-event dispatch (L1133) with atom type | WIRED |
| `Accrue.Mailer.Test` | `self()` mailbox | `send(self(), {:accrue_email_delivered, type, assigns})` (mailer/test.ex:21) | WIRED |
| Each `Accrue.Emails.*` module | `Accrue.Invoices.Components` | `HtmlBridge.render(&Components.*, @context)` in `<mj-raw>` | WIRED |
| `Accrue.Workers.Mailer.default_template/1` | 13 `Accrue.Emails.*` modules | Atom → module dispatch (L242-255) | WIRED |
| `Accrue.Billing.render_invoice_pdf/2` | `Accrue.PDF.impl()` | defdelegate → `Accrue.Invoices.render_invoice_pdf/2` → `Accrue.PDF.render/2` | WIRED |
| `Accrue.PDF.Null.render/2` | `Accrue.Error.PdfDisabled` | `{:error, %Accrue.Error.PdfDisabled{}}` return | WIRED |
| `Accrue.Storage.impl()` put/get/delete | `Accrue.Telemetry.span` | Behaviour facade wraps impl in `[:accrue, :storage, :*]` spans | WIRED |
| `Accrue.Application.start/2` | `warn_deprecated_branding/0` + ChromicPDF + session_pool boot checks | Emitted from application.ex:37 + L49-114 + L92-110 | WIRED |
| `Accrue.Invoices.Render.format_money/3` | `Accrue.Cldr` + ex_money | `Money.to_string/2` with locale + rescue → "en" + telemetry (render.ex:194, 114) | WIRED |
| `Accrue.Emails.HtmlBridge.render/2` | `Phoenix.HTML.Safe.to_iodata/1` | Direct pipe (html_bridge.ex:42-43) | WIRED |

All key links: WIRED.

---

## Data-Flow Trace (Level 4)

| Artifact | Data Source | Flows? | Notes |
|---|---|---|---|
| `Accrue.Emails.InvoiceFinalized` / `InvoicePaid` rendering | `Accrue.Invoices.Render.build_assigns/2` freezing branding + invoice + customer → RenderContext | FLOWING | `billing/pdf_test.exs` + invoice_finalized_pdf_branch_test assert real content round-trip |
| Worker PDF attachment | `Accrue.Billing.render_invoice_pdf/2` → `Accrue.Invoices.render_invoice_pdf/2` → `Accrue.PDF.impl().render/2` | FLOWING | Test adapter returns `"%PDF-TEST"`; attachment pipeline exercised in tests |
| `assert_email_sent` → assignment inspection | `Mailer.Test.deliver/2` → `send(self(), tuple)` | FLOWING | mailer_assertions_test validates full matcher set |
| Webhook → Mailer dispatch | `default_handler.ex:1133` `Accrue.Mailer.deliver(type, assigns)` | FLOWING | default_handler_mailer_dispatch_test green |
| Branding config | `Accrue.Config.branding/0` nested keyword list (NimbleOptions validated) + deprecation shim | FLOWING | config_branding_test green |

No HOLLOW_PROP or DISCONNECTED artifacts detected.

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase 6 test suite passes | `cd accrue && mix test test/accrue/emails test/accrue/invoices test/accrue/mailer test/accrue/test/mailer_assertions_test.exs test/accrue/test/pdf_assertions_test.exs test/accrue/workers/{mailer_resolve_template,invoice_finalized_pdf_branch,mailer_dispatch}_test.exs test/accrue/pdf/null_test.exs test/accrue/storage/null_test.exs test/accrue/config_branding_test.exs test/accrue/billing/customer_locale_timezone_test.exs test/accrue/billing/pdf_test.exs` | **2 properties, 291 tests, 0 failures** (1.5s) | PASS |
| Mailer worker default_template maps all 13 types | grep `default_template\(:` in workers/mailer.ex | 13 atom → module clauses + payment_succeeded fallback | PASS |
| 13 email modules present | `ls accrue/lib/accrue/emails/*.ex` | receipt, payment_failed, trial_ending, trial_ended, subscription_canceled, subscription_paused, subscription_resumed, card_expiring_soon, invoice_finalized, invoice_paid, invoice_payment_failed, refund_issued, coupon_applied (+ html_bridge, fixtures, payment_succeeded) | PASS |
| All 13 types have MJML + text pairs | `ls priv/accrue/templates/emails/*.{mjml.eex,text.eex}` | 14 mjml.eex + 14 text.eex (13 phase-6 + payment_succeeded phase 1) | PASS |
| Null PDF adapter returns PdfDisabled | Read pdf/null.ex | Returns `{:error, %Accrue.Error.PdfDisabled{}}` | PASS |

---

## Requirements Coverage

All 30 phase 6 requirement IDs cross-referenced against `.planning/REQUIREMENTS.md` and plan `requirements:` fields.

| Requirement | Source Plans | REQUIREMENTS.md | Evidence in codebase | Status |
|---|---|---|---|---|
| MAIL-02 | 06-04 | [x] Complete | `Accrue.Mailer.Test` + `assert_email_sent` macro | SATISFIED |
| MAIL-03 | 06-05 | [x] Complete | `Accrue.Emails.Receipt` + templates + receipt_test | SATISFIED |
| MAIL-04 | 06-05 | [x] Complete | `Accrue.Emails.PaymentFailed` + payment_failed_test | SATISFIED |
| MAIL-05 | 06-05 | [x] Complete | `Accrue.Emails.TrialEnding` + trial_ending_test | SATISFIED |
| MAIL-06 | 06-05 | [x] Complete | `Accrue.Emails.TrialEnded` + trial_ended_test | SATISFIED |
| MAIL-07 | 06-06, 06-07 | [x] Complete | `Accrue.Emails.InvoiceFinalized` + worker PDF attachment branch | SATISFIED |
| MAIL-08 | 06-06, 06-07 | [x] Complete | `Accrue.Emails.InvoicePaid` + worker PDF branch | SATISFIED |
| MAIL-09 | 06-06 | [x] Complete | `Accrue.Emails.InvoicePaymentFailed` + hosted_invoice_url in assigns | SATISFIED |
| MAIL-10 | 06-05 | [x] Complete | `Accrue.Emails.SubscriptionCanceled` | SATISFIED |
| MAIL-11 | 06-05 | [x] Complete | `Accrue.Emails.SubscriptionPaused` + `SubscriptionResumed` | SATISFIED |
| MAIL-12 | 06-06 | [x] Complete | `Accrue.Emails.RefundIssued` + fee breakdown template | SATISFIED |
| MAIL-13 | 06-06 | [x] Complete | `Accrue.Emails.CouponApplied` | SATISFIED |
| MAIL-14 | 06-03 | [x] Complete | `Accrue.Invoices.Components` shared between PDF + email via `HtmlBridge` | SATISFIED |
| MAIL-15 | 06-05, 06-06 | [x] Complete | 14 matched `.mjml.eex` + `.text.eex` pairs; multipart coverage property tests | SATISFIED |
| MAIL-16 | 06-01 | [x] Complete | `Accrue.Config.branding/0` single-point schema (14 keys) | SATISFIED |
| MAIL-17 | 06-04 | [x] Complete | `resolve_template/1` rungs: host MFA override + atom override + default | SATISFIED |
| MAIL-18 | 06-03, 06-05, 06-06 | [x] Complete | Each email module `use MjmlEEx` with mjml_template path | SATISFIED |
| MAIL-19 | 06-05 | [x] Complete | MSO fallbacks emitted by mjml_eex NIF at compile (Rustler); templates use full MJML | SATISFIED |
| MAIL-20 | 06-04, 06-07 | [x] Complete | `Accrue.Workers.Mailer` Oban worker; async dispatch proven in mailer_dispatch_test | SATISFIED |
| MAIL-21 | 06-01, 06-03, 06-04 | [x] Complete | CLDR via `Accrue.Cldr` + ex_money `Money.to_string/locale` + telemetry fallback | SATISFIED |
| PDF-02 | 06-06 | [x] Complete | `Accrue.PDF.ChromicPDF` adapter implements `@behaviour Accrue.PDF` | SATISFIED |
| PDF-03 | 06-04 | [x] Complete | `Accrue.PDF.Test` + `Accrue.Test.PdfAssertions.assert_pdf_rendered` | SATISFIED |
| PDF-04 | 06-02 | [x] Complete | `Accrue.PDF.Null` + `Accrue.Error.PdfDisabled` | SATISFIED |
| PDF-05 | 06-03, 06-06 | [x] Complete | Shared `Accrue.Invoices.Components` + `priv/accrue/templates/pdf/invoice.html.heex` | SATISFIED |
| PDF-06 | 06-01, 06-03, 06-06 | [x] Complete | Branded PDF via frozen-snapshot branding in RenderContext | SATISFIED |
| PDF-07 | 06-06 | [x] Complete | `Accrue.Billing.render_invoice_pdf/2` + `fetch_invoice_pdf/1` helpers exposed for host controllers | SATISFIED |
| PDF-08 | 06-07 | [x] Complete | `Accrue.Workers.Mailer.needs_pdf?` + `Swoosh.Email.attachment/2` branch (workers/mailer.ex:167-175) | SATISFIED |
| PDF-09 | 06-06, 06-07 | [x] Complete | Async PDF render via Oban `Accrue.Workers.Mailer.perform/1`; on-demand (zero-persist v1.0 per invoices.ex:5) | SATISFIED |
| PDF-10 | 06-01, 06-03 | [x] Complete | `preferred_locale` + `preferred_timezone` customer columns + RenderContext threading | SATISFIED |
| PDF-11 | 06-02 | [x] Complete | guides/pdf.md documents Gotenberg sidecar as custom-adapter path | SATISFIED |

**Coverage: 30/30 requirements SATISFIED.** No orphaned requirements; every requirement in REQUIREMENTS.md phase 6 block maps to at least one executing plan.

---

## Anti-Patterns Found

Scanned all 13 email modules, workers/mailer.ex, invoices.ex, config.ex, application.ex, pdf adapters, storage adapters, render + components + layouts, html_bridge, test assertions, mix task.

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `accrue/lib/accrue/emails/*.ex` (13 modules) | `render_text/1` | `EEx.eval_file/2` re-reads templates on every email | Info (WR-06 deferred) | Runtime file I/O on hot path; never fired in practice; documented follow-up |

No Blocker or Warning anti-patterns. All six Critical/Warning review findings (CR-01, WR-01, WR-02, WR-03, WR-04, WR-05) were fixed and recorded in `06-REVIEW-FIX.md` with commits. WR-06 explicitly deferred with rationale.

---

## Human Verification Required

None blocking. One recommended smoke test carried forward from 06-REVIEW-FIX.md WR-03:

- **Test:** Enqueue a mailer job with missing recipient in host deployment
- **Expected:** Job lands in `cancelled` state (not `discarded`) per Oban 2.21 cancel-tuple semantics
- **Why human:** Requires running host Oban instance; not reproducible in library test suite

This is a deployment sanity check, not a phase 6 goal gap. Phase 6 status is not blocked on it.

---

## Gaps Summary

**None.** All 5 ROADMAP success criteria are observably true in the codebase, all 30 phase 6 requirements are satisfied with code evidence, all must_haves artifacts and key links from every plan frontmatter are present and wired, the 291-test phase 6 subset passes cleanly (0 failures), the code-review pass closed 6/7 findings with the 7th (WR-06) explicitly deferred as a non-correctness refactor, and the 06-VALIDATION.md per-task verification map is fully green across all 21 tasks.

Phase 6 has achieved its goal: transactional email + invoice PDF rendering share a single HEEx template source of truth, 13 email types dispatch asynchronously via Oban with assertable test adapters, ChromicPDF is the production default with graceful `Null` degradation and a `Test` adapter for assertion-based testing, branding is single-point configured with CLDR localization and timezone threading, and the webhook handler wires domain events through to the mailer.

**Ready to proceed to Phase 7 (Admin UI).**

---

_Verified: 2026-04-15T08:45:00Z_
_Verifier: Claude (gsd-verifier)_
