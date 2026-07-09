if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentKitchenLive do
    @moduledoc false

    use Phoenix.LiveView

    alias AccrueAdmin.Components.{
      AppShell,
      Breadcrumbs,
      Button,
      Checkbox,
      Detail,
      DropdownMenu,
      EmptyState,
      FilterChipBar,
      FlashGroup,
      FunnelChart,
      Icon,
      IdBadge,
      InlineId,
      Input,
      JsonViewer,
      KpiCard,
      MoneyFormatter,
      Radio,
      RelatedResources,
      Select,
      Spinner,
      StatusBadge,
      Tabs,
      Textarea,
      ThemePicker,
      Timeline,
      Toggle,
      Tooltip,
      WindowSelector
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
         |> assign(:flashes, [])}
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
        current_owner_scope={assigns[:current_owner_scope]}
        active_organization_name={@active_organization_name}
      >
        <section class="ax-page">
          <header class="ax-page-header ax-page-header-compact">
            <Breadcrumbs.breadcrumbs
              items={[
                %{label: "Dashboard", href: @admin_mount_path},
                %{label: "Component kitchen"}
              ]}
            />
            <h1 class="ax-heading">Component Kitchen</h1>
            <p class="ax-page-description">Primitive and form components — full state matrix. Use the topbar theme toggle to review light and dark.</p>
          </header>

          <FlashGroup.flash_group flashes={@flashes} />

          <section :if={!@available?} class="ax-card">
            <p class="ax-label">Unavailable</p>
            <p class="ax-body">Dev tools require `Accrue.Processor.Fake` as the configured processor.</p>
          </section>

          <section :if={@available?} class="ax-kpi-grid ax-kpi-row">
            <KpiCard.kpi_card
              label="Primary KPI"
              value="$42.00"
              delta="healthy"
              delta_tone="moss"
              href={@admin_mount_path <> "/invoices?status=open"}
            >
              <:meta>Open invoice queue view</:meta>
            </KpiCard.kpi_card>
            <KpiCard.kpi_card
              label="Queued invoice jobs"
              value="7"
              delta="needs review"
              delta_tone="amber"
              href={@admin_mount_path <> "/invoices?status=open"}
            >
              <:meta>Review queued invoices</:meta>
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

            <div class="ax-dev-grid ax-toolbar">
              <Button.button variant="primary" type="button">Primary action</Button.button>
              <Button.button variant="secondary" type="button">Secondary action</Button.button>
              <Button.button variant="secondary" class="ax-button-recovery" href={@admin_mount_path <> "/analytics/recovery"}>Open recovery analytics</Button.button>
              <Button.button variant="ghost" href={@admin_mount_path <> "/webhooks"}>Ghost link</Button.button>
              <DropdownMenu.dropdown_menu
                label="More billing actions"
                items={[
                  %{label: "Open webhooks", href: @admin_mount_path <> "/webhooks", description: "Inspect event delivery"},
                  %{label: "Open events", href: @admin_mount_path <> "/events", description: "Review audit timeline"},
                  %{label: "Open recovery analytics", href: @admin_mount_path <> "/analytics/recovery", description: "Review dunning and at-risk accounts"}
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
          <section :if={@available?} class="ax-dev-stack ax-detail">
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

          <%!-- Component variants reference — registry-driven state-matrix renderer.
               State-matrix renderer: light and dark columns are genuine theme scopes via
               .accrue-admin [data-theme='dark'] sub-tree selector in theme.css (Phase 189).
               Each column independently inherits --ax-* token values — not merely duplicates
               with a class toggle.
               NOTE: HTML attribute presence (data-theme='light'/'dark') is verified by test (g);
               browser-level resolved-color delta is verified by Plan 06's themeColumnDeltaProbe —
               that is the definitive D-07 sign-off. --%>
          <%= for {family, entries} <- registry_families() do %>
            <section :if={@available?} class="ax-card ax-dev-stack" data-ax-family={family}>
              <div class="ax-dev-family-header">
                <h3 class="ax-type-eyebrow"><%= family_label(family) %></h3>
                <p class="ax-body-sm ax-muted">
                  <%= length(entries) %> variant(s) ·
                  <%= entries |> hd() |> Map.get(:applicable_states, []) |> length() %> applicable states
                </p>
              </div>

              <%!-- Single-column state matrix. The lab follows the global topbar
                   theme toggle (html.accrue-admin[data-theme]) like every other admin
                   page — see D-05/D-07 supersede note in 189-CONTEXT.md. --%>
              <div class="ax-dev-state-grid">
                <div class="ax-dev-state-grid-col">
                  <%= for entry <- entries do %>
                    <%= for state <- Map.get(entry, :applicable_states, []) do %>
                      <div class="ax-dev-state-cell" data-ax-state={state}>
                        <span class="ax-dev-state-cell-label ax-type-code-xs ax-muted"><%= state %></span>
                        <%= render_specimen(entry, state) %>
                      </div>
                    <% end %>
                    <%= for %{state: state, reason: reason} <- Map.get(entry, :na_states, []) do %>
                      <div class="ax-dev-state-cell ax-dev-state-cell-na" data-ax-state={state} data-ax-na-reason={reason}>
                        <span class="ax-dev-state-cell-label ax-type-code-xs ax-muted"><%= state %></span>
                        <span class="ax-type-code-xs ax-muted">n/a — <%= reason %></span>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>

              <%!-- Token reference for this family — ensures tokens appear in the rendered HTML
                   so test (d) can verify all registry tokens are visible on the page. --%>
              <dl class="ax-dev-token-dl">
                <%= for entry <- entries do %>
                  <dt class="ax-label"><code><%= entry.ax_class %></code></dt>
                  <%= for token <- entry.tokens do %>
                    <dd class="ax-dev-token"><span :if={color_token?(token)} class="ax-token-swatch" style={"background: var(#{token})"}></span><code :if={!color_token?(token)} class="ax-type-code-xs ax-token-kind"><%= token_kind(token) %></code><code class="ax-type-code-xs"><%= token %></code></dd>
                  <% end %>
                <% end %>
              </dl>
            </section>
          <% end %>

          <%!-- Phase 190 — Component-group proof specimens.
               Contract-driven roots close Phase 187 component-group visibility gaps and
               expose stable data-component-group locators for deterministic lab probes. --%>
          <section :if={@available?} class="ax-dev-group-stack" aria-labelledby="component-groups-title">
            <div class="ax-dev-group-intro">
              <p class="ax-label">Component groups</p>
              <h3 id="component-groups-title" class="ax-heading">Component Groups</h3>
              <p class="ax-body ax-dev-caption">
                Canonical Phase 190 proof specimens. Each root is driven by <code class="ax-type-code-xs">ComponentRegistry.group_contracts/0</code> and follows the global topbar theme toggle.
              </p>
            </div>

            <%= for contract <- ComponentRegistry.group_contracts() do %>
              <%= render_group_contract(contract, @admin_mount_path) %>
            <% end %>
          </section>

          <%!-- Card and legacy variant reference — base KPI card + delta tones.
               These entries have no applicable_states (not Phase-189 primitives) so they
               are not part of the state-matrix renderer above. Token reference is preserved
               so test (d) can verify card registry tokens appear in the page HTML. --%>
          <section :if={@available?} class="ax-card ax-dev-stack">
            <p class="ax-label">Cards (KPI + Delta tones)</p>
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
                      <dd class="ax-dev-token"><span :if={color_token?(token)} class="ax-token-swatch" style={"background: var(#{token})"}></span><code :if={!color_token?(token)} class="ax-type-code-xs ax-token-kind"><%= token_kind(token) %></code><code class="ax-type-code-xs"><%= token %></code></dd>
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
                  <div class="ax-foundation ax-foundation-layer ax-layer ax-card" data-ax-foundation-layer={layer} tabindex="0" aria-label={"Layer specimen #{layer}"} style={"top: #{i * 1.6}rem; left: #{i * 1.5}rem; z-index: var(#{token});"}>
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
                <input class="ax-input ax-foundation ax-foundation-disabled-readonly" data-ax-foundation-specimen="readonly-control" readonly value="Readonly" aria-label="Readonly input" />
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
              <div class="ax-card ax-foundation ax-foundation-scrollbar" data-ax-foundation-specimen="scrollbar" style="max-height: 5rem; overflow: auto;" tabindex="0" role="region" aria-label="Scrollbar token specimen">
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
              <p class="ax-body ax-dev-caption">Every foundation token behind the specimens above. Color tokens show a resolved-color chip; structural tokens (z-index, measure, fonts, shadows, motion) show their kind instead.</p>
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

          <section class="ax-card ax-dev-section" aria-labelledby="command-palette-motion-proof-title">
            <div class="ax-dev-section-head">
              <div>
                <p class="ax-eyebrow">Motion proof</p>
                <h3 id="command-palette-motion-proof-title" class="ax-heading">Command palette open state</h3>
              </div>
              <span class="ax-dev-chip">reduced-motion target</span>
            </div>

            <p class="ax-body ax-dev-caption">
              Static proof surface for the global search palette transition contract. The live command palette owns keyboard behavior; this specimen keeps the open-state CSS target present for deterministic token checks.
            </p>

            <div class="ax-command-palette-wrapper ax-dev-command-palette-specimen" data-open="true" data-component-group="toolbar-search-filter-sort">
              <div
                class="ax-command-palette"
                role="dialog"
                aria-modal="false"
                aria-label="Command palette motion specimen"
              >
                <form onsubmit="return false;">
                  <div class="ax-command-palette-input-group">
                    <Icon.icon name={:search} size="md" class="ax-command-palette-search-icon" />
                    <input
                      type="text"
                      class="ax-command-palette-input"
                      value="customer recovery"
                      aria-label="Command palette specimen search"
                      readonly
                    />
                    <span class="ax-spinner" aria-hidden="true"></span>
                  </div>
                </form>

                <div class="ax-command-palette-body">
                  <div class="ax-command-palette-empty">
                    <p class="ax-eyebrow">Jump to</p>
                    <ul class="ax-command-palette-list">
                      <li class="ax-command-palette-list-item">
                        <a class="ax-command-palette-item" href={@admin_mount_path <> "/customers"}>
                          <Icon.icon name={:users} size="sm" /> <span>Find one customer</span>
                        </a>
                      </li>
                      <li class="ax-command-palette-list-item">
                        <a class="ax-command-palette-item" href={@admin_mount_path <> "/invoices?status=open"}>
                          <Icon.icon name={:invoices} size="sm" /> <span>Clear the invoice queue</span>
                        </a>
                      </li>
                      <li class="ax-command-palette-list-item">
                        <a class="ax-command-palette-item" href={@admin_mount_path <> "/analytics/recovery"}>
                          <Icon.icon name={:recovery} size="sm" /> <span>Recover at-risk revenue</span>
                        </a>
                      </li>
                    </ul>
                  </div>
                </div>

                <div class="ax-command-palette-footer">
                  <span class="ax-shortcut"><kbd>esc</kbd> Close</span>
                </div>
              </div>
            </div>
          </section>
        </section>
      </AppShell.app_shell>
      """
    end

    defp render_group_contract(contract, admin_mount_path) do
      assigns = %{contract: contract, admin_mount_path: admin_mount_path, __changed__: %{}}

      ~H"""
      <section id={@contract.proof_id} class="ax-card ax-dev-group-specimen" data-component-group={@contract.slug}>
        <header class="ax-dev-group-header">
          <div>
            <p class="ax-type-code-xs ax-muted"><%= @contract.name %></p>
            <h4 class="ax-heading"><%= group_title(@contract.slug) %></h4>
            <p class="ax-body ax-dev-caption"><%= @contract.representative_route_category %></p>
          </div>
          <div class="ax-dev-group-state-list" aria-label={"States proven for #{group_title(@contract.slug)}"}>
            <span :for={state <- @contract.required_states} class="ax-dev-group-state-chip" data-group-state={state}>
              <%= state_label(state) %>
            </span>
          </div>
        </header>

        <%= render_group_body(@contract, @admin_mount_path) %>
      </section>
      """
    end

    defp render_group_body(%{slug: "page-header-actions-breadcrumbs"}, admin_mount_path) do
      assigns = %{admin_mount_path: admin_mount_path, __changed__: %{}}

      ~H"""
      <div class="ax-dev-group-body ax-dev-group-page-header">
        <header class="ax-page-header ax-dev-group-page-header-specimen">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: @admin_mount_path},
              %{label: "Subscriptions", href: @admin_mount_path <> "/subscriptions"},
              %{label: "Quarter close review"}
            ]}
          />
          <div class="ax-dev-group-header-row">
            <div class="ax-dev-group-header-copy">
              <p class="ax-eyebrow">Quarter close</p>
              <h4 class="ax-heading">Review subscriptions with unusually long dunning and payment recovery context</h4>
              <p class="ax-body ax-dev-caption">
                Breadcrumbs orient the operator before the task heading; primary and secondary actions stay adjacent to the identity band.
              </p>
            </div>
            <div class="ax-dev-group-actions">
              <Button.button variant="primary" type="button">Export review</Button.button>
              <Button.button variant="secondary" type="button">Open runbook</Button.button>
            </div>
          </div>
        </header>
      </div>
      """
    end

    defp render_group_body(%{slug: "toolbar-search-filter-sort"}, admin_mount_path) do
      assigns = %{admin_mount_path: admin_mount_path, __changed__: %{}}

      ~H"""
      <div class="ax-dev-group-body ax-dev-group-toolbar">
        <form class="ax-data-table-filters" action={@admin_mount_path <> "/invoices"} method="get">
          <div class="ax-data-table-filter">
            <label class="ax-label" for="grp190-toolbar-search">Search</label>
            <input id="grp190-toolbar-search" class="ax-field-control" name="q" value="enterprise annual renewal with long customer name" />
          </div>
          <div class="ax-data-table-filter">
            <label class="ax-label" for="grp190-toolbar-status">Status</label>
            <select id="grp190-toolbar-status" class="ax-field-control ax-select-control" name="status">
              <option>Open</option>
              <option>Past due</option>
            </select>
          </div>
          <Button.button variant="primary" type="submit">Apply filters</Button.button>
          <a class="ax-button ax-button-ghost" href={@admin_mount_path <> "/invoices"}>Clear filters</a>
        </form>

        <FilterChipBar.filter_chip_bar
          label="Invoice queue"
          items={[
            %{id: :status, label: "Status", value: "Open", remove_href: @admin_mount_path <> "/invoices"},
            %{id: :sort, label: "Sort", value: "Oldest first", remove_href: @admin_mount_path <> "/invoices?status=open"}
          ]}
        />

        <DropdownMenu.dropdown_menu
          label="Sort"
          items={[
            %{label: "Newest first", href: @admin_mount_path <> "/invoices?sort=newest", description: "Show recent invoice activity first"},
            %{label: "Largest balance", href: @admin_mount_path <> "/invoices?sort=balance", description: "Prioritize invoice recovery by amount"}
          ]}
        />

        <div class="ax-card ax-empty ax-dev-group-state-row" data-group-state="filtered-empty">
          <p class="ax-empty-title">Filtered empty</p>
          <p class="ax-body ax-empty-copy">No invoices match the active status and sort constraints.</p>
          <a class="ax-button ax-button-secondary" href={@admin_mount_path <> "/invoices"}>Clear filters</a>
        </div>
      </div>
      """
    end

    defp render_group_body(%{slug: "table-empty-loading-error-pagination"}, _admin_mount_path) do
      assigns = %{__changed__: %{}}

      ~H"""
      <div class="ax-dev-group-body ax-dev-group-table">
        <div class="ax-data-table-shell" data-group-state="long-content">
          <table class="ax-data-table-grid">
            <caption class="ax-label">Invoice queue proof table</caption>
            <thead>
              <tr>
                <th>Invoice</th>
                <th>Customer</th>
                <th>Status</th>
                <th>Balance</th>
              </tr>
            </thead>
            <tbody>
              <tr class="ax-data-table-row-selected" aria-selected="true" data-group-state="selected-filter-active">
                <td>Invoice for enterprise annual renewal with very long purchase-order context</td>
                <td>Northstar Operations and Billing Systems Group</td>
                <td><StatusBadge.status_badge status={:past_due} /></td>
                <td>$24,000.00</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="ax-data-table-cards" data-group-state="mobile-card-list-degradation">
          <article class="ax-card ax-data-table-card">
            <p class="ax-label">Mobile card degradation</p>
            <h5 class="ax-heading">Northstar Operations</h5>
            <dl class="ax-field-list">
              <div class="ax-field">
                <dt class="ax-field-label">Status</dt>
                <dd class="ax-field-value">Past due</dd>
              </div>
              <div class="ax-field">
                <dt class="ax-field-label">Balance</dt>
                <dd class="ax-field-value">$24,000.00</dd>
              </div>
            </dl>
          </article>
        </div>

        <div class="ax-dev-group-state-grid">
          <div class="ax-card ax-empty ax-dev-group-state-row" data-group-state="empty">
            <p class="ax-empty-title">True empty</p>
            <p class="ax-body ax-empty-copy">Billing records appear here when they match this view.</p>
          </div>
          <div class="ax-card ax-empty ax-dev-group-state-row" data-group-state="filtered-empty">
            <p class="ax-empty-title">Filtered empty</p>
            <p class="ax-body ax-empty-copy">No rows match the active filters. Clear filters is the next useful action.</p>
            <button class="ax-button ax-button-secondary" type="button">Clear filters</button>
          </div>
          <div class="ax-card ax-dev-group-state-row" data-group-state="loading">
            <Spinner.spinner size="sm" label="Loading billing records" />
          </div>
          <div class="ax-card ax-dev-group-state-row ax-dev-group-state-error" data-group-state="error">
            <p class="ax-label">Error</p>
            <p class="ax-body">This data display could not load. Retry the query; if it persists, inspect logs for the active owner scope.</p>
            <button class="ax-button ax-button-secondary" type="button">Retry</button>
          </div>
          <div class="ax-card ax-dev-group-state-row" data-group-state="no-pagination">
            <p class="ax-label">No pagination</p>
            <p class="ax-body">No pagination control is shown when there is no <code class="ax-type-code-xs">next_cursor</code> or equivalent more-data signal.</p>
          </div>
          <div class="ax-card ax-dev-group-state-row" data-group-state="has-pagination">
            <p class="ax-label">Has pagination</p>
            <button class="ax-button ax-button-secondary" type="button">Load more</button>
          </div>
        </div>
      </div>
      """
    end

    defp render_group_body(%{slug: "kpi-chart-table"}, admin_mount_path) do
      assigns = %{admin_mount_path: admin_mount_path, __changed__: %{}}

      ~H"""
      <div class="ax-dev-group-body ax-dev-group-kpi">
        <div class="ax-kpi-grid ax-kpi-grid-4">
          <KpiCard.kpi_card label="Recovered MRR" value="$12,450" delta="+12.5%" delta_tone="moss">
            <:meta>Money recovered this window</:meta>
          </KpiCard.kpi_card>
          <KpiCard.kpi_card label="At risk" value="$3,100" delta="5 campaigns" delta_tone="amber">
            <:meta>Needs operator review</:meta>
          </KpiCard.kpi_card>
        </div>

        <FunnelChart.funnel_chart entered={24} recovered={17} exhausted={4} active={3} />

        <div class="ax-card ax-dev-group-state-row" data-group-state="empty">
          <p class="ax-label">At-risk table empty state</p>
          <p class="ax-body">No active dunning campaigns are in this window.</p>
        </div>

        <table class="ax-data-table-grid">
          <caption class="ax-label">At-risk subscriptions</caption>
          <tbody>
            <tr>
              <td><a class="ax-link" href={@admin_mount_path <> "/subscriptions"}>Annual enterprise renewal</a></td>
              <td><StatusBadge.status_badge status={:retrying} /></td>
              <td>Retry scheduled</td>
            </tr>
          </tbody>
        </table>
      </div>
      """
    end

    defp render_group_body(%{slug: "detail-header-metadata-actions"}, admin_mount_path) do
      assigns = %{admin_mount_path: admin_mount_path, __changed__: %{}}

      ~H"""
      <div class="ax-dev-group-body ax-dev-group-detail">
        <Detail.summary_card eyebrow="Subscription" title="Subscription sub_group_visibility_demo">
          <:status><StatusBadge.status_badge status={:active} label="Status active" /></:status>
          <:facts>
            <span><strong>Status</strong> active</span>
            <span><strong>Owner scope</strong> platform-demo</span>
            <span><strong>Open invoices</strong> 2</span>
          </:facts>
          <:actions>
            <Button.button variant="primary" href={@admin_mount_path <> "/subscriptions"}>Review subscription</Button.button>
            <Button.button variant="secondary" type="button">Copy link</Button.button>
          </:actions>
        </Detail.summary_card>

        <Detail.detail_section title="Metadata">
          <Detail.detail_field_list fields={[
            %{label: "Owner scope", value: "platform-demo"},
            %{label: "External reference", value: "group-proof-reference-with-long-wrapping-value"},
            %{label: "Open invoices", value: "2"}
          ]} />
        </Detail.detail_section>
      </div>
      """
    end

    defp render_group_body(%{slug: "modal-confirm"}, _admin_mount_path) do
      assigns = %{__changed__: %{}}

      ~H"""
      <div class="ax-dev-group-body">
        <div
          class="ax-dev-group-modal"
          role="dialog"
          aria-labelledby="grp190-modal-title"
          aria-describedby="grp190-modal-desc"
          data-group-state="mobile-stack"
        >
          <header class="ax-dev-group-modal-header">
            <p class="ax-eyebrow">Confirm action</p>
            <h5 id="grp190-modal-title" class="ax-heading">Cancel renewal schedule</h5>
            <p id="grp190-modal-desc" class="ax-body">Cancel renewal schedule will execute against the subscription projection. Continue?</p>
          </header>
          <div class="ax-dev-group-modal-body">
            <p class="ax-body">This action changes billing recovery evidence and cannot be presented as a color-only warning.</p>
          </div>
          <footer class="ax-dev-group-modal-footer">
            <Button.button variant="ghost" type="button">Cancel</Button.button>
            <Button.button variant="danger" type="button">Cancel renewal</Button.button>
          </footer>
        </div>
      </div>
      """
    end

    defp render_group_body(%{slug: "drawer-form"}, admin_mount_path) do
      assigns = %{admin_mount_path: admin_mount_path, __changed__: %{}}

      ~H"""
      <div class="ax-dev-group-body ax-dev-group-drawer-specimen">
        <section class="ax-card ax-dev-group-drawer-preview" aria-label="Billing health and recovery drawer">
          <header class="ax-section-head">
            <div>
              <p class="ax-eyebrow">Drawer preview</p>
              <h5 class="ax-heading">Billing health and recovery drawer</h5>
              <p class="ax-body">Current billing health, at-risk dunning, actor audit history, failed-webhook debugging, and invoice queue controls.</p>
            </div>
          </header>

          <div class="ax-dev-group-drawer">
            <section class="ax-dev-group-drawer-context ax-dev-group-drawer-health" aria-label="Billing health summary">
              <p class="ax-label">Billing health verdict</p>
              <p class="ax-dev-group-drawer-health-verdict">
                <span class="ax-status-badge ax-status-badge-amber">
                  <span class="ax-status-dot"></span>Attention required
                </span>
                <strong>Billing needs attention now</strong>
                <span>$592.50 open exposure; target $0.00</span>
              </p>
              <p class="ax-body">
                Last edited Jul 7, 2026 at 18:00 UTC by System after billing.contact.updated.
              </p>
              <div class="ax-audit-summary-row" aria-label="Recent actor audit history">
                <span><strong>Actor</strong> System</span>
                <span><strong>Event</strong> billing.contact.updated</span>
                <span><strong>When</strong> Jul 7, 2026 18:00 UTC</span>
              </div>
              <div class="ax-dev-group-action-clusters">
                <div class="ax-dev-group-action-cluster">
                  <span class="ax-label">Queues</span>
                  <div class="ax-detail-actions-row ax-dev-group-drawer-primary-actions">
                    <a class="ax-button ax-button-primary ax-button-sm" href={@admin_mount_path <> "/invoices?status=open"}>Open invoice queue view for 2 open invoices</a>
                    <a class="ax-button ax-button-primary ax-button-sm" href={@admin_mount_path <> "/webhooks?status=failed,dead"}>Open failed-webhook debugger</a>
                  </div>
                </div>
                <div class="ax-dev-group-action-cluster">
                  <span class="ax-label">Recovery and audit</span>
                  <div class="ax-detail-actions-row">
                    <a class="ax-button ax-button-recovery ax-button-sm" href={@admin_mount_path <> "/analytics/recovery"}>View dunning funnel and at-risk analytics</a>
                    <a class="ax-button ax-button-warning ax-button-sm" href={@admin_mount_path <> "/events?actor_type=admin"}>View full audit history</a>
                    <a class="ax-button ax-button-secondary ax-button-sm" href={@admin_mount_path <> "/customers"}>Find customer</a>
                  </div>
                </div>
              </div>
            </section>

            <Input.input id="grp190-drawer-email" name="billing_email" label="Billing email" value="operations@example.test" />
            <Select.select
              id="grp190-drawer-cadence"
              name="cadence"
              label="Review cadence"
              value="monthly"
              options={[{"Monthly", "monthly"}, {"Quarterly", "quarterly"}]}
            />
            <Textarea.textarea
              id="grp190-drawer-notes"
              name="notes"
              label="Operator notes"
              value="Customer asked for billing contact review before the next renewal."
            />
            <Input.input
              id="grp190-drawer-error"
              name="owner_scope"
              label="Owner scope"
              value=""
              placeholder="platform-demo"
              help_text="Enter the organization slug or platform owner scope this billing contact belongs to."
              errors={["Owner scope is required before saving."]}
            />
          </div>

          <footer class="ax-detail-drawer-footer">
            <Button.button variant="ghost" type="button">Cancel</Button.button>
            <Button.button variant="primary" type="button">Save contact</Button.button>
          </footer>
        </section>
      </div>
      """
    end

    defp render_group_body(%{slug: "tabs-subviews"}, admin_mount_path) do
      assigns = %{admin_mount_path: admin_mount_path, __changed__: %{}}

      ~H"""
      <div class="ax-dev-group-body ax-dev-group-tabs">
        <Tabs.tabs
          active="events"
          tabs={[
            %{id: "overview", label: "Overview", href: @admin_mount_path <> "/customers"},
            %{id: "events", label: "Webhook delivery attempts with long label", href: @admin_mount_path <> "/events", count: 12},
            %{id: "invoices", label: "Invoices", href: @admin_mount_path <> "/invoices", count: 3}
          ]}
        />

        <WindowSelector.window_selector current_window="30d" base_path={@admin_mount_path <> "/analytics/recovery"} />

        <p class="ax-body ax-dev-caption">
          Active tabs use link navigation with <code class="ax-type-code-xs">aria-current="page"</code>, visible count pills, and horizontally reachable long labels.
        </p>
      </div>
      """
    end

    defp render_group_body(_contract, _admin_mount_path) do
      assigns = %{__changed__: %{}}

      ~H"""
      <p class="ax-body ax-muted">Group proof specimen not available.</p>
      """
    end

    defp group_title("page-header-actions-breadcrumbs"), do: "Page header + actions + breadcrumbs"
    defp group_title("toolbar-search-filter-sort"), do: "Toolbar + search + filters + sort"

    defp group_title("table-empty-loading-error-pagination"),
      do: "Table + empty/loading/error/pagination"

    defp group_title("kpi-chart-table"), do: "KPI + chart + table"
    defp group_title("detail-header-metadata-actions"), do: "Detail header + metadata + actions"
    defp group_title("modal-confirm"), do: "Modal confirm"
    defp group_title("drawer-form"), do: "Drawer + form"
    defp group_title("tabs-subviews"), do: "Tabs + subviews"
    defp group_title(slug), do: state_label(slug)

    defp state_label(state) do
      state
      |> String.replace("-", " ")
      |> String.capitalize()
    end

    # Returns all Phase-189 primitive families (those with applicable_states) grouped by family name.
    # Card and foundation entries (without applicable_states) are excluded — they are rendered
    # in their own hand-authored sections above and below the registry-driven matrix.
    defp registry_families do
      ComponentRegistry.entries()
      |> Enum.filter(&Map.has_key?(&1, :applicable_states))
      |> Enum.group_by(& &1.family)
    end

    # Human-facing display label for a registry family header, sourced from the
    # approved Phase-189 UI-SPEC `####` component section headings (replaces the
    # earlier `String.upcase/1`, which rendered raw tokens like "FORM-FIELD").
    # The catch-all humanizes any future/unmapped family so a newly registered
    # primitive can never regress to an unstyled token.
    defp family_label("button"), do: "Button"
    defp family_label("input"), do: "Input"
    defp family_label("textarea"), do: "Textarea"
    defp family_label("checkbox"), do: "Checkbox"
    defp family_label("radio"), do: "Radio"
    defp family_label("toggle"), do: "Toggle switch"
    defp family_label("select"), do: "Select"
    defp family_label("form-field"), do: "Form field"
    defp family_label("status"), do: "Status badge"
    defp family_label("icon"), do: "Icon"
    defp family_label("money"), do: "Money"
    defp family_label("json-viewer"), do: "JSON viewer"
    defp family_label("spinner"), do: "Loading"
    defp family_label("tooltip"), do: "Tooltip"
    defp family_label("inline-id"), do: "Inline code / ID"
    defp family_label("id-badge"), do: "ID badge"
    defp family_label("empty-state"), do: "Empty state"
    defp family_label("theme-picker"), do: "Theme picker"
    defp family_label("segmented"), do: "Segmented filter"
    defp family_label("timeline"), do: "Timeline"

    defp family_label(family) when is_binary(family) do
      family
      |> String.split("-")
      |> Enum.map_join(" ", &String.capitalize/1)
    end

    # Renders the appropriate specimen for a given registry entry, state, and theme column.
    # The `theme` parameter ("light" or "dark") is used to scope element IDs so that the
    # same component rendered in both columns has unique DOM IDs (required by LiveView).
    # Single-column lab: specimens render once and follow the global theme.
    # "lab" is a fixed id-namespace passed through to do_render_specimen/4 so
    # specimen element ids stay unique on the page (no light/dark duplication).
    defp render_specimen(entry, state) do
      specimen = pick_specimen(entry.specimens, state)
      do_render_specimen(entry.family, state, specimen, "lab")
    end

    # Map a state name to its data-ax-force token. "pressed" has no distinct
    # visual in the design system, so it reuses the active treatment.
    defp force_token("pressed"), do: "active"
    defp force_token(state), do: state

    # Pick the best specimen for the given state: prefer one whose label mentions the state,
    # fall back to the first specimen.
    defp pick_specimen(specimens, state) do
      state_label = String.downcase(state)

      Enum.find(specimens, List.first(specimens), fn s ->
        String.downcase(s.label) =~ state_label
      end)
    end

    # ── Button ──────────────────────────────────────────────────────────────────
    defp do_render_specimen("button", "disabled", %{props: props, content: content}, _theme) do
      variant = Map.get(props, :variant, "primary")
      assigns = %{variant: variant, content: content || "Archived", __changed__: %{}}

      ~H"""
      <Button.button variant={@variant} type="button" disabled={true}><%= @content %></Button.button>
      """
    end

    defp do_render_specimen("button", "loading", %{props: props, content: content}, _theme) do
      variant = Map.get(props, :variant, "primary")
      assigns = %{variant: variant, content: content || "Saving…", __changed__: %{}}

      ~H"""
      <Button.button variant={@variant} type="button" loading={true}><%= @content %></Button.button>
      """
    end

    # hover / focus / active / pressed are pure-CSS pseudo-states — force them to
    # render visibly via data-ax-force (companion selectors in app.css). pressed
    # maps to the active visual (no separate pressed style exists).
    defp do_render_specimen("button", state, %{props: props, content: content}, _theme)
         when state in ["hover", "focus", "active", "pressed"] do
      variant = Map.get(props, :variant, "primary")

      assigns = %{
        variant: variant,
        content: content || "Action",
        force: force_token(state),
        __changed__: %{}
      }

      ~H"""
      <Button.button variant={@variant} type="button" data-ax-force={@force}><%= @content %></Button.button>
      """
    end

    defp do_render_specimen("button", _state, %{props: props, content: content}, _theme) do
      variant = Map.get(props, :variant, "primary")
      assigns = %{variant: variant, content: content || "Action", __changed__: %{}}

      ~H"""
      <Button.button variant={@variant} type="button"><%= @content %></Button.button>
      """
    end

    # ── Input ───────────────────────────────────────────────────────────────────
    defp do_render_specimen("input", "error", _specimen, theme) do
      assigns = %{id: "#{theme}-inp-error", __changed__: %{}}

      ~H"""
      <Input.input
        id={@id}
        name={"#{@id}n"}
        label="Email"
        errors={["is not a valid email address"]}
        value="not-an-email"
      />
      """
    end

    defp do_render_specimen("input", "disabled", _specimen, theme) do
      assigns = %{id: "#{theme}-inp-disabled", __changed__: %{}}

      ~H"""
      <Input.input
        id={@id}
        name={"#{@id}n"}
        label="Email"
        value="locked@example.com"
        disabled
      />
      """
    end

    defp do_render_specimen("input", "overflow", _specimen, theme) do
      assigns = %{id: "#{theme}-inp-overflow", __changed__: %{}}

      ~H"""
      <Input.input
        id={@id}
        name={"#{@id}n"}
        label="Customer ID"
        value="cus_1234567890abcdefghijklmnopqrstuvwxyz"
      />
      """
    end

    defp do_render_specimen("input", "focus", _specimen, theme) do
      assigns = %{id: "#{theme}-inp-focus", __changed__: %{}}

      ~H"""
      <Input.input
        id={@id}
        name={"#{@id}n"}
        label="Email"
        placeholder="name@example.com"
        data-ax-force="focus"
      />
      """
    end

    defp do_render_specimen("input", state, _specimen, theme) do
      assigns = %{id: "#{theme}-inp-#{state}", __changed__: %{}}

      ~H"""
      <Input.input
        id={@id}
        name={"#{@id}n"}
        label="Email"
        placeholder="name@example.com"
      />
      """
    end

    # ── Textarea ─────────────────────────────────────────────────────────────────
    defp do_render_specimen("textarea", "error", _specimen, theme) do
      assigns = %{id: "#{theme}-ta-error", __changed__: %{}}

      ~H"""
      <Textarea.textarea
        id={@id}
        name={"#{@id}n"}
        label="Notes"
        errors={["is too short (minimum is 10 characters)"]}
        value="Too short"
      />
      """
    end

    defp do_render_specimen("textarea", "disabled", _specimen, theme) do
      assigns = %{id: "#{theme}-ta-disabled", __changed__: %{}}

      ~H"""
      <Textarea.textarea
        id={@id}
        name={"#{@id}n"}
        label="Notes"
        value="This field is locked."
        disabled
      />
      """
    end

    defp do_render_specimen("textarea", "overflow", _specimen, theme) do
      assigns = %{id: "#{theme}-ta-overflow", __changed__: %{}}

      ~H"""
      <Textarea.textarea
        id={@id}
        name={"#{@id}n"}
        label="Notes"
        value={"Line one.\nLine two.\nLine three — a very long line that demonstrates how the textarea handles content beyond normal line length.\nLine four."}
      />
      """
    end

    defp do_render_specimen("textarea", "focus", _specimen, theme) do
      assigns = %{id: "#{theme}-ta-focus", __changed__: %{}}

      ~H"""
      <Textarea.textarea
        id={@id}
        name={"#{@id}n"}
        label="Notes"
        placeholder="Add notes here…"
        data-ax-force="focus"
      />
      """
    end

    defp do_render_specimen("textarea", state, _specimen, theme) do
      assigns = %{id: "#{theme}-ta-#{state}", __changed__: %{}}

      ~H"""
      <Textarea.textarea
        id={@id}
        name={"#{@id}n"}
        label="Notes"
        placeholder="Add notes here…"
      />
      """
    end

    # ── Checkbox ─────────────────────────────────────────────────────────────────
    defp do_render_specimen("checkbox", "selected", _specimen, theme) do
      assigns = %{id: "#{theme}-cb-selected", __changed__: %{}}

      ~H"""
      <Checkbox.checkbox
        id={@id}
        name={"#{@id}n"}
        label="Accept terms and conditions"
        checked={true}
      />
      """
    end

    defp do_render_specimen("checkbox", "disabled", _specimen, theme) do
      assigns = %{id: "#{theme}-cb-disabled", __changed__: %{}}

      ~H"""
      <Checkbox.checkbox
        id={@id}
        name={"#{@id}n"}
        label="Accept terms and conditions"
        disabled={true}
      />
      """
    end

    defp do_render_specimen("checkbox", "focus", _specimen, theme) do
      assigns = %{id: "#{theme}-cb-focus", __changed__: %{}}

      ~H"""
      <Checkbox.checkbox
        id={@id}
        name={"#{@id}n"}
        label="Accept terms and conditions"
        data-ax-force="focus"
      />
      """
    end

    defp do_render_specimen("checkbox", state, _specimen, theme) do
      assigns = %{id: "#{theme}-cb-#{state}", __changed__: %{}}

      ~H"""
      <Checkbox.checkbox
        id={@id}
        name={"#{@id}n"}
        label="Accept terms and conditions"
      />
      """
    end

    # ── Radio ────────────────────────────────────────────────────────────────────
    defp do_render_specimen("radio", "selected", _specimen, theme) do
      assigns = %{id: "#{theme}-rb-selected", __changed__: %{}}

      ~H"""
      <Radio.radio
        id={@id}
        name={"#{@id}n"}
        label="Starter plan"
        value="starter"
        checked={true}
      />
      """
    end

    defp do_render_specimen("radio", "disabled", _specimen, theme) do
      assigns = %{id: "#{theme}-rb-disabled", __changed__: %{}}

      ~H"""
      <Radio.radio
        id={@id}
        name={"#{@id}n"}
        label="Enterprise plan (contact sales)"
        value="enterprise"
        disabled={true}
      />
      """
    end

    defp do_render_specimen("radio", "focus", _specimen, theme) do
      assigns = %{id: "#{theme}-rb-focus", __changed__: %{}}

      ~H"""
      <Radio.radio
        id={@id}
        name={"#{@id}n"}
        label="Starter plan"
        value="starter"
        data-ax-force="focus"
      />
      """
    end

    defp do_render_specimen("radio", state, _specimen, theme) do
      assigns = %{id: "#{theme}-rb-#{state}", __changed__: %{}}

      ~H"""
      <Radio.radio
        id={@id}
        name={"#{@id}n"}
        label="Starter plan"
        value="starter"
      />
      """
    end

    # ── Toggle ───────────────────────────────────────────────────────────────────
    defp do_render_specimen("toggle", "selected", _specimen, theme) do
      assigns = %{id: "#{theme}-tg-selected", __changed__: %{}}

      ~H"""
      <Toggle.toggle
        id={@id}
        name={"#{@id}n"}
        label="Email notifications"
        on={true}
      />
      """
    end

    defp do_render_specimen("toggle", "disabled", _specimen, theme) do
      assigns = %{id: "#{theme}-tg-disabled", __changed__: %{}}

      ~H"""
      <Toggle.toggle
        id={@id}
        name={"#{@id}n"}
        label="Email notifications"
        disabled={true}
      />
      """
    end

    defp do_render_specimen("toggle", "focus", _specimen, theme) do
      assigns = %{id: "#{theme}-tg-focus", __changed__: %{}}

      ~H"""
      <Toggle.toggle
        id={@id}
        name={"#{@id}n"}
        label="Email notifications"
        data-ax-force="focus"
      />
      """
    end

    defp do_render_specimen("toggle", state, _specimen, theme) do
      assigns = %{id: "#{theme}-tg-#{state}", __changed__: %{}}

      ~H"""
      <Toggle.toggle
        id={@id}
        name={"#{@id}n"}
        label="Email notifications"
      />
      """
    end

    # ── Theme picker ─────────────────────────────────────────────────────────────
    defp do_render_specimen("theme-picker", "selected", _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <ThemePicker.theme_picker theme="light" />
      """
    end

    defp do_render_specimen("theme-picker", _state, _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <ThemePicker.theme_picker theme="system" />
      """
    end

    # ── Segmented filter ─────────────────────────────────────────────────────────
    # Mirrors the DataTable.filter_input/1 :segmented rendering. The "active" specimen
    # highlights "Live"; the default specimen highlights "All". Both render the variant
    # class `ax-segmented-option` (render-coverage guardrail).
    defp do_render_specimen("segmented", state, _specimen, _theme) do
      active = if state == "active", do: "true", else: ""
      assigns = %{active: active, __changed__: %{}}

      ~H"""
      <div class="ax-segmented" role="radiogroup" aria-label="Live mode">
        <label
          :for={{value, label} <- [{"", "All"}, {"true", "Live"}, {"false", "Test"}]}
          class={["ax-segmented-option", value == @active && "ax-segmented-option-active"]}
        >
          <input type="radio" name="lab-segmented" value={value} checked={value == @active} class="ax-visually-hidden" />
          <span><%= label %></span>
        </label>
      </div>
      """
    end

    # ── Select ───────────────────────────────────────────────────────────────────
    defp do_render_specimen("select", "error", _specimen, theme) do
      assigns = %{id: "#{theme}-sel-error", __changed__: %{}}

      ~H"""
      <Select.select
        id={@id}
        name={"#{@id}n"}
        label="Country"
        errors={["is required"]}
        prompt="Select a country"
        options={[{"United States", "us"}, {"United Kingdom", "gb"}]}
      />
      """
    end

    defp do_render_specimen("select", "disabled", _specimen, theme) do
      assigns = %{id: "#{theme}-sel-disabled", __changed__: %{}}

      ~H"""
      <Select.select
        id={@id}
        name={"#{@id}n"}
        label="Country"
        value="us"
        disabled
        options={[{"United States", "us"}]}
      />
      """
    end

    defp do_render_specimen("select", "focus", _specimen, theme) do
      assigns = %{id: "#{theme}-sel-focus", __changed__: %{}}

      ~H"""
      <Select.select
        id={@id}
        name={"#{@id}n"}
        label="Country"
        prompt="Select a country"
        options={[{"United States", "us"}, {"United Kingdom", "gb"}, {"Canada", "ca"}]}
        data-ax-force="focus"
      />
      """
    end

    defp do_render_specimen("select", state, _specimen, theme) do
      assigns = %{id: "#{theme}-sel-#{state}", __changed__: %{}}

      ~H"""
      <Select.select
        id={@id}
        name={"#{@id}n"}
        label="Country"
        prompt="Select a country"
        options={[{"United States", "us"}, {"United Kingdom", "gb"}, {"Canada", "ca"}]}
      />
      """
    end

    # ── Form-field ───────────────────────────────────────────────────────────────
    defp do_render_specimen("form-field", "error", _specimen, theme) do
      assigns = %{id: "#{theme}-ff-error", __changed__: %{}}

      ~H"""
      <div class="ax-field ax-form-field">
        <label class="ax-field-label" for={@id}>Email address</label>
        <input id={@id} name={"#{@id}n"} type="email" class="ax-field-control ax-field-control-error" aria-invalid="true" value="not-an-email" />
        <p class="ax-field-error">Please enter a valid email address.</p>
      </div>
      """
    end

    defp do_render_specimen("form-field", state, _specimen, theme) do
      assigns = %{id: "#{theme}-ff-#{state}", __changed__: %{}}

      ~H"""
      <div class="ax-field ax-form-field">
        <label class="ax-field-label" for={@id}>Email address</label>
        <input id={@id} name={"#{@id}n"} type="email" class="ax-field-control" placeholder="name@example.com" />
        <p class="ax-field-help">We will send billing notifications to this address.</p>
      </div>
      """
    end

    # ── Status badge ─────────────────────────────────────────────────────────────
    defp do_render_specimen("status", "overflow", %{props: props}, _theme) do
      tone = Map.get(props, :tone, "moss")
      assigns = %{tone: tone, __changed__: %{}}

      ~H"""
      <StatusBadge.status_badge tone={@tone} status={:active} label="Requires additional customer authentication step" />
      """
    end

    defp do_render_specimen("status", _state, %{props: props}, _theme) do
      tone = Map.get(props, :tone, "moss")
      {status, _label} = tone_to_status(tone)
      assigns = %{tone: tone, status: status, __changed__: %{}}

      ~H"""
      <StatusBadge.status_badge tone={@tone} status={@status} />
      """
    end

    # ── Icon ─────────────────────────────────────────────────────────────────────
    defp do_render_specimen("icon", _state, _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <Icon.icon name={:invoices} size="md" />
      """
    end

    # ── MoneyFormatter ────────────────────────────────────────────────────────────
    defp do_render_specimen("money", "overflow", _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <MoneyFormatter.money_formatter amount_minor={99_999_999_999} currency={:usd} class="ax-money-display" />
      """
    end

    defp do_render_specimen("money", _state, _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <MoneyFormatter.money_formatter amount_minor={4200} currency={:usd} class="ax-money-display" />
      """
    end

    # ── JsonViewer ────────────────────────────────────────────────────────────────
    defp do_render_specimen("json-viewer", "empty", _specimen, theme) do
      assigns = %{id: "#{theme}-jv-empty", __changed__: %{}}

      ~H"""
      <JsonViewer.json_viewer id={@id} payload={%{}} label="Empty payload" />
      """
    end

    defp do_render_specimen("json-viewer", "overflow", _specimen, theme) do
      assigns = %{id: "#{theme}-jv-overflow", __changed__: %{}}

      ~H"""
      <JsonViewer.json_viewer
        id={@id}
        payload={%{"subscription" => %{"id" => "sub_1234567890abcdefghijklmnopqrstuvwxyz", "customer" => %{"id" => "cus_1234567890abcdefghijklmnopqrstuvwxyz", "email" => "customer.with.very.long.email@example-domain-quite-long.com"}}}}
        label="Nested payload"
      />
      """
    end

    defp do_render_specimen("json-viewer", state, _specimen, theme) do
      assigns = %{id: "#{theme}-jv-#{state}", __changed__: %{}}

      ~H"""
      <JsonViewer.json_viewer
        id={@id}
        payload={%{"id" => "evt_1234", "type" => "payment_intent.succeeded", "amount" => 4200}}
        label="Webhook payload"
      />
      """
    end

    # ── Spinner ──────────────────────────────────────────────────────────────────
    defp do_render_specimen("spinner", _state, _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <Spinner.spinner size="sm" label="Loading subscription data…" />
      """
    end

    # ── Tooltip ──────────────────────────────────────────────────────────────────
    defp do_render_specimen("tooltip", "overflow", _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <Tooltip.tooltip content="This action will permanently delete the subscription and all associated invoice history from the billing record" position="above">
        <Button.button variant="ghost" type="button">Delete</Button.button>
      </Tooltip.tooltip>
      """
    end

    defp do_render_specimen("tooltip", _state, _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <Tooltip.tooltip content="Copy to clipboard" position="above">
        <Button.button variant="ghost" type="button">Copy</Button.button>
      </Tooltip.tooltip>
      """
    end

    # ── InlineId ──────────────────────────────────────────────────────────────────
    defp do_render_specimen("inline-id", "overflow", _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <InlineId.inline_id id_value="cus_1234567890abcdefghijklmnopqrstuvwxyz" class="ax-inline-id-short" />
      """
    end

    defp do_render_specimen("inline-id", _state, _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <InlineId.inline_id id_value="cus_ABC123" class="ax-inline-id-short" />
      """
    end

    # ── IdBadge ───────────────────────────────────────────────────────────────────
    defp do_render_specimen("id-badge", _state, _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <IdBadge.id_badge id="lab-id-badge-default" id_value="cus_phase191_host_1" />
      """
    end

    # ── EmptyState ────────────────────────────────────────────────────────────────
    defp do_render_specimen("empty-state", _state, _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <EmptyState.empty_state
        icon={:inbox}
        title="No subscriptions yet"
        body="Create a subscription to start billing your customers."
        class="ax-empty-no-data"
      />
      """
    end

    # ── Timeline ─────────────────────────────────────────────────────────────────
    defp do_render_specimen("timeline", "empty", _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <Timeline.timeline items={[]} />
      """
    end

    defp do_render_specimen("timeline", _state, _specimen, _theme) do
      sample = [
        %{
          title: "Payment succeeded",
          at: "Apr 15, 2026 09:14",
          status: :succeeded,
          body: "Invoice in_123 paid"
        },
        %{
          title: "Webhook retrying",
          at: "Apr 15, 2026 09:12",
          status: :retrying,
          body: "payment_intent.payment_failed",
          details: "{\"attempt\": 2}"
        },
        %{
          title: "Subscription canceled",
          at: "Apr 14, 2026 17:02",
          status: :canceled,
          meta: "Ends at period end"
        }
      ]

      assigns = %{sample: sample, __changed__: %{}}

      ~H"""
      <Timeline.timeline items={@sample} />
      """
    end

    # ── Stat strip ─────────────────────────────────────────────────────────────────
    defp do_render_specimen("stat-strip", _state, _specimen, _theme) do
      assigns = %{__changed__: %{}}

      ~H"""
      <dl class="ax-stat-strip" aria-label="Customer summary">
        <div class="ax-stat">
          <dt class="ax-stat-label">Customers</dt>
          <dd class="ax-stat-value">1,284</dd>
        </div>
        <div class="ax-stat">
          <dt class="ax-stat-label">With payment method</dt>
          <dd class="ax-stat-value ax-stat-value--moss">972</dd>
        </div>
        <div class="ax-stat">
          <dt class="ax-stat-label">Canceling</dt>
          <dd class="ax-stat-value ax-stat-value--amber">18</dd>
        </div>
      </dl>
      """
    end

    # ── Fallback ──────────────────────────────────────────────────────────────────
    defp do_render_specimen(family, state, _specimen, _theme) do
      assigns = %{family: family, state: state, __changed__: %{}}

      ~H"""
      <span class="ax-type-code-xs ax-muted">[@<%= @family %>/<%= @state %>]</span>
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
      |> assign(:active_organization_name, admin["active_organization_name"])
    end

    defp fake_processor? do
      Application.get_env(:accrue, :processor, Accrue.Processor.Fake) == Accrue.Processor.Fake
    end

    defp default_brand do
      %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
    end

    # Token-swatch classification. Color tokens get a resolved-color chip; structural
    # tokens (fonts, lengths, z-index, shadows, motion) can't render as a background,
    # so they get a small "kind" tag instead of a misleading empty chip.
    defp color_token?(token), do: not non_color_token?(token)

    defp non_color_token?(token) do
      String.contains?(token, "-font") or
        String.contains?(token, "tracking") or
        String.contains?(token, "shadow") or
        String.contains?(token, "transition") or
        String.starts_with?(token, "--ax-z-") or
        token == "--ax-measure"
    end

    defp token_kind(token) do
      cond do
        String.contains?(token, "-font") -> "font"
        String.contains?(token, "tracking") -> "tracking"
        String.contains?(token, "shadow") -> "shadow"
        String.contains?(token, "transition") -> "motion"
        String.starts_with?(token, "--ax-z-") -> "z-index"
        token == "--ax-measure" -> "measure"
        true -> "color"
      end
    end

    # Maps a status badge tone to a representative status atom and label.
    defp tone_to_status("moss"), do: {:active, "Active"}
    defp tone_to_status("cobalt"), do: {:trialing, "Trialing"}
    defp tone_to_status("amber"), do: {:past_due, "Past due"}
    defp tone_to_status("slate"), do: {:canceled, "Canceled"}
    defp tone_to_status("ink"), do: {:failed, "Failed"}
    defp tone_to_status(_), do: {:active, "Active"}
  end
end
