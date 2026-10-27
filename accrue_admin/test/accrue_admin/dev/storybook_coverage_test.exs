defmodule AccrueAdmin.Dev.StorybookCoverageTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias AccrueAdmin.Dev.ComponentRegistry
  alias AccrueAdmin.Storybook.Components.ComponentRegistry, as: ComponentRegistryStory
  alias AccrueAdmin.Storybook.Groups.ComponentGroups, as: ComponentGroupsStory
  alias AccrueAdmin.Storybook.RegistryStory

  setup_all do
    previous_accrue_env = Application.get_env(:accrue, :env, :unset)
    previous_locale = Application.get_env(:localize, :default_locale, :unset)
    Application.put_env(:accrue, :env, :test)
    Application.put_env(:localize, :default_locale, :en)
    {:ok, _started} = Application.ensure_all_started(:localize)

    on_exit(fn ->
      case previous_accrue_env do
        :unset -> Application.delete_env(:accrue, :env)
        value -> Application.put_env(:accrue, :env, value)
      end

      case previous_locale do
        :unset -> Application.delete_env(:localize, :default_locale)
        value -> Application.put_env(:localize, :default_locale, value)
      end
    end)

    :ok
  end

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

  test "subscription composition coverage reconciles registry families, group identity, and manifest links" do
    alias AccrueAdmin.Storybook.SubscriptionManifest

    assert function_exported?(SubscriptionManifest, :caller_map, 0),
           "the production caller map is unavailable"

    rows = SubscriptionManifest.caller_map()
    entries = SubscriptionManifest.entries()
    expected_keys = Enum.map(entries, & &1.key) |> Enum.sort()
    family_rows = Enum.filter(rows, &is_binary(Map.get(&1, :registry_family)))

    assert Enum.map(family_rows, & &1.registry_family) ==
             Enum.map(family_rows, & &1.registry_family) |> Enum.uniq() |> Enum.sort()

    for row <- family_rows do
      registry_entries = ComponentRegistry.variants_for(row.registry_family)
      assert registry_entries != []
      assert row.registry_variants == Enum.map(registry_entries, & &1.variant)
      assert row.manifest_keys == expected_keys
    end

    group = Enum.find(rows, &(&1.tier == "group"))
    contract = ComponentRegistry.group_contract_by_slug(group.contract)
    assert contract.proof_id == group.registry_proof_id
    assert group.owner == "AccrueAdmin.Dev.ComponentRegistry.group_contracts/0"

    source_path = Path.expand("../../../../", __DIR__)

    for row <- rows do
      evidence_path = row.evidence |> String.split(":", parts: 2) |> hd()
      assert File.regular?(Path.join(source_path, evidence_path))
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
