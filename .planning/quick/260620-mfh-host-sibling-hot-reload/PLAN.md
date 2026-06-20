---
quick_id: 260620-mfh
slug: host-sibling-hot-reload
date: 2026-06-20
---

# Quick Task: Hot-reload sibling Accrue libs in the host dev DX

## Problem

Editing a sibling Accrue lib (`accrue`, `accrue_admin`, `accrue_portal` — all
`path:` deps of `examples/accrue_host`) didn't show up in the running Docker demo
until a manual `docker compose restart web`. Root cause in
`examples/accrue_host/config/dev.exs`:
- **no `reloadable_apps`** → Phoenix's dev code reloader only recompiles
  `:accrue_host`, never the path deps (stale compiled code served);
- `live_reload` patterns only watched `lib/accrue_host_web/**`, not the sibling
  lib dirs (which live outside the host dir at `/workspace/{accrue,…}`).

Surfaced when wiring the admin brand mark (task 260620-luy): the new
`sidebar.ex` markup wasn't served until a restart.

## Fix (dev-only; shift-left)

`examples/accrue_host/config/dev.exs` — on the Endpoint dev config:
- `reloadable_apps: [:accrue_host, :accrue, :accrue_admin, :accrue_portal]`
  (load-bearing: recompiles path deps on the next request);
- `live_reload: dirs: [...]` watching `../../accrue/lib`, `../../accrue_admin/lib`,
  `../../accrue_admin/priv/static`, `../../accrue_portal/lib`;
- sibling `patterns` for `accrue*/lib/**.{ex,heex}` + `accrue_admin/priv/static/**.{css,js}`.

`examples/accrue_host/docs/docker-dx.md` — new "Editing the Accrue libraries"
subsection rolling in the lesson: sibling `.ex`/`.heex` edits now auto
recompile+reload; the **one exception is admin CSS**, which still needs
`mix accrue_admin.assets.build` first (admin serves the committed bundle, not
source app.css), after which the rebuilt bundle auto-reloads.

## Out of scope
- prod/runtime config; `bin/dev-entrypoint.sh`.

## Verification
- `cd examples/accrue_host && MIX_ENV=dev mix compile` → clean (dev.exs valid).
- One-time: the running container must be restarted ONCE to load the new dev.exs;
  after that, sibling edits hot-reload with no further restarts.
