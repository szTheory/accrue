alias Accrue.Billing.Customer
alias Accrue.Billing.Subscription
alias Accrue.Billing.SubscriptionItem
alias Accrue.Events
alias Accrue.Events.Event
alias Accrue.Webhook.WebhookEvent
alias AccrueHost.Accounts
alias AccrueHost.Accounts.User
alias AccrueHost.Repo

import Ecto.Query

password = "hello world!"
fixture_path = System.fetch_env!("ACCRUE_HOST_E2E_FIXTURE")
webhook_secret = "whsec_test_host"
seeded_emails = ["host-user@example.test", "host-admin@example.test", "billing-history@example.test"]

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

previous_owner_ids =
  Repo.all(
    from(user in User,
      where: user.email in ^seeded_emails,
      select: user.id
    )
  )

cleanup_customer_ids =
  Repo.all(
    from(customer in Customer,
      where: customer.owner_type == "User" and customer.owner_id in ^previous_owner_ids,
      select: customer.id
    )
  )

Repo.delete_all(
  from(job in Oban.Job,
    where:
      job.worker == "Accrue.Webhook.DispatchWorker" and
        job.queue == "accrue_webhooks"
  )
)

Repo.query!("ALTER TABLE accrue_events DISABLE TRIGGER accrue_events_immutable_trigger")

try do
  Repo.delete_all(
    from(event in Event,
      where:
        event.type in ["invoice.payment_failed", "admin.webhook.replay.completed"] and
          event.subject_type in ["Subscription", "WebhookEvent"]
    )
  )
after
  Repo.query!("ALTER TABLE accrue_events ENABLE TRIGGER accrue_events_immutable_trigger")
end

Repo.delete_all(
  from(webhook in WebhookEvent,
    where: webhook.processor_event_id in ["evt_host_browser_replay", "evt_host_browser_first_run"]
  )
)

Repo.delete_all(
  from(item in SubscriptionItem,
    where:
      item.processor_id == "si_host_browser_replay" or
        item.subscription_id in subquery(
          from(subscription in Subscription,
            where: subscription.customer_id in ^cleanup_customer_ids,
            select: subscription.id
          )
        )
  )
)

Repo.delete_all(
  from(subscription in Subscription,
    where:
      subscription.processor_id == "sub_host_browser_replay" or
        subscription.customer_id in ^cleanup_customer_ids
  )
)

Repo.delete_all(
  from(customer in Customer,
    where:
      customer.processor_id == "cus_host_browser_replay" or
        customer.id in ^cleanup_customer_ids
  )
)

Repo.delete_all(
  from(user in User,
    where: user.email in ^seeded_emails
  )
)

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

first_run_webhook_payload =
  Jason.encode!(%{
    "id" => "evt_host_browser_first_run",
    "object" => "event",
    "type" => "customer.subscription.created",
    "created" => 1_712_880_000,
    "livemode" => false,
    "data" => %{
      "object" => %{
        "id" => subscription.processor_id,
        "object" => "subscription"
      }
    }
  })

first_run_webhook_signature =
  LatticeStripe.Webhook.generate_test_signature(first_run_webhook_payload, webhook_secret)

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
  subscription_id: subscription.id,
  first_run_webhook: %{
    processor_event_id: "evt_host_browser_first_run",
    payload: first_run_webhook_payload,
    signature: first_run_webhook_signature
  }
}

File.mkdir_p!(Path.dirname(fixture_path))
File.write!(fixture_path, Jason.encode!(fixture, pretty: true))
IO.puts("wrote #{fixture_path}")
