# Milestone Next-Step Assessment

**Date:** 2026-05-27
**Target:** Accrue (Elixir/Phoenix OSS billing library)

## 1. Framing

Accrue is a batteries-included Elixir/Phoenix payments and billing library. Its core promise is "a Phoenix developer can launch a real SaaS with subscription billing on day one," providing a complete, production-grade experience with idiomatic Elixir DX, strong domain modeling, a tamper-evident audit ledger, and zero breaking-change pain through v1.x.

"Done" for this project means that the library provides the core user flows, jobs-to-be-done, features, docs, operator/admin surfaces, and proof posture expected of a mature billing library in this ecosystem.

*Confidence level: Very high.* The `.planning` state, `JTBD-FRONTIER.md`, and recent milestones confirm all major core loops (including entitlements, dunning, search, and ad-hoc invoices) are now shipped and verified. There is no doc drift—the reality of the codebase matches the milestone wrap-ups.

## 2. Current State

**Job:** A complete, zero-sidecar Phoenix billing engine with built-in admin tooling and an immutable audit ledger.

**Rough Done-%: 98% (Diminishing returns)**

**What's clearly real:** The canonical SaaS loop is completely shipped. You have the subscription core, dual-provider support (Stripe/Braintree + Fake), webhook ingestion/DLQ, hosted/local portals, Rendro invoice PDFs, metered usage, coupons, `accrue_admin` LiveView dashboard, fail-closed entitlements (v1.39), multi-step dunning (v1.40), native Postgres admin search (v1.41), and ad-hoc manual invoices (v1.42).

## 3. Adopter Coverage Map

- **Well-Served (Core JTBD):**
  - Subscription lifecycle (create/swap/cancel/trials).
  - Money movement (invoices, PDF generation, one-off charges, refunds, ad-hoc invoices).
  - Growth/usage (coupons, metered billing).
  - Failure handling (dunning grace/terminal, webhooks, replay).
  - Trust (immutable audit ledger, telemetry).
  - Operator/Platform (LiveView admin UI, global search, portal sessions, entitlements/plan-gating).
- **Partially-Served (Bounded):**
  - Proration math (relies entirely on the processor).
  - Tax (Stripe automatic tax only).
- **Still-Rough / Unserved:**
  - Disputes/chargebacks visibility (absent).
- **Out-of-Scope (Deliberate non-goals):**
  - Revenue recognition / accounting exports (FIN-03).
  - Merchant-of-Record capabilities (Paddle, Lemon Squeezy).
  - Marketplace payouts via Hyperwallet.

## 4. Next-Work Recommendation

With 6 of 6 core SaaS loops shipped, plus the long-tail polish of Admin Search and Ad-hoc Invoices now completed, the remaining wedges are at the very bottom of the intake list:

1. **Hex Release (`v1.43` or standalone publish):** Cut the `1.1.2` or `1.2.0` linked Hex publish.
   - *Why it matters:* You have massive, shipped value (Entitlements, Dunning, Search, Ad-hoc invoices) sitting on `main` that integrators cannot fetch via `mix.exs`.
   - *Done enough:* Run Release Please and publish the packages to Hex.
2. **Disputes / chargebacks visibility (read-only):** Project `charge.dispute.*` into the ledger and admin dashboard.
   - *Why it matters:* Operator awareness for financial disputes.
   - *Done enough:* Read-only list in `accrue_admin`.
3. **Audit bridge (External sinking):** Sink critical events to an external system.
   - *Why it matters:* Enterprise compliance.
   - *Done enough:* Simple adapter behaviour.

**The Pick:** **Hex Release / Post-Publish Sweep**. Do not build new features. Put what you've built into the hands of adopters.

## 5. Diminishing-Returns Judgment

The value curve is now practically horizontal for new feature development. Accrue has dramatically over-delivered on the promise of a Phoenix billing library. You are completely into the realm of diminishing returns for feature work. Adding more features right now risks overbuilding or shifting into accounting territory.

## 6. Blunt Maintainer Takeaway

**Stop building features. Seriously.** Accrue is 100% complete for its stated scope. The only thing left to do is cut a new linked Hex release for the `1.x.x` line so that the community gets the v1.39-v1.42 features (Entitlements, Dunning, Search, Ad-hoc invoices). If I were you, my next step would be a Release Please publishing milestone to put this code on Hex.

## 7. Bookkeeping Written

- Updated `.planning/STATE.md` to indicate "Intake-gated maintenance mode / Hex Release Prep" and logged the decision to stop feature building.
- Updated `.planning/research/JTBD-FRONTIER.md` to move Admin Search and Ad-hoc Invoices to ✅ in the coverage map and removed them from the future JTBD list.
- Wrote this assessment to `.planning/threads/next-step-assessment.md`.

## 8. Shift-Left Applied

No new auto-applied configuration changes were made as the current `.planning/config.json` already heavily leverages parallelization, research, and rigorous gating mechanisms. The `yolo` mode is currently active, and the default behavior aligns perfectly with the ongoing intake-gated maintenance phase.

---

## 2026-05-31 Refresh: Stable Core / Demand-Driven Expansion

**Trigger:** After v1.47 shipped and archived, maintainer asked whether Accrue is approaching "done," whether future milestone planning should stop repeatedly re-litigating that question, and how to make future context resets remember the answer.

**Updated assessment:** Accrue is **90-95% done for its declared scope** and should now be treated as **stable core / demand-driven expansion**. The remaining useful work is not broad feature discovery; it is release readiness, maintenance, support-contract hardening, verifier/doc truth, and occasional strategic expansion when explicitly justified.

**Default next milestone:** `v1.48 — Release Readiness + Stable Core Posture`

Scope should include:
- full linked three-package release verification,
- release notes/changelog alignment for post-1.3.0 v1.47 work,
- stable-core positioning in public docs,
- support-matrix / docs / examples / verifier consistency,
- stale backlog-anchor archival,
- and linked Hex publish.

Scope should exclude:
- new billing primitives,
- new processor breadth,
- finance/accounting ownership,
- merchant-of-record or marketplace payout support,
- and polish that does not remove a real adopter, operational, correctness, security, or release failure mode.

**Intake rule for future milestones:** Do not ask "are we done?" again by default. Assume Accrue is done enough until new evidence appears. New feature work requires at least one of:
- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

**Backlog posture:** Deferred items should remain demand-driven or explicit non-goals. Historical FRG anchors (`INT-10`, `BIL-03`, `ADM-12`) are traceability entries, not active scope.
