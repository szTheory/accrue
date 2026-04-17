if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.WebhookFixtureLive do
    @moduledoc false

    use Phoenix.LiveView

    alias AccrueAdmin.Components.{AppShell, Breadcrumbs, JsonViewer, Tabs}

    @fixtures %{
      "invoice.payment_failed" => %{
        "id" => "evt_fixture_failed",
        "type" => "invoice.payment_failed",
        "data" => %{
          "object" => %{"id" => "in_fixture", "customer" => "cus_fixture", "status" => "open"}
        }
      },
      "customer.subscription.updated" => %{
        "id" => "evt_fixture_subscription",
        "type" => "customer.subscription.updated",
        "data" => %{
          "object" => %{"id" => "sub_fixture", "status" => "active", "trial_end" => 1_775_203_200}
        }
      }
    }

    @impl true
    def mount(_params, session, socket) do
      admin = Map.get(session, "accrue_admin", %{})

      if fake_processor?() do
        {selected_type, payload} = Enum.at(@fixtures, 0)

        {:ok,
         socket
         |> assign_shell(admin, "/dev/webhook-fixtures", "Webhook Fixtures")
         |> assign(:available?, true)
         |> assign(:fixture_type, selected_type)
         |> assign(:fixture_payload, payload)}
      else
        {:ok,
         socket
         |> assign_shell(admin, "/dev/webhook-fixtures", "Webhook Fixtures")
         |> assign(:available?, false)}
      end
    end

    @impl true
    def handle_params(%{"type" => type}, _uri, socket) when is_binary(type) do
      payload = Map.get(@fixtures, type, socket.assigns.fixture_payload)

      {:noreply,
       socket
       |> assign(:fixture_type, type)
       |> assign(:fixture_payload, payload)}
    end

    def handle_params(_params, _uri, socket), do: {:noreply, socket}

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
                %{label: "Webhook fixtures"}
              ]}
            />
            <p class="ax-eyebrow">Fixture payloads</p>
            <h2 class="ax-display">Reference webhook payload shapes without leaving admin</h2>
          </header>

          <section :if={!@available?} class="ax-card">
            <p class="ax-label">Unavailable</p>
            <p class="ax-body">Dev tools require `Accrue.Processor.Fake` as the configured processor.</p>
          </section>

          <section :if={@available?} class="ax-card">
            <Tabs.tabs
              active={@fixture_type}
              tabs={
                Enum.map(@fixtures, fn {type, _payload} ->
                  %{id: type, label: type, href: @current_path <> "?type=" <> URI.encode(type)}
                end)
              }
            />
          </section>

          <section :if={@available?} class="ax-card">
            <JsonViewer.json_viewer
              id="webhook-fixture-json"
              payload={@fixture_payload}
              active_tab="tree"
            />
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
      |> assign(:fixtures, @fixtures)
    end

    defp fake_processor? do
      Application.get_env(:accrue, :processor, Accrue.Processor.Fake) == Accrue.Processor.Fake
    end

    defp default_brand do
      %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
    end
  end
end
