# Phase 21: Admin and Host UX Proof - Context

**Gathered:** 2026-04-17  
**Status:** Ready for planning  
**Source:** `/gsd-discuss-phase 21` with parallel research synthesis (Playwright, admin IA, host narrative, VERIFY-01 split).

<domain>
## Phase Boundary

Phase 21 delivers the **executable** slice of VERIFY-01: Fake-backed tests, `examples/accrue_host` integration tests, and browser/admin checks that prove **tax states**, **user vs organization billing**, **invalid tax location UX**, and **webhook/admin replay denial** for out-of-scope organizations—without taking ownership of FIN-01/FIN-02 finance handoff narrative (Phase 22).

Success is measured by **green CI artifacts** and **evaluator-obvious** host/admin UX, not by finance product documentation depth.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Playwright and CI layout (cohesive with Fake + single host)

- **Split specs, one seed spine:** Replace a single kitchen-sink file with **several feature-scoped Playwright specs** under `examples/accrue_host/e2e/` (e.g. canonical demo smoke, org subscription path, tax-invalid messaging, admin/webhook denial), with shared helpers in `e2e/support/` (login, LiveView wait, fixture reader).
- **One global seed + rich fixture JSON:** Keep **one** `global-setup.js` invocation of `scripts/ci/accrue_host_seed_e2e.exs` for speed and least surprise; extend the emitted fixture with **named keys** (`org_alpha_slug`, `org_beta_slug`, `tax_invalid_customer_hint`, emails) so every spec reads the same contract.
- **Reseed only when destructive:** Use per-spec `reseedFixture()`-style hooks **only** for flows that mutate billing graph; document why—avoids the Pay/Cashier footgun of slow, flaky full reseeds on every test.
- **Desktop-first gate, mobile selective:** Run **full matrix on Chromium desktop** on every PR; run **mobile** as a **smaller tagged subset** or scheduled job—halves flake surface and runtime while keeping responsive signal where it matters (D-04 hybrid admin lists must not break on narrow viewports).

### D-02 — Admin information architecture (cohesive with Phase 20 `?org=` and ORG-03)

- **Hybrid list + detail:** On **money-relevant indexes** (`customers`, `subscriptions`, `invoices`, `charges`), show **two compact derived signals**: (1) **ownership class** (`User` vs `Org` from `owner_type`) and (2) **tax health tri-state** (`off` / `active` / `invalid or blocked`—never a binary “tax on” green dot). Detail pages carry the **authoritative** “Tax & ownership” card: plain language, effective behavior, blockers, safe next steps.
- **Single domain classification function:** List and detail **must** read the same enum/map from one Accrue/admin context or view helper so badges and cards cannot drift.
- **Chrome always shows tenant:** When `?org=` is active, **visible active organization** in shell/topbar alongside nav—reduces Stripe-Dashboard-style wrong-tenant mistakes; preserve `?org=` on every `link` / `push_patch` (Phase 20 pattern).
- **No raw JSON in operator UI:** Summarize from typed projections; mask PII—matches trust posture and avoids ActiveAdmin-style “dump and pray.”

### D-03 — Host demo narrative (cohesive with Sigra + `AccrueHost.Billing` facades)

- **Primary story = one user, multiple orgs, org switcher:** Canonical human path: log in as **one** seeded user, use **Sigra active organization** to switch between **two clearly named orgs** in seeds, complete **user-scoped** billing and **org-scoped** billing in one session—mirrors production mental model and minimizes password-matrix DX from multi-persona demos.
- **Extra personas only for RBAC gaps:** Add a **second** login only where one user cannot hold both roles without contrived data (e.g. member read-only vs owner mutate); document in README table; keep automated IDOR/forged-org proofs in **integration tests** (`org_billing_live_test.exs`, etc.) rather than duplicating every edge in tooltip copy.
- **Integration seam stays grep-friendly:** All Accrue calls from the host app continue through **`AccrueHost.Billing` (and siblings)**—LiveViews do not add ad-hoc `Repo` queries to Accrue tables; VERIFY-01 proofs extend through the **same facades** evaluators should copy.
- **Minimal always-on copy + README VERIFY checklist:** Keep one-line scope reminders (already aligned with “billing follows active organization”); put long-form “how to prove VERIFY-01” in **README / guide** so the UI stays calm.

### D-04 — VERIFY-01 split: Phase 21 vs Phase 22 (cohesive milestone engineering)

- **Phase 21 closes VERIFY-01 executable half:** Tax + org billing + invalid-location surfacing + admin/webhook replay **denial and ambiguity** behavior—proven with Fake, host `mix test`, and Playwright as listed in ROADMAP success criteria. **No** FIN-01/FIN-02 handbook scope; no GAAP/606 narrative; no “mini finance export product.”
- **Phase 22 closes VERIFY-01 narrative + finance-boundary half:** FIN-01/FIN-02 docs, object-ID mapping tables, host-authorized export audience rules, doc-tested boundary strings (or a **small** dedicated test module)—plus milestone-wide traceability and archive readiness **without** re-running Phase 21’s full browser matrix.
- **Practical triage rule:** *If it needs a browser or LiveView operator flow, Phase 21. If it names Stripe Revenue Recognition / Sigma / Data Pipeline / accounting disclaimers, Phase 22.*
- **Traceability cleanup (planner-owned):** `REQUIREMENTS.md` currently maps VERIFY-01 to two phases while claiming one phase per requirement—planners should add an explicit sub-table or split IDs (e.g. VERIFY-01A executable / VERIFY-01B finance-boundary) so closure is unambiguous.

### D-05 — Cross-cutting principles (architecture + DX)

- **Library vs app test pyramid:** `accrue` / `accrue_admin` stay **ExUnit-fast**; `examples/accrue_host` owns **ConnCase + LiveViewTest + Playwright**—idiomatic for Phoenix OSS (heavy browser gates on the **application**, not the core package default `mix test`).
- **Principle of least surprise:** One documented command for E2E from `examples/accrue_host`; stable `ACCRUE_HOST_E2E_FIXTURE` contract; `workers: 1` until DB isolation exists; extend JSON fields instead of proliferating env vars.
- **Learn from Pay / Cashier / Stripe samples:** Idempotent seeds, Fake/test processor, avoid live-network E2E, avoid giant shared DB cleanup races—Accrue already aligns; **guard** against scope creep into “every pixel” polish in Phase 21 (endless Phase 21 is a known OSS footgun).

### Claude's Discretion

- Exact Playwright file names and tag naming (`@mobile`) are left to implementation as long as D-01 structure holds.
- Which **extra** persona (if any) is required for member-denial theater is determined during planning against current Sigra seed shapes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — Phase 21 goal, success criteria, dependency on Phase 20.
- `.planning/REQUIREMENTS.md` — VERIFY-01 (note dual phase mapping; apply D-04 split mentally until traceability row is updated).

### Phase 20 handoff and proof patterns

- `.planning/phases/20-organization-billing-with-sigra/.continue-here.md` — ORG-03 boundaries, `?org=` nav, anti-patterns (UI-only scope, verifier gaps).
- `.planning/phases/20-organization-billing-with-sigra/20-VERIFICATION.md` — Final verification posture for org billing phase.

### Host and browser proof surface

- `examples/accrue_host/playwright.config.js` — `webServer`, projects, fixture env.
- `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` — Current canonical demo patterns (fixture, login, LiveView wait, a11y).
- `scripts/ci/accrue_host_seed_e2e.exs` — Seeding contract for CI/browser.

### Project vision

- `.planning/PROJECT.md` — v1.3 milestone goals, VERIFY-01 intent, risk themes (`wrong-audience finance exports`, etc.).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **Playwright harness:** `global-setup`, `webServer` with `MIX_ENV=test`, `ACCRUE_HOST_E2E_FIXTURE`, `reseedFixture()` pattern in `phase13-canonical-demo.spec.js`.
- **Host billing facade:** `AccrueHost.Billing` — active-org resolution, subscribe flows; extend VERIFY-01 through this module.
- **Admin org scope:** `AccrueAdmin.AuthHook`, `current_owner_scope`, `?org=` preserved via app shell / nav helpers from Phase 20 work.

### Established patterns

- **Fake-backed determinism** for CI; advisory live Stripe only outside default gate.
- **Owner-aware loaders** and denial redirects with exact flash copy—browser tests should assert those strings, not invent parallel UX.

### Integration points

- New Playwright specs register in `e2e/`; seed script emits fixture consumed by JS helpers.
- Admin list/detail LiveViews consume projected tax/ownership fields from existing query modules—prefer **derived view models** over duplicating Ecto in templates.

</code_context>

<specifics>
## Specific Ideas

- **Ecosystem learnings baked in:** Stripe-style explicit tenant chrome; avoid Chargebee/ActiveAdmin unscoped-table footguns; Rails Pay-style integration density stays in **host example**, not package default test.
- **Naming:** Seed orgs with human-obvious display names so single-user switching is self-explanatory in screenshots and traces.

</specifics>

<deferred>
## Deferred Ideas

- **VERIFY-01 traceability edit:** Split or sub-table in `REQUIREMENTS.md` (planner/REQ maintainer)—not blocking implementation decisions above.
- **Finance handoff UX:** Any dedicated “export to accounting” UI belongs in a later milestone unless explicitly pulled from FIN scope—Phase 22 owns narrative.

### Reviewed Todos (not folded)

- None — `gsd-sdk query todo.match-phase` unavailable in this environment.

</deferred>

---

*Phase: 21-admin-and-host-ux-proof*  
*Context gathered: 2026-04-17*
