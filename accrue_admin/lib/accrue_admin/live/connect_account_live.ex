defmodule AccrueAdmin.Live.ConnectAccountLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Auth, Config, Connect, Events, Money}
  alias Accrue.Connect.Account
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, FlashGroup, KpiCard}

  @default_preview_amount_minor 10_000
  @default_preview_currency "usd"

  @impl true
  def mount(%{"id" => account_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Repo.get(Account, account_id) do
      nil ->
        {:ok, redirect(socket, to: admin_path(admin, "/connect"))}

      account ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign_account(account)
         |> assign(:flashes, [])}
    end
  end

  @impl true
  def handle_event("validate_override", %{"override" => params}, socket) do
    {:noreply, apply_override_preview(socket, params)}
  end

  def handle_event("save_override", %{"override" => params}, socket) do
    socket = apply_override_preview(socket, params)

    case socket.assigns.override_preview do
      %{error: nil, override_payload: override_payload} ->
        account = socket.assigns.account
        data = merged_data(account, override_payload)

        case account |> Account.changeset(%{data: data}) |> Repo.update() do
          {:ok, updated_account} ->
            socket =
              socket
              |> record_override_update(updated_account, override_payload)
              |> assign_account(updated_account)
              |> assign(:flashes, [%{kind: :info, message: AccrueAdmin.Copy.connect_account_flash_override_saved()}])

            {:noreply, socket}

          {:error, changeset} ->
            {:noreply,
             assign(socket, :override_preview, %{
               socket.assigns.override_preview
               | error: humanize_changeset_errors(changeset)
             })}
        end

      %{error: error} ->
        {:noreply, socket |> assign(:flashes, [%{kind: :error, message: error}])}
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
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: AccrueAdmin.Copy.dashboard_breadcrumb_home(), href: @admin_mount_path},
              %{label: AccrueAdmin.Copy.connect_account_breadcrumb_connect(), href: @admin_mount_path <> "/connect"},
              %{label: @account.stripe_account_id || @account.id}
            ]}
          />
          <p class="ax-eyebrow"><%= AccrueAdmin.Copy.connect_account_eyebrow() %></p>
          <h2 class="ax-display"><%= @account.stripe_account_id %></h2>
          <p class="ax-body ax-page-copy">
            <%= @account.type |> humanize() %> · <%= owner_summary(@account) %> ·
            <%= account_status(@account) %>
          </p>
        </header>

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-kpi-grid" aria-label={AccrueAdmin.Copy.connect_account_kpi_section_aria_label()}>
          <KpiCard.kpi_card label={AccrueAdmin.Copy.connect_account_kpi_label_charges()} value={enabled_label(@account.charges_enabled)}>
            <:meta><%= AccrueAdmin.Copy.connect_account_kpi_meta_payouts_prefix() %><%= enabled_label(@account.payouts_enabled) %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label={AccrueAdmin.Copy.connect_account_kpi_label_onboarding()} value={enabled_label(@account.details_submitted)}>
            <:meta><%= AccrueAdmin.Copy.connect_account_kpi_meta_country_prefix() %><%= @account.country || "--" %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label={AccrueAdmin.Copy.connect_account_kpi_label_override()} value={override_state_label(@account)}>
            <:meta><%= AccrueAdmin.Copy.connect_account_kpi_meta_default_policy_prefix() %><%= describe_config(@default_fee_config) %></:meta>
          </KpiCard.kpi_card>
        </section>

        <section class="ax-grid ax-grid-2">
          <article class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow"><%= AccrueAdmin.Copy.connect_account_section_capabilities_eyebrow() %></p>
              <h3 class="ax-heading"><%= AccrueAdmin.Copy.connect_account_section_capabilities_heading() %></h3>
            </header>

            <div class="ax-page">
              <p class="ax-body"><%= AccrueAdmin.Copy.connect_account_detail_label_owner() %> <%= owner_summary(@account) %></p>
              <p class="ax-body"><%= AccrueAdmin.Copy.connect_account_detail_label_email() %> <%= @account.email || "--" %></p>
              <p class="ax-body"><%= AccrueAdmin.Copy.connect_account_detail_label_capabilities() %> <%= capabilities_summary(@account.capabilities) %></p>
              <p class="ax-body"><%= AccrueAdmin.Copy.connect_account_detail_label_requirements() %> <%= requirements_summary(@account.requirements) %></p>
            </div>
          </article>

          <article class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow"><%= AccrueAdmin.Copy.connect_account_section_effective_fee_eyebrow() %></p>
              <h3 class="ax-heading"><%= AccrueAdmin.Copy.connect_account_section_effective_fee_heading() %></h3>
            </header>

            <div class="ax-page">
              <p class="ax-body"><%= AccrueAdmin.Copy.connect_account_detail_label_stored_override() %> <%= describe_override(@account) %></p>
              <p class="ax-body"><%= AccrueAdmin.Copy.connect_account_detail_label_preview_gross() %> <%= preview_gross_summary(@override_preview.form) %></p>
              <p class="ax-body"><%= AccrueAdmin.Copy.connect_account_detail_label_computed_fee() %> <%= @override_preview.fee_label %></p>
              <p :if={@override_preview.error} class="ax-body"><%= @override_preview.error %></p>
            </div>
          </article>
        </section>

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow"><%= AccrueAdmin.Copy.connect_account_section_platform_fee_eyebrow() %></p>
            <h3 class="ax-heading"><%= AccrueAdmin.Copy.connect_account_section_platform_fee_heading() %></h3>
            <p class="ax-body">
              <%= AccrueAdmin.Copy.connect_account_section_platform_fee_body() %>
            </p>
          </header>

          <form phx-change="validate_override" phx-submit="save_override">
            <div class="ax-grid ax-grid-2">
              <label class="ax-label">
                <%= AccrueAdmin.Copy.connect_account_label_percent() %>
                <input
                  type="text"
                  name="override[percent]"
                  value={@override_preview.form["percent"]}
                  class="ax-input"
                />
              </label>

              <label class="ax-label">
                <%= AccrueAdmin.Copy.connect_account_label_fixed_minor_units() %>
                <input
                  type="text"
                  name="override[fixed_cents]"
                  value={@override_preview.form["fixed_cents"]}
                  class="ax-input"
                />
              </label>

              <label class="ax-label">
                <%= AccrueAdmin.Copy.connect_account_label_min_minor_units() %>
                <input
                  type="text"
                  name="override[min_cents]"
                  value={@override_preview.form["min_cents"]}
                  class="ax-input"
                />
              </label>

              <label class="ax-label">
                <%= AccrueAdmin.Copy.connect_account_label_max_minor_units() %>
                <input
                  type="text"
                  name="override[max_cents]"
                  value={@override_preview.form["max_cents"]}
                  class="ax-input"
                />
              </label>

              <label class="ax-label">
                <%= AccrueAdmin.Copy.connect_account_label_preview_gross_minor_units() %>
                <input
                  type="text"
                  name="override[preview_amount_minor]"
                  value={@override_preview.form["preview_amount_minor"]}
                  class="ax-input"
                />
              </label>

              <label class="ax-label">
                <%= AccrueAdmin.Copy.connect_account_label_preview_currency() %>
                <input
                  type="text"
                  name="override[preview_currency]"
                  value={@override_preview.form["preview_currency"]}
                  class="ax-input"
                />
              </label>
            </div>

            <div class="ax-page-header">
              <button type="submit" class="ax-button ax-button-primary" data-role="save-override">
                <%= AccrueAdmin.Copy.connect_account_save_platform_fee_override() %>
              </button>
            </div>
          </form>
        </section>
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, AccrueAdmin.Copy.connect_account_page_title())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/connect"))
  end

  defp assign_account(socket, account) do
    form = override_form(account)

    socket
    |> assign(:account, account)
    |> assign(:default_fee_config, default_fee_config())
    |> assign(:override_preview, preview_override(form))
  end

  defp apply_override_preview(socket, params) do
    assign(socket, :override_preview, preview_override(normalize_override_form(params)))
  end

  defp record_override_update(socket, account, override_payload) do
    current_admin = socket.assigns.current_admin

    {:ok, _event} =
      Events.record(%{
        type: "admin.connect.platform_fee_override.updated",
        subject_type: "ConnectAccount",
        subject_id: account.id,
        actor_type: "admin",
        actor_id: Auth.actor_id(current_admin),
        data: %{
          "stripe_account_id" => account.stripe_account_id,
          "platform_fee_override" => override_payload
        }
      })

    :ok =
      Auth.log_audit(current_admin, %{
        type: "admin.connect.platform_fee_override.updated",
        connect_account_id: account.id,
        source: :accrue_admin
      })

    socket
  end

  defp default_fee_config do
    Config.get!(:connect)
    |> Keyword.get(:platform_fee, [])
  end

  defp override_form(account) do
    override = platform_fee_override(account)

    normalize_override_form(%{
      "percent" => override["percent"] || "",
      "fixed_cents" => override["fixed_cents"] || "",
      "min_cents" => override["min_cents"] || "",
      "max_cents" => override["max_cents"] || "",
      "preview_amount_minor" => Integer.to_string(@default_preview_amount_minor),
      "preview_currency" => @default_preview_currency
    })
  end

  defp normalize_override_form(params) do
    %{
      "percent" => normalize_string(Map.get(params, "percent")),
      "fixed_cents" => normalize_string(Map.get(params, "fixed_cents")),
      "min_cents" => normalize_string(Map.get(params, "min_cents")),
      "max_cents" => normalize_string(Map.get(params, "max_cents")),
      "preview_amount_minor" =>
        normalize_string(Map.get(params, "preview_amount_minor")) ||
          Integer.to_string(@default_preview_amount_minor),
      "preview_currency" =>
        normalize_string(Map.get(params, "preview_currency")) || @default_preview_currency
    }
  end

  defp preview_override(form) do
    with {:ok, override_payload, opts} <- override_opts(form),
         {:ok, gross} <- preview_gross(form),
         {:ok, fee} <- Connect.platform_fee(gross, opts) do
      %{
        form: form,
        error: nil,
        fee_label: Money.to_string(fee),
        override_payload: override_payload
      }
    else
      {:error, reason} ->
        %{
          form: form,
          error: reason,
          fee_label: AccrueAdmin.Copy.connect_account_preview_fee_unable(),
          override_payload: %{}
        }
    end
  end

  defp override_opts(form) do
    with {:ok, percent, payload} <- maybe_decimal(form, "percent", "percent"),
         {:ok, fixed, payload} <- maybe_money(form, "fixed_cents", "fixed_cents", payload),
         {:ok, min, payload} <- maybe_money(form, "min_cents", "min_cents", payload),
         {:ok, max, payload} <- maybe_money(form, "max_cents", "max_cents", payload) do
      opts =
        []
        |> put_if_present(:percent, percent)
        |> put_if_present(:fixed, fixed)
        |> put_if_present(:min, min)
        |> put_if_present(:max, max)

      {:ok, payload, opts}
    end
  end

  defp maybe_decimal(form, key, payload_key) do
    label = override_field_label(key)

    case Map.get(form, key) do
      nil ->
        {:ok, nil, %{}}

      value ->
        try do
          decimal = Decimal.new(value)
          {:ok, decimal, %{payload_key => value}}
        rescue
          _ ->
            {:error, AccrueAdmin.Copy.connect_account_error_field_must_be_decimal(label)}
        end
    end
  end

  defp maybe_money(form, key, payload_key, payload) do
    label = override_field_label(key)

    case Map.get(form, key) do
      nil ->
        {:ok, nil, payload}

      value ->
        case Integer.parse(value) do
          {amount_minor, ""} ->
            with {:ok, currency} <- preview_currency(form) do
              {:ok, Money.new(amount_minor, currency), Map.put(payload, payload_key, value)}
            end

          _ ->
            {:error, AccrueAdmin.Copy.connect_account_error_field_must_be_integer_minor(label)}
        end
    end
  end

  defp override_field_label("percent"), do: AccrueAdmin.Copy.connect_account_label_percent()
  defp override_field_label("fixed_cents"), do: AccrueAdmin.Copy.connect_account_label_fixed_minor_units()
  defp override_field_label("min_cents"), do: AccrueAdmin.Copy.connect_account_label_min_minor_units()
  defp override_field_label("max_cents"), do: AccrueAdmin.Copy.connect_account_label_max_minor_units()

  defp preview_gross(form) do
    with {amount_minor, ""} <- Integer.parse(form["preview_amount_minor"]),
         {:ok, currency} <- preview_currency(form) do
      {:ok, Money.new(amount_minor, currency)}
    else
      :error ->
        {:error, AccrueAdmin.Copy.connect_account_error_preview_amount_invalid()}

      {:error, _} = error ->
        error

      _ ->
        {:error, AccrueAdmin.Copy.connect_account_error_preview_amount_invalid()}
    end
  end

  defp preview_currency(form) do
    currency =
      form["preview_currency"]
      |> String.downcase()

    try do
      {:ok, String.to_existing_atom(currency)}
    rescue
      ArgumentError -> {:error, AccrueAdmin.Copy.connect_account_error_preview_currency_unknown()}
    end
  end

  defp merged_data(account, override_payload) do
    account.data
    |> Kernel.||(%{})
    |> case do
      data when map_size(override_payload) == 0 -> Map.delete(data, "platform_fee_override")
      data -> Map.put(data, "platform_fee_override", override_payload)
    end
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

  defp override_state_label(account) do
    if map_size(platform_fee_override(account)) > 0,
      do: AccrueAdmin.Copy.connect_account_override_state_saved(),
      else: AccrueAdmin.Copy.connect_account_override_state_default_only()
  end

  defp describe_override(account) do
    case platform_fee_override(account) do
      override when map_size(override) == 0 ->
        AccrueAdmin.Copy.connect_account_override_state_no_override_saved()

      override ->
        describe_override_payload(override)
    end
  end

  defp describe_override_payload(override) do
    [
      override["percent"] && "#{override["percent"]}% percent",
      override["fixed_cents"] && "#{override["fixed_cents"]} fixed",
      override["min_cents"] && "#{override["min_cents"]} min",
      override["max_cents"] && "#{override["max_cents"]} max"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp describe_config(config) do
    payload = %{}

    payload =
      if config[:percent],
        do: Map.put(payload, "percent", Decimal.to_string(config[:percent], :normal)),
        else: payload

    payload =
      if config[:fixed],
        do: Map.put(payload, "fixed_cents", Integer.to_string(config[:fixed].amount_minor)),
        else: payload

    payload =
      if config[:min],
        do: Map.put(payload, "min_cents", Integer.to_string(config[:min].amount_minor)),
        else: payload

    payload =
      if config[:max],
        do: Map.put(payload, "max_cents", Integer.to_string(config[:max].amount_minor)),
        else: payload

    describe_override_payload(payload)
  end

  defp preview_gross_summary(form) do
    case preview_gross(form) do
      {:ok, gross} -> Money.to_string(gross)
      {:error, _} -> AccrueAdmin.Copy.connect_account_preview_gross_invalid()
    end
  end

  defp owner_summary(account),
    do: "#{account.owner_type || AccrueAdmin.Copy.connect_accounts_row_owner_fallback()} #{account.owner_id || "--"}"

  defp account_status(%{deauthorized_at: %DateTime{} = value}),
    do: AccrueAdmin.Copy.connect_account_status_deauthorized_prefix() <> format_datetime(value)

  defp account_status(_account), do: AccrueAdmin.Copy.connect_account_status_active_authorization()

  defp enabled_label(true), do: AccrueAdmin.Copy.connect_account_enabled_label_true()
  defp enabled_label(false), do: AccrueAdmin.Copy.connect_account_enabled_label_false()
  defp enabled_label(nil), do: AccrueAdmin.Copy.connect_account_enabled_label_unknown()

  defp capabilities_summary(capabilities)
       when is_map(capabilities) and map_size(capabilities) > 0 do
    capabilities
    |> Enum.map(fn {key, value} -> "#{key}=#{inspect(value)}" end)
    |> Enum.join(", ")
  end

  defp capabilities_summary(_capabilities), do: AccrueAdmin.Copy.connect_account_capabilities_none()

  defp requirements_summary(requirements)
       when is_map(requirements) and map_size(requirements) > 0 do
    [
      requirements["disabled_reason"] || requirements[:disabled_reason],
      requirement_list(requirements["currently_due"] || requirements[:currently_due])
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp requirements_summary(_requirements), do: AccrueAdmin.Copy.connect_account_requirements_none()

  defp requirement_list(list) when is_list(list) and list != [],
    do: AccrueAdmin.Copy.connect_account_requirements_currently_due_prefix() <> Enum.join(list, ", ")

  defp requirement_list(_), do: nil

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")

  defp normalize_string(nil), do: nil

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp put_if_present(opts, _key, nil), do: opts
  defp put_if_present(opts, key, value), do: Keyword.put(opts, key, value)

  defp humanize_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _meta}} -> "#{field} #{message}" end)
    |> Enum.join(", ")
  end

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
