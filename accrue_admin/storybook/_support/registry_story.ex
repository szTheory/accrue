if Mix.env() != :prod do
  defmodule AccrueAdmin.Storybook.RegistryStory do
    @moduledoc false

    # D-17 spike C recorded decision: inert attribute is the background-suppression
    # mechanism of choice for overlays (see accrue_admin/lib/accrue_admin/dev/storybook.ex).
    # RegistryStory is the registry->Variation pipeline: it delegates to
    # AccrueAdmin.Dev.ComponentRegistry.variants_for/1 and maps each entry's specimens
    # into %PhoenixStorybook.Story.Variation{} structs for Storybook rendering.
    # The ComponentRegistry remains the single source of truth (D-15 constraint honored).

    alias AccrueAdmin.Dev.ComponentRegistry
    alias PhoenixStorybook.Stories.Variation

    @doc """
    Returns a list of `%PhoenixStorybook.Story.Variation{}` structs for the given
    component family, sourced from `AccrueAdmin.Dev.ComponentRegistry.variants_for/1`.

    Each registry entry's `specimens` list is flattened into individual Variations.
    The variation `id` is derived from `variant` + specimen index to ensure uniqueness.
    """
    @spec variations_for(String.t()) :: [Variation.t()]
    def variations_for(family) when is_binary(family) do
      family
      |> ComponentRegistry.variants_for()
      |> Enum.flat_map(fn entry ->
        specimens = entry[:specimens] || []

        specimens
        |> Enum.with_index()
        |> Enum.map(fn {specimen, idx} ->
          %Variation{
            id: slug_id(family, entry.variant, specimen[:label], idx),
            attributes: specimen[:props] || %{},
            slots: slots_for(specimen),
            description: variation_description(entry, specimen),
            note: state_note(entry),
            template: template_for(entry, specimen)
          }
        end)
      end)
    end

    @doc "Registry-derived component coverage metadata grouped by family."
    @spec component_variations() :: [map()]
    def component_variations do
      entries = ComponentRegistry.entries()

      entries
      |> Enum.map(& &1.family)
      |> Enum.uniq()
      |> Enum.map(fn family ->
        family_entries = Enum.filter(entries, &(&1.family == family))

        %{
          family: family,
          id: slug_id("component", family, "registry", 0),
          dom_id: dom_id("component", family),
          entries: family_entries,
          variations: variations_for(family),
          applicable_states: state_set(family_entries, :applicable_states),
          na_states: na_state_set(family_entries)
        }
      end)
    end

    @doc "Registry-derived group coverage metadata for every ComponentRegistry group contract."
    @spec group_variations() :: [map()]
    def group_variations do
      ComponentRegistry.group_contracts()
      |> Enum.with_index()
      |> Enum.map(fn {contract, idx} ->
        %{
          id: slug_id("group", contract.slug, contract.proof_id, idx),
          dom_id: dom_id("group", contract.slug),
          slug: contract.slug,
          contract: contract,
          proof_selector: ~s([data-component-group="#{contract.slug}"]),
          representative_marker: %{data_component_group: contract.slug}
        }
      end)
    end

    @doc "Stable slug atom used for Storybook variation IDs."
    @spec slug_id(String.t(), String.t(), String.t() | nil, non_neg_integer()) :: atom()
    def slug_id(family, variant, label, index)
        when is_binary(family) and is_binary(variant) and is_integer(index) and index >= 0 do
      [family, variant, label || "specimen", Integer.to_string(index)]
      |> Enum.map_join("-", &slug_part/1)
      |> String.to_atom()
    end

    @doc "Stable DOM id for generated Storybook proof elements."
    @spec dom_id(String.t(), String.t() | atom()) :: String.t()
    def dom_id(prefix, value) when is_binary(prefix) do
      [prefix, to_string(value)]
      |> Enum.map_join("-", &slug_part/1)
    end

    defp slots_for(specimen) do
      cond do
        is_list(specimen[:slots]) ->
          specimen[:slots]

        is_map(specimen[:named_slots]) ->
          named_slots(specimen[:named_slots])

        is_binary(specimen[:content]) ->
          [specimen[:content]]

        true ->
          []
      end
    end

    defp named_slots(slots) do
      Enum.map(slots, fn {name, content} ->
        content =
          content
          |> List.wrap()
          |> Enum.join("\n")

        "<:#{name}>#{content}</:#{name}>"
      end)
    end

    defp variation_description(entry, specimen) do
      [entry.family, entry.variant, specimen[:label] || "Specimen"]
      |> Enum.join(" / ")
    end

    defp template_for(entry, specimen) do
      cond do
        Map.has_key?(specimen, :template) -> specimen[:template]
        Map.has_key?(entry, :template) -> entry[:template]
        true -> :unset
      end
    end

    defp state_note(entry) do
      applicable =
        entry
        |> Map.get(:applicable_states, [])
        |> Enum.join(", ")

      na =
        entry
        |> Map.get(:na_states, [])
        |> Enum.map_join("; ", fn %{state: state, reason: reason} -> "#{state}: #{reason}" end)

      cond do
        applicable != "" and na != "" -> "Applicable states: #{applicable}. N/A states: #{na}."
        applicable != "" -> "Applicable states: #{applicable}."
        na != "" -> "N/A states: #{na}."
        true -> nil
      end
    end

    defp state_set(entries, key) do
      entries
      |> Enum.flat_map(&Map.get(&1, key, []))
      |> Enum.uniq()
    end

    defp na_state_set(entries) do
      entries
      |> Enum.flat_map(&Map.get(&1, :na_states, []))
      |> Enum.uniq_by(& &1.state)
    end

    defp slug_part(value) do
      value
      |> to_string()
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/u, "-")
      |> String.trim("-")
      |> case do
        "" -> "item"
        slug -> slug
      end
    end
  end
end
