defmodule AccrueHostSeedE2E do
  alias Accrue.Billing.Customer
  alias Accrue.Billing.DiscountMapping
  alias Accrue.Billing.Invoice
  alias Accrue.Billing.PaymentMethod
  alias Accrue.Billing.Subscription
  alias Accrue.Billing.SubscriptionItem
  alias Accrue.Checkout.LocalSession
  alias Accrue.Connect.Account
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueHost.Accounts
  alias AccrueHost.Accounts.Scope
  alias AccrueHost.Accounts.OrganizationMembership
  alias AccrueHost.Accounts.User
  alias AccrueHost.Accounts.UserToken
  alias AccrueHost.Billing.Plans
  alias AccrueHost.Organizations
  alias AccrueHost.Repo

  import Ecto.Query

  @password "hello world!"
  @webhook_secret "whsec_test_host"
  @seeded_emails [
    "host-user@example.test",
    "host-admin@example.test",
    "host-billing-manager@example.test",
    "host-revocable-member@example.test",
    "billing-history@example.test"
  ]
  @fixture_org_customer_emails [
    "admin-e2e-alpha-customer@example.test",
    "admin-e2e-beta-customer@example.test",
    "host-org-checkout@example.test"
  ]
  @fixture_processor_event_ids ["evt_host_browser_replay", "evt_host_browser_first_run"]
  @fixture_customer_processor_ids [
    "cus_host_browser_replay",
    # Plan 04 host edge_states.exs: long-name customer
    "cus_e2e_edge_1"
  ]
  @fixture_subscription_processor_ids [
    "sub_host_browser_replay",
    "sub_bt_host_portal_fixture",
    "sub_bt_host_portal_partial",
    "sub_host_browser_recovery",
    # Plan 04 host edge_states.exs: at-risk and canceling subscriptions
    "sub_e2e_edge_at_risk",
    "sub_e2e_edge_canceling"
  ]
  @fixture_subscription_item_processor_ids [
    "si_host_browser_replay",
    "si_bt_host_portal_fixture"
  ]
  @fixture_invoice_processor_ids [
    "inv_bt_host_portal_personal",
    "inv_bt_host_portal_workspace"
  ]
  @fixture_discount_codes ["SPRING25", "BROKEN"]
  @fixture_checkout_operation_ids [
    "host-browser-portal-checkout",
    "host-browser-portal-checkout-expired",
    "host-browser-org-checkout"
  ]
  @events_table Accrue.Migration.qualified_table(:accrue_events)
  @discount_mappings_table Accrue.Migration.qualified_table(:accrue_discount_mappings)

  def run!(fixture_path \\ System.fetch_env!("ACCRUE_HOST_E2E_FIXTURE")) do
    cleanup_fixture_footprint!()

    normal_user = create_user!("host-user@example.test", false)
    admin_user = create_user!("host-admin@example.test", true)
    billing_manager = create_user!("host-billing-manager@example.test", false)
    revocable_member = create_user!("host-revocable-member@example.test", false)
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

    {:ok, revoked_org} =
      Organizations.create_organization(Scope.for_user(normal_user), %{
        name: "Host E2E Revoked Org",
        slug: "host-e2e-revoked"
      })

    Repo.delete_all(
      from(membership in OrganizationMembership,
        where:
          membership.user_id == ^normal_user.id and membership.organization_id == ^revoked_org.id
      )
    )

    {:ok, deleted_org} =
      Organizations.create_organization(Scope.for_user(admin_user), %{
        name: "Host E2E Deleted Org",
        slug: "host-e2e-deleted"
      })

    deleted_org
    |> Ecto.Changeset.change(deleted_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update!()

    set_fixture_membership_role!(normal_user, host_org_alpha, :member)
    insert_fixture_membership!(billing_manager, host_org_alpha, :admin)
    insert_fixture_membership!(revocable_member, host_org_alpha, :admin)
    insert_fixture_membership!(revocable_member, host_org_beta, :admin)

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
    admin_denial_payment_methods = insert_org_payment_methods!(admin_denial_customer)

    insert_org_fixture_subscription!(
      admin_denial_customer,
      admin_denial_payment_methods.in_use_blocked
    )

    fixture_invoice = insert_fixture_invoice!(admin_denial_customer)

    admin_foreign_customer =
      insert_org_customer!(admin_org_beta, "admin-e2e-beta-customer@example.test")

    admin_foreign_invoice =
      insert_fixture_invoice!(
        admin_foreign_customer,
        "inv_host_browser_foreign",
        "HOST-BROWSER-FOREIGN01"
      )

    recovery_subscription = insert_recovery_subscription!(admin_denial_customer)
    connect_account = insert_fixture_connect_account!(admin_org_alpha)

    customer = insert_fixture_customer!(history_user)
    subscription = insert_fixture_subscription!(customer)
    insert_fixture_subscription_item!(subscription)
    webhook = insert_fixture_webhook!(customer, subscription)
    portal_customer = insert_portal_checkout_customer!(normal_user)
    portal_payment_methods = insert_portal_payment_methods!(portal_customer)
    portal_subscription = insert_portal_subscription!(portal_customer)
    portal_partial_subscription = insert_portal_partial_subscription!(portal_customer)

    portal_invoice =
      insert_portal_invoice!(
        portal_customer,
        portal_subscription,
        "inv_bt_host_portal_personal",
        "INV-PORTAL-PERSONAL-001",
        "https://example.test/portal-personal-invoice"
      )

    checkout_session = insert_portal_checkout_session!(portal_customer)
    org_checkout_customer = insert_org_checkout_customer!(host_org_alpha)

    org_portal_invoice =
      insert_portal_invoice!(
        org_checkout_customer,
        nil,
        "inv_bt_host_portal_workspace",
        "INV-PORTAL-WORKSPACE-001",
        "https://example.test/portal-workspace-invoice"
      )

    org_checkout_session =
      insert_portal_checkout_session!(org_checkout_customer, "host-browser-org-checkout")

    braintree_completed_return =
      insert_braintree_host_return_session!(org_checkout_customer, host_org_alpha, "completed")

    braintree_pending_return =
      insert_braintree_host_return_session!(org_checkout_customer, host_org_alpha, "open")

    expired_portal_checkout_session =
      insert_portal_checkout_session!(
        portal_customer,
        "host-browser-portal-checkout-expired",
        expires_at: DateTime.add(DateTime.utc_now(), -300, :second),
        cancel_url: "/app/billing"
      )

    seed_portal_discount_mappings!()

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
      billing_manager_email: billing_manager.email,
      revocable_member_email: revocable_member.email,
      webhook_id: webhook.id,
      subscription_id: subscription.id,
      first_run_webhook: first_run_webhook,
      org_alpha_slug: host_org_alpha.slug,
      org_beta_slug: host_org_beta.slug,
      revoked_org_slug: revoked_org.slug,
      deleted_org_slug: deleted_org.slug,
      org_alpha_name: host_org_alpha.name,
      org_beta_name: host_org_beta.name,
      tax_invalid_customer_hint: "tax_invalid_e2e_hint",
      admin_org_alpha_slug: admin_org_alpha.slug,
      admin_org_beta_slug: admin_org_beta.slug,
      admin_org_beta_id: to_string(admin_org_beta.id),
      admin_denial_customer_id: admin_denial_customer.id,
      admin_beta_invoice_id: to_string(admin_foreign_invoice.id),
      recovery_subscription_id: to_string(recovery_subscription.id),
      admin_denial_payment_method_ids: %{
        in_use_blocked: admin_denial_payment_methods.in_use_blocked.id,
        replacement_required_default:
          admin_denial_payment_methods.replacement_required_default.id,
        deletable: admin_denial_payment_methods.deletable.id
      },
      connect_account_id: connect_account.id,
      invoice_id: to_string(fixture_invoice.id),
      portal_payment_method_ids: %{
        default: portal_payment_methods.default.id,
        backup: portal_payment_methods.backup.id
      },
      portal_subscription_id: to_string(portal_subscription.id),
      portal_partial_subscription_id: to_string(portal_partial_subscription.id),
      portal_invoice_id: to_string(portal_invoice.id),
      portal_invoice_url: portal_invoice.hosted_url,
      org_portal_invoice_url: org_portal_invoice.hosted_url,
      portal_checkout_token: checkout_session.session_token,
      portal_checkout_url: "/billing/checkout/#{checkout_session.session_token}",
      expired_portal_checkout_url:
        "/billing/checkout/#{expired_portal_checkout_session.session_token}",
      org_portal_checkout_url: "/shared-billing/checkout/#{org_checkout_session.session_token}",
      braintree_completed_return_url: braintree_completed_return.success_url,
      braintree_pending_return_url: braintree_pending_return.success_url,
      braintree_return_evidence: "fixture-backed LocalSession; not live Braintree proof",
      revocable_member_org_slug: host_org_alpha.slug
    }

    write_fixture!(fixture_path, fixture)
    fixture
  end

  defp cleanup_fixture_footprint! do
    # Browser VERIFY invoices use processor_id `inv_host_browser_*` on Fake — remove before
    # churning subscriptions/customers so unique indexes stay idempotent across reruns.
    Repo.delete_all(
      from(i in Invoice,
        where: i.processor == "fake" and fragment("? LIKE 'inv_host_browser_%'", i.processor_id)
      )
    )

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
      Repo.query!("ALTER TABLE #{@events_table} DISABLE TRIGGER accrue_events_immutable_trigger")

      try do
        Repo.delete_all(
          from(event in Event,
            where:
              event.subject_type == "Subscription" and
                event.subject_id in ^fake_browser_subscription_ids
          )
        )
      after
        Repo.query!("ALTER TABLE #{@events_table} ENABLE TRIGGER accrue_events_immutable_trigger")
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

    fixture_checkout_customer_ids =
      Repo.all(
        from(customer in Customer,
          where: customer.email in ^@fixture_org_customer_emails,
          select: customer.id
        )
      )

    cleanup_session_customer_ids =
      Enum.uniq(cleanup_customer_ids ++ fixture_checkout_customer_ids)

    Repo.delete_all(
      from(invoice in Invoice,
        where:
          invoice.processor_id in ^@fixture_invoice_processor_ids or
            invoice.customer_id in ^cleanup_session_customer_ids
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

    Repo.query!("ALTER TABLE #{@events_table} DISABLE TRIGGER accrue_events_immutable_trigger")

    try do
      Repo.delete_all(
        from(event in Event,
          where:
            event.actor_id in ^@fixture_processor_event_ids or
              event.caused_by_webhook_event_id in ^fixture_webhook_ids or
              (event.subject_type == "Subscription" and
                 event.subject_id in ^fixture_subscription_ids)
        )
      )
    after
      Repo.query!("ALTER TABLE #{@events_table} ENABLE TRIGGER accrue_events_immutable_trigger")
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
      from(session in LocalSession,
        where:
          session.customer_id in ^cleanup_session_customer_ids or
            session.operation_id in ^@fixture_checkout_operation_ids
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
      from(mapping in DiscountMapping,
        where: mapping.processor == "braintree" and mapping.code in ^@fixture_discount_codes
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
        {:ok, {user, _expired_tokens}} =
          Accounts.update_user_password(user, %{password: @password})

        user
      end

    user
    |> User.confirm_changeset()
    |> Ecto.Changeset.change(billing_admin: admin?)
    |> Repo.update!()
  end

  defp insert_org_customer!(organization, email \\ "admin-e2e-alpha-customer@example.test") do
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "Organization",
      owner_id: to_string(organization.id),
      processor: "fake",
      processor_id: "cus_host_org_" <> String.replace(to_string(organization.id), "-", ""),
      email: email
    })
    |> Repo.insert!()
  end

  defp insert_org_payment_methods!(customer) do
    in_use_blocked =
      insert_payment_method!(customer, %{
        processor_id: "pm_host_org_in_use_1111",
        fingerprint: "fp_host_org_in_use_1111",
        card_brand: "visa",
        card_last4: "1111",
        card_exp_month: 1,
        card_exp_year: 2030
      })

    replacement_required_default =
      insert_payment_method!(customer, %{
        processor_id: "pm_host_org_default_2222",
        fingerprint: "fp_host_org_default_2222",
        card_brand: "mastercard",
        card_last4: "2222",
        card_exp_month: 2,
        card_exp_year: 2031
      })

    deletable =
      insert_payment_method!(customer, %{
        processor_id: "pm_host_org_deletable_3333",
        fingerprint: "fp_host_org_deletable_3333",
        card_brand: "discover",
        card_last4: "3333",
        card_exp_month: 3,
        card_exp_year: 2032
      })

    customer
    |> Customer.changeset(%{default_payment_method_id: replacement_required_default.id})
    |> Repo.update!()

    %{
      in_use_blocked: in_use_blocked,
      replacement_required_default: replacement_required_default,
      deletable: deletable
    }
  end

  defp insert_payment_method!(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      processor: "fake",
      type: "card",
      is_default: false,
      metadata: %{},
      data: %{}
    }

    %PaymentMethod{}
    |> PaymentMethod.changeset(Map.merge(defaults, attrs))
    |> Repo.insert!()
  end

  # Deterministic VERIFY-01 invoice row for Admin E2E Alpha org (`accrue-e2e-alpha`).
  # processor_id prefix `inv_host_browser_%` is cleaned in `cleanup_fixture_footprint!/0`.
  defp insert_fixture_invoice!(
         %Customer{} = organization_scoped_customer,
         processor_id \\ "inv_host_browser_replay",
         number \\ "HOST-BROWSER-VERIFY01"
       ) do
    %Invoice{}
    |> Invoice.changeset(%{
      customer_id: organization_scoped_customer.id,
      subscription_id: nil,
      processor: "fake",
      processor_id: processor_id,
      status: :open,
      number: number,
      currency: "usd",
      total_cents: 1_000,
      metadata: %{},
      data: %{},
      collection_method: "charge_automatically",
      total_discount_amounts: %{},
      amount_due_minor: 1_000,
      amount_paid_minor: 0,
      amount_remaining_minor: 1_000,
      total_minor: 1_000,
      pdf_url: "https://example.test/e2e-invoice.pdf",
      hosted_url: "https://example.test/e2e-hosted-invoice"
    })
    |> Repo.insert!()
  end

  defp insert_recovery_subscription!(%Customer{} = customer) do
    campaign_started_at = DateTime.add(Accrue.Clock.utc_now(), -5 * 86_400, :second)

    subscription =
      %Subscription{}
      |> Subscription.force_status_changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "sub_host_browser_recovery",
        status: :past_due,
        past_due_since: campaign_started_at,
        dunning_campaign_started_at: campaign_started_at,
        cancel_at_period_end: false,
        lock_version: 1,
        metadata: %{},
        data: %{}
      })
      |> Repo.insert!()

    {:ok, _event} =
      Events.record(%{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subscription.id,
        actor_type: "system",
        actor_id: "phase237-admin-billing-e2e",
        data: %{"campaign_anchor" => DateTime.to_iso8601(campaign_started_at)}
      })

    subscription
  end

  defp insert_org_fixture_subscription!(customer, payment_method) do
    %Subscription{}
    |> Subscription.changeset(%{
      customer_id: customer.id,
      processor: "fake",
      processor_id: "sub_host_org_payment_method_guard",
      status: :active,
      data: %{
        "payment_method_token" => payment_method.processor_id,
        "items" => %{"data" => [%{"price" => %{"id" => "price_admin_verify01"}}]}
      }
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

  defp set_fixture_membership_role!(user, organization, role) do
    from(membership in OrganizationMembership,
      where: membership.user_id == ^user.id and membership.organization_id == ^organization.id
    )
    |> Repo.one!()
    |> Ecto.Changeset.change(role: role)
    |> Repo.update!()
  end

  defp insert_fixture_membership!(user, organization, role) do
    %OrganizationMembership{}
    |> OrganizationMembership.changeset(%{
      user_id: user.id,
      organization_id: organization.id,
      role: role
    })
    |> Repo.insert!()
  end

  defp insert_portal_checkout_customer!(user) do
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "User",
      owner_id: user.id,
      processor: "braintree",
      processor_id: "cus_bt_host_portal_fixture",
      email: user.email
    })
    |> Repo.insert!()
  end

  defp insert_org_checkout_customer!(organization) do
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "Organization",
      owner_id: to_string(organization.id),
      processor: "braintree",
      processor_id: "cus_bt_host_org_checkout_#{organization.id}",
      email: "host-org-checkout@example.test"
    })
    |> Repo.insert!()
  end

  defp insert_portal_payment_methods!(customer) do
    default =
      insert_payment_method!(customer, %{
        processor_id: "pm_host_portal_default_4242",
        fingerprint: "fp_host_portal_default_4242",
        card_brand: "visa",
        card_last4: "4242",
        card_exp_month: 12,
        card_exp_year: 2030,
        exp_month: 12,
        exp_year: 2030,
        is_default: true
      })

    backup =
      insert_payment_method!(customer, %{
        processor_id: "pm_host_portal_backup_4444",
        fingerprint: "fp_host_portal_backup_4444",
        card_brand: "mastercard",
        card_last4: "4444",
        card_exp_month: 1,
        card_exp_year: 2031,
        exp_month: 1,
        exp_year: 2031
      })

    customer
    |> Customer.changeset(%{default_payment_method_id: default.id})
    |> Repo.update!()

    %{default: default, backup: backup}
  end

  defp insert_portal_subscription!(customer) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    period_start = DateTime.add(now, -30 * 24 * 60 * 60, :second)
    period_end = DateTime.add(now, 30 * 24 * 60 * 60, :second)

    subscription =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_bt_host_portal_fixture",
        status: :active,
        current_period_start: period_start,
        current_period_end: period_end,
        cancel_at_period_end: false,
        data: %{
          "cancel_at_period_end" => false,
          "current_period_start" => DateTime.to_unix(period_start),
          "current_period_end" => DateTime.to_unix(period_end),
          "items" => %{
            "data" => [
              %{
                "id" => "si_bt_host_portal_fixture",
                "price" => %{"id" => "price_basic", "product" => "prod_host_portal"}
              }
            ]
          }
        }
      })
      |> Repo.insert!()

    %SubscriptionItem{}
    |> SubscriptionItem.changeset(%{
      subscription_id: subscription.id,
      processor: "braintree",
      processor_id: "si_bt_host_portal_fixture",
      price_id: "price_basic",
      processor_plan_id: "price_basic",
      processor_product_id: "prod_host_portal",
      quantity: 1,
      current_period_start: period_start,
      current_period_end: period_end,
      data: %{
        "id" => "si_bt_host_portal_fixture",
        "price" => %{"id" => "price_basic", "product" => "prod_host_portal"}
      }
    })
    |> Repo.insert!()

    Repo.preload(subscription, :subscription_items)
  end

  defp insert_portal_partial_subscription!(customer) do
    %Subscription{}
    |> Subscription.changeset(%{
      customer_id: customer.id,
      processor: "braintree",
      processor_id: "sub_bt_host_portal_partial",
      status: :past_due,
      data: %{
        "items" => %{
          "data" => [
            %{"id" => "si_bt_host_portal_partial", "price" => %{"id" => "price_basic"}}
          ]
        }
      }
    })
    |> Repo.insert!()
  end

  defp insert_portal_invoice!(customer, subscription, processor_id, number, hosted_url) do
    %Invoice{}
    |> Invoice.changeset(%{
      customer_id: customer.id,
      subscription_id: subscription && subscription.id,
      processor: "braintree",
      processor_id: processor_id,
      status: :open,
      number: number,
      currency: "usd",
      total_minor: 4_900,
      amount_due_minor: 4_900,
      amount_paid_minor: 0,
      amount_remaining_minor: 4_900,
      collection_method: "charge_automatically",
      total_discount_amounts: %{},
      automatic_tax: false,
      pdf_url: hosted_url <> ".pdf",
      hosted_url: hosted_url,
      metadata: %{},
      data: %{}
    })
    |> Repo.insert!()
  end

  defp insert_portal_checkout_session!(
         customer,
         operation_id \\ "host-browser-portal-checkout",
         overrides \\ []
       ) do
    attrs = %{
      processor: "braintree",
      mode: "subscription",
      ui_mode: "hosted",
      status: "open",
      price_id: "price_fixture",
      line_items: [
        %{
          "price" => "price_fixture",
          "quantity" => 1,
          "amount" => "49.00",
          "amount_minor" => 4_900
        }
      ],
      success_url: "https://app.example.test/billing/success",
      cancel_url: "https://app.example.test/billing/cancel",
      return_url: "https://app.example.test/settings/billing",
      operation_id: operation_id,
      metadata: %{
        "source" => "fixture",
        "plan_name" => "Studio",
        "amount_minor" => 4_900,
        "currency" => "USD",
        "interval" => "month",
        "interval_count" => 1,
        "billable_type" => customer.owner_type,
        "billable_id" => customer.owner_id,
        "billable_name" => customer.name || customer.email,
        "processor" => customer.processor
      },
      data: %{"local_portal" => true}
    }

    {:ok, session} =
      LocalSession.create_or_reuse(customer, Map.merge(attrs, Enum.into(overrides, %{})))

    session
  end

  defp insert_braintree_host_return_session!(customer, organization, status) do
    plan = Plans.get("price_basic")
    selection_id = Ecto.UUID.generate()

    success_url =
      "/app/billing?" <>
        URI.encode_query(%{
          checkout: "success",
          plan: plan.id,
          selection: selection_id
        })

    attrs = %{
      processor: "braintree",
      mode: "subscription",
      ui_mode: "hosted",
      status: status,
      price_id: plan.id,
      line_items: [
        %{
          "price" => plan.id,
          "quantity" => 1,
          "name" => plan.label,
          "amount" => "15.00",
          "amount_minor" => plan.unit_amount_minor,
          "currency" => plan.currency,
          "interval" => Atom.to_string(plan.billing_cycle.unit),
          "interval_count" => plan.billing_cycle.count
        }
      ],
      success_url: success_url,
      cancel_url: "/app/billing?checkout=cancel&plan=#{plan.id}&selection=#{selection_id}",
      operation_id: "pricing:#{organization.id}:#{plan.id}:#{selection_id}",
      metadata: %{
        "plan_name" => plan.label,
        "amount_minor" => plan.unit_amount_minor,
        "currency" => plan.currency,
        "interval" => Atom.to_string(plan.billing_cycle.unit),
        "interval_count" => plan.billing_cycle.count,
        "billable_type" => "Organization",
        "billable_id" => to_string(organization.id),
        "billable_name" => organization.name,
        "processor" => "braintree",
        "plan_id" => plan.id,
        "selection_id" => selection_id
      }
    }

    {:ok, session} = LocalSession.create_or_reuse(customer, attrs)
    session
  end

  defp seed_portal_discount_mappings! do
    {:ok, _mapping} =
      Accrue.Billing.upsert_discount_mapping("SPRING25", %{
        discount_id: "bt_discount_25",
        amount_off_minor: 2_500,
        currency: "USD"
      })

    {:ok, broken_mapping} =
      Accrue.Billing.upsert_discount_mapping("BROKEN", %{
        discount_id: "bt_discount_broken",
        amount_off_minor: 500,
        currency: "USD"
      })

    Repo.query!(
      """
      UPDATE #{@discount_mappings_table}
      SET discount_id = '', updated_at = $2
      WHERE id = $1
      """,
      [Ecto.UUID.dump!(broken_mapping.id), DateTime.utc_now() |> DateTime.truncate(:second)]
    )
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
