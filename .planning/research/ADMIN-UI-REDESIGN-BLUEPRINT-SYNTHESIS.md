# Candidate Milestone Research: Admin/Operator UI Redesign (Blueprint Synthesis)

**Status:** Candidate / seed research (see `SEED-004-admin-ui-blueprint-redesign`). Not an active milestone.
**Created:** 2026-07-04
**Scope target:** `accrue_admin` (with a flagged core-`accrue` dependency — see §7).
**Sequencing:** Post-v1.56. Open via `/gsd-new-milestone` after the v1.56 Admin UI Ratchet ships.

---

## 0. What this document is

The maintainer ran a blue-sky, first-principles deep-research pass in a separate LLM and produced a comprehensive **admin/operator UI journey blueprint** for Accrue. This document is the **synthesis + critical analysis** of that blueprint: what's worth adopting, how it differs from what we ship today, the tradeoffs/patterns/antipatterns/footguns, and a recommended way to fold it into the GSD roadmap as a post-v1.56 redesign program.

It is written to be **self-contained** — a future session with cleared context can act from this file alone without re-reading the 94KB blueprint.

### Provenance
- **Blueprint (primary source):** `prompts/accrue_admin_operator_ui_journey_blueprint.md` (~94KB, 3,420 lines). `prompts/map_out_user_journeys_prompt.txt` is a **byte-identical copy** — treat as one document. Section numbers below (§NN) refer to it.
- **Posture / hard constraints / current baseline:** `prompts/accrue-library-summary-for-admin-ux-deep-research.md` (the summary we wrote to seed the deep-research run — carries the `ax-*`/no-Tailwind/LiveView/`?org=` hard rules, ratified palette hexes, banned-words list, brand anchors, and the current-UI Appendix A).
- **Brand/voice/imagery:** `prompts/accrue-brand-book.md` (older/looser font options; superseded by the ratified `brandbook/` where they conflict).
- **Downstream scaffolding:** blueprint **§47–48** contain two ready-to-use LLM prompts for generating a full UI/UX spec and a compact version — use these when the milestone actually opens.

### Verdict (one line)
**Adopt the blueprint as the north-star target for a post-v1.56 admin-UI redesign.** It is high-quality and strongly aligned with our locked posture (dense operator console, not fintech, LiveView, exceptions-first, ratified palette). Divergences are minor and reconcilable (§6). It is a genuine *new target*, distinct from the v1.56 ratchet, which is evaluation *machinery* against the *current* design (§8).

---

## 1. The blueprint's core thesis (the framing to keep)

> "Accrue Admin is not a generic CRUD interface. It is an **operator control plane over billing state**." — §1

The UI's job is to answer three questions faster than anything else:
1. **What needs attention?** (exceptions-first)
2. **What is the customer's true billing state?** (across processor / projection / entitlement / event)
3. **What safe action can the operator take now?** (guarded, auditable)

Desired feel: **calm, exact, dense, durable — a maintainer-grade operations console, not a fintech dashboard.** The recurring north-star support question the whole UI is optimized for: *"This customer says they paid — why are they blocked?"*

---

## 2. Load-bearing ideas worth adopting

Each with why it matters + a rough impact/effort tag (I = impact, E = effort, both 1–3).

1. **"Operator control plane over billing state" framing** (§1) — the organizing mental model; everything else follows from it. **I3/E1** (it's a stance, not a build).
2. **Exceptions-first operating model** (§1, §6) — operators chase exception states, not healthy ones. Canonical exception set: failed/dead webhooks, past-due subs, open invoices needing work, failed usage reports, fee-reconciliation mismatches, expiring cards, Connect capability/payout issues. We already lean this way (dashboard four-zone); the blueprint makes it *pervasive* (every list defaults to an actionable lens). **I3/E2**
3. **"Why blocked?" diagnosis card** (§14.4) — **the signature support component.** Synthesizes entitlement + subscription + invoice + payment + webhook-lag + payment-method state into a plain-language verdict ("Customer appears blocked because the active entitlement cache has not synced after payment. Invoice INV-0042 is paid…"). Fallback verdict when nothing local blocks. This is the single highest-differentiation idea. **I3/E3** (needs core diagnosis fn — §7).
4. **Causality graph + causal timeline** (§9.8–9.9, §32.4) — first-class visualization of upstream/downstream event chains: `Webhook invoice.paid applied → Invoice marked paid → Subscription active → Entitlements synced`. Nodes: processor event, webhook event, ledger event, object state change, email sent, entitlement sync. Left-to-right desktop, vertical mobile. **I3/E3** (needs `causality_chain_for_event` — §7).
5. **Saved views / "lenses" as the core list model** (§8.2, §9.7) — every list defaults to *actionable work, not "all records"*; **"All" is always one click away.** Compliance is just a saved lens, not a nav destination. **I3/E2**
6. **Sensitive-action class system A/B/C** (§40) — uniform risk taxonomy: **A** (ordinary reversible: send invoice, set default PM, preview) → simple modal; **B** (state-changing: finalize, pause, swap plan, apply promo, replay) → preview + confirm + audit event; **C** (destructive/money/legal: refund, void, mark-uncollectible, cancel-now, detach-only-PM, reject Connect account, bulk replay) → guarded wizard + reason + **step-up auth** + explicit impact preview. **I3/E2**
7. **Uniform confirmation + success pattern** (§40.2–40.3) — every state-change toast reads **"[Object] [verb completed]. View event."** (e.g. "Refund created. View event."); every state-changing action links to its audit event. Ties the UI to the ledger. **I2/E1**
8. **Freshness / stale-projection chips** (§39.7) — e.g. "Last processor event 14m ago"; and when a failed webhook may be blocking a record: "A failed webhook may be preventing this state from updating. Review webhook." Directly serves the "why blocked?" job. **I2/E2**
9. **Optimistic-lock conflict handling** (§39.6) — on `lock_version` conflict: "This record changed after the page loaded. Review the latest state before applying this action." + Refresh/Compare/Cancel. **I2/E2**
10. **Domain-language translation table** (§4) — user-facing nouns/verbs/states with rules on when to keep backend terms (Charge→"Payment" in operator UI, keep "Charge" in raw/debug; MeterEvent→"Usage report"). **Exact backend statuses shown as chips with hover helper text — no friendlier synonyms that obscure legal/processor meaning.** Banned vague verbs: Manage/Handle/Fix/Resolve unless paired with a precise object + outcome. **I2/E1**
11. **Six named "screen grammars"** (§8) — Overview / Worklist / Index-list / Detail / Incident-debug / Action-wizard, each with a fixed content order. Consistency without forcing identical layouts. (We ship 3 today — overview/list/detail; this adds Worklist, Incident-debug, Action-wizard.) **I2/E2**
12. **Content-hierarchy "answer order" laws** (§41) — every detail page answers in order: *What is this? → What state? → Is anything wrong? → What can I do? → What related records? → What happened over time? → What raw payload proves it?* Every queue row: *Which object/customer → What state → How much/impact → How old/urgent → What next action.* Every error: *what happened → how to recover → where to inspect.* **I3/E1** (a rubric, cheap to adopt).
13. **List→detail→next-item worklist loop** (§39.1) — detail pages reached from a worklist support back-to-filtered-list, previous/next item, and a **queue position indicator** ("3 of 18 open invoices"), preserving scroll/filter state. The finance "invoices-to-zero" power-user path. **I2/E2**
14. **Exactly one related-resource strip per detail** (§39.2) — one compact strip of primary related objects; explicit anti-scatter rule. **I2/E1**
15. **Local-projection source labels** (§3.2) — subtle source chips (Processor / Local projection / Application / Audit); raw/debug shows `processor`, `processor_id`, local UUID, `last_stripe_event_ts/id`, `lock_version`. Restraint: don't say "source of truth" everywhere — tooltips/debug only. **I2/E2**
16. **Global command palette (⌘K) as a first-class surface** (§12) — searchable across customer name/email, app-owner ID, all UUIDs + processor IDs, invoice number, promo code, webhook/event/checkout IDs; exact-ID match sorts first. **Palette must NOT commit destructive work** — it may open the relevant modal but never execute. **I3/E2**

Supporting/keep-in-mind: environment pill (Live/Test/Fake) + calm Fake banner (§6.4); work-not-count nav badges with text (`3 dead`, `18 at risk`) (§6.2); org scope as global chrome, not a per-page filter, `?org=` on every URL (§6.3); 17-component anatomy inventory (§9); non-celebratory empty-state grammar "No [objects]. [Objects] appear here when [condition]." (§9.17); WCAG 2.2 AA + keyboard model `g h/c/s/i/w`, `/`, `⌘K`, `?`, `Esc` (§44, §7.4).

---

## 3. Delta vs the current baseline (what actually changes)

Current baseline (per Appendix A of the library summary + code): **6 nav groups, ~21 screens, 3 screen grammars**; Customer-360 is **tabbed**; lists are table-first but not lens-defaulted everywhere.

### 3.1 Information-architecture changes
- **+ Usage** top-level nav group (Usage reports / Meters / Metered renewals) — **absent today.**
- **+ Settings** top-level nav group (processor status readout / theme / density / reduced-motion / branding readout) — **absent today.**
- **De-tab Customer-360** → anchored/collapsible sections (§8.4, §14.5). Blueprint prefers anchored sections + collapsible drilldowns over tabs for primary content; tabs allowed *only* for peer record-sets. Today's Customer-360 is tabbed → a deliberate divergence.
- **Lens-default list model** everywhere (§5, §8.2) — lists open on actionable work with "All" one click away, vs today's more generic list defaults.
- **Related-resource-strip discipline** (§39.2) — one strip per detail, vs scattered links.
- **Nav grouping cleanup opportunity** — the current nav has 3 single-item groups (Home, Recovery, Connect); Recovery expands to 3 items (at-risk / dunning campaigns / expiring cards) under the blueprint, reducing single-item-group awkwardness. "Home" vs "Dashboard" naming mismatch and the `ChargesLive`/"Payments" module-vs-label drift are also worth resolving in the same pass.

### 3.2 New/expanded surfaces the current UI lacks
- **Usage room**: usage-reports DLQ worklist (default = Failed) + report detail (raw payload + retry w/ idempotency key) + meters list/detail + metered-renewals state machine (`pending / retry_scheduled / awaiting_payment_method / paid / failed_exhausted`).
- **Checkout sessions** list + detail (acquisition/incomplete-flow debugging) — under Developer.
- **Connect capabilities matrix** (§29–30) — requirements checklist + capabilities matrix (rows=capabilities; cols=requested/status/requirement-link).
- **Fee reconciliation** (§19–20) — Payments saved views "Fee unsettled" / "Fee mismatch" + a dedicated fee-reconciliation section on payment detail (charge amt, processor fee, net, settlement status, refund fee impact, mismatch warning).
- **Product/Price catalog gap** — noted in the baseline audit: subscriptions reference plans with no navigable product/price entity. The blueprint doesn't add one either, but it's a real IA gap to weigh.
- **State-as-of reconstruction** on the event log (§33–34) — "View state at this time" → before/after diff.

### 3.3 Cross-cutting systems to introduce
Sensitive-action A/B/C (§40), freshness/stale chips (§39.7), optimistic-lock handling (§39.6), "View event" toasts (§40.3), the domain-language table (§4), and the six screen grammars (§8).

---

## 4. Analysis: pros / cons / tradeoffs

**Pros**
- Coherent, first-principles IA that maps to *personas' entry points*, not the data schema — directly serves the "altitude" persona model (personas 1–3 same entities at different altitudes; 4–6 specialist rooms; Compliance = saved lens).
- The signature diagnostic surfaces ("Why blocked?", causality graph) are genuine differentiation — they turn Accrue's existing strengths (event ledger, projections, entitlement cache) into an operator superpower no Stripe-dashboard-clone offers.
- Strongly on-posture: dense, calm, LiveView, exceptions-first, ratified tokens — low reconciliation cost.
- Much of it is *rubric/discipline* (answer-order laws, screen grammars, empty-state grammar, related-strip rule) — cheap to adopt and it hardens consistency, which is exactly what the ratchet then locks.

**Cons / risks**
- **Scope is large** — 37-screen anticipated surface, 8 journeys, several new rooms. Not one milestone (see §5).
- **Reaches into core `accrue`** for the first time in the admin-UI line (§7) — the signature surfaces need backend diagnosis functions. That's a scope-class change, not just a UI pass.
- **De-tabbing Customer-360 and lens-defaulting every list are user-visible behavior changes** — need care to not regress the muscle memory of existing adopters.
- **Anti-over-whitespacing tension** — the blueprint's "dense but breathable" and the ratchet's "operator-density-defender" must agree; a redesign that adds air to look "designed" would fight both.

**Tradeoffs to decide at `/gsd-new-milestone` time**
- Build the new rooms (Usage, checkout, fee-recon) *before* or *after* the signature diagnostic surfaces? (Recommended: IA/grammar pivot first, signature surfaces second, new rooms third — §5.)
- How much core-backend work to pull in vs. defer (a "Why blocked?" card can ship a v1 heuristic in the LiveView before the core `blocking_reason_for_owner/1` exists, then swap).

---

## 5. Consolidated patterns / antipatterns / footguns (adopt as review checklist)

**Patterns to enforce**
- One page = one decision/task; lead with exceptions, demote KPIs (clickable, below tasks).
- Lists default to an actionable lens; "All" one click away.
- Detail pages follow the answer-order laws; exactly one related-resource strip.
- Every state-changing action → preview + audit event + "View event" toast; sensitive ones get step-up (class C).
- Status is **never color-only** — always paired with label text.
- Domain verbs, not CRUD; exact backend statuses as chips w/ hover, no obscuring synonyms.
- Empty states non-celebratory: "No [objects]. [Objects] appear here when [condition]."

**Antipatterns to avoid**
- Wall of metrics / chart wall as the landing surface.
- Ambiguous single "Cancel" — always split **Cancel now** vs **Cancel at period end** (§16.9).
- Vague verbs (Manage/Handle/Fix/Resolve) unbound to object+outcome.
- Scattering related links across every section (use the one strip).
- Raw JSON dominating support/finance screens (collapsed, labeled, sized).
- Destructive actions executing inline from tables (open a modal/wizard).
- Destructive actions committing from the command palette (palette opens, never commits).
- Tabs used to hide primary state (tabs only for peer record-sets).
- Celebratory/theatrical motion; cheerleading empty states.
- Processor links as primary (mark external "Open in Stripe"; only when local UI can't complete the task).

**Footguns (billing-specific)**
- Stale/idempotent replay — replay flows must surface local watermark + idempotency and can show skipped/stale outcomes (§32.6, §38.5).
- Bulk void/pay — discouraged without strong requirement + step-up (§17.8).
- Detaching the only payment method on active/past-due subs — stronger warning + step-up (§21.5).
- Optimistic-lock conflicts — never silently overwrite; show the conflict (§39.6).

---

## 6. Posture reconciliation (import these; the blueprint is silent or looser)

- **`ax-*` tokens are the styling SSOT; Tailwind is a compile-time minifier, NOT an authoring path.** The blueprint names token *roles* (Ink/Slate/Fog/Paper/Moss/Cobalt/Amber + semantic danger/info) but is **silent on the mechanism**. Carry the `ax-*` rule from the library summary §8 — do not let a redesign author raw Tailwind utilities.
- **Palette hexes (ratified):** Ink `#111418`, Slate `#24303B`, Fog `#E9EEF2`, Paper `#FAFBFC`, Moss `#5E9E84`, Cobalt `#5D79F6`, Amber `#C8923B`, Danger `#D64B4B`, Info `#3878A6`; dark base `#0F1318`, elevated `#171D24`. Rules: status never color-only; danger red reserved for destructive/error; Cobalt = interaction/focus, not status.
- **Typography:** **Geist Sans + Geist Mono** is canonical (library summary §7, blueprint §42.3). The brand book's older Inter/IBM-Plex options are superseded.
- **Brand anchors:** Linear / Vercel / Prisma / Tailscale / Oban. **Stripe is dropped as a brand-positive exemplar** (fintech, conflicts with the "not a fintech dashboard" posture) — density/IA reference only. The blueprint never names anchors; carry them from the summary.
- **Voice:** sand the blueprint's casual nits ("MRR-ish", "money-moving action") to named mechanisms; honor the banned-words list (production-grade, seamless, powerful, easy, wallet, money, funds, demo, …).
- **Aligned already (no action):** LiveView (§16.7, §39.5), dense/not-fintech (§1, §42), `?org=` scoping (§6.3), WCAG AA + 360px mobile (§43–44).

---

## 7. Core-`accrue` backend dependency (scope flag)

The signature diagnostic surfaces are **not pure `accrue_admin` work** — a first for the admin-UI line (v1.50–v1.56 were all admin-only). Blueprint §45 argues the UI language should drive backend cleanup:
- **Diagnosis functions** the UI needs: `blocking_reason_for_owner/1` ("why blocked?"), `billing_state_for_customer/1` (unified state across processor/projection/entitlement), `causality_chain_for_event/1` (the causality graph's data).
- **Domain verbs over CRUD**: `void_invoice`, `pause_subscription`, `replay_webhook` (not `object.update`).
- **Event names as durable UI contracts**: `invoice.finalized`, `refund.created` (not `object.updated`).

Implication: the redesign program must budget a **core-diagnosis phase/milestone**, or ship v1 heuristics in the LiveView and swap to core functions later. Flag at `/gsd-new-milestone` — this changes the reopen scope from "admin UI only" to "admin UI + core diagnosis surface."

---

## 8. Relationship to the v1.56 Admin UI Ratchet (keep them distinct)

- **v1.56 ratchet = machinery.** It fans out adversarial persona + design-lens evaluators, dedups, verifies, and mints deterministic guards to lock quality forward-only against the **current** design + locked brand DNA. It explicitly scopes OUT a new "target" (no 13th "award" rubric dimension) and any `accrue_portal` work, and its whole principle is *incremental, no huge changes*.
- **This blueprint = a new target.** A redesign is exactly the "huge change" the ratchet avoids.
- **Do NOT retarget the mid-flight ratchet.** Finish v1.56 (Phases 206→208; 209 optional) against today's design.
- **Downstream ratchet-refresh step (record for later):** once the redesign lands, refresh the ratchet's **design-lens rubric**, **persona-job strings** (`baseline-manifest.js`), and **exemplars** to the new signature surfaces, then **re-freeze the ledger baseline**. The ratchet becomes the tool that *locks* the redesign — it doesn't drive it.

---

## 9. Recommended milestone decomposition (a program, not one milestone)

Recommended shape — **not locked**; `/gsd-new-milestone` formalizes phases/requirements. Each carries the established reopen class: *"explicit strategy change — flagship admin surface"* + concrete maintainer request.

- **M1 — IA + screen-grammar pivot** (`accrue_admin` only, lowest risk, highest coherence-per-effort):
  nav restructure (+Usage +Settings, resolve single-item-group + Home/Dashboard + Payments/Charges naming drift), de-tab Customer-360, lens-default list model, related-resource-strip discipline, six screen grammars, answer-order laws, sensitive-action A/B/C, freshness/stale chips, optimistic-lock handling, "View event" toasts, empty-state grammar, ⌘K palette upgrade. *Ratchet-friendly: mostly discipline the ratchet can then lock.*
- **M2 — Signature diagnostic surfaces + core diagnosis backend** (reaches into core `accrue` — §7):
  "Why blocked?" card, causality graph/timeline, state-as-of reconstruction, unified billing-state view; plus the core `blocking_reason_for_owner` / `billing_state_for_customer` / `causality_chain_for_event` functions + durable event-name contracts.
- **M3 — New-domain rooms & completeness**:
  Usage/meters/metered-renewals room, checkout sessions, Connect capabilities matrix, fee reconciliation, (decide on) product/price catalog. Then **ratchet re-freeze/sweep** (§8) and optionally graduate the full surface under the ratchet.

Alternative if appetite is small: do **M1 only** as the next admin milestone and re-seed M2/M3. M1 delivers most of the "coherent, cohesive, best-in-class" feel with no core-backend risk.

---

## 10. Source pointers

- **Blueprint (verbatim, exhaustive):** `prompts/accrue_admin_operator_ui_journey_blueprint.md` (= identical `map_out_user_journeys_prompt.txt`). Key sections: §1 thesis, §3 three-worlds + two write paths, §4 domain-language table, §5 personas, §6 IA + badges + org/env chrome, §8 screen grammars, §9 component inventory, §10 screen inventory, §11–37 per-screen specs, §38 the 8 journeys, §39 cross-cutting interaction rules, §40 sensitive-action A/B/C, §41 answer-order laws, §42–44 graphic design / responsive / a11y, §45 backend alignment, §47–48 downstream spec-gen prompts.
- **Posture + current baseline:** `prompts/accrue-library-summary-for-admin-ux-deep-research.md` (§4 verbs, §5 personas+altitude, §6 exceptions, §7 palette/type/voice/banned-words/anchors, §8 `ax-*`/LiveView/`?org=` hard constraints, Appendix A current nav + 21-screen baseline + 3 grammars).
- **Brand/voice/imagery:** `prompts/accrue-brand-book.md` (superseded by `brandbook/` where they conflict).
- **Current code baseline:** `accrue_admin/lib/accrue_admin/{router.ex,nav.ex,live/}`, `accrue_admin/e2e/baseline-manifest.js`, `accrue_admin/guides/spec-{overview,list,detail}.md`.
- **Ratchet context:** `.planning/ROADMAP.md` (v1.56, Phases 205–209), `~/.claude/plans/ui-ratchet-txt-i-agile-honey.md`.
