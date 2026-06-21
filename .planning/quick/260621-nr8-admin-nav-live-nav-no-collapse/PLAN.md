---
quick_id: 260621-nr8
slug: admin-nav-live-nav-no-collapse
date: 2026-06-21
validate: true
approved_plan: /Users/jon/.claude/plans/i-just-got-an-ethereal-harbor.md
---

# Admin nav: live navigation + loading stripe · remove sidebar collapse

## Root cause (both complaints, one cause)

Sidebar nav links are plain `<a href={item.href}>` (`lib/accrue_admin/components/sidebar.ex:76`).
A bare anchor triggers a **full browser page reload**, which:
1. never emits `phx:page-loading-*`, so the already-wired topbar loading stripe
   (`assets/js/app.js:11-28`) never shows; and
2. re-mounts the whole LiveView, so the `SidebarCollapse` hook re-inits from `localStorage` and
   replays its opacity transition → the "section headers collapse/re-expand on every navigation"
   flash.

All admin pages share ONE `live_session :accrue_admin` (`router.ex:68-104`), so switching the
links to `<.link navigate>` makes section changes **client-side live navigation**: the topbar
fires AND morphdom preserves the sidebar DOM. The user also wants the collapse feature removed
outright.

## Part 1 — Live navigation + visible loading stripe

- `lib/accrue_admin/components/sidebar.ex:76` — `<a :for={item <- items} href={item.href}
  class={nav_class(item, @current_path)}>…</a>` → `<.link :for={item <- items} navigate={item.href}
  class={nav_class(item, @current_path)}>…</.link>`. Keep the `Icon.icon` + `<span
  class="ax-sidebar-link-label">` children. `<.link>` is available via `use Phoenix.Component`;
  it renders `href=…` PLUS `data-phx-link="redirect"`, so `nav_class` active styling and existing
  `href="/billing…"` substring assertions still pass. `?org=` rides along.
- Consistency sweep ONLY if trivially same shape: if `app_shell.ex` topbar/brand/breadcrumbs use
  plain `<a href>` for internal admin links, convert them too. Leave row/detail links (already
  `<.link>`).
- `assets/js/app.js:26` — `topbar.show(reduce.matches ? 0 : 300)` →
  `topbar.show(reduce.matches ? 0 : 120)` (delay constant only; reduced-motion stays instant).
- TEST (spec proof, request 1): in `test/accrue_admin/components/navigation_components_test.exs`
  add `assert html =~ ~s(data-phx-link="redirect")` to a sidebar render test. FAILS on current
  plain-`<a href>`, PASSES after the switch.

## Part 2 — Remove sidebar collapse/expand entirely (keep badges)

- `sidebar.ex`: drop `phx-hook`/`data-group`/`data-controls` from the `<section>` (`:49-51`; keep
  `id` + `class="ax-sidebar-nav-group"`). Replace the `if group_meta.collapsible do <button>…
  else <p>… end` block (`:53-73`) with a single static label carrying the badge:
  ```heex
  <p :if={group} class="ax-sidebar-group-label">
    <%= group %>
    <span :if={group_meta.badge} class={badge_class(group_meta.tone)}
      aria-label={badge_aria_label(group, group_meta.badge)}><%= group_meta.badge %></span>
  </p>
  ```
  Remove `hidden={not group_initially_expanded?(group_meta)}` from the links `<div>` (`:75`); keep
  the `<div id="sidebar-group-links-#{slug}" class="ax-sidebar-group-links">` wrapper. Delete
  `group_initially_expanded?/1` (`:116-119`). Drop `collapsible` from the `group_meta` map in
  `grouped_items/1` (`:108,111`) — keep `badge` + `tone`. Update moduledoc (`:4-16`).
- `nav.ex`: remove the dead `collapsible:` field from all 11 item maps; refresh the Phase 175-02
  comment (`:13-14`). KEEP `badge`.
- `assets/js/app.js`: remove `import { SidebarCollapse } …` (`:10`); drop `SidebarCollapse` from
  the `hooks: {…}` object (`:48`).
- DELETE `assets/js/hooks/sidebar_collapse.js`.
- `assets/css/app.css`: remove `.ax-sidebar-group-chevron`, the two `[aria-expanded="true"] …
  chevron` selectors, `.ax-sidebar-group-toggle`, `.ax-sidebar-group-toggle:focus-visible`
  (`:2041-2080`); remove `.ax-sidebar-group-links { transition: opacity … }` body + `.ax-collapsed`
  (`:3872-3888`) — keep `.ax-sidebar-group-links` only if other props remain; update Phase-177
  comment. Update the "token gap closures" comment (`:2013-2014`). Merge badge alignment into
  `.ax-sidebar-group-label` (`:667`): add `display:flex; align-items:center; gap:
  var(--ax-space-xs);` (tokens only).
- `lib/accrue_admin/dev/component_kitchen_live.ex`: the motion-inventory `<tr>` "collapsible nav
  group" (`:440-444`) now describes a removed feature — update/remove for doc accuracy.
- TESTS: `navigation_components_test.exs` "Sidebar collapsible groups" (`:311-411`) — Recovery now
  renders NO `aria-expanded`/no toggle button (`refute html =~ "aria-expanded"`); Catalog links
  NOT hidden (`refute html =~ ~r/id="sidebar-group-links-catalog"[^>]*hidden/`); keep badge
  assertions. `nav_test.exs` (`:49-92`) — drop `item.collapsible` assertions (keep badge); delete
  "Billing group items have collapsible: false" (`:83-92`); remove `:collapsible` from the
  "items/2 … has keys" check (`:69-73`).

## Guardrails

Don't touch `StatusBadge`, CSP, `examples/accrue_host/mix.lock`, `.planning/research/.cache/`,
ROADMAP.md. After JS+CSS edits run `cd accrue_admin && mix accrue_admin.assets.build` and commit
BOTH `priv/static/accrue_admin.{css,js}` (`assets_test.exs` asserts md5). No host coupling
(grep clean). Update STATE.md "Quick Tasks Completed" (NOT ROADMAP). Orchestrator commits docs;
executor commits code. On `main`, non-worktree.

## Verification

`cd accrue_admin`: `mix compile --warnings-as-errors` clean; `mix accrue_admin.assets.build`;
full `mix test` (report N/M) — `navigation_components_test.exs`, `nav_test.exs`, `assets_test.exs`,
`dev/component_registry_test.exs` green. Built `priv/static/accrue_admin.js` no longer contains
`SidebarCollapse`; `accrue_admin.css` no longer contains `.ax-sidebar-group-toggle`/`.ax-collapsed`.
Spec proof: `data-phx-link="redirect"` assertion FAILS pre-change, PASSES post-change.

## Commits

1. `feat`: live-nav sidebar links + topbar delay (sidebar.ex links, app.js:26, +data-phx-link test).
2. `refactor`: remove sidebar collapse (sidebar.ex, nav.ex, app.js hook removal, delete
   sidebar_collapse.js, app.css, component_kitchen row, test rewrites).
3. `chore`: rebuild committed asset bundle.
