defmodule AccrueHost.Phase191SeedReachabilityTest do
  @moduledoc """
  Host-level proof that Phase 191 click-through fixture data is reachable from
  deterministic seed rows, not from browser-only forcing helpers.
  """

  use AccrueHost.DataCase, async: false

  alias Accrue.Billing.{
    Charge,
    Coupon,
    Customer,
    Invoice,
    PromotionCode,
    Subscription
  }

  alias Accrue.Connect.Account
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent

  @seed_path Path.expand("../../priv/repo/seeds.exs", __DIR__)

  setup do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    previous_env = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :dev)
    on_exit(fn -> Application.put_env(:accrue, :env, previous_env) end)

    :ok
  end

  test "Phase 191 namespace exposes null-field, boundary, high-count, and non-ASCII host records" do
    Code.eval_file(@seed_path)

    customer =
      Repo.get_by!(Customer, processor: "fake", processor_id: "cus_phase191_host_customer")

    invoice = Repo.get_by!(Invoice, processor: "fake", processor_id: "in_phase191_host_boundary")
    charge = Repo.get_by!(Charge, processor: "fake", processor_id: "ch_phase191_host_boundary")
    coupon = Repo.get_by!(Coupon, processor: "fake", processor_id: "coupon_phase191_host_unicode")

    promo_code =
      Repo.get_by!(PromotionCode,
        processor: "fake",
        processor_id: "promo_phase191_host_unicode"
      )

    connect_account = Repo.get_by!(Account, stripe_account_id: "acct_phase191_host_boundary")
    webhook = Repo.get_by!(WebhookEvent, processor_event_id: "evt_phase191_host_dead")
    source_event = Repo.get_by!(Event, idempotency_key: "seed-phase191-fixture-seeded")

    assert customer.id == "19100000-0000-4000-8000-00000000a001"
    assert customer.name =~ "株式会社"
    assert customer.name =~ "Café"
    assert customer.email == "phase191-host-customer@example.com"
    assert customer.metadata["phase191_fixture"] == "non_ascii"
    assert customer.data["phase191_high_count"] == 100_000
    assert customer.data["optional_profile_fields"] == nil
    assert is_nil(customer.default_payment_method_id)

    assert invoice.hosted_url == nil
    assert invoice.pdf_url == nil
    assert invoice.currency == "jpy"
    assert invoice.metadata["phase191_fixture"] == "null-optional-fields"
    assert invoice.data["memo"] == nil
    assert invoice.data["phase191_non_ascii_note"] == "請求書"

    assert charge.amount_cents == 100_000
    assert charge.data["receipt_url"] == nil
    assert charge.data["phase191_high_count"] == 100_000

    assert coupon.name =~ "Crème"
    assert promo_code.code == "ÉTÉ191"
    assert promo_code.metadata["phase191_fixture"] == "non_ascii"

    assert connect_account.requirements["currently_due"] == ["external_account"]
    assert connect_account.data["phase191_null_future_requirement"] == nil

    assert webhook.status == :dead
    assert webhook.raw_body =~ "evt_phase191_host_dead"

    assert source_event.subject_type == "Phase191Fixture"
    assert source_event.actor_id == "phase191_host"

    assert boundary_count("cus_phase191_host_zero") == 0
    assert boundary_count("cus_phase191_host_one") == 1
    assert paginated_count() == 26
  end

  test "Phase 191 seed expansion preserves pre-existing edge-state anchors" do
    Code.eval_file(@seed_path)

    assert %Customer{name: long_name} =
             Repo.get_by(Customer, processor: "fake", processor_id: "cus_e2e_edge_1")

    assert long_name =~ "E2E Edge LongName"

    assert %Subscription{status: :past_due, dunning_campaign_started_at: %DateTime{}} =
             Repo.get_by(Subscription,
               processor: "fake",
               processor_id: "sub_e2e_edge_at_risk"
             )

    assert %Subscription{status: :active, cancel_at_period_end: true} =
             Repo.get_by(Subscription,
               processor: "fake",
               processor_id: "sub_e2e_edge_canceling"
             )

    assert %Charge{currency: "jpy", amount_cents: 55_000} =
             Repo.get_by(Charge, processor: "fake", processor_id: "ch_e2e_edge_jpy")

    assert %Invoice{currency: "jpy", status: :open, amount_due_minor: 55_000} =
             Repo.get_by(Invoice, processor: "fake", processor_id: "in_e2e_edge_jpy")
  end

  defp boundary_count(processor_id) do
    Repo.aggregate(
      from(c in Customer, where: c.processor == "fake" and c.processor_id == ^processor_id),
      :count
    )
  end

  defp paginated_count do
    Repo.aggregate(
      from(c in Customer,
        where: c.processor == "fake" and like(c.processor_id, "cus_phase191_host_page_%")
      ),
      :count
    )
  end
end
