# Phase 25 — Technical research

**Phase:** 25 — Admin UX inventory  
**Question:** What do we need to know to plan INV-01..03 well?

## RESEARCH COMPLETE

### Route truth (INV-01)

- **Authoritative source:** `accrue_admin/lib/accrue_admin/router.ex` — `accrue_admin/2` macro expands `live_session :accrue_admin` plus conditional `if dev_routes?` block (`:allow_live_reload` option, default `Mix.env() != :prod` when omitted).
- **Reference host:** `examples/accrue_host/lib/accrue_host_web/router.ex` mounts `accrue_admin "/billing", session_keys: [:user_token], allow_live_reload: false` — shipping-relevant matrix should use **`allow_live_reload: false`** in the header; dev-only rows must be **sourced from router source** (not from `mix phx.routes` when dev routes are compiled out).
- **`mix phx.routes`:** Run from `examples/accrue_host`. Confirms **host-absolute** paths under `/billing/...` for LiveViews and hashed asset `GET` routes (`AccrueAdmin.Assets` — **not** LiveView). WS/longpoll rows are Phoenix infra, not admin product routes — INV-01 should **exclude** or footnote them so security readers are not misled.
- **Scope decision (D-02 discretion):** Include **three** `get/3` asset routes in INV-01 under a **“Non-LiveView (Plug → Assets)”** subsection; all `live/4` rows under **Shipping `live_session`**. Dev `live/4` routes listed from `router.ex` lines 75–81 when `allow_live_reload: true`.

### Component coverage (INV-02)

- **Kitchen:** `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` (compile-wrapped `Mix.env() != :prod`) imports **AppShell, Breadcrumbs, Button, FlashGroup, KpiCard, StatusBadge, Tabs** only. Fake processor gate (`@available?`) affects content but not which modules exist.
- **Production primitives:** `accrue_admin/lib/accrue_admin/components/*.ex` lists **21** modules (e.g. `DataTable`, `MoneyFormatter`, `StepUpAuthModal`, `JsonViewer`, …) — many will be **non-blocking backlog** per D-03 unless used on normative surfaces (money indexes, webhooks, step-up, dashboard where spec says so).
- **Method:** `rg 'AccrueAdmin\.Components\.' accrue_admin/lib/accrue_admin/live` vs kitchen file; classify by surface (route module) against D-03 list.

### Spec alignment (INV-03)

- **Inputs:** `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md`, `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md` — use **heading + bullet** as stable pointers until specs gain explicit IDs.
- **Evidence column:** Prefer concrete test paths (`accrue_admin/test/...`, `examples/accrue_host/test/...`, `examples/accrue_host/e2e/*.spec.js`) or `—` with rationale per D-04.
- **Rollup:** Worst status per surface; link clause rows.

### Pitfalls

- **Route drift:** Hash suffixes on `/billing/assets/*` change when assets rebuild — matrix should say “hashed path; run `mix phx.routes`” or capture **pattern** not literal hash in narrative, while still listing **module** `AccrueAdmin.Assets`.
- **Kitchen false negatives:** Components used only on pages not in kitchen are expected; do not apply “every component in kitchen” rule (explicitly rejected in CONTEXT D-03).

---

## Validation Architecture

> Nyquist / plan-checker: Dimension 8 — how execution proves inventory quality without false confidence.

### Feedback channels

| Channel | When | Command / check |
|---------|------|-------------------|
| Route mechanical check | After INV-01 edit | `cd examples/accrue_host && mix phx.routes` — every **shipping** admin `GET /billing/...` LiveView path in INV-01 appears in output (except dev block) |
| Markdown completeness | After each INV file | `rg '_TBD_' .planning/phases/25-admin-ux-inventory/25-INV-*.md` exits **1** (no matches) |
| Snapshot headers | Before phase close | All three `25-INV-*.md` share same **Snapshot:** ISO date and **same git SHA** line (D-05) |
| Optional admin tests | If executor touches code (unlikely) | `mix test` in `accrue_admin` — only if plans expand scope |

### Sampling / continuity

- Inventory phase: **after each plan wave**, re-run `rg '_TBD_'` on INV files touched.
- **No Wave 0** new test framework — existing Mix + grep suffice.

### Manual-only (acceptable)

- Subjective **Partial vs Aligned** in INV-03 requires maintainer judgment; document evidence links, not automated status.

---

*Phase 25 — research for planning*
