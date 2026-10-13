# Representative activity for the isolated Fake preview. This file is additive:
# it never rewrites event history, removes records, or changes login credentials.
alias AccrueHost.{Repo, OrdinarySeedBoundary}
alias Accrue.Billing.Customer
alias Accrue.Events.Event
alias Accrue.Webhook.WebhookEvent
import Ecto.Query

[database, role, address] =
  Repo.query!("SELECT current_database(), current_user, host(inet_server_addr())").rows |> hd()

expected_address =
  case :inet.getaddr(~c"db", :inet) do
    {:ok, value} -> value |> :inet.ntoa() |> List.to_string()
    _ -> nil
  end

unless OrdinarySeedBoundary.allowed?(Mix.env(), database, role, address, expected_address) and
         System.get_env("COMPOSE_PROJECT_NAME") == "accrue-host-phase245-ordinary" and
         System.get_env("ACCRUE_HOST_SKIP_SEEDS") == "1" and
         Application.fetch_env!(:accrue, :processor) == Accrue.Processor.Fake do
  raise "activity seed refused: not the isolated Fake ordinary preview"
end

Code.eval_file("helpers.exs", __DIR__)
organization = Repo.get_by!(AccrueHost.Accounts.Organization, slug: "healthy-co")
customer = Repo.get_by!(Customer, owner_type: "Organization", owner_id: organization.id)
operator = Repo.get_by!(AccrueHost.Accounts.User, email: "admin@example.com")

# A real local maintenance operation supplies honest admin attribution. Preserve
# existing metadata and guard by the immutable operation receipt on repeat runs.
operation_id = "ordinary-preview-contact-review-v1"

unless Repo.exists?(
         from(event in Event, where: fragment("?->>'operation_id'", event.data) == ^operation_id)
       ) do
  previous_operation = Accrue.Actor.current_operation_id()
  Accrue.Actor.put_operation_id(operation_id)

  try do
    Accrue.Actor.with_actor(%{type: :admin, id: operator.id}, fn ->
      {:ok, _customer} =
        Accrue.Billing.update_customer_local(customer, %{
          metadata: Map.put(customer.metadata || %{}, "contact_review", "Billing contact checked")
        })
    end)
  after
    Accrue.Actor.put_operation_id(previous_operation)
  end
end

# A successful customer-update webhook is a historical demo fixture. Its payload
# describes this same customer; it claims no payment, refund, or replay outcome.
provider_id = "evt_ordinary_customer_contact_updated"
received_at = DateTime.add(Accrue.Clock.utc_now(), -600, :second)

payload = %{
  "id" => provider_id,
  "object" => "event",
  "type" => "customer.updated",
  "livemode" => false,
  "created" => DateTime.to_unix(received_at),
  "data" => %{
    "object" => %{
      "id" => customer.processor_id,
      "object" => "customer",
      "name" => customer.name,
      "email" => customer.email
    }
  }
}

webhook =
  Repo.get_by(WebhookEvent, processor: "fake", processor_event_id: provider_id) ||
    %WebhookEvent{}
    |> Ecto.Changeset.change(%{
      processor: "fake",
      processor_event_id: provider_id,
      type: "customer.updated",
      livemode: false,
      status: :succeeded,
      endpoint: :default,
      received_at: received_at,
      processed_at: DateTime.add(received_at, 1, :second),
      raw_body: Jason.encode!(payload),
      data: payload
    })
    |> Repo.insert!()

AccrueHost.Seeds.Helpers.record_at(
  %{
    type: "webhook.received",
    subject_type: "WebhookEvent",
    subject_id: webhook.id,
    actor_type: "webhook",
    data: %{processor: "fake", event_id: provider_id, event_type: "customer.updated"}
  },
  "seed-ordinary-activity-webhook-received-v1",
  webhook.received_at
)
