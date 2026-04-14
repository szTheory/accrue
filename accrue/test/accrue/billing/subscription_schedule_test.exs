defmodule Accrue.Billing.SubscriptionScheduleTest do
  @moduledoc """
  Phase 4 Plan 03 (BILL-16) — SubscriptionSchedule schema, projection,
  actions, and DefaultHandler webhook reducer.

  Covers:
    * `subscribe_via_schedule/3` creates a row via the Fake adapter
    * `subscription_schedule.created` webhook inserts a local row
    * Out-of-order `.updated` before `.created` uses `:deferred` path
    * `.released`/`.canceled` webhooks stamp the timestamps
    * `changeset/2` validates status, `force_status_changeset/2` doesn't
    * Full Stripe payload preserved in `data` jsonb via stringify helper
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{SubscriptionSchedule, SubscriptionScheduleProjection}
  alias Accrue.Webhook.DefaultHandler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_sched",
        email: "sched@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "subscribe_via_schedule/3" do
    test "creates a SubscriptionSchedule row via the Fake adapter", %{customer: customer} do
      phases = [
        %{start_date: nil, items: [%{price: "price_intro", quantity: 1}]},
        %{items: [%{price: "price_regular", quantity: 1}]}
      ]

      assert {:ok, %SubscriptionSchedule{} = sched} =
               Billing.subscribe_via_schedule(customer, phases)

      assert sched.customer_id == customer.id
      assert sched.processor == "fake"
      assert is_binary(sched.processor_id)
      assert sched.status == "not_started"
      assert sched.phases_count == 2
    end

    test "records a subscription_schedule.created event", %{customer: customer} do
      {:ok, sched} =
        Billing.subscribe_via_schedule(customer, [
          %{items: [%{price: "price_intro"}]},
          %{items: [%{price: "price_regular"}]}
        ])

      row =
        Repo.one!(
          from(e in Accrue.Events.Event,
            where:
              e.type == "subscription_schedule.created" and
                e.subject_id == ^sched.id
          )
        )

      assert row.data["phases_count"] == 2 or row.data[:phases_count] == 2
    end
  end

  describe "webhook reducer — subscription_schedule.*" do
    test "created webhook inserts local row", %{customer: customer} do
      fixture =
        StripeFixtures.subscription_schedule(%{"customer" => customer.processor_id})

      # Prime the Fake so the default handler's fetch call finds canonical state.
      prime_fake_schedule(fixture)

      event =
        StripeFixtures.webhook_event(
          "subscription_schedule.created",
          fixture
        )

      assert {:ok, %SubscriptionSchedule{} = sched} = DefaultHandler.handle(event)
      assert sched.processor_id == fixture["id"]
      assert sched.customer_id == customer.id
      assert sched.phases_count == 2
    end

    test "out-of-order .updated arrives before .created → :deferred", %{customer: _customer} do
      # The .updated arrives but the Fake has no canonical entry for the
      # id yet — reducer should hit the `:deferred` orphan path when the
      # fake fetch call fails. Use a schedule for an *unknown* customer
      # (different processor_id) to hit the customer-not-found branch.
      fixture =
        StripeFixtures.subscription_schedule(%{
          "customer" => "cus_unknown_not_in_db"
        })

      prime_fake_schedule(fixture)

      event = StripeFixtures.webhook_event("subscription_schedule.updated", fixture)

      assert {:ok, :deferred} = DefaultHandler.handle(event)
    end

    test "released webhook stamps released_at", %{customer: customer} do
      fixture =
        StripeFixtures.subscription_schedule(%{
          "customer" => customer.processor_id,
          "status" => "released",
          "released_at" => DateTime.to_unix(DateTime.utc_now())
        })

      prime_fake_schedule(fixture)

      event = StripeFixtures.webhook_event("subscription_schedule.released", fixture)

      assert {:ok, %SubscriptionSchedule{} = sched} = DefaultHandler.handle(event)
      assert sched.status == "released"
      assert %DateTime{} = sched.released_at
    end

    test "canceled webhook stamps canceled_at", %{customer: customer} do
      fixture =
        StripeFixtures.subscription_schedule(%{
          "customer" => customer.processor_id,
          "status" => "canceled",
          "canceled_at" => DateTime.to_unix(DateTime.utc_now())
        })

      prime_fake_schedule(fixture)

      event = StripeFixtures.webhook_event("subscription_schedule.canceled", fixture)

      assert {:ok, %SubscriptionSchedule{} = sched} = DefaultHandler.handle(event)
      assert sched.status == "canceled"
      assert %DateTime{} = sched.canceled_at
    end
  end

  describe "changesets" do
    test "changeset/2 rejects invalid status" do
      cs =
        SubscriptionSchedule.changeset(%SubscriptionSchedule{}, %{
          processor: "fake",
          processor_id: "sub_sched_1",
          status: "totally_bogus"
        })

      refute cs.valid?
      assert %{status: [_ | _]} = errors_on(cs)
    end

    test "force_status_changeset/2 accepts any status string" do
      cs =
        SubscriptionSchedule.force_status_changeset(%SubscriptionSchedule{}, %{
          processor: "fake",
          processor_id: "sub_sched_2",
          status: "anything_stripe_sends"
        })

      assert cs.valid?
    end
  end

  describe "projection" do
    test "decompose preserves the full Stripe object in `data` as string-keyed jsonb" do
      fixture = StripeFixtures.subscription_schedule()
      {:ok, attrs} = SubscriptionScheduleProjection.decompose(fixture)

      assert attrs.processor_id == fixture["id"]
      assert attrs.phases_count == 2
      assert is_map(attrs.data)
      # nested lists of maps preserved
      assert is_list(attrs.data["phases"])
    end
  end

  # ---------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------

  # Directly inject the fixture into the Fake's subscription_schedules
  # ETS map so the DefaultHandler's canonical refetch returns it.
  defp prime_fake_schedule(fixture) do
    Accrue.Processor.Fake.stub(:subscription_schedule_fetch, fn _id, _opts ->
      {:ok, fixture}
    end)

    :ok
  end

  defp errors_on(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _whole, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
