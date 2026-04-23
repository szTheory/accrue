defmodule Accrue.Docs.ExpansionDiscoveryTest do
  use ExUnit.Case, async: true

  @recommendation_path Path.expand(
                         "../../../../.planning/research/v1.2-expansion-recommendation.md",
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

    ranked_section =
      recommendation
      |> String.split("## Ranked Recommendation")
      |> Enum.at(1)
      |> String.split("## Migration Path Notes")
      |> List.first()

    assert ranked_section =~ "| 1 | Stripe Tax support | Next milestone |"
    assert ranked_section =~ "| 2 | Organization / multi-tenant billing | Backlog |"
    assert ranked_section =~ "| 3 | Revenue recognition / exports | Backlog |"
    assert ranked_section =~ "| 4 | Official second processor adapter | Planted seed |"
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
