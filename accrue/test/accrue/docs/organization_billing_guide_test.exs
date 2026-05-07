defmodule Accrue.Docs.OrganizationBillingGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/organization_billing.md"
  @installer Path.expand(
               Path.join([__DIR__, "..", "..", "..", "lib", "mix", "tasks", "accrue.install.ex"])
             )
  @readme Path.expand(Path.join([__DIR__, "..", "..", "..", "README.md"]))

  test "organization billing guide keeps mandatory org billing anchors without maintainer taxonomy" do
    guide = File.read!(@guide)

    for needle <- [
          "fetch_current_organization",
          "use Accrue.Billable",
          "MyApp.Auth.PhxGenAuth",
          "AccrueHost.Accounts.Organization",
          "AccrueHost.Billing",
          "auth_adapters.md",
          "owner_type",
          "MyApp.Auth.Pow",
          "Pow.Plug.current_user",
          "Custom organization model",
          "Anti-pattern",
          "## Security boundaries at a glance",
          "## Pow-oriented checklist"
        ] do
      assert guide =~ needle,
             "expected guides/organization_billing.md to include #{inspect(needle)}"
    end

    for forbidden <- [
          "ORG-03",
          "ORG-07",
          "ORG-08",
          "ORG-09",
          "Phase 38",
          "verify_adoption_proof_matrix.sh",
          "adoption-proof-matrix.md",
          ".planning/",
          "v1.3-REQUIREMENTS.md",
          "## Adoption proof matrix"
        ] do
      refute guide =~ forbidden,
             "expected guides/organization_billing.md to avoid #{inspect(forbidden)}"
    end
  end

  test "installer non-Sigra auth guidance names organization billing and auth adapter guides" do
    source = File.read!(@installer)

    [_, non_sigra_clause] =
      String.split(source, "defp print_auth_guidance(_project) do", parts: 2)

    [clause_body, _] = String.split(non_sigra_clause, "\n  defp ", parts: 2)

    assert clause_body =~ "guides/organization_billing.md"
    assert clause_body =~ "guides/auth_adapters.md"
  end

  test "README surfaces organization billing guide link" do
    readme = File.read!(@readme)
    assert readme =~ "organization_billing.md"
  end
end
