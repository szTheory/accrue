defmodule AccrueAdmin.Storybook.Components.ComponentRegistry do
  @moduledoc """
  Aggregate Storybook coverage for every component family in ComponentRegistry.
  """

  use PhoenixStorybook.Story, :page

  alias AccrueAdmin.Storybook.RegistryStory

  def doc do
    "Dynamic registry coverage for component families, variants, states, and generated Storybook variation IDs."
  end

  def variations, do: RegistryStory.component_variations()

  def coverage_rows do
    RegistryStory.component_variations()
    |> Enum.map(fn group ->
      %{
        family: group.family,
        dom_id: group.dom_id,
        entries: group.entries,
        applicable_states: group.applicable_states,
        na_states: Enum.map(group.na_states, & &1.state),
        variation_ids: Enum.map(group.variations, & &1.id)
      }
    end)
  end

  def render(assigns) do
    assigns = assign(assigns, :rows, coverage_rows())

    ~H"""
    <section class="ax-stack-xl" data-storybook-component-registry>
      <header class="ax-stack-sm">
        <p class="ax-eyebrow">Registry coverage</p>
        <h1 class="ax-heading-xl">Component Registry</h1>
        <p class="ax-body">
          Every row below is derived from AccrueAdmin.Dev.ComponentRegistry at compile/test time.
        </p>
      </header>

      <article
        :for={row <- @rows}
        id={row.dom_id}
        class="ax-card ax-stack-md"
        data-storybook-family={row.family}
      >
        <header class="ax-stack-xs">
          <p class="ax-eyebrow">{row.family}</p>
          <h2 class="ax-heading-md">{String.replace(row.family, "-", " ")}</h2>
        </header>

        <dl class="ax-description-list">
          <div>
            <dt>Variants</dt>
            <dd>
              <span
                :for={entry <- row.entries}
                class="ax-token"
                data-storybook-entry={"#{entry.family}/#{entry.variant}"}
              >
                {entry.variant}
              </span>
            </dd>
          </div>

          <div>
            <dt>Applicable states</dt>
            <dd>
              <span
                :for={state <- row.applicable_states}
                class="ax-token"
                data-storybook-state={state}
              >
                {state}
              </span>
            </dd>
          </div>

          <div>
            <dt>Not-applicable states</dt>
            <dd>
              <span :for={state <- row.na_states} class="ax-token" data-storybook-na-state={state}>
                {state}
              </span>
            </dd>
          </div>

          <div>
            <dt>Storybook variation IDs</dt>
            <dd>
              <code
                :for={variation_id <- row.variation_ids}
                class="ax-code"
                data-storybook-variation={to_string(variation_id)}
              >
                {to_string(variation_id)}
              </code>
            </dd>
          </div>
        </dl>
      </article>
    </section>
    """
  end
end
