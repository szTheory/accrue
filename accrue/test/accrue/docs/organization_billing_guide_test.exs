defmodule Accrue.Docs.OrganizationBillingGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/organization_billing.md"
  @installer Path.expand(Path.join([__DIR__, "..", "..", "..", "lib", "mix", "tasks", "accrue.install.ex"]))
  @readme Path.expand(Path.join([__DIR__, "..", "..", "..", "README.md"]))

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
          "owner_type",
          "ORG-07",
          "MyApp.Auth.Pow",
          "Pow.Plug.current_user",
          "ORG-08",
          "Custom organization model",
          "Anti-pattern"
        ] do
      assert guide =~ needle, "expected guides/organization_billing.md to include #{inspect(needle)}"
    end
  end

  test "installer non-Sigra auth guidance names organization billing and auth adapter guides" do
    source = File.read!(@installer)
    [_, non_sigra_clause] = String.split(source, "defp print_auth_guidance(_project) do", parts: 2)
    [clause_body, _] = String.split(non_sigra_clause, "\n  defp ", parts: 2)

    assert clause_body =~ "guides/organization_billing.md"
    assert clause_body =~ "guides/auth_adapters.md"
  end

  test "README surfaces organization billing guide link" do
    readme = File.read!(@readme)
    assert readme =~ "organization_billing.md"
  end
end
