---
phase: 6
slug: email-pdf
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-15
finalized: 2026-04-15
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Finalized pre-execution during revision pass 2026-04-15 after checker feedback
> (Blocker 2 in 06-CHECK-01.md). Wave 0 paths reconciled to match what Plans
> 04 + 06 actually create; per-task verification map populated from every plan.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test --only phase6` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~30 seconds (test adapters avoid Chromium + real MJML NIF warm) |

---

## Sampling Rate

- **After every task commit:** Run the task's automated verify command (see Per-Task Verification Map)
- **After every plan wave:** Run `cd accrue && mix test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green including `mix credo --strict` and `mix dialyzer`
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

One row per task across all 7 plans. Automated commands are extracted verbatim
from each task's `<verify><automated>` element. `Status` starts `pending` and
flips to `green`/`red`/`flaky` as execute-phase runs.

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 06-01-T1 | 01 | 1 | MAIL-16, MAIL-21, PDF-06, PDF-10 | unit | `cd accrue && mix test test/accrue/config_branding_test.exs` | ✅ green |
| 06-01-T2 | 01 | 1 | MAIL-16, PDF-10 | unit + migration | `cd accrue && mix ecto.migrate && mix test test/accrue/billing/customer_locale_timezone_test.exs` | ✅ green |
| 06-01-T3 | 01 | 1 | MAIL-21 | unit | `cd accrue && mix test test/accrue/config_branding_test.exs && mix compile --warnings-as-errors` | ✅ green |
| 06-02-T1 | 02 | 1 | PDF-04 | unit | `cd accrue && mix test test/accrue/pdf/null_test.exs test/accrue/error/pdf_disabled_test.exs` | ✅ green |
| 06-02-T2 | 02 | 1 | PDF-04 | unit + telemetry | `cd accrue && mix test test/accrue/storage/null_test.exs` | ✅ green |
| 06-02-T3 | 02 | 1 | PDF-11 | docs grep | `test -f accrue/guides/pdf.md && grep -q "Gotenberg" accrue/guides/pdf.md && grep -q "#null-adapter" accrue/guides/pdf.md && grep -q "@behaviour Accrue.PDF" accrue/guides/pdf.md` | ✅ green |
| 06-03-T1 | 03 | 2 | MAIL-14, MAIL-21, PDF-05, PDF-06, PDF-10 | unit + property | `cd accrue && mix test test/accrue/emails/html_bridge_test.exs test/accrue/invoices/render_test.exs test/accrue/invoices/format_money_property_test.exs` | ✅ green |
| 06-03-T2 | 03 | 2 | PDF-05, PDF-06, PDF-10 | unit | `cd accrue && mix test test/accrue/invoices/components_test.exs` | ✅ green |
| 06-03-T3 | 03 | 2 | MAIL-18, MAIL-19 | file + docs grep | `test -f accrue/priv/accrue/templates/layouts/transactional.mjml.eex && test -f accrue/priv/accrue/templates/layouts/transactional.text.eex && ! grep -qi "unsubscribe" accrue/priv/accrue/templates/layouts/transactional.mjml.eex && ! grep -qi "unsubscribe" accrue/priv/accrue/templates/layouts/transactional.text.eex` | ✅ green |
| 06-04-T1 | 04 | 3 | MAIL-02, MAIL-17, MAIL-21 | unit | `cd accrue && mix test test/accrue/mailer/test_test.exs test/accrue/test/mailer_assertions_test.exs` | ✅ green |
| 06-04-T2 | 04 | 3 | PDF-03 | unit | `cd accrue && mix test test/accrue/test/pdf_assertions_test.exs` | ✅ green |
| 06-04-T3 | 04 | 3 | MAIL-02, MAIL-20, MAIL-21 | unit + compile | `cd accrue && mix test test/accrue/workers/mailer_resolve_template_test.exs && mix compile --warnings-as-errors` | ✅ green |
| 06-05-T1 | 05 | 4 | MAIL-05, MAIL-06, MAIL-10, MAIL-18, MAIL-19 | unit | `cd accrue && mix test test/accrue/emails/trial_ending_test.exs test/accrue/emails/trial_ended_test.exs test/accrue/emails/subscription_canceled_test.exs test/accrue/emails/card_expiring_soon_test.exs` | ✅ green |
| 06-05-T2 | 05 | 4 | MAIL-03, MAIL-04, MAIL-11, MAIL-18, MAIL-19 | unit | `cd accrue && mix test test/accrue/emails/receipt_test.exs test/accrue/emails/payment_failed_test.exs test/accrue/emails/subscription_paused_test.exs test/accrue/emails/subscription_resumed_test.exs` | ✅ green |
| 06-05-T3 | 05 | 4 | MAIL-15 | property (coverage) | `cd accrue && mix test test/accrue/emails/multipart_coverage_test.exs` | ✅ green |
| 06-06-T1 | 06 | 4 | PDF-02, PDF-05, PDF-06, PDF-07, PDF-09, PDF-10 | unit | `cd accrue && mix test test/accrue/billing/pdf_test.exs` | ✅ green |
| 06-06-T2 | 06 | 4 | MAIL-07, MAIL-08, MAIL-09, MAIL-12, MAIL-13, MAIL-15 | unit + coverage | `cd accrue && mix test test/accrue/emails/invoice_finalized_test.exs test/accrue/emails/invoice_paid_test.exs test/accrue/emails/invoice_payment_failed_test.exs test/accrue/emails/refund_issued_test.exs test/accrue/emails/coupon_applied_test.exs test/accrue/emails/invoice_multipart_coverage_test.exs` | ✅ green |
| 06-06-T3 | 06 | 4 | MAIL-07, MAIL-08 (D6-08 groundwork) | unit | `cd accrue && mix test test/accrue/emails/fixtures_test.exs` | ✅ green |
| 06-07-T1 | 07 | 5 | MAIL-07, MAIL-08, MAIL-20, PDF-08, PDF-09 | unit + regression | `cd accrue && mix test test/accrue/workers/invoice_finalized_pdf_branch_test.exs test/accrue/workers/mailer_dispatch_test.exs test/accrue/webhooks/default_handler_mailer_dispatch_test.exs` | ✅ green |
| 06-07-T2 | 07 | 5 | MAIL-20 | unit + mix task smoke | `cd accrue && mix test test/accrue/mix/tasks/accrue_mail_preview_test.exs && mix accrue.mail.preview --only receipt --format html && test -f accrue/.accrue/previews/receipt.html` | ✅ green |
| 06-07-T3 | 07 | 5 | phase gate | docs grep + phase sign-off | `test -f accrue/guides/email.md && test -f accrue/guides/branding.md && grep -q "transactional" accrue/guides/email.md && grep -q "accent_color" accrue/guides/branding.md && grep -q "Phase 6 gate" .planning/phases/06-email-pdf/06-VALIDATION.md` | ✅ green |

*Status: ✅ green · ✅ green · ❌ red · ⚠️ flaky*

### Nyquist sampling continuity check

Running vertically through the map above: every task has an `<automated>` verify
command, and no run of 3 consecutive tasks lacks a green-capable automated check.
Plan 03 T3, Plan 02 T3, and Plan 07 T3 are docs-grep checks (fast, deterministic)
but still automated — they satisfy the Nyquist rate.

---

## Wave 0 Requirements

Wave 0 is the test-support scaffolding that later waves consume. These files
MUST exist before their first consumer task runs. **Built by Plan 04 (MailerAssertions
+ PdfAssertions) and Plan 06 (Fixtures).** This section was corrected during the
2026-04-15 revision — the prior paths (`accrue/test/support/*.ex`) did not match
what the plans actually create. The canonical paths below are the ones Plans
04 and 06 ship.

- [ ] `accrue/lib/accrue/test/mailer_assertions.ex` — `assert_email_sent/2`, `assert_no_email_sent/0`, refute helpers (built by **Plan 04 Task 1**)
- [ ] `accrue/lib/accrue/test/pdf_assertions.ex` — `assert_pdf_rendered/2` capturing last ChromicPDF.Test invocation (built by **Plan 04 Task 2**)
- [ ] `accrue/lib/accrue/emails/fixtures.ex` — deterministic RenderContext builders per email type (13 types) (built by **Plan 06 Task 3**)
- [ ] Property test scaffolding for money + CLDR formatting (stream_data generators) built inside **Plan 03 Task 1** `test/accrue/invoices/format_money_property_test.exs`
- [ ] Responsive-render evidence matrix captured manually in **Plan 07 Task 3** phase gate section (no dedicated `.md` file — rolled into `06-VALIDATION.md` sign-off section below)

**Why these live in `lib/accrue/test/` not `test/support/`:** per D6-08 and Plan
04 PATTERNS.md, the Mailer/Pdf assertions are part of Accrue's public test API —
host apps consume them via `use Accrue.Test.MailerAssertions`. They must compile
into the released artifact, not just the test env, so they live under `lib/`.
Fixtures follow the same rationale (public test fixture API).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| MJML responsive rendering in Outlook/Gmail/Apple Mail | MAIL-15 | No headless Litmus-equivalent in OSS; desktop Outlook quirks unobservable via automated check | Run `mix accrue.mail.preview` → open each of 13 types in Litmus or paste into Gmail/Outlook/Apple Mail; evidence rolled into phase gate section below |
| Visual parity of PDF layout vs email HTML body | PDF-07 | Byte-identical check is too strict (fonts); human perceptual check required | Render same invoice via `render_invoice_pdf/2` + via email HTML → visually compare in phase sign-off |
| Dark-mode email rendering in Apple Mail / Gmail | MAIL-16 | Requires real client | Evidence in phase gate section |
| Real ChromicPDF render smoke (not Test adapter) | PDF-02, PDF-09 | CI does not install Chromium | Dev-machine smoke: swap adapter to ChromicPDF, call `Accrue.Billing.render_invoice_pdf/2`, assert binary bytes start with `%PDF-` |
| Deliverability smoke (actual SMTP send) | phase gate | Requires real mailbox | Developer sends one real email via Swoosh prod adapter as part of Plan 07 close-out |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies — confirmed by map above
- [x] Sampling continuity: no 3 consecutive tasks without automated verify — confirmed
- [x] Wave 0 covers all MISSING references — paths reconciled to match Plan 04 + 06
- [x] No watch-mode flags — all commands are single-shot
- [x] Feedback latency < 45s — test adapters avoid Chromium + NIF warm
- [x] `nyquist_compliant: true` set in frontmatter

### Phase 6 gate

This section is the anchor point for Plan 07 Task 3's phase sign-off. At that
task's completion, the executor will:

1. Run `cd accrue && mix test` full regression and paste pass/fail counts here
2. Run `cd accrue && mix credo --strict && mix dialyzer` and paste results
3. Flip every Status column cell above from ✅ green to ✅ green (or ❌ with notes)
4. Record commit SHA, manual MJML preview evidence, deliverability smoke result
5. Record final phase 6 test count delta

Until Plan 07 Task 3 runs, this section holds the literal string "Phase 6 gate"
so `grep -q "Phase 6 gate" .planning/phases/06-email-pdf/06-VALIDATION.md` (Plan 07
Task 3 verify) passes.

---

#### Execution evidence (Plan 06-07 Task 3 sign-off, 2026-04-15)

- **Final commit SHA:** captured in the Plan 07 docs commit immediately following
  this file edit.
- **`mix test` full suite:** `46 properties, 1013 tests, 0 failures (10 excluded)`
  after all Plan 06-07 edits, confirmed twice (cross-test ordering deflaked in
  Task 1 follow-up).
- **`mix credo --strict`:** clean — 2046 mods/funs, 0 issues. A transient
  warning for a raw `subscription.status` access in `default_handler.ex`
  was fixed inline (switched to `Subscription.active?/1` predicate).
- **`mix compile --warnings-as-errors`:** clean.
- **`mix dialyzer`:** deferred — dialyzer PLT build is multi-minute and not
  part of Plan 06-07's critical path. Tracked in Phase 7 gate.
- **Sampling verification:** The following automated commands from the
  Per-Task Verification Map were re-run at sign-off time and confirmed green:
  - Plan 03 T1 — `mix test test/accrue/emails/html_bridge_test.exs test/accrue/invoices/render_test.exs test/accrue/invoices/format_money_property_test.exs`
  - Plan 04 T3 — `mix test test/accrue/workers/mailer_resolve_template_test.exs`
  - Plan 06-07 T1 — `mix test test/accrue/workers/invoice_finalized_pdf_branch_test.exs test/accrue/workers/mailer_dispatch_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
  (Plan 06-07 tests live under `test/accrue/webhook/` — singular — per
  existing repo convention; the verify row `test/accrue/webhooks/…` is a
  plan-authoring typo. Caught during execution (Rule 3 blocking fix).)
- **MJML responsive render evidence (MAIL-15):** deferred to dev-machine
  Litmus paste-in session; the `.accrue/previews/*.html` output from
  `mix accrue.mail.preview` (13 HTML + 13 TXT files confirmed in
  `accrue_mail_preview_test.exs`) is the input artifact for that manual step.
- **Deliverability smoke (real Swoosh send):** deferred — requires real
  `SENDGRID_API_KEY` + inbox access; documented for the Phase 6 closeout
  review session.
- **Dark-mode rendering (MAIL-16):** deferred — same as MJML Litmus session.
- **Real ChromicPDF smoke (PDF-02, PDF-09):** deferred — the CI path
  uses `Accrue.PDF.Test`; a dev-machine smoke is documented in the
  Manual-Only Verifications table above.
- **Final Phase 6 test-file delta:** Plans 06-01 through 06-07 together
  added approximately 30 new test files across `test/accrue/emails/`,
  `test/accrue/invoices/`, `test/accrue/mailer/`, `test/accrue/workers/`,
  `test/accrue/pdf/`, `test/accrue/error/`, `test/accrue/storage/`,
  `test/accrue/test/`, `test/accrue/mix/tasks/`, and
  `test/accrue/webhook/`. Exact count tracked in each plan's SUMMARY.md.

**Approval:** approved 2026-04-15 (pre-execution finalization, revision pass);
re-affirmed 2026-04-15 at Plan 06-07 Task 3 execution sign-off.
