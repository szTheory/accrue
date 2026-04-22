# Phase 38: Org billing recipes — Pow + custom org boundaries - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning  
**Source:** Roadmap + REQUIREMENTS bootstrap (no separate discuss-phase transcript — scope locked from v1.8 table and Phase 37 spine).

<domain>
## Phase Boundary

Extend the **non-Sigra** org billing spine (`guides/organization_billing.md`) with two additive tracks promised in Phase 37 forward links:

1. **ORG-07** — **Pow**-oriented checklist: same `Accrue.Auth` / `Accrue.Billable` / host facade contracts as phx.gen.auth mainline, with **Pow.Plug** as the identity boundary and **explicit** active-organization resolution (Pow does not provide org tenancy).
2. **ORG-08** — **Custom org model** recipe: normative scoping rules for **LiveView admin**, **context functions**, and **webhook replay** actor alignment so hosts do not violate **ORG-03** when org membership is non-trivial (subdomains, custom session keys, delegated admin, etc.).

No new Accrue Hex dependencies. No Sigra requirement. Proof matrix (**ORG-09**) remains Phase 39.

</domain>

<decisions>
## Implementation Decisions

### Doc placement (ORG-07 + ORG-08)

- **D-01:** Add **two new H2 sections** to `accrue/guides/organization_billing.md` (same spine as Phase 37): `## Pow-oriented checklist (ORG-07)` and `## Custom organization model (ORG-08)` — placed **after** `## phx.gen.auth checklist` and **before** `## User-as-billable (bounded aside)` so the mainline remains generator-default-first.
- **D-02:** **Short cross-link** from `guides/auth_adapters.md` in the **MyApp.Auth.Pow** section to the new Pow checklist heading in `organization_billing.md` (relative link); do **not** duplicate the full checklist in `auth_adapters.md`.

### Pow recipe content (ORG-07)

- **D-03:** **Version-agnostic host contract focus:** document against **`Pow.Plug.current_user/1`** and `Accrue.Auth` callbacks — not against Pow’s internal module layout. Name **mix dependency pins** as the host’s responsibility; avoid coupling prose to a single Pow minor.
- **D-04:** **Honest maintenance framing:** Pow remains a common choice but is **community-maintained**; upgrades should re-verify Plug callbacks and custom extensions (`Pow.Extension` / mailer) — one short paragraph, not a changelog dump.
- **D-05:** Mirror the phx.gen.auth checklist **shape** (numbered steps): identity via Pow → **membership-gated** `current_organization` → `use Accrue.Billable` on `Organization` → facade accepts `Organization` → `config :accrue, :auth_adapter, MyApp.Auth.Pow` with pointer to **`MyApp.Auth.Pow` module body in `auth_adapters.md`**.

### Custom org model (ORG-08)

- **D-06:** Provide a **markdown table** mapping **ORG-03 path classes** (public, admin, webhook replay, export) to **custom-org failure modes** and **required host scoping behaviors** (explicit anti-patterns: param-only org id, global queries, replay without billable scope, export jobs without org filter).
- **D-07:** **Webhook replay alignment:** state that replay/admin tooling must resolve **the same billable row class** as live user flows and that **`Accrue.Auth.actor_id/1`** must not silently widen to a superuser when the acting user lacks membership (unless a documented break-glass path is host-owned and audited).
- **D-08:** **LiveView admin:** require `on_mount` (or equivalent) to load `current_organization` from **session + membership**, not from **live_action params alone**.

### Contract tests

- **D-09:** Extend `accrue/test/accrue/docs/organization_billing_guide_test.exs` with **ORG-07 / ORG-08** literal anchors (Pow checklist title, `MyApp.Auth.Pow`, custom-org section title, anti-pattern vocabulary).

### Claude's Discretion

- Exact subsection titles inside the two new H2s (H3 ordering).
- Whether to add a **single** installer scrollback line naming Pow explicitly — only if it fits without duplicating the spine.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — ORG-07, ORG-08 acceptance text.
- `.planning/ROADMAP.md` — Phase 38 goal and success criteria.

### Prior phase spine (Phase 37)

- `accrue/guides/organization_billing.md` — existing ORG-05/06 narrative, ORG-03 table, forward links.
- `.planning/phases/37-org-billing-recipes-doc-spine-phx-gen-auth/37-CONTEXT.md` — doc architecture decisions D-01..D-21.

### ORG-03 canonical text

- `.planning/milestones/v1.3-REQUIREMENTS.md` — ORG-03 row (full wording anchor).

### Auth adapter SSOT

- `accrue/guides/auth_adapters.md` — `MyApp.Auth.Pow` module body.

### Example host

- `examples/accrue_host/lib/accrue_host/` — reference wiring (generator-agnostic spine cites modules only).

</canonical_refs>

<specifics>
## Specific Ideas

- Phase 37 guide already references **Phase 38** / **ORG-07** / **ORG-08** in the ORG-03 intro — Phase 38 delivery should make those **clickable anchors** within the same file (headings) so ExDoc TOC works.
- `organization_billing_guide_test.exs` is the **merge-friendly** guardrail pattern from Phase 37 — reuse, extend needles list.

</specifics>

<deferred>
## Deferred Ideas

- **ORG-09** / adoption-proof matrix non-Sigra archetype — **Phase 39** only.

</deferred>

---

*Phase: 38-org-billing-recipes-pow-custom-org-boundaries*  
*Context gathered: 2026-04-21 via plan-phase bootstrap*
