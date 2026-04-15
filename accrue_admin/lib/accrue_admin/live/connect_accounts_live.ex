defmodule AccrueAdmin.Live.ConnectAccountsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Connect.Account
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, KpiCard}
  alias AccrueAdmin.Queries.ConnectAccounts

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(:table_path, admin_path(admin, "/connect"))
     |> assign(:summary, connect_summary())}
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
              %{label: "Connect"}
            ]}
          />
          <p class="ax-eyebrow">Marketplace operations</p>
          <h2 class="ax-display">Connected accounts and payout readiness</h2>
          <p class="ax-body ax-page-copy">
            Operators can filter connected-account projections, inspect onboarding state, and jump
            into per-account platform-fee configuration.
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label="Connect summary">
          <KpiCard.kpi_card label="Accounts" value={Integer.to_string(@summary.total_count)}>
            <:meta>All locally projected connected accounts</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Charges enabled"
            value={Integer.to_string(@summary.charges_enabled_count)}
            delta={Integer.to_string(@summary.details_submitted_count) <> " submitted"}
            delta_tone="cobalt"
          >
            <:meta>Capability and onboarding state from the local projection</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Overrides"
            value={Integer.to_string(@summary.override_count)}
            delta={Integer.to_string(@summary.deauthorized_count) <> " deauthorized"}
            delta_tone="amber"
          >
            <:meta>Accounts carrying a local platform-fee override</:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="connect-accounts"
          query_module={ConnectAccounts}
          path={@table_path}
          params={@params}
          columns={[
            %{label: "Account", render: &account_link(&1, @admin_mount_path)},
            %{label: "Owner", render: &owner_summary/1},
            %{label: "Readiness", render: &readiness_summary/1},
            %{label: "Override", render: &override_summary/1},
            %{label: "Status", render: &status_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Owner", render: &owner_summary/1},
            %{label: "Readiness", render: &readiness_summary/1},
            %{label: "Override", render: &override_summary/1},
            %{label: "Status", render: &status_summary/1}
          ]}
          filter_fields={[
            %{id: :q, label: "Search"},
            %{
              id: :type,
              label: "Type",
              type: :select,
              options: [{"standard", "Standard"}, {"express", "Express"}, {"custom", "Custom"}]
            },
            %{
              id: :charges_enabled,
              label: "Charges",
              type: :select,
              options: [{"true", "Enabled"}, {"false", "Disabled"}]
            },
            %{
              id: :payouts_enabled,
              label: "Payouts",
              type: :select,
              options: [{"true", "Enabled"}, {"false", "Disabled"}]
            },
            %{
              id: :details_submitted,
              label: "Onboarding",
              type: :select,
              options: [{"true", "Submitted"}, {"false", "Pending"}]
            },
            %{
              id: :deauthorized,
              label: "Authorization",
              type: :select,
              options: [{"true", "Deauthorized"}, {"false", "Active"}]
            }
          ]}
          empty_title="No connected accounts matched"
          empty_copy="Adjust the Connect filters or wait for the next projection sync."
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Connect")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/connect"))
  end

  defp connect_summary do
    %{
      total_count: Repo.aggregate(Account, :count, :id),
      charges_enabled_count:
        Account
        |> where([account], account.charges_enabled == true)
        |> Repo.aggregate(:count, :id),
      details_submitted_count:
        Account
        |> where([account], account.details_submitted == true)
        |> Repo.aggregate(:count, :id),
      deauthorized_count:
        Account
        |> where([account], not is_nil(account.deauthorized_at))
        |> Repo.aggregate(:count, :id),
      override_count:
        Account
        |> where(
          [account],
          fragment("?->'platform_fee_override' IS NOT NULL", account.data)
        )
        |> Repo.aggregate(:count, :id)
    }
  end

  defp account_link(row, mount_path),
    do: safe_link("#{mount_path}/connect/#{row.id}", row.stripe_account_id || row.id)

  defp owner_summary(row), do: "#{row.owner_type || "Owner"} #{row.owner_id || "--"}"

  defp readiness_summary(row) do
    [
      row.type && String.capitalize(row.type),
      row.charges_enabled && "charges",
      row.payouts_enabled && "payouts",
      row.details_submitted && "submitted"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == false))
    |> case do
      [] -> "Needs onboarding"
      values -> Enum.join(values, " · ")
    end
  end

  defp override_summary(%{id: id}) do
    case Repo.get(Account, id) do
      nil -> "Default only"
      account -> if has_override?(account), do: "Override saved", else: "Default only"
    end
  end

  defp status_summary(%{deauthorized_at: %DateTime{} = value}),
    do: "Deauthorized · " <> format_datetime(value)

  defp status_summary(row) do
    if row.country do
      "#{String.upcase(row.country)} · #{row.email || "No email"}"
    else
      row.email || "No email"
    end
  end

  defp card_title(row), do: row.stripe_account_id || row.id

  defp has_override?(account) do
    account
    |> platform_fee_override()
    |> map_size()
    |> Kernel.>(0)
  end

  defp platform_fee_override(account) do
    account.data
    |> Kernel.||(%{})
    |> Map.get("platform_fee_override", %{})
    |> case do
      value when is_map(value) -> value
      _ -> %{}
    end
  end

  defp safe_link(href, label) do
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  defp format_datetime(_value), do: "Unknown"

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
