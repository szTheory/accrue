---
quick_id: 260620-mfh
slug: host-sibling-hot-reload
date: 2026-06-20
status: complete
---

# Summary: Hot-reload sibling Accrue libs in the host dev DX

## What changed
- `examples/accrue_host/config/dev.exs`: added
  `reloadable_apps: [:accrue_host, :accrue, :accrue_admin, :accrue_portal]` and
  extended `live_reload` with `dirs` (sibling `lib/` + admin `priv/static`) and
  sibling `patterns`. Editing any Accrue lib `.ex`/`.heex` now recompiles on the
  next request and auto-reloads the browser — no `docker compose restart web`.
- `examples/accrue_host/docs/docker-dx.md`: new "Editing the Accrue libraries
  (sibling path deps) — also hot" subsection documenting the behavior and the
  CSS exception (`mix accrue_admin.assets.build` still required for the committed
  bundle).

## Result
`MIX_ENV=dev mix compile` clean. Dev-only; no prod/runtime impact.

## One-time activation
The running container must be restarted ONCE (`docker compose restart web`) to
load the new `dev.exs`. After that, sibling-lib edits are hot — no more restarts.

## Lineage
Lesson extracted from task 260620-luy (admin brand mark), where the sibling
edit needed a manual restart to appear.
