# Feature Research

**Domain:** `accrue_admin` operator-control-plane IA / screen-grammar pivot (v1.57 SEED-004 **M1**) — reign **Home** + **Subscriptions** onto the shared component vocabulary and restructure their information architecture
**Researched:** 2026-07-19
**Confidence:** HIGH (grounded in the SEED-004 blueprint synthesis, the 23 round-99 ratchet-confirmed findings, and direct reading of `dashboard_live.ex` + `subscriptions_live.ex` against the canonical Payments/Customers/Invoices reference grammar)

---

## Framing (the M1 north-star, in one paragraph)

The blueprint's thesis: **"Accrue Admin is not a CRUD interface — it is an operator control plane over billing state."** Every screen must answer three questions faster than anything else: (1) **What needs attention?** (2) **What is the true billing state?** (3) **What safe action can I take?** M1 does **not** build the signature diagnostic surfaces (those are M2) or new rooms (M3). M1 is the **coherence layer**: apply the "answer-first / one health verdict / one primary action per zone" screen grammar — the grammar the reference list pages (Payments/Customers/Invoices) already exhibit — to the two outlier pages (**Home**, **Subscriptions**), retiring their bespoke component sets and trimming the redundant bands, so the whole admin reads as one system before M2's diagnostics land.

**Why these two pages:** Subscriptions already imports the shared vocabulary (`PageHeader` / `StatStrip` / `DataTable` / `FilterChipBar` / `StatusBadge`) but buries it under ~5 stacked bespoke `ax-inline-worklist` / `ax-subscriptions-*` bands. Home is fully bespoke — `ax-home-*` / `ax-launcher*` / `ax-attention*` — and shares almost nothing with the reference grammar. Together these are the ~325 rules of outlier CSS the milestone retires.

---

## Feature Landscape

### Table Stakes (Must-Do for M1 Cohesion)

Non-negotiable for the "one cohesive operator-first system" goal. Each traces to a blueprint principle **and/or** a round-99 finding.

| Feature | Why Expected / Trace | Complexity | Notes |
|---------|----------------------|------------|-------|
| **One scannable health verdict per page** (single verdict element; retire competing/redundant health signals) | Blueprint §1 "what is true billing state" + §41 answer-order. Home: `f-48c5df33` (verdict buried in dense P1/P2/P3 alert blocks), `f-3536ce24` (red banner "Billing status: Unhealthy" **duplicates** the page title "Billing health: Unhealthy"). Subscriptions/detail family: `f-c56b21f4`, `f-f1a5f298`, `f-48c3e6c9` (health scattered / competing banners with no hierarchy) | MEDIUM | Today Home renders the verdict **three times** (`dashboard_health_headline/1` H1 **and** `ax-home-header-health` band **and** `ax-attention-summary` "Billing status: Unhealthy"). Collapse to a single verdict in the `PageHeader` title slot. |
| **Reign onto the shared vocabulary** (`PageHeader` / `StatStrip` / shared `DataTable`+cell idiom / `FilterChipBar` / `.ax-card` / `Button` / `StatusBadge` / `EmptyState`); retire `.ax-home-*` / `.ax-launcher*` / `.ax-attention*` / `.ax-subscriptions-*` / `.ax-inline-worklist*` (~325 rules) | PROJECT.md M1 target feature #1; blueprint §8 screen grammars. Home currently shares **zero** primitives with the reference pages | HIGH | The single largest lever. Subscriptions is a partial job (already uses `PageHeader`/`StatStrip`/`DataTable`); Home is a from-scratch reign onto `PageHeader` + `StatStrip` + a `.ax-card`-based launcher/exception list. Compose the existing shared components — do **not** fork. |
| **One primary action per zone; de-duplicate competing entry points** | Blueprint §39.2 (one related-resource strip) + §41 "what next action". Subscriptions: `f-5a1ecbfd` ("Open dedicated invoice queue" appears **3×** — banner, blue card, tab), `f-ad500f6f` (unclear if working rows resolves the 2 open invoices or you go elsewhere), `f-186adbbb` ("Work open invoices" appears **2×** in table, no affordance), `f-037729e9` (queue link rendered as inline body text, not a control) | MEDIUM | Subscriptions currently has **three** stacked bands (`ax-subscriptions-invoice-strip`, `ax-subscriptions-queue-shortcut`, `ax-subscriptions-invoice-records`) each with its own "Open dedicated invoice queue" CTA. Collapse to **one** canonical invoice-queue entry point. |
| **Trim redundant bands + tighten density** (remove stacked worklist bands; fix oversized padding) | Blueprint "dense but breathable" / operator-density-defender. Padding findings: `f-70ea46e4` (MRR row ≈24px/16px waste), `f-f00ee035` (primary queue banner ≈16px pushes table below fold), `f-4704825f` (table rows ≈16px waste), `f-033f8d87`, `f-54366a37`, `f-7573c4d4`, `f-4f83748a` (breadcrumb+banner padding pushes data below fold) | MEDIUM | Removing the redundant bands (above) fixes most of these structurally; the rest is spacing tokens back to the reference density. Density must match Payments/Customers/Invoices, not add "designed" air. |
| **Plain-language verdicts + precise action labels** (no double-negatives, no CRUD/jargon verbs) | Blueprint §4 domain-language table; banned vague verbs (Manage/Handle/Fix/Resolve, plus jargon). `f-66d02ab6` ("No - billing is not active" double-negative), `f-3229847d` (jargon "workspace"), `f-186adbbb` / `f-45f7a0e8` / `f-0f90c9ba` (button outcome unclear) | LOW | Copy lives in `AccrueAdmin.Copy` (SSOT). Verdict reads as a positive-framed state ("Past due — $592.50 to collect"), action labels name object+outcome ("Collect open invoices"). |
| **Correct navigation paths + breadcrumb integrity** | Blueprint §6 IA. `f-16203f0c` (breadcrumb "Billing health overview / Subscriptions" implies a parent page with **no return control** — Subscriptions' breadcrumb points at `""` = Home, but the label promises a "Billing health overview" that Home must actually be), `f-f6f54df7` (Webhooks has no visible path to Events) | LOW | Make Home genuinely be the "Billing health overview" the Subscriptions breadcrumb references, or rename. Scoped to what Home/Subscriptions link to. |
| **Customer lookup as a first-class, prominent entry** | Blueprint §12 (⌘K first-class) + persona "find ONE customer, see everything". `f-ca8eabe5` (search buried in a small blue banner at the **bottom** of Priority exceptions), `f-91cf2660` / `f-f1be6ae0` (filter/lookup de-emphasized, far from workspace), `f-bd22ab26` (search button blends into input) | LOW | The command-palette trigger already exists (`data-command-palette-trigger`); promote it to a prominent, single, obvious entry in the page header — stop rendering it three times in three visual weights. |
| **Answer-first content order on both pages** (verdict → primary action → demoted KPIs → records) | Blueprint §41 answer-order laws + §8 Overview/Index-list grammars. `f-f72b5bca` / `f-3380c550` (header mixes health verdict **and** action guidance in one dense paragraph, forcing simultaneous parsing) | MEDIUM | KPIs are clickable but demoted **below** the verdict + exceptions (Home already attempts this with "Zone 3 — demoted KPIs"; keep the intent, standardize the containers). |
| **Lens-default lists with "All" one click away** | Blueprint §5 / §8.2 saved-lens list model. Subscriptions already defaults to `past_due,canceling` with an "All" chip; standardize the pattern and confirm Home's exception rail follows the same "actionable-first" default | LOW | Mostly a **confirm/standardize**, not net-new — Subscriptions' `work_queue_chips/3` already implements it. Ensure the reign preserves it. |

### Differentiators (What Makes M1 Read as "Best-in-Class Operator Console")

M1's differentiation is intentionally thin — the marquee differentiators ("Why blocked?", causality graph) are **M2**. M1's differentiation is the *feel*: calm, exact, one-verdict density that separates Accrue from a generic CRUD admin.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Reusable "health verdict" pattern** (one calm, scannable verdict block reused on Home + Subscriptions, later every overview) | Turns "operator control plane" from a slogan into a repeatable component; the single most-visible signal of the redesign | MEDIUM | If a "work-queue callout" shape clearly repeats, PROJECT.md permits **one** small new shared component — this is the likely candidate. Compose from `.ax-card` first; only extract if it repeats. |
| **"One door per JTBD" launcher as shared cards** (Home's four task launchers rebuilt on `.ax-card` + `Button` instead of `.ax-launcher*`) | Keeps the strong uk.gov-style task-launcher IA while shedding bespoke CSS; makes Home feel like the same system as the lists | MEDIUM | Preserve the existing four jobs (invoices / customer search / recovery / webhooks); change the *chassis*, not the IA. |
| **Consistent list→detail worklist affordance on Subscriptions** (back-to-filtered list + one clear "work this" action) | Blueprint §39.1 worklist loop — the finance "invoices-to-zero" power path | LOW–MEDIUM | Light version only for M1: one unambiguous per-row action, preserved filter state. Full queue-position indicator / prev-next is a later polish, not required for cohesion. |

### Anti-Features for M1 (Real Blueprint Ideas — but M2/M3, exclude here)

These are **good** and on the roadmap; they are **out of scope for v1.57 M1** and must not be pulled in. Excluding them is what keeps M1 low-risk and admin-only.

| Feature | Why Tempting | Why Out of M1 | Correct Milestone |
|---------|--------------|---------------|-------------------|
| **"Why blocked?" diagnosis card** | The signature component; `f-2d5d1031` (audit log shows only a label, not actual entries) points toward it | Needs core `accrue` diagnosis fn `blocking_reason_for_owner/1`; synthesizes entitlement+sub+invoice+payment+webhook-lag — a scope-class change (admin → admin+core) | **M2** |
| **Causality graph / causal timeline** | Turns the event ledger into an operator superpower | Needs core `causality_chain_for_event/1`; net-new visualization | **M2** |
| **State-as-of reconstruction / before-after diff** | High support value on the event log | Core reconstruction backend; not a Home/Subscriptions surface | **M2** |
| **Unified `billing_state_for_customer/1` view + core diagnosis fns + durable event-name contracts** | The backbone of the whole control-plane thesis | Explicitly core-`accrue` work; M1 is `accrue_admin` templates + `assets/css` only, **no core change** | **M2** |
| **New rooms: Usage / meters / metered-renewals, checkout sessions, Connect capabilities matrix, fee reconciliation** | Fills real IA gaps in the blueprint | New surfaces, not a reign of existing pages; failed-meter signals stay as an existing attention row in M1 | **M3** |
| **`+Usage` / `+Settings` top-level nav groups** | Part of the blueprint's IA restructure | Those groups only make sense once M3's rooms exist; adding empty nav now is premature. M1 breadcrumb/nav work is limited to what Home+Subscriptions reference | **M3** (with the rooms) |
| **De-tab Customer-360 into anchored sections** | Blueprint IA change; subscription-**detail** findings (`f-bd3b2c`, `f-66d02ab`, `f-c56b21`, `f-f1a5f2`, `f-ce7380d`, etc.) show the same defect grammar | Customer-360 and subscription-**detail** are **not** the two named M1 pages (Home + Subscriptions **list**). Same grammar, later slice | **Later M1-family / M2 slice** |
| **Sensitive-action class A/B/C + step-up auth; "[Object] [verb]. View event." toasts; optimistic-lock conflict UI** | Cross-cutting discipline in the synthesis' broad M1 | Home + Subscriptions list are read/navigate surfaces with no state-changing actions to guard; these belong to action-bearing **detail/wizard** pages | **Later M1-family slice** |
| **Freshness / stale-projection chips** ("last processor event 14m ago", "a failed webhook may be blocking this") | Serves "why blocked?"; tempting on the Home health verdict | Tied to webhook-lag diagnosis (M2-adjacent); adds a data dependency M1 shouldn't take on | **M2** |

> **Note on subscription-detail & component-kitchen findings:** 11 of the 23 round-99 findings are on `subscription-detail` (7) and `component-kitchen` (7). They are the **same defect grammar** (competing banners, scattered health, double-negative copy, padding, buried CTAs) and validate the M1 patterns, but the two pages this milestone reigns are **Home** and **Subscriptions (list)**. Subscription-detail is same-family cleanup for a later slice; the component-kitchen entries mirror the shared components being fixed and will improve as the vocabulary is reigned. The **12 findings on `dashboard` + `subscriptions`** are the direct M1 input.

---

## Home vs Subscriptions — Page-Specific Specifics

### Home (`dashboard_live.ex`) — the harder reign (fully bespoke today)

**Current state:** No shared primitives. Renders the health verdict **three times** (`h1` headline + `ax-home-header-health` band + `ax-attention-summary`). Bespoke `ax-attention` exception rail, a standalone `ax-home-customer-search-strip` band (duplicating the header's "Find one customer" button **and** the launcher's customer-search card — the search entry appears **3×**), bespoke `ax-launchers` grid, `ax-kpi-grid`, and two activity cards.

**M1 moves:**
1. Collapse the three health verdicts to **one** in a `PageHeader` title slot (fixes `f-48c5df33`, `f-3536ce24`, `f-f72b5bca`, `f-3380c550`).
2. Rebuild the exception rail on `.ax-card` (retire `ax-attention*`); keep exceptions-first ordering, drop the redundant `ax-attention-summary` restating "Unhealthy".
3. Rebuild the four task launchers on `.ax-card` + `Button` (retire `ax-launcher*`); preserve the four JTBD doors.
4. Promote customer search to **one** prominent entry (retire the standalone `ax-home-customer-search-strip` band + duplicate CTA — fixes `f-ca8eabe5`, `f-bd22ab26`).
5. Demote KPIs below verdict+exceptions on a shared `StatStrip`/`.ax-card` idiom (retire the bespoke `ax-kpi-grid` wrapper where it diverges).

### Subscriptions (`subscriptions_live.ex`) — the partial reign (bands to delete)

**Current state:** Already uses `PageHeader` / `StatStrip` / `DataTable` / `FilterChipBar` / `StatusBadge` — but between the header and the table sit **five** bespoke bands: `ax-subscriptions-invoice-strip`, `ax-subscriptions-queue-shortcut`, `ax-subscriptions-invoice-records`, `ax-subscriptions-at-risk-strip`, `ax-subscriptions-audit-strip`. The "Open dedicated invoice queue" CTA appears in the header actions **and** in three of these bands.

**M1 moves:**
1. Delete the redundant invoice bands; keep **one** canonical invoice-queue entry point (fixes `f-5a1ecbfd`, `f-ad500f6f`, `f-037729e9`, `f-3229847d`).
2. Fold at-risk + audit strips into the existing `StatStrip` / table signals rather than standalone `ax-inline-worklist` bands (removes padding waste `f-70ea46e4`, `f-f00ee035`, `f-4704825f`).
3. Resolve the double per-row "Work open invoices" action to one clear affordance (fixes `f-186adbbb`).
4. Make Home the real "Billing health overview" the breadcrumb promises, with a return path (fixes `f-16203f0c`).
5. Move the bespoke raw-HTML `identity_cell`/`billing_signals_cell` idioms toward the shared cell idiom where practical, sanding jargon (`f-3229847d`).

---

## Feature Dependencies

```
Reign onto shared vocabulary (PageHeader/StatStrip/DataTable/.ax-card/Button/StatusBadge/EmptyState)
    └──enables──> One health verdict per page
    └──enables──> One primary action per zone / de-dup entry points
                       └──enables──> Trim redundant bands + tighten density
    └──enables──> Answer-first content order

Plain-language copy (AccrueAdmin.Copy SSOT) ──enhances──> One health verdict per page
Lens-default lists (already present) ──preserved-by──> Reign onto shared vocabulary

One health verdict ──precedes──> M2 "Why blocked?" card (M2 slots into the verdict location)
Answer-first grammar ──precedes──> M2 diagnostic surfaces (grammar must exist first)

Reign + de-dup + density ──precedes──> ratchet re-freeze (v1.56 harness re-locks the new baseline)
```

### Dependency Notes

- **Everything depends on the reign:** the shared vocabulary is the substrate; verdict-consolidation, entry-point de-dup, and density all fall out of composing the shared components correctly.
- **M1 must precede M2 structurally:** the "one verdict per page" slot is exactly where M2's "Why blocked?" card lands. Building the grammar first means M2 is an insertion, not a rewrite.
- **Ratchet re-freeze is downstream, not in M1:** the parked v1.56 harness re-locks the redesign after M1 lands (rubric/exemplar refresh + baseline re-freeze). Do not retarget it mid-M1.

---

## MVP Definition (v1.57 M1)

### Launch With (M1 — the cohesion baseline)

- [ ] **Reign Home onto the shared vocabulary** — retire `ax-home-*` / `ax-launcher*` / `ax-attention*`; essential, it's the biggest outlier.
- [ ] **Reign Subscriptions onto the shared vocabulary** — delete the 5 redundant bespoke bands; essential.
- [ ] **One health verdict per page** — single scannable verdict, no duplicate banners; the defining "operator control plane" signal.
- [ ] **One primary action per zone / de-dup the invoice-queue entry point** — the single most-confirmed round-99 defect (`f-5a1ecbfd`).
- [ ] **Trim redundant bands + tighten density to reference** — essential to "reads as one system".
- [ ] **Plain-language verdicts + precise action labels** — kill double-negatives + jargon (`f-66d02ab6`, `f-3229847d`).
- [ ] **Answer-first content order** on both pages.
- [ ] **Rebuild the committed `priv/static/accrue_admin.css` bundle + PNG-verify** against the Payments/Customers/Invoices reference (build discipline, non-negotiable).

### Add After Validation (still M1-family, later slice)

- [ ] Customer-lookup ⌘K promotion refinements beyond a single prominent entry.
- [ ] Subscription-**detail** same-grammar cleanup (7 `subscription-detail` findings).
- [ ] Full list→detail worklist loop (queue-position indicator, prev/next).

### Future Consideration (M2 / M3 — do not build in v1.57)

- [ ] "Why blocked?" diagnosis card + core `blocking_reason_for_owner/1` — **M2**.
- [ ] Causality graph / timeline + `causality_chain_for_event/1` — **M2**.
- [ ] Unified `billing_state_for_customer/1` view, state-as-of, freshness/stale chips — **M2**.
- [ ] `+Usage` / `+Settings` nav + Usage/checkout/Connect-matrix/fee-recon rooms — **M3**.
- [ ] De-tab Customer-360; sensitive-action A/B/C; "View event" toasts; optimistic-lock UI — later slices.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Reign Home onto shared vocabulary | HIGH | HIGH | P1 |
| Reign Subscriptions onto shared vocabulary (delete bands) | HIGH | MEDIUM | P1 |
| One health verdict per page | HIGH | MEDIUM | P1 |
| De-duplicate invoice-queue entry point / one action per zone | HIGH | MEDIUM | P1 |
| Trim redundant bands + density to reference | HIGH | MEDIUM | P1 |
| Plain-language verdicts + precise action labels | MEDIUM | LOW | P1 |
| Answer-first content order | MEDIUM | MEDIUM | P1 |
| Correct nav paths + breadcrumb integrity | MEDIUM | LOW | P2 |
| Customer lookup as one prominent entry | MEDIUM | LOW | P2 |
| Confirm/standardize lens-default lists | MEDIUM | LOW | P2 |
| Reusable health-verdict component (1 new shared allowed) | MEDIUM | MEDIUM | P2 |
| Light list→detail worklist affordance | LOW | LOW | P3 |

**Priority key:** P1 = must have for M1 cohesion · P2 = should have, strengthens the pivot · P3 = nice to have, later slice.

## Reference / "Competitor" Feature Analysis (internal reference pages)

The "competitors" here are Accrue's own **already-good** pages — the reign target.

| Feature | Payments/Customers/Invoices (reference) | Home (today) | Subscriptions (today) | M1 Target |
|---------|------------------------------------------|--------------|------------------------|-----------|
| Page header | `PageHeader` (breadcrumb+title+actions+stat_strip+filter) | Bespoke `ax-page-header` + 3 verdict renders | `PageHeader` ✓ | `PageHeader`, single verdict |
| Stats | `StatStrip` | `ax-kpi-grid` bespoke | `StatStrip` ✓ | `StatStrip` |
| List | shared `DataTable` + `FilterChipBar` | none (launchers) | `DataTable`+`FilterChipBar` ✓ but buried under 5 bands | shared, unbuffered |
| Bands between header + list | none | n/a | **5 bespoke worklist bands** | **0** |
| Primary action | one per header | 5 header buttons + duplicated CTAs | invoice CTA ×3+ | **one per zone** |
| Empty state | `EmptyState` grammar | bespoke `ax-empty` | `Copy.resource_state_copy` ✓ | `EmptyState` grammar |

## Sources

- `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md` (§1 thesis, §2 load-bearing ideas, §5 patterns/antipatterns, §9 M1/M2/M3 decomposition) — HIGH
- `.planning/research/admin-ratchet-round99-confirmed-findings.json` (23 confirmed findings; 12 on `dashboard`+`subscriptions` = direct M1 input) — HIGH
- `.planning/seeds/SEED-004-admin-ui-blueprint-redesign.md` (scope, guardrails, M1-only alternative) — HIGH
- `.planning/PROJECT.md` "Current Milestone: v1.57" (M1 target features, admin-only constraint) — HIGH
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` + `subscriptions_live.ex` (current bespoke component sets + redundant bands, read directly) — HIGH
- Blueprint north-star `prompts/accrue_admin_operator_ui_journey_blueprint.md` (via synthesis; §4 domain-language, §8 grammars, §12 ⌘K, §41 answer-order) — MEDIUM (read through the self-contained synthesis, not verbatim)

---
*Feature research for: v1.57 SEED-004 M1 admin operator-control-plane IA/grammar pivot (Home + Subscriptions)*
*Researched: 2026-07-19*
