# Add representative saved methods to background customers in the named Fake
# preview. Preserve existing methods, exceptional personas, and event history.
alias AccrueHost.{Repo, OrdinarySeedBoundary}
alias Accrue.Billing.{Customer, PaymentMethod, Subscription}
alias Accrue.Events.Event
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
  raise "payment-method seed refused: not the isolated Fake ordinary preview"
end

customers =
  Repo.all(
    from(customer in Customer,
      join: subscription in Subscription,
      on: subscription.customer_id == customer.id,
      join: event in Event,
      on:
        event.subject_id == type(subscription.id, :string) and
          event.subject_type == "Subscription",
      where:
        customer.processor == "fake" and subscription.processor == "fake" and
          event.type == "subscription.created" and like(event.idempotency_key, "seed-bg-sub-%"),
      distinct: true,
      select: customer
    )
  )

Repo.transaction(fn ->
  for customer <- customers,
      customer.processor_id == "cus_" <> customer.id,
      is_nil(customer.default_payment_method_id),
      :erlang.phash2(customer.id, 10) < 8 do
    processor_id = "pm_ordinary_background_" <> customer.id

    # A manually added method is meaningful demo state; leave it alone.
    unless Repo.exists?(
             from(method in PaymentMethod,
               where: method.customer_id == ^customer.id and method.processor_id != ^processor_id
             )
           ) do
      method =
        Repo.get_by(PaymentMethod, processor: "fake", processor_id: processor_id) ||
          %PaymentMethod{}
          |> PaymentMethod.changeset(%{
            customer_id: customer.id,
            processor: "fake",
            processor_id: processor_id,
            type: "card",
            is_default: true,
            card_brand: if(:erlang.phash2(customer.id, 2) == 0, do: "visa", else: "mastercard"),
            card_last4: if(:erlang.phash2(customer.id, 2) == 0, do: "4242", else: "4444"),
            card_exp_month: 12,
            card_exp_year: 2032,
            exp_month: 12,
            exp_year: 2032,
            metadata: %{"seed_persona" => "ordinary_background"},
            data: %{"demo_fixture" => true}
          })
          |> Repo.insert!()

      if method.customer_id != customer.id,
        do: raise("payment-method seed refused: mismatched customer")

      customer
      |> Customer.changeset(%{default_payment_method_id: method.id})
      |> Repo.update!()
    end
  end
end)
