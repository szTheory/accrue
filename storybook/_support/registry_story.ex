if Mix.env() != :prod do
  defmodule AccrueAdmin.Storybook.RegistryStory do
    @moduledoc false

    # D-17 spike C recorded decision: inert attribute is the background-suppression
    # mechanism of choice for overlays (see accrue_admin/lib/accrue_admin/dev/storybook.ex).
    # RegistryStory is the registry→Variation pipeline: it delegates to
    # AccrueAdmin.Dev.ComponentRegistry.variants_for/1 and maps each entry's specimens
    # into %PhoenixStorybook.Story.Variation{} structs for Storybook rendering.
    # The ComponentRegistry remains the single source of truth (D-15 constraint honored).

    alias PhoenixStorybook.Story.Variation

    @doc """
    Returns a list of `%PhoenixStorybook.Story.Variation{}` structs for the given
    component family, sourced from `AccrueAdmin.Dev.ComponentRegistry.variants_for/1`.

    Each registry entry's `specimens` list is flattened into individual Variations.
    The variation `id` is derived from `variant` + specimen index to ensure uniqueness.
    """
    @spec variations_for(String.t()) :: [Variation.t()]
    def variations_for(family) when is_binary(family) do
      family
      |> AccrueAdmin.Dev.ComponentRegistry.variants_for()
      |> Enum.flat_map(fn entry ->
        specimens = entry[:specimens] || []

        specimens
        |> Enum.with_index()
        |> Enum.map(fn {specimen, idx} ->
          id_str =
            entry.variant
            |> String.replace("-", "_")
            |> then(&"#{&1}_#{idx}")

          %Variation{
            id: String.to_atom(id_str),
            attributes: specimen[:props] || %{},
            slots: if(specimen[:content], do: [specimen[:content]], else: []),
            description: specimen[:label] || ""
          }
        end)
      end)
    end
  end
end
