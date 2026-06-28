defmodule AccrueAdmin.Live.ConnectAccountsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Connect.Account
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    DataTable,
    FilterChipBar,
    PageHeader,
    StatStrip
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.ConnectAccounts
  alias AccrueAdmin.ScopedPath

  @default_attention "true"

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(
       :current_path,
       ScopedPath.build(
         admin["mount_path"] || "/billing",
         "/connect",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       ScopedPath.build(
         admin["mount_path"] || "/billing",
         "/connect",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, connect_summary(socket.assigns.current_owner_scope))}
  end

  @impl true
  def handle_event("data_table_filter", params, socket) do
    {:noreply,
     AccrueAdmin.DataTableNav.patch_with_filters(
       socket,
       socket.assigns.table_path,
       Map.drop(params, ["_target", "_csrf_token"])
     )}
  end

  @impl true
  def handle_params(%{"view" => "all"} = params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  def handle_params(params, _uri, socket) do
    if map_size(params) == 0 or map_only_scope?(params) do
      default = build_default_params(socket.assigns[:current_owner_scope], @default_attention)
      to = AccrueAdmin.DataTableNav.merge_query(socket.assigns.table_path, default)

      if connected?(socket) do
        {:noreply, push_patch(socket, to: to)}
      else
        {:noreply, assign(socket, :params, default)}
      end
    else
      {:noreply, assign(socket, :params, params)}
    end
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
        <PageHeader.page_header
          breadcrumbs={[
            %{label: Copy.dashboard_breadcrumb_home(), href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)},
            %{label: Copy.connect_accounts_breadcrumb_connect()}
          ]}
          title={Copy.connect_accounts_list_heading()}
        >
          <:description>
            <p class="ax-body"><%= Copy.connect_accounts_list_subtitle() %></p>
          </:description>

          <:stat_strip>
            <StatStrip.stat_strip label={Copy.connect_accounts_kpi_section_aria_label()}>
              <:stat
                label={Copy.connect_accounts_kpi_label_accounts()}
                value={Integer.to_string(@summary.total_count)}
              />
              <:stat
                label={Copy.connect_accounts_kpi_label_charges_enabled()}
                value={Integer.to_string(@summary.charges_enabled_count)}
                tone="cobalt"
              />
              <:stat
                label={Copy.connect_accounts_kpi_label_overrides()}
                value={Integer.to_string(@summary.override_count)}
                tone="amber"
              />
            </StatStrip.stat_strip>
          </:stat_strip>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="connect-accounts"
              filter_fields={connect_filter_fields()}
              filter_params={filter_params(@params)}
              path={@table_path}
              clear_href={clear_all_href(@params, @table_path)}
              clear_visible={filter_active?(@params)}
            />
          </:filter_toolbar>
        </PageHeader.page_header>

        <.live_component
          module={DataTable}
          id="connect-accounts"
          query_module={ConnectAccounts}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          list_id="connect-accounts"
          list_state={list_state(@params)}
          empty_reason={empty_reason(@params, @summary)}
          loading_fixture={phase197_loading_fixture?(@params)}
          loading_label={Copy.connect_accounts_list_loading_label()}
          render_filter_toolbar={false}
          clear_href={clear_all_href(@params, @table_path)}
          row_label={Copy.connect_accounts_list_result_label_pair()}
          filter_submit_label={Copy.connect_accounts_apply_filters()}
          columns={[
            %{
              label: Copy.connect_accounts_table_column_account(),
              render: &account_link(&1, @admin_mount_path, @current_owner_scope)
            },
            %{label: Copy.connect_accounts_table_column_owner(), render: &owner_summary/1},
            %{label: Copy.connect_accounts_table_column_readiness(), render: &readiness_summary/1},
            %{label: Copy.connect_accounts_table_column_override(), render: &override_summary/1},
            %{label: Copy.connect_accounts_table_column_status(), render: &status_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: Copy.connect_accounts_table_column_owner(), render: &owner_summary/1},
            %{label: Copy.connect_accounts_table_column_readiness(), render: &readiness_summary/1},
            %{label: Copy.connect_accounts_table_column_override(), render: &override_summary/1},
            %{label: Copy.connect_accounts_table_column_status(), render: &status_summary/1}
          ]}
          filter_fields={connect_filter_fields()}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={connect_lens_chips(@params, @table_path)}
              label="Connect account view"
              result_count={status.visible_count}
              result_label={Copy.connect_accounts_list_result_label_pair()}
              clear_all_href={active_clear_all_href(@params, @table_path)}
              clear_all_label={Copy.data_table_clear_filters_label()}
            />
          </:list_status>
        </.live_component>
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, Copy.connect_accounts_page_title())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/connect"))
  end

  defp connect_filter_fields do
    [
      %{
        id: :q,
        label: Copy.connect_accounts_filter_label_search(),
        placeholder: Copy.connect_accounts_filter_label_search()
      },
      %{
        id: :type,
        label: Copy.connect_accounts_filter_label_type(),
        type: :segmented,
        options: [
          {"", "All"},
          {"standard", Copy.connect_accounts_filter_option_type_standard()},
          {"express", Copy.connect_accounts_filter_option_type_express()},
          {"custom", Copy.connect_accounts_filter_option_type_custom()}
        ]
      },
      %{
        id: :charges_enabled,
        label: Copy.connect_accounts_filter_label_charges(),
        type: :segmented,
        options: [
          {"", "All"},
          {"true", Copy.connect_accounts_filter_option_charges_enabled()},
          {"false", Copy.connect_accounts_filter_option_charges_disabled()}
        ]
      },
      %{
        id: :payouts_enabled,
        label: Copy.connect_accounts_filter_label_payouts(),
        type: :segmented,
        options: [
          {"", "All"},
          {"true", Copy.connect_accounts_filter_option_payouts_enabled()},
          {"false", Copy.connect_accounts_filter_option_payouts_disabled()}
        ]
      },
      %{
        id: :details_submitted,
        label: Copy.connect_accounts_filter_label_onboarding(),
        type: :segmented,
        options: [
          {"", "All"},
          {"true", Copy.connect_accounts_filter_option_onboarding_submitted()},
          {"false", Copy.connect_accounts_filter_option_onboarding_pending()}
        ]
      },
      %{
        id: :deauthorized,
        label: Copy.connect_accounts_filter_label_authorization(),
        type: :segmented,
        options: [
          {"", "All"},
          {"true", Copy.connect_accounts_filter_option_authorization_deauthorized()},
          {"false", Copy.connect_accounts_filter_option_authorization_active()}
        ]
      }
    ]
  end

  defp filter_params(params) do
    params
    |> ConnectAccounts.decode_filter()
    |> ConnectAccounts.encode_filter()
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp connect_lens_chips(params, table_path) do
    queue_active? = queue_active?(params)
    all_active? = Map.get(params, "view") == "all"
    clear_href = clear_all_href(params, table_path)

    filter_chips =
      params
      |> filter_params()
      |> Enum.reject(fn {key, value} -> key == "needs_attention" and value == "true" end)
      |> Enum.map(fn {key, value} ->
        %{
          id: String.to_atom(key),
          label: filter_chip_label(key),
          value: filter_chip_value(key, value),
          tone: :slate,
          active: true,
          remove_href:
            AccrueAdmin.DataTableNav.merge_query(table_path, %{
              key => nil,
              "cursor" => nil,
              "phase197_state" => nil
            })
        }
      end)

    [
      %{
        id: :needs_attention,
        label: Copy.connect_accounts_list_default_lens_label(),
        tone: if(queue_active?, do: :cobalt, else: :slate),
        active: true,
        remove_href: if(queue_active?, do: clear_href)
      },
      %{
        id: :all_accounts,
        label: Copy.connect_accounts_list_all_lens_label(),
        tone: if(all_active? and !queue_active?, do: :cobalt, else: :slate),
        active: true,
        href: if(queue_active? or filter_active?(params), do: clear_href)
      }
    ] ++ filter_chips
  end

  defp filter_chip_label("q"), do: Copy.connect_accounts_filter_label_search()
  defp filter_chip_label("type"), do: Copy.connect_accounts_filter_label_type()
  defp filter_chip_label("charges_enabled"), do: Copy.connect_accounts_filter_label_charges()
  defp filter_chip_label("payouts_enabled"), do: Copy.connect_accounts_filter_label_payouts()
  defp filter_chip_label("details_submitted"), do: Copy.connect_accounts_filter_label_onboarding()
  defp filter_chip_label("deauthorized"), do: Copy.connect_accounts_filter_label_authorization()
  defp filter_chip_label("needs_attention"), do: Copy.connect_accounts_list_default_lens_label()
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("charges_enabled", "true"),
    do: Copy.connect_accounts_filter_option_charges_enabled()

  defp filter_chip_value("charges_enabled", "false"),
    do: Copy.connect_accounts_filter_option_charges_disabled()

  defp filter_chip_value("payouts_enabled", "true"),
    do: Copy.connect_accounts_filter_option_payouts_enabled()

  defp filter_chip_value("payouts_enabled", "false"),
    do: Copy.connect_accounts_filter_option_payouts_disabled()

  defp filter_chip_value("details_submitted", "true"),
    do: Copy.connect_accounts_filter_option_onboarding_submitted()

  defp filter_chip_value("details_submitted", "false"),
    do: Copy.connect_accounts_filter_option_onboarding_pending()

  defp filter_chip_value("deauthorized", "true"),
    do: Copy.connect_accounts_filter_option_authorization_deauthorized()

  defp filter_chip_value("deauthorized", "false"),
    do: Copy.connect_accounts_filter_option_authorization_active()

  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => "all",
      "q" => nil,
      "type" => nil,
      "charges_enabled" => nil,
      "payouts_enabled" => nil,
      "details_submitted" => nil,
      "deauthorized" => nil,
      "needs_attention" => nil,
      "cursor" => nil,
      "phase197_state" => nil
    })
  end

  defp filter_active?(params), do: filter_params(params) != %{}

  defp active_clear_all_href(params, table_path) do
    if filter_active?(params), do: clear_all_href(params, table_path)
  end

  defp list_state(params) do
    if phase197_loading_fixture?(params), do: "loading-skeleton", else: nil
  end

  defp empty_reason(params, summary) do
    cond do
      phase197_loading_fixture?(params) -> nil
      first_run_empty?(params, summary) -> "first-run"
      queue_active?(params) -> "queue"
      filter_active?(params) -> "filter"
      true -> nil
    end
  end

  defp empty_title(params, summary) do
    cond do
      first_run_empty?(params, summary) -> Copy.connect_accounts_list_first_run_empty_title()
      queue_active?(params) -> Copy.connect_accounts_list_queue_empty_title()
      filter_active?(params) -> Copy.connect_accounts_list_filtered_empty_title()
      true -> Copy.connect_accounts_list_first_run_empty_title()
    end
  end

  defp empty_copy(params, summary) do
    cond do
      first_run_empty?(params, summary) -> Copy.connect_accounts_list_first_run_empty_body()
      queue_active?(params) -> Copy.connect_accounts_list_queue_empty_body()
      filter_active?(params) -> Copy.connect_accounts_list_filtered_empty_body()
      true -> Copy.connect_accounts_list_first_run_empty_body()
    end
  end

  defp first_run_empty?(params, summary),
    do:
      Map.get(params, "view") == "all" and summary.total_count == 0 and
        !non_lens_filter_active?(params)

  defp non_lens_filter_active?(params) do
    params
    |> filter_params()
    |> Map.drop(["needs_attention"])
    |> Kernel.!=(%{})
  end

  defp queue_active?(params),
    do:
      Map.get(params, "needs_attention") == @default_attention and
        Map.get(params, "view") != "all"

  defp build_default_params(%{mode: :organization, organization_slug: slug}, needs_attention)
       when is_binary(slug) do
    %{"needs_attention" => needs_attention, "org" => slug}
  end

  defp build_default_params(_scope, needs_attention), do: %{"needs_attention" => needs_attention}

  defp phase197_loading_fixture?(params) do
    Application.get_env(:accrue_admin, :env) == :test and
      Map.get(params, "phase197_state") == "loading-skeleton"
  end

  defp connect_summary(owner_scope) do
    accounts = scoped_accounts(owner_scope)

    %{
      total_count: Repo.aggregate(accounts, :count, :id),
      charges_enabled_count:
        accounts
        |> where([account], account.charges_enabled == true)
        |> Repo.aggregate(:count, :id),
      details_submitted_count:
        accounts
        |> where([account], account.details_submitted == true)
        |> Repo.aggregate(:count, :id),
      deauthorized_count:
        accounts
        |> where([account], not is_nil(account.deauthorized_at))
        |> Repo.aggregate(:count, :id),
      override_count:
        accounts
        |> where(
          [account],
          fragment("?->'platform_fee_override' IS NOT NULL", account.data)
        )
        |> Repo.aggregate(:count, :id)
    }
  end

  defp scoped_accounts(%{mode: :organization, organization_id: organization_id}) do
    Account
    |> where(
      [account],
      account.owner_type == "Organization" and account.owner_id == ^organization_id
    )
  end

  defp scoped_accounts(_owner_scope), do: Account

  defp account_link(row, mount_path, owner_scope),
    do:
      safe_link(
        ScopedPath.build(mount_path, "/connect/#{row.id}", owner_scope),
        row.stripe_account_id || row.id
      )

  defp owner_summary(row),
    do: "#{row.owner_type || Copy.connect_accounts_row_owner_fallback()} #{row.owner_id || "--"}"

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
      [] -> Copy.connect_accounts_readiness_needs_onboarding()
      values -> Enum.join(values, Copy.connect_accounts_readiness_joiner())
    end
  end

  defp override_summary(%{id: id}) do
    case Repo.get(Account, id) do
      nil ->
        Copy.connect_accounts_override_default_only()

      account ->
        if has_override?(account),
          do: Copy.connect_accounts_override_saved(),
          else: Copy.connect_accounts_override_default_only()
    end
  end

  defp status_summary(%{deauthorized_at: %DateTime{} = value}),
    do: Copy.connect_accounts_status_deauthorized_prefix() <> format_datetime(value)

  defp status_summary(row) do
    if row.country do
      "#{String.upcase(row.country)} · #{row.email || Copy.connect_accounts_status_no_email()}"
    else
      row.email || Copy.connect_accounts_status_no_email()
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

  defp map_only_scope?(params) do
    params != %{} and Map.keys(params) -- ["org"] == []
  end

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
