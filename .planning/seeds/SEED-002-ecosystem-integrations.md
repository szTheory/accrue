---
id: SEED-002
status: backlogged
planted: 2026-05-31
planted_during: v1.47 closeout
trigger_when: when a milestone considers ecosystem / interoperability integrations with sibling sztheory libraries (Threadline audit bridge, Chimeway/Mailglass notifications, Rendro PDF, Scrypath search, Sigra/Lockspire identity), or when a concrete adopter needs one of these integrations
scope: Large
---

# Ecosystem Integrations (High-Value Wins)

**Domain:** Interoperability with sztheory ecosystem libraries
**Status:** Backlogged / Future Roadmap

This is a strategic future-roadmap seed, not an unimplemented commitment for the
current milestone. Keep it available for future milestone selection, but do not
treat it as a v1.47 closeout blocker.

Accrue provides the canonical billing state and lifecycle events. To provide a true "SaaS-in-a-box" experience, Accrue should provide seamless integration blueprints with the following sztheory libraries:

## When to Surface

Surface this seed when:

- a new milestone theme touches ecosystem interoperability or "SaaS-in-a-box" completeness;
- a concrete adopter needs one of the listed integrations (audit bridge, notification orchestration, PDF, search, identity/entitlement mapping);
- the maintainer is choosing where to expand Accrue's ecosystem surface next.

Note: dormant future-roadmap material — does not open milestone scope by itself.

## 1. Chimeway (Notification Orchestration) & Mailglass
*The Win:* Automated, Explainable Dunning & Upgrades. 
*Integration point:* Accrue emits canonical events (`invoice.payment_failed`, `subscription.trial_ending`). Chimeway consumes these to orchestrate multi-step, durable notification journeys (e.g., Send email -> wait 3 days -> escalate). Mailglass acts as the underlying transactional email framework for delivering these notifications reliably. Accrue's admin UI (`accrue_admin`) should expose the active Chimeway notification state for a given customer.

## 2. Threadline (Audit Platform)
*The Win:* Financial compliance and irrefutable billing ledgers.
*Integration point:* A telemetry bridge that automatically sinks Accrue's critical state changes (plan upgraded, invoice paid, refund issued, manual credit applied) into Threadline's immutable audit log, tagging the operator/user who initiated the change.

## 3. Rendro (PDF Generation)
*The Win:* Deterministic, pixel-perfect Invoice generation in pure Elixir.
*Integration point:* Accrue defines the standard data schema for an Invoice. Rendro takes that struct and produces the PDF without relying on external sidecars. Accrue then provides a blueprint for attaching that Rendro PDF to a Mailglass email.

## 4. Sigra & Lockspire (Identity & Access)
*The Win:* Tying billing entitlement to authentication access scopes.
*Integration point:* Exposing Accrue entitlement checks (`Accrue.has_active_plan?(user, "pro")`) as native plugs or Guards that map cleanly onto Sigra's session identity or Lockspire's OAuth scopes. For enterprise SaaS, Relyra can also be linked to SAML-driven entitlement provisioning.

## 5. Scrypath (Search Indexing)
*The Win:* Lightning-fast, Ecto-native admin search for billing records.
*Integration point:* Implementing Scrypath indexing across Accrue's `Customer`, `Invoice`, and `Subscription` models, enabling instant lookup capabilities natively within the `accrue_admin` LiveView interface.
