defmodule AccrueHost.OrdinaryPreviewSeedTest do
  use AccrueHost.DataCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Charge, Coupon, Customer, Invoice, PromotionCode, Refund, Subscription}
  alias Accrue.Events.Event
  alias AccrueHost.Repo

  @ordinary_seed Path.expand("../priv/repo/seeds/ordinary.exs", __DIR__)

  setup do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    previous_env = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :dev)
    on_exit(fn -> Application.put_env(:accrue, :env, previous_env) end)

    previous_project = System.get_env("COMPOSE_PROJECT_NAME")
    previous_skip = System.get_env("ACCRUE_HOST_SKIP_SEEDS")
    System.put_env("COMPOSE_PROJECT_NAME", "accrue-host-phase245-ordinary")
    System.put_env("ACCRUE_HOST_SKIP_SEEDS", "1")

    on_exit(fn ->
      if previous_project,
        do: System.put_env("COMPOSE_PROJECT_NAME", previous_project),
        else: System.delete_env("COMPOSE_PROJECT_NAME")

      if previous_skip,
        do: System.put_env("ACCRUE_HOST_SKIP_SEEDS", previous_skip),
        else: System.delete_env("ACCRUE_HOST_SKIP_SEEDS")
    end)

    :ok
  end

  test "ordinary seed reruns keep one coherent invoice journey and exclude Phase 191" do
    seed_if_available()
    first = invoice_journey()

    seed_if_available()
    second = invoice_journey()

    assert first == second
    assert first.invoice_number == "PORTAL-LAUNCH-001"
    assert first.invoice_count == 1
    assert first.customer_count == 1
    assert first.subscription_count == 1
    assert first.amounts == %{subtotal: 1_500, tax: 0, total: 1_500, paid: 1_500, remaining: 0}
    assert first.currency == "usd"
    assert first.customer_owner_type == "User"
    assert first.subscription_status == :active
    assert first.subscription_customer_id == first.customer_id
    assert first.phase191_events == 0
    assert first.phase191_customers == 0
    assert first.edge_customers == 0
  end

  test "showcase invoices without subscription links use a manual billing reason" do
    seed_if_available()
    first = showcase_invoice_facts()

    seed_if_available()
    second = showcase_invoice_facts()

    assert first == second
    assert map_size(first) == 6

    expected_customers = %{
      "in_showcase_draft" => {"cus_fake_00001", "Northwind Labs"},
      "in_showcase_open" => {"cus_fake_00003", "Tidewater Systems"},
      "in_showcase_paid_usd" => {"cus_fake_00001", "Northwind Labs"},
      "in_showcase_paid_jpy" => {"cus_fake_00005", "Meridian Group"},
      "in_showcase_void" => {"cus_fake_00004", "Redwood Studio"},
      "in_showcase_uncollectible" => {"cus_fake_00003", "Tidewater Systems"}
    }

    for {processor_id, facts} <- first do
      assert facts.customer_exists
      assert facts.subscription_id == nil

      assert {facts.customer_processor_id, facts.customer_name} ==
               expected_customers[processor_id]

      assert facts.billing_reason == "manual",
             "#{processor_id} claims a subscription without a linked subscription"

      if facts.status == :void do
        assert facts.amount_paid_minor == 0
        assert facts.amount_remaining_minor == 0
      else
        assert facts.total_minor == facts.amount_paid_minor + facts.amount_remaining_minor
      end

      assert facts.currency in ["usd", "jpy"]
      assert DateTime.compare(facts.period_start, facts.period_end) == :lt
    end
  end

  test "ordinary seed reconciles a stale billing reason on its existing showcase row" do
    seed_if_available()
    invoice = Repo.get_by!(Invoice, processor: "fake", processor_id: "in_showcase_paid_usd")

    invoice
    |> Ecto.Changeset.change(billing_reason: "subscription_cycle")
    |> Repo.update!()

    seed_if_available()

    reconciled = Repo.get!(Invoice, invoice.id)
    assert reconciled.billing_reason == "manual"
    assert reconciled.subscription_id == nil
    assert reconciled.total_minor == 5292
    assert reconciled.currency == "usd"
  end

  test "showcase paid and refund evidence agrees with stored money and UTC history" do
    seed_if_available()

    paid = Repo.get_by!(Invoice, processor: "fake", processor_id: "in_showcase_paid_usd")
    paid_event = Repo.get_by!(Event, idempotency_key: "seed-showcase-invoice-paid-usd")
    assert paid_event.subject_type == "Invoice"
    assert paid_event.subject_id == paid.id

    assert paid_event.data == %{
             "amount_paid_minor" => paid.amount_paid_minor,
             "currency" => paid.currency
           }

    assert paid.amount_due_minor == 5292
    assert paid.amount_paid_minor == paid.total_minor
    assert paid.amount_remaining_minor == 0
    assert DateTime.compare(paid.finalized_at, paid.paid_at) == :lt
    assert DateTime.compare(paid.paid_at, paid_event.inserted_at) == :eq

    open = Repo.get_by!(Invoice, processor: "fake", processor_id: "in_showcase_open")
    assert open.status == :open
    assert open.amount_remaining_minor == open.amount_due_minor
    assert DateTime.compare(open.finalized_at, open.due_date) == :lt

    void = Repo.get_by!(Invoice, processor: "fake", processor_id: "in_showcase_void")
    assert void.status == :void
    assert void.amount_paid_minor == 0
    assert DateTime.compare(void.finalized_at, void.voided_at) == :lt

    paid_jpy = Repo.get_by!(Invoice, processor: "fake", processor_id: "in_showcase_paid_jpy")
    assert paid_jpy.currency == "jpy"
    assert paid_jpy.total_minor == 55_000
    assert paid_jpy.amount_paid_minor == paid_jpy.total_minor
    assert DateTime.compare(paid_jpy.finalized_at, paid_jpy.paid_at) == :lt

    charge = Repo.get_by!(Charge, processor: "fake", processor_id: "ch_showcase_refunded")
    refund = Repo.get_by!(Refund, stripe_id: "re_showcase_full")
    refund_event = Repo.get_by!(Event, idempotency_key: "seed-showcase-charge-refunded")

    assert refund.charge_id == charge.id
    assert refund.amount_minor == charge.amount_cents
    assert refund.currency == charge.currency
    assert refund_event.subject_id == charge.id

    assert refund_event.data == %{
             "amount_refunded_minor" => refund.amount_minor,
             "currency" => refund.currency
           }

    assert DateTime.compare(charge.fees_settled_at, refund.fees_settled_at) == :lt

    failed_charge = Repo.get_by!(Charge, processor: "fake", processor_id: "ch_showcase_failed")
    failed_event = Repo.get_by!(Event, idempotency_key: "seed-showcase-charge-failed")
    assert failed_charge.status == "failed"
    assert is_nil(failed_charge.fees_settled_at)
    assert failed_event.subject_id == failed_charge.id
    assert failed_event.data["amount_cents"] == failed_charge.amount_cents
    assert failed_event.data["failure_code"] == "card_declined"

    percent_coupon = Repo.get_by!(Coupon, processor: "fake", processor_id: "coupon_showcase_pct")

    active_code =
      Repo.get_by!(PromotionCode, processor: "fake", processor_id: "promo_showcase_active")

    assert active_code.coupon_id == percent_coupon.id
    assert active_code.active
    assert active_code.times_redeemed == percent_coupon.times_redeemed
  end

  defp seed_if_available do
    Code.eval_file(@ordinary_seed)
  end

  defp invoice_journey do
    invoice =
      Repo.get_by(Invoice, processor: "fake", processor_id: "in_seed_healthy_portal_launch_paid")

    assert not is_nil(invoice), "expected the ordinary paid invoice journey to be seeded"
    customer = Repo.get!(Customer, invoice.customer_id)
    subscription = Repo.get!(Subscription, invoice.subscription_id)

    invoice_count =
      Repo.aggregate(
        from(row in Invoice,
          where:
            row.processor == "fake" and row.processor_id == "in_seed_healthy_portal_launch_paid"
        ),
        :count
      )

    customer_count =
      Repo.aggregate(from(row in Customer, where: row.id == ^invoice.customer_id), :count)

    subscription_count =
      Repo.aggregate(from(row in Subscription, where: row.id == ^invoice.subscription_id), :count)

    %{
      invoice_number: invoice.number,
      invoice_id: invoice.id,
      invoice_count: invoice_count,
      customer_id: customer.id,
      customer_count: customer_count,
      customer_owner_type: customer.owner_type,
      subscription_id: subscription.id,
      subscription_count: subscription_count,
      subscription_status: subscription.status,
      subscription_customer_id: subscription.customer_id,
      currency: invoice.currency,
      amounts: %{
        subtotal: invoice.subtotal_minor,
        tax: invoice.tax_minor,
        total: invoice.total_minor,
        paid: invoice.amount_paid_minor,
        remaining: invoice.amount_remaining_minor
      },
      phase191_events:
        Repo.aggregate(
          from(e in Event, where: like(e.idempotency_key, "seed-phase191-%")),
          :count
        ),
      phase191_customers:
        Repo.aggregate(
          from(c in Customer, where: like(c.processor_id, "cus_phase191_host%")),
          :count
        ),
      edge_customers:
        Repo.aggregate(from(c in Customer, where: c.processor_id == "cus_e2e_edge_1"), :count)
    }
  end

  defp showcase_invoice_facts do
    Repo.all(
      from(invoice in Invoice,
        where: invoice.processor == "fake" and like(invoice.processor_id, "in_showcase_%"),
        order_by: invoice.processor_id
      )
    )
    |> Map.new(fn invoice ->
      customer_exists = not is_nil(Repo.get(Customer, invoice.customer_id))
      customer = Repo.get!(Customer, invoice.customer_id)

      {invoice.processor_id,
       %{
         customer_id: invoice.customer_id,
         customer_exists: customer_exists,
         customer_processor_id: customer.processor_id,
         customer_name: customer.name,
         subscription_id: invoice.subscription_id,
         billing_reason: invoice.billing_reason,
         status: invoice.status,
         total_minor: invoice.total_minor,
         amount_paid_minor: invoice.amount_paid_minor,
         amount_remaining_minor: invoice.amount_remaining_minor,
         currency: invoice.currency,
         period_start: invoice.period_start,
         period_end: invoice.period_end
       }}
    end)
  end
end
