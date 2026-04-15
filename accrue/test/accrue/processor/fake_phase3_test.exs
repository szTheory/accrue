defmodule Accrue.Processor.FakePhase3Test do
  @moduledoc """
  Phase 3 coverage for `Accrue.Processor.Fake`: subscription/invoice/
  intent/payment-method/charge/refund callbacks, `transition/3`,
  `advance_subscription/2` webhook synthesis, `scripted_response/2`,
  and `fetch/2` generic dispatch.

  Phase 1 `FakeTest` covers the customer callbacks separately.
  """

  use ExUnit.Case, async: false

  alias Accrue.Processor.Fake

  setup do
    case Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Fake.reset()
    :ok
  end

  # ---------------------------------------------------------------------------
  # Subscription
  # ---------------------------------------------------------------------------

  describe "create_subscription/2" do
    test "returns stripe-shaped map with sub_fake_ id and trialing default when trial_end is set" do
      {:ok, cus} = Fake.create_customer(%{email: "t@e.co"}, [])

      trial_end_unix = DateTime.to_unix(DateTime.add(Fake.now(), 14 * 86_400, :second))

      {:ok, sub} =
        Fake.create_subscription(
          %{customer: cus.id, items: [%{price: "price_basic"}], trial_end: trial_end_unix},
          []
        )

      assert sub.id =~ ~r/^sub_fake_/
      assert sub.status == :trialing
      assert sub.customer == cus.id
      assert sub.trial_end == trial_end_unix
    end

    test "defaults to :active when no trial_end" do
      {:ok, cus} = Fake.create_customer(%{email: "t@e.co"}, [])

      {:ok, sub} =
        Fake.create_subscription(%{customer: cus.id, items: [%{price: "p"}]}, [])

      assert sub.status == :active
    end
  end

  describe "retrieve_subscription/2" do
    test "round-trips a created subscription" do
      {:ok, cus} = Fake.create_customer(%{email: "t@e.co"}, [])
      {:ok, sub} = Fake.create_subscription(%{customer: cus.id, items: [%{price: "p"}]}, [])
      {:ok, fetched} = Fake.retrieve_subscription(sub.id, [])
      assert fetched.id == sub.id
    end

    test "returns resource_missing for unknown id" do
      assert {:error, %Accrue.APIError{code: "resource_missing"}} =
               Fake.retrieve_subscription("sub_fake_missing", [])
    end
  end

  describe "transition/3" do
    test "moves subscription to past_due" do
      {:ok, cus} = Fake.create_customer(%{email: "x@y.z"}, [])
      {:ok, sub} = Fake.create_subscription(%{customer: cus.id, items: [%{price: "p"}]}, [])

      {:ok, _} = Fake.transition(sub.id, :past_due, synthesize_webhooks: false)

      {:ok, refetched} = Fake.retrieve_subscription(sub.id, [])
      assert refetched.status == :past_due
    end

    test "moves subscription to :canceled" do
      {:ok, cus} = Fake.create_customer(%{email: "x@y.z"}, [])
      {:ok, sub} = Fake.create_subscription(%{customer: cus.id, items: [%{price: "p"}]}, [])
      {:ok, _} = Fake.transition(sub.id, :canceled, synthesize_webhooks: false)
      {:ok, refetched} = Fake.retrieve_subscription(sub.id, [])
      assert refetched.status == :canceled
    end
  end

  describe "advance_subscription/2" do
    test "with days: 10 crosses trial_end (7d) → status becomes active" do
      {:ok, cus} = Fake.create_customer(%{email: "a@b.c"}, [])
      trial_end_unix = DateTime.to_unix(DateTime.add(Fake.now(), 7 * 86_400, :second))

      {:ok, sub} =
        Fake.create_subscription(
          %{customer: cus.id, items: [%{price: "p"}], trial_end: trial_end_unix},
          []
        )

      :ok = Fake.advance_subscription(sub.id, days: 10, synthesize_webhooks: false)

      {:ok, refetched} = Fake.retrieve_subscription(sub.id, [])
      assert refetched.status == :active
    end

    test "with days: 5 advances clock without crossing trial_end (7d)" do
      {:ok, cus} = Fake.create_customer(%{email: "a@b.c"}, [])
      trial_end_unix = DateTime.to_unix(DateTime.add(Fake.now(), 7 * 86_400, :second))

      {:ok, sub} =
        Fake.create_subscription(
          %{customer: cus.id, items: [%{price: "p"}], trial_end: trial_end_unix},
          []
        )

      before_clock = Fake.now()
      :ok = Fake.advance_subscription(sub.id, days: 5, synthesize_webhooks: false)
      assert DateTime.diff(Fake.now(), before_clock) == 5 * 86_400

      {:ok, refetched} = Fake.retrieve_subscription(sub.id, [])
      # Still trialing, inside trial window
      assert refetched.status == :trialing
    end

    test "with nil stripe_id only advances clock" do
      before_clock = Fake.now()
      :ok = Fake.advance_subscription(nil, seconds: 3600)
      assert DateTime.diff(Fake.now(), before_clock) == 3600
    end
  end

  describe "cancel_subscription/2" do
    test "marks subscription canceled and sets ended_at" do
      {:ok, cus} = Fake.create_customer(%{email: "x@y.z"}, [])
      {:ok, sub} = Fake.create_subscription(%{customer: cus.id, items: [%{price: "p"}]}, [])
      {:ok, canceled} = Fake.cancel_subscription(sub.id, [])
      assert canceled.status == :canceled
      assert %DateTime{} = canceled.ended_at
    end
  end

  # ---------------------------------------------------------------------------
  # Invoice
  # ---------------------------------------------------------------------------

  describe "invoice lifecycle" do
    test "create → finalize → pay" do
      {:ok, cus} = Fake.create_customer(%{email: "i@n.v"}, [])

      {:ok, inv} =
        Fake.create_invoice(%{customer: cus.id, amount_due: 2500, currency: "usd"}, [])

      assert inv.id =~ ~r/^in_fake_/
      assert inv.status == :draft

      {:ok, finalized} = Fake.finalize_invoice(inv.id, [])
      assert finalized.status == :open

      {:ok, paid} = Fake.pay_invoice(inv.id, [])
      assert paid.status == :paid
      assert paid.amount_paid == 2500
      assert paid.amount_remaining == 0
    end

    test "void_invoice sets status to :void and voided_at" do
      {:ok, cus} = Fake.create_customer(%{email: "i@n.v"}, [])
      {:ok, inv} = Fake.create_invoice(%{customer: cus.id}, [])
      {:ok, voided} = Fake.void_invoice(inv.id, [])
      assert voided.status == :void
      assert %DateTime{} = voided.voided_at
    end

    test "create_invoice_preview returns a non-persistent preview" do
      {:ok, cus} = Fake.create_customer(%{email: "p@v.w"}, [])
      {:ok, preview} = Fake.create_invoice_preview(%{customer: cus.id}, [])
      assert preview.object == "invoice"
      assert preview.id == nil
    end
  end

  # ---------------------------------------------------------------------------
  # Payment intent
  # ---------------------------------------------------------------------------

  describe "create_payment_intent/2" do
    test "default returns succeeded PI" do
      {:ok, pi} = Fake.create_payment_intent(%{amount: 1000, currency: "usd"}, [])
      assert pi.id =~ ~r/^pi_fake_/
      assert pi.status == :succeeded
      assert pi.next_action == nil
    end

    test "with requires_action_test: true returns requires_action PI with next_action map" do
      {:ok, pi} =
        Fake.create_payment_intent(
          %{amount: 1000, currency: "usd", requires_action_test: true},
          []
        )

      assert pi.status == :requires_action
      assert pi.next_action.type == "use_stripe_sdk"
    end
  end

  describe "confirm_payment_intent/3" do
    test "moves PI to :succeeded" do
      {:ok, pi} =
        Fake.create_payment_intent(
          %{amount: 1000, currency: "usd", requires_action_test: true},
          []
        )

      {:ok, confirmed} = Fake.confirm_payment_intent(pi.id, %{}, [])
      assert confirmed.status == :succeeded
    end
  end

  # ---------------------------------------------------------------------------
  # Setup intent
  # ---------------------------------------------------------------------------

  describe "setup intent" do
    test "create + confirm lifecycle" do
      {:ok, si} = Fake.create_setup_intent(%{}, [])
      assert si.id =~ ~r/^si_fake_/
      assert si.status == :succeeded

      {:ok, confirmed} = Fake.confirm_setup_intent(si.id, %{}, [])
      assert confirmed.status == :succeeded
    end

    test "requires_action_test flag returns SI with next_action" do
      {:ok, si} = Fake.create_setup_intent(%{requires_action_test: true}, [])
      assert si.status == :requires_action
      assert si.next_action.type == "use_stripe_sdk"
    end
  end

  # ---------------------------------------------------------------------------
  # Payment method
  # ---------------------------------------------------------------------------

  describe "payment method" do
    test "create + attach + detach + list" do
      {:ok, cus} = Fake.create_customer(%{email: "p@m.co"}, [])
      {:ok, pm} = Fake.create_payment_method(%{type: "card"}, [])
      assert pm.id =~ ~r/^pm_fake_/

      {:ok, attached} = Fake.attach_payment_method(pm.id, %{customer: cus.id}, [])
      assert attached.customer == cus.id

      {:ok, %{data: data}} = Fake.list_payment_methods(%{customer: cus.id}, [])
      assert length(data) == 1

      {:ok, detached} = Fake.detach_payment_method(pm.id, [])
      assert detached.customer == nil
    end

    test "set_default_payment_method updates customer.invoice_settings" do
      {:ok, cus} = Fake.create_customer(%{email: "d@f.co"}, [])
      {:ok, pm} = Fake.create_payment_method(%{type: "card"}, [])
      {:ok, _} = Fake.attach_payment_method(pm.id, %{customer: cus.id}, [])

      {:ok, updated} =
        Fake.set_default_payment_method(
          cus.id,
          %{invoice_settings: %{default_payment_method: pm.id}},
          []
        )

      assert updated.invoice_settings.default_payment_method == pm.id
    end
  end

  # ---------------------------------------------------------------------------
  # Charge / Refund
  # ---------------------------------------------------------------------------

  describe "charge + refund" do
    test "create_charge populates balance_transaction with fee details" do
      {:ok, ch} = Fake.create_charge(%{amount: 10_000, currency: "usd"}, [])
      assert ch.id =~ ~r/^ch_fake_/
      assert ch.status == :succeeded
      assert is_map(ch.balance_transaction)
      assert ch.balance_transaction.fee == 30
    end

    test "create_refund populates balance_transaction with fee details" do
      {:ok, ch} = Fake.create_charge(%{amount: 10_000, currency: "usd"}, [])
      {:ok, refund} = Fake.create_refund(%{charge: ch.id, amount: 10_000}, [])
      assert refund.id =~ ~r/^re_fake_/
      assert refund.charge == ch.id
      assert is_map(refund.balance_transaction)
    end
  end

  # ---------------------------------------------------------------------------
  # scripted_response / fetch / behaviour compliance
  # ---------------------------------------------------------------------------

  describe "scripted_response/2" do
    test "returns pre-programmed error once, then falls back to default" do
      err = %Accrue.CardError{
        message: "declined",
        code: "card_declined",
        http_status: 402
      }

      :ok = Fake.scripted_response(:create_subscription, {:error, err})
      {:ok, cus} = Fake.create_customer(%{email: "d@e.f"}, [])

      assert {:error, ^err} =
               Fake.create_subscription(%{customer: cus.id, items: [%{price: "p"}]}, [])

      # Script consumed — next call should succeed
      assert {:ok, _} =
               Fake.create_subscription(%{customer: cus.id, items: [%{price: "p"}]}, [])
    end
  end

  describe "fetch/2 generic dispatch" do
    test "routes :subscription to retrieve_subscription" do
      {:ok, cus} = Fake.create_customer(%{email: "f@g.h"}, [])
      {:ok, sub} = Fake.create_subscription(%{customer: cus.id, items: [%{price: "p"}]}, [])
      {:ok, fetched} = Fake.fetch(:subscription, sub.id)
      assert fetched.id == sub.id
    end

    test "routes :charge to retrieve_charge" do
      {:ok, ch} = Fake.create_charge(%{amount: 500}, [])
      {:ok, fetched} = Fake.fetch(:charge, ch.id)
      assert fetched.id == ch.id
    end

    test "routes :customer to retrieve_customer" do
      {:ok, cus} = Fake.create_customer(%{email: "f@g.h"}, [])
      {:ok, fetched} = Fake.fetch(:customer, cus.id)
      assert fetched.id == cus.id
    end
  end

  describe "behaviour compliance" do
    test "Fake exports every required Accrue.Processor callback" do
      # Phase 5 Plan 01 declared Connect callbacks as `@optional_callbacks`
      # pending adapter implementations in Plan 05-02/05-03. Filter them
      # out here so this Phase 3 strictness check still enforces the full
      # Phase 1-4 surface without tripping on the intentional Connect gap.
      optional = Accrue.Processor.behaviour_info(:optional_callbacks)

      required =
        Accrue.Processor.behaviour_info(:callbacks)
        |> Enum.reject(fn callback -> callback in optional end)

      for {name, arity} <- required do
        assert function_exported?(Accrue.Processor.Fake, name, arity),
               "Fake missing callback #{name}/#{arity}"
      end
    end
  end
end
