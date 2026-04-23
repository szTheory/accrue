defmodule AccrueAdmin.Live.SubscriptionsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Query, Subscription}
  alias Accrue.Repo
  alias AccrueAdmin.BillingPresentation
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, FlashGroup, KpiCard}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Subscriptions

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(
       :current_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/subscriptions",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/subscriptions",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, subscription_summary(socket.assigns.current_owner_scope))}
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
    active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
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

        <FlashGroup.flash_group flashes={flash_messages(@flash)} />

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
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          columns={[
            %{
              label: "Subscription",
              render: &subscription_link(&1, @admin_mount_path, @current_owner_scope)
            },
            %{label: "Customer", render: &customer_link(&1, @admin_mount_path, @current_owner_scope)},
            %{label: "Billing signals", render: &billing_signals_cell/1},
            %{label: "Lifecycle", render: &lifecycle_summary/1},
            %{id: :current_period_end, label: "Current period end"}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Customer", render: &customer_label/1},
            %{label: "Billing signals", render: &billing_signals_cell/1},
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
          empty_title={Copy.subscriptions_index_empty_title()}
          empty_copy={Copy.subscriptions_index_empty_copy()}
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

  defp subscription_summary(owner_scope) do
    subscriptions = scoped_subscriptions(owner_scope)

    %{
      active_count: subscriptions |> Query.active() |> Repo.aggregate(:count, :id),
      canceling_count: subscriptions |> Query.canceling() |> Repo.aggregate(:count, :id),
      paused_count: subscriptions |> Query.paused() |> Repo.aggregate(:count, :id),
      past_due_count: subscriptions |> Query.past_due() |> Repo.aggregate(:count, :id)
    }
  end

  defp scoped_subscriptions(%{mode: :organization, organization_id: organization_id}) do
    Subscription
    |> join(:inner, [subscription], customer in assoc(subscription, :customer))
    |> where(
      [_subscription, customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end

  defp scoped_subscriptions(_owner_scope), do: Subscription

  defp billing_signals_cell(row) do
    ownership = BillingPresentation.ownership_label(row)
    tax = BillingPresentation.tax_health_label(BillingPresentation.tax_health(row))
    escaped_o = ownership |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    escaped_t = tax |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s(<span class="ax-chip ax-label">#{escaped_o}</span> <span class="ax-chip ax-label">#{escaped_t}</span>)
    )
  end

  defp subscription_link(row, mount_path, owner_scope),
    do:
      safe_link(
        scoped_path(mount_path, "/subscriptions/#{row.id}", owner_scope),
        row.processor_id || row.id
      )

  defp customer_link(row, mount_path, owner_scope),
    do:
      safe_link(
        scoped_path(mount_path, "/customers/#{row.customer_id}", owner_scope),
        customer_label(row)
      )

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

  defp flash_messages(flash) do
    Enum.flat_map([:error, :info], fn kind ->
      case Phoenix.Flash.get(flash, kind) do
        nil -> []
        message -> [%{kind: kind, message: message}]
      end
    end)
  end

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp scoped_path(mount_path, suffix, %{mode: :organization, organization_slug: slug})
       when is_binary(slug) do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_path(mount_path, suffix, _owner_scope), do: mount_path <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
