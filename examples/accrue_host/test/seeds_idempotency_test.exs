defmodule AccrueHost.SeedsIdempotencyTest do
  @moduledoc """
  Adversarial coverage for BAN-04 (Phase 150): the example-host seed script
  must produce the past-due + healthy demo accounts AND back-dated dunning
  ledger events IDEMPOTENTLY.

  This guards the f26fab9b append-only-seed fix. An earlier seed back-dated
  events via `Repo.update_all` against the append-only `accrue_events` table,
  hitting the `BEFORE UPDATE OR DELETE` immutability trigger (SQLSTATE 45A01)
  on the second `mix ecto.reset`. The fix sets `inserted_at` at INSERT time via
  `Repo.insert_all` with `on_conflict: :nothing` on a partial-unique
  idempotency_key. Previously this was verified ONLY by manually running
  `mix ecto.reset` once — there was no repeatable automated guard. This is it.

  Not async: the seed touches the Fake processor and global billing rows.
  """
  use AccrueHost.DataCase, async: false

  alias Accrue.Events.Event
  alias Accrue.Connect.Account

  alias Accrue.Billing.{
    Charge,
    Coupon,
    Customer,
    Invoice,
    PromotionCode,
    Subscription
  }

  alias Accrue.Webhook.WebhookEvent
  alias AccrueHost.Accounts.User
  alias AccrueHost.Billing
  alias AccrueHost.Repo

  @seed_path Path.expand("../priv/repo/seeds.exs", __DIR__)

  setup do
    # The seed calls `AccrueHost.Billing.subscribe/2`, which dispatches to the
    # Fake processor (config/test.exs). Start it the same way the dunning banner
    # LiveView test does so the seed runs hermetically against the sandbox.
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    # `mix ecto.reset` runs the seed in dev env, where `Accrue.Clock.utc_now/0`
    # returns `DateTime.utc_now/0` (microsecond precision). Under the test env
    # the same call returns the Fake clock's epoch at SECOND precision, which
    # `Repo.insert_all` rejects against the `:utc_datetime_usec` `inserted_at`
    # column. To exercise the SAME code path `mix ecto.reset` does (the path
    # BAN-04 is about), point the Accrue clock at the real wall clock for the
    # duration of this test, then restore the test-env flag.
    previous_env = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :dev)
    on_exit(fn -> Application.put_env(:accrue, :env, previous_env) end)

    :ok
  end

  describe "priv/repo/seeds.exs (BAN-04 append-only idempotency)" do
    test "re-running the seed does not crash and does not double-count dunning events" do
      # --- First eval: full seed run -------------------------------------
      Code.eval_file(@seed_path)

      first_event_count = seed_dunning_event_count()

      assert first_event_count == 7,
             "expected the seed to insert exactly 7 back-dated dunning events, got #{first_event_count}"

      # Demo accounts exist after the first run.
      assert %User{} = Repo.get_by(User, email: "healthy@example.com")
      assert %User{} = Repo.get_by(User, email: "past-due@example.com")

      # Banner anchor: past-due org has a dunning campaign anchor; healthy does not.
      assert dunning_anchor_for("past-due-co"),
             "expected the past-due demo subscription to carry a dunning_campaign_started_at anchor"

      refute dunning_anchor_for("healthy-co"),
             "expected the healthy demo subscription to have NO dunning_campaign_started_at anchor"

      # --- Second eval: the core idempotency assertion -------------------
      # Must NOT raise. A raise here is exactly the f26fab9b regression:
      # either the append-only 45A01 immutability trigger on UPDATE, or a
      # unique-constraint crash on re-insert.
      Code.eval_file(@seed_path)

      second_event_count = seed_dunning_event_count()

      assert second_event_count == first_event_count,
             "re-running the seed double-counted dunning events: #{first_event_count} -> #{second_event_count} (on_conflict :nothing should collapse the re-run to a no-op)"

      # Demo accounts are still unique (no second user / org on re-run).
      assert Repo.aggregate(from(u in User, where: u.email == "healthy@example.com"), :count) == 1

      assert Repo.aggregate(from(u in User, where: u.email == "past-due@example.com"), :count) ==
               1
    end

    test "re-running the seed keeps Phase 191 fixture rows and append-only events stable" do
      Code.eval_file(@seed_path)

      first_counts = phase191_fixture_counts()
      first_route_ids = phase191_route_ids()

      # Part C added a coherent linked billing graph for the first 10 page
      # customers (sub + invoice + charge each), on top of the pre-existing
      # primary/at-risk rows. Customers stay at 28 (no new customers);
      # coupons/promos/connect/webhooks/events are untouched.
      #   subscriptions: 2 existing (active + at_risk) + 10 page = 12
      #   invoices:      1 existing (boundary)          + 10 page = 11
      #   charges:       1 existing (boundary)          + 10 page = 11
      assert first_counts == %{
               customers: 28,
               subscriptions: 12,
               invoices: 11,
               charges: 11,
               coupons: 1,
               promotion_codes: 1,
               connect_accounts: 1,
               webhooks: 1,
               events: 1
             }

      assert first_route_ids.customer_id == "19100000-0000-4000-8000-00000000a001"
      assert first_route_ids.subscription_id == "19100000-0000-4000-8000-00000000a002"
      assert first_route_ids.invoice_id == "19100000-0000-4000-8000-00000000a003"
      assert first_route_ids.charge_id == "19100000-0000-4000-8000-00000000a004"
      assert first_route_ids.coupon_id == "19100000-0000-4000-8000-00000000a005"
      assert first_route_ids.promotion_code_id == "19100000-0000-4000-8000-00000000a006"
      assert first_route_ids.connect_account_id == "19100000-0000-4000-8000-00000000a007"
      assert first_route_ids.webhook_id == "19100000-0000-4000-8000-00000000a008"

      Code.eval_file(@seed_path)

      assert phase191_fixture_counts() == first_counts
      assert phase191_route_ids() == first_route_ids
    end
  end

  defp seed_dunning_event_count do
    Repo.aggregate(
      from(e in Event, where: like(e.idempotency_key, "seed-dunning-%")),
      :count
    )
  end

  defp dunning_anchor_for(slug) do
    org = Repo.get_by!(AccrueHost.Accounts.Organization, slug: slug)
    {:ok, %{subscription: subscription}} = Billing.billing_state_for(org)
    subscription.dunning_campaign_started_at
  end

  defp phase191_fixture_counts do
    %{
      customers:
        Repo.aggregate(
          from(c in Customer, where: like(c.processor_id, "cus_phase191_host%")),
          :count
        ),
      subscriptions:
        Repo.aggregate(
          from(s in Subscription, where: like(s.processor_id, "sub_phase191_host%")),
          :count
        ),
      invoices:
        Repo.aggregate(
          from(i in Invoice, where: like(i.processor_id, "in_phase191_host%")),
          :count
        ),
      charges:
        Repo.aggregate(
          from(c in Charge, where: like(c.processor_id, "ch_phase191_host%")),
          :count
        ),
      coupons:
        Repo.aggregate(
          from(c in Coupon, where: like(c.processor_id, "coupon_phase191_host%")),
          :count
        ),
      promotion_codes:
        Repo.aggregate(
          from(p in PromotionCode, where: like(p.processor_id, "promo_phase191_host%")),
          :count
        ),
      connect_accounts:
        Repo.aggregate(
          from(a in Account, where: like(a.stripe_account_id, "acct_phase191_host%")),
          :count
        ),
      webhooks:
        Repo.aggregate(
          from(w in WebhookEvent, where: like(w.processor_event_id, "evt_phase191_host%")),
          :count
        ),
      events:
        Repo.aggregate(
          from(e in Event, where: like(e.idempotency_key, "seed-phase191-%")),
          :count
        )
    }
  end

  defp phase191_route_ids do
    %{
      customer_id:
        id_for(Customer, processor: "fake", processor_id: "cus_phase191_host_customer"),
      subscription_id:
        id_for(Subscription, processor: "fake", processor_id: "sub_phase191_host_active"),
      invoice_id: id_for(Invoice, processor: "fake", processor_id: "in_phase191_host_boundary"),
      charge_id: id_for(Charge, processor: "fake", processor_id: "ch_phase191_host_boundary"),
      coupon_id: id_for(Coupon, processor: "fake", processor_id: "coupon_phase191_host_unicode"),
      promotion_code_id:
        id_for(PromotionCode, processor: "fake", processor_id: "promo_phase191_host_unicode"),
      connect_account_id: id_for(Account, stripe_account_id: "acct_phase191_host_boundary"),
      webhook_id:
        id_for(WebhookEvent, processor: "stripe", processor_event_id: "evt_phase191_host_dead"),
      source_event_id: id_for(Event, idempotency_key: "seed-phase191-fixture-seeded")
    }
  end

  defp id_for(schema, clauses) do
    case Repo.get_by(schema, clauses) do
      nil -> nil
      %{id: id} -> id
    end
  end
end
