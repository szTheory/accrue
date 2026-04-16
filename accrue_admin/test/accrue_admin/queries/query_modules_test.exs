defmodule AccrueAdmin.Queries.QueryModulesTest do
  use AccrueAdmin.RepoCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Charge, Coupon, Customer, Invoice, PromotionCode, Subscription}
  alias Accrue.Connect.Account

  alias AccrueAdmin.Queries.{
    Charges,
    ConnectAccounts,
    Coupons,
    Customers,
    Invoices,
    PromotionCodes,
    Subscriptions
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
    assert [%{id: ^coupon_new_id, valid: true}] = coupon_rows

    {promo_rows, _cursor} =
      PromotionCodes.list(filter: PromotionCodes.decode_filter(%{"active" => "true"}))

    assert [%{code: "NEWPROMO", active: true}] = promo_rows
  end

  test "connect account queries filter by onboarding booleans" do
    {rows, _cursor} =
      ConnectAccounts.list(filter: ConnectAccounts.decode_filter(%{"charges_enabled" => "true"}))

    assert [%{stripe_account_id: "acct_new", payouts_enabled: true}] = rows
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
end
