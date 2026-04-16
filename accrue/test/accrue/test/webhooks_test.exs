defmodule Accrue.Test.WebhooksTest do
  use Accrue.RepoCase, async: false

  import Ecto.Query

  alias Accrue.Webhook.WebhookEvent

  setup do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()
    :ok
  end

  test "trigger_event/2 routes invoice_payment_failed through ingest and DefaultHandler normal path" do
    assert WebhookEvent.__schema__(:source) == "accrue_webhook_events"
    assert Code.ensure_loaded?(Accrue.Webhook.Ingest)

    invoice = %{
      id: "in_fake_00001",
      customer: "cus_fake_00001",
      subscription: "sub_fake_00001",
      amount_due: 2_000,
      currency: "usd"
    }

    assert {:ok, %WebhookEvent{} = row} =
             Accrue.Test.Webhooks.trigger_event(:invoice_payment_failed, invoice)

    assert row.type == "invoice.payment_failed"

    assert Accrue.TestRepo.exists?(
             from(w in WebhookEvent,
               where:
                 w.id == ^row.id and w.type == "invoice.payment_failed" and
                   w.status in [:received, :succeeded]
             )
           )

    assert row.data["handler"] == "Accrue.Webhook.DefaultHandler" or
             row.data[:handler] == Accrue.Webhook.DefaultHandler
  end

  test "trigger_event/2 does not bypass normal webhook handler path with direct row mutation" do
    invoice = %{id: "in_fake_00002", customer: "cus_fake_00001"}

    assert {:ok, row} = Accrue.Test.Webhooks.trigger_event(:invoice_payment_failed, invoice)

    assert row.processor_event_id =~ "evt_"
    assert row.raw_body
    assert row.data["normal_path"] == true or row.data[:normal_path] == true
    refute row.data["not bypass"] == false
  end

  test "inspect redacts raw webhook bodies" do
    event = %WebhookEvent{raw_body: ~s({"secret":true})}

    output = inspect(event)

    refute output =~ "raw_body"
    refute output =~ "secret"
  end
end
