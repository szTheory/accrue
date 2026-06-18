defmodule AccrueAdmin.Dev.ComponentGroupRegistryTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AccrueAdmin.Dev.ComponentRegistry

  @phase187_groups [
    {"page-header/actions/breadcrumbs", "page-header-actions-breadcrumbs"},
    {"toolbar/search/filter/sort", "toolbar-search-filter-sort"},
    {"table/empty/loading/error/pagination", "table-empty-loading-error-pagination"},
    {"KPI/chart/table", "kpi-chart-table"},
    {"detail-header/metadata/actions", "detail-header-metadata-actions"},
    {"modal-confirm", "modal-confirm"},
    {"drawer/form", "drawer-form"},
    {"tabs/subviews", "tabs-subviews"}
  ]

  @operator_stress_states [
    "long-content",
    "overflow",
    "empty",
    "filtered-empty",
    "loading",
    "error",
    "no-pagination",
    "has-pagination",
    "selected-filter-active",
    "mobile-card-list-degradation",
    "dark-mode"
  ]

  @phase191_handoff_tags [
    "focus-trap",
    "focus-restore",
    "escape",
    "click-outside",
    "scroll-reachability",
    "overlay-position",
    "liveview-patch-focus",
    "fixture-gaps",
    "microcopy"
  ]

  @billing_identifier_pattern ~r/(account|acct|customer|cus_|invoice|in_|subscription|sub_|webhook|event|evt_)/i

  test "all eight UI-SPEC slugs appear exactly once in Phase 187 order" do
    contracts = ComponentRegistry.group_contracts()

    assert Enum.map(contracts, & &1.name) == Enum.map(@phase187_groups, &elem(&1, 0))
    assert ComponentRegistry.component_group_slugs() == Enum.map(@phase187_groups, &elem(&1, 1))
    assert length(ComponentRegistry.component_group_slugs()) == 8
    assert Enum.uniq(ComponentRegistry.component_group_slugs()) == ComponentRegistry.component_group_slugs()

    for {name, slug} <- @phase187_groups do
      assert %{name: ^name, slug: ^slug} = ComponentRegistry.group_contract_by_slug(slug)
    end
  end

  test "each group contract has proof IDs, locators, components, and handoff metadata" do
    proof_ids = Enum.map(ComponentRegistry.group_contracts(), & &1.proof_id)

    assert Enum.uniq(proof_ids) == proof_ids

    for contract <- ComponentRegistry.group_contracts() do
      assert is_binary(contract.proof_id) and String.starts_with?(contract.proof_id, "grp190-")
      assert Enum.any?(contract.locators, &(&1 == ~s([data-component-group="#{contract.slug}"])))
      assert Enum.any?(contract.locators, &(&1 == "##{contract.slug}"))
      assert contract.primary_components != []
      assert contract.required_states != []
      assert contract.behavior_contracts != []
      assert contract.hierarchy != []
      assert contract.representative_route_category != ""
      assert contract.phase191_handoff_tags != []
    end
  end

  test "every required operator-stress state has a contract owner" do
    state_owners =
      for contract <- ComponentRegistry.group_contracts(),
          state <- contract.required_states,
          reduce: %{} do
        owners -> Map.update(owners, state, [contract.slug], &[contract.slug | &1])
      end

    missing_states =
      Enum.reject(@operator_stress_states, fn state ->
        Map.has_key?(state_owners, state)
      end)

    assert missing_states == []
  end

  test "overlay contracts carry Phase 191 handoff tags without claiming Phase 191 behavior" do
    modal = ComponentRegistry.group_contract_by_slug("modal-confirm")
    drawer = ComponentRegistry.group_contract_by_slug("drawer-form")

    assert "D-30" in modal.decisions
    assert "D-30" in drawer.decisions

    for tag <- ["focus-trap", "focus-restore", "escape", "click-outside", "overlay-position"] do
      assert tag in modal.phase191_handoff_tags
      assert tag in drawer.phase191_handoff_tags
    end

    all_handoff_tags =
      ComponentRegistry.group_contracts()
      |> Enum.flat_map(& &1.phase191_handoff_tags)
      |> MapSet.new()

    assert MapSet.subset?(MapSet.new(@phase191_handoff_tags), all_handoff_tags)

    deferred_language =
      ComponentRegistry.group_contracts()
      |> Enum.flat_map(& &1.behavior_contracts)
      |> Enum.join(" ")

    refute deferred_language =~ "trap focus"
    refute deferred_language =~ "restore focus"
    refute deferred_language =~ "dismisses on Escape"
    refute deferred_language =~ "click outside"
  end

  test "group slugs are static and cannot carry runtime billing identifiers" do
    for slug <- ComponentRegistry.component_group_slugs() do
      assert String.match?(slug, ~r/^[a-z0-9-]+$/)
      refute Regex.match?(@billing_identifier_pattern, slug)
      refute String.contains?(slug, ":")
      refute String.contains?(slug, "{")
      refute String.contains?(slug, "}")
    end
  end
end
