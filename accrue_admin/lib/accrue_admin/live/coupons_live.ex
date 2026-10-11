defmodule AccrueAdmin.Live.CouponsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Coupon, PromotionCode}
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    DataTable,
    IdBadge,
    FilterChipBar,
    FlashGroup,
    PageHeader,
    StatStrip
  }

  alias AccrueAdmin.Components.Timestamp

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Coupons

  @default_valid "true"

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
         "/coupons",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/coupons",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :promotion_codes_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/promotion-codes",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, coupon_summary())}
  end

  @impl true
  def handle_event("data_table_filter", params, socket) do
    params = Map.drop(params, ["_target", "_csrf_token"])

    params =
      if Map.get(params, "valid") in [nil, ""] do
        params |> Map.put("valid", nil) |> Map.put("view", "all")
      else
        Map.put(params, "view", nil)
      end

    {:noreply,
     AccrueAdmin.DataTableNav.patch_with_filters(
       socket,
       socket.assigns.table_path,
       params
     )}
  end

  @impl true
  def handle_params(%{"view" => "all"} = params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  def handle_params(params, _uri, socket) do
    if not Map.has_key?(params, "valid") and not Map.has_key?(params, "view") do
      default = build_default_params(socket.assigns[:current_owner_scope], @default_valid)
      default = Map.merge(params, default)
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
      current_owner_scope={assigns[:current_owner_scope]}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <PageHeader.page_header
          breadcrumbs={[
            %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
            %{label: Copy.coupon_breadcrumb_coupons()}
          ]}
          title={Copy.coupons_list_heading()}
        >
          <:description>
            <p class="ax-body"><%= Copy.coupons_list_subtitle() %></p>
            <p class="ax-body">
              <%= Copy.coupon_index_body_link_prefix() %>
              <a href={@promotion_codes_path} class="ax-link"><%= Copy.coupon_index_promotion_codes_link_text() %></a>.
            </p>
          </:description>

          <:stat_strip>
            <StatStrip.stat_strip label={Copy.coupon_index_kpi_section_aria_label()}>
              <:stat label={Copy.coupon_kpi_label_coupons()} value={Integer.to_string(@summary.total_count)} />
              <:stat
                label={Copy.coupon_kpi_label_valid()}
                value={Integer.to_string(@summary.valid_count)}
                tone="amber"
              />
              <:stat
                label={Copy.coupon_kpi_label_promotion_codes()}
                value={Integer.to_string(@summary.promotion_code_count)}
                tone="cobalt"
              />
            </StatStrip.stat_strip>
          </:stat_strip>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="coupons"
              filter_fields={coupon_filter_fields()}
              filter_params={filter_params(@params)}
              path={@table_path}
              clear_href={clear_all_href(@params, @table_path)}
              clear_visible={filter_active?(@params)}
            />
          </:filter_toolbar>
        </PageHeader.page_header>

        <FlashGroup.flash_group flashes={flash_messages(@flash)} />

        <.live_component
          module={DataTable}
          id="coupons"
          query_module={Coupons}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          list_id="coupons"
          list_state={list_state(@params)}
          empty_reason={empty_reason(@params, @summary)}
          loading_fixture={phase197_loading_fixture?(@params)}
          loading_label={list_state_copy(:loading).heading}
          render_filter_toolbar={false}
          clear_href={clear_all_href(@params, @table_path)}
          columns={[
            %{label: Copy.coupon_table_column_coupon(), render: &coupon_link(&1, @admin_mount_path, @current_owner_scope, @params, :table)},
            %{label: Copy.coupon_table_column_status(), render: &status_summary/1},
            %{label: Copy.coupon_table_column_discount(), render: &discount_summary/1},
            %{label: Copy.coupon_table_column_redeem_by(), render: &redeem_by_summary(&1, :table)},
            %{label: Copy.coupon_table_column_redemptions(), render: &redemption_summary/1}
          ]}
          card_title={&coupon_link(&1, @admin_mount_path, @current_owner_scope, @params, :card)}
          card_fields={[
            %{label: Copy.coupon_table_column_status(), render: &status_summary/1},
            %{label: Copy.coupon_table_column_discount(), render: &discount_summary/1},
            %{label: Copy.coupon_table_column_redeem_by(), render: &redeem_by_summary(&1, :card)},
            %{label: Copy.coupon_table_column_redemptions(), render: &redemption_summary/1}
          ]}
          filter_fields={coupon_filter_fields()}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={coupon_lens_chips(@params, @table_path)}
              label="Coupon view"
              result_count={status.visible_count}
              result_label={Copy.coupons_list_result_label_pair()}
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
    |> assign(:page_title, Copy.coupon_page_title_index())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/coupons"))
  end

  defp coupon_summary do
    %{
      total_count: Repo.aggregate(Coupon, :count, :id),
      valid_count: Coupon |> where([coupon], coupon.valid == true) |> Repo.aggregate(:count, :id),
      invalid_count:
        Coupon |> where([coupon], coupon.valid == false) |> Repo.aggregate(:count, :id),
      promotion_code_count: Repo.aggregate(PromotionCode, :count, :id),
      redeemed_count:
        Coupon
        |> select([coupon], coalesce(sum(coupon.times_redeemed), 0))
        |> Repo.one()
        |> Kernel.||(0)
    }
  end

  defp coupon_link(row, mount_path, owner_scope, params, presentation) do
    label = coupon_label(row)
    return_to = coupon_return_path(mount_path, owner_scope, params)

    href =
      AccrueAdmin.ScopedPath.build(mount_path, "/coupons/#{row.id}", owner_scope, %{
        "return_to" => return_to
      })

    assigns = %{
      __changed__: %{},
      href: href,
      label: label,
      badge_id: "ax-id-badge-coupon-#{row.id}#{if presentation == :card, do: "-card", else: ""}",
      id_value: row.processor_id || to_string(row.id)
    }

    ~H"""
    <DataTable.identity_cell>
      <:primary><.link href={@href} class="ax-link"><%= @label %></.link></:primary>
      <:secondary><IdBadge.id_badge id={@badge_id} id_value={@id_value} label="Copy coupon ID" /></:secondary>
    </DataTable.identity_cell>
    """
  end

  defp coupon_return_path(mount_path, owner_scope, params) do
    filters = filter_params(params)
    view = Map.take(params, ["view"])

    AccrueAdmin.ScopedPath.build(mount_path, "/coupons", owner_scope, Map.merge(filters, view))
  end

  defp coupon_label(row), do: row.name || row.processor_id || row.id

  defp discount_summary(%{amount_off_minor: amount, currency: currency})
       when is_integer(amount) and amount > 0,
       do: format_minor(amount, currency)

  defp discount_summary(%{amount_off_cents: amount, currency: currency})
       when is_integer(amount) and amount > 0,
       do: format_minor(amount, currency)

  defp discount_summary(%{percent_off: %Decimal{} = percent}),
    do: Decimal.to_string(percent, :normal) <> "% off"

  defp discount_summary(_row), do: Copy.coupon_discount_processor_defined()

  defp redemption_summary(row) do
    case row.times_redeemed do
      used when is_integer(used) -> Integer.to_string(used)
      _ -> Copy.Coupon.coupon_redemptions_unknown()
    end
  end

  defp status_summary(%{valid: true}), do: Copy.coupon_status_valid()
  defp status_summary(%{valid: false}), do: Copy.coupon_status_invalid()
  defp status_summary(_row), do: Copy.Coupon.coupon_unknown_value()

  defp redeem_by_summary(%{redeem_by: %DateTime{} = value} = row, presentation),
    do: timestamp_value(value, "coupon-row-redeem-by-#{presentation}-#{row.id}")

  defp redeem_by_summary(_row, _presentation), do: Copy.coupon_redeem_by_no_expiry()

  defp coupon_filter_fields do
    [
      %{
        id: :q,
        label: Copy.coupon_filter_label_search(),
        placeholder: Copy.coupon_filter_label_search()
      },
      %{
        id: :valid,
        label: Copy.coupon_filter_label_validity(),
        type: :segmented,
        options: [
          {"", "All"},
          {"true", Copy.coupon_filter_option_valid()},
          {"false", Copy.coupon_filter_option_invalid()}
        ]
      }
    ]
  end

  defp filter_params(params) do
    params
    |> Coupons.decode_filter()
    |> Coupons.encode_filter()
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp coupon_lens_chips(params, table_path) do
    filter_chips =
      params
      |> filter_params()
      |> Enum.reject(fn {key, value} -> key == "valid" and value == @default_valid end)
      |> Enum.map(fn {key, value} ->
        %{
          id: String.to_atom(key),
          label: filter_chip_label(key),
          value: filter_chip_value(key, value),
          tone: :slate,
          active: true,
          remove_href: AccrueAdmin.DataTableNav.merge_query(table_path, %{key => nil})
        }
      end)

    filter_chips
  end

  defp filter_chip_label("q"), do: Copy.coupon_filter_label_search()
  defp filter_chip_label("valid"), do: Copy.coupon_filter_label_validity()
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("valid", "true"), do: Copy.coupon_filter_option_valid()
  defp filter_chip_value("valid", "false"), do: Copy.coupon_filter_option_invalid()
  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => "all",
      "q" => nil,
      "valid" => nil,
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
      default_valid_active?(params) -> "queue"
      filter_active?(params) -> "filter"
      true -> nil
    end
  end

  defp empty_title(params, summary) do
    params
    |> empty_state(summary)
    |> list_state_copy()
    |> Map.fetch!(:heading)
  end

  defp empty_copy(params, summary) do
    params
    |> empty_state(summary)
    |> list_state_copy()
    |> Map.fetch!(:body)
  end

  defp empty_state(params, summary) do
    cond do
      first_run_empty?(params, summary) -> :first_run_empty
      default_valid_active?(params) -> :queue_empty
      filter_active?(params) -> :filtered_empty
      true -> :first_run_empty
    end
  end

  defp list_state_copy(state), do: Copy.resource_state_copy(:coupons, state)

  defp first_run_empty?(params, summary),
    do: Map.get(params, "view") == "all" and summary.total_count == 0 and !filter_active?(params)

  defp default_valid_active?(params),
    do: Map.get(params, "valid") == @default_valid and Map.get(params, "view") != "all"

  defp build_default_params(%{mode: :organization, organization_slug: slug}, valid)
       when is_binary(slug) do
    %{"valid" => valid, "org" => slug}
  end

  defp build_default_params(_scope, valid), do: %{"valid" => valid}

  defp phase197_loading_fixture?(params) do
    Application.get_env(:accrue_admin, :env) == :test and
      Map.get(params, "phase197_state") == "loading-skeleton"
  end

  defp flash_messages(flash) do
    Enum.flat_map([:error, :info], fn kind ->
      case Phoenix.Flash.get(flash, kind) do
        nil -> []
        message -> [%{kind: kind, message: message}]
      end
    end)
  end

  defp format_minor(amount_minor, currency) when is_integer(amount_minor) do
    dollars = amount_minor / 100
    code = currency |> to_string() |> String.upcase()
    :erlang.float_to_binary(dollars, decimals: 2) <> " " <> code
  end

  defp timestamp_value(value, id) do
    assigns = %{value: value, id: id}

    ~H"""
    <Timestamp.timestamp value={@value} id={@id} />
    """
  end

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp scoped_path(mount_path, suffix, %{mode: :organization, organization_slug: slug})
       when is_binary(slug) do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_path(mount_path, suffix, _owner_scope), do: mount_path <> suffix

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
