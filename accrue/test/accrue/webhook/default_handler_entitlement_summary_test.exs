defmodule Accrue.Webhook.DefaultHandlerEntitlementSummaryTest do
  @moduledoc """
  Phase 127 (ENT-10) — entitlement-summary reducer contract.

  Encodes the executable contract for the optional, off-by-default
  Stripe-native entitlement-summary sync reducer.

  Behaviors covered (VALIDATION Per-Task Verification Map):

    * **enabled -> cache write** — `stripe_native_sync: :advisory` + a summary
      webhook writes one `accrue_entitlement_summaries` row for the customer
      with the inline entitlements (<=10) and `has_more` persisted.
    * **stale-skip (`:lt`)** — an older event (strict `:lt` on the watermark)
      is skipped and emits `[:accrue, :webhooks, :stale_event]` with
      `object_type: :entitlement_summary`; no clobber.
    * **tie (`:eq`)** — equal timestamps proceed (no skip).
    * **orphan customer** — customer-not-found returns `{:ok, :deferred}` and
      emits `[:accrue, :webhooks, :orphan_entitlement_summary]`, never raises,
      never creates a customer, writes no row.
    * **malformed** — missing `customer` / non-list `entitlements` returns
      `{:ok, :ignored}`, never writes garbage.
    * **truncated** — `has_more: true` sets `truncated: true` on the row.
    * **disabled (default)** — with sync `:disabled`, the dispatch clause
      early-returns `{:ok, :ignored}` and writes no row (off-lane is inert).
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.EntitlementSummary

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "stripe",
        processor_id: "cus_fake_ent_summary",
        email: "ent-summary@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  defp enable_advisory_sync do
    prev = Application.get_env(:accrue, :entitlements)
    merged = Keyword.put(prev || [], :stripe_native_sync, :advisory)
    Application.put_env(:accrue, :entitlements, merged)

    on_exit(fn ->
      if prev do
        Application.put_env(:accrue, :entitlements, prev)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)
  end

  # CR-01 regression: the production webhook path is DispatchWorker ->
  # `handle_event/3`, NOT the raw-map `handle/1` the other tests use. The
  # summary object has no top-level `id`, so the lean `%Accrue.Webhook.Event{}`
  # carries `object_id: nil`; without a dedicated dispatch clause the event
  # short-circuits on the generic nil-guard and the reducer never runs. These
  # tests lock the real path end-to-end (the object travels in `ctx`, exactly
  # as `Accrue.Webhook.DispatchWorker` stows it under `:meter_error_object`).
  describe "real DispatchWorker path (handle_event/3)" do
    @summary_type "entitlements.active_entitlement_summary.updated"

    defp summary_event_and_ctx(customer_processor_id, opts) do
      raw = StripeFixtures.entitlement_summary_event([customer: customer_processor_id] ++ opts)
      summary_object = raw["data"]["object"]

      event = %Accrue.Webhook.Event{
        type: raw["type"],
        object_id: nil,
        livemode: false,
        created_at: DateTime.from_unix!(raw["created"]),
        processor_event_id: raw["id"],
        processor: :stripe
      }

      {event, %{meter_error_object: summary_object}}
    end

    test "enabled (:advisory): writes a row via the lean event + ctx", %{customer: customer} do
      enable_advisory_sync()

      {event, ctx} =
        summary_event_and_ctx(customer.processor_id,
          entitlements: [%{"id" => "ent_1", "feature" => "feat_a", "lookup_key" => "alpha"}]
        )

      assert :ok = Accrue.Webhook.DefaultHandler.handle_event(event.type, event, ctx)

      row = Repo.get_by(EntitlementSummary, customer_id: customer.id)
      assert row
      assert row.entitlement_count == 1
      assert row.stripe_customer_id == customer.processor_id
    end

    test "disabled (default): writes no row via the lean event + ctx", %{customer: customer} do
      {event, ctx} = summary_event_and_ctx(customer.processor_id, [])

      assert :ok = Accrue.Webhook.DefaultHandler.handle_event(event.type, event, ctx)
      refute Repo.get_by(EntitlementSummary, customer_id: customer.id)
    end
  end

  describe "enabled (:advisory) -> cache write" do
    setup do
      enable_advisory_sync()
      :ok
    end

    test "writes one row per customer with inline entitlements + has_more", %{customer: customer} do
      event =
        StripeFixtures.entitlement_summary_event(
          customer: customer.processor_id,
          entitlements: [
            %{"id" => "ent_1", "feature" => "feat_a", "lookup_key" => "alpha"},
            %{"id" => "ent_2", "feature" => "feat_b", "lookup_key" => "beta"}
          ],
          has_more: false
        )

      assert {:ok, %EntitlementSummary{} = saved} = Accrue.Webhook.DefaultHandler.handle(event)
      assert saved.customer_id == customer.id
      assert saved.entitlement_count == 2
      assert saved.truncated == false

      row = Repo.get_by(EntitlementSummary, customer_id: customer.id)
      assert row
      assert row.stripe_customer_id == customer.processor_id
    end

    test "truncated summary (has_more: true) sets truncated: true", %{customer: customer} do
      event =
        StripeFixtures.entitlement_summary_event(
          customer: customer.processor_id,
          has_more: true
        )

      assert {:ok, %EntitlementSummary{truncated: true}} =
               Accrue.Webhook.DefaultHandler.handle(event)
    end

    test "stale event (strict :lt) skips with :stale_event telemetry, no clobber", %{
      customer: customer
    } do
      newer_ts = DateTime.add(Accrue.Clock.utc_now(), 3600, :second)

      # Seed a row already watermarked at `newer_ts`.
      {:ok, _} =
        %EntitlementSummary{}
        |> EntitlementSummary.force_changeset(%{
          customer_id: customer.id,
          stripe_customer_id: customer.processor_id,
          entitlement_count: 1,
          last_stripe_event_ts: newer_ts,
          last_stripe_event_id: "evt_new"
        })
        |> Repo.insert()

      test_pid = self()

      :telemetry.attach(
        "test-ent-stale-#{System.unique_integer([:positive])}",
        [:accrue, :webhooks, :stale_event],
        fn evt, meas, meta, _ -> send(test_pid, {:stale, evt, meas, meta}) end,
        nil
      )

      older_event =
        StripeFixtures.entitlement_summary_event(
          [customer: customer.processor_id],
          %{
            "id" => "evt_older",
            "created" => DateTime.to_unix(DateTime.add(newer_ts, -1800, :second))
          }
        )

      assert {:ok, :stale} = Accrue.Webhook.DefaultHandler.handle(older_event)
      assert_received {:stale, _, _, %{object_type: :entitlement_summary, event_id: "evt_older"}}

      unchanged = Repo.get_by(EntitlementSummary, customer_id: customer.id)
      assert unchanged.last_stripe_event_id == "evt_new"
    end

    test "tie on equal timestamps processes the event (no skip)", %{customer: customer} do
      ts = DateTime.truncate(Accrue.Clock.utc_now(), :second)

      {:ok, _} =
        %EntitlementSummary{}
        |> EntitlementSummary.force_changeset(%{
          customer_id: customer.id,
          stripe_customer_id: customer.processor_id,
          entitlement_count: 1,
          last_stripe_event_ts: ts,
          last_stripe_event_id: "evt_a"
        })
        |> Repo.insert()

      equal_event =
        StripeFixtures.entitlement_summary_event(
          [customer: customer.processor_id],
          %{"id" => "evt_b", "created" => DateTime.to_unix(ts)}
        )

      assert {:ok, %EntitlementSummary{}} = Accrue.Webhook.DefaultHandler.handle(equal_event)
      updated = Repo.get_by(EntitlementSummary, customer_id: customer.id)
      assert updated.last_stripe_event_id == "evt_b"
    end

    test "orphan customer -> {:ok, :deferred} + orphan telemetry, no raise, no row" do
      test_pid = self()

      :telemetry.attach(
        "test-ent-orphan-#{System.unique_integer([:positive])}",
        [:accrue, :webhooks, :orphan_entitlement_summary],
        fn evt, meas, meta, _ -> send(test_pid, {:orphan, evt, meas, meta}) end,
        nil
      )

      event = StripeFixtures.entitlement_summary_event(customer: "cus_does_not_exist")

      assert {:ok, :deferred} = Accrue.Webhook.DefaultHandler.handle(event)
      assert_received {:orphan, _, _, %{customer_stripe_id: "cus_does_not_exist"}}
      assert Repo.aggregate(EntitlementSummary, :count) == 0
    end

    test "malformed (missing customer) -> {:ok, :ignored}, no garbage write" do
      event =
        StripeFixtures.entitlement_summary_event()
        |> pop_in_object("customer")

      assert {:ok, :ignored} = Accrue.Webhook.DefaultHandler.handle(event)
      assert Repo.aggregate(EntitlementSummary, :count) == 0
    end

    test "malformed (non-list entitlements) -> {:ok, :ignored}, no garbage write", %{
      customer: customer
    } do
      event = StripeFixtures.entitlement_summary_event(customer: customer.processor_id)
      broken = put_in(event, ["data", "object", "entitlements"], "not-a-list")

      assert {:ok, :ignored} = Accrue.Webhook.DefaultHandler.handle(broken)
      assert Repo.aggregate(EntitlementSummary, :count) == 0
    end
  end

  describe "disabled (default) off-lane" do
    test "sync :disabled -> {:ok, :ignored}, no row written", %{customer: customer} do
      refute Accrue.Config.stripe_native_sync?()

      event = StripeFixtures.entitlement_summary_event(customer: customer.processor_id)

      assert {:ok, :ignored} = Accrue.Webhook.DefaultHandler.handle(event)
      assert Repo.aggregate(EntitlementSummary, :count) == 0
    end
  end

  # Remove a key from the summary `data.object` to model a malformed payload.
  defp pop_in_object(event, key) do
    update_in(event, ["data", "object"], &Map.delete(&1, key))
  end
end
