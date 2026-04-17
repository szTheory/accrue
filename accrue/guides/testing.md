# Testing Accrue Billing Flows

## Fake-first Phoenix scenario

Start billing tests in the host app, not inside Accrue internals. This example belongs in a Phoenix `DataCase` and runs against the Fake Processor, test mailer, test PDF adapter, Oban test mode, and the normal webhook reducer path.

```elixir
defmodule MyApp.BillingTest do
  use MyApp.DataCase, async: true
  use Accrue.Test
  use Oban.Testing, repo: MyApp.Repo

  setup do
    Accrue.Test.setup_fake_processor()
    Accrue.Test.setup_mailer_test()
    Accrue.Test.setup_pdf_test()

    :ok
  end

  test "subscriber renews through the local billing flow" do
    user = MyApp.AccountsFixtures.user_fixture()

    assert {:ok, subscription} =
             MyApp.Billing.subscribe(user, "price_monthly",
               trial_days: 14,
               payment_method: "pm_card_visa"
             )

    assert MyApp.Billing.subscription_status(user) == :trialing
    assert_event_recorded(user, type: :subscription_created)

    assert {:ok, _clock} = Accrue.Test.advance_clock(subscription, "1 month")

    invoice = MyApp.Billing.latest_invoice(user)
    assert invoice.status in [:open, :paid]

    assert {:ok, _event} = Accrue.Test.trigger_event(:invoice_payment_failed, invoice)

    assert_enqueued worker: Accrue.Workers.Mailer
    assert_email_sent(:receipt, to: user.email)
    assert_pdf_rendered(invoice)
    assert_event_recorded(user, type: :subscription_created)

    assert MyApp.Billing.account_state(user).billing_status in [:past_due, :active]
  end
end
```

The point is the shape: the host `MyApp.Billing` context owns the public test surface, while `Accrue.Test` makes time, webhooks, email, PDFs, events, and jobs deterministic. You should be able to prove billing behavior without Stripe, Chrome, SMTP, or sleeps.

Scenario checklist: successful checkout, trial conversion, failed renewal, cancellation/grace period, invoice email/PDF, webhook replay, background jobs, and provider-parity tests.

## Successful checkout

Call the host checkout or subscribe function and assert both persisted state and user-visible side effects. Prefer `MyApp.Billing.subscribe/3`, `MyApp.Billing.create_checkout_session/2`, or the facade your installer generated. Assert the subscription row, the account-facing status, the event ledger entry, and any receipt email or invoice PDF the flow promises.

## Trial conversion

Use `Accrue.Test.advance_clock(subscription, "1 month")` or a precise keyword duration to cross a trial boundary. The assertion should be about host behavior: the billable account leaves trial state, renewal work is enqueued, and the side effects a customer would see are recorded.

```elixir
assert {:ok, _} = Accrue.Test.advance_clock(subscription, days: 14)
assert MyApp.Billing.subscription_status(user) in [:active, :past_due]
```

## Failed renewal and retry

Simulate payment failure with `Accrue.Test.trigger_event(:invoice_payment_failed, invoice)`. Assert the webhook row exists, the host billing state changes, dunning or retry work is queued, and customer communication is captured with `assert_email_sent/2`.

## Cancellation/grace period

Exercise the host cancellation API, then advance the Fake clock through the grace period. Assert the local subscription status with `MyApp.Billing`, not private Accrue reducer state. A good test proves when access stays available, when it stops, and which event is recorded for the transition.

## Invoice email/PDF

Use the test mailer and PDF adapter together. The email assertion proves the customer communication path; the PDF assertion proves invoice rendering was requested without requiring Chrome.

```elixir
assert_email_sent(:receipt, to: user.email)
assert_pdf_rendered(invoice)
```

## Webhook replay

Replays should enter the same reducer path as first delivery. Trigger or requeue the event, assert idempotent persisted state, and verify that duplicate delivery does not duplicate customer-visible side effects.

## Background jobs

Use `Oban.Testing` for queue assertions and `perform_job/2` when the test needs to prove worker behavior. Keep queue names and worker modules host-visible so failures point to the app wiring a developer can fix.

## Provider-parity tests

Use the Fake Processor for normal test coverage, then keep a small provider-parity suite for behaviors where Stripe itself is the contract: SCA/3DS cards, Stripe test clocks, hosted checkout redirect behavior, and webhook signatures. Tag those tests separately so local development and CI do not depend on network calls by default.

## Helper reference

- `use Accrue.Test` imports mail, PDF, and event assertions and exposes the public action helpers.
- `Accrue.Test.setup_fake_processor/1` configures the Fake Processor for the test process.
- `Accrue.Test.setup_mailer_test/1` captures `Accrue.Mailer.Test` deliveries in the current process mailbox.
- `Accrue.Test.setup_pdf_test/1` captures `Accrue.PDF.Test` renders in the current process mailbox.
- `Accrue.Test.advance_clock/2` advances Fake time with readable strings, seconds, or keyword durations.
- `Accrue.Test.trigger_event/2` synthesizes a webhook event through Accrue ingest and the default handler path.
- `assert_email_sent/2` matches captured emails by type, recipient, assigns, or predicate.
- `assert_pdf_rendered/1` matches captured PDF renders by invoice id, contents, options, or predicate.
- `assert_event_recorded/1` and `assert_event_recorded/2` query the event ledger visible to the test sandbox.

## External-provider appendix

Use real Stripe test mode only for parity checks that the Fake Processor cannot prove. Keep those tests tagged and skipped unless `STRIPE_TEST_SECRET_KEY` and the matching webhook secret are present. Never make real Stripe sandbox calls by default in the main unit or context suite.

Stripe test clocks are useful for provider-level lifecycle parity. They are not a replacement for `Accrue.Test.advance_clock/2` in host flow tests because they require network access and provider resources.

Use 3DS cards in the provider-parity suite to prove SCA branches such as `requires_action`, failed authentication, and successful retry. Keep those card numbers in fixtures or test data, not in production config.

live webhook forwarding is useful when validating local endpoint wiring and signatures. Treat it as an integration exercise: document the local route, keep secrets in environment variables, and assert that the same event shape is reduced locally.

## Footguns

- Testing Accrue internals instead of host flows makes the app look green while `MyApp.Billing` is broken.
- `Process.sleep` hides races and slows the suite. Use Fake time, Oban testing helpers, and explicit event triggers.
- Real Stripe sandbox calls by default make local and CI tests slow, flaky, and dependent on external state.
- mixing live/test keys can mutate real accounts or make failures misleading. Keep environment variable names explicit and never paste real keys into examples.
- Hiding webhook setup means nobody knows whether raw body capture, signature verification, and dispatch are actually wired.
- Failing to assert side effects misses the behaviors customers notice: emails, PDFs, jobs, and event ledger rows.
- Raw payloads, metadata blobs, card data, emails beyond variables such as `user.email`, API keys, and signing secrets do not belong in test logs or telemetry attributes.

## Finance handoff (Stripe RR, Sigma, Data Pipeline)

For **Stripe-native finance and reporting** — what Accrue stores vs Stripe, when to
use Revenue Recognition vs Sigma vs Data Pipeline, and explicit **non-accounting**
boundaries — see [Finance handoff](finance-handoff.md).
