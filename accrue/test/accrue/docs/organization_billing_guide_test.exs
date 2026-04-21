defmodule Accrue.Docs.OrganizationBillingGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/organization_billing.md"

  test "organization billing guide keeps mandatory org billing anchors" do
    guide = File.read!(@guide)

    for needle <- [
          "ORG-03",
          "fetch_current_organization",
          "use Accrue.Billable",
          "MyApp.Auth.PhxGenAuth",
          "AccrueHost.Accounts.Organization",
          "AccrueHost.Billing",
          "auth_adapters.md",
          "Phase 38",
          "owner_type"
        ] do
      assert guide =~ needle, "expected guides/organization_billing.md to include #{inspect(needle)}"
    end
  end
end
