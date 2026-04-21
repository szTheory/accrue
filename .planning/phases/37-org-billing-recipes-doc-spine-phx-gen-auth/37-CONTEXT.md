# Phase 37: Org billing recipes — doc spine + phx.gen.auth - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish the **non-Sigra** documentation spine for **session → billable** (org-shaped billing, **ORG-03** boundaries) and a **phx.gen.auth**-oriented checklist touching `Accrue.Auth`, `Accrue.Billable`, and the host billing facade — **without** new Accrue Hex dependencies and **without** requiring Sigra modules. Pow, custom org depth, and adoption-proof matrix work stay in phases **38–39**.

</domain>

<decisions>
## Implementation Decisions

### Doc spine shape (ORG-05 narrative home)

- **D-01:** Add a **new dedicated ExDoc extra** (e.g. `accrue/guides/organization_billing_host.md` — exact filename TBD in plan) as the **single ORG-05 spine**: linear story from session through host-resolved org to Accrue billing seams.
- **D-02:** Use a **hybrid hub + deep links** model: the spine owns **sequence and obligations**; it **does not** duplicate full `Accrue.Auth` callback reference or full config surface — those stay in existing guides and are linked.
- **D-03:** Add a **short pointer** from top-level discoverability surfaces (`accrue/README.md` and/or `guides/quickstart.md` if present) — **not** README-only documentation; the spine remains the canonical long-form (Hex/Phoenix ecosystem norm: many focused guides vs one mega-README).
- **D-04:** Keep **`auth_adapters.md`** scoped to the **Accrue.Auth contract** and adapter examples; do **not** fold the full org billing narrative into it (avoids merge/review churn and “I searched billable and landed in auth” surprise).

### “Not using Sigra” entry points

- **D-05:** **`auth_adapters.md`** — add a compact **“Choosing an adapter / without Sigra”** block **immediately after the opening framing** (2–4 sentences SSOT): Accrue is auth-agnostic; Sigra is an **optional** first-party adapter when `:sigra` is already a dependency; otherwise implement `Accrue.Auth` (link to PhxGenAuth/Pow/Assent sections below).
- **D-06:** **`sigra_integration.md`** — add a **small “Not using Sigra?”** callout **at the top** (before dependency install): eligibility (“this guide assumes Sigra is already part of your app”), one link to **`auth_adapters.md`** as the default path, restate “do not reference `Accrue.Integrations.Sigra` without Sigra” **without** pasting full PhxGenAuth examples (avoid duplication and circular doc bloat).
- **D-07:** **`mix accrue.install`** — when `has_sigra?` is **false**, extend `print_auth_guidance/1` with **one stable line** pointing to the ExDoc path or repo-relative path for **`guides/auth_adapters.md`** (and optionally the new spine once it exists). Installer text is a **pointer**, not a second tutorial (reaches users who never open ExDoc; avoids scrollback-only truth).
- **D-08:** Maintain **one canonical sentence** for “Sigra is optional” wording in the hub; Sigra guide and installer use **short mirrors + link** to avoid drift.

### phx.gen.auth recipe concreteness (ORG-05 + ORG-06)

- **D-09:** **One linear mainline** in the spine: **Organization-as-billable** with **membership** + **active organization** resolved from session (after `phx.gen.auth` identity is established). This matches ORG-05’s org-shaped billing and B2B least surprise (Stripe Customer mental model per org).
- **D-10:** Document **minimal host data model**: `Organization`, `Membership` (user ↔ org + role); recommend **bootstrap personal org + membership on registration** so solo developers are not forced into a second parallel recipe.
- **D-11:** **`phx.gen.auth` checklist** (ORG-06) in the same spine: `fetch_current_user` unchanged as source of truth → add **`fetch_current_organization`** (plug / `on_mount`) that **always** validates membership before exposing `current_organization` → attach **`use Accrue.Billable` on `Organization`** → billing facade accepts **Organization** as billable for org-shaped flows → wire **`Accrue.Auth`** adapter (`MyApp.Auth.PhxGenAuth` pattern from `auth_adapters.md`, linked not inlined).
- **D-12:** **Bounded aside** (not a second full track): acknowledge **User-as-billable** (Cashier-style) as a stepping stone — one short subsection: when it is acceptable, what Accrue still expects (`owner_type` / `owner_id`), and that moving to org billing later requires **migrating Stripe customer/subscription ownership** to the org row. Full Pow/custom anti-patterns and replay matrices → **Phase 38** forward link.

### ORG-03 depth in Phase 37

- **D-13:** Use **checklist + normative paragraph** (not link-only, not full re-copy of v1.3 prose): one **short paragraph** restating **ORG-03** in host-owned terms (four path classes: **public**, **admin**, **webhook replay**, **export** — no cross-org billing access or mutation).
- **D-14:** Include a **fixed checklist table**: each row = path class → **threat one-liner** → **host obligation** → **where to enforce** (router plug, LiveView mount, context query scope, replay handler, export job) → **link** to canonical ORG-03 text and forward link to **Phase 38 / ORG-08** for anti-pattern catalog and custom org/replay edge cases.
- **D-15:** **Canonical reference** for full ORG-03 wording: `.planning/milestones/v1.3-REQUIREMENTS.md` (ORG-03 row) — stable ID anchor; spine does not duplicate the entire security narrative.

### examples/accrue_host anchoring

- **D-16:** **Hybrid documentation layers** in the spine: (1) **generator-agnostic** narrative using `MyApp.*` placeholders for invariants; (2) a recurring **“Reference wiring (`examples/accrue_host`)"** block (or end section) with **real modules/paths** proving the recipe.
- **D-17:** The example host already has **`User` and `Organization`** both `use Accrue.Billable` — cite **`AccrueHost.Accounts.Organization`**, **`AccrueHost.Accounts.User`**, **`AccrueHost.Billing`**, and router as **ground truth** for wiring; prose clarifies **Organization** is the **recommended billable** for org-shaped flows in the Phase 37 mainline, while **User** illustrates the bounded aside / legacy path.
- **D-18:** Prefer **module + responsibility** in prose; put fragile **file paths** in a skimmable table; accept occasional path churn or plan lightweight link/snippet checks in CI in a later plan if not already present.

### Cross-cutting engineering principles (locked)

- **D-19:** **Principle of least surprise:** neutral contract docs first; Sigra is clearly **branch** documentation; org billing has **one obvious front door** (new spine) linked from auth + Sigra + installer.
- **D-20:** **DX:** Cashier-like **vertical TOC** inside the spine (install/config → session → org → billable → admin → webhooks pointer → testing pointer); Stripe-like separation of **concept spine** vs **API reference** (stay in moduledocs for exhaustive API).
- **D-21:** **Footguns explicitly documented** in spine: stale `active_organization_id` after revoke; IDOR on `/orgs/:id` without membership check; “first org in DB” defaults; webhook/replay using global queries; implying `Accrue.Auth.Default` is production-safe for non-Sigra apps.

### Claude's Discretion

- Exact filename for the new guide and ExDoc `groups_for_extras` placement — planner picks to match existing `guides/` naming.
- Whether the README pointer is one sentence vs a small “Org billing (non-Sigra)” bullet — planner decides based on current README structure.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — ORG-05, ORG-06 (checkbox acceptance); out-of-scope table.
- `.planning/ROADMAP.md` — Phase 37 goal, success criteria, v1.8 milestone context.
- `.planning/milestones/v1.3-REQUIREMENTS.md` — ORG-03 full requirement text (canonical security ID).

### Research (milestone v1.8)

- `.planning/research/SUMMARY.md` — doc spine intent, non-Sigra parallel paths.
- `.planning/research/FEATURES.md` — spine + phx.gen.auth path expectations.
- `.planning/research/PITFALLS.md` — admin “first org” and related pitfalls.
- `.planning/research/ARCHITECTURE.md` — `Accrue.Billable` / ownership model.
- `.planning/research/STACK.md` — phx.gen.auth + host-owned session notes.

### Existing guides (edit targets)

- `accrue/guides/auth_adapters.md` — `Accrue.Auth` contract, PhxGenAuth/Pow/Assent examples.
- `accrue/guides/sigra_integration.md` — Sigra-first spine; needs non-Sigra escape hatch.
- `accrue/guides/finance-handoff.md` — billable / customer ownership table (cross-link as needed).

### Installer

- `accrue/lib/mix/tasks/accrue.install.ex` — `print_auth_guidance/1` non-Sigra branch.

### Reference implementation

- `examples/accrue_host/lib/accrue_host/accounts/user.ex` — `use Accrue.Billable, billable_type: "User"`.
- `examples/accrue_host/lib/accrue_host/accounts/organization.ex` — `use Accrue.Billable, billable_type: "Organization"`.
- `examples/accrue_host/lib/accrue_host/billing.ex` — host billing facade pattern.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`auth_adapters.md`** — `MyApp.Auth.PhxGenAuth` is already the template for ORG-06; spine should link here instead of duplicating.
- **`examples/accrue_host`** — dual billable schemas (`User`, `Organization`) + `AccrueHost.Billing` facade for concrete annex.

### Established Patterns

- ExDoc **extras** pattern (`guides/*.md`) matches Ecto/Phoenix multi-guide docs — new spine fits ecosystem norms.
- Installer already branches **`has_sigra?`** for auth messaging — extend non-Sigra branch only.

### Integration Points

- `mix.exs` **extras** list / groups for new guide (if required).
- Cross-links from **README**, **quickstart** (if applicable), **sigra** + **auth** guides.

</code_context>

<specifics>
## Specific Ideas

- **Subagent synthesis (2026-04-21):** Compared Laravel Cashier (user-default, long pages), Stripe (concepts vs API), Rails Pay/README bloat, Jumpstart opinionated paths, Sentry/NextAuth optional-integration doc patterns — converged on **hub + optional spine + short mirrors**, **org-first mainline** with **personal-org bootstrap**, **ORG-03 checklist** in spine, **abstract + `accrue_host` annex** for DX.

</specifics>

<deferred>
## Deferred Ideas

- **Pow-oriented recipe and version variance** — Phase 38 (ORG-07).
- **Custom org model anti-patterns and webhook replay alignment detail** — Phase 38 (ORG-08).
- **Adoption proof matrix / VERIFY-01 non-Sigra archetype** — Phase 39 (ORG-09).
- **Automated snippet extraction / link checking for guides** — nice-to-have; not required for ORG-05/06 text acceptance unless planner folds in trivially.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 37-org-billing-recipes-doc-spine-phx-gen-auth*  
*Context gathered: 2026-04-21*
