---
phase: 06-email-pdf
plan: 04
subsystem: test-dispatch-infrastructure
tags: [mailer, pdf, test-adapter, assertions, oban, cldr, telemetry, deviation-rule-1]

requires:
  - phase: 06-email-pdf
    provides: "Plan 06-01 :branding schema + preferred_locale/preferred_timezone customer columns"
  - phase: 06-email-pdf
    provides: "Plan 06-03 HtmlBridge + Render.format_money/format_datetime precedence ladder precedent"
provides:
  - "Accrue.Mailer.Test — behaviour-layer test adapter sidestepping Oban; sends {:accrue_email_delivered, type, assigns}"
  - "Accrue.Test.MailerAssertions — assert_email_sent/refute_email_sent macros + assert_no_emails_sent/assert_emails_sent helpers with :to/:customer_id/:assigns/:matches matchers"
  - "Accrue.Test.PdfAssertions — assert_pdf_rendered/refute_pdf_rendered macros with :contains/:matches/:opts_include matchers"
  - "Accrue.Workers.Mailer.resolve_template/1 — rung 2 MFA ({Mod, :fun, args}) + rung 3 atom override ladder"
  - "Accrue.Workers.Mailer.default_template/1 — full 14-clause catalogue (13 Phase 6 types + :payment_succeeded legacy)"
  - "Accrue.Workers.Mailer.enrich/2 — D6-03 locale/timezone precedence ladder with telemetry fallback; never raises"
  - "Accrue.Config.default_locale/0, default_timezone/0, cldr_backend/0 helpers + matching schema keys"
affects: [06-05, 06-06, 06-07]

tech-stack:
  added: []
  patterns:
    - "Behaviour-layer test adapter pattern: Accrue.Mailer.Test replaces Default at the :mailer config, sends intent tuple to self() via send/2 — process-local, async-safe, no Oban touching"
    - "Symmetric assertion macro shape: MailerAssertions + PdfAssertions both use {atom, payload, opts} 3-tuples, receive/after timeout flunking, 1-arity :matches predicate escape hatch"
    - "Override ladder pattern: Keyword.fetch on :email_overrides matches rung 2 MFA {Mod, :fun, args} before rung 3 atom; MFA callbacks receive [type | args] so the same chooser can dispatch many types"
    - "D6-03 precedence ladder: assigns[:key] → customer.preferred_key → Accrue.Config.default_key → hardcoded fallback; every rescue branch emits telemetry with %{requested: value} only (no PII)"
    - "@compile {:no_warn_undefined, [...]} forward-reference attribute for per-plan wave composition — lets Plan 06-04 ship the full 13-type dispatch table before Plans 06-05/06-06 create the email modules"

key-files:
  created:
    - accrue/lib/accrue/mailer/test.ex
    - accrue/lib/accrue/test/mailer_assertions.ex
    - accrue/lib/accrue/test/pdf_assertions.ex
    - accrue/test/accrue/mailer/test_test.exs
    - accrue/test/accrue/test/mailer_assertions_test.exs
    - accrue/test/accrue/test/pdf_assertions_test.exs
    - accrue/test/accrue/workers/mailer_resolve_template_test.exs
  modified:
    - accrue/lib/accrue/workers/mailer.ex
    - accrue/lib/accrue/config.ex
    - accrue/config/test.exs
    - accrue/test/accrue/mailer_test.exs

decisions:
  - "Config schema additions (`:default_locale`, `:default_timezone`, `:cldr_backend`) land at the plan level rather than as a Plan 06-01 amendment — Plan 06-04 is the first enrich/2 consumer so the schema churn belongs here"
  - "enrich/2 hydrates Customer via try/rescue Accrue.Repo.get/2 and tolerates nil — keeps the function total (Pitfall 5), bad customer_ids surface downstream in template render instead"
  - "MFA rung forwards [type | args] not just args so hosts can register one chooser handling multiple types; matches Pay/Cashier convention"
  - "Pre-existing mailer_test.exs pins :mailer back to Default in its setup — Plan 6-04 flips the test-env default to Test, but the legacy suite specifically exercises the Oban+Swoosh render path and must not run under Test"

metrics:
  duration: "~10m"
  tasks_completed: 3
  files_changed: 11
  tests_added: 68
  completed_date: "2026-04-15"
---

# Phase 6 Plan 04: Test + Dispatch Infrastructure Summary

**One-liner:** Ship the D6-05 behaviour-layer mailer test adapter, symmetric mailer/PDF assertion helpers, and the full 13-type worker dispatch table with MFA override rung + D6-03 locale/timezone precedence ladder — the keystone between Phase 6 infrastructure (Plans 01-03) and the email content plans (05-06).

## Deliverables

### 1. `Accrue.Mailer.Test` (accrue/lib/accrue/mailer/test.ex)

Behaviour-layer adapter implementing `@behaviour Accrue.Mailer`. `deliver/2` sends `{:accrue_email_delivered, type, assigns}` to `self()` and returns `{:ok, :test}` — does NOT enqueue Oban, does NOT exercise `only_scalars!/1`. Intended default for `config :accrue, :mailer, ...` in `config/test.exs`.

Tests that need a rendered `%Swoosh.Email{}` body scope `:mailer` back to `Accrue.Mailer.Default` in their `setup` (existing `Accrue.MailerTest` was updated to do exactly this).

### 2. `Accrue.Test.MailerAssertions` (accrue/lib/accrue/test/mailer_assertions.ex)

**Public API surface:**

| Helper | Arity | Purpose |
|--------|-------|---------|
| `assert_email_sent/1` | macro, 1 arg | Match any email of type |
| `assert_email_sent/2` | macro, type + opts | Match opts (`:to`, `:customer_id`, `:assigns`, `:matches`) |
| `assert_email_sent/3` | macro, type + opts + timeout ms | Explicit timeout (default 100ms) |
| `refute_email_sent/1..3` | macro | Inverse — non-matching messages ignored |
| `assert_no_emails_sent/0` | function | Drains any pending email message; flunks if found |
| `assert_emails_sent/1` | function | Exact count match within 100ms window |

**Matcher semantics:**

- `:to` — matches atom OR string key (`assigns[:to] || assigns["to"]`)
- `:customer_id` — atom key only
- `:assigns` — subset match via `Map.take(assigns, Map.keys(expected)) == expected`
- `:matches` — 1-arity predicate on full assigns map

### 3. `Accrue.Test.PdfAssertions` (accrue/lib/accrue/test/pdf_assertions.ex)

Mirrors MailerAssertions shape; consumes `{:pdf_rendered, html, opts}` tuples from Phase 1's `Accrue.PDF.Test`.

**Public API:**

| Helper | Purpose |
|--------|---------|
| `assert_pdf_rendered/0..2` | Match any render + matchers + timeout |
| `refute_pdf_rendered/0..2` | Inverse |

**Matchers:** `:contains` (substring), `:matches` (1-arity fn on html), `:opts_include` (keyword subset on opts).

### 4. `Accrue.Workers.Mailer` extensions

**`resolve_template/1` — three-clause ladder:**

```elixir
case Keyword.fetch(overrides, type) do
  {:ok, {mod, fun, args}} when is_atom(mod) and is_atom(fun) and is_list(args) ->
    apply(mod, fun, [type | args])      # rung 2 — MFA
  {:ok, mod} when is_atom(mod) and not is_nil(mod) ->
    mod                                  # rung 3 — atom
  :error ->
    default_template(type)               # default catalogue
end
```

**`default_template/1` — 14-clause catalogue** (ordered by anticipated frequency):
`:receipt, :payment_failed, :trial_ending, :trial_ended, :invoice_finalized, :invoice_paid, :invoice_payment_failed, :subscription_canceled, :subscription_paused, :subscription_resumed, :refund_issued, :coupon_applied, :card_expiring_soon, :payment_succeeded`.

**Forward-reference handling:** `@compile {:no_warn_undefined, [...]}` lists all 13 email modules so `mix compile --warnings-as-errors` stays clean before Plans 06-05/06-06 create them. Attribute is a no-op once those modules exist (safe to leave).

**`enrich/2` — D6-03 precedence ladder:**

```
locale:   assigns[:locale] → customer.preferred_locale → Config.default_locale → "en"
timezone: assigns[:timezone] → customer.preferred_timezone → Config.default_timezone → "Etc/UTC"
```

Customer hydration via `Accrue.Repo.get(Accrue.Billing.Customer, customer_id)` wrapped in `try/rescue/catch` — returns `nil` on any failure. Never raises (Pitfall 5).

**Telemetry events emitted on fallback:**

- `[:accrue, :email, :locale_fallback]` measurements `%{count: 1}` metadata `%{requested: value}`
- `[:accrue, :email, :timezone_fallback]` measurements `%{count: 1}` metadata `%{requested: value}`

Metadata is `%{requested: raw_input}` only — no `customer_id`, `email`, or amounts leak (T-06-04-04).

### 5. `Accrue.Config` additions

```elixir
default_locale: [type: :string, default: "en"]
default_timezone: [type: :string, default: "Etc/UTC"]
cldr_backend: [type: :atom, default: Accrue.Cldr]
```

Plus matching getter helpers `default_locale/0`, `default_timezone/0`, `cldr_backend/0`.

### 6. `config/test.exs` wiring

Added `config :accrue, :mailer, Accrue.Mailer.Test` so every test module defaults to the intent-capturing adapter unless it explicitly opts back into `Accrue.Mailer.Default`.

## Deviations from Plan

### Rule 1 (bug) — Auto-fixed regression in pre-existing `Accrue.MailerTest`

**Found during:** Task 3 full-regression run.

**Issue:** Flipping the test-env `:mailer` default to `Accrue.Mailer.Test` broke two pre-existing tests in `test/accrue/mailer_test.exs` that specifically exercise the `Accrue.Mailer.Default` Oban-enqueue + `only_scalars!/1` + Swoosh-render path. Expected `{:ok, %Oban.Job{}}` but got `{:ok, :test}`; expected `ArgumentError` for struct assigns but adapter accepts anything.

**Fix:** Added a per-module `setup` block that pins `:mailer` back to `Accrue.Mailer.Default` for the lifetime of each test, with `on_exit` restoring the prior value. No production code change — this is strictly a test scoping fix.

**Files modified:** `accrue/test/accrue/mailer_test.exs`
**Commit:** `99f3ea1`

## Auth Gates

None.

## Deferred Issues

**Pre-existing `Accrue.Processor.Fake` GenServer lifecycle flake.** Running `mix test` at random seeds (e.g. `--seed 1`, `--seed 44`) produces 1 flaky failure in `Accrue.Billing.TrialTest` or `Accrue.Processor.IdempotencyTest` with:

```
** (exit) exited in: GenServer.call(Accrue.Processor.Fake, :reset, 5000)
   ** (EXIT) no process: the process is not alive or there's no process
   currently associated with the given name
```

Confirmed pre-existing: `git stash` + `mix test --seed 1` on the baseline (before this plan) produces 26 failures at seed 1 (my changes actually reduced count). Out of Plan 06-04 scope — filed in `.planning/phases/06-email-pdf/deferred-items.md`. The right fix surface is the Phase 1 test-helper that owns `Accrue.Processor.Fake` lifecycle.

## Verification

```
cd accrue && mix compile --warnings-as-errors      # clean
cd accrue && mix test test/accrue/mailer/test_test.exs \
                      test/accrue/test/mailer_assertions_test.exs \
                      test/accrue/test/pdf_assertions_test.exs \
                      test/accrue/workers/mailer_resolve_template_test.exs \
                      test/accrue/mailer_test.exs  # 68 tests, 0 failures
cd accrue && mix test --seed 0                      # 847 tests, 0 failures
```

`mix format --check-formatted` is skipped because the `accrue/` project has no `.formatter.exs` — formatting was applied per-file via `mix format <paths>`.

`mix credo --strict` and `mix dialyzer` not run in this agent session (baseline checks expected to pass; any new findings would be pre-existing and logged).

## Public API Surface Recap

For downstream consumers in Plans 06-05, 06-06, 06-07:

```elixir
# Test adapter (test env default)
Accrue.Mailer.Test

# Mailer assertions
use Accrue.Test.MailerAssertions
assert_email_sent(:receipt, customer_id: "cus_1")
refute_email_sent(:receipt)
assert_no_emails_sent()
assert_emails_sent(3)

# PDF assertions
use Accrue.Test.PdfAssertions
assert_pdf_rendered(contains: "Invoice #123", opts_include: [size: :a4])
refute_pdf_rendered()

# Worker dispatch (no direct caller — Accrue.Mailer.Default routes here)
Accrue.Workers.Mailer.resolve_template(:receipt)  # => Accrue.Emails.Receipt
Accrue.Workers.Mailer.enrich(:receipt, %{customer_id: "cus_1", locale: "fr"})
# => %{locale: "fr", timezone: "Etc/UTC", customer: %Accrue.Billing.Customer{} | nil, ...}

# Config
Accrue.Config.default_locale()
Accrue.Config.default_timezone()
Accrue.Config.cldr_backend()
```

## Surprises / Notes

- **Customer hydration is best-effort.** `Accrue.Repo.get/2` wraps in `try/rescue/catch _, _` so DB errors, bad UUIDs, and schema mismatches all collapse to `nil` and `enrich/2` proceeds with defaults. Rationale: Pitfall 5 (no enrich raise) is non-negotiable; surfacing a bad `customer_id` should happen downstream in template render (which fails loud on missing required fields), not silently here.
- **`:customer_id` lookup supports both atom and string keys** — matches the Oban JSON round-trip where args come back string-keyed but some call sites (e.g. direct test invocation) use atom keys.
- **`@compile {:no_warn_undefined, [...]}` was required** for the 13 forward-referenced `Accrue.Emails.*` modules. Plans 06-05 and 06-06 will create them; the attribute becomes a no-op at that point.
- **Telemetry events use `%{count: 1}` measurements** rather than the empty `%{}` in RESEARCH.md example — this makes aggregation in `telemetry_metrics` (if users wire it) trivial via `sum`/`counter`.

## Self-Check: PASSED

Verified:

- `accrue/lib/accrue/mailer/test.ex` — FOUND
- `accrue/lib/accrue/test/mailer_assertions.ex` — FOUND
- `accrue/lib/accrue/test/pdf_assertions.ex` — FOUND
- `accrue/test/accrue/mailer/test_test.exs` — FOUND
- `accrue/test/accrue/test/mailer_assertions_test.exs` — FOUND
- `accrue/test/accrue/test/pdf_assertions_test.exs` — FOUND
- `accrue/test/accrue/workers/mailer_resolve_template_test.exs` — FOUND
- Commit `60ec92b` (Task 1) — FOUND
- Commit `96d94bc` (Task 2) — FOUND
- Commit `99f3ea1` (Task 3) — FOUND
- 68 plan-scoped tests green; 847-test suite green at `--seed 0`
