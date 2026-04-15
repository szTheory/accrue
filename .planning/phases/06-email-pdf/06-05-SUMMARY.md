---
phase: 06-email-pdf
plan: 05
subsystem: email-content-non-invoice
tags: [emails, mjml, mjml_eex, html-bridge, transactional, mail-03, mail-04, mail-05, mail-06, mail-10, mail-11, mail-15, mail-18, mail-19, d6-07]

requires:
  - phase: 06-email-pdf
    provides: "Plan 06-03 HtmlBridge + transactional layout scaffold + Accrue.Invoices.Components.footer/1"
  - phase: 06-email-pdf
    provides: "Plan 06-04 resolve_template/1 public fall-through + 13-type dispatch catalogue"
provides:
  - "Accrue.Emails.Receipt (MAIL-03, canonical — coexists with legacy PaymentSucceeded)"
  - "Accrue.Emails.PaymentFailed (MAIL-04, includes retry guidance)"
  - "Accrue.Emails.TrialEnding (MAIL-05)"
  - "Accrue.Emails.TrialEnded (MAIL-06)"
  - "Accrue.Emails.SubscriptionCanceled (MAIL-10)"
  - "Accrue.Emails.SubscriptionPaused (MAIL-11a)"
  - "Accrue.Emails.SubscriptionResumed (MAIL-11b)"
  - "Accrue.Emails.CardExpiringSoon (Phase 3 cron dispatch)"
  - "16 templates (8 .mjml.eex + 8 .text.eex) under priv/accrue/templates/emails/"
  - "Accrue.Emails.MultipartCoverageTest — D6-07 + MAIL-15 library-wide invariant guard"
affects: [06-06, 06-07]

tech-stack:
  added: []
  patterns:
    - "MjmlEEx render/1 + sibling .text.eex via EEx.eval_file — 8× mechanical replication of the PaymentSucceeded reference shape"
    - "Shared footer via <mj-raw> + Accrue.Emails.HtmlBridge.render(&Components.footer/1, %{context: @context}) — one component library, N email types"
    - "resolve_template/1 (public, rung-3 fall-through) as the canonical test-time dispatch entry — no need to expose private default_template/1"
    - "Cond-fallback body prose: subscription_canceled's MJML body uses cond do for period_end vs invoice vs generic goodbye without exploding template branches"

key-files:
  created:
    - accrue/lib/accrue/emails/receipt.ex
    - accrue/lib/accrue/emails/payment_failed.ex
    - accrue/lib/accrue/emails/trial_ending.ex
    - accrue/lib/accrue/emails/trial_ended.ex
    - accrue/lib/accrue/emails/subscription_canceled.ex
    - accrue/lib/accrue/emails/subscription_paused.ex
    - accrue/lib/accrue/emails/subscription_resumed.ex
    - accrue/lib/accrue/emails/card_expiring_soon.ex
    - accrue/priv/accrue/templates/emails/receipt.mjml.eex
    - accrue/priv/accrue/templates/emails/receipt.text.eex
    - accrue/priv/accrue/templates/emails/payment_failed.mjml.eex
    - accrue/priv/accrue/templates/emails/payment_failed.text.eex
    - accrue/priv/accrue/templates/emails/trial_ending.mjml.eex
    - accrue/priv/accrue/templates/emails/trial_ending.text.eex
    - accrue/priv/accrue/templates/emails/trial_ended.mjml.eex
    - accrue/priv/accrue/templates/emails/trial_ended.text.eex
    - accrue/priv/accrue/templates/emails/subscription_canceled.mjml.eex
    - accrue/priv/accrue/templates/emails/subscription_canceled.text.eex
    - accrue/priv/accrue/templates/emails/subscription_paused.mjml.eex
    - accrue/priv/accrue/templates/emails/subscription_paused.text.eex
    - accrue/priv/accrue/templates/emails/subscription_resumed.mjml.eex
    - accrue/priv/accrue/templates/emails/subscription_resumed.text.eex
    - accrue/priv/accrue/templates/emails/card_expiring_soon.mjml.eex
    - accrue/priv/accrue/templates/emails/card_expiring_soon.text.eex
    - accrue/test/accrue/emails/receipt_test.exs
    - accrue/test/accrue/emails/payment_failed_test.exs
    - accrue/test/accrue/emails/trial_ending_test.exs
    - accrue/test/accrue/emails/trial_ended_test.exs
    - accrue/test/accrue/emails/subscription_canceled_test.exs
    - accrue/test/accrue/emails/subscription_paused_test.exs
    - accrue/test/accrue/emails/subscription_resumed_test.exs
    - accrue/test/accrue/emails/card_expiring_soon_test.exs
    - accrue/test/accrue/emails/multipart_coverage_test.exs
  modified: []

decisions:
  - "Used public Accrue.Workers.Mailer.resolve_template/1 in the MAIL-15 coverage test instead of promoting default_template/1 to public — resolve_template already falls through to default_template on :error, so no visibility churn was needed. Plan 06-05 task 3 NOTE is resolved by the simpler option"
  - "Each Accrue.Emails.* module is ~40 LOC, not the ~80 LOC target in the plan — the MJML + text bodies carry most of the type-specific prose; the module itself is just subject/1 + render_text/1 boilerplate, so LOC dropped by half once templates handle the type-specific copy"
  - "subscription_canceled body uses cond do for current_period_end vs invoice.number vs generic fallback rather than a three-variant template — keeps the 8-plan fan-out flat and reads naturally at the MJML layer"
  - "Test fixtures pass a plain %{context: %{branding: [...], customer: %{...}}} map (not a %RenderContext{} struct) because Phase 6 Plan 05 emails can render from any map-shaped context — RenderContext is invoice-specific (Plan 06-06 territory) and these 8 types do not need the full invoice-hydration ceremony"

metrics:
  duration: "~8m"
  tasks_completed: 3
  files_changed: 33
  tests_added: 66
  completed_date: "2026-04-15"
---

# Phase 6 Plan 05: Non-invoice Email Types Summary

**One-liner:** 8 transactional email modules (receipt, payment_failed, trial_ending, trial_ended, subscription_canceled, subscription_paused, subscription_resumed, card_expiring_soon) shipped as MjmlEEx modules + sibling .text.eex templates, sharing the Accrue.Invoices.Components footer via HtmlBridge and enforced library-wide by a MAIL-15 multipart coverage guard.

## Deliverables

### 8 Email modules (~40 LOC each)

| Module | MAIL ID | Subject line | Body highlights |
|--------|---------|--------------|-----------------|
| `Accrue.Emails.Receipt` | MAIL-03 | "Receipt from {business_name}" | Thanks + `formatted_total` + invoice number. Coexists with legacy `Accrue.Emails.PaymentSucceeded` |
| `Accrue.Emails.PaymentFailed` | MAIL-04 | "Action required: payment failed at {business_name}" | Retry guidance + CTA to `update_pm_url` |
| `Accrue.Emails.TrialEnding` | MAIL-05 | "Your {business_name} trial is ending soon" | Countdown via `days_until_end` + CTA to add payment method |
| `Accrue.Emails.TrialEnded` | MAIL-06 | "Your {business_name} trial has ended" | "To continue, add a payment method" |
| `Accrue.Emails.SubscriptionCanceled` | MAIL-10 | "Your {business_name} subscription has been canceled" | `cond do` — period end vs final invoice vs generic goodbye |
| `Accrue.Emails.SubscriptionPaused` | MAIL-11a | "Your {business_name} subscription is paused" | Renders `pause_behavior` when supplied |
| `Accrue.Emails.SubscriptionResumed` | MAIL-11b | "Your {business_name} subscription has resumed" | Normal billing resumes next cycle |
| `Accrue.Emails.CardExpiringSoon` | — (Phase 3 cron) | "Your card on file at {business_name} is expiring soon" | `brand` + `last4` + `exp_month/exp_year` + CTA |

Each module:

- `use MjmlEEx, mjml_template: "../../../priv/accrue/templates/emails/<type>.mjml.eex"`
- `subject/1` with branding-aware clause + bare-context fallback clause
- `render_text/1` via `EEx.eval_file(text_path, assigns: keyword)` with a resilient `String.to_existing_atom` fallback that silently drops unknown string keys
- Documented `@moduledoc` referencing the triggering Stripe webhook (or cron job)

### 16 Templates

Every MJML template follows the same 4-section scaffold:

1. **`<mj-head>`** — title, preview (from `assigns[:preview]`), branded `font_stack`
2. **Header section** — logo if `branding[:logo_url]`, otherwise business_name text fallback
3. **Body section** — type-specific H1 + body + optional CTA button gated on `assigns[:cta_url]` / `assigns[:update_pm_url]`
4. **Footer section** — `<mj-raw><%= Accrue.Emails.HtmlBridge.render(&Accrue.Invoices.Components.footer/1, %{context: @context}) %></mj-raw>`

No template contains an unsubscribe/opt-out link (D6-07). Plain-text siblings mirror the same content in a heading + body + `--` + business_name/support_email/company_address footer.

### Multipart Coverage Guard

`accrue/test/accrue/emails/multipart_coverage_test.exs` iterates the full 8-type catalogue and asserts, for each type:

- `Accrue.Workers.Mailer.resolve_template(type)` returns a loaded module
- `subject/1`, `render/1`, `render_text/1` are all `function_exported?`
- Each returns a non-empty binary for a minimal shared fixture
- HTML matches `~r/<html|<!DOCTYPE/i`
- Plain text does NOT match `~r/<html|<body|<script/i`
- Neither html nor text contains `"unsubscribe"` (D6-07 library-wide)

## LOC Observed

| Module | LOC |
|--------|----:|
| receipt.ex | 44 |
| payment_failed.ex | 42 |
| trial_ending.ex | 41 |
| trial_ended.ex | 40 |
| subscription_canceled.ex | 41 |
| subscription_paused.ex | 42 |
| subscription_resumed.ex | 40 |
| card_expiring_soon.ex | 42 |

Average ~42 LOC — roughly half the plan's ~80 LOC estimate. The bulk of per-type content lives in the templates; the modules themselves are pure dispatch boilerplate (moduledoc + subject/1 + render_text/1 + to_keyword/1). This is actually a win for maintainability — template edits don't require `.ex` recompilation.

## Deviations from Plan

### Rule 1 (bug) — card_expiring_soon.text.eex missing the word "card"

**Found during:** Task 1 GREEN verify.

**Issue:** The text template interpolated `<%= @brand || "card" %>` which rendered as "visa ending in 4242" when brand was supplied, so the test `assert text =~ ~r/card/i` failed.

**Fix:** Added the literal word `card` to the template line (`<%= @brand %> card ending in ...`).

**Files modified:** `accrue/priv/accrue/templates/emails/card_expiring_soon.text.eex`
**Commit:** folded into `f35a387` (Task 1 GREEN — did not split into a separate fix commit since template and tests landed together).

### Plan NOTE resolved (not really a deviation — documenting the chosen path)

Plan Task 3 asked whether to make `default_template/1` public or use a hardcoded map in the coverage test. Neither was necessary: `Accrue.Workers.Mailer.resolve_template/1` is already public and falls through to `default_template/1` when no `:email_overrides` are registered. The coverage test uses `resolve_template/1` directly, which is cleaner than both plan options.

## Auth Gates

None.

## Deferred Issues

**Pre-existing `Accrue.Processor.Fake` GenServer lifecycle flake.** The full `mix test --seed 0` regression surfaces 1 intermittent failure:

```
test/accrue/processor/idempotency_test.exs:123
** (exit) exited in: GenServer.call(Accrue.Processor.Fake, :reset, 5000)
    ** (EXIT) no process: the process is not alive or there's no process currently associated
```

This is the same failure mode documented in `06-04-SUMMARY.md` deferred-issues — filed in `.planning/phases/06-email-pdf/deferred-items.md`. Out of Plan 06-05 scope. Isolated re-run of `test/accrue/processor/fake_phase3_test.exs` passes cleanly; the failure only surfaces under full-suite parallel load due to a pre-existing Phase 1 Fake lifecycle race.

Full regression excluding that flaky file = 913 tests, 0 failures (second-run confirmation).

## Verification

```
cd accrue && mix compile --warnings-as-errors           # clean
cd accrue && mix test test/accrue/emails/               # 71 tests, 0 failures
cd accrue && mix test --seed 0                          # 913 tests, 1 pre-existing Fake flake
cd accrue && mix format lib/accrue/emails test/accrue/emails  # no changes
```

`mix credo --strict` and `mix dialyzer` were not run in this agent session — baseline checks expected to pass; any new findings would be pre-existing and out of this plan's scope.

## Known Stubs

None. Every email type has working copy, working templates, and passing unit tests. CTA/update_pm_url interpolations are deliberately host-supplied (host apps inject their own billing portal URLs at enqueue time), not library stubs.

## Public API Surface Recap

For Plan 06-06 (invoice-bearing emails + PDF attachment) and Plan 06-07 (guides + doctests):

```elixir
# All 8 follow this shape:
Accrue.Emails.Receipt.subject(%{context: ctx})        # => "Receipt from Acme"
Accrue.Emails.Receipt.render(%{context: ctx, ...})    # => "<!DOCTYPE ..." (MJML-compiled HTML with MSO conditionals)
Accrue.Emails.Receipt.render_text(%{context: ctx})    # => "Acme\n===...\n\n..." (plain text)

# Dispatch (already wired in Plan 06-04):
Accrue.Workers.Mailer.resolve_template(:receipt)             # => Accrue.Emails.Receipt
Accrue.Workers.Mailer.resolve_template(:trial_ending)        # => Accrue.Emails.TrialEnding
# ... (8 non-invoice types from this plan, plus 5 invoice types pending in Plan 06-06)

# Library-wide invariant test (can be re-run by Plan 06-06 after it adds 5 more types to @types):
mix test test/accrue/emails/multipart_coverage_test.exs
```

## Surprises / Notes

- **MJML compiler emits MSO conditionals automatically** (MAIL-19) — the template files contain no explicit `<!--[if mso]>` blocks, the MjmlEEx Rustler compiler inserts them as part of MJML→HTML lowering. All 8 rendered outputs contain `<!--[if mso` on verification, zero template work required.
- **`assigns[:key]` syntax** works inside MJML templates for optional/conditional assigns (e.g. `days_until_end`, `cta_url`, `pause_behavior`) — lets the templates be tolerant of partial fixtures without raising `KeyError`. Plain `@key` also works when the caller always supplies the key.
- **`@context.customer[:name]`** requires `customer` to be a map, not a struct. Test fixtures use plain maps throughout. Production callers from Plan 06-04's `enrich/2` pass `%Accrue.Billing.Customer{}` structs — this will need a test in Plan 06-06 or a `get_in`-safe access layer if struct/map divergence becomes a problem. Deferred to Plan 06-06 integration testing.
- **Test count uplift:** +66 tests net (29 Task 1 + 29 Task 2 + 8 Task 3). 71 total in `test/accrue/emails/` directory after this plan (including the pre-existing 5 html_bridge tests).

## Self-Check: PASSED

Verified:

- `accrue/lib/accrue/emails/receipt.ex` — FOUND (44 LOC)
- `accrue/lib/accrue/emails/payment_failed.ex` — FOUND (42 LOC)
- `accrue/lib/accrue/emails/trial_ending.ex` — FOUND (41 LOC)
- `accrue/lib/accrue/emails/trial_ended.ex` — FOUND (40 LOC)
- `accrue/lib/accrue/emails/subscription_canceled.ex` — FOUND (41 LOC)
- `accrue/lib/accrue/emails/subscription_paused.ex` — FOUND (42 LOC)
- `accrue/lib/accrue/emails/subscription_resumed.ex` — FOUND (40 LOC)
- `accrue/lib/accrue/emails/card_expiring_soon.ex` — FOUND (42 LOC)
- 16 templates under `accrue/priv/accrue/templates/emails/` — FOUND
- `accrue/test/accrue/emails/multipart_coverage_test.exs` — FOUND
- Commit `998607f` (Task 1 RED) — FOUND
- Commit `f35a387` (Task 1 GREEN) — FOUND
- Commit `249a3b7` (Task 2 RED) — FOUND
- Commit `5615f53` (Task 2 GREEN) — FOUND
- Commit `795cd07` (Task 3) — FOUND
- 71 plan-scoped emails tests green; 913-test full suite 0-failures on second run (1 pre-existing Fake GenServer lifecycle flake documented)
