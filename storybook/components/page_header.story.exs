defmodule AccrueAdmin.Storybook.Components.PageHeader do
  @moduledoc """
  Focused Storybook coverage for the Phase 196 PageHeader slot contract.
  """

  use PhoenixStorybook.Story, :component
  use Phoenix.Component

  alias AccrueAdmin.Components.DataTable
  alias AccrueAdmin.Components.PageHeader
  alias AccrueAdmin.Components.StatStrip
  alias PhoenixStorybook.Stories.Variation

  def function, do: &__MODULE__.page_header_story/1

  def variations do
    if Code.ensure_loaded?(AccrueAdmin.Components.PageHeader) do
      [
        %Variation{
          id: :default,
          description: "Breadcrumbs, title, and description",
          attributes: %{state: :default}
        },
        %Variation{
          id: :actions,
          description: "Caller-owned actions slot",
          attributes: %{state: :actions}
        },
        %Variation{
          id: :stat_strip,
          description: "Caller-owned stat strip slot",
          attributes: %{state: :stat_strip}
        },
        %Variation{
          id: :filter_toolbar,
          description: "Caller-owned filter toolbar slot",
          attributes: %{state: :filter_toolbar}
        },
        %Variation{
          id: :long_content,
          description: "Long breadcrumbs and title",
          attributes: %{state: :long_content}
        },
        %Variation{
          id: :combined_controls,
          description: "Actions plus filter toolbar",
          attributes: %{state: :combined_controls}
        }
      ]
    else
      []
    end
  end

  def page_header_story(assigns) do
    assigns =
      assigns
      |> Phoenix.Component.assign_new(:state, fn -> :default end)
      |> Phoenix.Component.assign(:breadcrumbs, breadcrumbs(assigns[:state] || :default))
      |> Phoenix.Component.assign(:title, title(assigns[:state] || :default))

    ~H"""
    <section class="ax-page ax-stack-xl" data-story-page-header={@state}>
      <PageHeader.page_header
        breadcrumbs={@breadcrumbs}
        title={@title}
        heading_id={"storybook-page-header-#{@state}"}
      >
        <:description>
          <p class="ax-body ax-page-copy">
            <%= description(@state) %>
          </p>
        </:description>

        <:stat_strip :if={@state in [:stat_strip, :combined_controls]}>
          <StatStrip.stat_strip label="Subscription summary">
            <:stat label="At risk" value="2" tone="amber" />
            <:stat label="Active" value="42" tone="moss" />
            <:stat label="Canceling" value="3" tone="cobalt" />
          </StatStrip.stat_strip>
        </:stat_strip>

        <:actions :if={@state in [:actions, :combined_controls]}>
          <a href="/billing/subscriptions?view=all" class="ax-button ax-button-secondary">
            View all subscriptions
          </a>
          <a href="/billing/customers" class="ax-button ax-button-primary">
            Find customer
          </a>
        </:actions>

        <:filter_toolbar :if={@state in [:filter_toolbar, :combined_controls]}>
          <DataTable.filter_toolbar
            id={"storybook-page-header-filter-#{@state}"}
            path="/billing/subscriptions"
            filter_fields={filter_fields()}
            filter_params={filter_params()}
            clear_href="/billing/subscriptions?view=all"
            clear_visible={true}
          />
        </:filter_toolbar>
      </PageHeader.page_header>
    </section>
    """
  end

  defp breadcrumbs(:long_content) do
    [
      %{label: "Dashboard", href: "/billing"},
      %{
        label: "Northeast Regional Platform Operations And Compliance Workspace",
        href: "/billing/subscriptions"
      },
      %{label: "Subscriptions requiring a billing-state review"}
    ]
  end

  defp breadcrumbs(_state) do
    [
      %{label: "Dashboard", href: "/billing"},
      %{label: "Subscriptions"}
    ]
  end

  defp title(:long_content) do
    "Subscriptions requiring operator review across enterprise billing work queues"
  end

  defp title(_state), do: "Subscriptions"

  defp description(:long_content) do
    "A deliberately long page title and breadcrumb trail exercise the shared header's truncation-friendly layout without moving list state into the component."
  end

  defp description(:actions),
    do: "Header actions are caller-owned and stay separate from resource query state."

  defp description(:stat_strip),
    do: "Stat-strip content is supplied by the page and rendered inside the bounded slot."

  defp description(:filter_toolbar),
    do:
      "Filter controls keep their LiveView event contract while PageHeader only provides placement."

  defp description(:combined_controls),
    do: "Actions and filter toolbar can coexist without PageHeader knowing what the filters mean."

  defp description(_state),
    do: "At-risk subscriptions first, with every subscription one click away."

  defp filter_fields do
    [
      %{id: :q, label: "Search", placeholder: "Search subscriptions"},
      %{
        id: :status,
        label: "Status",
        type: :select,
        options: [
          {"past_due,canceling", "At risk"},
          {"active", "Active"},
          {"canceled", "Canceled"}
        ]
      }
    ]
  end

  defp filter_params do
    %{"q" => "northwind", "status" => "past_due,canceling"}
  end
end
