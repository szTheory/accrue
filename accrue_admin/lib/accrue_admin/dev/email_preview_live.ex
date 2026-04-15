if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.EmailPreviewLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Accrue.Emails.Fixtures
    alias AccrueAdmin.Components.{AppShell, Breadcrumbs, JsonViewer, Select}

    @impl true
    def mount(_params, session, socket) do
      admin = Map.get(session, "accrue_admin", %{})

      if fake_processor?() do
        fixtures = Fixtures.all()
        selected = if Map.has_key?(fixtures, :receipt), do: :receipt, else: fixtures |> Map.keys() |> List.first()

        {:ok,
         socket
         |> assign_shell(admin, "/dev/email-preview", "Email Preview")
         |> assign(:available?, true)
         |> assign(:fixtures, fixtures)
         |> assign_fixture(selected)}
      else
        {:ok,
         socket
         |> assign_shell(admin, "/dev/email-preview", "Email Preview")
         |> assign(:available?, false)}
      end
    end

    @impl true
    def handle_event("select_fixture", %{"fixture" => fixture}, socket) do
      {:noreply, assign_fixture(socket, String.to_existing_atom(fixture))}
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
                %{label: "Email preview"}
              ]}
            />
            <p class="ax-eyebrow">Fixtures</p>
            <h2 class="ax-display">Preview deterministic Accrue email assigns</h2>
            <p class="ax-body ax-page-copy">
              Reads directly from `Accrue.Emails.Fixtures.all/0`; no DB rows, processor calls, or
              template overrides are introduced here.
            </p>
          </header>

          <section :if={!@available?} class="ax-card">
            <p class="ax-label">Unavailable</p>
            <p class="ax-body">Dev tools require `Accrue.Processor.Fake` as the configured processor.</p>
          </section>

          <section :if={@available?} class="ax-card">
            <form phx-change="select_fixture">
              <Select.select
                id="fixture"
                name="fixture"
                label="Email type"
                value={Atom.to_string(@selected_fixture)}
                options={@fixture_options}
              />
            </form>
          </section>

          <section :if={@available?} class="ax-grid ax-grid-2">
            <article class="ax-card">
              <p class="ax-label">Subject</p>
              <h3 class="ax-heading">{@fixture.subject}</h3>
              <p class="ax-label">Preview text</p>
              <p class="ax-body">{@fixture.preview}</p>
            </article>

            <article class="ax-card">
              <p class="ax-label">Context payload</p>
              <JsonViewer.json_viewer
                id="email-preview-json"
                payload={@display_fixture}
                active_tab="tree"
              />
            </article>
          </section>
        </section>
      </AppShell.app_shell>
      """
    end

    defp assign_fixture(socket, key) do
      fixture = Map.fetch!(socket.assigns.fixtures, key)
      display_fixture =
        fixture
        |> Map.update!(:context, fn context ->
          Map.update!(context, :branding, &Enum.into(&1, %{}))
        end)

      assign(socket,
        selected_fixture: key,
        fixture: fixture,
        display_fixture: display_fixture,
        fixture_options:
          Enum.map(socket.assigns.fixtures, fn {name, _fixture} ->
            {humanize(name), Atom.to_string(name)}
          end)
      )
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

    defp humanize(name), do: name |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

    defp fake_processor? do
      Application.get_env(:accrue, :processor, Accrue.Processor.Fake) == Accrue.Processor.Fake
    end

    defp default_brand do
      %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
    end
  end
end
