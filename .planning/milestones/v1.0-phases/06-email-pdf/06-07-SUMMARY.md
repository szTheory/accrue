---
phase: 06-email-pdf
plan: 07
subsystem: mailer-dispatch-wiring-and-phase-gate
tags: [mailer, webhook, pdf, mix-task, boot-guard, guides, phase-gate, mail-07, mail-08, mail-20, pdf-08, pdf-09, d6-04, d6-07, d6-08]

requires:
  - phase: 06-email-pdf
    provides: "Plan 06-04 Accrue.Workers.Mailer.perform/1 base render pipeline + resolve_template/1 catalogue"
  - phase: 06-email-pdf
    provides: "Plan 06-05 non-invoice email modules (receipt, payment_failed, trial_ending, trial_ended, subscription_*)"
  - phase: 06-email-pdf
    provides: "Plan 06-06 Accrue.Billing.render_invoice_pdf/2 + invoice-bearing email modules + Accrue.Emails.Fixtures"
  - phase: 03-billing
    provides: "Accrue.Webhook.DefaultHandler reducer framework"

provides:
  - "Accrue.Workers.Mailer.perform/1 — PDF attachment branch via needs_pdf?/1 + maybe_attach_pdf/3"
  - "Accrue.Workers.Mailer.template_for/1 — public catalogue accessor for mix preview"
  - "Accrue.PDF.RenderFailed — transient-error exception for Oban backoff"
  - "Accrue.Webhook.DefaultHandler.maybe_dispatch_*_email/2-3 — post-commit mailer dispatch for charge/refund/invoice/subscription reducers"
  - "Mix.Tasks.Accrue.Mail.Preview — mix accrue.mail.preview task with --only + --format flags"
  - "Accrue.Application.warn_pdf_adapter_unavailable/0 — Pitfall 3 boot guard"
  - "Accrue.Application.warn_oban_queue_vs_pdf_pool/0 — Pitfall 4 boot guard"
  - "Accrue.Application.warn_company_address_locale_mismatch/0 — D6-07 EU/CA locale guard"
  - "guides/email.md — Phase 6 email configuration guide"
  - "guides/branding.md — Phase 6 branding schema reference + migration"
  - ".planning/phases/06-email-pdf/06-VALIDATION.md — Phase 6 gate sign-off"

affects: [07-admin]

tech-stack:
  added: []
  patterns:
    - "Reducer-level mailer dispatch happens OUTSIDE Repo.transact/1 wrapper so rollbacks never enqueue ghost emails (Pitfall 7 single-dispatch + Pitfall 7 atomicity)"
    - "safe_deliver/2 wraps Accrue.Mailer.deliver in try/rescue + try/catch, emitting [:accrue, :mailer, :dispatch_failed] telemetry — dispatch failure never rolls back state reconciliation (T-06-07-08)"
    - "PDF attachment branch lazy-renders at delivery time (D6-04) rather than persisting bytes — retroactive brand consistency preserved"
    - "Mix preview task uses Mix.Task.run(\"loadpaths\") instead of app.start so host apps without :repo/:secret_key_base can still run mix accrue.mail.preview (fixtures are pure data)"
    - "Boot guards use :persistent_term dedupe pattern matching Plan 01 warn_deprecated_branding — distinct keys per guard, idempotent under reboot-within-same-BEAM-instance"

key-files:
  created:
    - accrue/lib/mix/tasks/accrue.mail.preview.ex
    - accrue/.gitignore
    - accrue/guides/email.md
    - accrue/guides/branding.md
    - accrue/test/accrue/workers/invoice_finalized_pdf_branch_test.exs
    - accrue/test/accrue/workers/mailer_dispatch_test.exs
    - accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs
    - accrue/test/accrue/mix/tasks/accrue_mail_preview_test.exs
    - accrue/test/accrue/application_boot_guards_test.exs
  modified:
    - accrue/lib/accrue/errors.ex
    - accrue/lib/accrue/workers/mailer.ex
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/lib/accrue/application.ex
    - accrue/test/accrue/application_test.exs
    - .planning/phases/06-email-pdf/06-VALIDATION.md

decisions:
  - "Webhook reducers dispatch mailer AFTER Repo.transact returns — not inside — so transaction rollback (stale event, deferred, upsert error) never leaks a ghost email. Trade-off: one extra DB hit for refund_customer_id lookup (via Repo.get(Charge, charge_id)) which is negligible at webhook rates"
  - "DefaultHandlerMailerDispatchTest lives under test/accrue/webhook/ (singular) not test/accrue/webhooks/ (plural) — matches the existing Phase 3 directory layout. The plan's acceptance_criteria path (plural) is a typo; reconciled in VALIDATION.md Execution Evidence subsection"
  - "Preview task uses Mix.Task.run(\"loadpaths\") not app.start. Plan suggested app.start but that forces the host app's full boot-time validation chain (Accrue.Config.validate_at_boot! requiring :repo) which makes the task unrunnable standalone. Pure-data fixtures don't need OTP — Rule 3 deviation"
  - "Boot guard warn_pdf_adapter_unavailable/0 short-circuits in :test env via safe_mix_env/0 to prevent the guard from firing inside every test run. Prod-only firing matches the guard's intent (catching production misconfig) and avoids polluting test logs"
  - "ApplicationTest Pitfall 4 regex relaxed to permit Process.whereis(ChromicPDF) — the intent is 'no start / no child_spec', and a whereis read does not start anything. Applied @doc-comment stripping to allow the Logger.warning bodies to reference {ChromicPDF, on_demand: true} as host-guidance strings without tripping the check"
  - "Accrue.Workers.MailerDispatchTest + DefaultHandlerMailerDispatchTest force :mailer = Accrue.Mailer.Test in per-test setup because other (async: false) test modules flip the same env var for their own scope; async: false is not a cross-module lock. Setup + on_exit restore original value cleanly"
  - "needs_pdf?/1 is a private predicate on two atoms only (:invoice_finalized, :invoice_paid). :invoice_payment_failed deliberately does NOT attach a PDF (the dunning CTA routes to hosted_invoice_url — MAIL-09 payment-action semantics from Plan 06-06)"

requirements-completed: [MAIL-07, MAIL-08, MAIL-20, PDF-08, PDF-09]

metrics:
  duration: "~30m"
  tasks_completed: 3
  files_changed: 15
  tests_added: 29
  completed_date: "2026-04-15"
---

# Phase 6 Plan 07: Mailer Dispatch Wiring + Phase 6 Gate Sign-Off Summary

**One-liner:** Wires every Phase 6 email and PDF primitive into real dispatch paths — webhook reducers call `Accrue.Mailer.deliver/2` for every catalogue event, the mailer worker attaches PDFs to `:invoice_finalized` + `:invoice_paid` via `Accrue.Billing.render_invoice_pdf/2` with graceful fallback to hosted_invoice_url on PdfDisabled/chromic_pdf_not_started, `mix accrue.mail.preview` renders 13 email types to `.accrue/previews/`, three boot-time guards surface Pitfall 3/4 + D6-07 misconfigs, two guides (email + branding) ship, and the Phase 6 VALIDATION.md gate is signed off.

## Deliverables

### 1. PDF attachment branch in Accrue.Workers.Mailer.perform/1

New private helpers:

- `needs_pdf?/1` — predicate returning `true` for `:invoice_finalized` + `:invoice_paid` only
- `maybe_attach_pdf/3` — lazy-renders via `Accrue.Billing.render_invoice_pdf/2` and branches on the result:
  - `{:ok, binary}` → `Swoosh.Email.attachment/2` with `content_type: "application/pdf"` + `filename: "invoice-#{number_or_id}.pdf"`
  - `{:error, %Accrue.Error.PdfDisabled{}}` → `append_hosted_url_note/3` — no raise
  - `{:error, :chromic_pdf_not_started}` → emit `[:accrue, :ops, :pdf_adapter_unavailable]` telemetry + hosted URL note
  - `{:error, other}` → `raise Accrue.PDF.RenderFailed, reason: other` → Oban backoff retries
- `append_hosted_url_note/3` — appends `"View your invoice online: <url>"` to both HTML + text bodies when `assigns[:invoice][:hosted_invoice_url]` is present
- `safe_render_invoice_pdf/2` — nil-invoice_id guard: returns `PdfDisabled` terminal rather than calling into `Accrue.Billing` with nil

Public accessor added:

- `Accrue.Workers.Mailer.template_for/1` — delegates to the private `default_template/1`; used by `mix accrue.mail.preview`

New exception:

- `Accrue.PDF.RenderFailed` in `accrue/lib/accrue/errors.ex` — defexception with `:reason` + `:message` fields, `message/1` falling back to `"PDF render failed: #{inspect(reason)}"`

### 2. Webhook reducer → mailer dispatch wiring

Extended `Accrue.Webhook.DefaultHandler.dispatch/4` for every event family in the Email Type Catalogue. Each reducer's result is piped into a `maybe_dispatch_*_email/2-3` helper AFTER `Repo.transact/1` returns:

| Stripe event | Reducer | Email type | Notes |
|--------------|---------|------------|-------|
| `charge.succeeded` | `reduce_charge` | `:receipt` | Scalars: `customer_id`, `charge_id` |
| `charge.failed` | `reduce_charge` | `:payment_failed` | Scalars: `customer_id`, `charge_id` |
| `charge.refunded` | `reduce_charge` | `:refund_issued` | Dispatched via charge reducer (alt dispatch path) |
| `charge.refund.updated` | `reduce_refund` | `:refund_issued` | Scalars: `customer_id` (via Charge lookup), `refund_id`, `charge_id` |
| `refund.created` / `refund.updated` | `reduce_refund` | `:refund_issued` | Same |
| `invoice.finalized` | `reduce_invoice` | `:invoice_finalized` | Scalars: `customer_id`, `invoice_id`, `invoice_number`, `hosted_invoice_url` |
| `invoice.paid` | `reduce_invoice` | `:invoice_paid` | Same |
| `invoice.payment_failed` | `reduce_invoice` | `:invoice_payment_failed` | Same |
| `customer.subscription.trial_will_end` | `reduce_subscription` | `:trial_ending` | Scalars: `customer_id`, `subscription_id` |
| `customer.subscription.deleted` | `reduce_subscription` | `:subscription_canceled` | Same |
| `customer.subscription.updated` (pause_collection set) | `reduce_subscription` | `:subscription_paused` | Same |
| `customer.subscription.updated` (pause_collection cleared + status active) | `reduce_subscription` | `:subscription_resumed` | Uses `Subscription.active?/1` predicate |

Action-dispatched types (unchanged, documented in guides/email.md):

- `:card_expiring_soon` — cron via `Accrue.Jobs.DetectExpiringCards`
- `:coupon_applied` — `Accrue.Billing.CouponActions`
- `:trial_ended` — cron (existing Phase 3 job)

`safe_deliver/2` wraps `Accrue.Mailer.deliver/2` in try/rescue + try/catch so dispatch failures never rollback state reconciliation — failures emit `[:accrue, :mailer, :dispatch_failed]` telemetry (T-06-07-08).

### 3. mix accrue.mail.preview

New task at `accrue/lib/mix/tasks/accrue.mail.preview.ex`. Renders every `Accrue.Emails.*` type from `Accrue.Emails.Fixtures.all/0` to `.accrue/previews/{type}.{html,txt,pdf}`.

Flags:

- `--only receipt,trial_ending` — CSV filter; unknown types raise `Mix.Error`
- `--format html|txt|pdf|both` — default `both` (html + txt)

Uses `Mix.Task.run("loadpaths")` + `Application.ensure_all_started(:mjml_eex)` + `Application.ensure_all_started(:phoenix_html)` instead of `app.start` so the task runs against host apps that haven't wired `:repo`/`:secret_key_base` (deviation from plan; fixtures are pure data per D6-08 invariant).

PDF rendering is best-effort: if the fixture invoice_id has no DB row (which is the steady-state case — fixtures are pure data), `Accrue.Billing.render_invoice_pdf/2` returns `{:error, :chromic_pdf_not_started}` or similar and the task logs `skipped {type}.pdf` and continues.

Default-run output count: **26 files** — 13 types × 2 formats (html + txt). Confirmed at sign-off time via:

```bash
mix accrue.mail.preview && ls .accrue/previews/ | wc -l
# 26
```

`.accrue/` added to `accrue/.gitignore`.

### 4. Boot-time guard warnings

Three new `Accrue.Application.warn_*` functions called from `start/2`:

- `warn_pdf_adapter_unavailable/0` — Pitfall 3. Prod-only; Mix.env/0 gate silences the warning in dev/test. Fires when `:pdf_adapter = Accrue.PDF.ChromicPDF` AND `Process.whereis(ChromicPDF) == nil`. Logger.warning + `:accrue_pdf_adapter_unavailable_warned?` persistent_term dedupe.
- `warn_oban_queue_vs_pdf_pool/0` — Pitfall 4. Fires when `:attach_invoice_pdf` is true AND the `:accrue_mailers` Oban queue concurrency exceeds `:chromic_pdf_pool_size` (default 3). Reads queue concurrency via `Application.get_env(:accrue, Oban, [])` + `Keyword.get(:queues, [])`. Supports both `limit: N` and bare integer forms.
- `warn_company_address_locale_mismatch/0` — D6-07. Skips when `:branding[:company_address]` is set. Otherwise samples distinct `preferred_locale` values via `SELECT preferred_locale FROM accrue_customers WHERE preferred_locale IS NOT NULL GROUP BY preferred_locale LIMIT 100` — grouped counts only, zero PII leaked (T-06-07-05). If any locale starts with `fr`/`de`/`nl` or is `en-GB`/`en-CA`/`en_GB`/`en_CA`, emits Logger.warning. Wrapped in try/rescue/catch so boot never fails if the DB is unreachable at start time.

Each guard uses distinct `:persistent_term` keys for idempotent firing.

### 5. guides/email.md + guides/branding.md

Two Phase 6 user-facing guides:

**`accrue/guides/email.md`** (~240 lines):

- Quickstart config snippet with nested `:branding`
- 13-type semantic API catalogue table
- 4-rung override ladder (kill switch → MFA → atom swap → pipeline replace) with code examples
- Testing section with `Accrue.Test.MailerAssertions` usage
- CAN-SPAM / CASL / GDPR transactional exemption explainer + RFC 8058 opt-in pointer
- Async Oban config with Pitfall 4 concurrency guidance
- Localization ladder (D6-03)
- `mix accrue.mail.preview` developer workflow
- Pitfall 7 single-dispatch discipline note + action-dispatched exceptions

**`accrue/guides/branding.md`** (~140 lines):

- Quickstart config snippet
- Full 14-key `:branding` schema table (type, default, requirement, purpose)
- Hex color validation format reference
- Logo strategy across email vs PDF contexts (HTTPS vs base64)
- Per-template override pointer
- Deprecated flat-key migration with before/after example
- Connect v1.0 platform-branding-wins note

Both guides are emoji-free and reference the CLAUDE.md stack versions where relevant.

### 6. VALIDATION.md phase gate sign-off

`.planning/phases/06-email-pdf/06-VALIDATION.md` updated per Plan 06-07 Task 3 instructions:

- Per-Task Verification Map Status column: all 21 rows flipped from `⬜ pending` to `✅ green`
- Frontmatter `status: ready`, `nyquist_compliant: true`, `wave_0_complete: true`, `finalized: 2026-04-15` — unchanged, per task instruction
- New "Execution evidence (Plan 06-07 Task 3 sign-off)" subsection appended to the "Phase 6 gate" section with:
  - Final test counts (1013 tests, 0 failures)
  - Credo + compile status
  - Sampling verification (3 re-run commands)
  - `webhook/` vs `webhooks/` path reconciliation note
  - Deferred manual items (MJML Litmus, deliverability smoke, real ChromicPDF smoke, dark-mode rendering, dialyzer)
  - Test-file count delta reference

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] mix task `Mix.Task.run("app.start")` path unsupported standalone**
- **Found during:** Task 2 post-commit smoke verification
- **Issue:** The plan's action block called `Mix.Task.run("app.start")` which triggers `Accrue.Config.validate_at_boot!/0` — that validation requires `:repo` to be set, which is not part of the test config and is a host-app concern. Standalone `mix accrue.mail.preview --only receipt --format html` therefore crashed with `NimbleOptions.ValidationError: required :repo option not found`.
- **Fix:** Switched to `Mix.Task.run("loadpaths")` plus explicit `Application.ensure_all_started(:mjml_eex)` + `Application.ensure_all_started(:phoenix_html)`. Fixtures are pure data per D6-08 invariant — no OTP boot required.
- **Files modified:** `accrue/lib/mix/tasks/accrue.mail.preview.ex`
- **Commit:** `bdb95af`

**2. [Rule 3 — Blocking] ApplicationTest Pitfall 4 regex too strict for `Process.whereis(ChromicPDF)` read**
- **Found during:** Full suite regression after Task 2 boot guard addition
- **Issue:** `Accrue.ApplicationTest` asserted `refute code =~ "ChromicPDF"` to enforce "Accrue doesn't start ChromicPDF". Plan 06-07 Task 2's `warn_pdf_adapter_unavailable/0` guard calls `Process.whereis(ChromicPDF)` as a READ — that is not a start/child_spec, but the grep tripped anyway.
- **Fix:** Relaxed the regex to explicitly allow `Process.whereis` reads. Now refutes `ChromicPDF.start`, `ChromicPDF.child_spec`, and `{ChromicPDF, ...}` child-spec tuples after stripping `@doc` strings, `Logger.warning(""" ... """)` bodies, and `#` line comments (those contain host-guidance references like `{ChromicPDF, on_demand: true}` that are not actual Accrue supervisor children).
- **Files modified:** `accrue/test/accrue/application_test.exs`
- **Commit:** `b7f443c`

**3. [Rule 1 — Bug] Cross-test contamination in MailerDispatchTest / DefaultHandlerMailerDispatchTest**
- **Found during:** Full suite regression after Task 1 test additions
- **Issue:** Both new test files rely on the test-env default `:mailer = Accrue.Mailer.Test` to capture intent tuples. Other (async: false) test modules flip `:mailer` to `Accrue.Mailer.Default` for their own scope via `Application.put_env` — when those tests run before the new ones, the `Accrue.Mailer.Test` adapter is no longer active and intent tuples never land in the calling pid's mailbox. `async: false` is a per-module exclusion, not a global env lock.
- **Fix:** Added explicit setup blocks to both test files that `Application.put_env(:accrue, :mailer, Accrue.Mailer.Test)` at test start and restore the original value via `on_exit`.
- **Files modified:** `accrue/test/accrue/workers/mailer_dispatch_test.exs`, `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
- **Commit:** `b7f443c`

**4. [Rule 1 — Bug] Raw subscription.status access in `maybe_dispatch_subscription_email` tripped credo BILL-05**
- **Found during:** `mix credo --strict` run
- **Issue:** The updated-subscription-resumed branch used `if sub.status == :active do ... end` — raw status comparison. The Accrue.Credo.NoRawStatusAccess rule (BILL-05) requires all subscription status checks to go through predicates.
- **Fix:** Switched to `Subscription.active?/1` predicate which covers both `:active` and `:trialing`.
- **Files modified:** `accrue/lib/accrue/webhook/default_handler.ex`
- **Commit:** `b7f443c`

**5. [Rule 3 — Path reconciliation] Test directory `webhook/` vs `webhooks/`**
- **Found during:** Task 1 initial test placement
- **Issue:** The plan's acceptance_criteria command and VALIDATION.md Per-Task Verification Map row for 06-07 T1 reference `test/accrue/webhooks/default_handler_mailer_dispatch_test.exs` (plural). The existing repo convention is `test/accrue/webhook/` (singular) — every other webhook test lives there, and `Accrue.BillingCase` + test support modules are wired to that path via `test_helper.exs`.
- **Fix:** Placed the new test under `test/accrue/webhook/` to match convention. Recorded reconciliation note in VALIDATION.md Execution Evidence subsection so the verifier can find the file.
- **Files modified:** N/A (file placement)
- **Commit:** `ffd5127`

### Scope boundary deferrals

- **`mix dialyzer`** — not re-run at sign-off. Multi-minute PLT build; deferred to Phase 7 gate. Tracked in VALIDATION.md Execution Evidence.
- **MJML responsive rendering in Litmus** — manual evidence capture deferred; the `.accrue/previews/*.html` artifacts produced by the mix task are the inputs for the manual session.
- **Real SMTP deliverability smoke** — requires real API key + inbox; documented for the Phase 6 closeout review.
- **Real ChromicPDF end-to-end render smoke** — CI uses `Accrue.PDF.Test`; dev-machine smoke documented in the Manual-Only Verifications table.

## Known Stubs

None. The PDF attachment branch produces a real `%Swoosh.Attachment{}` on the happy path and a real hosted URL link on the terminal-error path. The mix preview task writes real HEEx/MJML output (not placeholder strings). Boot guards emit real `Logger.warning/1` calls. No TODO/FIXME/placeholder markers introduced.

## Self-Check: PASSED

Verification:

- `test -f accrue/lib/accrue/workers/mailer.ex` → FOUND
- `test -f accrue/lib/accrue/errors.ex` → FOUND (Accrue.PDF.RenderFailed added)
- `test -f accrue/lib/accrue/webhook/default_handler.ex` → FOUND
- `test -f accrue/lib/mix/tasks/accrue.mail.preview.ex` → FOUND
- `test -f accrue/lib/accrue/application.ex` → FOUND (3 new boot guards)
- `test -f accrue/.gitignore` → FOUND
- `test -f accrue/guides/email.md` → FOUND
- `test -f accrue/guides/branding.md` → FOUND
- `test -f accrue/test/accrue/workers/invoice_finalized_pdf_branch_test.exs` → FOUND
- `test -f accrue/test/accrue/workers/mailer_dispatch_test.exs` → FOUND
- `test -f accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` → FOUND
- `test -f accrue/test/accrue/mix/tasks/accrue_mail_preview_test.exs` → FOUND
- `test -f accrue/test/accrue/application_boot_guards_test.exs` → FOUND
- `test -f .planning/phases/06-email-pdf/06-VALIDATION.md` → FOUND (Phase 6 gate signed off)

Commits confirmed via `git log --oneline -5`:

- `ffd5127` feat(06-07): wire PDF attachment branch + webhook mailer dispatch
- `bdb95af` feat(06-07): mix accrue.mail.preview task + boot-time guard warnings
- `b7f443c` docs(06-07): email + branding guides, VALIDATION.md phase gate sign-off

All three task commits present. Final regression:

- `cd accrue && mix test` → `46 properties, 1013 tests, 0 failures (10 excluded)`
- `cd accrue && mix credo --strict` → `2046 mods/funs, found no issues`
- `cd accrue && mix compile --warnings-as-errors` → clean
- `cd accrue && mix accrue.mail.preview` → 26 files written to `.accrue/previews/`
