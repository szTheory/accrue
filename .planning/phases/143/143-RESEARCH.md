# Phase 143: Recovered-Revenue Analytics Dashboard - Research

**Researched:** 2026-05-27
**Domain:** Analytics & Dunning Event Ledger
**Confidence:** HIGH

## Summary

This phase implements a new "Money Saved" analytics dashboard in `accrue_admin` to visualize the success of the Dunning Engine. It introduces MRR snapshotting into the existing event ledger (`accrue_events`), enabling Ecto-driven aggregations without adding new database tables. 

**Primary recommendation:** Snapshot MRR during `dunning.recovered` and `dunning.exhausted` emissions in `Accrue.Webhook.DefaultHandler`, and query it via Ecto JSONB fragments in a new `Accrue.Analytics.Dunning` context. Use a dedicated `/analytics/recovery` LiveView route for isolation.

<user_constraints>
## User Constraints (from 143-DISCUSS.md & v1.44-NEXT-STEP-ASSESSMENT.md)

### Locked Decisions
- **Metric Type:** Update the Event Payload (Snapshotting MRR) at emission time to avoid temporal data leakage.
- **Querying:** Use Ecto fragments to sum directly from the JSONB payload: `sum(fragment("(?->>'mrr_value_cents')::integer", e.data))`.
- **UI Location:** Standalone Route (`/analytics/recovery`) in `accrue_admin` to avoid bloat in `DashboardLive`.
- **Data Access:** Create a public API in `accrue` (`Accrue.Analytics.Dunning`) encapsulating the `group_by` aggregations.
- **No New Tables:** Must rely only on the existing event ledger (no new analytical tables or dependencies) to maintain Accrue's lightweight footprint.

### the agent's Discretion
- Backfill script (optional) to seed historical events with current MRR.

### Deferred Ideas (OUT OF SCOPE)
- Multi-channel Dunning (In-App, SMS, Push)
- Rich Metered/Tiered Entitlement Math
- General BI tool scope creep (FIN-03 finance exports, MoR processors, generic MRR/ARR analytics product)
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Event Emission (MRR Snapshotting) | API / Backend | Database | `Accrue.Webhook.DefaultHandler` intercepts webhook events and calculates MRR before committing it atomically with the event record. |
| Analytics Aggregation | API / Backend | Database | `Accrue.Analytics.Dunning` handles the `group_by` and Ecto JSONB fragment querying against Postgres. |
| Dashboard UI | Frontend Server (SSR) | Browser | `AccrueAdmin.Live.Analytics.RecoveryLive` renders the metrics server-side, adhering to Phoenix LiveView idioms. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | (Existing) | UI framework | Standard for `accrue_admin`. |
| Ecto | (Existing) | DB abstractions | Fragment usage for Postgres JSONB aggregations (`?->>'mrr_value_cents'`). |

## Architecture Patterns

### System Architecture Diagram
```
Stripe Webhook -> Accrue.Webhook.DefaultHandler
                     |
                     v
             Calculate MRR Cents
                     |
                     v
          Events.record (dunning.recovered / exhausted)
                     |
                     v
             Postgres (accrue_events) JSONB data
                     |
                     v
          Accrue.Analytics.Dunning (Ecto sum group_by)
                     |
                     v
    AccrueAdmin.Live.Analytics.RecoveryLive (LiveView)
                     |
                     v
              Operator Dashboard
```

### Pattern 1: Ecto JSONB Aggregations
**What:** Leveraging Postgres JSONB functions directly in Ecto.
**When to use:** When calculating aggregate metrics like MRR from schemaless event data.
**Example:**
```elixir
# Source: Accrue.Analytics.Dunning
query =
  from e in Event,
    where: e.type in [@recovered_type, @exhausted_type],
    group_by: e.type,
    select: {e.type, sum(fragment("(?->>'mrr_value_cents')::integer", e.data))}
```

### Anti-Patterns to Avoid
- **Temporal Data Leakage:** Joining `accrue_subscriptions` at query time to fetch MRR. If a user's subscription changes *after* recovery, the historical analytics dashboard would warp. We must snapshot at emission time.
- **God Module `DashboardLive`:** Putting these heavy aggregations in the main dashboard's `mount/3`. Keep bounded contexts in their own LiveViews.

## Common Pitfalls

### Pitfall 1: Assuming `Accrue.Jobs.DunningSweeper` Emits Exhaustion
**What goes wrong:** Attempting to add MRR calculation to `DunningSweeper` for terminal events.
**Why it happens:** The discuss thread mentioned checking the sweeper. However, the sweeper only emits `dunning.terminal_action_requested`. The *actual* `dunning.exhausted` record is only ever emitted by `Accrue.Webhook.DefaultHandler` once the subscription state actually updates.
**How to avoid:** Only augment the event payloads within `Accrue.Webhook.DefaultHandler` where `dunning.recovered` and `dunning.exhausted` are definitively emitted.

## Code Examples

### Calculating MRR from `data` payload
```elixir
# Source: Accrue.Webhook.DefaultHandler
defp calculate_mrr_cents(%Subscription{data: data}) do
  items = Map.get(data, "items", %{}) |> Map.get("data", [])
  
  Enum.reduce(items, 0, fn item, acc ->
    quantity = Map.get(item, "quantity", 1)
    plan = Map.get(item, "plan", %{}) || %{}
    price = Map.get(item, "price", %{}) || %{}
    
    amount = Map.get(plan, "amount") || Map.get(price, "unit_amount") || 0
    interval = Map.get(plan, "interval") || get_in(price, ["recurring", "interval"]) || "month"
    interval_count = Map.get(plan, "interval_count") || get_in(price, ["recurring", "interval_count"]) || 1
    
    mrr_cents = 
      case interval do
        "month" -> div(amount * quantity, interval_count)
        "year" -> div(amount * quantity, interval_count * 12)
        "week" -> div(amount * quantity * 52, interval_count * 12)
        "day" -> div(amount * quantity * 365, interval_count * 12)
        _ -> 0
      end
      
    acc + mrr_cents
  end)
end
```

### Snapshotting in DefaultHandler
```elixir
# In maybe_emit_dunning_exhaustion/2:
mrr_value_cents = calculate_mrr_cents(updated)
currency = updated.data["currency"] || "usd"

Events.record(%{
  type: "dunning.exhausted",
  subject_type: "Subscription",
  subject_id: updated.id,
  data: %{
    to_status: to_status, 
    source: source,
    mrr_value_cents: mrr_value_cents,
    currency: currency
  }
})
```

### Target Files in `accrue_admin`
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`
- `accrue_admin/lib/accrue_admin/router.ex` (Under a new `scope "/analytics"`)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | MRR is calculated by iterating over `data["items"]["data"]` | Code Examples | [ASSUMED] The MRR calculation might omit discount/coupon math or custom tier logic. If wrong, the MRR saved number will be an upper-bound estimate rather than strictly exact. |

## Open Questions (RESOLVED)

1. **Historic Backfill**
   - What we know: The discussion thread notes an optional backfill script.
   - What's unclear: Should the backfill script be written as a Mix task, or just a documentation guide?
   - Resolution: Operator documentation will suffice. We want to avoid adding maintenance surface area with a Mix task. We will provide an example Ecto query in the documentation for backfilling if requested by the user, but we will not build a dedicated task in this phase.

## Sources

### Primary (HIGH confidence)
- `.planning/threads/143-DISCUSS.md` - Direct architecture instructions.
- `accrue/lib/accrue/webhook/default_handler.ex` - Verified event emission locations.
- `accrue/lib/accrue/billing/subscription_projection.ex` - Verified that Stripe's `data` payload persists to the DB.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Ecto JSONB querying is fully supported.
- Architecture: HIGH - Strictly follows `143-PATTERNS.md` components.
- Pitfalls: HIGH - Audited `DunningSweeper` code and proved it doesn't emit the final events.

**Research date:** 2026-05-27
**Valid until:** Indefinitely (Core ledger architecture)
