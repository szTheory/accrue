# Phase 163 Context: Realistic Domain & Rich Seeds

**Domain:**
Realistic Demo App & Adoption Evidence — Defining a concrete cohort persona/JTBD and populating the demo app with realistic fixtures (users, plans, subscriptions).

**Canonical refs:**
- .planning/ROADMAP.md
- .planning/REQUIREMENTS.md

## Decisions

### 1. Domain & Persona
**Decision:** B2B SaaS (e.g., "PingPal" Uptime Monitoring or similar Developer Tool).
**Rationale:** A B2B DevTool naturally features tiered subscriptions (Hobby, Pro, Enterprise), seat-based/metered usage (monitors, SMS alerts), and demonstrates the full suite of Accrue features (Admin UI, Dunning, Invoicing) seamlessly. It aligns perfectly with typical Phoenix live dashboard use cases.

### 2. Seed Scale & Variety
**Decision:** Hybrid approach: 5-10 curated "Hero" accounts + ~100 random background accounts.
**Rationale:** Hero accounts (e.g., `past-due@example.com`, `enterprise@example.com`) provide predictable, stable fixtures for Playwright E2E tests and manual QA without flakiness. Background accounts (generated) populate the analytics charts, pagination, and MRR funnels so the app doesn't look like a toy. This avoids the footgun of massive seed times while still providing a rich "click-around" experience.

### 3. Generation Strategy
**Decision:** Hardcode Hero accounts; use `faker` (via standard Ecto patterns) for background accounts.
**Rationale:** Hardcoding Hero accounts ensures Playwright E2E tests have deterministic, rock-solid data. `faker` provides variety for the background accounts without bloating `seeds.exs`. We will use `Repo.insert_all` for the bulk background data to keep `mix ecto.reset` fast and idiomatic.

### 4. Historical Depth
**Decision:** Seed time-series events (invoices, subscriptions, dunning events) spanning the last 90 days.
**Rationale:** Accrue's analytics windows (7d, 30d, 90d) need historical data to show meaningful trend lines. A flat "today" spike looks broken. We will expand the existing `record_at` backdating technique (bypassing Ecto's `inserted_at` defaults via `Repo.insert_all`) to ensure the dashboard feels "alive" on first boot.

## Code Context
- `examples/accrue_host/priv/repo/seeds.exs`: Currently contains basic dunning banner demo accounts and `record_at` utility for backdating events. We will expand this significantly.
