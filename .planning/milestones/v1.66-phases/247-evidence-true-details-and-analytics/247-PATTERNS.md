# Phase 247: Evidence-True Details and Analytics - Pattern Map

**Mapped:** 2026-10-11  
**Files analyzed:** 9 likely production files  
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/components/app_shell.ex` | component | request-response | same file, shared `AppShell` shell | exact |
| `accrue_admin/assets/js/hooks/clipboard.js` | utility | event-driven | same file, `Clipboard` hook | exact |
| `accrue_admin/lib/accrue_admin/components/detail.ex` | component | transform | same file, detail sections/summary list/card | exact |
| `accrue_admin/lib/accrue_admin/components/page_header.ex` | component | transform | same file, `PageHeader` | exact |
| `accrue_admin/lib/accrue_admin/components/json_viewer.ex` | component | event-driven | same file, payload tabs/tree/copy | exact |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | controller | request-response | same file, scoped detail/replay/history | exact |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | controller | request-response | same file, scoped async analytics and metric rendering | exact |
| `accrue_admin/lib/accrue_admin/components/kpi_card.ex` | component | transform | same file, metric value/meta/delta slots | exact |
| `accrue_admin/lib/accrue_admin/copy.ex` | utility | transform | same file, recovery and webhook copy functions | exact |

These are likely existing files to refine, not a requirement to create every listed path. No service, query, migration, or test files are assigned: the phase contracts call for presentation and copy changes while preserving query and action behavior. A timestamp component or hook may be introduced at the planner's discretion; closest analogs are `Detail` and `Clipboard` below.

## Pattern Assignments

### Shared shell and timestamp preference

**Target:** `accrue_admin/lib/accrue_admin/components/app_shell.ex`  
**Analog:** same file, shared shell markup and navigation setup.

The component uses Phoenix function-component attrs and one shared shell around every mounted LiveView. The shell already owns `Topbar`, which is the likely placement seam for a single persistent Local/UTC control. Keep per-page state out of this shared presentation component.

```elixir
alias AccrueAdmin.Components.{Sidebar, Topbar}
alias AccrueAdmin.Nav

def app_shell(assigns) do
  assigns = assign(assigns, :nav_items,
    Nav.items(assigns.mount_path, assigns.current_path, assigns.nav_attention_counts)
  )
  ~H"""
  <div id="accrue-admin-shell" class="ax-shell" ...>
    <Sidebar.sidebar brand={@brand} current_path={@current_path} items={@nav_items} />
    ...
    <Topbar.topbar theme={@theme} theme_forced={Map.get(@brand, :theme_forced?, false)} />
    <main id="main-content"><%= render_slot(@inner_block) %></main>
  </div>
  """
end
```

**Source lines:** `app_shell.ex:8-27,50-59,86-98`. For timestamp markup, prefer a small reusable Phoenix component following `Detail`'s attrs/template pattern (`detail.ex:22-36`); server-render UTC as the initial text and retain the unmodified ISO string separately for copying.

### Browser timestamp formatting and exact clipboard interaction

**Target:** `accrue_admin/assets/js/hooks/clipboard.js` (and any new time-format hook/helper)  
**Analog:** same file, per-element LiveView `Clipboard` hook and first-paint initializer.

```javascript
export const Clipboard = {
  mounted() {
    this.el.addEventListener("click", async () => {
      const text = this.el.dataset.clipboardText || "";
      if (!navigator.clipboard?.writeText) return;
      await navigator.clipboard.writeText(text);
      this.el.dataset.copied = "true";
    });
  }
};
```

**Source lines:** `clipboard.js:6-19,21-40`. Reuse the mounted hook lifecycle so newly rendered LiveView nodes receive behavior. Extend it to report success only after the awaited promise resolves, and expose an accessible/manual-copy failure state for absent API or rejection. Keep the exact source ISO in `data-clipboard-text`; local formatting must not round or replace that payload. For hook registration and startup, copy imports/registration from `accrue_admin/assets/js/app.js:1-14,34-49`.

### Shared detail metadata and hierarchy

**Target:** `accrue_admin/lib/accrue_admin/components/detail.ex`  
**Analog:** same file, `detail_section/1`, `detail_field_list/1`, `summary_list/1`, `summary_card/1`.

```elixir
attr(:title, :string, required: true)
slot(:actions)
slot(:inner_block, required: true)

def detail_section(assigns) do
  ~H"""
  <section class="ax-detail-section">
    <header class="ax-detail-section-head">
      <h3 class="ax-detail-section-title"><%= @title %></h3>
      <div :if={@actions != []} class="ax-detail-section-actions"><%= render_slot(@actions) %></div>
    </header>
    <%= render_slot(@inner_block) %>
  </section>
  """
end
```

**Source lines:** `detail.ex:22-36`; metadata row and copy-action mechanics are at `detail.ex:58-103`. Keep values rendered by callers, so IDs can continue to use the established `InlineId`/`IdBadge` copy treatment. A `Copy details` summary should be an explicit allowlist assembled from visible fields, not a serialization of the full detail or payload.

**Page header analog:** `accrue_admin/lib/accrue_admin/components/page_header.ex:12-56` uses `Breadcrumbs`, title, description and bounded action/filter slots. Breadcrumbs are rendered as native anchors/current-page text in `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex:10-28`; keep destination labels tied to real navigation parents.

### Webhook identity, replay action and history disclosures

**Target:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex`  
**Analog:** same file, scoped mount/reload, replay action band, and lazy Activity disclosure.

```elixir
<Detail.summary_card eyebrow="Webhook inspector" title={webhook_heading(assigns)}>
  <:facts :if={@webhook}>
    <span><%= @webhook.processor_event_id %></span>
    <span><%= humanize(@webhook.status) %></span>
    <span>received <%= format_datetime(@webhook.received_at) %></span>
  </:facts>
</Detail.summary_card>

<section :if={@webhook} class="ax-detail-section" data-ax-action-band>
  <h2>Replay delivery</h2>
  <p><%= replay_copy(assigns) %></p>
  <button :if={replayable?(@webhook)} phx-click="prepare_replay">Replay webhook</button>
</section>

<details :if={@webhook} data-ax-lazy-activity phx-hook="PreserveDisclosure" phx-click="load_activity">
  <summary>Activity</summary>
  ...
</details>
```

**Source lines:** `webhook_live.ex:202-250,260-285`; scoped mount and action handlers are `webhook_live.ex:20-115`. Preserve current owner scope, action-time authorization, step-up and confirmation paths. Keep accepted/queued feedback distinct from completed delivery. Retain lazy disclosure behavior and expose a visible summary affordance with expanded state.

### Payload disclosure and JSON controls

**Target:** `accrue_admin/lib/accrue_admin/components/json_viewer.ex`  
**Analog:** same file, exact JSON normalization, tabs and separate payload copy control.

```elixir
raw_json = Jason.encode_to_iodata!(normalized, pretty: true) |> IO.iodata_to_binary()
...
<nav class="ax-tabs" aria-label="Payload views">
  <button :for={tab <- ["tree", "raw", "copy"]} ...>
    <%= String.capitalize(tab) %>
  </button>
</nav>
...
<button phx-hook="Clipboard" data-clipboard-text={@raw_json}>Copy payload</button>
```

**Source lines:** `json_viewer.ex:14-23,32-63`; native nested `<details>/<summary>` disclosure is `json_viewer.ex:81-97`. Keep Tree/Raw labels consistent and Copy separate from view selection, preserve exact serialized JSON and keyboard support.

### Recovery metrics, KPI copy and UTC window

**Targets:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`, `components/kpi_card.ex`, `components/window_selector.ex`, and `copy.ex`  
**Analogs:** same files, existing async scoped query result presentation and semantic slots.

Recovery already queries using owner scope and UTC boundaries, then pairs returned currencies while preserving unavailable amounts:

```elixir
start_async(:recovery_query, fn ->
  %{stats: Dunning.recovered_vs_lost_mrr(owner_scope, since: since, until: until),
    funnel: Dunning.funnel(owner_scope, since: since, until: until),
    at_risk: Dunning.at_risk_subscriptions(owner_scope, since: since, until: until)}
end)
...
recovered_str: format_recovery_money(recovered && recovered.cents, ...),
exhausted_str: format_recovery_money(lost && lost.cents, ...)
```

**Source lines:** `recovery_live.ex:27-48,74-114,131-136`. Preserve owner scope, UTC window, calculations, actual zero, nil/unavailable and unsupported currency distinctions. Modify only rendering/copy where the phase requires it.

`KpiCard` uses ordinary label/value with optional delta and meta slots (`kpi_card.ex:11-24,37-67`). Put concise metric definitions in ordinary descriptive copy rather than prose delta decoration. `WindowSelector` uses URL patch links and explicitly announces `Time window (UTC)` (`window_selector.ex:20-48`); align its placement and spacing without changing the UTC window contract.

```elixir
def recovery_recovered_mrr_label(currency),
  do: "Recovered MRR (#{String.upcase(to_string(currency))})"

def recovery_exhausted_mrr_label(currency),
  do: "Exhausted MRR (#{String.upcase(to_string(currency))})"
```

**Source lines:** `copy.ex:984-998`. Keep copy definitions centralized here, revise unsupported claims such as “Money Saved” / “Churned Revenue,” and make help-link copy name its actual documentation destination. Recovery rendering that consumes these functions is `recovery_live.ex:150-193`.

## Shared Patterns

### Shared shell ownership

**Source:** `accrue_admin/lib/accrue_admin/components/app_shell.ex:50-98`  
**Apply to:** the one Local/UTC preference and shared navigation labels. Keep the preference in shell-owned chrome so it is not repeated per timestamp or page.

### Accessible interaction and copy

**Source:** `accrue_admin/assets/js/hooks/clipboard.js:6-19`; `accrue_admin/lib/accrue_admin/components/detail.ex:73-103`  
**Apply to:** timestamps, IDs, and optional investigation summaries. Use native buttons/links, preserve focus/touch sizing from the UI contract, announce only confirmed copy success, and keep fallback values selectable.

### Evidence and owner scope

**Source:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex:20-115`; `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:27-48`  
**Apply to:** all detail links/actions and summary copy. Continue to derive data and destinations from the current owner scope; do not change replay eligibility/action handlers or recovery calculations as part of presentation edits.

### Metric state and language

**Source:** `recovery_live.ex:74-114,131-136`; `copy.ex:976-998`  
**Apply to:** recovery cards and help text. Keep actual zero, absent value, unsupported currency and observed values distinct; explain metric meaning in short body/help text, and ensure help describes its destination.

## No Analog Found

None for the likely modified files. If planning introduces a dedicated timestamp component/hook or a shared “Copy details” control, base it on `Detail` component conventions and the mounted `Clipboard` hook rather than creating a new pattern family.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/components/`, `accrue_admin/lib/accrue_admin/live/`, `accrue_admin/lib/accrue_admin/copy.ex`, and `accrue_admin/assets/js/`.  
**Files scanned:** 12 tracked source analogs read.  
**Pattern extraction date:** 2026-10-11
