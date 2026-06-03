if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentKitchenLive do
    @moduledoc false

    use Phoenix.LiveView

    alias AccrueAdmin.Components.{
      AppShell,
      Breadcrumbs,
      Button,
      Detail,
      FlashGroup,
      Icon,
      KpiCard,
      RelatedResources,
      StatusBadge,
      Tabs
    }

    @impl true
    def mount(_params, session, socket) do
      admin = Map.get(session, "accrue_admin", %{})

      if fake_processor?() do
        {:ok,
         socket
         |> assign_shell(admin, "/dev/components", "Component Kitchen")
         |> assign(:available?, true)
         |> assign(:flashes, [
           %{
             kind: :info,
             message: "Previewing shared admin components against the shipped package CSS."
           }
         ])}
      else
        {:ok,
         socket
         |> assign_shell(admin, "/dev/components", "Component Kitchen")
         |> assign(:available?, false)
         |> assign(:flashes, [])}
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
                %{label: "Dashboard", href: @admin_mount_path},
                %{label: "Component kitchen"}
              ]}
            />
            <p class="ax-eyebrow">Shared primitives</p>
            <h2 class="ax-display">One dev page to sanity-check the admin component layer</h2>
          </header>

          <FlashGroup.flash_group flashes={@flashes} />

          <section :if={!@available?} class="ax-card">
            <p class="ax-label">Unavailable</p>
            <p class="ax-body">Dev tools require `Accrue.Processor.Fake` as the configured processor.</p>
          </section>

          <section :if={@available?} class="ax-kpi-grid">
            <KpiCard.kpi_card label="Primary KPI" value="$42.00" delta="healthy" delta_tone="moss">
              <:meta>Sample money formatting in the packaged shell</:meta>
            </KpiCard.kpi_card>
            <KpiCard.kpi_card label="Queued jobs" value="7" delta="needs review" delta_tone="amber">
              <:meta>Visual check for operator-heavy status cards</:meta>
            </KpiCard.kpi_card>
          </section>

          <section :if={@available?} class="ax-card ax-dev-stack">
            <Tabs.tabs
              active="components"
              tabs={[
                %{id: "overview", label: "Overview", href: @admin_mount_path},
                %{id: "components", label: "Components", href: @current_path, count: 8}
              ]}
            />

            <div class="ax-dev-grid">
              <Button.button variant="primary" type="button">Primary action</Button.button>
              <Button.button variant="secondary" type="button">Secondary action</Button.button>
              <Button.button variant="ghost" href={@admin_mount_path <> "/webhooks"}>Ghost link</Button.button>
            </div>

            <div class="ax-dev-grid">
              <StatusBadge.status_badge status={:paid} />
              <StatusBadge.status_badge status={:past_due} />
              <StatusBadge.status_badge status={:failed} />
            </div>
          </section>

          <%!-- Icon gallery (every glyph in the inline icon set) --%>
          <section :if={@available?} class="ax-card ax-dev-stack">
            <p class="ax-label">Icons (AccrueAdmin.Components.Icon)</p>
            <div class="ax-dev-grid">
              <span :for={name <- Icon.names()} title={to_string(name)}>
                <Icon.icon name={name} size="md" />
              </span>
            </div>
          </section>

          <%!-- Detail skeleton: summary card + section + field list --%>
          <section :if={@available?} class="ax-dev-stack">
            <Detail.summary_card eyebrow="Component kitchen" title="sub_demo_00042">
              <:status><StatusBadge.status_badge status={:active} /></:status>
              <:facts>
                <span>$42.00 / month</span>
                <span>Acme Corp</span>
                <span>Started Jan 1, 2026</span>
              </:facts>
              <:actions>
                <Button.button variant="secondary" type="button">Manage</Button.button>
              </:actions>
            </Detail.summary_card>

            <Detail.detail_section title="Key fields">
              <Detail.detail_field_list fields={[
                %{label: "Status", value: "Active"},
                %{label: "Amount", value: "$42.00"},
                %{label: "Customer", value: "Acme Corp"},
                %{label: "Next invoice", value: "Feb 1, 2026"}
              ]} />
            </Detail.detail_section>
          </section>

          <%!-- Related-resources card + empty state --%>
          <section :if={@available?} class="ax-dev-stack">
            <RelatedResources.related_resources items={[
              %{icon: :users, label: "Customer", value: "Acme Corp", href: @admin_mount_path <> "/customers"},
              %{icon: :invoices, label: "Invoices", value: "3 open", href: @admin_mount_path <> "/invoices"},
              %{icon: :payments, label: "Charges", href: @admin_mount_path <> "/charges"}
            ]} />

            <div class="ax-card ax-empty">
              <Icon.icon name={:inbox} size="lg" class="ax-empty-icon ax-empty-icon-muted" />
              <p class="ax-empty-title">No rows in this list yet</p>
              <p class="ax-body ax-empty-copy">Empty-state pattern: state glyph, headline, one line of context.</p>
            </div>
          </section>
        </section>
      </AppShell.app_shell>
      """
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
