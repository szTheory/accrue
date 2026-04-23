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
    active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: AccrueAdmin.Copy.dashboard_breadcrumb_home(), href: @admin_mount_path},
              %{label: AccrueAdmin.Copy.connect_accounts_breadcrumb_connect()}
            ]}
          />
          <p class="ax-eyebrow"><%= AccrueAdmin.Copy.connect_accounts_eyebrow() %></p>
          <h2 class="ax-display"><%= AccrueAdmin.Copy.connect_accounts_headline() %></h2>
          <p class="ax-body ax-page-copy">
            <%= AccrueAdmin.Copy.connect_accounts_page_copy_primary() %>
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label={AccrueAdmin.Copy.connect_accounts_kpi_section_aria_label()}>
          <KpiCard.kpi_card label={AccrueAdmin.Copy.connect_accounts_kpi_label_accounts()} value={Integer.to_string(@summary.total_count)}>
            <:meta><%= AccrueAdmin.Copy.connect_accounts_kpi_meta_all_accounts() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label={AccrueAdmin.Copy.connect_accounts_kpi_label_charges_enabled()}
            value={Integer.to_string(@summary.charges_enabled_count)}
            delta={Integer.to_string(@summary.details_submitted_count) <> AccrueAdmin.Copy.connect_accounts_kpi_delta_submitted_suffix()}
            delta_tone="cobalt"
          >
            <:meta><%= AccrueAdmin.Copy.connect_accounts_kpi_meta_capability_onboarding() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label={AccrueAdmin.Copy.connect_accounts_kpi_label_overrides()}
            value={Integer.to_string(@summary.override_count)}
            delta={Integer.to_string(@summary.deauthorized_count) <> AccrueAdmin.Copy.connect_accounts_kpi_delta_deauthorized_suffix()}
            delta_tone="amber"
          >
            <:meta><%= AccrueAdmin.Copy.connect_accounts_kpi_meta_platform_fee_override() %></:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="connect-accounts"
          query_module={ConnectAccounts}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          filter_submit_label={AccrueAdmin.Copy.connect_accounts_apply_filters()}
          columns={[
            %{label: AccrueAdmin.Copy.connect_accounts_table_column_account(), render: &account_link(&1, @admin_mount_path)},
            %{label: AccrueAdmin.Copy.connect_accounts_table_column_owner(), render: &owner_summary/1},
            %{label: AccrueAdmin.Copy.connect_accounts_table_column_readiness(), render: &readiness_summary/1},
            %{label: AccrueAdmin.Copy.connect_accounts_table_column_override(), render: &override_summary/1},
            %{label: AccrueAdmin.Copy.connect_accounts_table_column_status(), render: &status_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: AccrueAdmin.Copy.connect_accounts_table_column_owner(), render: &owner_summary/1},
            %{label: AccrueAdmin.Copy.connect_accounts_table_column_readiness(), render: &readiness_summary/1},
            %{label: AccrueAdmin.Copy.connect_accounts_table_column_override(), render: &override_summary/1},
            %{label: AccrueAdmin.Copy.connect_accounts_table_column_status(), render: &status_summary/1}
          ]}
          filter_fields={[
            %{id: :q, label: AccrueAdmin.Copy.connect_accounts_filter_label_search()},
            %{
              id: :type,
              label: AccrueAdmin.Copy.connect_accounts_filter_label_type(),
              type: :select,
              options: [
                {"standard", AccrueAdmin.Copy.connect_accounts_filter_option_type_standard()},
                {"express", AccrueAdmin.Copy.connect_accounts_filter_option_type_express()},
                {"custom", AccrueAdmin.Copy.connect_accounts_filter_option_type_custom()}
              ]
            },
            %{
              id: :charges_enabled,
              label: AccrueAdmin.Copy.connect_accounts_filter_label_charges(),
              type: :select,
              options: [
                {"true", AccrueAdmin.Copy.connect_accounts_filter_option_charges_enabled()},
                {"false", AccrueAdmin.Copy.connect_accounts_filter_option_charges_disabled()}
              ]
            },
            %{
              id: :payouts_enabled,
              label: AccrueAdmin.Copy.connect_accounts_filter_label_payouts(),
              type: :select,
              options: [
                {"true", AccrueAdmin.Copy.connect_accounts_filter_option_payouts_enabled()},
                {"false", AccrueAdmin.Copy.connect_accounts_filter_option_payouts_disabled()}
              ]
            },
            %{
              id: :details_submitted,
              label: AccrueAdmin.Copy.connect_accounts_filter_label_onboarding(),
              type: :select,
              options: [
                {"true", AccrueAdmin.Copy.connect_accounts_filter_option_onboarding_submitted()},
                {"false", AccrueAdmin.Copy.connect_accounts_filter_option_onboarding_pending()}
              ]
            },
            %{
              id: :deauthorized,
              label: AccrueAdmin.Copy.connect_accounts_filter_label_authorization(),
              type: :select,
              options: [
                {"true", AccrueAdmin.Copy.connect_accounts_filter_option_authorization_deauthorized()},
                {"false", AccrueAdmin.Copy.connect_accounts_filter_option_authorization_active()}
              ]
            }
          ]}
          empty_title={AccrueAdmin.Copy.connect_accounts_table_empty_title()}
          empty_copy={AccrueAdmin.Copy.connect_accounts_table_empty_copy()}
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, AccrueAdmin.Copy.connect_accounts_page_title())
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

  defp owner_summary(row),
    do:
      "#{row.owner_type || AccrueAdmin.Copy.connect_accounts_row_owner_fallback()} #{row.owner_id || "--"}"

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
      [] -> AccrueAdmin.Copy.connect_accounts_readiness_needs_onboarding()
      values -> Enum.join(values, AccrueAdmin.Copy.connect_accounts_readiness_joiner())
    end
  end

  defp override_summary(%{id: id}) do
    case Repo.get(Account, id) do
      nil ->
        AccrueAdmin.Copy.connect_accounts_override_default_only()

      account ->
        if has_override?(account),
          do: AccrueAdmin.Copy.connect_accounts_override_saved(),
          else: AccrueAdmin.Copy.connect_accounts_override_default_only()
    end
  end

  defp status_summary(%{deauthorized_at: %DateTime{} = value}),
    do: AccrueAdmin.Copy.connect_accounts_status_deauthorized_prefix() <> format_datetime(value)

  defp status_summary(row) do
    if row.country do
      "#{String.upcase(row.country)} · #{row.email || AccrueAdmin.Copy.connect_accounts_status_no_email()}"
    else
      row.email || AccrueAdmin.Copy.connect_accounts_status_no_email()
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

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
