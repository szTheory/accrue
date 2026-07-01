defmodule AccrueAdmin.Queries.QueryModulesTest do
  use AccrueAdmin.RepoCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Charge, Coupon, Customer, Invoice, PromotionCode, Subscription}
  alias Accrue.Connect.Account
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.OwnerScope

  alias AccrueAdmin.Queries.{
    Charges,
    ConnectAccounts,
    Coupons,
    Customers,
    Invoices,
    PromotionCodes,
    Subscriptions,
    Webhooks
  }

  setup do
    customer_old =
      insert_customer(%{
        email: "alpha@example.com",
        name: "Alpha",
        inserted_at: ~U[2026-04-10 10:00:00Z]
      })

    customer_new =
      insert_customer(%{
        email: "bravo@example.com",
        name: "Bravo",
        inserted_at: ~U[2026-04-11 10:00:00Z]
      })

    subscription_old =
      insert_subscription(customer_old, %{
        status: :trialing,
        processor_id: "sub_old",
        inserted_at: ~U[2026-04-10 11:00:00Z]
      })

    subscription_new =
      insert_subscription(customer_new, %{
        status: :active,
        processor_id: "sub_new",
        inserted_at: ~U[2026-04-11 11:00:00Z]
      })

    _invoice_old =
      insert_invoice(customer_old, subscription_old, %{
        status: :draft,
        number: "INV-0001",
        processor_id: "in_old",
        inserted_at: ~U[2026-04-10 12:00:00Z]
      })

    invoice_new =
      insert_invoice(customer_new, subscription_new, %{
        status: :open,
        number: "INV-0002",
        processor_id: "in_new",
        inserted_at: ~U[2026-04-11 12:00:00Z]
      })

    insert_charge(customer_old, subscription_old, %{
      status: "pending",
      processor_id: "ch_old",
      inserted_at: ~U[2026-04-10 13:00:00Z],
      fees_settled_at: nil
    })

    insert_charge(customer_new, subscription_new, %{
      status: "succeeded",
      processor_id: "ch_new",
      stripe_fee_amount_minor: 99,
      inserted_at: ~U[2026-04-11 13:00:00Z],
      fees_settled_at: ~U[2026-04-12 00:00:00Z]
    })

    coupon_old =
      insert_coupon(%{
        name: "Old Coupon",
        processor_id: "co_old",
        valid: false,
        inserted_at: ~U[2026-04-10 14:00:00Z]
      })

    coupon_new =
      insert_coupon(%{
        name: "New Coupon",
        processor_id: "co_new",
        valid: true,
        inserted_at: ~U[2026-04-11 14:00:00Z]
      })

    insert_promotion_code(coupon_old, %{
      code: "OLDPROMO",
      processor_id: "promo_old",
      active: false,
      inserted_at: ~U[2026-04-10 15:00:00Z]
    })

    insert_promotion_code(coupon_new, %{
      code: "NEWPROMO",
      processor_id: "promo_new",
      active: true,
      inserted_at: ~U[2026-04-11 15:00:00Z]
    })

    insert_connect_account(%{
      stripe_account_id: "acct_old",
      email: "old-account@example.com",
      charges_enabled: false,
      inserted_at: ~U[2026-04-10 16:00:00Z]
    })

    insert_connect_account(%{
      stripe_account_id: "acct_new",
      email: "new-account@example.com",
      charges_enabled: true,
      payouts_enabled: true,
      details_submitted: true,
      inserted_at: ~U[2026-04-11 16:00:00Z]
    })

    {:ok, customer_new: customer_new, invoice_new: invoice_new, coupon_new: coupon_new}
  end

  test "customer queries filter, paginate, and fail closed on invalid cursors", %{
    customer_new: customer_new
  } do
    customer_new_id = customer_new.id

    {rows, next_cursor} =
      Customers.list(limit: 1, filter: Customers.decode_filter(%{"q" => "example.com"}))

    assert [%{id: ^customer_new_id, email: "bravo@example.com"}] = rows
    assert is_binary(next_cursor)
    refute Map.has_key?(hd(rows), :data)
    refute Map.has_key?(hd(rows), :metadata)

    top_cursor = AccrueAdmin.Queries.Cursor.encode(hd(rows).inserted_at, hd(rows).id)

    assert Customers.count_newer_than(
             cursor: top_cursor,
             filter: Customers.decode_filter(%{"q" => "example.com"})
           ) == 0

    {invalid_rows, _cursor} =
      Customers.list(limit: 1, cursor: "bad-cursor", filter: Customers.decode_filter(%{}))

    assert [%{id: ^customer_new_id}] = invalid_rows
  end

  test "subscription queries use status-safe list filters", %{customer_new: customer_new} do
    customer_new_id = customer_new.id

    {rows, _cursor} =
      Subscriptions.list(filter: Subscriptions.decode_filter(%{"status" => "active"}))

    assert Enum.take(rows, 2) == [
             %{
               customer_id: customer_new_id,
               customer_email: "bravo@example.com",
               customer_name: "Bravo",
               processor_id: "sub_new",
               status: :active,
               cancel_at_period_end: false,
               current_period_end: nil,
               ended_at: nil,
               trial_end: nil,
               owner_id: Enum.at(rows, 0).owner_id,
               owner_type: "User",
               automatic_tax: false,
               automatic_tax_disabled_reason: nil,
               id: Enum.at(rows, 0).id,
               inserted_at: Enum.at(rows, 0).inserted_at
             },
             %{
               customer_email: "alpha@example.com",
               customer_name: "Alpha",
               processor_id: "sub_old",
               status: :trialing,
               cancel_at_period_end: false,
               current_period_end: nil,
               ended_at: nil,
               trial_end: nil,
               owner_id: Enum.at(rows, 1).owner_id,
               owner_type: "User",
               automatic_tax: false,
               automatic_tax_disabled_reason: nil,
               customer_id: Enum.at(rows, 1).customer_id,
               id: Enum.at(rows, 1).id,
               inserted_at: Enum.at(rows, 1).inserted_at
             }
           ]
  end

  test "invoice queries map real schema fields and search by invoice number", %{
    invoice_new: invoice_new
  } do
    invoice_new_id = invoice_new.id

    {rows, _cursor} = Invoices.list(filter: Invoices.decode_filter(%{"q" => "INV-0002"}))

    assert [%{id: ^invoice_new_id, number: "INV-0002", status: :open}] = rows
  end

  test "charge queries surface fee settlement filters" do
    {rows, _cursor} = Charges.list(filter: Charges.decode_filter(%{"fees_settled" => "true"}))

    assert hd(rows).processor_id == "ch_new"
    assert hd(rows).stripe_fee_amount_minor == 99
  end

  test "coupon and promotion code queries respect valid/active flags", %{coupon_new: coupon_new} do
    coupon_new_id = coupon_new.id

    {coupon_rows, _cursor} = Coupons.list(filter: Coupons.decode_filter(%{"valid" => "true"}))
    assert Enum.any?(coupon_rows, &match?(%{id: ^coupon_new_id, valid: true}, &1))
    assert Enum.all?(coupon_rows, &(&1.valid == true))
    refute Enum.any?(coupon_rows, &(&1.processor_id == "co_old"))

    {promo_rows, _cursor} =
      PromotionCodes.list(filter: PromotionCodes.decode_filter(%{"active" => "true"}))

    assert Enum.any?(promo_rows, &match?(%{code: "NEWPROMO", active: true}, &1))
    assert Enum.all?(promo_rows, &(&1.active == true))
    refute Enum.any?(promo_rows, &(&1.code == "OLDPROMO"))
  end

  test "connect account queries filter by onboarding booleans" do
    {rows, _cursor} =
      ConnectAccounts.list(filter: ConnectAccounts.decode_filter(%{"charges_enabled" => "true"}))

    assert Enum.any?(rows, &match?(%{stripe_account_id: "acct_new", payouts_enabled: true}, &1))
    assert Enum.all?(rows, &(&1.charges_enabled == true))
    refute Enum.any?(rows, &(&1.stripe_account_id == "acct_old"))
  end

  describe "multi-status filter handling" do
    test "Invoices.decode_filter/1 passes comma-separated status through unchanged" do
      filter = Invoices.decode_filter(%{"status" => "open,uncollectible"})
      assert filter.status == "open,uncollectible"
    end

    test "Invoices.list/1 with comma-separated status does not raise ArgumentError" do
      # The query module must not blow up — result may be empty but no crash.
      assert {rows, _cursor} =
               Invoices.list(filter: Invoices.decode_filter(%{"status" => "open,uncollectible"}))

      assert is_list(rows)
    end

    test "Invoices.list/1 with multi-status returns matching rows (open present in setup)" do
      {rows, _cursor} =
        Invoices.list(filter: Invoices.decode_filter(%{"status" => "open,uncollectible"}))

      # Setup inserts one :open invoice (INV-0002) and one :draft invoice (INV-0001).
      # Only :open should appear.
      assert Enum.any?(rows, &(&1.status == :open))
      refute Enum.any?(rows, &(&1.status == :draft))
    end

    test "Subscriptions.decode_filter/1 passes comma-separated status through unchanged" do
      filter = Subscriptions.decode_filter(%{"status" => "past_due,canceling"})
      assert filter.status == "past_due,canceling"
    end

    test "Subscriptions.list/1 with comma-separated status does not raise" do
      assert {rows, _cursor} =
               Subscriptions.list(
                 filter: Subscriptions.decode_filter(%{"status" => "past_due,canceling"})
               )

      assert is_list(rows)
    end

    test "Subscriptions.list/1 single-status path still works after refactor" do
      {rows, _cursor} =
        Subscriptions.list(filter: Subscriptions.decode_filter(%{"status" => "active"}))

      assert Enum.all?(rows, &(&1.status in [:active, :trialing]))
    end

    test "Charges.list/1 with single status still works (backward compat)" do
      {rows, _cursor} = Charges.list(filter: Charges.decode_filter(%{"status" => "succeeded"}))
      assert Enum.all?(rows, &(&1.status == "succeeded"))
    end

    test "Charges.list/1 with multi-value status does not raise" do
      assert {rows, _cursor} =
               Charges.list(filter: Charges.decode_filter(%{"status" => "failed,pending"}))

      assert is_list(rows)
    end

    test "Charges.list/1 with multi-value status returns matching rows" do
      # Setup inserts "pending" charge (ch_old) and "succeeded" charge (ch_new).
      {rows, _cursor} =
        Charges.list(filter: Charges.decode_filter(%{"status" => "pending,succeeded"}))

      statuses = Enum.map(rows, & &1.status)
      assert "pending" in statuses
      assert "succeeded" in statuses
    end

    test "Webhooks.decode_filter/1 allowlists comma-separated replay statuses" do
      filter = Webhooks.decode_filter(%{"status" => "failed,dead,Elixir.String"})

      assert filter.status == [:failed, :dead]
    end

    test "Webhooks.list/1 with replay statuses returns failed or dead deliveries only" do
      insert_webhook(%{
        processor_event_id: "evt_phase197_failed",
        status: :failed,
        received_at: ~U[2026-04-11 17:00:00Z]
      })

      insert_webhook(%{
        processor_event_id: "evt_phase197_dead",
        status: :dead,
        received_at: ~U[2026-04-11 17:01:00Z]
      })

      insert_webhook(%{
        processor_event_id: "evt_phase197_succeeded",
        status: :succeeded,
        received_at: ~U[2026-04-11 17:02:00Z]
      })

      {rows, _cursor} =
        Webhooks.list(filter: Webhooks.decode_filter(%{"status" => "failed,dead"}))

      processor_event_ids = Enum.map(rows, & &1.processor_event_id)

      assert "evt_phase197_failed" in processor_event_ids
      assert "evt_phase197_dead" in processor_event_ids
      refute "evt_phase197_succeeded" in processor_event_ids
      assert Enum.all?(rows, &(&1.status in [:failed, :dead]))
    end
  end

  describe "phase 197 query semantics" do
    test "ConnectAccounts.decode_filter/1 emits a named attention lens" do
      filter = ConnectAccounts.decode_filter(%{"needs_attention" => "true"})

      assert filter.needs_attention == true
    end

    test "ConnectAccounts.list/1 needs_attention matches any readiness blocker" do
      insert_connect_account(%{
        stripe_account_id: "acct_attention_deauthorized",
        email: "deauthorized@example.com",
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true,
        deauthorized_at: ~U[2026-04-11 17:10:00Z],
        inserted_at: ~U[2026-04-11 17:10:00Z]
      })

      insert_connect_account(%{
        stripe_account_id: "acct_attention_charges",
        email: "charges-disabled@example.com",
        charges_enabled: false,
        payouts_enabled: true,
        details_submitted: true,
        inserted_at: ~U[2026-04-11 17:11:00Z]
      })

      insert_connect_account(%{
        stripe_account_id: "acct_attention_payouts",
        email: "payouts-disabled@example.com",
        charges_enabled: true,
        payouts_enabled: false,
        details_submitted: true,
        inserted_at: ~U[2026-04-11 17:12:00Z]
      })

      insert_connect_account(%{
        stripe_account_id: "acct_attention_onboarding",
        email: "onboarding@example.com",
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: false,
        inserted_at: ~U[2026-04-11 17:13:00Z]
      })

      insert_connect_account(%{
        stripe_account_id: "acct_attention_healthy",
        email: "healthy@example.com",
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true,
        inserted_at: ~U[2026-04-11 17:14:00Z]
      })

      {rows, _cursor} =
        ConnectAccounts.list(
          filter: ConnectAccounts.decode_filter(%{"needs_attention" => "true"}),
          limit: 20
        )

      account_ids = Enum.map(rows, & &1.stripe_account_id)

      assert "acct_attention_deauthorized" in account_ids
      assert "acct_attention_charges" in account_ids
      assert "acct_attention_payouts" in account_ids
      assert "acct_attention_onboarding" in account_ids
      refute "acct_attention_healthy" in account_ids
    end

    test "ConnectAccounts.list/1 applies organization owner scope" do
      allowed_old =
        insert_connect_account(%{
          stripe_account_id: "acct_connect_allowed_old",
          owner_type: "Organization",
          owner_id: "org_allowed",
          charges_enabled: false,
          inserted_at: ~U[2026-04-11 18:10:00Z]
        })

      insert_connect_account(%{
        stripe_account_id: "acct_connect_allowed_new",
        owner_type: "Organization",
        owner_id: "org_allowed",
        charges_enabled: false,
        inserted_at: ~U[2026-04-11 18:11:00Z]
      })

      insert_connect_account(%{
        stripe_account_id: "acct_connect_denied_newer",
        owner_type: "Organization",
        owner_id: "org_denied",
        charges_enabled: false,
        inserted_at: ~U[2026-04-11 18:12:00Z]
      })

      owner_scope = organization_owner_scope("org_allowed")

      {rows, _cursor} =
        ConnectAccounts.list(
          filter: ConnectAccounts.decode_filter(%{"charges_enabled" => "false"}),
          owner_scope: owner_scope,
          limit: 20
        )

      account_ids = Enum.map(rows, & &1.stripe_account_id)

      assert "acct_connect_allowed_old" in account_ids
      assert "acct_connect_allowed_new" in account_ids
      refute "acct_connect_denied_newer" in account_ids

      cursor = AccrueAdmin.Queries.Cursor.encode(allowed_old.inserted_at, allowed_old.id)

      assert ConnectAccounts.count_newer_than(
               filter: ConnectAccounts.decode_filter(%{"charges_enabled" => "false"}),
               owner_scope: owner_scope,
               cursor: cursor
             ) == 1
    end

    test "Charges.list/1 applies organization owner scope through customers" do
      allowed_customer =
        insert_customer(%{
          owner_type: "Organization",
          owner_id: "org_allowed",
          email: "allowed-scope@example.com",
          name: "Allowed Scope"
        })

      denied_customer =
        insert_customer(%{
          owner_type: "Organization",
          owner_id: "org_denied",
          email: "denied-scope@example.com",
          name: "Denied Scope"
        })

      allowed_subscription =
        insert_subscription(allowed_customer, %{
          status: :active,
          processor_id: "sub_allowed_scope",
          inserted_at: ~U[2026-04-11 18:00:00Z]
        })

      denied_subscription =
        insert_subscription(denied_customer, %{
          status: :active,
          processor_id: "sub_denied_scope",
          inserted_at: ~U[2026-04-11 18:01:00Z]
        })

      insert_charge(allowed_customer, allowed_subscription, %{
        status: "failed",
        processor_id: "ch_allowed_scope",
        inserted_at: ~U[2026-04-11 18:02:00Z]
      })

      insert_charge(denied_customer, denied_subscription, %{
        status: "failed",
        processor_id: "ch_denied_scope",
        inserted_at: ~U[2026-04-11 18:03:00Z]
      })

      {rows, _cursor} =
        Charges.list(
          filter: Charges.decode_filter(%{"status" => "failed"}),
          owner_scope: organization_owner_scope("org_allowed")
        )

      processor_ids = Enum.map(rows, & &1.processor_id)

      assert "ch_allowed_scope" in processor_ids
      refute "ch_denied_scope" in processor_ids
    end
  end

  test "phase 7 admin indexes exist" do
    names = [
      "accrue_customers_inserted_at_id_idx",
      "accrue_customers_email_idx",
      "accrue_subscriptions_status_inserted_at_id_idx",
      "accrue_subscriptions_customer_inserted_at_id_idx",
      "accrue_invoices_status_inserted_at_id_idx",
      "accrue_invoices_customer_inserted_at_id_idx",
      "accrue_invoices_number_index",
      "accrue_charges_status_inserted_at_id_idx",
      "accrue_charges_customer_inserted_at_id_idx",
      "accrue_coupons_valid_inserted_at_id_idx",
      "accrue_promotion_codes_active_inserted_at_id_idx",
      "accrue_connect_accounts_charges_enabled_inserted_at_id_idx"
    ]

    found =
      from(index in "pg_indexes",
        where: index.indexname in ^names,
        select: index.indexname
      )
      |> AccrueAdmin.TestRepo.all()

    assert Enum.sort(found) == Enum.sort(names)
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    attrs =
      defaults
      |> Map.merge(attrs)

    %Customer{}
    |> Customer.changeset(attrs)
    |> AccrueAdmin.TestRepo.insert!()
  end

  defp insert_subscription(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      processor_id: "sub_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Subscription{}
    |> Subscription.changeset(Map.merge(defaults, attrs))
    |> AccrueAdmin.TestRepo.insert!()
  end

  defp insert_invoice(customer, subscription, attrs) do
    defaults = %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      processor: "stripe",
      currency: "usd",
      collection_method: "charge_automatically",
      amount_due_minor: 1_000,
      amount_paid_minor: 0,
      amount_remaining_minor: 1_000,
      total_minor: 1_000,
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Invoice{}
    |> Invoice.force_status_changeset(Map.merge(defaults, attrs))
    |> AccrueAdmin.TestRepo.insert!()
  end

  defp insert_charge(customer, subscription, attrs) do
    defaults = %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      processor: "stripe",
      amount_cents: 2_000,
      currency: "usd",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Charge{}
    |> Charge.changeset(Map.merge(defaults, attrs))
    |> AccrueAdmin.TestRepo.insert!()
  end

  defp insert_coupon(attrs) do
    defaults = %{
      processor: "stripe",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Coupon{}
    |> Coupon.changeset(Map.merge(defaults, attrs))
    |> AccrueAdmin.TestRepo.insert!()
  end

  defp insert_promotion_code(coupon, attrs) do
    defaults = %{
      processor: "stripe",
      coupon_id: coupon.id,
      metadata: %{},
      data: %{},
      last_stripe_event_id: "evt_" <> Integer.to_string(System.unique_integer([:positive]))
    }

    %PromotionCode{}
    |> PromotionCode.force_status_changeset(Map.merge(defaults, attrs))
    |> AccrueAdmin.TestRepo.insert!()
  end

  defp insert_connect_account(attrs) do
    defaults = %{
      stripe_account_id: "acct_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "express",
      capabilities: %{},
      requirements: %{},
      data: %{},
      lock_version: 1
    }

    %Account{}
    |> Account.changeset(Map.merge(defaults, attrs))
    |> AccrueAdmin.TestRepo.insert!()
  end

  defp insert_webhook(attrs) do
    defaults = %{
      processor: "stripe",
      processor_event_id: "evt_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "invoice.payment_failed",
      livemode: false,
      endpoint: :default,
      status: :received,
      raw_body:
        Jason.encode!(%{
          "id" => "evt_seed",
          "object" => "event",
          "type" => "invoice.payment_failed"
        }),
      received_at: DateTime.utc_now(),
      data: %{"id" => "evt_seed", "object" => "event", "type" => "invoice.payment_failed"}
    }

    Map.merge(defaults, attrs)
    |> WebhookEvent.ingest_changeset()
    |> AccrueAdmin.TestRepo.insert!()
    |> then(fn webhook ->
      webhook
      |> Ecto.Changeset.change(%{
        status: Map.get(attrs, :status, :received),
        processed_at: Map.get(attrs, :processed_at)
      })
      |> AccrueAdmin.TestRepo.update!()
    end)
  end

  defp organization_owner_scope(organization_id) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: organization_id,
      organization_slug: "allowed-org",
      platform_admin?: false,
      admin_org_ids: [organization_id],
      active_organization_id: organization_id,
      active_organization_slug: "allowed-org"
    }
  end
end
