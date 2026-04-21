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
end
