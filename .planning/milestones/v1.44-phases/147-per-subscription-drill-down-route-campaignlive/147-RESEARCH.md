# Phase 147: Per-subscription drill-down route + CampaignLive — Research

**Researched:** 2026-05-27
**Domain:** Elixir/Phoenix LiveView analytics drill-down, Ecto query composition, Phoenix.Component
**Confidence:** HIGH

## Summary

Phase 147 adds the operator drill-down path: clicking any at-risk table row navigates to `/billing/analytics/recovery/subscriptions/:id`, which renders the full dunning campaign history for that subscription. The work divides into three layers — (1) two new public functions in `Accrue.Analytics.Dunning`, (2) a new `AccrueAdmin.Live.Analytics.CampaignLive` LiveView, and (3) a new `AccrueAdmin.Components.CampaignTimeline` Phoenix.Component — plus one router line addition.

All infrastructure is in place. `Accrue.Events.timeline_for/3` already exists with the exact signature needed. The `accrue_admin` live_session, breadcrumb pattern, assign_shell pattern, StatusBadge component, and `format_money/3` call pattern are all established in prior phases. The Phase 146 AtRiskTable already renders the row-click link pointing to the Phase 147 URL — Phase 147 makes that URL resolve.

One critical discrepancy exists between the CONTEXT.md description and live code: `invoice_id` stored in `dunning.campaign_started` event data is the **Stripe processor ID** (e.g., `"in_xxxx"`), not an Accrue UUID — confirmed by both `emit_campaign_started/2` (line 1263) and the `at_risk_subscriptions/1` join (`cs.data->>'invoice_id' = i.processor_id`). The `invoices_for_campaign/2` function must join on `accrue_invoices.processor_id`, not `accrue_invoices.id`. The CONTEXT.md `## Decisions D-02` describes it as "an Accrue Invoice UUID" — this is incorrect and would produce empty maps if followed literally.

**Primary recommendation:** Implement the three functions in `dunning.ex` first (`campaign_timeline/2`, `campaign_timeline_grouped/2`, `invoices_for_campaign/2`), test them, then wire the LiveView and component.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** `campaign_timeline/2` returns `[Event.t()]` — thin wrapper around `Accrue.Events.timeline_for("Subscription", subscription_id, ...)` filtered to `dunning.*` event types, ordered chronologically (`asc: e.inserted_at, asc: e.id`). Return type is NOT enriched.

**D-02:** `invoices_for_campaign/2` signature: `(subscription_id :: String.t(), opts :: keyword()) :: %{String.t() => map()}`. Returns a map keyed by `invoice_id` string. Joins Invoice → PaymentMethod. Map value: `%{status:, amount_due_cents:, card_last4:, card_brand:}`. Pre-v1.44 events without `invoice_id` in data: gracefully handled.

**D-03:** `CampaignLive.mount/3` calls both functions and assigns independently — `@arcs` and `@invoice_map`. Two DB queries in mount.

**D-04:** Cross-package boundary enforced: `CampaignLive` calls ONLY `Accrue.Analytics.Dunning.*`. No `Ecto.Query`, `Accrue.Repo`, or `Accrue.Billing.*` aliases in `accrue_admin`. Enforced by boundary assertion test.

**D-05:** `campaign_timeline_grouped/2` is a thin pure function (no DB call). Groups via `Enum.chunk_by(&(&1.type == "dunning.campaign_started"), events)`. Returns `[{anchor :: String.t() | nil, events :: [Event.t()]}]`.

**D-06:** The `dunning.step_sent`-no-`campaign_anchor` edge case handled by `chunk_by` boundary logic. No anchor assignment on step events.

**D-07:** Still-active campaign (no terminal event): last arc has events ending with most recent `dunning.step_sent`. Rendered as open section.

**D-08:** Both `campaign_timeline/2` and `campaign_timeline_grouped/2` are public API functions in `Accrue.Analytics.Dunning`.

**D-09:** New `AccrueAdmin.Components.CampaignTimeline` at `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex`. Three distinct row variants: `dunning.campaign_started` (anchor row), `dunning.step_sent` × N (retry rows), `dunning.recovered` | `dunning.exhausted` (terminal row).

**D-10:** `CampaignTimeline` embeds `StatusBadge.status_badge/1` and `Accrue.Invoices.Render.format_money/3` directly.

**D-11:** Existing `AccrueAdmin.Components.Timeline` is NOT modified.

**D-12:** `CampaignTimeline` accepts `arcs` and `invoice_map` as attrs.

**D-13:** `CampaignLive` uses `mount/3`-based data loading, not `handle_params/3`. `mount(%{"id" => subscription_id}, session, socket)`.

**D-14:** No window selector on CampaignLive. Shows full dunning history regardless of window.

**D-15:** Not-found handling: empty list → "No dunning history found" empty state, NOT 404.

**D-16:** New route: `live("/recovery/subscriptions/:id", CampaignLive, :show)` inside `scope "/analytics", AccrueAdmin.Live.Analytics` block, sibling to `live("/recovery", RecoveryLive, :index)`.

### Claude's Discretion

- Exact Ecto query shape for `campaign_timeline/2`: in-Ecto `where: e.type in ^dunning_types` (recommended) vs in-memory filter.
- `invoices_for_campaign/2` join shape: single compound query or two-step load.
- Breadcrumb for CampaignLive: `[%{label: "Analytics"}, %{label: "Recovery", href: base_path <> "/analytics/recovery"}, %{label: "Subscription"}]`.
- CSS class names: `ax-campaign-timeline-anchor`, `ax-campaign-timeline-step`, `ax-campaign-timeline-terminal`.
- Step numbering: 1-indexed within arc. "Attempt 1", "Attempt 2", etc.
- `invoices_for_campaign/2` opts: recommend NO window bounds.

### Deferred Ideas (OUT OF SCOPE)

- Window selector on CampaignLive.
- MRR-at-risk per campaign arc.
- Direct link from CampaignLive to Invoice detail or Subscription detail.
- `campaign_timeline/2` accepting `:types` opt.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DAN-05 | `Accrue.Analytics.Dunning.campaign_timeline(subject_id, opts \\ [])` — thin wrapper around `Accrue.Events.timeline_for/3` filtered to `dunning.*` event types, chronologically ordered. Powers drill-down. | `timeline_for/3` at `accrue/lib/accrue/events.ex:262` confirmed. Dunning type list `@dunning_lifecycle_types` already defined in dunning.ex. |
| DAN-12 | Per-subscription drill-down route + view: `/billing/analytics/recovery/subscriptions/:id`, `CampaignLive` renders timeline variants, linked invoice/payment-method context, row-click from at-risk table. | Router scope location confirmed (lines 75–77). AtRiskTable link confirmed pointing to this URL. All component patterns established. |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Campaign timeline query | API/Backend (`Accrue.Analytics.Dunning`) | — | Read-path analytics, no LiveView socket in always-compiled code; cross-package boundary enforced |
| Invoice context query | API/Backend (`Accrue.Analytics.Dunning`) | — | Same boundary: admin LiveView calls ONLY `Dunning.*`; Ecto query lives in core |
| Timeline grouping | API/Backend (pure Elixir, no DB) | — | `Enum.chunk_by` is pure; no DB call in `campaign_timeline_grouped/2` |
| Route declaration | Frontend Server (Router macro) | — | `live("/recovery/subscriptions/:id", CampaignLive, :show)` inside live_session |
| CampaignLive data loading | Frontend Server (LiveView mount) | — | `mount/3` calls two analytics functions; no socket runtime in core |
| CampaignTimeline rendering | Frontend Server (Phoenix.Component) | — | Pure HEEx render; no slots, three row variants per event type |
| Auth | Frontend Server (inherited live_session) | — | `live_session :accrue_admin` with `{AccrueAdmin.AuthHook, :ensure_admin}` already declared; no changes |

---

## Standard Stack

### Core (no new dependencies — zero new mix deps for this phase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | `~> 1.1` | LiveView + Phoenix.Component | Already required core dep; `CampaignLive` uses `use Phoenix.LiveView` |
| `ecto` | `~> 3.13` | Query composition | `campaign_timeline/2` and `invoices_for_campaign/2` use `Ecto.Query` |
| `postgrex` | `~> 0.22` | PG driver | Backing `Accrue.Repo.all/1` calls |

No new packages are introduced in Phase 147. [VERIFIED: live codebase grep]

## Package Legitimacy Audit

No external packages are installed in this phase. This section is intentionally minimal.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| (none) | — | — | — | — | — | N/A |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Operator browser
       |
       | GET /billing/analytics/recovery/subscriptions/:id
       v
[AccrueAdmin.Router — live_session :accrue_admin]
       |
       | (auth inherited from Phase 143 on_mount hook)
       v
[AccrueAdmin.Live.Analytics.CampaignLive]
  mount/3
       |---> Accrue.Analytics.Dunning.campaign_timeline/2
       |           |---> Accrue.Events.timeline_for("Subscription", id)
       |           |     (DB query: accrue_events WHERE subject_type/id ORDER BY inserted_at ASC)
       |           \---> in-Ecto filter: WHERE type IN dunning_lifecycle_types
       |
       |---> Accrue.Analytics.Dunning.campaign_timeline_grouped/2
       |           (pure: Enum.chunk_by, no DB call)
       |           \---> assigns @arcs :: [{anchor | nil, [Event.t()]}]
       |
       \---> Accrue.Analytics.Dunning.invoices_for_campaign/2
                   (DB query: accrue_invoices JOIN accrue_customers JOIN accrue_payment_methods)
                   \---> assigns @invoice_map :: %{stripe_invoice_id => %{status, amount_due_cents, card_last4, card_brand}}
       |
       v
[AccrueAdmin.Components.CampaignTimeline]
  for {anchor, events} <- @arcs
    for event <- events
      | dunning.campaign_started  -> anchor row (date, failure reason if available)
      | dunning.step_sent × N     -> retry row (attempt N, invoice amount+status)
      | dunning.recovered         -> terminal row (moss/green, "Recovered")
      | dunning.exhausted         -> terminal row (amber, "Exhausted")
        |-> StatusBadge.status_badge/1 (invoice status)
        |-> Accrue.Invoices.Render.format_money/3 (amount display)
```

### Recommended Project Structure

```
accrue/lib/accrue/analytics/
  dunning.ex                          # ADD: campaign_timeline/2, campaign_timeline_grouped/2, invoices_for_campaign/2

accrue_admin/lib/accrue_admin/
  router.ex                           # ADD: live("/recovery/subscriptions/:id", CampaignLive, :show)
  live/analytics/
    campaign_live.ex                  # NEW
  components/
    campaign_timeline.ex              # NEW

accrue/test/accrue/analytics/
  dunning_test.exs                    # ADD: campaign_timeline/2, grouped/2, invoices_for_campaign/2 tests

accrue_admin/test/accrue_admin/live/analytics/
  campaign_live_test.exs              # NEW
  recovery_live_test.exs              # ADD: row-click link assertion
```

### Pattern 1: `campaign_timeline/2` — In-Ecto filter on dunning types

**What:** Thin wrapper calling `timeline_for/3` with an additional `where: e.type in ^dunning_types` clause in the query, rather than in-memory filtering.
**When to use:** This phase. More efficient — avoids fetching non-dunning events from DB.

```elixir
# Source: accrue/lib/accrue/analytics/dunning.ex (existing module)
# accrue/lib/accrue/events.ex lines 261-273 (confirmed signature)

@dunning_lifecycle_types ~w[dunning.campaign_started dunning.step_sent dunning.recovered dunning.exhausted]

@doc """
Returns `dunning.*` events for a subscription in chronological order.

Thin wrapper around `Accrue.Events.timeline_for/3` filtered to dunning
lifecycle event types.

## Options

  * `:limit` — max rows (default 1_000 from timeline_for/3)

@since "1.4.0"
"""
@spec campaign_timeline(String.t(), keyword()) :: [Event.t()]
def campaign_timeline(subscription_id, opts \\ []) when is_binary(subscription_id) and is_list(opts) do
  limit = Keyword.get(opts, :limit, 1_000)

  from(e in Event,
    where: e.subject_type == "Subscription" and e.subject_id == ^subscription_id,
    where: e.type in ^@dunning_lifecycle_types,
    order_by: [asc: e.inserted_at, asc: e.id],
    limit: ^limit
  )
  |> Repo.all()
  |> Enum.map(&upcast_to_current/1)
end
```

Note: `upcast_to_current/1` is a private function in `Accrue.Events` — it is NOT accessible from `Accrue.Analytics.Dunning`. The recommendation above is aspirational. Since the dunning module cannot call `upcast_to_current/1` directly, the correct approach is either: (a) call `Events.timeline_for/3` and filter the result, or (b) expose a filtered variant from Events. Given the CONTEXT.md D-01 says "thin wrapper around `Accrue.Events.timeline_for/3`", the **actual implementation** is:

```elixir
@spec campaign_timeline(String.t(), keyword()) :: [Event.t()]
def campaign_timeline(subscription_id, opts \\ []) when is_binary(subscription_id) and is_list(opts) do
  Accrue.Events.timeline_for("Subscription", subscription_id, opts)
  |> Enum.filter(&String.starts_with?(&1.type, "dunning."))
end
```

This in-memory filter is correct and safe — `timeline_for/3` already handles ordering and `upcast_to_current/1`. The dunning event fraction is small (typically 3–15 events per campaign cycle vs dozens of subscription/invoice events). [ASSUMED: the in-memory approach is the implementation the CONTEXT intends; the "in-Ecto" variant would require access to private `upcast_to_current/1` or refactoring Events — a larger change than this phase warrants]

### Pattern 2: `campaign_timeline_grouped/2` — Pure Enum.chunk_by

**What:** Groups a flat event list by `dunning.campaign_started` boundary events.
**When to use:** Takes output of `campaign_timeline/2`; pure function, no DB.

```elixir
# Source: CONTEXT.md D-05 specification (confirmed approach)
@spec campaign_timeline_grouped(String.t(), keyword()) :: [{String.t() | nil, [Event.t()]}]
def campaign_timeline_grouped(subscription_id, opts \\ []) when is_binary(subscription_id) and is_list(opts) do
  subscription_id
  |> campaign_timeline(opts)
  |> group_into_arcs()
end

defp group_into_arcs([]), do: []

defp group_into_arcs(events) do
  # Chunk by: start a new chunk when event type is dunning.campaign_started
  events
  |> Enum.chunk_by(&(&1.type == "dunning.campaign_started"))
  |> merge_anchor_with_steps()
end

# After chunk_by, we get alternating [campaign_started_chunk, steps_chunk, ...].
# Pairs: {anchor_event, step_events} → one arc.
# Edge: events starting before any campaign_started → {nil, events} prefix bucket.
defp merge_anchor_with_steps(chunks) do
  Enum.reduce(chunks, [], fn chunk, acc ->
    case chunk do
      [%{type: "dunning.campaign_started"} = anchor | _rest] ->
        # This chunk is exactly one campaign_started event
        acc ++ [{anchor.data["campaign_anchor"], [anchor]}]
      other_events ->
        # Append to last arc or create nil-anchor arc
        case List.last(acc) do
          nil -> [{nil, other_events}]
          {anchor, existing} -> List.replace_at(acc, -1, {anchor, existing ++ other_events})
        end
    end
  end)
end
```

**Simpler alternative** (recommended): Since `Enum.chunk_by` produces `[[started], [steps], [started], [steps], ...]` or `[[steps], [started], [steps]]`, a cleaner pattern is:

```elixir
defp group_into_arcs(events) do
  # Partition into groups where each group starts at a campaign_started boundary.
  # Events before the first campaign_started form a {nil, events} prefix.
  Enum.reduce(events, [], fn event, acc ->
    if event.type == "dunning.campaign_started" do
      anchor = event.data["campaign_anchor"]
      acc ++ [{anchor, [event]}]
    else
      case acc do
        [] -> [{nil, [event]}]
        _ ->
          {anchor, arc_events} = List.last(acc)
          List.replace_at(acc, -1, {anchor, arc_events ++ [event]})
      end
    end
  end)
end
```

The planner chooses whichever grouping implementation is simplest and most readable.

### Pattern 3: `invoices_for_campaign/2` — Join chain

**What:** Single Ecto query joining Invoice → Customer → PaymentMethod for a subscription's invoices, keyed by Stripe invoice processor_id.

**Critical finding:** The `invoice_id` stored in `dunning.campaign_started` data is the **Stripe invoice ID** (e.g., `"in_xxxx"`), matching `accrue_invoices.processor_id`. This is confirmed by:
- `default_handler.ex:1263`: `data: %{step_count: step_count, invoice_id: get(canonical, :id)}` where `canonical` is the Stripe invoice object
- `at_risk_subscriptions/1` line 234: `cs.data->>'invoice_id' = i.processor_id`

The CONTEXT.md D-02 says "an Accrue Invoice UUID" — this is a documentation error in the CONTEXT. The join MUST use `i.processor_id`, not `i.id`. [VERIFIED: live codebase — default_handler.ex:1263, dunning.ex:234]

```elixir
# Source: accrue/lib/accrue/billing/invoice.ex (confirmed fields)
# Source: accrue/lib/accrue/billing/customer.ex (confirmed default_payment_method association)
# Source: accrue/lib/accrue/billing/payment_method.ex (confirmed card_brand, card_last4 fields)

alias Accrue.Billing.{Customer, Invoice, PaymentMethod}

@spec invoices_for_campaign(String.t(), keyword()) :: %{String.t() => map()}
def invoices_for_campaign(subscription_id, opts \\ []) when is_binary(subscription_id) and is_list(opts) do
  from(i in Invoice,
    join: c in Customer,
    on: c.id == i.customer_id,
    left_join: pm in PaymentMethod,
    on: pm.id == c.default_payment_method_id,
    where: i.subscription_id == ^Ecto.UUID.cast!(subscription_id),
    where: not is_nil(i.processor_id),
    select: %{
      processor_id: i.processor_id,
      status: i.status,
      amount_due_cents: i.amount_due_minor,
      card_last4: pm.card_last4,
      card_brand: pm.card_brand
    }
  )
  |> Repo.all()
  |> Map.new(fn row -> {row.processor_id, Map.delete(row, :processor_id)} end)
end
```

Note: `subscription_id` parameter is a string UUID. Invoice's `subscription_id` column is `:binary_id`. The `Ecto.UUID.cast!` converts the string to the binary form needed for the join. Alternative: use `fragment("?::uuid", ^subscription_id)`. The planner picks cleanest form.

`amount_due_cents` in the returned map is aliased from `i.amount_due_minor` — the Invoice schema field is `amount_due_minor` but the return map uses `amount_due_cents` to match the CONTEXT spec. [VERIFIED: invoice.ex:76 — `field(:amount_due_minor, :integer)`]

### Pattern 4: CampaignLive mount structure

**What:** Static detail view with mount-only data loading.

```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscription_live.ex (confirmed pattern)
# Source: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex (confirmed assign_shell)

defmodule AccrueAdmin.Live.Analytics.CampaignLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Analytics.Dunning
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, CampaignTimeline}

  @impl true
  def mount(%{"id" => subscription_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    arcs = Dunning.campaign_timeline_grouped(subscription_id)
    invoice_map = Dunning.invoices_for_campaign(subscription_id)

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:subscription_id, subscription_id)
     |> assign(:arcs, arcs)
     |> assign(:invoice_map, invoice_map)}
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Dunning Timeline")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, (admin["mount_path"] || "/billing") <> "/analytics/recovery")
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
```

No `handle_params/3` needed — URL has only `:id`, which is consumed in `mount/3` params. [VERIFIED: SubscriptionLive uses same mount-only pattern]

### Pattern 5: CampaignTimeline component

**What:** Purpose-built Phoenix.Component with three row variants.

```elixir
# Source: accrue_admin/lib/accrue_admin/components/status_badge.ex (confirmed usage)
# Source: accrue/lib/accrue/invoices/render.ex:106 (confirmed format_money/3 signature)
# Source: CONTEXT.md D-09, D-10, D-12

defmodule AccrueAdmin.Components.CampaignTimeline do
  use Phoenix.Component

  alias AccrueAdmin.Components.StatusBadge

  attr(:arcs, :list, required: true)
  attr(:invoice_map, :map, required: true)

  def campaign_timeline(assigns) do
    ~H"""
    <section class="ax-campaign-timeline">
      <div :if={@arcs == []} class="ax-empty-state" data-role="empty-state">
        <p class="ax-heading">No dunning history found</p>
        <p class="ax-body">This subscription has no dunning events.</p>
      </div>
      <div :for={{anchor, events} <- @arcs} class="ax-campaign-arc">
        <.arc_events events={events} invoice_map={@invoice_map} />
      </div>
    </section>
    """
  end

  attr(:events, :list, required: true)
  attr(:invoice_map, :map, required: true)

  defp arc_events(assigns) do
    step_index = 0  # tracked via Enum.with_index in the for comprehension
    ~H"""
    <div :for={{event, idx} <- Enum.with_index(@events)}>
      <.campaign_row event={event} invoice_map={@invoice_map} step_index={idx} />
    </div>
    """
  end

  # Three row variants dispatched by event type
  defp campaign_row(%{event: %{type: "dunning.campaign_started"}} = assigns) do
    # anchor row: date + failure reason from invoice_map
    ~H"""..."""
  end

  defp campaign_row(%{event: %{type: "dunning.step_sent"}} = assigns) do
    # retry row: "Attempt N", invoice amount + status badge
    ~H"""..."""
  end

  defp campaign_row(%{event: %{type: type}} = assigns)
       when type in ["dunning.recovered", "dunning.exhausted"] do
    # terminal row: outcome tone
    ~H"""..."""
  end
end
```

**`format_money/3` call pattern** (confirmed from RecoveryLive):
```elixir
# Source: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:30-31
currency = Accrue.Config.get!(:default_currency)
locale = Accrue.Config.default_locale()
Accrue.Invoices.Render.format_money(amount_cents, currency, locale)
```

In CampaignTimeline, read currency/locale once per component render (not once per row) and thread through as component-level assigns.

**`StatusBadge` call pattern** (confirmed from SubscriptionLive + StatusBadge module):
```elixir
# Source: accrue_admin/lib/accrue_admin/components/status_badge.ex
# Source: accrue_admin/lib/accrue_admin/live/subscription_live.ex:159
<StatusBadge.status_badge status={invoice_status_atom} />
# or with explicit tone override:
<StatusBadge.status_badge status={:recovered} tone="moss" />
```

`status_badge/1` accepts `status` (any) and optional `tone` (string) and `label` (string). For invoice statuses (`:draft`, `:open`, `:paid`, `:void`), the default tone mapping is: `:paid` → "moss", `:draft` → "cobalt", `:open` → "amber", `:void` → "slate". [VERIFIED: status_badge.ex:28-39]

### Pattern 6: Router addition

```elixir
# Source: accrue_admin/lib/accrue_admin/router.ex lines 75-77 (confirmed)
# ADD inside the scope "/analytics" block:

scope "/analytics", AccrueAdmin.Live.Analytics do
  live("/recovery", RecoveryLive, :index)
  live("/recovery/subscriptions/:id", CampaignLive, :show)  # NEW
end
```

This is the only router change. The `live_session :accrue_admin` and `on_mount: [{AccrueAdmin.AuthHook, :ensure_admin}]` are already wrapping this scope — no auth changes needed. [VERIFIED: router.ex:52-77]

### Anti-Patterns to Avoid

- **Ecto.Query in accrue_admin:** Cross-package boundary violation. CampaignLive must never `import Ecto.Query` or call `Accrue.Repo`. All data loading goes through `Accrue.Analytics.Dunning.*`. Enforced by boundary assertion test.
- **Modifying Timeline component:** Do NOT add slot machinery to `AccrueAdmin.Components.Timeline`. It has no `inner_block` slot and CampaignTimeline is a separate purpose-built component. [VERIFIED: timeline.ex]
- **UUID vs Stripe ID for invoice lookup:** Do NOT key `invoices_for_campaign/2` result by `accrue_invoices.id` (UUID). The `invoice_id` in event data is the Stripe processor ID — key by `accrue_invoices.processor_id`.
- **`handle_params/3` for CampaignLive:** Not needed — `:id` is consumed in `mount/3`, no other URL params to parse. Using `handle_params/3` would add unnecessary complexity.
- **`amount_due_cents` vs `amount_due_minor`:** Invoice schema field is `amount_due_minor`. Return it as `amount_due_cents` in the `invoices_for_campaign/2` result map (rename in `select:`).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Money formatting | Custom format/rounding | `Accrue.Invoices.Render.format_money/3` | CLDR-backed, handles JPY zero-decimal, established in Phase 144 |
| Status badge HTML | Custom badge markup | `AccrueAdmin.Components.StatusBadge.status_badge/1` | Consistent tone palette, already used across all detail LiveViews |
| Breadcrumb navigation | Custom back-link | `AccrueAdmin.Components.Breadcrumbs.breadcrumbs/1` | Established pattern across all admin LiveViews |
| Timeline grouping | Custom Enum traversal with complex state | `Enum.chunk_by` + simple reduce | Idiomatic Elixir; pure function, 10-15 LOC |
| Auth for drill-down route | New auth hook or session check | Inherited `live_session :accrue_admin` | Already wraps the `scope "/analytics"` block |

**Key insight:** This phase adds zero new dependencies and zero custom infrastructure. Every building block already exists in the codebase.

---

## Runtime State Inventory

Step 2.5 SKIPPED — This is a greenfield feature addition, not a rename/refactor/migration. No runtime state inventory needed.

---

## Common Pitfalls

### Pitfall 1: Keying `invoices_for_campaign/2` by Accrue UUID instead of Stripe processor_id

**What goes wrong:** `event.data["invoice_id"]` contains the Stripe ID (e.g., `"in_xxxx"`), but if the map is keyed by `accrue_invoices.id` (UUID), every lookup `Map.get(invoice_map, event.data["invoice_id"])` returns `nil` — the invoice context never renders.

**Why it happens:** CONTEXT.md D-02 describes `invoice_id` as "an Accrue Invoice UUID" — this is incorrect. The live code stores `get(canonical, :id)` where `canonical` is the Stripe invoice Stripe ID.

**How to avoid:** Join and key on `i.processor_id`, not `i.id`. Confirm with: `at_risk_subscriptions/1` line 234: `cs.data->>'invoice_id' = i.processor_id`. [VERIFIED: dunning.ex:234]

**Warning signs:** Integration test shows empty invoice context for every row; all `@invoice_map[event.data["invoice_id"]]` lookups return `nil`.

### Pitfall 2: Missing `upcast_to_current/1` when writing `campaign_timeline/2`

**What goes wrong:** If the planner writes a raw Ecto query in `Dunning` module without calling `upcast_to_current/1`, events with old schema versions won't be migrated to current shape.

**Why it happens:** `timeline_for/3` in `Events` module applies `upcast_to_current/1` after the query — but `upcast_to_current/1` is private to `Accrue.Events`.

**How to avoid:** Delegate to `Accrue.Events.timeline_for/3` and filter the result in-memory. Do NOT write a raw Ecto query in `Dunning` that bypasses the upcaster. [VERIFIED: events.ex:267-272 — `|> Enum.map(&upcast_to_current/1)` is inside `timeline_for/3`]

**Warning signs:** Pattern-match on `Event.t()` fields fails for legacy events; tests with manually-inserted low-schema-version events break.

### Pitfall 3: `Enum.chunk_by` behavior — alternating chunks, not boundary groups

**What goes wrong:** `Enum.chunk_by(&(&1.type == "dunning.campaign_started"), events)` produces alternating chunks: `[[campaign_started_event], [step1, step2, terminal], [campaign_started_event], [step1, terminal]]` — NOT `[{anchor, all_events_in_arc}]`. The naïve reading "chunk_by groups events with the same campaign" is wrong.

**Why it happens:** `Enum.chunk_by` groups consecutive elements with the same predicate result. When the predicate flips from `true` to `false`, a new chunk starts.

**How to avoid:** After `chunk_by`, use a reduce or zip to merge each `[started]` chunk with the following `[steps+terminal]` chunk into one arc tuple. Or use a plain `Enum.reduce` directly. See Pattern 2 above.

**Warning signs:** `arcs` list has double the expected number of entries; anchor rows rendered twice.

### Pitfall 4: Step numbering skips campaign_started row

**What goes wrong:** If step number is derived from `Enum.with_index(@events)` over ALL events in an arc (including the `campaign_started` anchor event), the first `step_sent` is "Attempt 2" instead of "Attempt 1".

**Why it happens:** Index 0 = `campaign_started`, index 1 = first `step_sent` → rendered as "Attempt 2" (1-indexed).

**How to avoid:** Number only within `step_sent` events in the arc. Either filter to `step_sent` events first and use `with_index`, or track a separate step counter. CONTEXT specifies "1-indexed position within the campaign arc" for `step_sent` events.

### Pitfall 5: Cross-package boundary violation causing test failure

**What goes wrong:** `CampaignLive` inadvertently aliases `Accrue.Billing.*` or imports `Ecto.Query` — the boundary assertion test fails.

**Why it happens:** Temptation to look up a subscription name or customer label directly rather than through `Dunning.*` functions.

**How to avoid:** `CampaignLive` displays only the subscription ID in the breadcrumb (per CONTEXT specifics), not a customer name. No `Accrue.Billing.*` lookup needed. [VERIFIED: boundary assertion test pattern confirmed in recovery_live_test.exs:243-249]

---

## Code Examples

### `timeline_for/3` exact call signature

```elixir
# Source: accrue/lib/accrue/events.ex:261-273 [VERIFIED]
@spec timeline_for(String.t(), String.t(), keyword()) :: [Event.t()]
def timeline_for(subject_type, subject_id, opts \\ [])
    when is_binary(subject_type) and is_binary(subject_id) and is_list(opts) do
  # Returns events ordered asc: inserted_at, asc: id
  # Applies upcast_to_current/1 to each row
end

# Called as:
Events.timeline_for("Subscription", subscription_id)
# or with limit:
Events.timeline_for("Subscription", subscription_id, limit: 500)
```

### `assign_shell/2` pattern (from RecoveryLive — use this for CampaignLive)

```elixir
# Source: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:116-127 [VERIFIED]
defp assign_shell(socket, admin) do
  socket
  |> assign(:page_title, "Recovery Dashboard")
  |> assign(:brand, admin["brand"] || default_brand())
  |> assign(:theme, admin["theme"] || "system")
  |> assign(:csp_nonce, admin["csp_nonce"])
  |> assign(:brand_css_path, admin["brand_css_path"])
  |> assign(:assets_css_path, admin["assets_css_path"])
  |> assign(:assets_js_path, admin["assets_js_path"])
  |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
  |> assign(:current_path, (admin["mount_path"] || "/billing") <> "/analytics/recovery")
end
```

For `CampaignLive`, `:current_path` should point to the recovery dashboard (back-link target): `(admin["mount_path"] || "/billing") <> "/analytics/recovery"`. The `assign(:page_title, ...)` becomes `"Dunning Timeline"` or similar.

### `format_money/3` call pattern in HEEx component

```elixir
# Source: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:28-31 [VERIFIED]
# Source: accrue/lib/accrue/invoices/render.ex:106-132 [VERIFIED]

# In CampaignTimeline component — compute once per render, not per row:
currency = Accrue.Config.get!(:default_currency)
locale = Accrue.Config.default_locale()
# Then per row:
Accrue.Invoices.Render.format_money(amount_due_cents, currency, locale)
```

`format_money/3` signature: `(amount_minor :: integer(), currency :: atom(), locale :: String.t()) :: String.t()`. Returns gracefully formatted string with CLDR locale fallback to "en" then raw string on double failure.

### AtRiskTable row-click link (already ships in Phase 146)

```elixir
# Source: accrue_admin/lib/accrue_admin/components/at_risk_table.ex:55-58 [VERIFIED]
<a
  href={@base_path <> "/analytics/recovery/subscriptions/" <> row.subscription_id}
  class="ax-link"
>
  {row.customer_label || "—"}
</a>
```

Phase 147 makes this URL resolve by adding the route and `CampaignLive`.

### Boundary assertion test pattern

```elixir
# Source: accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:243-249 [VERIFIED]
test "cross-package boundary: CampaignLive does not import Ecto.Query, Accrue.Repo, or Accrue.Billing.*" do
  source = File.read!("lib/accrue_admin/live/analytics/campaign_live.ex")

  refute source =~ "import Ecto.Query"
  refute source =~ "Accrue.Repo"
  refute source =~ "Accrue.Billing."
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single flat event list for timeline display | Grouped arc list via `campaign_timeline_grouped/2` | Phase 147 (new) | Multi-campaign subscriptions render as distinct campaign arcs, not one flat list |
| USD-only money formatting | CLDR-backed `format_money/3` | Phase 144 | CampaignTimeline inherits correct multi-currency rendering from day one |
| Generic Timeline component | Purpose-built CampaignTimeline | Phase 147 (new) | Dunning-specific 3-variant rows; generic Timeline has no slot machinery |

**Deprecated/outdated:**
- CONTEXT.md D-02 description of `invoice_id` as "Accrue Invoice UUID": incorrect per live code. Use `processor_id` for join.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `campaign_timeline/2` delegates to `Events.timeline_for/3` and filters in-memory (not raw Ecto in Dunning module) to avoid private `upcast_to_current/1` | Code Examples, Pattern 1 | If the planner writes a raw Ecto query in Dunning, legacy events won't be upcasted → silent data shape drift |
| A2 | `invoices_for_campaign/2` join path is Invoice → Customer → PaymentMethod (not Invoice → Subscription → Customer → PaymentMethod) since Invoice has direct `customer_id` FK | Architecture Patterns, Pattern 3 | If Invoice's `customer_id` is ever nil (orphaned invoice), the join returns no payment method row — handled by `left_join` |
| A3 | `Ecto.UUID.cast!/1` or `fragment("?::uuid", ...)` is needed to compare string `subscription_id` to binary_id `i.subscription_id` | Pattern 3 | If Ecto handles string↔binary_id coercion automatically (it may, for `==` with binary_id type), the cast is unnecessary but harmless |

**CRITICAL DISCREPANCY (not tagged ASSUMED — verified by code):** CONTEXT.md D-02 states `invoice_id` is "an Accrue Invoice UUID". Live code proves it is the Stripe invoice ID (`get(canonical, :id)` = Stripe processor_id). This is a documentation error in CONTEXT.md that the planner MUST resolve by joining on `processor_id`. [VERIFIED: default_handler.ex:1263, dunning.ex:234]

---

## Open Questions

1. **`Enum.chunk_by` grouping implementation choice**
   - What we know: `Enum.chunk_by` produces alternating chunks; needs post-processing to merge `[started]` + `[steps+terminal]` into one arc tuple.
   - What's unclear: Whether to use a `chunk_by` + zip, or a plain `Enum.reduce`. Both work.
   - Recommendation: Plain `Enum.reduce` with pattern match on `event.type == "dunning.campaign_started"` — clearest intent, ~10 LOC.

2. **`subscription_id` UUID string → binary_id coercion in Ecto query**
   - What we know: `invoices_for_campaign/2` receives `subscription_id` as a string. `accrue_invoices.subscription_id` is `:binary_id`.
   - What's unclear: Whether Ecto automatically casts string → binary_id for equality comparison.
   - Recommendation: Test with a real UUID string in integration test. If Ecto raises a cast error, add `Ecto.UUID.cast!(subscription_id)` or use `type(^subscription_id, :binary_id)` in the fragment.

3. **CampaignTimeline `format_money/3` with nil `amount_due_cents`**
   - What we know: `i.amount_due_minor` can be `nil` for invoices that haven't been finalized.
   - What's unclear: CONTEXT.md does not specify nil-amount handling.
   - Recommendation: Guard with `if invoice_ctx && invoice_ctx.amount_due_cents, do: format_money(...), else: "—"`. Pattern consistent with existing "—" nil defaults throughout the admin UI.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 147 is purely code changes in existing Elixir/Phoenix files. No new external tools, runtimes, databases, or CLI utilities required. All existing deps (`ecto`, `postgrex`, `phoenix_live_view`) are already confirmed operational in the test environment.

---

## Validation Architecture

nyquist_validation is `true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs` |
| Quick run command | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` |
| Full suite command | `cd accrue && mix test && cd ../accrue_admin && mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DAN-05 | `campaign_timeline/2` returns only `dunning.*` events, chronological | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ (add cases) |
| DAN-05 | `campaign_timeline_grouped/2` groups by arc correctly (2 campaigns: 1 recovered, 1 active) | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ (add cases) |
| DAN-05 | `campaign_timeline_grouped/2` returns `[]` for empty input | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ (add cases) |
| DAN-12 | `invoices_for_campaign/2` returns map keyed by Stripe processor_id | integration | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ (add cases) |
| DAN-12 | `invoices_for_campaign/2` gracefully handles nil invoice_id (no key in map) | integration | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ (add cases) |
| DAN-12 | `CampaignLive` mounts and renders timeline for subscription with 2 arcs | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs` | ❌ Wave 0 |
| DAN-12 | `CampaignLive` renders empty state for unknown subscription_id | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs` | ❌ Wave 0 |
| DAN-12 | Cross-package boundary: CampaignLive has no Ecto.Query/Repo/Billing.* | static grep | `cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs` | ❌ Wave 0 |
| DAN-12 | RecoveryLive at-risk table row links to Phase 147 route | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ✅ (add assertion) |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/analytics/dunning_test.exs`
- **Per wave merge:** `cd accrue && mix test && cd ../accrue_admin && mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` — new test file covering DAN-12 LiveView cases + boundary assertion
- [ ] Add `describe "campaign_timeline/2"`, `describe "campaign_timeline_grouped/2"`, `describe "invoices_for_campaign/2"` blocks to `accrue/test/accrue/analytics/dunning_test.exs`
- [ ] Add at-risk table row-link assertion to `recovery_live_test.exs` (DAN-12 row-click affordance verification)

*(No new test framework install needed — ExUnit + Phoenix.LiveViewTest already in place)*

---

## Security Domain

`security_enforcement` not explicitly set to false in config.json — section required.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (inherited) | `live_session :accrue_admin` with `{AccrueAdmin.AuthHook, :ensure_admin}` on_mount hook — no changes, already enforced |
| V3 Session Management | yes (inherited) | Session keys threaded via `AccrueAdmin.Router.__session__/3` — no changes |
| V4 Access Control | yes (inherited) | Admin-only route; no new permission surfaces |
| V5 Input Validation | yes — `:id` URL param | `subscription_id` is received as a binary string in `mount/3`. Used in `campaign_timeline_grouped/2` and `invoices_for_campaign/2`. Ecto parameterized queries prevent injection. Malformed UUID → empty result, not crash. |
| V6 Cryptography | no | No new crypto in this phase |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized drill-down access | Elevation of Privilege | `live_session :accrue_admin` blocks non-admin access at mount; no new bypass surface |
| IDOR via subscription_id | Information Disclosure | `invoices_for_campaign/2` returns data for any subscription_id; admin-only route means only authorized operators can query. No owner-scoping needed (admin = full access). |
| SQL injection via subscription_id | Tampering | Ecto parameterized queries prevent injection; `^subscription_id` is bound safely |
| PII in event data logged | Information Disclosure | `dunning.*` event data contains `invoice_id` (Stripe ID) and `campaign_anchor` (ISO timestamp) — no PII per existing data model. CLAUDE.md: "Sensitive Stripe fields never logged." |

---

## Sources

### Primary (HIGH confidence)
- `accrue/lib/accrue/events.ex` lines 261-273 — `timeline_for/3` signature verified
- `accrue/lib/accrue/analytics/dunning.ex` — full module read; `@dunning_lifecycle_types`, `apply_window/2`, `at_risk_subscriptions/1` join pattern verified
- `accrue/lib/accrue/webhook/default_handler.ex` lines 1256-1264 — `emit_campaign_started/2` stores `invoice_id: get(canonical, :id)` (Stripe ID)
- `accrue/lib/accrue/analytics/dunning.ex` line 234 — `cs.data->>'invoice_id' = i.processor_id` join confirmed
- `accrue/lib/accrue/billing/invoice.ex` — schema fields: `amount_due_minor`, `processor_id`, `status`, `subscription_id`, `customer_id`
- `accrue/lib/accrue/billing/payment_method.ex` — `card_brand`, `card_last4` fields confirmed
- `accrue/lib/accrue/billing/customer.ex` — `belongs_to(:default_payment_method, Accrue.Billing.PaymentMethod, type: :binary_id)` confirmed
- `accrue_admin/lib/accrue_admin/router.ex` lines 75-77 — `scope "/analytics"` block structure confirmed
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — `assign_shell/2` pattern, `format_money/3` call pattern, `handle_params/3` vs `mount/3` contrast
- `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` line 55 — row-click href confirmed
- `accrue_admin/lib/accrue_admin/components/timeline.ex` — no slot machinery confirmed; DO NOT modify
- `accrue_admin/lib/accrue_admin/components/status_badge.ex` — `status_badge/1` attrs and tone mapping confirmed
- `accrue/lib/accrue/invoices/render.ex` lines 106-132 — `format_money/3` signature and fallback behavior
- `accrue_admin/test/support/live_case.ex` — `AccrueAdmin.LiveCase` test setup confirmed
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — boundary assertion test pattern confirmed
- `.planning/config.json` — `nyquist_validation: true` confirmed

### Secondary (MEDIUM confidence)
- CONTEXT.md canonical refs section — phased code locations cited; all verified against live code
- `accrue/lib/accrue/billing/subscription.ex` — Subscription has `belongs_to(:customer)` only; no direct PaymentMethod link; confirmed Invoice joins through Customer

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all building blocks verified in live codebase
- Architecture: HIGH — all patterns verified from existing parallel implementations
- Pitfalls: HIGH — Pitfall 1 (UUID vs Stripe ID) verified by cross-checking two independent code locations

**Research date:** 2026-05-27
**Valid until:** 2026-06-27 (stable internal codebase — no external registry dependencies)
