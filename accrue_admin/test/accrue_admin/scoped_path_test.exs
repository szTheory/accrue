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

  test "return path preserves supported list state in the configured mount and current owner" do
    scope = organization_scope()

    assert ScopedPath.return_path(
             "/admin",
             "/admin/subscriptions?view=all&q=ada&sort=created_at&cursor=next&org=foreign",
             scope
           ) ==
             "/admin/subscriptions?cursor=next&org=acme&q=ada&sort=created_at&view=all"
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
