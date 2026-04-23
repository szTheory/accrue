defmodule AccrueAdmin.Live.ChargesLive do
  @moduledoc false

  import Ecto.Query

  use Phoenix.LiveView

  alias Accrue.Billing.Charge
  alias Accrue.Repo
  alias AccrueAdmin.BillingPresentation
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, KpiCard}
  alias AccrueAdmin.Queries.Charges

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(:table_path, admin_path(admin, "/charges"))
     |> assign(:summary, charge_summary())}
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
              %{label: "Dashboard", href: @admin_mount_path},
              %{label: "Charges"}
            ]}
          />
          <p class="ax-eyebrow">Charges</p>
          <h2 class="ax-display">Payment and refund review</h2>
          <p class="ax-body ax-page-copy">
            Inspect payment fee settlement, jump into charge detail, and start fee-aware refunds
            through the existing billing facade.
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label="Charge summary">
          <KpiCard.kpi_card label="Succeeded" value={Integer.to_string(@summary.succeeded_count)}>
            <:meta>Charges already settled locally</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Fees settled"
            value={Integer.to_string(@summary.fees_settled_count)}
            delta={Integer.to_string(@summary.refund_count) <> " refunds"}
            delta_tone="cobalt"
          >
            <:meta>Stripe fee detail available for refund review</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label="Refunded" value={Integer.to_string(@summary.refunded_count)}>
            <:meta>Charges with at least one refund row</:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="charges"
          query_module={Charges}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          columns={[
            %{label: "Charge", render: &charge_link(&1, @admin_mount_path)},
            %{label: "Customer", render: &customer_link(&1, @admin_mount_path)},
            %{label: "Billing signals", render: &billing_signals_cell/1},
            %{label: "Status", render: &status_summary/1},
            %{label: "Amount", render: &amount_summary/1},
            %{label: "Fees", render: &fee_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Customer", render: &customer_label/1},
            %{label: "Billing signals", render: &billing_signals_cell/1},
            %{label: "Status", render: &status_summary/1},
            %{label: "Amount", render: &amount_summary/1},
            %{label: "Fees", render: &fee_summary/1}
          ]}
          filter_fields={[
            %{id: :q, label: "Search"},
            %{id: :status, label: "Status"},
            %{id: :customer_id, label: "Customer id"},
            %{
              id: :fees_settled,
              label: "Fees settled",
              type: :select,
              options: [{"true", "Yes"}, {"false", "No"}]
            }
          ]}
          empty_title={Copy.charges_index_empty_title()}
          empty_copy={Copy.charges_index_empty_copy()}
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Charges")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/charges"))
  end

  defp charge_summary do
    refunded_charge_ids =
      from(refund in Accrue.Billing.Refund, select: refund.charge_id, distinct: true)
      |> Repo.all()

    %{
      succeeded_count:
        Charge |> where([charge], charge.status == "succeeded") |> Repo.aggregate(:count, :id),
      fees_settled_count:
        Charge
        |> where([charge], not is_nil(charge.fees_settled_at))
        |> Repo.aggregate(:count, :id),
      refund_count: Accrue.Billing.Refund |> Repo.aggregate(:count, :id),
      refunded_count: length(refunded_charge_ids)
    }
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

  defp charge_link(row, mount_path) do
    safe_link("#{mount_path}/charges/#{row.id}", row.processor_id || row.id)
  end

  defp customer_link(row, mount_path) do
    safe_link("#{mount_path}/customers/#{row.customer_id}", customer_label(row))
  end

  defp safe_link(href, label) do
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
  end

  defp customer_label(row), do: row.customer_name || row.customer_email || row.customer_id
  defp status_summary(row), do: humanize(row.status)
  defp card_title(row), do: row.processor_id || row.id

  defp amount_summary(row) do
    format_money(row.amount_cents, row.currency)
  end

  defp fee_summary(row) do
    stripe_fee =
      case row.stripe_fee_amount_minor do
        amount when is_integer(amount) ->
          format_money(amount, row.stripe_fee_currency || row.currency)

        _ ->
          "pending"
      end

    settled = if row.fees_settled_at, do: "settled", else: "unsettled"
    "#{stripe_fee} stripe fee · #{settled}"
  end

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
