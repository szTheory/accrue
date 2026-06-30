defmodule AccrueAdmin.Dev.StorybookCoverageTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AccrueAdmin.Dev.ComponentRegistry
  alias AccrueAdmin.Storybook.Components.ComponentRegistry, as: ComponentRegistryStory
  alias AccrueAdmin.Storybook.Groups.ComponentGroups, as: ComponentGroupsStory
  alias AccrueAdmin.Storybook.RegistryStory

  test "component registry story derives one coverage row per registry family" do
    expected_families =
      ComponentRegistry.entries()
      |> Enum.map(& &1.family)
      |> Enum.uniq()

    rows = ComponentRegistryStory.coverage_rows()

    assert Enum.map(rows, & &1.family) == expected_families

    assert Enum.map(ComponentRegistryStory.variations(), & &1.id) ==
             Enum.map(RegistryStory.component_variations(), & &1.id)

    for row <- rows do
      expected_entries = ComponentRegistry.variants_for(row.family)

      assert row.dom_id == RegistryStory.dom_id("component", row.family)
      assert Enum.map(row.entries, & &1.variant) == Enum.map(expected_entries, & &1.variant)
      assert row.variation_ids == Enum.map(RegistryStory.variations_for(row.family), & &1.id)

      assert MapSet.new(row.applicable_states) ==
               expected_entries
               |> Enum.flat_map(&Map.get(&1, :applicable_states, []))
               |> Enum.uniq()
               |> MapSet.new()

      assert MapSet.new(row.na_states) ==
               expected_entries
               |> Enum.flat_map(&Map.get(&1, :na_states, []))
               |> Enum.map(& &1.state)
               |> Enum.uniq()
               |> MapSet.new()
    end
  end

  test "component group story derives one coverage row per registry group contract" do
    contracts = ComponentRegistry.group_contracts()
    rows = ComponentGroupsStory.coverage_rows()

    assert Enum.map(rows, & &1.slug) == Enum.map(contracts, & &1.slug)

    for {row, contract} <- Enum.zip(rows, contracts) do
      assert row.dom_id == RegistryStory.dom_id("group", contract.slug)
      assert row.proof_id == contract.proof_id
      assert row.proof_selector == ~s([data-component-group="#{contract.slug}"])
      assert row.representative_marker == %{data_component_group: contract.slug}
      assert row.primary_components == contract.primary_components
      assert row.required_states == contract.required_states
      assert row.behavior_contracts == contract.behavior_contracts
      assert row.hierarchy == contract.hierarchy
    end
  end

  test "storybook coverage files do not hardcode current registry totals" do
    root = Path.expand("../../../../", __DIR__)

    forbidden_counts = ["3" <> "0", "4" <> "2", <<56>>]

    for path <- [
          "storybook/components/component_registry.story.exs",
          "storybook/groups/component_groups.story.exs",
          "accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs"
        ] do
      source = File.read!(Path.join(root, path))

      for count <- forbidden_counts do
        refute Regex.match?(~r/\b#{Regex.escape(count)}\b/, source),
               "#{path} hardcodes registry count #{count}; derive coverage from ComponentRegistry"
      end
    end
  end
end
