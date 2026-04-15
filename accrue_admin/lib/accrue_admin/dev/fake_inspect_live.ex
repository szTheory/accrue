if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.FakeInspectLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Accrue.Processor.Fake
    alias AccrueAdmin.Components.{AppShell, Breadcrumbs, JsonViewer, KpiCard}

    @impl true
    def mount(_params, session, socket) do
      admin = Map.get(session, "accrue_admin", %{})

      if fake_processor?() do
        {:ok,
         socket
         |> assign_shell(admin, "/dev/fake-inspect", "Fake Inspect")
         |> assign(:available?, true)
         |> assign_snapshot()}
      else
        {:ok,
         socket
         |> assign_shell(admin, "/dev/fake-inspect", "Fake Inspect")
         |> assign(:available?, false)}
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
      >
        <section class="ax-page">
          <header class="ax-page-header">
            <Breadcrumbs.breadcrumbs
              items={[
                %{label: "Dashboard", href: @admin_mount_path},
                %{label: "Fake inspect"}
              ]}
            />
            <p class="ax-eyebrow">State inspection</p>
            <h2 class="ax-display">Inspect live Fake processor state from the package</h2>
          </header>

          <section :if={!@available?} class="ax-card">
            <p class="ax-label">Unavailable</p>
            <p class="ax-body">Dev tools require `Accrue.Processor.Fake` as the configured processor.</p>
          </section>

          <section :if={@available?} class="ax-kpi-grid" aria-label="Fake resource counts">
            <KpiCard.kpi_card label="Customers" value={Integer.to_string(length(@snapshot.customers))}>
              <:meta>Platform-scoped fake customers</:meta>
            </KpiCard.kpi_card>
            <KpiCard.kpi_card label="Subscriptions" value={Integer.to_string(length(@snapshot.subscriptions))}>
              <:meta>Platform-scoped fake subscriptions</:meta>
            </KpiCard.kpi_card>
            <KpiCard.kpi_card label="Charges" value={Integer.to_string(length(@snapshot.charges))}>
              <:meta>Platform-scoped fake charges</:meta>
            </KpiCard.kpi_card>
          </section>

          <section :if={@available?} class="ax-card">
            <JsonViewer.json_viewer id="fake-inspect-json" payload={@snapshot} active_tab="tree" />
          </section>
        </section>
      </AppShell.app_shell>
      """
    end

    defp assign_snapshot(socket) do
      assign(socket, :snapshot, %{
        clock: Fake.current_time(),
        customers: Fake.customers_on(:platform),
        subscriptions: Fake.subscriptions_on(:platform),
        charges: Fake.charges_on(:platform),
        transfers: Fake.transfers_on(:platform)
      })
    end

    defp assign_shell(socket, admin, path, title) do
      socket
      |> assign(:page_title, title)
      |> assign(:brand, admin["brand"] || default_brand())
      |> assign(:theme, admin["theme"] || "system")
      |> assign(:csp_nonce, admin["csp_nonce"])
      |> assign(:brand_css_path, admin["brand_css_path"])
      |> assign(:assets_css_path, admin["assets_css_path"])
      |> assign(:assets_js_path, admin["assets_js_path"])
      |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
      |> assign(:current_path, (admin["mount_path"] || "/billing") <> path)
    end

    defp fake_processor? do
      Application.get_env(:accrue, :processor, Accrue.Processor.Fake) == Accrue.Processor.Fake
    end

    defp default_brand do
      %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
    end
  end
end
