defmodule AccrueHostSeedE2E do
  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Billing.SubscriptionItem
  alias Accrue.Connect.Account
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueHost.Accounts
  alias AccrueHost.Accounts.Scope
  alias AccrueHost.Accounts.User
  alias AccrueHost.Accounts.UserToken
  alias AccrueHost.Organizations
  alias AccrueHost.Repo

  import Ecto.Query

  @password "hello world!"
  @webhook_secret "whsec_test_host"
  @seeded_emails ["host-user@example.test", "host-admin@example.test", "billing-history@example.test"]
  @fixture_org_customer_emails ["admin-e2e-alpha-customer@example.test"]
  @fixture_processor_event_ids ["evt_host_browser_replay", "evt_host_browser_first_run"]
  @fixture_customer_processor_ids ["cus_host_browser_replay"]
  @fixture_subscription_processor_ids ["sub_host_browser_replay"]
  @fixture_subscription_item_processor_ids ["si_host_browser_replay"]

  def run!(fixture_path \\ System.fetch_env!("ACCRUE_HOST_E2E_FIXTURE")) do
    cleanup_fixture_footprint!()

    normal_user = create_user!("host-user@example.test", false)
    admin_user = create_user!("host-admin@example.test", true)
    history_user = create_user!("billing-history@example.test", false)

    {:ok, host_org_alpha} =
      Organizations.create_organization(Scope.for_user(normal_user), %{
        name: "Host E2E Alpha Org",
        slug: "host-e2e-alpha"
      })

    {:ok, host_org_beta} =
      Organizations.create_organization(Scope.for_user(normal_user), %{
        name: "Host E2E Beta Org",
        slug: "host-e2e-beta"
      })

    {:ok, admin_org_alpha} =
      Organizations.create_organization(Scope.for_user(admin_user), %{
        name: "Admin E2E Alpha Org",
        slug: "accrue-e2e-alpha"
      })

    {:ok, admin_org_beta} =
      Organizations.create_organization(Scope.for_user(admin_user), %{
        name: "Admin E2E Beta Org",
        slug: "accrue-e2e-beta"
      })

    admin_denial_customer = insert_org_customer!(admin_org_alpha)
    connect_account = insert_fixture_connect_account!(admin_org_alpha)

    customer = insert_fixture_customer!(history_user)
    subscription = insert_fixture_subscription!(customer)
    insert_fixture_subscription_item!(subscription)
    webhook = insert_fixture_webhook!(customer, subscription)

    first_run_webhook = build_first_run_webhook(subscription)

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
      password: @password,
      normal_email: normal_user.email,
      admin_email: admin_user.email,
      webhook_id: webhook.id,
      subscription_id: subscription.id,
      first_run_webhook: first_run_webhook,
      org_alpha_slug: host_org_alpha.slug,
      org_beta_slug: host_org_beta.slug,
      org_alpha_name: host_org_alpha.name,
      org_beta_name: host_org_beta.name,
      tax_invalid_customer_hint: "tax_invalid_e2e_hint",
      admin_org_alpha_slug: admin_org_alpha.slug,
      admin_org_beta_slug: admin_org_beta.slug,
      admin_denial_customer_id: admin_denial_customer.id,
      connect_account_id: connect_account.id
    }

    write_fixture!(fixture_path, fixture)
    fixture
  end

  defp cleanup_fixture_footprint! do
    # Playwright / host browser runs persist Organization-billed Fake subscriptions as
    # `sub_fake_%` rows. They are outside the fixture `processor_id` contract; if left
    # behind, the next run's Fake id allocation can collide with PG and crash LiveView
    # (unique index on processor + processor_id).
    fake_browser_subscription_ids =
      Repo.all(
        from(s in Subscription,
          where: s.processor == "fake" and fragment("? LIKE 'sub_fake%'", s.processor_id),
          select: s.id
        )
      )

    unless fake_browser_subscription_ids == [] do
      Repo.query!("ALTER TABLE accrue_events DISABLE TRIGGER accrue_events_immutable_trigger")

      try do
        Repo.delete_all(
          from(event in Event,
            where: event.subject_type == "Subscription" and event.subject_id in ^fake_browser_subscription_ids
          )
        )
      after
        Repo.query!("ALTER TABLE accrue_events ENABLE TRIGGER accrue_events_immutable_trigger")
      end

      Repo.delete_all(
        from(item in SubscriptionItem,
          join: sub in Subscription,
          on: sub.id == item.subscription_id,
          where: sub.id in ^fake_browser_subscription_ids
        )
      )

      Repo.delete_all(from(sub in Subscription, where: sub.id in ^fake_browser_subscription_ids))
    end

    previous_owner_ids =
      Repo.all(
        from(user in User,
          where: user.email in ^@seeded_emails,
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

    fixture_subscription_ids =
      Repo.all(
        from(subscription in Subscription,
          where:
            subscription.processor_id in ^@fixture_subscription_processor_ids or
              subscription.customer_id in ^cleanup_customer_ids,
          select: subscription.id
        )
      )

    fixture_webhook_ids =
      Repo.all(
        from(webhook in WebhookEvent,
          where: webhook.processor_event_id in ^@fixture_processor_event_ids,
          select: webhook.id
        )
      )

    fixture_webhook_id_strings = Enum.map(fixture_webhook_ids, &to_string/1)

    Repo.delete_all(
      from(job in Oban.Job,
        where:
          job.worker == "Accrue.Webhook.DispatchWorker" and
            job.queue == "accrue_webhooks" and
            fragment("?->>'webhook_event_id'", job.args) in ^fixture_webhook_id_strings
      )
    )

    Repo.query!("ALTER TABLE accrue_events DISABLE TRIGGER accrue_events_immutable_trigger")

    try do
      Repo.delete_all(
        from(event in Event,
          where:
            event.actor_id in ^@fixture_processor_event_ids or
              event.caused_by_webhook_event_id in ^fixture_webhook_ids or
              (event.subject_type == "Subscription" and event.subject_id in ^fixture_subscription_ids)
        )
      )
    after
      Repo.query!("ALTER TABLE accrue_events ENABLE TRIGGER accrue_events_immutable_trigger")
    end

    Repo.delete_all(
      from(webhook in WebhookEvent,
        where: webhook.processor_event_id in ^@fixture_processor_event_ids
      )
    )

    Repo.delete_all(
      from(item in SubscriptionItem,
        where:
          item.processor_id in ^@fixture_subscription_item_processor_ids or
            item.subscription_id in ^fixture_subscription_ids
      )
    )

    Repo.delete_all(
      from(subscription in Subscription,
        where:
          subscription.processor_id in ^@fixture_subscription_processor_ids or
            subscription.id in ^fixture_subscription_ids or
            subscription.customer_id in ^cleanup_customer_ids
      )
    )

    Repo.delete_all(
      from(customer in Customer,
        where:
          customer.processor_id in ^@fixture_customer_processor_ids or
            customer.id in ^cleanup_customer_ids
      )
    )

    Repo.delete_all(
      from(customer in Customer,
        where: customer.email in ^@fixture_org_customer_emails
      )
    )

    Repo.delete_all(
      from(account in Account, where: account.stripe_account_id == "acct_host_browser_verify01")
    )

    Repo.delete_all(
      from(t in UserToken,
        join: u in User,
        on: t.user_id == u.id,
        where: u.email in ^@seeded_emails
      )
    )

    Repo.delete_all(
      from(user in User,
        where: user.email in ^@seeded_emails
      )
    )
  end

  defp create_user!(email, admin?) do
    user =
      case Accounts.get_user_by_email(email) do
        %User{} = user ->
          user

        nil ->
          {:ok, user} = Accounts.register_user(%{email: email})
          user
      end

    user =
      if User.valid_password?(user, @password) do
        user
      else
        {:ok, {user, _expired_tokens}} = Accounts.update_user_password(user, %{password: @password})
        user
      end

    user
    |> User.confirm_changeset()
    |> Ecto.Changeset.change(billing_admin: admin?)
    |> Repo.update!()
  end

  defp insert_org_customer!(organization) do
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "Organization",
      owner_id: to_string(organization.id),
      processor: "fake",
      processor_id: "cus_host_org_" <> String.replace(to_string(organization.id), "-", ""),
      email: "admin-e2e-alpha-customer@example.test"
    })
    |> Repo.insert!()
  end

  defp insert_fixture_connect_account!(organization) do
    %Account{}
    |> Account.changeset(%{
      stripe_account_id: "acct_host_browser_verify01",
      type: "standard",
      owner_type: "Organization",
      owner_id: to_string(organization.id),
      email: "connect-e2e@example.test",
      country: "us",
      charges_enabled: true,
      payouts_enabled: true,
      details_submitted: true
    })
    |> Repo.insert!()
  end

  defp insert_fixture_customer!(history_user) do
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "User",
      owner_id: history_user.id,
      processor: "fake",
      processor_id: "cus_host_browser_replay",
      email: history_user.email
    })
    |> Repo.insert!()
  end

  defp insert_fixture_subscription!(customer) do
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
  end

  defp insert_fixture_subscription_item!(subscription) do
    %SubscriptionItem{}
    |> SubscriptionItem.changeset(%{
      subscription_id: subscription.id,
      processor: "fake",
      processor_id: "si_host_browser_replay",
      price_id: "price_basic",
      quantity: 1
    })
    |> Repo.insert!()
  end

  defp insert_fixture_webhook!(customer, subscription) do
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
  end

  defp build_first_run_webhook(subscription) do
    payload =
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

    %{
      processor_event_id: "evt_host_browser_first_run",
      payload: payload,
      signature: LatticeStripe.Webhook.generate_test_signature(payload, @webhook_secret)
    }
  end

  defp write_fixture!(fixture_path, fixture) do
    File.mkdir_p!(Path.dirname(fixture_path))
    File.write!(fixture_path, Jason.encode!(fixture, pretty: true))
    IO.puts("wrote #{fixture_path}")
  end
end

if System.get_env("ACCRUE_HOST_SEED_E2E_NOAUTO") != "1" do
  AccrueHostSeedE2E.run!()
end
