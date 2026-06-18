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
      FlashGroup,
      Icon,
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
      Toggle,
      Tooltip
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
            <h2 class="ax-display">Component Kitchen</h2>
            <p class="ax-page-description">Primitive and form components — full state matrix. Use the topbar theme toggle to review light and dark.</p>
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
                <h3 class="ax-type-eyebrow"><%= String.upcase(family) %></h3>
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

    # Returns all Phase-189 primitive families (those with applicable_states) grouped by family name.
    # Card and foundation entries (without applicable_states) are excluded — they are rendered
    # in their own hand-authored sections above and below the registry-driven matrix.
    defp registry_families do
      ComponentRegistry.entries()
      |> Enum.filter(&Map.has_key?(&1, :applicable_states))
      |> Enum.group_by(& &1.family)
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
      assigns = %{variant: variant, content: content || "Action", force: force_token(state), __changed__: %{}}

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
