defmodule Accrue.LiveStripe.Charge3DSLiveTest do
  @moduledoc """
  Quick task 260414-l9q: live-Stripe fidelity companion for Phase 3
  HUMAN-UAT Item 1 (3DS charge).

  Proves the `{:ok, :requires_action, pi}` contract holds against
  REAL Stripe test mode — not the Fake — by:

    1. Creating a real test-mode Customer via `Billing.create_customer`.
    2. Attaching Stripe's canned 3DS test payment method token
       `pm_card_threeDSecure2Required` (documented at
       https://docs.stripe.com/testing#regulatory-cards).
    3. Calling `Billing.charge/3` and asserting the tagged intent_result
       surfaces `{:ok, :requires_action, pi}` with the expected
       `next_action` + `client_secret` shape.

  Does NOT complete the 3DS flow in a browser — that is a host-app
  concern, not a library-level invariant. The library-level invariant
  this test guards is that the SCA branch in `IntentResult.wrap/1`
  correctly recognizes Stripe's real `requires_action` status string
  on a real PaymentIntent and does not regress if the Stripe API
  version shifts.

  ## Gating

  `@moduletag :live_stripe` keeps this out of the default `mix test`
  run (tag excluded in `test/test_helper.exs`). Runs only via:

      STRIPE_TEST_SECRET_KEY=sk_test_... mix test.live

  The module conditionally sets `@moduletag :skip` when the secret is
  unset, so a bare `mix test.live` with no key in the env skips cleanly
  instead of erroring.

  See `guides/testing-live-stripe.md` for the full local + CI workflow.
  """
  use ExUnit.Case, async: false

  @moduletag :live_stripe
  @moduletag timeout: 60_000

  # Conditional skip: if no secret is set in the environment, tag the
  # whole module `:skip` so `mix test.live` on a bare environment
  # reports "skipped" instead of dying in setup_all.
  unless System.get_env("STRIPE_TEST_SECRET_KEY") do
    @moduletag :skip
  end

  alias Accrue.Billing
  alias Accrue.Billing.Customer

  setup_all do
    # Re-assert at setup_all so the test author gets a clear message if
    # the skip attribute was removed but the secret is still missing.
    # This is defensive — normally the module-level skip attribute fires
    # first and setup_all never runs.
    secret = System.get_env("STRIPE_TEST_SECRET_KEY")

    if is_nil(secret) do
      {:ok, skip: true}
    else
      # The Stripe processor reads its secret via
      # `Application.get_env(:accrue, :stripe_secret_key)` — see
      # `lib/accrue/processor/stripe.ex:627`.
      prior_secret = Application.get_env(:accrue, :stripe_secret_key)
      prior_processor = Application.get_env(:accrue, :processor)
      Application.put_env(:accrue, :stripe_secret_key, secret)
      Application.put_env(:accrue, :processor, Accrue.Processor.Stripe)

      on_exit(fn ->
        if prior_processor do
          Application.put_env(:accrue, :processor, prior_processor)
        else
          Application.delete_env(:accrue, :processor)
        end

        if prior_secret do
          Application.put_env(:accrue, :stripe_secret_key, prior_secret)
        else
          Application.delete_env(:accrue, :stripe_secret_key)
        end
      end)

      :ok
    end
  end

  @threeds_required_pm "pm_card_threeDSecure2Required"

  test "Billing.charge/3 with 3DS-required test PM surfaces :requires_action" do
    # Seed a customer directly via changeset (bypass host-owned billable
    # resolution for a library-level test). We use the live-Stripe
    # processor, so Accrue.Processor.Stripe.create_customer/2 hits real
    # Stripe and returns a real `cus_...` id.
    {:ok, stripe_customer} =
      Accrue.Processor.Stripe.create_customer(
        %{email: "accrue-ci-3ds@example.com", description: "accrue live-stripe CI"},
        []
      )

    customer_repo = Application.get_env(:accrue, :repo)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "CIUser",
        owner_id: Ecto.UUID.generate(),
        processor: "stripe",
        processor_id: stripe_customer[:id] || stripe_customer["id"],
        email: "accrue-ci-3ds@example.com"
      })
      |> customer_repo.insert()

    # Attach Stripe's canned 3DS-required PM token.
    {:ok, _attached} =
      Accrue.Processor.Stripe.attach_payment_method(
        @threeds_required_pm,
        %{customer: customer.processor_id},
        []
      )

    # Drive the real charge path. Expect :requires_action because the
    # PM above mandates 3DS challenge completion.
    assert {:ok, :requires_action, pi} =
             Billing.charge(customer, Accrue.Money.new(5_000, :usd),
               payment_method: @threeds_required_pm
             )

    # Stripe returns string-keyed maps after translate_resource; tolerate
    # either key shape because the wrapper preserves the original map.
    assert (pi[:status] || pi["status"]) == "requires_action"

    assert (pi[:client_secret] || pi["client_secret"]) != nil

    assert pi[:next_action] || pi["next_action"]
  end
end
