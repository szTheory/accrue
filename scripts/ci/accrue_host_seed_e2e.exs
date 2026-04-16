alias Accrue.Billing.Customer
alias Accrue.Billing.Subscription
alias Accrue.Billing.SubscriptionItem
alias Accrue.Events
alias Accrue.Webhook.WebhookEvent
alias AccrueHost.Accounts
alias AccrueHost.Accounts.User
alias AccrueHost.Repo

password = "hello world!"
fixture_path = System.fetch_env!("ACCRUE_HOST_E2E_FIXTURE")

create_user = fn email, admin? ->
  user =
    case Accounts.get_user_by_email(email) do
      %User{} = user ->
        user

      nil ->
        {:ok, user} = Accounts.register_user(%{email: email})
        user
    end

  user =
    if User.valid_password?(user, password) do
      user
    else
      {:ok, {user, _expired_tokens}} = Accounts.update_user_password(user, %{password: password})
      user
    end

  user
  |> User.confirm_changeset()
  |> Ecto.Changeset.change(billing_admin: admin?)
  |> Repo.update!()
end

normal_user = create_user.("host-user@example.test", false)
admin_user = create_user.("host-admin@example.test", true)
history_user = create_user.("billing-history@example.test", false)

customer =
  %Customer{}
  |> Customer.changeset(%{
    owner_type: "User",
    owner_id: history_user.id,
    processor: "fake",
    processor_id: "cus_host_browser_replay",
    email: history_user.email
  })
  |> Repo.insert!()

subscription =
  %Subscription{}
  |> Subscription.changeset(%{
    customer_id: customer.id,
    processor: "fake",
    processor_id: "sub_host_browser_replay",
    status: :active,
    data: %{
      "items" => %{
        "data" => [
          %{"price" => %{"id" => "price_basic"}}
        ]
      }
    }
  })
  |> Repo.insert!()
  |> Repo.preload(:subscription_items)

%SubscriptionItem{}
|> SubscriptionItem.changeset(%{
  subscription_id: subscription.id,
  processor: "fake",
  processor_id: "si_host_browser_replay",
  price_id: "price_basic",
  quantity: 1
})
|> Repo.insert!()

webhook =
  %{
    processor: "stripe",
    processor_event_id: "evt_host_browser_replay",
    type: "invoice.payment_failed",
    livemode: false,
    endpoint: :default,
    status: :received,
    raw_body:
      Jason.encode!(%{
        "id" => "evt_host_browser_replay",
        "type" => "invoice.payment_failed",
        "data" => %{
          "object" => %{
            "id" => "in_host_browser_replay",
            "object" => "invoice",
            "customer" => customer.processor_id,
            "subscription" => subscription.processor_id
          }
        }
      }),
    received_at: DateTime.utc_now(),
    data: %{
      "id" => "evt_host_browser_replay",
      "type" => "invoice.payment_failed",
      "data" => %{
        "object" => %{
          "id" => "in_host_browser_replay",
          "customer" => customer.processor_id,
          "subscription" => subscription.processor_id
        }
      }
    }
  }
  |> WebhookEvent.ingest_changeset()
  |> Repo.insert!()
  |> Ecto.Changeset.change(%{status: :dead})
  |> Repo.update!()

{:ok, _event} =
  Events.record(%{
    type: "invoice.payment_failed",
    subject_type: "Subscription",
    subject_id: subscription.id,
    actor_type: "webhook",
    actor_id: webhook.processor_event_id,
    caused_by_webhook_event_id: webhook.id
  })

Repo.insert!(%Oban.Job{
  state: "discarded",
  queue: "accrue_webhooks",
  worker: "Accrue.Webhook.DispatchWorker",
  args: %{"webhook_event_id" => webhook.id},
  errors: [%{"attempt" => 3, "error" => "processor timeout"}],
  attempt: 3,
  max_attempts: 25,
  inserted_at: ~U[2026-04-15 10:01:00.000000Z],
  attempted_at: ~U[2026-04-15 10:02:00.000000Z],
  discarded_at: ~U[2026-04-15 10:03:00.000000Z]
})

fixture = %{
  password: password,
  normal_email: normal_user.email,
  admin_email: admin_user.email,
  webhook_id: webhook.id,
  subscription_id: subscription.id
}

File.mkdir_p!(Path.dirname(fixture_path))
File.write!(fixture_path, Jason.encode!(fixture, pretty: true))
IO.puts("wrote #{fixture_path}")
