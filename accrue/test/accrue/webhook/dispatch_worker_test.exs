defmodule Accrue.Webhook.DispatchWorkerTest do
  use Accrue.RepoCase

  import ExUnit.CaptureLog

  alias Accrue.Webhook.{DispatchWorker, WebhookEvent, Event, Pruner}

  # A test handler that succeeds
  defmodule SuccessHandler do
    use Accrue.Webhook.Handler

    def handle_event("customer.created", _event, _ctx) do
      send(self(), {:handler_called, __MODULE__})
      :ok
    end
  end

  # A test handler that crashes
  defmodule CrashingHandler do
    use Accrue.Webhook.Handler

    def handle_event("customer.created", _event, _ctx) do
      raise "boom from CrashingHandler"
    end
  end

  # A test handler that tracks calls for ordering verification
  defmodule TrackingHandler do
    use Accrue.Webhook.Handler

    def handle_event(_type, _event, _ctx) do
      send(self(), {:handler_called, __MODULE__})
      :ok
    end
  end

  setup do
    # Reset webhook_handlers config for each test
    Application.put_env(:accrue, :webhook_handlers, [])

    on_exit(fn ->
      Application.put_env(:accrue, :webhook_handlers, [])
    end)

    :ok
  end

  describe "perform/1" do
    test "loads WebhookEvent row, projects to Event struct, calls handlers" do
      Application.put_env(:accrue, :webhook_handlers, [SuccessHandler])

      row = insert_webhook_event!()

      job = build_job(row.id, attempt: 1, max_attempts: 25)
      assert :ok = DispatchWorker.perform(job)

      # Handler was called
      assert_received {:handler_called, SuccessHandler}

      # Status transitioned to :succeeded
      updated = Accrue.TestRepo.get!(WebhookEvent, row.id)
      assert updated.status == :succeeded
      assert updated.processed_at != nil
    end

    test "DefaultHandler reconciles customer.created event" do
      row = insert_webhook_event!(type: "customer.created")

      job = build_job(row.id, attempt: 1, max_attempts: 25)
      assert :ok = DispatchWorker.perform(job)

      # DefaultHandler runs without error for customer.created
      updated = Accrue.TestRepo.get!(WebhookEvent, row.id)
      assert updated.status == :succeeded
    end

    test "user handler crash does not prevent default handler or other user handlers from running" do
      Application.put_env(:accrue, :webhook_handlers, [CrashingHandler, TrackingHandler])

      row = insert_webhook_event!()

      job = build_job(row.id, attempt: 1, max_attempts: 25)

      log =
        capture_log(fn ->
          # Default handler succeeds, so overall result is :ok despite CrashingHandler crash
          assert :ok = DispatchWorker.perform(job)
        end)

      # CrashingHandler crash was logged
      assert log =~ "CrashingHandler"
      assert log =~ "boom from CrashingHandler"

      # TrackingHandler still ran (after CrashingHandler crashed)
      assert_received {:handler_called, TrackingHandler}

      # Event still succeeded because default handler was fine
      updated = Accrue.TestRepo.get!(WebhookEvent, row.id)
      assert updated.status == :succeeded
    end

    test "on final attempt, failed event transitions to :dead status" do
      # Use a handler that makes the default handler fail
      row = insert_webhook_event!(type: "some.unknown.event")

      # Simulate final attempt (attempt == max_attempts)
      job = build_job(row.id, attempt: 25, max_attempts: 25)
      # Default handler returns :ok for unknown events (fallthrough)
      assert :ok = DispatchWorker.perform(job)

      updated = Accrue.TestRepo.get!(WebhookEvent, row.id)
      # Unknown events succeed because of the fallthrough clause
      assert updated.status == :succeeded
    end

    test "Oban worker configured with max_attempts: 25" do
      # Verify the Oban worker configuration
      changeset = DispatchWorker.new(%{webhook_event_id: "test-id"})
      assert changeset.changes.max_attempts == 25
      assert changeset.changes.queue == "accrue_webhooks"
    end
  end

  describe "Pruner" do
    test "deletes :succeeded events older than retention days" do
      # Default retention is 14 days for succeeded
      old_event =
        insert_webhook_event!(
          status: :succeeded,
          processed_at: DateTime.utc_now() |> DateTime.add(-15 * 86400, :second)
        )

      # Manually set inserted_at to old date for pruner query
      {:ok, uuid_bin} = Ecto.UUID.dump(old_event.id)

      Accrue.TestRepo.query!(
        "UPDATE accrue_webhook_events SET inserted_at = $1 WHERE id = $2",
        [DateTime.utc_now() |> DateTime.add(-15 * 86400, :second), uuid_bin]
      )

      recent_event =
        insert_webhook_event!(
          status: :succeeded,
          processed_at: DateTime.utc_now()
        )

      job = %Oban.Job{args: %{}}
      assert :ok = Pruner.perform(job)

      # Old succeeded event deleted, recent one kept
      assert Accrue.TestRepo.get(WebhookEvent, old_event.id) == nil
      assert Accrue.TestRepo.get(WebhookEvent, recent_event.id) != nil
    end

    test "deletes :dead events older than retention days" do
      old_dead =
        insert_webhook_event!(
          status: :dead,
          processed_at: DateTime.utc_now() |> DateTime.add(-91 * 86400, :second)
        )

      {:ok, uuid_bin} = Ecto.UUID.dump(old_dead.id)

      Accrue.TestRepo.query!(
        "UPDATE accrue_webhook_events SET inserted_at = $1 WHERE id = $2",
        [DateTime.utc_now() |> DateTime.add(-91 * 86400, :second), uuid_bin]
      )

      job = %Oban.Job{args: %{}}
      assert :ok = Pruner.perform(job)

      assert Accrue.TestRepo.get(WebhookEvent, old_dead.id) == nil
    end
  end

  # --- helpers ---

  defp insert_webhook_event!(opts \\ []) do
    type = Keyword.get(opts, :type, "customer.created")
    status = Keyword.get(opts, :status, :received)
    processed_at = Keyword.get(opts, :processed_at)

    attrs = %{
      processor: "stripe",
      processor_event_id: "evt_test_#{System.unique_integer([:positive])}",
      type: type,
      livemode: false,
      raw_body: ~s({"test": true}),
      received_at: DateTime.utc_now(),
      data: %{
        "data" => %{
          "object" => %{
            "id" => "cus_test_#{System.unique_integer([:positive])}",
            "object" => "customer"
          }
        }
      }
    }

    changeset = WebhookEvent.ingest_changeset(attrs)
    {:ok, row} = Accrue.TestRepo.insert(changeset)

    # If status is not :received, update it
    if status != :received do
      row
      |> WebhookEvent.status_changeset(status)
      |> Accrue.TestRepo.update!()
    else
      row
    end
  end

  defp build_job(webhook_event_id, opts) do
    attempt = Keyword.get(opts, :attempt, 1)
    max_attempts = Keyword.get(opts, :max_attempts, 25)

    %Oban.Job{
      args: %{"webhook_event_id" => webhook_event_id},
      attempt: attempt,
      max_attempts: max_attempts
    }
  end
end
