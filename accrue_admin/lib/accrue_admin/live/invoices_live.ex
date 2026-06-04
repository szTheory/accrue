defmodule AccrueAdmin.Live.InvoicesLive do
  @moduledoc false

  import Ecto.Query

  use Phoenix.LiveView

  alias Accrue.Billing.Invoice
  alias Accrue.Repo
  alias AccrueAdmin.BillingPresentation
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, FilterChipBar, KpiCard}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Invoices

  @default_queue_status "open,uncollectible"

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(:table_path, admin_path(admin, "/invoices"))
     |> assign(:summary, invoice_summary())}
  end

  @impl true
  def handle_params(%{"view" => "all"} = params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  def handle_params(params, _uri, socket) when map_size(params) == 0 do
    if connected?(socket) do
      default = build_default_params(socket.assigns[:current_owner_scope], @default_queue_status)
      {:noreply, push_patch(socket, to: socket.assigns.table_path <> "?" <> URI.encode_query(default))}
    else
      {:noreply, assign(socket, :params, params)}
    end
  end

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
              %{label: Copy.dashboard_breadcrumb_home(), href: @admin_mount_path},
              %{label: Copy.invoices_index_breadcrumb_invoices()}
            ]}
          />
          <p class="ax-eyebrow"><%= Copy.invoices_index_eyebrow() %></p>
          <h2 class="ax-display"><%= Copy.invoices_index_headline() %></h2>
          <p class="ax-body ax-page-copy">
            <%= Copy.invoices_index_body() %>
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label={Copy.invoices_kpi_section_aria_label()}>
          <KpiCard.kpi_card label={Copy.invoices_kpi_open_label()} value={Integer.to_string(@summary.open_count)}>
            <:meta><%= Copy.invoices_kpi_open_meta() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label={Copy.invoices_kpi_paid_label()} value={Integer.to_string(@summary.paid_count)}>
            <:meta><%= Copy.invoices_kpi_paid_meta() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label={Copy.invoices_kpi_uncollectible_label()}
            value={Integer.to_string(@summary.uncollectible_count)}
            delta={Integer.to_string(@summary.void_count) <> Copy.invoices_kpi_uncollectible_void_delta_suffix()}
            delta_tone="amber"
          >
            <:meta><%= Copy.invoices_kpi_uncollectible_meta() %></:meta>
          </KpiCard.kpi_card>
        </section>

        <FilterChipBar.filter_chip_bar
          items={work_queue_chips(@params, @table_path)}
          label="Work queue"
        />

        <.live_component
          module={DataTable}
          id="invoices"
          query_module={Invoices}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          columns={[
            %{label: Copy.invoices_column_invoice(), render: &invoice_link(&1, @admin_mount_path)},
            %{label: Copy.invoices_column_customer(), render: &customer_link(&1, @admin_mount_path)},
            %{label: Copy.invoices_column_billing_signals(), render: &billing_signals_cell/1},
            %{label: Copy.invoices_column_status(), render: &status_summary/1},
            %{label: Copy.invoices_column_balance(), render: &balance_summary/1},
            %{id: :collection_method, label: Copy.invoices_column_collection()}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: Copy.invoices_card_customer(), render: &customer_label/1},
            %{label: Copy.invoices_column_billing_signals(), render: &billing_signals_cell/1},
            %{label: Copy.invoices_column_status(), render: &status_summary/1},
            %{label: Copy.invoices_column_balance(), render: &balance_summary/1},
            %{id: :collection_method, label: Copy.invoices_column_collection()}
          ]}
          filter_fields={[
            %{id: :q, label: Copy.invoices_filter_search()},
            %{
              id: :status,
              label: Copy.invoices_filter_status(),
              type: :select,
              options: [
                {"draft", Copy.invoices_filter_status_draft()},
                {"open", Copy.invoices_filter_status_open()},
                {"paid", Copy.invoices_filter_status_paid()},
                {"uncollectible", Copy.invoices_filter_status_uncollectible()},
                {"void", Copy.invoices_filter_status_void()}
              ]
            },
            %{id: :customer_id, label: Copy.invoices_filter_customer_id()},
            %{
              id: :collection_method,
              label: Copy.invoices_filter_collection(),
              type: :select,
              options: [
                {"charge_automatically", Copy.invoices_filter_collection_automatic()},
                {"send_invoice", Copy.invoices_filter_collection_send_invoice()}
              ]
            }
          ]}
          empty_title={queue_empty_title(@params)}
          empty_copy={queue_empty_copy(@params)}
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, Copy.invoices_page_title_index())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/invoices"))
  end

  defp invoice_summary do
    %{
      open_count: count_invoices(:open),
      paid_count: count_invoices(:paid),
      uncollectible_count: count_invoices(:uncollectible),
      void_count: count_invoices(:void)
    }
  end

  defp count_invoices(status) do
    Invoice
    |> where([invoice], invoice.status == ^status)
    |> Repo.aggregate(:count, :id)
  end

  defp billing_signals_cell(row) do
    ownership = BillingPresentation.ownership_label(row)
    tax = BillingPresentation.tax_health_label(BillingPresentation.tax_health(row))
    escaped_o = ownership |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    escaped_t = tax |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s(<span class="ax-chip ax-label">#{escaped_o}</span> <span class="ax-chip ax-label">#{escaped_t}</span>)
    )
  end

  defp invoice_link(row, mount_path) do
    safe_link("#{mount_path}/invoices/#{row.id}", row.number || row.processor_id || row.id)
  end

  defp customer_link(row, mount_path) do
    safe_link("#{mount_path}/customers/#{row.customer_id}", customer_label(row))
  end

  defp safe_link(href, label) do
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
  end

  defp customer_label(row), do: row.customer_name || row.customer_email || row.customer_id

  defp status_summary(row) do
    [row.status, row.finalized_at && "finalized", row.due_date && "due"]
    |> Enum.reject(&is_nil/1)
    |> Enum.map_join(" · ", &humanize/1)
  end

  defp balance_summary(row) do
    due = format_money(row.amount_due_minor, row.currency)
    paid = format_money(row.amount_paid_minor, row.currency)
    remaining = format_money(row.amount_remaining_minor, row.currency)
    Copy.invoices_balance_summary(due, paid, remaining)
  end

  defp card_title(row), do: row.number || row.processor_id || row.id

  defp format_money(amount_minor, currency) when is_integer(amount_minor) do
    Accrue.Invoices.Render.format_money(
      amount_minor,
      normalize_currency(currency),
      Accrue.Config.default_locale()
    )
  end

  defp format_money(_amount_minor, _currency), do: "--"

  defp normalize_currency(currency) when is_atom(currency), do: currency

  defp normalize_currency(currency) when is_binary(currency) do
    code = String.downcase(currency)

    try do
      String.to_existing_atom(code)
    rescue
      ArgumentError -> :usd
    end
  end

  defp normalize_currency(_currency), do: :usd

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp work_queue_chips(params, table_path) do
    queue_active = Map.get(params, "status") == @default_queue_status
    all_active = Map.get(params, "view") == "all"

    [
      %{
        id: :status_queue,
        label: "Queue",
        value: "open · uncollectible",
        tone: :cobalt,
        # Always render: when queue is active show it as cobalt; when all-view,
        # still render (active: true) so the user can see and re-apply the queue.
        active: queue_active,
        remove_href: if(queue_active, do: table_path <> "?view=all", else: nil)
      },
      %{
        id: :view_all,
        label: "All",
        tone: :slate,
        # Always render as the escape hatch — visible whenever the queue chip is active
        # OR when the user has explicitly selected all-view.
        active: queue_active or all_active,
        remove_href: if(all_active, do: table_path, else: nil)
      }
    ]
  end

  defp build_default_params(%{mode: :organization, organization_slug: slug}, status)
       when is_binary(slug) do
    %{"status" => status, "org" => slug}
  end

  defp build_default_params(_scope, status), do: %{"status" => status}

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  # Queue-context-aware empty states (IA-03 contract).
  # When the persona work-queue filter is active and returns zero rows, show
  # a task-complete message rather than the generic "no data" copy.
  defp queue_active?(params),
    do: Map.get(params, "status") == @default_queue_status and Map.get(params, "view") != "all"

  defp queue_empty_title(params) do
    if queue_active?(params),
      do: "Queue clear",
      else: Copy.invoices_index_empty_title()
  end

  defp queue_empty_copy(params) do
    if queue_active?(params),
      do: "No open or uncollectible invoices. View All to see every invoice.",
      else: Copy.invoices_index_empty_copy()
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
