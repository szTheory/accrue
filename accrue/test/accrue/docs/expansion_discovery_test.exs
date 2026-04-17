defmodule Accrue.Docs.ExpansionDiscoveryTest do
  use ExUnit.Case, async: true

  @recommendation_path Path.expand(
                         "../../../../.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md",
                         __DIR__
                       )

  test "checked-in expansion recommendation exists and covers ranked candidates" do
    recommendation = File.read!(@recommendation_path)

    assert recommendation =~ "## Recommendation Rationale"
    assert recommendation =~ "## Ranked Recommendation"
    assert recommendation =~ "## Migration Path Notes"
    assert recommendation =~ "## Assumptions Log"
    assert recommendation =~ "## Open Questions"
    assert recommendation =~ "## Security And Boundary Checks"
    assert recommendation =~ "### Verification Runs"
    assert recommendation =~ "## Sign-Off"

    assert recommendation =~ "Stripe Tax support"
    assert recommendation =~ "Organization / multi-tenant billing"
    assert recommendation =~ "Revenue recognition / exports"
    assert recommendation =~ "Official second processor adapter"

    assert recommendation =~ "Next milestone"
    assert recommendation =~ "Backlog"
    assert recommendation =~ "Planted seed"
  end

  test "checked-in expansion recommendation preserves required decision language" do
    recommendation = File.read!(@recommendation_path)

    assert recommendation =~ "user value"
    assert recommendation =~ "architecture impact"
    assert recommendation =~ "risk"
    assert recommendation =~ "prerequisites"
    assert recommendation =~ "Stripe-first"
    assert recommendation =~ "host-owned"
    assert recommendation =~ "custom processor"
    assert recommendation =~ "Sigra"
    assert recommendation =~ "owner_type"
    assert recommendation =~ "owner_id"
  end

  test "checked-in expansion recommendation records security and migration constraints" do
    recommendation = File.read!(@recommendation_path)

    assert recommendation =~ "cross-tenant billing leakage"
    assert recommendation =~ "wrong-audience finance exports"
    assert recommendation =~ "tax rollout correctness"
    assert recommendation =~ "processor-boundary downgrade"
    assert recommendation =~ "customer location"
    assert recommendation =~ "recurring-item migration"
    assert recommendation =~ "host-authorized export delivery"
    assert recommendation =~ "separate-package"
  end
end
