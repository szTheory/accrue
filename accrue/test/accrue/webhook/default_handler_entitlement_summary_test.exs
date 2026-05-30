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

  # ENT-10 scoping isolation: Plan 01, Task 1, Behavior 2.
  # Verifies that a customer row with the same processor_id but a DIFFERENT
  # processor value is NOT matched — the strict two-column scope
  # (processor_id + processor) prevents cross-processor ID collisions.
  describe "ENT-10 cross-processor isolation (processor differs -> no match)" do
    setup do
      enable_advisory_sync()
      :ok
    end

    test "same processor_id under 'fake' processor is invisible to a :stripe webhook", %{
      customer: _stripe_customer
    } do
      # The shared setup already inserted a customer with processor: "stripe",
      # processor_id: "cus_fake_ent_summary". Insert a SECOND customer row
      # with processor: "fake" and the SAME processor_id — this simulates
      # the pre-ENT-10 collision scenario.
      {:ok, fake_customer} =
        %Customer{}
        |> Customer.changeset(%{
          owner_type: "User",
          owner_id: Ecto.UUID.generate(),
          processor: "fake",
          processor_id: "cus_fake_ent_summary",
          email: "ent-summary-fake@example.com"
        })
        |> Repo.insert()

      # Fire a Stripe webhook carrying "cus_fake_ent_summary". The handle/1
      # path defaults to :stripe — so the lookup must match processor: "stripe",
      # not processor: "fake". The stripe customer exists, so the result should
      # be {:ok, %EntitlementSummary{}} associated with the stripe customer, NOT
      # with fake_customer.
      event =
        StripeFixtures.entitlement_summary_event(
          customer: "cus_fake_ent_summary",
          entitlements: [%{"id" => "ent_x", "feature" => "feat_x", "lookup_key" => "x"}]
        )

      assert {:ok, %EntitlementSummary{} = saved} = Accrue.Webhook.DefaultHandler.handle(event)

      # The saved row must be linked to the STRIPE customer, not the fake one.
      assert saved.customer_id != fake_customer.id

      # The fake customer must have NO entitlement summary row.
      refute Repo.get_by(EntitlementSummary, customer_id: fake_customer.id)
    end
  end

  # -----------------------------------------------------------------------
  # Phase 154 — ADV-02, ADV-03, POL-01, POL-02 correctness tests
  # -----------------------------------------------------------------------

  describe "ADV-02: nil last_stripe_event_ts event updates the row (not a silent no-op)" do
    setup do
      enable_advisory_sync()
      :ok
    end

    test "first-ever event with no created timestamp writes the row", %{customer: customer} do
      # Seed a row with no last_stripe_event_ts (nil watermark — first-ever state).
      {:ok, _} =
        %EntitlementSummary{}
        |> EntitlementSummary.force_changeset(%{
          customer_id: customer.id,
          stripe_customer_id: customer.processor_id,
          entitlement_count: 0
          # deliberately absent: last_stripe_event_ts stays nil
        })
        |> Repo.insert()

      # Build a fixture event where the envelope `created` field is absent (nil evt_ts path).
      # Pass the event through with no `created` override so the fixture omits it.
      # Then strip the `created` key from the envelope via overrides.
      raw =
        StripeFixtures.entitlement_summary_event(
          [customer: customer.processor_id],
          %{"created" => nil}
        )

      # Deliver the nil-timestamp event.
      # Before ADV-02 fix: on_conflict_where `e.last_stripe_event_ts < EXCLUDED.last_stripe_event_ts`
      # compares NULL < NULL → NULL (falsy) → 0 rows updated → silent no-op / stale.
      # After fix: EXCLUDED.last_stripe_event_ts IS NULL → condition true → update proceeds.
      assert {:ok, %EntitlementSummary{}} = Accrue.Webhook.DefaultHandler.handle(raw)
    end
  end

  describe "ADV-03: DB-level stale skip emits result: :unchanged, no ledger event" do
    setup do
      enable_advisory_sync()
      :ok
    end

    test "second delivery of same-timestamp event returns {:ok, :stale} and emits :unchanged telemetry",
         %{customer: customer} do
      test_pid = self()
      ref = System.unique_integer([:positive])

      :telemetry.attach(
        "test-adv03-synced-#{ref}",
        [:accrue, :entitlements, :summary_synced],
        fn _evt, _meas, meta, _ -> send(test_pid, {:synced, meta}) end,
        nil
      )

      ts = DateTime.truncate(Accrue.Clock.utc_now(), :second)
      event_id = "evt_adv03_#{ref}"

      # First delivery — writes the row, watermarks it at `ts`.
      event =
        StripeFixtures.entitlement_summary_event(
          [customer: customer.processor_id],
          %{"id" => event_id, "created" => DateTime.to_unix(ts)}
        )

      assert {:ok, %EntitlementSummary{}} = Accrue.Webhook.DefaultHandler.handle(event)

      # Flush the first telemetry message.
      assert_received {:synced, _}

      events_before =
        Repo.aggregate(Accrue.Events.Event, :count)

      # Second delivery — same event_id, same timestamp.
      # check_stale passes (:eq timestamp is not stale), but the DB-level
      # on_conflict_where guard: existing.ts (T) NOT < EXCLUDED.ts (T) → false → 0 rows updated.
      # Before ADV-03 fix: Ecto.StaleEntryError propagates out of upsert_entitlement_summary/2.
      # After fix: rescue converts to {:ok, :stale}, write_entitlement_summary/9 returns {:ok, :stale}.
      assert {:ok, :stale} = Accrue.Webhook.DefaultHandler.handle(event)

      # result: :unchanged telemetry must be emitted.
      assert_received {:synced, %{result: :unchanged}}

      # No new ledger event should be written for the second delivery.
      assert Repo.aggregate(Accrue.Events.Event, :count) == events_before
    end
  end

  describe "POL-01: processor field reflects event processor, not global config" do
    setup do
      enable_advisory_sync()
      :ok
    end

    test "entitlement summary row has processor: 'stripe', not 'fake' (global config in BillingCase)",
         %{customer: customer} do
      # BillingCase wires the Fake processor; processor_name() returns "fake" in test env.
      # The Stripe webhook arrives with processor: :stripe on the Accrue.Webhook.Event.
      # The handle/1 path defaults to :stripe (the Stripe webhook path).
      # After POL-01 fix: the row's processor field must be "stripe" (from the event arg),
      # not "fake" (from processor_name() global config lookup).
      event =
        StripeFixtures.entitlement_summary_event(
          customer: customer.processor_id,
          entitlements: [%{"id" => "ent_pol01", "feature" => "feat_pol01", "lookup_key" => "pol01"}]
        )

      assert {:ok, %EntitlementSummary{} = saved} = Accrue.Webhook.DefaultHandler.handle(event)

      # Before POL-01 fix: processor_name() returns "fake" in BillingCase → row.processor == "fake".
      # After fix: to_string(processor) where processor = :stripe → row.processor == "stripe".
      assert saved.processor == "stripe"
    end
  end

  describe "POL-02: follow-up event with absent livemode key carries forward prior row livemode" do
    setup do
      enable_advisory_sync()
      :ok
    end

    test "second event missing livemode key preserves existing livemode: true", %{
      customer: customer
    } do
      ts_first = DateTime.truncate(Accrue.Clock.utc_now(), :second)

      # Seed a row with livemode: true and a known watermark.
      {:ok, _} =
        %EntitlementSummary{}
        |> EntitlementSummary.force_changeset(%{
          customer_id: customer.id,
          stripe_customer_id: customer.processor_id,
          livemode: true,
          entitlement_count: 1,
          last_stripe_event_ts: ts_first,
          last_stripe_event_id: "evt_pol02_first"
        })
        |> Repo.insert()

      # Build a second event with a newer timestamp.
      ts_second = DateTime.add(ts_first, 60, :second)

      raw =
        StripeFixtures.entitlement_summary_event(
          [customer: customer.processor_id],
          %{"id" => "evt_pol02_second", "created" => DateTime.to_unix(ts_second)}
        )

      # Strip the livemode key from the summary object so it is absent (not nil — absent).
      event_without_livemode = update_in(raw, ["data", "object"], &Map.delete(&1, "livemode"))

      # Before POL-02 fix: get(obj, :livemode) returns nil when key absent → livemode overwritten with nil.
      # After fix: nil incoming + non-nil row → carry forward row.livemode (true).
      assert {:ok, %EntitlementSummary{} = saved} =
               Accrue.Webhook.DefaultHandler.handle(event_without_livemode)

      assert saved.livemode == true
    end
  end

  # Remove a key from the summary `data.object` to model a malformed payload.
  defp pop_in_object(event, key) do
    update_in(event, ["data", "object"], &Map.delete(&1, key))
  end
end
