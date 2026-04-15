defmodule AccrueAdmin.Live.InvoicesLive do
  @moduledoc false

  import Ecto.Query

  use Phoenix.LiveView

  alias Accrue.Billing.Invoice
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, KpiCard}
  alias AccrueAdmin.Queries.Invoices

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
              %{label: "Invoices"}
            ]}
          />
          <p class="ax-eyebrow">Invoices</p>
          <h2 class="ax-display">Collections and invoice review</h2>
          <p class="ax-body ax-page-copy">
            Inspect invoice state, open detail pages, and route high-risk state changes through
            the shared billing workflow and audit seams.
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label="Invoice summary">
          <KpiCard.kpi_card label="Open" value={Integer.to_string(@summary.open_count)}>
            <:meta>Invoices still collecting payment</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label="Paid" value={Integer.to_string(@summary.paid_count)}>
            <:meta>Settled invoices in the local projection</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Uncollectible"
            value={Integer.to_string(@summary.uncollectible_count)}
            delta={Integer.to_string(@summary.void_count) <> " void"}
            delta_tone="amber"
          >
            <:meta>Operator-driven collection stops</:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="invoices"
          query_module={Invoices}
          path={@table_path}
          params={@params}
          columns={[
            %{label: "Invoice", render: &invoice_link(&1, @admin_mount_path)},
            %{label: "Customer", render: &customer_link(&1, @admin_mount_path)},
            %{label: "Status", render: &status_summary/1},
            %{label: "Balance", render: &balance_summary/1},
            %{id: :collection_method, label: "Collection"}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Customer", render: &customer_label/1},
            %{label: "Status", render: &status_summary/1},
            %{label: "Balance", render: &balance_summary/1},
            %{id: :collection_method, label: "Collection"}
          ]}
          filter_fields={[
            %{id: :q, label: "Search"},
            %{
              id: :status,
              label: "Status",
              type: :select,
              options: [
                {"draft", "Draft"},
                {"open", "Open"},
                {"paid", "Paid"},
                {"uncollectible", "Uncollectible"},
                {"void", "Void"}
              ]
            },
            %{id: :customer_id, label: "Customer id"},
            %{
              id: :collection_method,
              label: "Collection",
              type: :select,
              options: [
                {"charge_automatically", "Automatic"},
                {"send_invoice", "Send invoice"}
              ]
            }
          ]}
          empty_title="No invoices matched"
          empty_copy="Adjust the invoice filters or wait for the next billing cycle."
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Invoices")
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
    "#{due} due · #{paid} paid · #{remaining} remaining"
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

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
