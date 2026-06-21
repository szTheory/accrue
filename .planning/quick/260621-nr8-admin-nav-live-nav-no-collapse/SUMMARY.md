---
quick_id: 260621-nr8
slug: admin-nav-live-nav-no-collapse
date: 2026-06-21
status: complete
validate: true
verify: Verified
---

# Summary: Admin nav — live navigation + loading stripe · remove sidebar collapse

Two user complaints about navigating between admin sections (e.g. Customers → Subscriptions),
both traced to **one root cause** and fixed in one move + one removal (`--validate`: plan-check
PASS first iteration; verification PASS 7/7, suites independently re-run). 3 atomic code commits on
`main`, non-worktree.

## Root cause

The sidebar nav links were plain `<a href={item.href}>` (`sidebar.ex:76`). A bare anchor is a
**full browser page reload**, which (1) never emits `phx:page-loading-*` — so the already-wired
topbar loading stripe (`app.js:11-28`) never fired — and (2) re-mounted the whole LiveView, so the
`SidebarCollapse` hook re-initialised from `localStorage` and replayed its opacity transition →
the "section headers collapse/re-expand on every navigation" flash. All admin pages share one
`live_session :accrue_admin` (`router.ex:68-104`), so the fix is to make section nav **client-side
live navigation**.

## What changed

1. **Live navigation + visible stripe.** `sidebar.ex:76` `<a href>` → `<.link navigate={item.href}>`
   (renders `href` + `data-phx-link="redirect"`). Now section changes are live redirects: the
   topbar fires AND morphdom preserves the sidebar DOM (no re-mount flash). `app.js:26` topbar
   show-delay `300`→`120` ms so the stripe is perceptible on fast local navs (reduced-motion stays
   instant). Plan-checker confirmed there were no other plain internal `<a href>` links in
   `lib/accrue_admin` — the consistency sweep was a genuine no-op.
2. **Collapse/expand removed entirely (badges kept).** Per the user's explicit ask. `sidebar.ex`:
   `<section>` lost `phx-hook`/`data-group`/`data-controls`; the `if collapsible do <button>… else
   <p>… end` block became a single static `<p class="ax-sidebar-group-label">` carrying the badge
   span; dropped `hidden=…`, deleted `group_initially_expanded?/1`, removed `collapsible` from
   `grouped_items/1` meta; moduledoc updated. `nav.ex`: `collapsible:` removed from all 11 item
   maps (`badge` kept). `app.js`: `SidebarCollapse` import + hook registration removed;
   `assets/js/hooks/sidebar_collapse.js` `git rm`'d. `app.css`: removed
   `.ax-sidebar-group-toggle`/`-chevron`/`[aria-expanded] chevron` rotation/`.ax-collapsed` +
   the group-links opacity transition; merged badge flex/gap alignment into
   `.ax-sidebar-group-label` (tokens only); updated the two explanatory comments.
   `component_kitchen_live.ex`: removed the now-stale "collapsible nav group" motion-inventory row.

Rebuilt the committed `priv/static/accrue_admin.{css,js}` (final commit).

## Result

`mix compile --warnings-as-errors` clean; full `mix test` → **348 tests, 0 failures**
(`navigation_components_test`, `nav_test`, `assets_test`, `dev/component_registry_test`,
`app_shell_test` all green). Built `accrue_admin.js` has **no** `SidebarCollapse`;
`accrue_admin.css` has **no** `.ax-sidebar-group-toggle`/`.ax-collapsed`. Spec-gap proven: the new
`data-phx-link="redirect"` assertion (navigation_components_test.exs:394) FAILS on the pre-change
`<a href>` markup and PASSES after.

## Commits
- `76ea8393` — `feat`: live-nav sidebar links + topbar delay (sidebar.ex link, app.js:26, +data-phx-link test)
- `9b7b9c56` — `refactor`: remove sidebar collapse, keep badges (sidebar.ex, nav.ex ×11, app.js hook removal, `git rm` sidebar_collapse.js, app.css, component_kitchen row, test rewrites, app_shell assertion fix)
- `c2187e54` — `chore`: rebuild committed accrue_admin asset bundle

## Notes / decisions
- **One deviation (Rule 1, direct consequence)**: `app_shell_test.exs:153-154` asserted exact
  `href="…" class="…"` adjacency; `<.link navigate>` inserts `data-phx-link` attrs between them.
  Loosened to single-tag regex (`href="/billing"[^>]*class="…active"`) — verifier confirmed it
  preserves the "only the current journey item is active" intent (`[^>]*` can't cross `>`;
  `/billing` vs `/billing/webhooks` are distinct literals), not a regression-permitting weakening.
- **No new CSS class / no registry churn**: the removed collapse classes were not registered in
  `dev/component_registry.ex`, so the render-coverage guardrail stayed green.
- **Guardrails honored**: untouched StatusBadge, CSP, `examples/accrue_host/mix.lock`,
  `.planning/research/.cache/`, ROADMAP.md. No host tests run (would need `deps.get` on the
  off-limits stale host `mix.lock`); no host files changed.

## Browser-only follow-up (user visual confirm on the demo)
Navigate Customers → Subscriptions → Webhooks: (a) a thin accent **top loading stripe** appears
during transitions; (b) the **sidebar no longer flashes/collapses** — all groups show their links
permanently; (c) Recovery/Developer **badges still render**. Confirm deep links
(`/billing/customers?org=…`) still scope correctly through live nav and the active-link highlight
follows the current section.
