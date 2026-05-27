# Milestone Next-Step Assessment

**Date:** 2026-05-25
**Target:** Accrue (Elixir/Phoenix OSS billing library)

## 1. Framing

Accrue is a batteries-included Elixir/Phoenix payments and billing library. Its core promise is "a Phoenix developer can launch a real SaaS with subscription billing on day one," providing a complete, production-grade experience with idiomatic Elixir DX, strong domain modeling, a tamper-evident audit ledger, and zero breaking-change pain through v1.x.

"Done" for this project means that the library provides the core user flows, jobs-to-be-done, features, docs, operator/admin surfaces, and proof posture expected of a mature billing library in this ecosystem.

*Confidence level: Very high.* The `.planning` state, particularly `JTBD-FRONTIER.md` (which called out Entitlements as the final gap before it shipped in v1.39) and `STATE.md` (confirming Dunning shipped in v1.40), confirms that the core features are not aspirational—they are shipped and verified.

## 2. Current State

**Job:** A batteries-included, zero-sidecar (where possible) Phoenix billing and subscription management library with built-in admin tooling and immutable audit logging.

**Rough Done-%: 95% (Near-done / Diminishing returns)**

**What's clearly real:** The canonical SaaS loop is completely shipped. This includes the subscription core, dual-provider support (Stripe/Braintree + Fake), webhook processing, local and hosted portal sessions, native invoicing with pure-Elixir PDFs (Rendro), metered usage, coupons, complete operator dashboard (`accrue_admin`), local plan-gating/entitlements (v1.39), and multi-step dunning notification journeys (v1.40).

## 3. Adopter Coverage Map

- **Well-Served (Core JTBD):**
  - Subscription lifecycle (create/swap/cancel/trials).
  - Money movement (invoices, PDF generation, one-off charges, refunds).
  - Growth/usage (coupons, metered billing).
  - Failure handling (dunning grace/terminal, webhooks, replay).
  - Trust (immutable audit ledger, telemetry).
  - Operator/Platform (LiveView admin UI, portal sessions, entitlements/plan-gating).
- **Partially-Served (Bounded):**
  - Proration math (relies entirely on the processor).
  - Tax (Stripe automatic tax only).
- **Out-of-Scope (Deliberate non-goals):**
  - Revenue recognition / accounting exports (FIN-03).
  - Merchant-of-Record capabilities (Paddle, Lemon Squeezy).
  - Marketplace payouts via Hyperwallet.

## 4. Next-Work Recommendation

With 6 of 6 core SaaS loops shipped, we researched the remaining high-value wedges from the intake/seeds frontier:

1. **Admin search across billing records (Scrypath vs Native Postgres)**
   - *Why it matters:* Ecto-native global search for Customers/Invoices/Subscriptions in the admin UI is a massive quality-of-life win for operators (approaching the Stripe Dashboard UX).
   - *Done enough:* Implementing Postgres native search (`pg_trgm`) for the core tables, rather than adopting Scrypath+Meilisearch, to avoid forcing a sidecar infrastructure dependency on host apps.
2. **Ad-hoc / manual invoice line items**
   - *Why it matters:* Fills a real B2B edge case for manual adjustments.
   - *Done enough:* Enabling local-first draft invoices where admins can review, add items, and render PDFs before committing them to the gateway.
3. **Disputes / chargebacks visibility**
   - *Why it matters:* Operator awareness of financial disputes.
   - *Done enough:* A dedicated read-only `Dispute` schema projecting Stripe events into the local DB and surfacing them in the admin UI.

**The Pick:** **Admin search (Native Postgres)**. If a new milestone must be opened, providing a CMD+K global search experience in `accrue_admin` via native Postgres extensions provides the highest leverage operator win without compromising the project's zero-sidecar philosophy.

*Suggested Ordering:* Admin search -> Ad-hoc invoice items -> Disputes visibility.

## 5. Diminishing-Returns Judgment

The value curve has flattened. Accrue is now feature-complete for its core promise. Further work on major features pushes into diminishing returns, or worse, risks overbuilding into different product domains (like an accounting system or analytics suite). We have officially crossed from "finishing the last important wedges" to **mostly stop / intake-gated maintenance mode**.

## 6. Blunt Maintainer Takeaway

**The autopilot did, in fact, build a feature-complete billing library.** You are 6 of 6 on the canonical SaaS loop. Entitlements (v1.39) and Dunning depth (v1.40) were the last two places where "basically done" was doing real work, and they are now closed.

If I were you, I would **build nothing major next.** The library is basically done for its scope. Switch entirely to intake-driven polish, bug fixes, and documentation improvements.

## 7. Bookkeeping Written

- Updated `.planning/STATE.md` to change "Current focus: Next milestone planning" to "Current focus: Intake-gated maintenance mode / Polish (6 of 6 core SaaS loop JTBDs complete)."
- Appended decision to `.planning/STATE.md`: "2026-05-25: Milestone Next-Step Assessment complete. Accrue is 6 of 6 on the canonical SaaS loop (feature-complete core). Shifted to intake-gated maintenance mode. Highest-value intake candidate is Admin Search (Postgres native), but no major milestones are strictly necessary."
- Saved this assessment as `.planning/threads/next-step-assessment.md`.

## 8. Shift-Left Applied

No new auto-applied configuration changes were made as the current `.planning/config.json` already heavily leverages parallelization, research, and rigorous gating mechanisms. The `yolo` mode is currently active, and the default behavior aligns well with the ongoing intake-gated maintenance phase.