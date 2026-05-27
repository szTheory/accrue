# Phase 143 Discuss: Recovered-Revenue Analytics Dashboard

**Date:** 2026-05-27
**Status:** Completed

This document captures the architectural and UX decisions for Phase 143 (Recovered-Revenue Analytics Dashboard) following deep subagent research.

## 1. Metric Type: How do we track MRR?

**The Problem:** The current `dunning.recovered` and `dunning.exhausted` events in the `accrue_events` ledger do not store monetary values (MRR). We need to decide how to derive "Revenue Recovered".

**Options Evaluated:**
1. **Update Event Payload:** Snapshot `mrr_value_cents` at emission time.
2. **Join Subscriptions:** Join `accrue_subscriptions` at query time.
3. **Show Counts Only:** Avoid money entirely.

**Decision: Update the Event Payload (Snapshotting MRR).**
*   **Why:** Relying on current subscription state (Option 2) causes "Temporal Data Leakage"—if a user upgrades/downgrades months after recovery, the historical dashboard would retroactively change, destroying financial reporting accuracy.
*   **Action:** Modify the event emitters for `dunning.recovered` and `dunning.exhausted` (e.g., in `Accrue.Webhook.DefaultHandler` and `Accrue.Jobs.DunningSweeper`) to calculate and embed `mrr_value_cents` and `currency` in the `data` JSONB payload.
*   **Querying:** The new analytics query will use Ecto fragments to sum directly from the JSONB payload: `sum(fragment("(?->>'mrr_value_cents')::integer", e.data))`.
*   *(Optional)*: A backfill script can be provided to seed historical events with current MRR so the dashboard isn't completely empty on day one.

## 2. UI Location: Where does the dashboard live?

**The Problem:** `accrue_admin` needs a home for this new visualization.

**Options Evaluated:**
1. **Standalone Route:** A dedicated `/analytics/recovery` route and new sidebar item.
2. **Dashboard Tab:** A toggle inside the existing `DashboardLive` operator home page.

**Decision: Standalone Route (`/analytics/recovery`).**
*   **Why:** The main `DashboardLive` currently performs numerous synchronous aggregate queries in `mount/3` (for KPIs like active subscriptions, webhook backlog, etc.). Adding heavy analytical aggregations there creates a "god module" and risks blocking the operational dashboard. A standalone route isolates the concern, providing a pristine sandbox for charts and aligning with LiveView idioms ("one LiveView per bounded concern").
*   **Action:** 
    *   Create a new item in `AccrueAdmin.Nav` under a new "Analytics" eyebrow.
    *   Create `AccrueAdmin.Live.Analytics.RecoveryLive`.
    *   Map it in `accrue_admin/router.ex` within the existing `:accrue_admin` `live_session`.

## 3. Data Access & UI Components

*   **Query Module:** Create a public API in `accrue`, e.g., `Accrue.Analytics.Dunning`, which encapsulates the complex `group_by` and JSONB parsing logic. This allows developers to build custom internal dashboards without relying on `accrue_admin`.
*   **Visuals:** 
    *   Hero Metric: "MRR Recovered (Last 30 Days)".
    *   Funnel Chart: Visual drop-off from "Entered Dunning" to "Recovered" or "Exhausted/Canceled".
    *   "At Risk" Table: Subscriptions with an active campaign (`dunning_campaign_started_at != nil`).

## Next Steps
The discuss phase is complete. We have absolute clarity on the event ledger changes and the LiveView routing architecture. We are ready to transition to `/gsd-plan-phase 143`.