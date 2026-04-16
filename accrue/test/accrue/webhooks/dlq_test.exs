defmodule Accrue.Webhooks.DLQTest do
  use Accrue.RepoCase

  alias Accrue.Webhook.WebhookEvent
  alias Accrue.Webhooks.DLQ

  describe "requeue/1" do
    test "for a :dead webhook event inserts a fresh dispatch job and resets status to :received" do
      row = insert_event!(status: :dead)

      events =
        capture_telemetry([:accrue, :ops, :webhook_dlq, :replay], fn ->
          assert {:ok, updated} = DLQ.requeue(row.id)
          assert updated.id == row.id
          assert updated.status == :received
        end)

      assert length(events) >= 1

      # Ledger row recorded
      ledger =
        Accrue.TestRepo.all(
          from(e in Accrue.Events.Event,
            where: e.type == "webhook.replay_requested" and e.subject_id == ^row.id
          )
        )

      assert length(ledger) == 1
    end

    test "for a :replayed event returns {:error, :already_replayed}" do
      row = insert_event!(status: :replayed)
      assert {:error, :already_replayed} = DLQ.requeue(row.id)
    end

    test "for a :succeeded event returns {:error, :not_dead_lettered}" do
      row = insert_event!(status: :succeeded)
      assert {:error, :not_dead_lettered} = DLQ.requeue(row.id)
    end

    test "for an unknown UUID returns {:error, :not_found}" do
      assert {:error, :not_found} =
               DLQ.requeue("00000000-0000-0000-0000-000000000000")
    end

    test "also accepts :failed status" do
      row = insert_event!(status: :failed)
      assert {:ok, updated} = DLQ.requeue(row.id)
      assert updated.status == :received
    end
  end

  describe "requeue_where/2" do
    test "with dry_run: true returns count without mutation" do
      _r1 = insert_event!(status: :dead, type: "invoice.payment_failed")
      _r2 = insert_event!(status: :dead, type: "invoice.payment_failed")
      _r3 = insert_event!(status: :dead, type: "charge.succeeded")

      assert {:ok, %{requeued: 0, would_requeue: 2, skipped: 0}} =
               DLQ.requeue_where([type: "invoice.payment_failed"], dry_run: true)

      # Nothing mutated
      assert Accrue.TestRepo.aggregate(
               from(w in WebhookEvent, where: w.status == :dead),
               :count,
               :id
             ) == 3
    end

    test "processes matching dead rows in batches" do
      for _ <- 1..3, do: insert_event!(status: :dead, type: "invoice.payment_failed")

      assert {:ok, %{requeued: 3}} =
               DLQ.requeue_where([type: "invoice.payment_failed"], batch_size: 2, stagger_ms: 0)

      remaining_dead =
        Accrue.TestRepo.aggregate(
          from(w in WebhookEvent,
            where: w.status == :dead and w.type == "invoice.payment_failed"
          ),
          :count,
          :id
        )

      assert remaining_dead == 0
    end

    test "rejects requests above dlq_replay_max_rows unless force: true" do
      Application.put_env(:accrue, :dlq_replay_max_rows, 2)
      on_exit(fn -> Application.delete_env(:accrue, :dlq_replay_max_rows) end)

      for _ <- 1..3, do: insert_event!(status: :dead, type: "charge.refunded")

      assert {:error, :replay_too_large} =
               DLQ.requeue_where([type: "charge.refunded"], stagger_ms: 0)

      assert {:ok, %{requeued: 3}} =
               DLQ.requeue_where([type: "charge.refunded"], force: true, stagger_ms: 0)
    end
  end

  describe "list/2 + count/1" do
    test "list returns matching events with limit" do
      for _ <- 1..5, do: insert_event!(status: :dead, type: "invoice.paid")

      results = DLQ.list([type: "invoice.paid"], limit: 3)
      assert length(results) == 3
      assert Enum.all?(results, &(&1.type == "invoice.paid"))
    end

    test "count returns accurate count" do
      for _ <- 1..4, do: insert_event!(status: :dead, type: "invoice.paid")
      _ = insert_event!(status: :succeeded, type: "invoice.paid")

      assert DLQ.count(type: "invoice.paid") == 5
    end
  end

  describe "prune/1 and prune_succeeded/1" do
    test "prune deletes :dead rows older than N days" do
      old =
        insert_event!(
          status: :dead,
          inserted_at: DateTime.add(DateTime.utc_now(), -100 * 86_400, :second)
        )

      _young = insert_event!(status: :dead)

      assert {:ok, 1} = DLQ.prune(90)
      assert Accrue.TestRepo.get(WebhookEvent, old.id) == nil
    end

    test "prune(:infinity) is a no-op" do
      _ = insert_event!(status: :dead)
      assert {:ok, 0} = DLQ.prune(:infinity)
    end

    test "prune_succeeded deletes :succeeded rows older than N days" do
      old =
        insert_event!(
          status: :succeeded,
          inserted_at: DateTime.add(DateTime.utc_now(), -30 * 86_400, :second)
        )

      assert {:ok, 1} = DLQ.prune_succeeded(14)
      assert Accrue.TestRepo.get(WebhookEvent, old.id) == nil
    end
  end

  # --- helpers ----------------------------------------------------------

  defp insert_event!(opts) do
    type = Keyword.get(opts, :type, "customer.created")
    status = Keyword.get(opts, :status, :received)
    inserted_at = Keyword.get(opts, :inserted_at)

    attrs = %{
      processor: "stripe",
      processor_event_id: "evt_test_#{System.unique_integer([:positive])}",
      type: type,
      livemode: false,
      raw_body: ~s({"test": true}),
      received_at: DateTime.utc_now()
    }

    {:ok, row} =
      attrs |> WebhookEvent.ingest_changeset() |> Accrue.TestRepo.insert()

    row =
      if status != :received do
        row
        |> WebhookEvent.status_changeset(status)
        |> Accrue.TestRepo.update!()
      else
        row
      end

    if inserted_at do
      from(w in WebhookEvent, where: w.id == ^row.id)
      |> Accrue.TestRepo.update_all(set: [inserted_at: inserted_at])

      Accrue.TestRepo.get!(WebhookEvent, row.id)
    else
      row
    end
  end

  defp capture_telemetry(event_name, fun) do
    test_pid = self()
    handler_id = "test-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      event_name,
      fn name, measurements, metadata, _ ->
        send(test_pid, {:telemetry, name, measurements, metadata})
      end,
      nil
    )

    try do
      fun.()
    after
      :telemetry.detach(handler_id)
    end

    drain_telemetry([])
  end

  defp drain_telemetry(acc) do
    receive do
      {:telemetry, _, _, _} = msg -> drain_telemetry([msg | acc])
    after
      0 -> acc
    end
  end
end
