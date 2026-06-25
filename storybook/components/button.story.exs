defmodule AccrueAdmin.Storybook.Components.Button do
  @moduledoc """
  PoC proof story for the Button component family.

  Delegates to `AccrueAdmin.Storybook.RegistryStory.variations_for/1` which
  sources all variations from `AccrueAdmin.Dev.ComponentRegistry` — the single
  source of truth (D-15 constraint honored). Phase 200 will add the remaining
  ~13 component families and both-color-mode theming verification (D-14 deferral).
  """

  use PhoenixStorybook.Story, :component

  def function, do: &AccrueAdmin.Components.Button.button/1

  def variations do
    if Code.ensure_loaded?(AccrueAdmin.Storybook.RegistryStory) do
      AccrueAdmin.Storybook.RegistryStory.variations_for("button")
    else
      []
    end
  end
end
