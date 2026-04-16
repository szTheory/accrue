defmodule Accrue.Webhook.ConnectHandlerTest do
  @moduledoc """
  Tests for `Accrue.Webhook.ConnectHandler` — the Plan 05-06 D5-05 reducer
  set dispatched from Connect-endpoint webhooks.

  Covers VALIDATION rows 8 and 9 plus the full reducer clause matrix:

    * `account.updated` happy path + out-of-order (no local row) seeding
    * `account.application.deauthorized` tombstones, never deletes
    * `account.application.deauthorized` ops telemetry
    * `capability.updated` jsonb merge + capability-lost telemetry
    * `payout.*` events-only writes + `payout.failed` ops telemetry
    * `person.*` passthrough no-op
    * Catch-all returns `:ok` for unknown Connect event types
    * End-to-end integration: DispatchWorker → ConnectHandler
  """

  use Accrue.ConnectCase, async: false

  alias Accrue.Connect
  alias Accrue.Connect.Account
  alias Accrue.Events.Event, as: LedgerEvent
  alias Accrue.Webhook.{ConnectHandler, DispatchWorker, WebhookEvent}
  alias Accrue.Webhook.Event, as: WebhookEventStruct

  import Ecto.Query

  # ---------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------

  defp insert_webhook_row!(type, object, opts \\ []) do
    endpoint = Keyword.get(opts, :endpoint, :connect)
    received_at = Keyword.get(opts, :received_at, DateTime.utc_now())

    attrs = %{
      processor: "stripe",
      processor_event_id: "evt_test_" <> Integer.to_string(System.unique_integer([:positive])),
      type: type,
      livemode: false,
      endpoint: endpoint,
      raw_body: "{}",
      received_at: received_at,
      data: %{
        "id" => "evt_test_raw",
        "type" => type,
        "data" => %{"object" => object}
      }
    }

    changeset = WebhookEvent.ingest_changeset(attrs)
    {:ok, row} = Accrue.TestRepo.insert(changeset)
    row
  end

  defp build_event(type, object_id, livemode \\ false) do
    %WebhookEventStruct{
      type: type,
      object_id: object_id,
      livemode: livemode,
      created_at: DateTime.utc_now(),
      processor_event_id: "evt_" <> Integer.to_string(System.unique_integer([:positive])),
      processor: :stripe
    }
  end

  defp seed_account_via_connect!(overrides \\ %{}) do
    params =
      Map.merge(
        %{
          type: "standard",
          country: "US",
          email: "owner@example.com"
        },
        overrides
      )

    {:ok, %Account{} = account} = Connect.create_account(params)
    account
  end

  defp attach_telemetry(event_name) do
    test_pid = self()
    handler_id = "ch-test-" <> Integer.to_string(System.unique_integer([:positive]))

    :telemetry.attach(
      handler_id,
      event_name,
      fn evt, measurements, metadata, _ ->
        send(test_pid, {:telemetry_event, evt, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    handler_id
  end

  # ---------------------------------------------------------------------
  # account.updated
  # ---------------------------------------------------------------------

  describe "handle_event/3 account.updated (VALIDATION row 8)" do
    test "updates charges_enabled/payouts_enabled/details_submitted via force_status_changeset" do
      account = seed_account_via_connect!()

      # Flip the Fake-side account state. `Connect.retrieve_account/2`
      # will read this back on refetch and the reducer will project it
      # into the local row.
      {:ok, _} =
        Connect.update_account(account.stripe_account_id, %{
          charges_enabled: true,
          payouts_enabled: true,
          details_submitted: true
        })

      # Reset the local row's flags to simulate stale state.
      Accrue.TestRepo.update_all(
        from(a in Account, where: a.stripe_account_id == ^account.stripe_account_id),
        set: [charges_enabled: false, payouts_enabled: false, details_submitted: false]
      )

      event = build_event("account.updated", account.stripe_account_id)
      row = insert_webhook_row!("account.updated", %{"id" => account.stripe_account_id})

      assert :ok =
               ConnectHandler.handle_event(event.type, event, %{webhook_event_id: row.id})

      updated = Accrue.TestRepo.get_by!(Account, stripe_account_id: account.stripe_account_id)
      assert updated.charges_enabled == true
      assert updated.payouts_enabled == true
      assert updated.details_submitted == true
      assert Account.fully_onboarded?(updated)
    end

    test "out-of-order delivery (no local row) seeds via Connect.retrieve_account/2 (VALIDATION row 9, Pitfall 3)" do
      # Create the account on the Fake processor, then delete the
      # local row — simulating Stripe delivering account.updated
      # before create_account/2 finished persisting locally.
      account = seed_account_via_connect!()
      {1, _} = Accrue.TestRepo.delete_all(from(a in Account, where: a.id == ^account.id))
      refute Accrue.TestRepo.get_by(Account, stripe_account_id: account.stripe_account_id)

      event = build_event("account.updated", account.stripe_account_id)
      row = insert_webhook_row!("account.updated", %{"id" => account.stripe_account_id})

      assert :ok =
               ConnectHandler.handle_event(event.type, event, %{webhook_event_id: row.id})

      # Local row is seeded from the refetch.
      seeded = Accrue.TestRepo.get_by!(Account, stripe_account_id: account.stripe_account_id)
      assert seeded.stripe_account_id == account.stripe_account_id
      assert seeded.type == "standard"
    end

    test "records connect.account.updated event in the ledger" do
      account = seed_account_via_connect!()

      event = build_event("account.updated", account.stripe_account_id)
      row = insert_webhook_row!("account.updated", %{"id" => account.stripe_account_id})

      assert :ok =
               ConnectHandler.handle_event(event.type, event, %{webhook_event_id: row.id})

      events =
        Accrue.TestRepo.all(
          from(e in LedgerEvent,
            where:
              e.type == "connect.account.updated" and
                e.subject_id == ^account.stripe_account_id
          )
        )

      assert length(events) >= 1
    end
  end

  # ---------------------------------------------------------------------
  # account.application.deauthorized
  # ---------------------------------------------------------------------

  describe "handle_event/3 account.application.deauthorized" do
    test "tombstones deauthorized_at and DOES NOT delete the row" do
      account = seed_account_via_connect!()

      event = build_event("account.application.deauthorized", account.stripe_account_id)

      row =
        insert_webhook_row!("account.application.deauthorized", %{
          "id" => account.stripe_account_id
        })

      assert :ok =
               ConnectHandler.handle_event(event.type, event, %{webhook_event_id: row.id})

      updated = Accrue.TestRepo.get_by!(Account, stripe_account_id: account.stripe_account_id)
      assert updated != nil, "row must not be hard-deleted"
      assert Account.deauthorized?(updated)
      assert %DateTime{} = updated.deauthorized_at
    end

    test "emits [:accrue, :ops, :connect_account_deauthorized] telemetry" do
      attach_telemetry([:accrue, :ops, :connect_account_deauthorized])

      account = seed_account_via_connect!()

      event = build_event("account.application.deauthorized", account.stripe_account_id)

      row =
        insert_webhook_row!("account.application.deauthorized", %{
          "id" => account.stripe_account_id
        })

      assert :ok =
               ConnectHandler.handle_event(event.type, event, %{webhook_event_id: row.id})

      assert_received {:telemetry_event, [:accrue, :ops, :connect_account_deauthorized],
                       %{count: 1}, metadata}

      assert metadata.stripe_account_id == account.stripe_account_id
      assert %DateTime{} = metadata.deauthorized_at
    end

    test "tombstones even when no local row existed (upsert via retrieve_account)" do
      # Create on Fake, wipe local row.
      account = seed_account_via_connect!()
      {1, _} = Accrue.TestRepo.delete_all(from(a in Account, where: a.id == ^account.id))

      event = build_event("account.application.deauthorized", account.stripe_account_id)

      row =
        insert_webhook_row!("account.application.deauthorized", %{
          "id" => account.stripe_account_id
        })

      assert :ok =
               ConnectHandler.handle_event(event.type, event, %{webhook_event_id: row.id})

      seeded = Accrue.TestRepo.get_by!(Account, stripe_account_id: account.stripe_account_id)
      assert Account.deauthorized?(seeded)
    end
  end

  # ---------------------------------------------------------------------
  # capability.updated
  # ---------------------------------------------------------------------

  describe "handle_event/3 capability.updated" do
    test "merges capability status into the capabilities jsonb column" do
      account = seed_account_via_connect!()

      payload = %{
        "id" => "card_payments",
        "object" => "capability",
        "account" => account.stripe_account_id,
        "status" => "active",
        "requested" => true
      }

      event = build_event("capability.updated", "card_payments")
      row = insert_webhook_row!("capability.updated", payload)

      assert :ok =
               ConnectHandler.handle_event(event.type, event, %{webhook_event_id: row.id})

      updated = Accrue.TestRepo.get_by!(Account, stripe_account_id: account.stripe_account_id)
      assert %{"card_payments" => %{"status" => "active"}} = updated.capabilities
    end

    test "emits [:accrue, :ops, :connect_capability_lost] when status transitions from active to inactive" do
      attach_telemetry([:accrue, :ops, :connect_capability_lost])

      account = seed_account_via_connect!()

      # First event: make card_payments active.
      active_payload = %{
        "id" => "card_payments",
        "object" => "capability",
        "account" => account.stripe_account_id,
        "status" => "active",
        "requested" => true
      }

      row1 = insert_webhook_row!("capability.updated", active_payload)

      assert :ok =
               ConnectHandler.handle_event(
                 "capability.updated",
                 build_event("capability.updated", "card_payments"),
                 %{webhook_event_id: row1.id}
               )

      # Second event: transition to inactive.
      inactive_payload = %{active_payload | "status" => "inactive"}
      row2 = insert_webhook_row!("capability.updated", inactive_payload)

      assert :ok =
               ConnectHandler.handle_event(
                 "capability.updated",
                 build_event("capability.updated", "card_payments"),
                 %{webhook_event_id: row2.id}
               )

      assert_received {:telemetry_event, [:accrue, :ops, :connect_capability_lost], %{count: 1},
                       metadata}

      assert metadata.capability == "card_payments"
      assert metadata.from == "active"
      assert metadata.to == "inactive"
    end
  end

  # ---------------------------------------------------------------------
  # payout.*
  # ---------------------------------------------------------------------

  describe "handle_event/3 payout reducers" do
    test "payout.created records an events row without mutating the account" do
      account = seed_account_via_connect!()

      payload = %{
        "id" => "po_test_created",
        "object" => "payout",
        "amount" => 2500,
        "currency" => "usd",
        "status" => "pending",
        "destination" => account.stripe_account_id
      }

      row = insert_webhook_row!("payout.created", payload)

      before_snapshot =
        Accrue.TestRepo.get_by!(Account, stripe_account_id: account.stripe_account_id)

      assert :ok =
               ConnectHandler.handle_event(
                 "payout.created",
                 build_event("payout.created", "po_test_created"),
                 %{webhook_event_id: row.id}
               )

      after_snapshot =
        Accrue.TestRepo.get_by!(Account, stripe_account_id: account.stripe_account_id)

      assert before_snapshot.updated_at == after_snapshot.updated_at

      events =
        Accrue.TestRepo.all(
          from(e in LedgerEvent,
            where:
              e.type == "connect.payout.created" and e.subject_id == ^account.stripe_account_id
          )
        )

      assert length(events) == 1
    end

    test "payout.failed emits [:accrue, :ops, :connect_payout_failed] telemetry" do
      attach_telemetry([:accrue, :ops, :connect_payout_failed])

      account = seed_account_via_connect!()

      payload = %{
        "id" => "po_test_failed",
        "object" => "payout",
        "amount" => 500,
        "currency" => "usd",
        "status" => "failed",
        "failure_code" => "account_closed",
        "destination" => account.stripe_account_id
      }

      row = insert_webhook_row!("payout.failed", payload)

      assert :ok =
               ConnectHandler.handle_event(
                 "payout.failed",
                 build_event("payout.failed", "po_test_failed"),
                 %{webhook_event_id: row.id}
               )

      assert_received {:telemetry_event, [:accrue, :ops, :connect_payout_failed], %{count: 1},
                       metadata}

      assert metadata.stripe_account_id == account.stripe_account_id
      assert metadata.payout_id == "po_test_failed"
      assert metadata.failure_code == "account_closed"
    end
  end

  # ---------------------------------------------------------------------
  # person.*
  # ---------------------------------------------------------------------

  describe "handle_event/3 person reducers (deferred passthrough)" do
    test "person.created no-ops (no DB mutation, no events row)" do
      event = build_event("person.created", "person_fake")

      before_count =
        Accrue.TestRepo.aggregate(
          from(e in LedgerEvent, where: like(e.type, "connect.person.%")),
          :count
        )

      assert :ok = ConnectHandler.handle_event(event.type, event, %{webhook_event_id: nil})

      after_count =
        Accrue.TestRepo.aggregate(
          from(e in LedgerEvent, where: like(e.type, "connect.person.%")),
          :count
        )

      assert before_count == after_count
    end

    test "person.updated no-ops" do
      event = build_event("person.updated", "person_fake")
      assert :ok = ConnectHandler.handle_event(event.type, event, %{webhook_event_id: nil})
    end
  end

  # ---------------------------------------------------------------------
  # Catch-all
  # ---------------------------------------------------------------------

  describe "handle_event/3 catch-all" do
    test "unknown Connect event type returns :ok without crashing" do
      event = build_event("account.external_account.created", "ba_test_fake")
      assert :ok = ConnectHandler.handle_event(event.type, event, %{webhook_event_id: nil})
    end
  end

  # ---------------------------------------------------------------------
  # End-to-end DispatchWorker integration (Plan 01 + Plan 06 chain)
  # ---------------------------------------------------------------------

  describe "integration — DispatchWorker routes Connect endpoint events" do
    test "account.updated row with endpoint :connect dispatches to ConnectHandler and updates local row" do
      account = seed_account_via_connect!()

      {:ok, _} =
        Connect.update_account(account.stripe_account_id, %{
          charges_enabled: true,
          payouts_enabled: true,
          details_submitted: true
        })

      # Reset local flags to force the reducer to do real work.
      Accrue.TestRepo.update_all(
        from(a in Account, where: a.stripe_account_id == ^account.stripe_account_id),
        set: [charges_enabled: false, payouts_enabled: false, details_submitted: false]
      )

      row = insert_webhook_row!("account.updated", %{"id" => account.stripe_account_id})

      job = %Oban.Job{
        args: %{"webhook_event_id" => row.id},
        attempt: 1,
        max_attempts: 25
      }

      assert :ok = DispatchWorker.perform(job)

      updated = Accrue.TestRepo.get_by!(Account, stripe_account_id: account.stripe_account_id)
      assert Account.fully_onboarded?(updated)

      refreshed = Accrue.TestRepo.get!(WebhookEvent, row.id)
      assert refreshed.status == :succeeded
    end
  end
end
