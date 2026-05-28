# Phase 150: Documentation & Adopter Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 150-documentation-adopter-proof
**Areas discussed:** Demo dunning scenario, Banner placement & style, Guide depth + core-only path, Customer resolution

---

## Pre-discussion: planning-state repair

Before discussion could begin, a half-finished, entirely-uncommitted milestone transition was blocking the GSD tooling (`init.phase-op` returned `phase_found: false`). The active top-level `.planning/ROADMAP.md` / `REQUIREMENTS.md` (held v1.44) had been deleted but never replaced; the v1.45 roadmap/requirements were stranded as untracked files under `.planning/milestones/`, and the active-milestone phase 149 dir was under `.planning/milestones/v1.45-phases/`.

**User chose:** "Repair, then discuss." Promoted `v1.45-ROADMAP.md`/`v1.45-REQUIREMENTS.md` to the active top-level position, moved the phase 149 dir into `.planning/phases/`, committed as `chore(planning): promote v1.45 roadmap to active position` (bd20e46b). Non-destructive — v1.44 archive untouched.

---

## Demo dunning scenario

| Option | Description | Selected |
|--------|-------------|----------|
| Seeded scenario | seeds.exs creates a demo user whose org has a past-due subscription + active dunning campaign (Fake processor); always-on, reproducible | ✓ |
| Dev-only trigger button | A dev/demo-only route or button to push the current subscription into dunning on demand | |
| Documented manual steps | No seeded data; guide documents manual Fake-processor steps | |

**User's choice:** Seeded scenario.
**Follow-up — which account:**

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated past-due account | Seed a separate user/org explicitly in dunning alongside a healthy primary account (side-by-side proof) | ✓ |
| Primary seeded user goes past-due | Put the existing main demo user into dunning | |

**User's choice:** Dedicated past-due account.
**Notes:** Always-on, reproducible via `mix ecto.setup` + log in. Healthy default account stays banner-free; reviewer can compare banner-on vs banner-off.

---

## Banner placement & style

| Option | Description | Selected |
|--------|-------------|----------|
| Top of `<main>`, default style | Mount in `Layouts.app` global, zero-config default styling — truest "drop it in" path | ✓ |
| Top of `<main>`, custom inner_block | Same placement but styled `inner_block` with CTA | |
| Subscription page only | Render only on the billing/subscription LiveView | |

**User's choice:** Top of `<main>`, default style.
**Notes:** Example showcases the zero-config headless default. The customized/CTA variant moves into the guide's customization snippet rather than the example.

---

## Guide depth + core-only path

| Option | Description | Selected |
|--------|-------------|----------|
| Both paths: component + core-only | Document the accrue_admin component (default + inner_block) AND a core-only requires_attention?/1 DIY snippet | ✓ |
| Component-focused only | Document only the accrue_admin component path | |
| Core-API-focused only | Document requires_attention?/1 primarily, mention component briefly | |

**User's choice:** Both paths.
**Follow-up — section placement in dunning.md:**

| Option | Description | Selected |
|--------|-------------|----------|
| After "Over-email warning" | In-app banners as the natural non-email alternative; cross-link from over-email section | ✓ |
| After "Observability" | Group with operator/surface concerns | |
| At the end | Append after "Lifecycle & entitlements" | |

**User's choice:** After "Over-email warning" (with cross-link).
**Notes:** Be explicit about the dep boundary — component requires accrue_admin, helper is core.

---

## Customer resolution

| Option | Description | Selected |
|--------|-------------|----------|
| Active org's Accrue customer | Resolve current scope's active organization → its Accrue customer; lookup in a small helper | ✓ |
| User-level customer | Treat the user as the billable | |
| You decide from the code | Inspect subscription_live.ex / AccrueHost.Billing and reuse that pattern | |

**User's choice:** Active org's Accrue customer.
**Notes:** Matches org-level billing model. Reuse the existing org→customer pattern in `subscription_live.ex` / `AccrueHost.Billing`; keep `Layouts.app` clean via a helper/assign.

## Claude's Discretion

- Guide prose/wording, snippet formatting, seeded account display name/email.
- Whether the org→customer helper lives in `AccrueHost.Billing` vs a layout assign/`on_mount` (match existing pattern).
- Exact form of the BAN-04 adopter-proof matrix row (follow existing matrix convention).

## Deferred Ideas

- Multi-channel SMS/push dunning via Chimeway — standing non-goal (compliance).
- Real-time PubSub-driven banner refresh — out of scope.
- Dedicated dunning-resolution UI in the example — banner CTA links to existing subscription page; full flow is its own concern.
- Promoting the banner component into core `accrue` — would re-open Phase 149's placement decision; core-only DIY doc path is the v1.45 answer.
