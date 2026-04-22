---
status: clean
phase: 50
depth: quick
updated: 2026-04-22
---

# Code review — Phase 50

## Scope

- `accrue_admin/lib/accrue_admin/copy/subscription.ex`, `accrue_admin/lib/accrue_admin/copy.ex`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex`
- `scripts/ci/accrue_host_verify_browser.sh`, `examples/accrue_host/e2e/verify01-admin-a11y.spec.js`, `examples/accrue_host/e2e/generated/copy_strings.json`
- Docs: `accrue_admin/guides/theme-exceptions.md`, `examples/accrue_host/docs/verify01-v112-admin-paths.md`, `CONTRIBUTING.md`, `examples/accrue_host/README.md`, `.planning/.../50-VERIFICATION.md`

## Security / privacy

- Export allowlist is explicit (no blind sweep); JSON contains only public operator strings already on `AccrueAdmin.Copy`.
- Path inventory uses placeholders only (`:id`, `<slug>`).

## Quality

- `function_exported?/3` is unreliable for `defdelegate` in Mix tasks; export uses `__info__(:functions)` membership instead.
- LiveView `defp proration_options/0` sits before `attr` so declarative components stay valid.

## Findings

None.
