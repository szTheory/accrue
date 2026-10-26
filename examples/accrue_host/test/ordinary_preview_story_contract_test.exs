defmodule AccrueHost.OrdinaryPreviewStoryContractTest do
  use AccrueHost.DataCase, async: false

  alias Accrue.Billing.{
    Charge,
    Coupon,
    Customer,
    Invoice,
    PaymentMethod,
    PromotionCode,
    Refund,
    Subscription
  }

  alias Accrue.Events.Event
  @ordinary_seed Path.expand("../priv/repo/seeds/ordinary.exs", __DIR__)
  @payment_methods_seed Path.expand("../priv/repo/seeds/ordinary_payment_methods.exs", __DIR__)

  setup do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()
    previous_env = Application.get_env(:accrue, :env)
    previous_project = System.get_env("COMPOSE_PROJECT_NAME")
    previous_skip = System.get_env("ACCRUE_HOST_SKIP_SEEDS")
    Application.put_env(:accrue, :env, :dev)
    System.put_env("COMPOSE_PROJECT_NAME", "accrue-host-phase245-ordinary")
    System.put_env("ACCRUE_HOST_SKIP_SEEDS", "1")

    on_exit(fn ->
      Application.put_env(:accrue, :env, previous_env)

      for {key, value} <- [
            {"COMPOSE_PROJECT_NAME", previous_project},
            {"ACCRUE_HOST_SKIP_SEEDS", previous_skip}
          ] do
        if value, do: System.put_env(key, value), else: System.delete_env(key)
      end
    end)

    Code.eval_file(@ordinary_seed)
    :ok
  end

  test "ordinary Unicode identity preserves customer and lifecycle relationships on rerun" do
    customer = fake!(Customer, "cus_fake_00006")
    assert customer.name == "Atelier Café"
    assert String.valid?(customer.name)
    refute String.contains?(customer.name, ["Phase", "Boundary", "seed", "showcase"])
    assert customer.owner_type == "Organization"
    assert Repo.get!(AccrueHost.Accounts.Organization, customer.owner_id).slug == "trialing-co"
    sub = fake!(Subscription, "sub_showcase_incomplete")
    assert sub.customer_id == customer.id
    Code.eval_file(@ordinary_seed)
    assert Repo.get!(Customer, customer.id).name == customer.name
    assert Repo.get!(Customer, customer.id).processor_id == customer.processor_id
    assert fake!(Subscription, sub.processor_id).id == sub.id

    assert Repo.aggregate(from(c in Customer, where: c.processor_id == "cus_fake_00006"), :count) ==
             1
  end

  test "background customers have a repeatable mix of default methods and missing-method cases" do
    background =
      Repo.all(from(c in Customer, where: like(c.processor_id, "cus_%")))
      |> Enum.filter(&(&1.processor_id == "cus_" <> &1.id))

    assert length(background) > 0
    assert Enum.any?(background, &is_nil(&1.default_payment_method_id))
    assert Enum.any?(background, &(!is_nil(&1.default_payment_method_id)))

    for customer <- background do
      if :erlang.phash2(customer.id, 10) < 8 do
        method = Repo.get!(PaymentMethod, customer.default_payment_method_id)
        assert method.customer_id == customer.id
        assert method.processor == "fake"
        assert method.is_default
        assert method.card_brand in ["visa", "mastercard"]
        assert method.card_last4 in ["4242", "4444"]
      else
        assert is_nil(customer.default_payment_method_id)
      end
    end

    before = Enum.map(background, &{&1.id, &1.default_payment_method_id}) |> Enum.sort()

    counts =
      {Repo.aggregate(PaymentMethod, :count), Repo.aggregate(Event, :count),
       Repo.aggregate(Customer, :count)}

    Code.eval_file(@payment_methods_seed)

    after_rows =
      Enum.map(background, fn customer ->
        current = Repo.get!(Customer, customer.id)
        {current.id, current.default_payment_method_id}
      end)
      |> Enum.sort()

    assert before == after_rows

    assert counts ==
             {Repo.aggregate(PaymentMethod, :count), Repo.aggregate(Event, :count),
              Repo.aggregate(Customer, :count)}
  end

  test "payment-method additions refuse a different preview" do
    System.put_env("COMPOSE_PROJECT_NAME", "another-preview")

    assert_raise RuntimeError, ~r/payment-method seed refused/, fn ->
      Code.eval_file(@payment_methods_seed)
    end
  end

  test "promotion redemption totals and eligibility fields agree with their linked coupons" do
    percent = fake!(Coupon, "coupon_showcase_pct")
    amount = fake!(Coupon, "coupon_showcase_amt")
    expired = fake!(Coupon, "coupon_showcase_expired")
    active = fake!(PromotionCode, "promo_showcase_active")
    inactive = fake!(PromotionCode, "promo_showcase_inactive")
    assert active.coupon_id == percent.id
    assert inactive.coupon_id == amount.id

    for coupon <- [percent, amount, expired] do
      codes = Repo.all(from(p in PromotionCode, where: p.coupon_id == ^coupon.id))
      assert Enum.sum(Enum.map(codes, & &1.times_redeemed)) <= coupon.times_redeemed
      assert coupon.times_redeemed <= coupon.max_redemptions
      for code <- codes, do: assert(code.times_redeemed <= code.max_redemptions)
    end

    assert Decimal.equal?(percent.percent_off, Decimal.new("25"))
    assert {percent.duration, percent.duration_in_months} == {"repeating", 3}
    assert percent.valid and active.active
    assert {active.times_redeemed, active.max_redemptions} == {12, 100}
    assert DateTime.compare(active.expires_at, Accrue.Clock.utc_now()) == :gt
    assert {amount.amount_off_minor, amount.currency, amount.duration} == {1000, "usd", "once"}
    assert amount.valid
    refute inactive.active
    assert {inactive.times_redeemed, inactive.max_redemptions} == {500, 500}
    assert DateTime.compare(inactive.expires_at, Accrue.Clock.utc_now()) == :lt
    refute expired.valid
    assert Decimal.equal?(expired.percent_off, Decimal.new("40"))
    assert DateTime.compare(expired.redeem_by, inactive.expires_at) == :lt

    assert Repo.aggregate(from(p in PromotionCode, where: p.coupon_id == ^expired.id), :count) ==
             0

    assert percent.data == %{} and amount.data == %{} and expired.data == %{}
    assert active.data == %{} and inactive.data == %{}

    amount |> Ecto.Changeset.change(times_redeemed: 87) |> Repo.update!()
    Code.eval_file(@ordinary_seed)
    reconciled = Repo.get!(Coupon, amount.id)
    assert reconciled.times_redeemed == 500
    assert reconciled.processor_id == amount.processor_id
    assert fake!(PromotionCode, inactive.processor_id).id == inactive.id
  end

  test "lifecycle markers coincide with period boundaries without invented prices or events" do
    for {pid, customer_pid, status, marker} <- [
          {"sub_showcase_paused", "cus_fake_00005", :paused, :paused_at},
          {"sub_showcase_unpaid", "cus_fake_00003", :unpaid, :past_due_since},
          {"sub_showcase_incomplete", "cus_fake_00006", :incomplete, nil}
        ] do
      sub = fake!(Subscription, pid)
      assert sub.customer_id == fake!(Customer, customer_pid).id
      assert sub.status == status

      assert DateTime.diff(sub.current_period_end, sub.current_period_start, :second) ==
               30 * 86_400

      assert_utc(sub.current_period_end)

      if marker,
        do: assert(DateTime.compare(Map.fetch!(sub, marker), sub.current_period_end) == :eq)

      assert Repo.preload(sub, :subscription_items).subscription_items == []
      assert Repo.aggregate(from(e in Event, where: e.subject_id == ^sub.id), :count) == 0
      assert sub.data == %{}
    end

    assert fake!(Subscription, "sub_showcase_paused").pause_behavior == "void"
    assert is_nil(fake!(Subscription, "sub_showcase_incomplete").past_due_since)
    assert is_nil(fake!(Subscription, "sub_showcase_incomplete").paused_at)
  end

  test "invoice due paid and settlement boundaries use stored UTC precision" do
    portal = fake!(Invoice, "in_seed_healthy_portal_launch_paid")
    paid = fake!(Invoice, "in_showcase_paid_usd")
    open = fake!(Invoice, "in_showcase_open")
    jpy = fake!(Invoice, "in_showcase_paid_jpy")
    event = Repo.get_by!(Event, idempotency_key: "seed-showcase-invoice-paid-usd")
    succeeded = fake!(Charge, "ch_showcase_succeeded")
    charge_event = Repo.get_by!(Event, idempotency_key: "seed-showcase-charge-succeeded")
    assert portal.status == :paid
    assert DateTime.compare(portal.finalized_at, portal.paid_at) == :eq
    assert DateTime.compare(portal.period_end, portal.paid_at) == :eq
    assert DateTime.diff(portal.due_date, portal.paid_at, :second) == 30 * 86_400
    assert paid.status == :paid and paid.amount_remaining_minor == 0
    assert DateTime.compare(paid.period_end, paid.finalized_at) == :eq
    assert DateTime.compare(paid.paid_at, event.inserted_at) == :eq
    assert DateTime.compare(paid.paid_at, charge_event.inserted_at) == :eq
    assert charge_event.subject_id == succeeded.id
    assert charge_event.data == %{"amount_cents" => 5292, "currency" => "usd"}
    assert {succeeded.amount_cents, succeeded.currency} == {paid.total_minor, paid.currency}
    assert DateTime.diff(succeeded.fees_settled_at, charge_event.inserted_at, :second) == 86_400
    assert {succeeded.stripe_fee_amount_minor, succeeded.stripe_fee_currency} == {183, "usd"}
    assert open.status == :open and is_nil(open.paid_at)
    assert DateTime.compare(open.period_end, open.finalized_at) == :eq
    assert DateTime.diff(open.due_date, open.finalized_at, :second) == 13 * 86_400

    assert {jpy.subtotal_minor, jpy.tax_minor, jpy.total_minor, jpy.currency} ==
             {50_000, 5000, 55_000, "jpy"}

    assert jpy.amount_remaining_minor == 0

    for invoice <- [portal, paid, open, jpy] do
      assert_utc(invoice.finalized_at)
      assert invoice.subtotal_minor + invoice.tax_minor == invoice.total_minor
      assert invoice.total_minor == invoice.amount_paid_minor + invoice.amount_remaining_minor
    end

    for invoice <- [open, jpy] do
      assert Repo.aggregate(from(e in Event, where: e.subject_id == ^invoice.id), :count) == 0
      assert invoice.data == %{}
      assert Repo.preload(invoice, :items).items == []
    end
  end

  test "full and partial refunds preserve charge limits fees and missing provider history" do
    for {refund_id, charge_id, amount, fee_refunded, loss} <- [
          {"re_showcase_full", "ch_showcase_refunded", 9900, 317, 0},
          {"re_showcase_partial", "ch_showcase_partial_refunded", 5000, 0, 153}
        ] do
      refund = Repo.get_by!(Refund, stripe_id: refund_id)
      charge = fake!(Charge, charge_id)
      assert refund.charge_id == charge.id
      assert refund.processor_id == refund_id
      assert refund.status == :succeeded and charge.status == "succeeded"
      assert {refund.amount_minor, refund.currency} == {amount, charge.currency}
      assert refund.amount_minor <= charge.amount_cents
      assert refund.currency == "usd" and charge.stripe_fee_currency == "usd"
      assert refund.stripe_fee_refunded_amount_minor == fee_refunded
      assert refund.stripe_fee_refunded_amount_minor <= charge.stripe_fee_amount_minor
      assert refund.merchant_loss_amount_minor == loss
      assert DateTime.diff(refund.fees_settled_at, charge.fees_settled_at, :second) == 86_400
      assert_utc(refund.fees_settled_at)
      assert refund.data == %{}
      assert is_nil(refund.last_stripe_event_ts) and is_nil(refund.last_stripe_event_id)
    end

    partial = fake!(Charge, "ch_showcase_partial_refunded")
    assert partial.amount_cents == 20_000 and partial.stripe_fee_amount_minor == 610
    assert Repo.aggregate(from(e in Event, where: e.subject_id == ^partial.id), :count) == 0
    full = Repo.get_by!(Refund, stripe_id: "re_showcase_full")
    full_event = Repo.get_by!(Event, idempotency_key: "seed-showcase-charge-refunded")
    assert DateTime.compare(full_event.inserted_at, full.fees_settled_at) == :eq
  end

  defp fake!(schema, processor_id),
    do: Repo.get_by!(schema, processor: "fake", processor_id: processor_id)

  defp assert_utc(datetime) do
    assert datetime.time_zone == "Etc/UTC"
    assert datetime.utc_offset == 0 and datetime.std_offset == 0
  end
end
