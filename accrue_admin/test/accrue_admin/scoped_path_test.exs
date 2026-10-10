defmodule AccrueAdmin.ScopedPathTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.{OwnerScope, ScopedPath}

  test "global scope, empty params, customers suffix" do
    scope = %OwnerScope{
      mode: :global,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: nil,
      organization_slug: nil,
      organization_display_name: nil,
      platform_admin?: true,
      admin_org_ids: [],
      active_organization_id: nil,
      active_organization_slug: nil
    }

    assert ScopedPath.build("/billing", "/customers", scope) == "/billing/customers"
  end

  test "organization scope appends org query" do
    scope = %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: "org_1",
      organization_slug: "acme",
      organization_display_name: "Acme",
      platform_admin?: false,
      admin_org_ids: ["org_1"],
      active_organization_id: "org_1",
      active_organization_slug: "acme"
    }

    path = ScopedPath.build("/billing", "/invoices/12", scope)
    assert path =~ "org=acme"
    assert String.starts_with?(path, "/billing/invoices/12")
  end

  test "global scope encodes extra query params" do
    scope = %OwnerScope{
      mode: :global,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: nil,
      organization_slug: nil,
      organization_display_name: nil,
      platform_admin?: true,
      admin_org_ids: [],
      active_organization_id: nil,
      active_organization_slug: nil
    }

    path = ScopedPath.build("/billing", "/customers/1", scope, %{"tab" => "invoices"})
    assert path =~ "tab=invoices"
  end

  test "return path keeps destination filters and drops unsupported list state and caller owner" do
    scope = organization_scope()

    assert ScopedPath.return_path(
             "/admin",
             "/admin/subscriptions?view=all&q=ada&sort=created_at&cursor=next&org=foreign",
             scope
           ) ==
             "/admin/subscriptions?org=acme&q=ada&view=all"
  end

  test "direct links and cross-mount return paths fall back to the current subscriptions list" do
    scope = organization_scope()

    assert ScopedPath.return_path("/admin", nil, scope) == "/admin/subscriptions?org=acme"

    assert ScopedPath.return_path("/admin", "/billing/subscriptions?view=all", scope) ==
             "/admin/subscriptions?org=acme"
  end

  test "absolute, foreign-scope, and secret-bearing return input cannot redirect or cross owner scope" do
    scope = organization_scope()

    assert ScopedPath.return_path(
             "/admin",
             "https://foreign.example/admin/subscriptions?view=all&org=foreign&token=secret&code=123456",
             scope
           ) == "/admin/subscriptions?org=acme"

    assert ScopedPath.return_path(
             "/admin",
             "/admin/subscriptions?view=all&org=foreign&token=secret&payment_token=secret",
             scope
           ) == "/admin/subscriptions?org=acme&view=all"
  end

  test "invalid and unsupported query values are dropped while a recognized local route is kept" do
    scope = organization_scope()

    assert ScopedPath.return_path(
             "/billing",
             "/billing/subscriptions?view=bogus&q=%00bad&cursor=#{String.duplicate("x", 2_049)}",
             scope
           ) == "/billing/subscriptions?org=acme"
  end

  test "return destination labels and paths share supported invoice meaning in both mounts" do
    scope = organization_scope()

    origin =
      "/billing/invoices?view=all&q=R%C3%A9sum%C3%A9&status=open&customer_id=cus_1&collection_method=send_invoice&sort=ignored&org=foreign"

    for mount <- ["/billing", "/admin"] do
      prefixed_origin = String.replace_prefix(origin, "/billing", mount)

      assert ScopedPath.return_destination(mount, prefixed_origin, scope, nil, "/invoices") == %{
               path:
                 "#{mount}/invoices?collection_method=send_invoice&customer_id=cus_1&org=acme&q=R%C3%A9sum%C3%A9&status=open&view=all",
               label: "Back to customer invoices"
             }
    end
  end

  test "query-free recognized routes are valid and get route-specific labels" do
    scope = organization_scope()

    assert ScopedPath.return_destination(
             "/admin",
             "/admin/invoices",
             scope,
             nil,
             "/invoices"
           ) == %{path: "/admin/invoices?org=acme", label: "Back to invoices"}

    assert ScopedPath.return_destination(
             "/billing",
             "/billing/payments?fees_settled=false&view=all",
             scope,
             nil,
             "/invoices"
           ) == %{
             path: "/billing/payments?fees_settled=false&org=acme&view=all",
             label: "Back to payments"
           }
  end

  test "customer detail return requires matching record and supported tab" do
    scope = organization_scope()
    customer_id = Ecto.UUID.generate()

    assert ScopedPath.return_destination(
             "/billing",
             "/billing/customers/#{customer_id}?tab=payments&org=foreign",
             scope,
             customer_id,
             "/invoices"
           ) == %{
             path: "/billing/customers/#{customer_id}?org=acme&tab=payments",
             label: "Back to customer payments"
           }

    assert ScopedPath.return_destination(
             "/billing",
             "/billing/customers/#{Ecto.UUID.generate()}?tab=payments",
             scope,
             customer_id,
             "/invoices"
           ) == %{path: "/billing/invoices?org=acme", label: "Back to invoices"}
  end

  test "event, webhook, catalog and Connect returns retain only decoder-supported filters" do
    scope = organization_scope()

    cases = [
      {"/events", "q=invoice&type=paid&actor_type=admin&subject_type=Invoice&source_webhook_event_id=evt_1&subject_id=ignored", "Back to events"},
      {"/webhooks", "type=invoice.payment_failed&status=failed,dead&livemode=false&query=ignored", "Back to webhooks"},
      {"/coupons", "view=all&q=summer&valid=true&status=ignored", "Back to coupons"},
      {"/promotion-codes", "view=all&q=SUMMER&active=false&coupon_id=coupon_1&status=ignored", "Back to promotion codes"},
      {"/connect", "view=all&q=acct_1&type=express&charges_enabled=true&payouts_enabled=false&details_submitted=true&deauthorized=false&needs_attention=true&status=ignored", "Back to Connect accounts"}
    ]

    for {suffix, query, label} <- cases do
      result =
        ScopedPath.return_destination(
          "/admin",
          "/admin#{suffix}?#{query}&org=foreign&owner_id=caller",
          scope,
          nil,
          suffix
        )

      assert result.label == label
      assert String.starts_with?(result.path, "/admin#{suffix}?")
      assert URI.decode_query(URI.parse(result.path).query)["org"] == "acme"
      refute result.path =~ "foreign"
      refute result.path =~ "owner_id"
      refute result.path =~ "ignored"
    end
  end

  test "malformed or invalid consumed return filters fall back to the current family" do
    scope = organization_scope()

    for origin <- [
          "/admin/events?type=%ZZ",
          "/admin/events?type=paid&type=failed",
          "/admin/webhooks?livemode=maybe",
          "/admin/coupons?valid=maybe",
          "/admin/promotion-codes?active=maybe",
          "/admin/connect?needs_attention=maybe",
          "/admin/events?source_webhook_event_id=#{String.duplicate("x", 129)}"
        ] do
      assert ScopedPath.return_destination("/admin", origin, scope, nil, "/events") == %{
               path: "/admin/events?org=acme",
               label: "Back to events"
             }
    end
  end

  test "ambiguous, malformed, external, scheme-relative, and cross-mount origins use fallback" do
    scope = organization_scope()

    for origin <- [
          "/admin/invoices?status=open&status=paid",
          "/admin/invoices?q=%ZZ",
          "//evil.example/admin/invoices",
          "https://evil.example/admin/invoices",
          "/billing/invoices"
        ] do
      assert ScopedPath.return_destination("/admin", origin, scope, nil, "/payments") == %{
               path: "/admin/payments?org=acme",
               label: "Back to payments"
             }
    end
  end

  test "customer detail returns are bound to the loaded record and current mount and owner" do
    scope = organization_scope()
    customer_id = Ecto.UUID.generate()
    other_customer_id = Ecto.UUID.generate()

    assert ScopedPath.return_path(
             "/admin",
             "/admin/customers/#{customer_id}?tab=payments&org=foreign",
             scope,
             customer_id,
             "/invoices"
           ) == "/admin/customers/#{customer_id}?org=acme&tab=payments"

    assert ScopedPath.return_path(
             "/admin",
             "/admin/customers/#{other_customer_id}?tab=payments",
             scope,
             customer_id,
             "/invoices"
           ) == "/admin/invoices?org=acme"

    assert ScopedPath.return_path(
             "/admin",
             "/billing/customers/#{customer_id}?tab=payments",
             scope,
             customer_id,
             "/invoices"
           ) == "/admin/invoices?org=acme"
  end

  defp organization_scope do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: "org_1",
      organization_slug: "acme",
      organization_display_name: "Acme",
      platform_admin?: false,
      admin_org_ids: ["org_1"],
      active_organization_id: "org_1",
      active_organization_slug: "acme"
    }
  end
end
