---
status: clean
phase: 49
depth: quick
updated: 2026-04-22
---

# Code review — Phase 49

## Scope

- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — ScopedPath breadcrumbs + related billing card
- `accrue_admin/lib/accrue_admin/copy.ex` — `subscription_drill_*` copy
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — org-scoped href assertions
- `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` — mounted `/billing/subscriptions/:id` + Fake cleanup
- `accrue_admin/README.md` — router vs sidebar clarification

## Security / privacy

- Links reuse loaded `subscription.customer` only; no new processor tokens in query strings; no `subscription_id=` on list routes (per research).

## Quality

- Removed dead `scoped_mount_path/3` after migrating to `ScopedPath.build/3|4`.
- Host test resets `Accrue.Processor.Fake` and deletes `sub_fake_%` / `cus_fake_%` rows before `Factory.active_subscription/1` to avoid processor_id collisions on shared host test DB.

## Findings

None.
