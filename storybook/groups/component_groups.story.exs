defmodule AccrueAdmin.Storybook.Groups.ComponentGroups do
  @moduledoc """
  Aggregate Storybook coverage for ComponentRegistry group contracts.
  """

  use PhoenixStorybook.Story, :page

  alias AccrueAdmin.Storybook.RegistryStory

  def doc do
    "Dynamic registry coverage for component group contracts and representative proof markers."
  end

  def coverage_rows do
    RegistryStory.group_variations()
    |> Enum.map(fn group ->
      contract = group.contract

      %{
        slug: contract.slug,
        name: contract.name,
        dom_id: group.dom_id,
        proof_id: contract.proof_id,
        proof_selector: group.proof_selector,
        representative_marker: group.representative_marker,
        primary_components: contract.primary_components,
        required_states: contract.required_states,
        behavior_contracts: contract.behavior_contracts,
        hierarchy: contract.hierarchy,
        locators: contract.locators,
        phase191_handoff_tags: contract.phase191_handoff_tags
      }
    end)
  end

  def render(assigns) do
    assigns = assign(assigns, :rows, coverage_rows())

    ~H"""
    <section class="ax-stack-xl" data-storybook-component-groups>
      <header class="ax-stack-sm">
        <p class="ax-eyebrow">Registry coverage</p>
        <h1 class="ax-heading-xl">Component Groups</h1>
        <p class="ax-body">
          Every group proof below is derived from ComponentRegistry.group_contracts/0.
        </p>
      </header>

      <article
        :for={row <- @rows}
        id={row.dom_id}
        class="ax-card ax-stack-md"
        data-component-group={row.slug}
        data-storybook-group={row.slug}
      >
        <header class="ax-stack-xs">
          <p class="ax-eyebrow">{row.slug}</p>
          <h2 class="ax-heading-md">{row.name}</h2>
          <p class="ax-body-sm">Proof root: <code>{row.proof_id}</code></p>
        </header>

        <dl class="ax-description-list">
          <div>
            <dt>Primary components</dt>
            <dd>
              <span :for={component <- row.primary_components} class="ax-token">
                {component}
              </span>
            </dd>
          </div>

          <div>
            <dt>Required states</dt>
            <dd>
              <span :for={state <- row.required_states} class="ax-token" data-group-state={state}>
                {state}
              </span>
            </dd>
          </div>

          <div>
            <dt>Behavior contracts</dt>
            <dd>
              <span :for={contract <- row.behavior_contracts} class="ax-token">
                {contract}
              </span>
            </dd>
          </div>

          <div>
            <dt>Hierarchy</dt>
            <dd>
              <span :for={item <- row.hierarchy} class="ax-token">
                {item}
              </span>
            </dd>
          </div>

          <div>
            <dt>Proof selector</dt>
            <dd>
              <code data-storybook-proof-selector={row.proof_selector}>{row.proof_selector}</code>
            </dd>
          </div>
        </dl>
      </article>
    </section>
    """
  end
end
