defmodule Accrue.Webhook.IngestTest do
  use Accrue.RepoCase

  alias Accrue.Webhook.{Ingest, WebhookEvent}

  import Accrue.WebhookFixtures

  @processor :stripe

  setup do
    # Ensure Oban testing mode is active for job assertions
    :ok
  end

  describe "run/4" do
    test "persists event-owned webhook, dispatch job, and received ledger facts" do
      {other_body, _sig} = signed_event()
      other_event = build_lattice_event(other_body)
      other_conn = Plug.Test.conn(:post, "/webhook/stripe")
      assert %{status: 200} = Ingest.run(other_conn, @processor, other_event, other_body)

      {body, _sig} = signed_event()
      stripe_event = build_lattice_event(body)

      conn = Plug.Test.conn(:post, "/webhook/stripe")
      result_conn = Ingest.run(conn, @processor, stripe_event, body)

      assert result_conn.status == 200
      assert result_conn.halted

      event = webhook_event!(stripe_event)
      assert event.processor == "stripe"
      assert event.processor_event_id == stripe_event.id
      assert event.type == stripe_event.type
      assert event.status == :received

      assert [job] = dispatch_jobs_for(event.id)
      assert job.worker == "Accrue.Webhook.DispatchWorker"
      assert job.args["webhook_event_id"] == event.id

      assert [ledger_event] = received_ledger_events_for(event.id)
      assert ledger_event.data["event_type"] == stripe_event.type
    end

    test "duplicate POST returns 200 with one event-owned webhook, job, and ledger fact" do
      {body, _sig} = signed_event()
      stripe_event = build_lattice_event(body)

      conn1 = Plug.Test.conn(:post, "/webhook/stripe")
      result1 = Ingest.run(conn1, @processor, stripe_event, body)
      assert result1.status == 200
      first_event_id = webhook_event!(stripe_event).id

      # Second call with same event
      conn2 = Plug.Test.conn(:post, "/webhook/stripe")
      result2 = Ingest.run(conn2, @processor, stripe_event, body)
      assert result2.status == 200

      assert [event] = webhook_events_for(stripe_event)
      assert event.id == first_event_id
      assert [_job] = dispatch_jobs_for(first_event_id)
      assert [_ledger_event] = received_ledger_events_for(first_event_id)
    end

    test "records an event-owned webhook.received ledger row" do
      {body, _sig} = signed_event()
      stripe_event = build_lattice_event(body)

      conn = Plug.Test.conn(:post, "/webhook/stripe")
      Ingest.run(conn, @processor, stripe_event, body)

      event = webhook_event!(stripe_event)
      assert [ledger_event] = received_ledger_events_for(event.id)
      assert ledger_event.type == "webhook.received"
      assert ledger_event.subject_type == "WebhookEvent"
      assert ledger_event.subject_id == to_string(event.id)
      assert ledger_event.data["event_type"] == stripe_event.type
    end

    test "successful ingest keeps event-owned webhook, dispatch job, and ledger facts together" do
      {body, _sig} = signed_event()
      stripe_event = build_lattice_event(body)

      conn = Plug.Test.conn(:post, "/webhook/stripe")
      Ingest.run(conn, @processor, stripe_event, body)

      event = webhook_event!(stripe_event)
      assert [_job] = dispatch_jobs_for(event.id)
      assert [_ledger_event] = received_ledger_events_for(event.id)
    end

    test "request completes in reasonable time" do
      {body, _sig} = signed_event()
      stripe_event = build_lattice_event(body)

      conn = Plug.Test.conn(:post, "/webhook/stripe")

      {elapsed_us, result_conn} =
        :timer.tc(fn -> Ingest.run(conn, @processor, stripe_event, body) end)

      assert result_conn.status == 200
      # Allow generous margin for CI: 500ms (target is <100ms in prod)
      assert elapsed_us < 500_000, "Ingest took #{elapsed_us / 1000}ms, expected <500ms"
    end
  end

  # --- helpers ---

  defp build_lattice_event(body) do
    body
    |> Jason.decode!()
    |> LatticeStripe.Event.from_map()
  end

  defp webhook_event!(stripe_event) do
    Accrue.TestRepo.get_by!(WebhookEvent,
      processor: "stripe",
      processor_event_id: stripe_event.id
    )
  end

  defp webhook_events_for(stripe_event) do
    Accrue.TestRepo.all(
      from(event in WebhookEvent,
        where: event.processor == "stripe" and event.processor_event_id == ^stripe_event.id
      )
    )
  end

  defp dispatch_jobs_for(event_id) do
    Accrue.TestRepo.all(
      from(job in Oban.Job,
        where: job.worker == "Accrue.Webhook.DispatchWorker",
        where: fragment("? ->> 'webhook_event_id' = ?", job.args, ^event_id)
      )
    )
  end

  defp received_ledger_events_for(event_id) do
    Accrue.TestRepo.all(
      from(event in Accrue.Events.Event,
        where:
          event.type == "webhook.received" and event.subject_type == "WebhookEvent" and
            event.subject_id == ^to_string(event_id)
      )
    )
  end
end
