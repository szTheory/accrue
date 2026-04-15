defmodule Mix.Tasks.Accrue.Webhooks.ReplayTest do
  use Accrue.RepoCase

  import ExUnit.CaptureIO

  alias Accrue.Webhook.WebhookEvent
  alias Mix.Tasks.Accrue.Webhooks.Replay

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
    :ok
  end

  test "single event id requeues that event" do
    row = insert_dead_event!()

    Replay.run([row.id])

    assert_received {:mix_shell, :info, [info]}
    assert info =~ "Requeued #{row.id}"

    updated = Accrue.TestRepo.get!(WebhookEvent, row.id)
    assert updated.status == :received
  end

  test "--dry-run --since --type reports without mutation" do
    _r1 = insert_dead_event!(type: "invoice.payment_failed")
    _r2 = insert_dead_event!(type: "invoice.payment_failed")

    Replay.run([
      "--since",
      "2020-01-01",
      "--type",
      "invoice.payment_failed",
      "--dry-run"
    ])

    assert_received {:mix_shell, :info, [info]}
    assert info =~ "would_requeue: 2"
    assert info =~ "requeued=0"

    # Nothing mutated
    remaining_dead =
      Accrue.TestRepo.aggregate(
        from(w in WebhookEvent, where: w.status == :dead),
        :count,
        :id
      )

    assert remaining_dead == 2
  end

  test "--all-dead --yes skips confirmation prompt" do
    for _ <- 1..15, do: insert_dead_event!(type: "charge.refunded")

    capture_io(fn ->
      Replay.run(["--all-dead", "--yes", "--type", "charge.refunded"])
    end)

    assert_received {:mix_shell, :info, [info]}
    assert info =~ "requeued=15"
  end

  # --- helpers ----------------------------------------------------------

  defp insert_dead_event!(opts \\ []) do
    type = Keyword.get(opts, :type, "customer.created")

    attrs = %{
      processor: "stripe",
      processor_event_id: "evt_test_#{System.unique_integer([:positive])}",
      type: type,
      livemode: false,
      raw_body: ~s({"test": true}),
      received_at: DateTime.utc_now()
    }

    {:ok, row} = attrs |> WebhookEvent.ingest_changeset() |> Accrue.TestRepo.insert()

    row
    |> WebhookEvent.status_changeset(:dead)
    |> Accrue.TestRepo.update!()
  end
end
