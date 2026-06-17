if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentKitchenLive do
    @moduledoc false

    use Phoenix.LiveView

    alias AccrueAdmin.Components.{
      AppShell,
      Breadcrumbs,
      Button,
      Detail,
      DropdownMenu,
      FlashGroup,
      Icon,
      KpiCard,
      RelatedResources,
      StatusBadge,
      Tabs
    }

    alias AccrueAdmin.Dev.ComponentRegistry

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
              <DropdownMenu.dropdown_menu
                label="More actions"
                items={[
                  %{label: "Open webhooks", href: @admin_mount_path <> "/webhooks", description: "Inspect event delivery"},
                  %{label: "Open events", href: @admin_mount_path <> "/events", description: "Review audit timeline"}
                ]}
              />
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

          <%!-- Component variants reference — every button, badge, status, and card with its token map --%>

          <%!-- Buttons variant reference. Each component is shown ONCE; review light vs
               dark with the page theme toggle (the per-specimen light/dark wrappers used to
               be inert — no CSS re-themed them — so they only looked like duplicates). --%>
          <section :if={@available?} class="ax-card ax-dev-stack">
            <p class="ax-label">Buttons</p>
            <p class="ax-body ax-dev-caption">Four button roles. Toggle the page theme (top bar) to check each in light and dark.</p>
            <div class="ax-dev-grid">
              <%= for entry <- ComponentRegistry.variants_for("button") do %>
                <div class="ax-dev-variant-row">
                  <Button.button variant={entry.variant} type="button">
                    <%= String.capitalize(entry.variant) %>
                  </Button.button>
                  <dl class="ax-dev-token-dl">
                    <dt class="ax-label"><code><%= entry.ax_class %></code></dt>
                    <%= for token <- entry.tokens do %>
                      <dd class="ax-dev-token"><span class="ax-token-swatch" style={"background: var(#{token})"}></span><code class="ax-type-code-xs"><%= token %></code></dd>
                    <% end %>
                  </dl>
                </div>
              <% end %>
            </div>
          </section>

          <%!-- Status badges — the five semantic tones (moss/cobalt/amber/slate/ink) shown
               with representative lifecycle statuses so each label reads true to its color.
               (Previously split into redundant "Badges" + "Status" sections that rendered the
               same component in the same tones.) --%>
          <section :if={@available?} class="ax-card ax-dev-stack">
            <p class="ax-label">Status badges</p>
            <p class="ax-body ax-dev-caption">One badge per semantic tone, labelled with a representative subscription/invoice status.</p>
            <div class="ax-dev-grid">
              <%= for {entry, status} <- Enum.zip(ComponentRegistry.variants_for("status"), [:active, :trialing, :past_due, :canceled, :failed]) do %>
                <div class="ax-dev-variant-row">
                  <StatusBadge.status_badge tone={entry.variant} status={status} />
                  <dl class="ax-dev-token-dl">
                    <dt class="ax-label"><code><%= entry.ax_class %></code></dt>
                    <%= for token <- entry.tokens do %>
                      <dd class="ax-dev-token"><span class="ax-token-swatch" style={"background: var(#{token})"}></span><code class="ax-type-code-xs"><%= token %></code></dd>
                    <% end %>
                  </dl>
                </div>
              <% end %>
            </div>
          </section>

          <%!-- Cards variant reference (base card + delta tones), each shown once. --%>
          <section :if={@available?} class="ax-card ax-dev-stack">
            <p class="ax-label">Cards</p>
            <p class="ax-body ax-dev-caption">Base KPI card plus the five delta-pill tones.</p>
            <div class="ax-dev-grid">
              <%= for entry <- ComponentRegistry.variants_for("card") do %>
                <div class="ax-dev-variant-row">
                  <%= if entry.variant == "base" do %>
                    <KpiCard.kpi_card label="MRR" value="$4,200" />
                  <% else %>
                    <KpiCard.kpi_card label="Delta" value="$420" delta={"+" <> entry.variant} delta_tone={entry.variant} />
                  <% end %>
                  <dl class="ax-dev-token-dl">
                    <dt class="ax-label"><code><%= entry.ax_class %></code></dt>
                    <%= for token <- entry.tokens do %>
                      <dd class="ax-dev-token"><span class="ax-token-swatch" style={"background: var(#{token})"}></span><code class="ax-type-code-xs"><%= token %></code></dd>
                    <% end %>
                  </dl>
                </div>
              <% end %>
            </div>
          </section>

          <%!-- Phase 188 — Foundation token specimens --%>
          <section :if={@available?} class="ax-card ax-dev-stack ax-foundation ax-foundation-type">
            <p class="ax-label">Review foundations</p>
            <h3 class="ax-heading">Foundation Tokens</h3>

            <div class="ax-foundation-type-stack">
              <div class="ax-foundation ax-foundation-type" data-ax-foundation-specimen="type-display">
                <p class="ax-type-display">Display</p>
                <code class="ax-type-code-xs">--ax-type-display-font</code>
              </div>
              <div class="ax-foundation ax-foundation-type" data-ax-foundation-specimen="type-body">
                <p class="ax-type-body">Body — the resting role for paragraphs, descriptions, and table copy.</p>
                <code class="ax-type-code-xs">--ax-type-body-font</code>
              </div>
              <div class="ax-foundation ax-foundation-measure" data-ax-foundation-specimen="measure-prose">
                <p class="ax-body ax-prose">Reading measure keeps explanatory copy to a durable line length without capping tables.</p>
                <p class="ax-body ax-dev-caption">The paragraph above is capped to <code class="ax-type-code-xs">--ax-measure</code> (~66 characters) so long copy stays readable instead of running edge-to-edge.</p>
              </div>
            </div>

            <%!-- Elevation scale: a diagonal cascade that makes the z-index order visible —
                  sticky at the back, toast on top. Emitted in reversed DOM order (toast first)
                  so the --ax-z-* tokens, not source order, decide what paints on top. Each card
                  keeps data-ax-foundation-layer + a var()-based z-index (the contract the
                  foundation-tokens spec asserts). --%>
            <div class="ax-dev-stack">
              <p class="ax-label">Elevation · z-index scale</p>
              <p class="ax-body ax-dev-caption">Higher layers paint on top: toast sits over modal, over drawer, over popover, over dropdown, over sticky. Nothing to click — the cascade itself shows the order.</p>
              <div class="ax-foundation-layer-stack">
                <%= for {{layer, token}, i} <- Enum.reverse(Enum.with_index([{"sticky", "--ax-z-sticky"}, {"dropdown", "--ax-z-dropdown"}, {"popover", "--ax-z-popover"}, {"drawer", "--ax-z-drawer"}, {"modal", "--ax-z-modal"}, {"toast", "--ax-z-toast"}])) do %>
                  <div class="ax-foundation ax-foundation-layer ax-card" data-ax-foundation-layer={layer} style={"top: #{i * 1.6}rem; left: #{i * 1.5}rem; z-index: var(#{token});"}>
                    <p class="ax-label"><%= layer %></p>
                    <code class="ax-type-code-xs"><%= token %></code>
                  </div>
                <% end %>
              </div>
            </div>

            <div class="ax-dev-stack">
              <p class="ax-body ax-dev-caption">Focus ring — press <kbd>Tab</kbd> to move keyboard focus onto this control; a visible ring should appear (mouse clicks intentionally don't show it).</p>
              <div class="ax-dev-grid">
                <button class="ax-button ax-button-secondary ax-foundation ax-foundation-focus" data-ax-foundation-specimen="focus-control" type="button">Focus</button>
              </div>
            </div>

            <div class="ax-dev-stack">
              <p class="ax-body ax-dev-caption">Control states — disabled (blocked, dimmed), readonly (locked value, copyable), and a normal editable input for contrast.</p>
              <div class="ax-dev-grid">
                <button class="ax-button ax-button-secondary ax-foundation ax-foundation-disabled-readonly" data-ax-foundation-specimen="disabled-control" type="button" disabled>Disabled</button>
                <input class="ax-input ax-foundation ax-foundation-disabled-readonly" data-ax-foundation-specimen="readonly-control" readonly value="Readonly" />
                <input class="ax-input ax-foundation" data-ax-foundation-specimen="editable-control" type="text" value="Editable" aria-label="Editable input" />
              </div>
            </div>

            <div class="ax-dev-stack">
              <p class="ax-body ax-dev-caption">Interactive fills shown at rest — hover, active (pressed), and selected.</p>
              <div class="ax-dev-grid">
                <button class="ax-button ax-button-secondary ax-foundation ax-foundation-interactive" data-ax-foundation-specimen="interactive-hover" type="button">Hover</button>
                <button class="ax-button ax-button-secondary ax-foundation ax-foundation-interactive" data-ax-foundation-specimen="interactive-active" type="button">Active</button>
                <button class="ax-button ax-button-secondary ax-foundation ax-foundation-interactive" data-ax-foundation-specimen="interactive-selected" type="button" aria-pressed="true">Selected</button>
              </div>
            </div>

            <div class="ax-dev-stack">
              <p class="ax-body ax-dev-caption">Scrollbar — scroll inside the box to reveal the themed thumb and track.</p>
              <div class="ax-card ax-foundation ax-foundation-scrollbar" data-ax-foundation-specimen="scrollbar" style="max-height: 5rem; overflow: auto;">
                <p class="ax-body">Tokens: --ax-scrollbar-thumb, --ax-scrollbar-track, --ax-scrollbar-thumb-hover.</p>
                <p class="ax-body">Overflow line 1 — keep scrolling to see the thumb travel.</p>
                <p class="ax-body">Overflow line 2 — keep scrolling.</p>
                <p class="ax-body">Overflow line 3 — keep scrolling.</p>
                <p class="ax-body">Overflow line 4 — keep scrolling.</p>
                <p class="ax-body">Overflow line 5 — bottom of the sample.</p>
              </div>
            </div>

            <div class="ax-dev-stack">
              <p class="ax-body ax-dev-caption">Status colors — each role's background/text/border token trio, rendered as a swatch.</p>
              <div class="ax-dev-grid">
                <%= for status <- ["success", "warning", "danger", "info", "neutral"] do %>
                  <div
                    class={"ax-foundation-swatch ax-foundation ax-foundation-status ax-foundation-status-#{status}"}
                    data-ax-foundation-status={status}
                    style={"background: var(--ax-status-#{status}-bg); color: var(--ax-status-#{status}-text); border-color: var(--ax-status-#{status}-border);"}
                  >
                    <span><%= status %></span>
                    <code class="ax-type-code-xs"><%= "--ax-status-#{status}-bg" %></code>
                  </div>
                <% end %>
              </div>
            </div>

            <div class="ax-dev-stack">
              <p class="ax-label">Token reference</p>
              <p class="ax-body ax-dev-caption">Every foundation token behind the specimens above. The chip shows the resolved color where the token is a color; structural tokens (z-index, measure, fonts) leave it empty.</p>
              <dl class="ax-dev-token-dl">
                <%= for entry <- ComponentRegistry.entries(), String.starts_with?(entry.family, "foundation-") do %>
                  <dt class="ax-label"><code><%= entry.ax_class %></code></dt>
                  <%= for token <- entry.tokens do %>
                    <dd class="ax-dev-token"><span class="ax-token-swatch" style={"background: var(#{token})"}></span><code class="ax-type-code-xs"><%= token %></code></dd>
                  <% end %>
                <% end %>
              </dl>
            </div>
          </section>

          <%!-- Banners showcase (danger/dunning) — stable locator for Playwright --%>
          <section :if={@available?} class="ax-card ax-dev-stack">
            <p class="ax-label">Banners</p>
            <div data-ax-kitchen-banner="danger" class="ax-banner ax-banner-danger">
              Action Required — danger banner (dunning), token-driven styling.
            </div>
          </section>

          <%!-- Phase 177 — Motion reference (MOT-01) --%>
          <%!-- See accrue_admin/guides/motion.md for the full spec. --%>
          <section :if={@available?} class="ax-card ax-dev-stack">
            <p class="ax-label">Motion Reference</p>
            <p class="ax-body">
              Nine surfaces animate via Phase 174 <code>--ax-transition-*</code> bundles.
              Full spec: <code>accrue_admin/guides/motion.md</code>. Motion trace review: Phase 179.
            </p>
            <table class="ax-dev-motion-table">
              <thead>
                <tr>
                  <th class="ax-label">Surface</th>
                  <th class="ax-label">CSS selector</th>
                  <th class="ax-label">Trigger</th>
                  <th class="ax-label">Token(s)</th>
                  <th class="ax-label">Justification</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="ax-body">detail drawer</td>
                  <td class="ax-body"><code>.ax-detail-drawer</code></td>
                  <td class="ax-body"><code>@open</code> mount/remove</td>
                  <td class="ax-body"><code>--ax-dur-3</code> + <code>--ax-rise-md</code></td>
                  <td class="ax-body">Continuity — slides from edge so operator keeps spatial context</td>
                </tr>
                <tr>
                  <td class="ax-body">drawer backdrop</td>
                  <td class="ax-body"><code>.ax-detail-drawer-backdrop</code></td>
                  <td class="ax-body">same as drawer</td>
                  <td class="ax-body"><code>--ax-dur-3</code></td>
                  <td class="ax-body">Affordance — dimming signals modal layer; click-to-dismiss target</td>
                </tr>
                <tr>
                  <td class="ax-body">dropdown menu</td>
                  <td class="ax-body"><code>.ax-dropdown-panel</code></td>
                  <td class="ax-body"><code>details[open]</code></td>
                  <td class="ax-body"><code>--ax-dur-2</code> + <code>--ax-rise-sm</code></td>
                  <td class="ax-body">Affordance — small rise reads as "panel belongs to trigger above"</td>
                </tr>
                <tr>
                  <td class="ax-body">More ▾ overflow</td>
                  <td class="ax-body"><code>.ax-tab-more-menu</code></td>
                  <td class="ax-body">toggle open</td>
                  <td class="ax-body"><code>--ax-dur-2</code> + <code>--ax-rise-sm</code></td>
                  <td class="ax-body">Affordance — same grammar as any dropdown (consistency)</td>
                </tr>
                <tr>
                  <td class="ax-body">collapsible nav group</td>
                  <td class="ax-body"><code>.ax-sidebar-nav-group</code></td>
                  <td class="ax-body"><code>aria-expanded</code> toggle</td>
                  <td class="ax-body"><code>--ax-transition-transform</code> (chevron) + <code>--ax-dur-2</code></td>
                  <td class="ax-body">Feedback — chevron confirms toggle; reveal shows where items went</td>
                </tr>
                <tr>
                  <td class="ax-body">command palette</td>
                  <td class="ax-body"><code>.ax-command-palette</code></td>
                  <td class="ax-body">Cmd-K / Esc (<code>data-open</code>)</td>
                  <td class="ax-body"><code>--ax-dur-2</code> + <code>--ax-ease-emphasis</code></td>
                  <td class="ax-body">Feedback — scale-in announces palette took focus (one earned overshoot)</td>
                </tr>
                <tr>
                  <td class="ax-body">palette backdrop</td>
                  <td class="ax-body"><code>.ax-command-palette-backdrop</code></td>
                  <td class="ax-body">same as palette</td>
                  <td class="ax-body"><code>--ax-dur-2</code></td>
                  <td class="ax-body">Affordance — modal dimming</td>
                </tr>
                <tr>
                  <td class="ax-body">tabs active indicator</td>
                  <td class="ax-body"><code>.ax-tab</code> / <code>.ax-tab-active</code></td>
                  <td class="ax-body">active tab change (link nav)</td>
                  <td class="ax-body"><code>--ax-transition-colors</code></td>
                  <td class="ax-body">Feedback — confirms selection; color crossfade (no slide — link-based nav)</td>
                </tr>
                <tr>
                  <td class="ax-body">flash / toasts</td>
                  <td class="ax-body"><code>.ax-flash</code></td>
                  <td class="ax-body">mount / dismiss</td>
                  <td class="ax-body"><code>--ax-dur-2</code> + <code>--ax-rise-sm</code></td>
                  <td class="ax-body">Feedback — slides in to be noticed; snappy fade-out so dismissal feels immediate</td>
                </tr>
                <tr>
                  <td class="ax-body">skeleton → content</td>
                  <td class="ax-body"><code>.ax-skeleton</code> → table rows</td>
                  <td class="ax-body">data arrives (skeleton removed)</td>
                  <td class="ax-body"><code>--ax-dur-2</code></td>
                  <td class="ax-body">Continuity — content fades in where skeleton was; no pop</td>
                </tr>
                <tr>
                  <td class="ax-body">badge / state change</td>
                  <td class="ax-body"><code>.ax-status-badge</code>, <code>.ax-badge</code></td>
                  <td class="ax-body">status change / first-appear</td>
                  <td class="ax-body"><code>--ax-transition-colors</code> + <code>--ax-transition-transform</code></td>
                  <td class="ax-body">Feedback — status change draws a glance without layout shift</td>
                </tr>
              </tbody>
            </table>
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
