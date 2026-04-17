if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ClockLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Accrue.Processor.Fake
    alias AccrueAdmin.Components.{AppShell, Breadcrumbs, Button, FlashGroup, KpiCard}

    @advance_options [
      {"Advance 1 hour", 3_600},
      {"Advance 1 day", 86_400},
      {"Advance 3 days", 259_200}
    ]

    @impl true
    def mount(_params, session, socket) do
      admin = Map.get(session, "accrue_admin", %{})

      if fake_processor?() do
        {:ok,
         socket
         |> assign_shell(admin, "/dev/clock", "Dev Clock")
         |> assign(:available?, true)
         |> assign(:flashes, [])
         |> assign_clock()}
      else
        {:ok,
         socket
         |> assign_shell(admin, "/dev/clock", "Dev Clock")
         |> assign(:available?, false)
         |> assign(:flashes, [])}
      end
    end

    @impl true
    def handle_event("advance", %{"seconds" => seconds}, socket) do
      seconds = String.to_integer(seconds)
      :ok = Fake.advance(seconds)

      {:noreply,
       socket
       |> assign_clock()
       |> assign(:flashes, [%{kind: :info, message: "Advanced fake time by #{seconds} seconds."}])}
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
                %{label: "Dev clock"}
              ]}
            />
            <p class="ax-eyebrow">Fake processor controls</p>
            <h2 class="ax-display">Advance the shared non-prod billing clock</h2>
            <p class="ax-body ax-page-copy">
              Uses `Accrue.Processor.Fake.advance/2` so previews and local projections stay aligned
              with the same in-memory clock.
            </p>
          </header>

          <FlashGroup.flash_group flashes={@flashes} />

          <section :if={!@available?} class="ax-card">
            <p class="ax-label">Unavailable</p>
            <p class="ax-body">Dev tools require `Accrue.Processor.Fake` as the configured processor.</p>
          </section>

          <section :if={@available?} class="ax-kpi-grid" aria-label="Fake clock state">
            <KpiCard.kpi_card label="Current fake time" value={@clock_label}>
              <:meta>Derived from `Accrue.Processor.Fake.current_time/1`</:meta>
            </KpiCard.kpi_card>
          </section>

          <section :if={@available?} class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow">Advance clock</p>
              <h3 class="ax-heading">Preset jumps</h3>
            </header>

            <div class="ax-dev-grid">
              <form :for={{label, seconds} <- @advance_options} phx-submit="advance">
                <input type="hidden" name="seconds" value={seconds} />
                <Button.button variant="secondary" type="submit">{label}</Button.button>
              </form>
            </div>
          </section>
        </section>
      </AppShell.app_shell>
      """
    end

    defp assign_clock(socket) do
      assign(
        socket,
        :clock_label,
        Fake.current_time() |> Calendar.strftime("%b %d, %Y %H:%M:%S UTC")
      )
      |> assign(:advance_options, @advance_options)
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
