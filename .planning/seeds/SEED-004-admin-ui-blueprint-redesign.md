---
id: SEED-004
status: backlogged
planted: 2026-07-04
planted_during: post-Phase-205 admin-UI blueprint synthesis
trigger_when: opening any admin/operator UI, information-architecture, content-hierarchy, design-system, or admin-surface-quality milestone; or selecting the next post-v1.56 milestone
scope: Large
---

# Admin/Operator UI Blueprint Redesign (IA + Content-Hierarchy Pivot)

**Domain:** `accrue_admin` information architecture, content hierarchy, and signature operator surfaces (with a flagged core-`accrue` diagnosis dependency)
**Status:** Backlogged / Future Roadmap — **post-v1.56**

This is a strategic future-roadmap seed, not a commitment for the current milestone.
It does **not** create v1.56 scope and is **not** a v1.56 closeout blocker. Keep it
available for milestone selection once the v1.56 Admin UI Ratchet ships.

## What it is

A first-principles redesign of the admin/operator UI toward a coherent, best-in-class
**"operator control plane over billing state"** — reframing the admin UI around three
questions (what needs attention? / what is the customer's true billing state? / what safe
action can I take?) rather than CRUD over the schema.

**North-star source (authoritative target):** `prompts/accrue_admin_operator_ui_journey_blueprint.md`
(≈94KB; `prompts/map_out_user_journeys_prompt.txt` is a byte-identical copy).
**Synthesis + critical analysis (self-contained, read this first):**
`.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md`.

## Why it's a new thing (not v1.56)

v1.56 (Admin UI Ratchet) is evaluation **machinery** that locks quality forward-only against
the **current** design + locked brand DNA — it explicitly scopes out a new visual target and
any core changes. This blueprint is a genuine **new target** (a "huge change" the ratchet
deliberately avoids). Correct order: finish v1.56, then open this. After the redesign lands,
the ratchet's design-lens rubric + persona-job strings + exemplars get refreshed to the new
surfaces and the ledger baseline is re-frozen — the ratchet becomes the tool that *locks* the
redesign, it does not drive it.

## Highest-value ideas to adopt (full list in the synthesis doc §2)

- **"Why blocked?" diagnosis card** — the signature support component (synthesizes entitlement +
  subscription + invoice + payment + webhook-lag into a plain-language verdict).
- **Causality graph / causal timeline** — first-class event-chain visualization.
- **Saved "lenses" as the default list model** — lists open on actionable work; "All" one click away.
- **Sensitive-action class A/B/C** with step-up on destructive/money/legal actions.
- **IA restructure** — add **Usage** + **Settings** nav groups; **de-tab Customer-360** into anchored
  sections; resolve single-item-group / Home-vs-Dashboard / Payments-vs-Charges naming drift.
- **New rooms the current UI lacks** — Usage/meters/metered-renewals, checkout sessions, Connect
  capabilities matrix, fee reconciliation.
- **Discipline layer** — six screen grammars, answer-order laws, one related-resource strip per detail,
  freshness/stale chips, optimistic-lock handling, "[Object] [verb]. View event." toasts, non-celebratory
  empty-state grammar, ⌘K command palette.

## Scope flag: reaches into core `accrue`

Unlike v1.50–v1.56 (all `accrue_admin`-only), the signature diagnostic surfaces need core diagnosis
functions (`blocking_reason_for_owner/1`, `billing_state_for_customer/1`, `causality_chain_for_event/1`)
and durable event-name contracts (blueprint §45). Budget a core-diagnosis phase, or ship LiveView v1
heuristics and swap later. This changes the reopen scope from "admin UI only" to "admin UI + core diagnosis."

## Recommended decomposition (not locked — `/gsd-new-milestone` formalizes)

- **M1 IA + screen-grammar pivot** (`accrue_admin` only, lowest risk): nav restructure, de-tab Customer-360,
  lens-default lists, screen grammars, answer-order laws, sensitive-action A/B/C, freshness/lock chips,
  "View event" toasts, ⌘K upgrade. Ratchet-friendly discipline.
- **M2 Signature diagnostic surfaces + core diagnosis backend**: "Why blocked?" card, causality graph,
  state-as-of, unified billing-state view + the §45 core functions.
- **M3 New-domain rooms & completeness**: Usage/meters, checkout sessions, Connect capabilities matrix,
  fee reconciliation, (decide) product/price catalog; then ratchet re-freeze/sweep.

Small-appetite alternative: ship **M1 only** as the next admin milestone (most of the "coherent, cohesive,
best-in-class" feel, zero core-backend risk) and re-seed M2/M3.

## Posture guardrails to carry (do not relitigate)

`ax-*` tokens are the styling SSOT (Tailwind = compile-time minifier, not an authoring path); ratified
palette; Geist Sans/Mono canonical; brand anchors Linear/Vercel/Prisma/Tailscale/Oban (Stripe dropped as
brand-positive); dense operator console, not fintech; core `accrue` LiveView-runtime-free; no `accrue_portal`
work under this seed (portal white-label is a separate queued item in the Phase 204 hardening roadmap).

## When to Surface

Surface this seed when:

- a new milestone is being opened after v1.56 (Admin UI Ratchet) ships;
- the next milestone theme touches the `accrue_admin` operator UI, information architecture, content
  hierarchy, or design system;
- signature-diagnostic work is being considered ("Why blocked?" card, causality graph, saved-lens list
  model, sensitive-action A/B/C, or the new Usage / checkout / fee-reconciliation rooms);
- the maintainer is choosing where to take admin UX next, or asking "what's the roadmap for the admin UI".

Open via `/gsd-new-milestone` with reopen class **"explicit strategy change — flagship admin surface"** +
concrete maintainer request (the established v1.50–v1.56 precedent). Downstream spec-generation scaffolding
lives at blueprint §47–48.
