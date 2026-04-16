defmodule AccrueAdmin.Live.SubscriptionsLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Billing.{Query, Subscription}
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, KpiCard}
  alias AccrueAdmin.Queries.Subscriptions

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(:table_path, admin_path(admin, "/subscriptions"))
     |> assign(:summary, subscription_summary())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AppShell.app_shell
      brand={@brand}
      current_path={@current_path}
      mount_path={@admin_mount_path}
      page_title={@page_title}
      theme={@theme}
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: @admin_mount_path},
              %{label: "Subscriptions"}
            ]}
          />
          <p class="ax-eyebrow">Subscriptions</p>
          <h2 class="ax-display">Lifecycle-safe subscription search</h2>
          <p class="ax-body ax-page-copy">
            Subscription list filters run on the shared query layer and expose canonical lifecycle
            states without requiring raw status checks in the UI.
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label="Subscription summary">
          <KpiCard.kpi_card label="Active" value={Integer.to_string(@summary.active_count)}>
            <:meta>Active and trialing subscriptions</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Canceling"
            value={Integer.to_string(@summary.canceling_count)}
            delta={Integer.to_string(@summary.paused_count) <> " paused"}
            delta_tone="amber"
          >
            <:meta>Canonical canceling and paused predicates</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label="Past due" value={Integer.to_string(@summary.past_due_count)}>
            <:meta>Subscriptions in dunning territory</:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="subscriptions"
          query_module={Subscriptions}
          path={@table_path}
          params={@params}
          columns={[
            %{label: "Subscription", render: &subscription_link(&1, @admin_mount_path)},
            %{label: "Customer", render: &customer_link(&1, @admin_mount_path)},
            %{label: "Lifecycle", render: &lifecycle_summary/1},
            %{id: :current_period_end, label: "Current period end"}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Customer", render: &customer_label/1},
            %{label: "Lifecycle", render: &lifecycle_summary/1},
            %{id: :current_period_end, label: "Current period end"}
          ]}
          filter_fields={[
            %{id: :q, label: "Search"},
            %{
              id: :status,
              label: "Status",
              type: :select,
              options: [
                {"active", "Active"},
                {"trialing", "Trialing"},
                {"canceling", "Canceling"},
                {"paused", "Paused"},
                {"past_due", "Past due"},
                {"canceled", "Canceled"}
              ]
            },
            %{id: :customer_id, label: "Customer id"}
          ]}
          empty_title="No subscriptions matched"
          empty_copy="Adjust the subscription filters or wait for new billing activity."
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Subscriptions")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/subscriptions"))
  end

  defp subscription_summary do
    %{
      active_count: Subscription |> Query.active() |> Repo.aggregate(:count, :id),
      canceling_count: Subscription |> Query.canceling() |> Repo.aggregate(:count, :id),
      paused_count: Subscription |> Query.paused() |> Repo.aggregate(:count, :id),
      past_due_count: Subscription |> Query.past_due() |> Repo.aggregate(:count, :id)
    }
  end

  defp subscription_link(row, mount_path),
    do: safe_link("#{mount_path}/subscriptions/#{row.id}", row.processor_id || row.id)

  defp customer_link(row, mount_path),
    do: safe_link("#{mount_path}/customers/#{row.customer_id}", customer_label(row))

  defp safe_link(href, label) do
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
  end

  defp customer_label(row), do: row.customer_name || row.customer_email || row.customer_id

  defp lifecycle_summary(row) do
    row
    |> lifecycle_flags()
    |> Enum.join(" · ")
  end

  defp lifecycle_flags(row) do
    [
      row.status && to_string(row.status),
      row.cancel_at_period_end && "cancel at period end",
      row.ended_at && "ended"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == false))
  end

  defp card_title(row), do: row.processor_id || row.id
  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
