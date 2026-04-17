# Phase 14: Adoption Front Door - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 14-adoption-front-door
**Areas discussed:** Root README Front Door, Package Docs Alignment, Fake vs Stripe Positioning, Support Surfaces, Public API Stability Message, Brand Voice and Claims

---

## Root README Front Door

| Option | Description | Selected |
|--------|-------------|----------|
| Thin signpost README | Mostly links to package docs and demo. Low drift, but too little trust for a lesser-known billing library. | |
| Balanced front door | Concise identity, package map, local demo, package tutorial, public boundaries, support, and Fake/Stripe labels. | Yes |
| Audience-split portal README | Separate evaluator/integrator/maintainer paths. Useful but can over-design the scan path. | |
| Tutorial-in-root README | Root README becomes full setup tutorial. Lowest click depth, highest duplication and drift. | |

**User's choice:** User asked the agent to research all areas and make the coherent recommendation.

**Notes:** Recommendation is a balanced root README: not a tutorial, not a bare signpost. It should define Accrue, explain `accrue` vs `accrue_admin`, route to the canonical host demo and First Hour guide, list public boundaries, and explain Fake/test/live validation modes.

---

## Package Docs Alignment

| Option | Description | Selected |
|--------|-------------|----------|
| Monolithic root README | Root README teaches repo, demo, install, webhooks, admin, testing, and support. | |
| Package-siloed docs | Each package README is self-contained and the root stays very short. | |
| Front-door plus canonical owners | Root README routes; host README owns executable demo; First Hour owns package tutorial; package/topic guides stay focused. | Yes |

**User's choice:** User asked for the researched recommendation.

**Notes:** Recommendation is to keep the Phase 13 split and make it stricter. One canonical owner per concern prevents drift and preserves the public API story.

---

## Fake vs Stripe Positioning

| Option | Description | Selected |
|--------|-------------|----------|
| Fake-first front door; Stripe test as provider-parity; live Stripe advisory/manual | Deterministic, no secrets, matches host demo and `Accrue.Test`, while still naming what real Stripe proves. | Yes |
| Fake and Stripe test mode as equal starts | Gives advanced users familiar Stripe path but splits the front door and implies secrets are required. | |
| Stripe test mode first; Fake as unit-test helper | Production-like but wrong for Accrue's no-secrets local demo and deterministic CI goals. | |
| Live Stripe validation required | Strong caution signal but brittle, secret-heavy, and external-state-dependent. | |

**User's choice:** User asked for the researched recommendation.

**Notes:** Recommendation is Fake as the canonical evaluation and required gate; Stripe test mode as provider-parity; live Stripe as advisory/manual. Docs must say what Fake does not prove.

---

## Support Surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Issue forms only, blank issues disabled | High triage quality but can feel rigid. | |
| Hybrid: four focused issue forms plus light contact links | Best balance: structured intake, security routed privately, legitimate setup blockers remain public. | Yes |
| Minimal templates with blank issues enabled | Lowest friction but noisy and risky for secrets/PII. | |

**User's choice:** User asked for the researched recommendation.

**Notes:** Recommendation is four public forms: bug, integration problem, docs gap, feature request; blank issues disabled; security and general reading routed through contact links. No generic support-question issue template.

---

## Public API Stability Message

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit public-boundary contract in README, First Hour, and Upgrade | Copy-paste safe, aligns with Phoenix context/generated-code precedent, supports upgrade safety. | Yes |
| Host-first examples only | Lighter but leaves boundaries implicit and risks internal coupling. | |
| API-doc labeling only | Precise but too late for first users who copy README/guide snippets. | |

**User's choice:** User asked for the researched recommendation.

**Notes:** Recommendation is a short repeated contract: generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router.accrue_admin/2`, `Accrue.Auth`, and `Accrue.ConfigError` are supported first-time integration surfaces; internals are not app-facing API.

---

## Brand Voice and Claims

| Option | Description | Selected |
|--------|-------------|----------|
| Framework-native, proof-backed | Calm, Phoenix-native, precise, and tied to host-demo proof. | Yes |
| Capability-led, compact | Good scanability but can drift into a feature blob. | |
| Commercial-style breadth-led | Stronger marketing pull but wrong for Accrue's OSS trust posture. | |

**User's choice:** User asked for the researched recommendation.

**Notes:** Recommendation is measured, proof-backed copy. Lead with identity and operating model, show host-demo proof immediately, and avoid unsupported maturity claims until Phase 15 adds evidence.

---

## the agent's Discretion

- Exact root README section order and copy.
- Exact issue form filenames/YAML field names.
- Exact docs drift-check implementation.
- Exact release-guidance placement for required vs advisory validation labels.

## Deferred Ideas

- Hosted public demo.
- Phase 15 trust evidence surfaced as badges or README sections after security/performance/accessibility/compatibility checks exist.
- Phase 16 expansion positioning for tax, revenue/export, processors, and org billing.
