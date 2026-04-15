defmodule Accrue.Events.AdminCausalityTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Auth
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent

  test "default auth adapter auto-approves step-up in test" do
    assert %{kind: :auto} = Auth.step_up_challenge(%{id: "dev"}, %{type: "invoice.void"})
    assert :ok = Auth.verify_step_up(%{id: "dev"}, %{}, %{type: "invoice.void"})
  end

  test "record/1 persists admin and webhook causality link fields" do
    {:ok, source} =
      Events.record(%{
        type: "invoice.finalized",
        subject_type: "Invoice",
        subject_id: "in_123",
        actor_type: "system"
      })

    webhook =
      WebhookEvent.ingest_changeset(%{
        processor: "stripe",
        processor_event_id: "evt_admin_causality",
        type: "invoice.finalized",
        data: %{"id" => "evt_admin_causality"}
      })
      |> Accrue.TestRepo.insert!()

    assert {:ok, %Event{} = event} =
             Events.record(%{
               type: "admin.refund_requested",
               subject_type: "Refund",
               subject_id: "re_123",
               actor_type: "admin",
               actor_id: "admin_123",
               caused_by_event_id: source.id,
               caused_by_webhook_event_id: webhook.id,
               data: %{"source" => "admin"}
             })

    persisted = Accrue.TestRepo.get!(Event, event.id)
    assert persisted.caused_by_event_id == source.id
    assert persisted.caused_by_webhook_event_id == webhook.id
  end
end
